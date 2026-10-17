# Make One PR Ready

Use this guide for an existing GitHub pull request. Follow the repo's own rules first. The repo's CI workflow defines the checks; its branch rules define required reviews and the allowed merge method.

## 1. Check the PR and Repo

- Confirm the PR number, source branch, base branch, and requested change.
- Read repository instructions and inspect the diff.
- Read CI workflows and find the exact lint, test, and build commands.
- Check which files or interfaces must not change.
- If the repo uses Copilot or another review bot, request it as a reviewer.
- Confirm the requested review actually posts; a successful request or an empty pending-reviewer list is not proof that Copilot reviewed the current commit.
- A bot can be active yet invisible in `reviewRequests`. Copilot posts as `copilot-pull-request-reviewer` and on some repos never appears in that list at all. Check `gh api repos/<owner>/<repo>/pulls/<n>/reviews` instead of concluding the bot is unavailable.
- Settle the merge question now, not at the end: find out whether this repo requires a human approval, and whether the user authorizes an admin bypass if one is needed. See §5.

## 2. Run the Required Checks

Run the same checks CI runs. If a check fails, compare the failure with the base branch:

- Failure caused by this PR: fix it and rerun the check.
- Failure already present on the base branch: record it; do not change unrelated code just to hide it.
- Real bug or unclear contract: ask the user before making a larger change.

Run the full required test suite, not just tests for changed files, when CI expects it.

## 3. Review Every Comment Thread

Start polling immediately after each push, **while CI is still running**. **Every 30 seconds**, check CI status and fetch review threads again, with a real wait between polls rather than one long sleep. Do not wait for CI to finish before reading or fixing new review-bot conversations. Track thread IDs between polls so newly posted findings receive attention; also revisit every unresolved thread, including old comments.

Three rules work together here, and each costs a full CI cycle when ignored:

1. **Poll every 30 seconds** from the push onward.
2. **Do not wait for CI.** A review bot re-scans on its own schedule, so findings land in the middle of a long test job. Work them in parallel.
3. **Cancel the superseded run and push.** CI restarts on the new commit. Waiting out a run you are about to invalidate gains nothing.

Use the paginated helper on every poll:

```bash
bash "<skill-folder>/scripts/pr-threads.sh" <PR-number> --open
```

For each open thread:

1. Check whether the finding is correct and whether this PR caused it.
2. Fix regressions. For a pre-existing issue or false alarm, record the evidence and reason.
3. Reply to the comment with what you checked and changed, if anything.
4. Resolve the thread only after the reply and any required fix are complete.

The helper shows two IDs: use the comment database ID for `pr-reply.sh` and the GraphQL thread ID for `pr-resolve.sh`. A reply does not resolve a thread.

### Push Fixes Without Waiting for Old CI

If resolving a conversation requires another push, prepare and validate the fixes without waiting for the current CI run to finish. Before pushing, cancel the superseded queued or running CI runs for this PR's current head commit. Do not cancel unrelated branch, deployment, or release runs.

In PowerShell, capture the current remote PR head and inspect its runs:

```powershell
$repo = '<owner>/<repo>'
$pr = <PR-number>
$oldHead = gh pr view $pr --repo $repo --json headRefOid --jq '.headRefOid'
gh pr checks $pr --repo $repo --json name,state,link
gh run list --repo $repo --commit $oldHead --limit 100 --json databaseId,headSha,status,event,workflowName,url
```

Replace the placeholders. Use the PR check links to identify all associated CI runs: GitHub can run PR workflows against a synthetic merge commit, which a run-list filter for `$oldHead` will miss. Confirm each candidate belongs to this PR's CI, is `queued`, `in_progress`, or `waiting`, and tests the current PR revision (either `$oldHead` or its associated merge commit). If the list reaches 100 entries, retrieve additional pages before treating it as complete. For each verified superseded run:

```powershell
gh run cancel <run-id> --repo $repo
```

Check the PR head again before cancelling; if another contributor pushed, refresh the run list instead of cancelling from stale data. Do not wait for old CI results or cancellation completion before pushing the validated fixes. If cancellation is denied, report it and proceed with the authorized push; do not bypass permissions.

Confirm the repository's CI triggers will run on the next push or PR synchronization event. For external CI, use its supported cancellation mechanism instead of `gh run cancel`. If replacement CI requires a manual trigger or approval, follow repository policy and report the blocker; do not assume it restarts automatically.

After the push, capture the new head commit, confirm replacement CI starts for that commit, and request a new Copilot review if the repository does not request one automatically. Restart the concurrent CI/thread polling loop immediately. A push invalidates earlier readiness polls: only the latest head's checks and reviews can establish readiness.

### Keep the Branch Current With Its Base

Whenever any PR merges into the base branch, every other open PR is **behind** it. A PR that is behind cannot pass the merge gate: its required checks are still "expected" on the old tip. The refusal can be misleading. For example, even an admin merge may fail with a message about a missing code-owner review, when the real cause is the stale branch.

On every poll, and again right before every merge attempt, check ancestry and read the merge state. `mergeStateStatus` is a merge-gate aggregate, not proof of ancestry: a stale branch can report `BLOCKED` or `CLEAN` instead of `BEHIND`. Use the compare API for ancestry:

```bash
bash "<skill-folder>/scripts/pr-update-branch.sh" <PR-number> --behind-by   # 0 = current; >0 = behind
# raw: gh api repos/<owner>/<repo>/compare/<base>...<head> --jq .behind_by
gh pr view <PR-number> --json mergeStateStatus --jq .mergeStateStatus
```

| State | Meaning | Action |
|---|---|---|
| behind-by > 0 (any state, often `BEHIND`) | The base has moved on | Update the branch (below), then wait for CI on the new tip |
| `DIRTY` | Merge conflict with the base | Merge the base in that PR's own worktree, resolve, test, push. Never pick a side in code you do not own; report it if the PR is someone else's |
| `UNKNOWN` | GitHub is still computing it | Ask again in a few seconds. Do not treat it as up to date |
| behind-by 0, any other state | Current. `BLOCKED` here is the normal review-required gate, which an authorized `--admin` merge bypasses | Carry on with the checks |

Update the branch without touching any local checkout:

```bash
bash "<skill-folder>/scripts/pr-update-branch.sh" <PR-number>   # one PR
bash "<skill-folder>/scripts/pr-update-branch.sh" --all         # every open PR
```

Without the script, `gh api -X PUT repos/<owner>/<repo>/pulls/<PR-number>/update-branch` does the same on GitHub. As a last resort, run `git fetch origin && git merge origin/<base>` in the PR's worktree and push.

Rules that go with this:

- **A merge into the base is a trigger.** When you merge one PR while others are in flight, update all of them at once (`--all`). Do the same when you see another PR merge.
- **A push or an update empties the check list for a short time.** An empty list, or "0 pending", is not green. Wait until the required checks exist and are all complete on the new tip. The merge command stops saying checks are "expected" or "in progress" when they are.
- **Do not retry a refused merge on the same tip more than twice.** A repeated refusal means the cause is the merge state or a missing check, so read `mergeStateStatus` instead of trying again.
- **Cancel only superseded CI runs** before an update, as in the section above. The new tip starts CI by itself.
- Several PRs merging in turn can keep each other behind while CI is slow. Merge the PR whose checks are already green on the current tip first, then update the rest.

### The Poll Loop: Threads First, Never CI Alone

Review-bot conversations arrive on their own schedule, in the middle of a CI run. A PR that waits for CI while a thread is open wastes a full CI cycle and hides the finding. Use one poll that checks, in this order:

1. **Unresolved review threads** (paginated). Any open thread: stop. Cancel this PR's in-flight CI runs (never the review bot's own run), then fix, test, reply, resolve and push. Do not wait for CI.
2. **Branch state**: update a `BEHIND` branch, resolve a `DIRTY` one (see the section above).
3. **CI on the current tip**: pending, failed, or complete. An empty check list is not green.

```bash
bash "<skill-folder>/scripts/pr-watch.sh" <PR-number>              # one poll
bash "<skill-folder>/scripts/pr-watch.sh" --loop <PR-number>       # every 30 seconds, returns when there is something to act on
bash "<skill-folder>/scripts/pr-watch.sh" --cancel-ci <PR-number>  # cancel this PR's queued or running CI for its current head
```

The script prints `threads=N` on every line. Exit 10 means threads are open. Never write a wait loop that reads only CI status. Merge only after CI is green and two clean polls at least 30 seconds apart.

### Round Limit: Park, Do Not Chase

Review bots keep finding things. A PR that fixes every finding can stay open for hours and grow with each fix. Set a limit: **the fifth review is the last one that is acted on by parking**. A round is one submitted review by the review bot. `scripts/pr-watch.sh` counts rounds and prints `round=N/5` on the thread lines; `PR_ROUND_LIMIT` changes the limit.

- **Reviews 1 to 4 (exit 10):** fix, test, reply, resolve and push, as above. Cancel in-flight CI first.
- **From the fifth review on, with threads open (exit 16, PARK):** do not fix them, do not start another round, and do not cancel CI. For each thread, in this order: add an entry to a known-issues file in the repo's backlog folder (thread link, file, the finding, the failure scenario, severity, a suggested fix); push that one documentation commit (CI restarts on it); reply on the thread with the link to the entry; resolve the thread. List the parked items in the PR description under "Known issues (parked after N review rounds)" and say which of them touch money, security or data.
- **Merge** when CI is green on the final tip (the one with the backlog commit), the branch is current, and two clean polls (zero open threads) 30 seconds apart are in. If CI is red, fix only what CI needs.
- The parked entries are the backlog. A later step or a dedicated cleanup PR works them off.

## 4. Check Readiness

Use the helper for one poll:

```bash
bash "<skill-folder>/scripts/pr-ready.sh" <PR-number>
```

A PR is ready only when it is not behind or in conflict with its base, required CI checks pass for the latest head, there are no unresolved review threads, and GitHub reports it can merge. Require two clean polls at least 30 seconds apart for the same head, including one after CI is green. Keep polling for new review threads while CI runs and after it finishes; review bots can post comments later than CI. `pr-ready.sh` first updates a behind branch and refuses a conflicting one, then checks one snapshot only, so the calling workflow must track elapsed time, head changes, and the two clean polls.

A missing human approval is handled in §5; it is not something more polling will clear.

## 5. Merge and Report

**Never approve your own PR.** GitHub rejects self-approval at the platform level. This is not a branch rule or a permission setting, so no flag and no admin right changes it. Do not retry it with different flags.

Merging is a separate question, and which path applies depends on the repo and on the user:

### Path A — no bypass authorized (assume this unless told otherwise)

If a required human approval is missing, stop. Report plainly: CI is green, every thread is resolved, and the named reviewer must approve. Do not reach for `--admin`.

### Path B — the user authorized a bypass and the repo permits one

Some repositories enable an "allow merging without waiting for requirements" ruleset for admins or maintainers. Where that exists **and the user has authorized its use**, finish the job:

```bash
gh pr merge <PR-number> --squash --delete-branch --admin
```

Use the merge method the repo actually allows (`gh api repos/<owner>/<repo>` reports `allow_squash_merge`, `allow_merge_commit`, `allow_rebase_merge`; squash-only is common).

On such a repo, handing back a green, fully-resolved PR that is blocked only on `reviewDecision: REVIEW_REQUIRED` is an incomplete task, not a safe default. **Ask once, then remember the answer** — re-requesting permission the user already granted, on every later PR in the same repo, is a real and common failure.

### Facts about `--admin` worth knowing on either path

- **It grants nothing.** It invokes power the acting account already has. If the account has none, it simply fails.
- **A `write` permission level does not prove it will fail.** A repo-ruleset bypass is granted separately from the collaborator permission level, so `gh api repos/<owner>/<repo>/collaborators/<account>/permission` can report `admin: false` on an account that still merges successfully with `--admin`. Do not use that API reading as a reason to refuse before trying. Run the merge and let the result decide.
- **It is unreliable.** The same flag has been seen to succeed on one clean PR and fail moments later on another, with no confirmed cause. On failure, re-confirm CI, threads, and mergeable are *still* clean right now, then simply retry. Do not escalate to other flags. If it keeps failing after several genuinely clean retries, report that plainly.
- **It never replaces the work.** A bypass skips an approval gate, not §1–§4.

### Reporting

After merging, report the PR link, checks run, review-thread status, merge result, and any known gaps. Note which path was used. Clean up a worktree only when its changes are merged and its contents are no longer needed.