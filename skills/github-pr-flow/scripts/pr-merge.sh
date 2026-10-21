#!/usr/bin/env bash
# Merge a PR that is ready: two clean polls 30 seconds apart, then the merge, then
# proof that it merged. This replaces the "two clean polls", "retry --admin at most
# twice" and "verify it actually merged" prose with one command.
#
#   pr-merge.sh <pr>            merge with the repo's allowed method (squash preferred)
#   pr-merge.sh <pr> --admin    same, plus --admin when the only blocker is a required
#                               human review (REVIEW_REQUIRED). Use it only where the
#                               user has authorized the bypass.
#
# Steps:
#   1. pr-watch.sh poll: must report CLEAN (exit 0), else this script exits with
#      that code and its output, and you act on it exactly as for pr-watch.sh.
#   2. Refuses CHANGES_REQUESTED (exit 21): a reviewer asked for changes.
#   3. Waits PR_MERGE_GAP_SECS (default 30), then a second pr-watch.sh poll must
#      also be CLEAN.
#   4. Merges (at most 2 attempts, a CLEAN poll before the second). The result is
#      checked with `gh pr view`, not with the exit status: `gh pr merge` can print
#      an error about the local branch or a worktree even though GitHub merged.
#
# Exit codes:
#   0   merged (or already merged)
#   20  not merged after the attempts; the last error is printed
#   21  CHANGES_REQUESTED
#   other  the pr-watch.sh code of the poll that was not clean (10, 11, 12, 13, 14, 15, 16)
#
# After it returns 0, run pr-cleanup.sh if the PR had its own worktree.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pr="${1:?usage: pr-merge.sh <pr> [--admin]}"
use_admin=0
[ "${2:-}" = "--admin" ] && use_admin=1
GAP="${PR_MERGE_GAP_SECS:-30}"

command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }

state_of() { gh pr view "$pr" --json state --jq .state; }

clean_poll() {
  local out rc
  out="$(bash "$SCRIPT_DIR/pr-watch.sh" "$pr")"; rc=$?
  printf '%s\n' "$out"
  case "$out" in *" MERGED"*) return 100 ;; esac
  return "$rc"
}

clean_poll; rc=$?
[ "$rc" -eq 100 ] && exit 0
[ "$rc" -eq 0 ] || exit "$rc"

decision="$(gh pr view "$pr" --json reviewDecision --jq '.reviewDecision // ""')" || exit 1
if [ "$decision" = "CHANGES_REQUESTED" ]; then
  echo "#$pr reviewDecision=CHANGES_REQUESTED: a reviewer asked for changes; not merging"; exit 21
fi

sleep "$GAP"
clean_poll; rc=$?
[ "$rc" -eq 100 ] && exit 0
[ "$rc" -eq 0 ] || exit "$rc"

repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)" || exit 1
method="$(gh api "repos/$repo" --jq 'if .allow_squash_merge then "--squash" elif .allow_merge_commit then "--merge" else "--rebase" end')" || exit 1

last=""
for attempt in 1 2; do
  flags="$method --delete-branch"
  if [ "$use_admin" -eq 1 ] && [ "$decision" = "REVIEW_REQUIRED" ]; then flags="$flags --admin"; fi
  echo "#$pr merge attempt $attempt: gh pr merge $flags"
  # shellcheck disable=SC2086
  last="$(gh pr merge "$pr" $flags 2>&1)"
  sleep 3
  if [ "$(state_of)" = "MERGED" ]; then
    echo "#$pr MERGED"
    exit 0
  fi
  [ "$attempt" -eq 2 ] && break
  # A refusal on the same tip does not change by retrying; re-check it is still clean first.
  sleep "$GAP"
  clean_poll; rc=$?
  [ "$rc" -eq 100 ] && exit 0
  [ "$rc" -eq 0 ] || { printf '%s\n' "$last"; exit "$rc"; }
done
printf '%s\n' "$last"
echo "#$pr NOT merged after 2 attempts. Read mergeStateStatus (BEHIND, DIRTY, a missing required check) instead of retrying."
exit 20
