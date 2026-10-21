---
name: github-pr-flow
description: Help make a GitHub pull request ready to merge, or split a large branch into smaller pull requests. Use when asked to prepare, review, split, or land GitHub PRs. Requires Git, authenticated gh, Bash, and Python 3 for the helper scripts.
---

# GitHub Pull Request Flow

- One PR already exists: follow [Merge readiness](references/MERGE-READINESS.md).
- A large branch needs several PRs: follow [Split a large branch](references/SPLIT-LARGE-BRANCH.md).

Read the repo's `AGENTS.md`, contribution guide, CI workflow and any PR playbook first. Its test commands, protected files, required reviewers and merge rules win over this skill.

## Rules

- Never switch branches, force-push or discard changes in the user's current worktree while a PR is in flight. Work in a separate worktree (see the `pr-to-main` skill, or the snapshot steps in the split guide). Do not use `git stash push` to move the user's changes.
- Never approve your own PR (GitHub blocks it). Never merge without the CI-green and zero-open-threads bar; `--admin` skips an approval gate only where the user authorized it.
- Use the scripts, not hand-written `gh`/GraphQL: they paginate, print both id spaces, and encode the polling rules.

## Scripts

Run from inside the repo: `bash "<skill-folder>/scripts/<name>"`. On Windows use Git Bash (not WSL). Need `gh` and Python 3 (`pr-watch.sh`, `pr-update-branch.sh` need only `gh`).

| Script | Use |
|---|---|
| `pr-watch.sh --loop <n>` | The only wait loop. Threads first, then branch state, then CI; quiet until something needs action; exit 10 = threads open, 16 = park, 17 = call again. |
| `pr-threads.sh <n> --text` | Open threads with ids and full text, one call. |
| `pr-reply.sh`, `pr-resolve.sh` | Reply (REST comment id) then resolve (GraphQL thread id). |
| `pr-merge.sh <n> [--admin]` | Two clean polls, merge, verify MERGED. |
| `pr-update-branch.sh <n>` or `--all` | Bring a BEHIND branch up to date (API, no checkout). |
| `pr-cleanup.sh <worktree> <branch>` | After merge: remove the worktree, delete the branch, fold the default branch into the parent tree. Never discards a file it cannot prove is already merged. |
| `pr-ready.sh <n>` | One-shot readiness check (not part of the normal flow). |

Each script's header comment is its usage doc.

## Efficiency rules (each saves a CI cycle or many tokens)

1. Request the review bot the moment the PR opens; self-review the diff before the first push.
2. Do not wait for CI: findings land mid-run. `pr-watch.sh --loop` handles it.
3. Fix every open thread, then push once per round. Cancel superseded CI first; CI restarts by itself.
4. The 4th bot review is parked, not fixed (`PR_ROUND_LIMIT`, default 4).
5. A review bot can be invisible in `reviewRequests`; check `gh api repos/<owner>/<repo>/pulls/<n>/reviews`.
6. Keep logs and large outputs out of the conversation: read only the failing step.
