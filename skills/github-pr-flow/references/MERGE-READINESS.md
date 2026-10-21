# Make One PR Ready

For an existing GitHub PR. The repo's own rules come first: its CI workflow defines the checks, its branch rules define required reviews and the merge method, its contributor guide lists protected files.

Scripts below live in `<scripts>` (the repo's `tools/pr-review/` or this skill's `scripts/`). Run them with `bash`.

## 1. Orient and open the review early

- Read the PR diff and the repo's CI workflow; note the exact lint, test and build commands.
- Request the review bot **at once**: `gh pr edit <n> --add-reviewer "@copilot"`. It reviews in parallel with CI, so do not wait for it before anything else; `pr-watch.sh` will not report CLEAN until the bot has looked at the current tip (or `PR_BOT_WAIT_SECS`, default 600, has passed).
- The bot can be active yet invisible in `reviewRequests` (Copilot posts as `copilot-pull-request-reviewer`). Judge it from `gh api repos/<owner>/<repo>/pulls/<n>/reviews`, never from an empty requested-reviewer list.
- Run a local self-review of the diff **before the first push** (a review agent, or read it yourself for regressions, missing consumers, resource cleanup, error paths). Every finding caught here is a bot round and a CI cycle saved.

## 2. Fix CI

Reproduce failures locally with CI's own command. Classify each failure:

- **Caused by this PR:** fix it.
- **Pre-existing** (same on the base branch): record it in a backlog doc; do not rewrite unrelated logic to hide it. A small additive shim is fine if it unblocks compilation.
- **Real bug or unclear contract:** ask the user before a larger change.

Never touch a protected contract to make a check pass. Run the full suite CI runs, not only the touched package.

## 3. The loop

```bash
bash <scripts>/pr-watch.sh --loop <n>      # blocks; prints only when the status changes
```

It checks, in order: unresolved review threads, branch state (a BEHIND branch is updated for you; DIRTY is reported), then CI on the current tip. Never write your own wait loop and never wait on CI alone.

| Exit | Meaning | Do |
|---|---|---|
| 10 | threads open (CI already cancelled) | handle threads, push, call the loop again |
| 11 | branch was behind, updated | call the loop again |
| 12 | DIRTY: conflict with base | merge the base in the PR's worktree, test, push |
| 13 | CI failed on the tip | read the failing log, fix, push |
| 14/15 | still waiting | (the loop keeps waiting) |
| 17 | 9 minutes passed, nothing to act on | call the loop again |
| 16 | PARK: round limit reached, threads open | see below |
| 0 | CLEAN (one poll) | `pr-merge.sh` |

### Handling threads (exit 10)

1. `bash <scripts>/pr-threads.sh <n> --text`: ids, location and the full finding for every open thread, in one call.
2. Decide each: regression (fix), real but pre-existing (backlog entry), or false positive (evidence). Reproduce the claim; do not rubber-stamp or dismiss.
3. **Fix all of them, validate, and push once** (one commit per round). Pushing per thread multiplies CI runs.
4. Reply with evidence: `pr-reply.sh <n> <comment-id> "<text>"` (or `--file`). Then `pr-resolve.sh <thread-id>...` (several ids per call).
5. Call the loop again. A push invalidates earlier readiness.

Cancel superseded CI before the push (`pr-watch.sh --cancel-ci <n>`; the loop already does it on exit 10). CI restarts by itself; never cancel the review bot's own run.

### Round limit: park, do not chase (exit 16)

A round is one submitted review by the bot; `pr-watch.sh` prints `round=N/4` (`PR_ROUND_LIMIT` changes it). Reviews 1 to 3 are fixed. From the 4th, with threads open: do not fix, do not start another round, do not cancel CI.

For each open thread: add an entry to `docs/backlog/<topic>-known-issues.md` (thread link, file, finding, failure scenario, severity, suggested fix). Push that one documentation commit. Reply with the link and resolve. List the parked items in the PR description under "Known issues (parked after N review rounds)", marking any that touch money, security or data. Then `pr-watch.sh --loop` and merge.

## 4. Merge

```bash
bash <scripts>/pr-merge.sh <n>             # add --admin only where the user authorized the bypass
```

It requires two CLEAN polls 30 seconds apart, refuses CHANGES_REQUESTED (exit 21), picks the allowed merge method, makes at most two attempts, and confirms the PR is MERGED from GitHub (not from `gh`'s exit status). Exit 20 means not merged: read `mergeStateStatus` (BEHIND, DIRTY, missing required check) instead of retrying.

An empty check list after a push is not green. A merge into the base leaves every other open PR behind: `pr-update-branch.sh --all`.

`pr-ready.sh <n>` is a one-shot check; it is not part of the normal flow.

## 5. Approval and bypass

- **Never approve your own PR.** GitHub blocks it at the platform level; no flag changes that.
- **No bypass authorized (default):** if a required human approval is missing, stop and report who must approve.
- **Bypass authorized by the user and permitted by the repo:** run `pr-merge.sh <n> --admin`. Handing back a green, fully-resolved PR blocked only on `REVIEW_REQUIRED` is an incomplete task. Ask once, record the answer, do not re-ask on later PRs in the same repo.
- `--admin` grants nothing new, it uses rights the account already has; a `write` permission reading does not prove it will fail, so try it. It is intermittent: `pr-merge.sh` already re-verifies and retries once. It never replaces §2 to §4.

## 6. Report

PR link, checks run, thread status (and anything parked), merge result, known gaps. Clean up a PR worktree with `pr-cleanup.sh <worktree> <branch>` only after the merge; it never discards a file it cannot prove is already on the default branch.
