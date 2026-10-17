#!/usr/bin/env bash
# Bring a PR's branch up to date with its base branch, so a merge into the base
# does not leave the PR BEHIND (the required checks then re-run on the new tip
# and the merge gate stops refusing).
#
#   tools/pr-review/pr-update-branch.sh <pr-number>   # one PR
#   tools/pr-review/pr-update-branch.sh --all         # every open PR
#   tools/pr-review/pr-update-branch.sh <pr> --check  # only report, change nothing
#   tools/pr-review/pr-update-branch.sh <pr> --behind-by  # print how many base commits the head lacks
#
# Call it (a) right after you push, (b) in every 30-second poll loop, and
# (c) whenever any PR merges into the base. Safe to call repeatedly: it does
# nothing when the PR is not behind.
#
# How it updates:
#   `gh api -X PUT repos/{owner}/{repo}/pulls/<n>/update-branch` merges the base
#   into the head on GitHub. It needs no checkout and never touches a local
#   worktree. The push of the merge commit starts CI again by itself.
#
# Exit codes (the worst one wins when --all is used):
#   0  every PR is up to date, or was updated
#   1  usage error or an API/network/permission failure (not a conflict)
#   2  a PR is DIRTY (merge conflict). Resolve it by hand in that PR's own
#      worktree: git fetch origin && git merge origin/<base>, then push. The
#      script never guesses a resolution.
#
# Needs only `gh` (no python).
set -uo pipefail

usage() { sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }
[ $# -ge 1 ] || usage

check_only=0
behind_only=0
for a in "$@"; do
  [ "$a" = "--check" ] && check_only=1
  [ "$a" = "--behind-by" ] && behind_only=1
done

repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)" \
  || { echo "cannot read the repository with gh" >&2; exit 1; }

# Prints "<STATE> <mergeStateStatus>" or fails.
pr_state() {
  gh pr view "$1" --json state,mergeStateStatus --jq '.state+" "+.mergeStateStatus'
}

# Number of base commits the PR head lacks, from the compare API. This is the
# real ancestry test: mergeStateStatus is a merge-gate aggregate (BLOCKED or
# CLEAN can both hide a stale branch), so it is only a hint. Fails (non-zero)
# when the answer cannot be read; callers must not treat that as "current".
pr_behind_by() {
  local base head
  base="$(gh pr view "$1" --json baseRefName --jq .baseRefName)" || return 1
  head="$(gh pr view "$1" --json headRefOid --jq .headRefOid)" || return 1
  # A base name may hold characters that break a URL path (release#2026 turns
  # into a fragment); percent-encode the ones that matter. The head is a SHA.
  base="${base//%/%25}"; base="${base//#/%23}"; base="${base//\?/%3F}"
  gh api "repos/$repo/compare/${base}...${head}" --jq .behind_by
}

# Returns 0 ok, 1 API error, 2 conflict. Do not call it on the left of `||`:
# Bash would switch error checking off inside it. The caller captures `$?`.
update_one() {
  local pr="$1" state head out
  state="$(pr_state "$pr")" || { echo "#$pr: cannot read the PR" >&2; return 1; }
  case "$state" in
    MERGED*|CLOSED*) echo "#$pr: ${state%% *}, skipped"; return 0 ;;
  esac
  # mergeStateStatus is UNKNOWN while GitHub is still computing it; ask a few
  # times. If it never settles, say so: an unknown answer is not "up to date".
  local tries=0
  while [ "${state#OPEN }" = "UNKNOWN" ] && [ "$tries" -lt 4 ]; do
    sleep 5
    state="$(pr_state "$pr")" || { echo "#$pr: cannot read the PR" >&2; return 1; }
    tries=$((tries + 1))
  done
  if [ "${state#OPEN }" = "UNKNOWN" ]; then
    echo "#$pr: merge state still UNKNOWN; retry later" >&2
    return 1
  fi
  case "${state#OPEN }" in
    DIRTY)
      echo "#$pr: DIRTY (merge conflict with the base). Resolve by hand in the PR's own worktree: git fetch origin && git merge origin/<base>" >&2
      return 2 ;;
  esac
  # Ancestry, not mergeStateStatus, decides whether the branch is behind.
  local behind
  behind="$(pr_behind_by "$pr")" || { echo "#$pr: cannot compare head with base" >&2; return 1; }
  if [ "$behind_only" = 1 ]; then echo "$behind"; return 0; fi
  if [ "$behind" = "0" ]; then echo "#$pr: ${state#OPEN } (not behind: 0 base commits missing), nothing to do"; return 0; fi
  if [ "$check_only" = 1 ]; then echo "#$pr: BEHIND by $behind commit(s) (check only)"; return 0; fi

  head="$(gh pr view "$pr" --json headRefOid --jq .headRefOid)" \
    || { echo "#$pr: cannot read the head commit" >&2; return 1; }
  if out="$(gh api -X PUT "repos/$repo/pulls/$pr/update-branch" -f expected_head_sha="$head" 2>&1)"; then
    echo "#$pr: base merged into the branch; CI restarts on the new tip"
    return 0
  fi
  # A merge conflict shows up as DIRTY on the next read; anything else (a
  # permission error, the network, a head that moved) is an API error.
  state="$(pr_state "$pr" 2>/dev/null || true)"
  if [ "${state#OPEN }" = "DIRTY" ]; then
    echo "#$pr: update-branch refused because of a merge conflict" >&2
    return 2
  fi
  echo "#$pr: update-branch failed: $out" >&2
  return 1
}

worst=0
note() { [ "$1" -gt "$worst" ] && worst="$1"; return 0; }

if [ "$1" = "--all" ]; then
  # --limit 1000: gh lists only 30 PRs by default. A failed listing is an error.
  numbers="$(gh pr list --state open --limit 1000 --json number --jq '.[].number')" \
    || { echo "cannot list open PRs" >&2; exit 1; }
  for pr in $numbers; do
    update_one "$pr"; note $?
  done
else
  update_one "$1"; note $?
fi
exit "$worst"
