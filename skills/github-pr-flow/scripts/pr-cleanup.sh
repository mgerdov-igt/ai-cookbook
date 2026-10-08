#!/usr/bin/env bash
# Post-merge cleanup for the worktree-per-PR workflow: remove the PR's
# worktree, prune, delete its local branch, then bring the parent tree's
# current branch up to date with the newly-merged main — never resetting
# or checking out anything else in the parent tree beyond what's verified
# below.
#
#   bash <skill-folder>/scripts/pr-cleanup.sh <worktree-path> <local-branch>
#
# Run this from inside the PARENT tree (the checkout you want folded back
# into), not from inside the worktree being removed.
#
# A dirty parent tree does NOT automatically stop this script. Workflows
# that snapshot the parent tree's pending changes into a separate worktree
# without ever committing them in the parent itself routinely leave the
# parent dirty after a merge — with files that are now stale duplicates of
# what's on the default branch (sometimes OLDER duplicates, since review
# fixes land on the branch but never flow back here). This script verifies
# that before touching any of the parent tree's working copy or index —
# the worktree removal and local branch delete above are always safe (they
# only ever affect the already-merged PR branch, never the parent's own
# checkout) and happen first regardless. Every dirty path (working tree AND
# index, since a path can have staged content that differs from its
# working copy) is checked against the default branch, content-for-content
# (ignoring only line-ending differences). If all of it is a confirmed-
# stale duplicate, the parent tree is reset clean to match the default
# branch. If anything dirty is NOT found there, it might be real unique
# work that never shipped — this script stops without resetting and names
# exactly which file(s) it's unsure about.
set -euo pipefail

worktree=${1:?usage: pr-cleanup.sh <worktree-path> <local-branch>}
branch=${2:?usage: pr-cleanup.sh <worktree-path> <local-branch>}

if git remote get-url origin >/dev/null 2>&1; then
  remote=origin
else
  remote=$(git remote | head -1)
fi
: "${remote:?no git remote configured}"

git fetch "$remote"
remote_url=$(git remote get-url "$remote")
default_branch=$(gh repo view "$remote_url" --json defaultBranchRef -q '.defaultBranchRef.name')
remote_ref="$remote/$default_branch"

if ! git show-ref --verify --quiet "refs/heads/$branch"; then
  echo "STOP: local branch $branch does not exist. Nothing removed."
  exit 1
fi

pr_json=$(gh pr view "$branch" --json state,headRefName,headRefOid) || {
  echo "STOP: cannot find a PR for local branch $branch. Nothing removed."
  exit 1
}
pr_state=$(echo "$pr_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('state', ''))")
pr_head=$(echo "$pr_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('headRefName', ''))")
pr_head_oid=$(echo "$pr_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('headRefOid', ''))")
local_head_oid=$(git rev-parse "refs/heads/$branch")
if [ "$pr_state" != "MERGED" ] || [ "$pr_head" != "$branch" ] || [ "$local_head_oid" != "$pr_head_oid" ]; then
  echo "STOP: branch $branch is not the unchanged head of a merged PR. Nothing removed."
  exit 1
fi

if [ -d "$worktree" ]; then
  ignored=$(git -C "$worktree" ls-files --others --ignored --exclude-standard)
  if [ -n "$ignored" ]; then
    echo "STOP: $worktree has git-ignored files that 'git worktree remove' would delete:"
    echo "$ignored"
    echo "Move anything you need out of the worktree, then re-run this script."
    exit 1
  fi
  git worktree remove "$worktree"
else
  echo "note: $worktree does not exist, skipping worktree remove"
fi
git worktree prune

if git show-ref --verify --quiet "refs/heads/$branch"; then
  git branch -D "$branch"
else
  echo "note: local branch $branch does not exist, skipping branch delete"
fi

# Every dirty path (working tree AND index) must be a confirmed-stale
# duplicate of what's now on $remote_ref before we touch anything.
# `--strip-trailing-cr` ignores only line-ending differences (e.g. a CRLF
# vs LF rewrite that happened upstream during review) — those don't count
# as "unique", they're the same content. Indentation and other whitespace
# changes ARE treated as real differences, since they're semantic in
# formats like YAML and Python. Mode/type (executable bit, symlink) is
# compared too, since identical blob bytes under a changed mode is still a
# real, unique change. A path deleted locally (X or Y == 'D') is treated as
# confirmed-stale when the remote also lacks it (the merged PR did the same
# deletion) — remote-absence otherwise means "unique addition", not "stale".
status_lines=$(git status --porcelain)
unique=""

remote_mode_for() { git ls-tree "${remote_ref}" -- "$1" 2>/dev/null | awk '{print $1}'; }
index_mode_for() { git ls-files -s -- "$1" 2>/dev/null | awk '{print $1}'; }
worktree_mode_for() {
  if [ -L "$1" ]; then echo 120000
  elif [ -x "$1" ]; then echo 100755
  elif [ -e "$1" ]; then echo 100644
  fi
}
# Content match for the worktree copy of $1 against $remote_ref, given its
# mode. A symlink's "content" is its stored target text, not whatever the
# link happens to resolve to — `diff` on the pathname would follow it and
# compare the TARGET FILE's bytes instead, so symlinks are special-cased via
# `readlink` rather than handed to `diff`. `--` guards every path operand
# (including inside process substitution) against one starting with `-`.
worktree_content_matches() {
  local f="$1" mode="$2"
  if [ "$mode" = "120000" ]; then
    # Compare raw bytes via process substitution, never `$(...)` — command
    # substitution strips trailing newlines, and newline is a legal byte in
    # a symlink target, so a target differing only by a trailing newline
    # would otherwise be misclassified as an identical match. `readlink -n`
    # (not the default, newline-terminated form) emits exactly the target
    # bytes, nothing added.
    cmp -s <(git show "${remote_ref}:${f}" 2>/dev/null) <(readlink -n -- "$f")
  else
    diff -q --strip-trailing-cr -- <(git show "${remote_ref}:${f}" 2>/dev/null) "$f" >/dev/null 2>&1
  fi
}
index_content_matches() {
  local f="$1"
  diff -q --strip-trailing-cr -- <(git show "${remote_ref}:${f}" 2>/dev/null) <(git show ":${f}" 2>/dev/null) >/dev/null 2>&1
}

if [ -n "$status_lines" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    x=${line:0:1}
    y=${line:1:1}
    f=${line:3}

    remote_mode=$(remote_mode_for "$f")

    # Index layer (staged content relative to HEAD).
    if [ "$x" = "D" ]; then
      [ -n "$remote_mode" ] && unique="${unique}  DELETED locally but present on ${remote_ref} (staged): ${f}\n"
    elif [ "$x" != " " ] && [ "$x" != "?" ]; then
      if [ -z "$remote_mode" ]; then
        unique="${unique}  NEW (not on ${remote_ref} at all, staged): ${f}\n"
      elif [ "$(index_mode_for "$f")" != "$remote_mode" ] || ! index_content_matches "$f"; then
        unique="${unique}  DIFFERS from ${remote_ref} (staged): ${f}\n"
      fi
    fi

    # Worktree layer (relative to index), including fully-untracked files.
    if [ "$x" = "?" ] && [ "$y" = "?" ]; then
      if [ -z "$remote_mode" ]; then
        unique="${unique}  NEW (not on ${remote_ref} at all): ${f}\n"
      else
        wt_mode=$(worktree_mode_for "$f")
        if [ "$wt_mode" != "$remote_mode" ] || ! worktree_content_matches "$f" "$wt_mode"; then
          unique="${unique}  DIFFERS from ${remote_ref} (untracked): ${f}\n"
        fi
      fi
    elif [ "$y" = "D" ]; then
      [ -n "$remote_mode" ] && unique="${unique}  DELETED locally but present on ${remote_ref} (working tree): ${f}\n"
    elif [ "$y" != " " ]; then
      if [ -z "$remote_mode" ]; then
        unique="${unique}  NEW (not on ${remote_ref} at all, working tree): ${f}\n"
      else
        wt_mode=$(worktree_mode_for "$f")
        if [ "$wt_mode" != "$remote_mode" ] || ! worktree_content_matches "$f" "$wt_mode"; then
          unique="${unique}  DIFFERS from ${remote_ref} (working tree): ${f}\n"
        fi
      fi
    fi
  done <<<"$status_lines"
fi

if [ -n "$unique" ]; then
  echo "STOP: parent tree is dirty, and the file(s) below are not confirmed"
  echo "stale duplicates of ${remote_ref} — they may be unique work that"
  echo "never made it into the shipped PR. Not resetting anything."
  printf '%b' "$unique"
  echo "Review these yourself (commit/ship them, or discard if you're sure"
  echo "they're not needed), then re-run this script."
  exit 1
fi

current=$(git branch --show-current)

if [ -n "$status_lines" ]; then
  echo "parent tree was dirty but every file is a confirmed-stale duplicate"
  echo "of ${remote_ref} — clearing it before syncing with ${default_branch}."
  # Reset to HEAD (not $remote_ref) so this only discards the confirmed-
  # stale dirty changes — it never rewrites commits unique to a non-default
  # branch. Folding in the default branch's new content happens below, the
  # same way as the already-clean case.
  git reset --hard HEAD
  git clean -fd
fi

# A fast-forward pull/merge silently overwrites a locally-ignored file (an
# .env, a build artifact) the instant the incoming branch starts tracking
# that same path, or even that same path as a different type (an ignored
# FILE `cache` vs. an incoming tracked DIRECTORY `cache/result.txt`) — git
# does not warn or refuse by default, it just clobbers it, and a plain
# path-string collision check misses the file-vs-directory case entirely.
# `--no-overwrite-ignore` makes git itself refuse (and leave the ignored
# path untouched) instead of us trying to pre-detect every collision shape.
if [ "$current" = "$default_branch" ]; then
  git merge "$remote_ref" --ff-only --no-overwrite-ignore
else
  git merge "$remote_ref" --no-edit --no-overwrite-ignore
fi

echo "parent tree is now clean and in sync with ${remote_ref}."
