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

## 4. Check Readiness

Use the helper for one poll:

```bash
bash "<skill-folder>/scripts/pr-ready.sh" <PR-number>
```

A PR is ready only when required CI checks pass for the latest head, there are no unresolved review threads, and GitHub reports it can merge. Require two clean polls at least 30 seconds apart for the same head, including one after CI is green. Keep polling for new review threads while CI runs and after it finishes; review bots can post comments later than CI. `pr-ready.sh` checks one snapshot only, so the calling workflow must track elapsed time, head changes, and the two clean polls.

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