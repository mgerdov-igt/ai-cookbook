# GitHub PR Flow Skill

This folder contains a tool-neutral skill and helper scripts for GitHub pull requests.

## Requirements

- Git
- GitHub CLI (`gh`), signed in with permission to read and update the PR
- Bash and Python 3 for the helper scripts (Git Bash or WSL on Windows)

The scripts find the repository from the current directory. Run them from inside the repo. They do not contain a fixed owner or repo name.

## Files

- [SKILL.md](./SKILL.md): how to choose and run the PR workflows
- [Merge readiness](./references/MERGE-READINESS.md): checks and review-thread steps for one PR
- [Split a large branch](./references/SPLIT-LARGE-BRANCH.md): plan and land a stack of smaller PRs
- `scripts/`: paginated review-thread tools and safe worktree cleanup

## Use Globally

Install this whole `github-pr-flow/` folder in a personal skills directory supported by your AI tool. Keep `SKILL.md`, `references/`, and `scripts/` together. See the top-level [Skills guide](../README.md) for examples of global skill locations.

Review the helper scripts before using them. The cleanup script removes a worktree and local branch; run it only after the PR is merged and its work is safe to remove.