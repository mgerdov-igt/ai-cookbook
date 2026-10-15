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
- `scripts/`: paginated review-thread tools, the poll loop, branch updater, and safe worktree cleanup

## Use Globally

Install this whole `github-pr-flow/` folder in a personal skills directory supported by your AI tool. Keep `SKILL.md`, `references/`, and `scripts/` together. See the top-level [Skills guide](../README.md) for examples of global skill locations.

Review the helper scripts before using them. The cleanup script removes a worktree and local branch; run it only after the PR is merged and its work is safe to remove.

## How a PR Is Driven

Six working rules (0 to 5). The first five save a full CI cycle each time they are followed:

0. **The poll loop is `scripts/pr-watch.sh`, not your own loop.** It checks unresolved review threads first, then branch state, then CI, so a PR never waits on CI while a conversation is open.
1. **Poll review threads every 30 seconds** from the push onward, with a real wait between polls.
2. **Do not wait for CI to finish.** Review bots re-scan on a schedule independent of CI, so findings arrive mid-run. Work them in parallel.
3. **Cancel the superseded CI runs and push.** CI restarts on the new commit. Cancel only this PR's own runs, never unrelated branch, deployment, or release runs.
4. **Keep the branch current with its base.** When any PR merges, the others are behind and cannot pass the merge gate (the refusal message can blame a missing review). Check `mergeStateStatus` on every poll and before every merge; update a `BEHIND` branch with `scripts/pr-update-branch.sh` (or `--all`), and wait until the new tip's checks exist and finish. An empty check list is not green.
5. **Finish the merge where you are allowed to.** With CI green and every thread resolved, merge using the repo's allowed method. If a required human approval is missing, the default is to stop and report who must approve — unless the user has authorized an admin bypass and the repo permits one, in which case complete the merge rather than handing back a finished PR. Ask once; do not re-ask on every later PR in the same repo.

Never approve your own PR. GitHub blocks self-approval at the platform level and no flag changes that.

Note: `--admin` is optional and environment-dependent. It grants no new rights; it invokes rights the account already holds, and fails harmlessly when it has none. A `write` permission level does not prove it will fail, because a ruleset bypass is granted separately from that level. Details in [Merge readiness](./references/MERGE-READINESS.md) §5.