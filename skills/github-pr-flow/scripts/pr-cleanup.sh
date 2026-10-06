#!/usr/bin/env bash
# Post-merge cleanup for the worktree-per-PR workflow: remove the PR's
# worktree, prune, delete its local branch, then bring the parent tree's
# current branch up to date with the newly-merged main — never resetting
# or checking out anything else in the parent tree.
#
#   bash <skill-folder>/scripts/pr-cleanup.sh <worktree-path> <local-branch>
#
# Run this from inside the PARENT tree (the checkout you want folded back
# into), not from inside the worktree being removed.
#
# Refuses to touch the parent tree if it is dirty. Stop and report instead.
set -euo pipefail

worktree=${1:?usage: pr-cleanup.sh <worktree-path> <local-branch>}
branch=${2:?usage: pr-cleanup.sh <worktree-path> <local-branch>}

# Check the PARENT tree (this cwd) before touching anything destructive —
# a dirty parent must stop cleanup before the worktree/branch are gone,
# not after.
if [ -n "$(git status --porcelain)" ]; then
  echo "STOP: parent tree is dirty — not cleaning up. Nothing removed."
  echo "Commit or stash your changes, then re-run this script."
  exit 1
fi

if git remote get-url origin >/dev/null 2>&1; then
  remote=origin
else
  remote=$(git remote | head -1)
fi
: "${remote:?no git remote configured}"

git fetch "$remote"
remote_url=$(git remote get-url "$remote")
default_branch=$(gh repo view "$remote_url" --json defaultBranchRef -q '.defaultBranchRef.name')

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

current=$(git branch --show-current)

# A fast-forward pull/merge silently overwrites a locally-ignored file (an
# .env, a build artifact) the instant the incoming branch starts tracking
# that same path, or even that same path as a different type (an ignored
# FILE `cache` vs. an incoming tracked DIRECTORY `cache/result.txt`) — git
# does not warn or refuse by default, it just clobbers it, and a plain
# path-string collision check misses the file-vs-directory case entirely.
# `--no-overwrite-ignore` makes git itself refuse (and leave the ignored
# path untouched) instead of us trying to pre-detect every collision shape.
if [ "$current" = "$default_branch" ]; then
  git merge "$remote/$default_branch" --ff-only --no-overwrite-ignore
else
  git merge "$remote/$default_branch" --no-edit --no-overwrite-ignore
fi
