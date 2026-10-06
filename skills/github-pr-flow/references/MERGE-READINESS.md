# Make One PR Ready

Use this guide for an existing GitHub pull request. Follow the repo's own rules first. The repo's CI workflow defines the checks; its branch rules define required reviews and the allowed merge method.

## 1. Check the PR and Repo

- Confirm the PR number, source branch, base branch, and requested change.
- Read repository instructions and inspect the diff.
- Read CI workflows and find the exact lint, test, and build commands.
- Check which files or interfaces must not change.
- If the repo uses Copilot or another review bot, request it as a reviewer.

## 2. Run the Required Checks

Run the same checks CI runs. If a check fails, compare the failure with the base branch:

- Failure caused by this PR: fix it and rerun the check.
- Failure already present on the base branch: record it; do not change unrelated code just to hide it.
- Real bug or unclear contract: ask the user before making a larger change.

Run the full required test suite, not just tests for changed files, when CI expects it.

## 3. Review Every Comment Thread

List all review threads, including old comments. Use the paginated helper:

```bash
bash "<skill-folder>/scripts/pr-threads.sh" <PR-number> --open
```

For each open thread:

1. Check whether the finding is correct and whether this PR caused it.
2. Fix regressions. For a pre-existing issue or false alarm, record the evidence and reason.
3. Reply to the comment with what you checked and changed, if anything.
4. Resolve the thread only after the reply and any required fix are complete.

The helper shows two IDs: use the comment database ID for `pr-reply.sh` and the GraphQL thread ID for `pr-resolve.sh`. A reply does not resolve a thread.

## 4. Check Readiness

Use the helper for one poll:

```bash
bash "<skill-folder>/scripts/pr-ready.sh" <PR-number>
```

A PR is ready only when required CI checks pass, there are no unresolved review threads, GitHub reports it can merge, and any required human approval is present. Poll again after each push and after CI finishes; review bots can post comments later than CI.

Do not approve your own PR. If a human approval is still required, stop and report who must approve. Use an admin bypass only when the user explicitly authorizes it and repo policy allows it; this skill does not grant bypass permission.

## 5. Merge and Report

Use the merge method allowed by the repo. After merging, report the PR link, checks run, review-thread status, merge result, and any known gaps. Clean up a worktree only when its changes are merged and its contents are no longer needed.