# Split a Large Branch

Use this when a long-lived branch has too many files or unrelated changes for one useful review. The goal is a series of smaller PRs that each pass the repo's checks. Do not change product behavior as part of the split.

## 1. Measure and Inspect

- Fetch the source branch and target branch, usually `main`.
- Record the source branch's current commit so the input does not move during the split.
- Compare the source branch with the merge base and target branch. Count changed files and lines.
- Check which target-branch files changed after the branches split. Reconcile those paths by hand; do not overwrite newer target-branch work.
- Read package manifests, project rules, and CI workflows to learn dependencies, protected files, and required checks.

## 2. Plan the PRs

Make a short table with each PR's paths, dependencies, size, and status. Order the PRs so that shared libraries and tools land before the apps that use them. Keep code and its tests in the same PR.

Use the repo's review limits and bot behavior to choose a size. Smaller is easier to review, but do not split packages or interfaces in a way that breaks builds. Docs-only changes can often go first. Treat config, fixtures, generated files, and public interfaces according to the repo's rules.

## 3. Create Each PR from the Target Branch

Use a separate worktree for each PR when possible. This keeps the user's working branch untouched. Start each PR from the latest target branch, then bring in only that PR's paths or commits.

When commits mix several changes, copy the selected paths from the recorded source commit instead of replaying the whole branch history. Handle deleted files explicitly. Inspect `git status --short --ignored` before staging; stage only files planned for that PR.

Do not take target-branch conflict files from the source branch automatically. Compare both versions and keep both sides' work where needed.

## 4. Test, Review, and Merge Each PR

For each PR:

1. Run the checks that apply to the changed paths, then the full checks required by the repo.
2. Open the PR against the target branch.
3. Follow [Merge readiness](./MERGE-READINESS.md) to get checks green and resolve every review thread.
4. Merge only when required reviews and repo rules allow it.
5. Update the table and start the next PR from the latest target branch.

If a split exposes a bug or requires changing behavior, stop that change. Record it for a separate PR unless the user approves expanding scope.

## 5. Finish Safely

Compare the target branch with the recorded source commit. Resolve any remaining paths before closing the split. If the source branch will stay in use, bring the target branch back into it only when the source worktree is clean. Do not force-push or resolve conflicts by guessing.

If the user started with uncommitted work, follow the [GitHub PR Flow skill](../SKILL.md) safety rules. Do not switch, reset, or stash away changes from the active worktree.