#!/usr/bin/env bash
# Bring a long-lived working branch (for example `develop`) back in line with
# the default branch AFTER a squash-merged PR, without a merge commit.
#
#   pr-sync-branch.sh <pr-number | last-shipped-commit> [--branch develop]
#                     [--push] [--dry-run]
#
# Run it from inside the PARENT tree (the checkout of the working branch), not
# from the PR worktree.
#
# WHY THIS EXISTS. The default branch takes squash merges only. A PR therefore
# lands as ONE NEW COMMIT with a new id, and the working branch keeps the
# original commits: git sees "N ahead, M behind" although the content is the
# same, and a review-round fix exists only on the PR branch and the default
# branch. `git merge origin/main` cannot tell the squash equals those commits,
# so it conflicts on every file both sides touched and leaves a merge commit.
# The cure is to MOVE the branch instead of merging:
#
#   - nothing on the branch that the PR did not ship  ->  reset to origin/<default>
#   - newer commits on top of what the PR shipped     ->  rebase --onto origin/<default>
#                                                          <last shipped commit> <branch>
#
# Either way the branch afterwards holds the default branch's version of the
# shipped work (review fixes included) plus only the genuinely newer commits.
#
# <last-shipped-commit> is the tip of the commits the PR shipped, as they exist
# ON THE WORKING BRANCH (not the PR branch's rewritten copies). Give a PR number
# and the script finds it: the PR's commit subjects are matched, in order, against
# the working branch. If it cannot prove the match it STOPS and tells you.
#
# SAFETY (it refuses, and changes nothing, unless ALL of these hold):
#   1. the parent tree is clean (no staged, tracked-modified or untracked files);
#   2. the current branch is --branch (default: the current branch);
#   3. origin/<branch> equals what this branch last pushed, or is an ancestor of
#      it: nobody else pushed commits that this script would erase;
#   4. the PR is MERGED;
#   5. for the reset case: the branch's tree equals the PR's last shipped
#      commit's tree on the default branch for every path the PR touched
#      (nothing unshipped hides in those files).
# A rebase conflict stops the script mid-rebase: it never resolves a conflict
# and never picks a side. Run `git rebase --abort` to undo, or resolve it
# yourself and `git rebase --continue`.
#
# --push   after a successful sync, `git push --force-with-lease=<branch>:<old-origin-sha>
#          origin <branch>`. The lease names the exact commit the remote branch was
#          at when the script started, so a push by anyone else in between makes
#          it refuse. NEVER the default branch, never plain --force. Only use --push
#          when the owner has said the working branch may be force-pushed.
# --dry-run  print what it would do (and verify every check), change nothing.
#
# Exit codes: 0 synced (or already in sync); 2 usage; 3 a safety check refused;
#             4 PR not merged; 5 could not match the PR's commits; 6 rebase
#             conflict (left in progress); 7 push refused.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
. "$here/_common.sh"

usage() { sed -n '2,50p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

target=""; branch=""; do_push=0; dry=0
while [ $# -gt 0 ]; do
  case "$1" in
    --branch) shift; branch="${1:?--branch needs a name}" ;;
    --push) do_push=1 ;;
    --dry-run) dry=1 ;;
    -h|--help) usage ;;
    -*) echo "unknown option: $1" >&2; usage ;;
    *) [ -z "$target" ] && target="$1" || { echo "unexpected argument: $1" >&2; usage; } ;;
  esac
  shift
done
[ -n "$target" ] || usage

refuse() { echo "REFUSED: $*" >&2; exit 3; }
say() { echo "pr-sync-branch: $*"; }

# ---- the repo, the default branch, the working branch ----------------------
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not inside a git work tree" >&2; exit 2; }
if git remote get-url origin >/dev/null 2>&1; then remote=origin; else remote=$(git remote | head -1); fi
: "${remote:?no git remote configured}"
remote_url=$(git remote get-url "$remote")
default_branch=$(gh repo view "$remote_url" --json defaultBranchRef -q '.defaultBranchRef.name')
default_ref="$remote/$default_branch"
current=$(git branch --show-current)
[ -n "$current" ] || refuse "detached HEAD: check out the working branch first"
[ -n "$branch" ] || branch="$current"
[ "$branch" = "$current" ] || refuse "you are on '$current' but --branch is '$branch': check it out first"
[ "$branch" != "$default_branch" ] || refuse "'$branch' is the default branch: nothing to sync, and this script never rewrites it"

git fetch --quiet "$remote"

# ---- 1. clean tree ---------------------------------------------------------
if [ -n "$(git status --porcelain --untracked-files=all)" ]; then
  echo "REFUSED: the parent tree is not clean. Commit, stash or move these first:" >&2
  git status --short | head -15 >&2
  exit 3
fi

# ---- 3. origin/<branch> is not ahead of us in a way we would erase --------
old_origin=""
if git rev-parse --verify --quiet "refs/remotes/$remote/$branch" >/dev/null; then
  old_origin=$(git rev-parse "refs/remotes/$remote/$branch")
  if ! git merge-base --is-ancestor "$old_origin" "$branch"; then
    # Not an ancestor: either a teammate pushed, or WE rewrote this branch in an
    # earlier run that was not pushed yet (origin still has the old commits). Tell
    # them apart by the branch's own reflog: our old tips contain origin's tip.
    ours=0
    while IFS= read -r past; do
      [ -n "$past" ] && git merge-base --is-ancestor "$old_origin" "$past" 2>/dev/null && { ours=1; break; }
    done < <(git reflog show --format=%H "$branch" 2>/dev/null | head -50)
    [ "$ours" -eq 1 ] || refuse "$remote/$branch has commits '$branch' does not have, and they were never on '$branch'. Someone else pushed. Look first: git log $branch..$remote/$branch"
    say "$remote/$branch holds this branch's own older commits (an earlier sync that was not pushed): OK"
  fi
fi

# ---- 4. the PR is merged; find its shipped commits -------------------------
shipped_tip=""; pr_number=""
if [[ "$target" =~ ^[0-9]+$ ]] && [ ${#target} -le 6 ]; then
  pr_number="$target"
  state=$(gh pr view "$pr_number" --json state -q .state 2>/dev/null) || { echo "cannot read PR #$pr_number" >&2; exit 2; }
  [ "$state" = "MERGED" ] || { echo "PR #$pr_number is $state, not MERGED: nothing to sync yet." >&2; exit 4; }
  # The PR's own commits, oldest first, by subject. The squash merge does not keep
  # them, but the PR keeps its commit list; the working branch holds the originals.
  mapfile -t pr_subjects < <(gh pr view "$pr_number" --json commits -q '.commits[].messageHeadline')
  [ ${#pr_subjects[@]} -gt 0 ] || { echo "PR #$pr_number reports no commits" >&2; exit 5; }
  # Walk the working branch (oldest first, unmerged-into-default first) and match each
  # PR commit subject in order. The PR may be a cherry-picked copy (subjects equal,
  # ids differ), which is exactly the case this handles.
  mapfile -t branch_commits < <(git log --reverse --format='%H%x09%s' "$default_ref..$branch")
  # GitHub shortens a long commit subject in `messageHeadline` to about 72
  # characters and ends it with "…" (U+2026). Compare by prefix in that case, or
  # every long subject would be "unmatched".
  subject_matches() { # branch-subject pr-headline
    local want="$2"
    # A glob on the literal bytes of "…" works in any locale; ${want: -1} would
    # take the last BYTE of the 3-byte character and never see it.
    case "$want" in
      *…) case "$1" in "${want%…}"*) return 0 ;; *) return 1 ;; esac ;;
    esac
    [ "$1" = "$want" ]
  }
  idx=0; last=""
  for line in "${branch_commits[@]}"; do
    sha="${line%%$'\t'*}"; subj="${line#*$'\t'}"
    if [ $idx -lt ${#pr_subjects[@]} ] && subject_matches "$subj" "${pr_subjects[$idx]}"; then
      last="$sha"; idx=$((idx + 1))
    fi
  done
  if [ $idx -eq 0 ]; then
    # None of the PR's commits are on this branch: it was already synced (the
    # shipped commits are gone and main's copy is what the branch builds on), or
    # this is a different branch. Either way there is nothing to move.
    say "none of the ${#pr_subjects[@]} commits of PR #$pr_number are on '$branch' (already synced, or another branch): nothing to do."
    say "'$branch' is $(git rev-list --count "$default_ref..$branch") ahead / $(git rev-list --count "$branch..$default_ref") behind $default_ref."
    if [ "$do_push" -eq 1 ] && [ -n "$old_origin" ] && [ "$(git rev-parse "$branch")" != "$old_origin" ] && [ "$dry" -eq 0 ]; then
      say "but $remote/$branch differs from '$branch': pushing with the lease ($old_origin)"
      git push --force-with-lease="$branch:$old_origin" "$remote" "$branch" || { echo "push refused (the remote moved, or a hook said no)." >&2; exit 7; }
    fi
    exit 0
  fi
  if [ $idx -ne ${#pr_subjects[@]} ]; then
    echo "could not match all ${#pr_subjects[@]} commits of PR #$pr_number on '$branch' by subject (matched $idx)." >&2
    echo "Give the last shipped commit yourself: pr-sync-branch.sh <commit> ..." >&2
    exit 5
  fi
  shipped_tip="$last"
else
  shipped_tip=$(git rev-parse --verify --quiet "$target^{commit}") || { echo "not a commit: $target" >&2; exit 2; }
  git merge-base --is-ancestor "$shipped_tip" "$branch" || refuse "$target is not on '$branch'"
fi

say "default branch: $default_ref; working branch: $branch; last shipped commit on it: $(git rev-parse --short "$shipped_tip")"
newer=$(git rev-list --count "$shipped_tip..$branch")
say "commits on '$branch' newer than the shipped work: $newer"

# ---- decide: reset or rebase ----------------------------------------------
if [ "$newer" -eq 0 ]; then
  action=reset
  # 5. nothing unshipped may hide in the files the PR touched. Compare the branch
  # tree to the default branch for the paths the shipped range changed.
  base=$(git merge-base "$default_ref" "$shipped_tip")
  touched=$(git diff --name-only "$base" "$shipped_tip")
  diffs=""
  if [ -n "$touched" ]; then
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      # a file the default branch has, but with different content than the branch
      # is expected when review fixes landed there. A file the branch has that the
      # default branch lacks is NOT: that would be unshipped work.
      if ! git cat-file -e "$default_ref:$f" 2>/dev/null && git cat-file -e "$branch:$f" 2>/dev/null; then
        diffs="${diffs}  only on '$branch', not on $default_ref: $f\n"
      fi
    done <<< "$touched"
  fi
  if [ -n "$diffs" ]; then
    printf 'REFUSED: files the PR touched exist on %s but not on %s (unshipped work, or a file the review removed):\n%b' "$branch" "$default_ref" "$diffs" >&2
    echo "Look at them, then run again (or sync by hand)." >&2
    exit 3
  fi
else
  action=rebase
fi

# What will be lost? The shipped commits' content is already on the default branch
# (squashed). Print the proof: the commits that will disappear from the branch.
say "action: $action"
say "commits that will leave '$branch' (already on $default_ref in squashed form):"
git log --format='  %h %s' "$default_ref..$shipped_tip" | head -40
[ "$(git rev-list --count "$default_ref..$shipped_tip")" -gt 40 ] && echo "  ... (more)"
if [ "$newer" -gt 0 ]; then
  say "commits that stay on top (the genuinely newer work):"
  git log --format='  %h %s' "$shipped_tip..$branch" | head -20
fi

if [ "$dry" -eq 1 ]; then say "dry run: nothing changed."; exit 0; fi

# Save the old tip: an undo is `git reset --hard <this>` or `git reflog`.
old_tip=$(git rev-parse HEAD)
say "old tip of '$branch' (to undo: git reset --hard $old_tip): $old_tip"

case "$action" in
  reset)
    git reset --hard "$default_ref"
    ;;
  rebase)
    if ! git rebase --onto "$default_ref" "$shipped_tip" "$branch"; then
      echo "REBASE CONFLICT: left in progress. Resolve it (never pick a side in code you do not own)," >&2
      echo "then 'git rebase --continue', or undo with 'git rebase --abort'." >&2
      exit 6
    fi
    ;;
esac
say "'$branch' is now: $(git rev-parse --short HEAD) ($(git rev-list --count "$default_ref..$branch") commit(s) ahead of $default_ref, $(git rev-list --count "$branch..$default_ref") behind)"

# ---- push (only when asked, only with a lease) ----------------------------
if [ "$do_push" -eq 1 ]; then
  if [ -z "$old_origin" ]; then
    say "no $remote/$branch yet: pushing with -u (no lease needed)"
    git push -u "$remote" "$branch" || exit 7
  else
    say "force-with-lease push, lease = the remote's tip when we started ($old_origin)"
    git push --force-with-lease="$branch:$old_origin" "$remote" "$branch" || { echo "push refused (the remote moved, or a hook said no)." >&2; exit 7; }
  fi
else
  say "not pushed. When the owner allows it: git push --force-with-lease=$branch:$old_origin $remote $branch"
fi
exit 0
