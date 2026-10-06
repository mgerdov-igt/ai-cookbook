# Make One PR Ready

Use this guide for an existing GitHub pull request. Follow the repo's own rules first. The repo's CI workflow defines the checks; its branch rules define required reviews and the allowed merge method.

## 1. Check the PR and Repo

- Confirm the PR number, source branch, base branch, and requested change.
- Read repository instructions and inspect the diff.
- Read CI workflows and find the exact lint, test, and build commands.
- Check which files or interfaces must not change.
- If the repo uses Copilot or another review bot, request it as a reviewer.
- Confirm the requested review actually posts; a successful request or an empty pending-reviewer list is not proof that Copilot reviewed the current commit.

## 2. Run the Required Checks

Run the same checks CI runs. If a check fails, compare the failure with the base branch:

- Failure caused by this PR: fix it and rerun the check.
- Failure already present on the base branch: record it; do not change unrelated code just to hide it.
- Real bug or unclear contract: ask the user before making a larger change.

Run the full required test suite, not just tests for changed files, when CI expects it.

## 3. Review Every Comment Thread

Start polling immediately after each push, **while CI is still running**. Every 60 seconds, check CI status and fetch review threads again. Do not wait for CI to finish before reading or fixing new Copilot conversations. Track thread IDs between polls so newly posted findings receive attention; also revisit every unresolved thread, including old comments.

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

A PR is ready only when required CI checks pass for the latest head, there are no unresolved review threads, GitHub reports it can merge, and any required human approval is present. Require two clean polls at least 60 seconds apart for the same head, including one after CI is green. Keep polling for new Copilot threads while CI runs and after it finishes; review bots can post comments later than CI. `pr-ready.sh` checks one snapshot only, so the calling workflow must track elapsed time, head changes, and the two clean polls.

Do not approve your own PR. If a human approval is still required, stop and report who must approve. Use an admin bypass only when the user explicitly authorizes it and repo policy allows it; this skill does not grant bypass permission.

## 5. Merge and Report

Use the merge method allowed by the repo. After merging, report the PR link, checks run, review-thread status, merge result, and any known gaps. Clean up a worktree only when its changes are merged and its contents are no longer needed.