---
name: github-pr-flow
description: Help make a GitHub pull request ready to merge, or split a large branch into smaller pull requests. Use when asked to prepare, review, split, or land GitHub PRs. Requires Git, authenticated gh, Bash, and Python 3 for the helper scripts.
---

# GitHub Pull Request Flow

Use this skill to prepare a pull request (PR) for review, clear review comments, check that it can merge, or split a large branch into smaller PRs.

## Choose a Guide

- One PR already exists: use [Merge readiness](references/MERGE-READINESS.md).
- A large branch needs several PRs: use [Split a large branch](references/SPLIT-LARGE-BRANCH.md).

Read the repository's `AGENTS.md`, contribution guide, CI workflow, and any PR playbooks first. Use that repository's test commands, protected-file list, required reviewers, and merge rules. Do not assume they match this cookbook.

## Protect the Active Worktree

- Do not switch branches, reset, force-push, or discard changes in the user's current worktree.
- Do not use `git stash push` to move the user's changes. If pending local work must be copied to another worktree, use the separate-worktree snapshot steps in [Split a large branch](references/SPLIT-LARGE-BRANCH.md).
- Before merging updates into a worktree, confirm it is clean. Stop if it is dirty or a merge has conflicts; do not resolve the user's work by guessing.

## Helper Scripts

The scripts in `scripts/` use the current directory to find the GitHub repo. Run them from inside that repo. On Windows, use Git Bash or WSL. Requirements are Git, `gh`, Python 3, and Bash.

```bash
bash "<skill-folder>/scripts/pr-threads.sh" <PR-number> --open
bash "<skill-folder>/scripts/pr-ready.sh" <PR-number>
```

Replace `<skill-folder>` with this skill's installed folder. Review a script before running it. `pr-reply.sh` posts a GitHub comment, `pr-resolve.sh` resolves review threads, and `pr-cleanup.sh` removes a worktree and local branch; use those only at the matching step in the guides. Cleanup is optional and must not delete unmerged work.

Never approve your own PR. Do not use an admin merge or skip a required approval unless the user explicitly authorizes it and the repository permits it.

## References

- [Merge readiness](references/MERGE-READINESS.md)
- [Split a large branch](references/SPLIT-LARGE-BRANCH.md)
- [Helper scripts](README.md)