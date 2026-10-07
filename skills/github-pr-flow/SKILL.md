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

Poll for new review threads **every 30 seconds** while CI is still running, not only after it finishes. When review fixes require a push, cancel only the superseded PR CI runs and push without waiting for their results. Confirm replacement CI starts for the new head and resume polling immediately. Follow the scoped cancellation and readiness steps in [Merge readiness](references/MERGE-READINESS.md).

A review bot may be invisible in the PR's requested-reviewer list even when it is active. GitHub Copilot, for example, posts as `copilot-pull-request-reviewer` but may never appear in `reviewRequests`. Check the reviews endpoint (`gh api repos/<owner>/<repo>/pulls/<n>/reviews`) before concluding that no bot reviewed.

## Finishing the PR

Never approve your own PR. GitHub blocks self-approval at the platform level, so no permission or flag changes it.

How the last step ends depends on the repository and on what the user authorized:

- **Default, and the safe assumption:** when a required human approval is still missing, stop and report who must approve. Do not bypass it.
- **When the user has authorized a bypass and the repo permits one:** finish the job. Merge with the repo's allowed method plus `--admin`, rather than handing back a PR that is otherwise done. Ask once, record the answer, and do not re-ask on every later PR in the same repo — repeatedly requesting permission that was already granted wastes the user's time.

Both paths require the real quality bar first: CI green, every thread resolved, two clean polls. A bypass skips an approval gate, never the work.

See [Merge readiness](references/MERGE-READINESS.md) §5 for how to tell which path applies and what `--admin` can and cannot do.

## References

- [Merge readiness](references/MERGE-READINESS.md)
- [Split a large branch](references/SPLIT-LARGE-BRANCH.md)
- [Helper scripts](README.md)