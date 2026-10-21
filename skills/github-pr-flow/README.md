# GitHub PR Flow Skill

Tool-neutral skill and helper scripts for GitHub pull requests. **This folder is the canonical source** of the PR scripts: copies in other repos and in personal skill folders are generated from it with `sync.sh`.

## Requirements

Git, `gh` (signed in), Bash and Python 3 (Git Bash or WSL on Windows). Scripts find the repo from the current directory; nothing is hardcoded.

## Files

- [SKILL.md](./SKILL.md): rules and script table
- [Merge readiness](./references/MERGE-READINESS.md): the loop, thread handling, round limit, merge
- [Split a large branch](./references/SPLIT-LARGE-BRANCH.md)
- `scripts/`: `pr-watch.sh` (poll loop), `pr-threads.sh`, `pr-reply.sh`, `pr-resolve.sh`, `pr-merge.sh`, `pr-update-branch.sh`, `pr-cleanup.sh`, `pr-ready.sh`
- `sync.sh`: keeps every copy identical to this folder

Companion skill [pr-to-main](../pr-to-main/SKILL.md) ships pending work end to end from a separate worktree.

## How a PR is driven

1. Open the PR, request the review bot at once, self-review the diff before the first push.
2. `pr-watch.sh --loop <n>`: threads first, then branch state, then CI. Quiet until there is something to act on; exit 17 only means "call it again".
3. Exit 10: `pr-threads.sh <n> --text`, fix everything, push once, reply and resolve.
4. The 4th bot review is parked in a backlog doc, not fixed (`PR_ROUND_LIMIT`, default 4); exit 16.
5. `pr-merge.sh <n>` (add `--admin` only where the user authorized the bypass): two clean polls, merge, verify.
6. `pr-cleanup.sh <worktree> <branch>` after the merge.

Never approve your own PR. `--admin` uses rights the account already has; it fails harmlessly otherwise.

## Tuning (environment variables)

| Variable | Default | Meaning |
|---|---|---|
| `PR_ROUND_LIMIT` | 4 | the Nth bot review with open threads is parked |
| `PR_REVIEW_BOT` | `copilot-pull-request-reviewer` | login of the review bot |
| `PR_BOT_WAIT_SECS` | 600 | how long after a push CLEAN waits for the bot to review the tip (0 disables) |
| `PR_WATCH_MAX_SECS` | 540 | `--loop` returns 17 after this long |
| `PR_MERGE_GAP_SECS` | 30 | gap between the two clean polls of `pr-merge.sh` |

## Keeping copies in sync

```bash
bash sync.sh --check --repo <path-to-repo> --global   # report drift
bash sync.sh --apply --repo <path-to-repo> --global   # copy; --repo may repeat
```

`--repo` updates `<repo>/tools/pr-review/*.sh`; `--global` installs this skill and `pr-to-main` into `~/.claude/skills` and `~/.copilot/skills`. Review the scripts before running them: `pr-cleanup.sh` removes a worktree and local branch, and never deletes unmerged work.
