# Smoke test and baseline

Two routines the `pre-push` skill points to. Both keep the user's folder untouched.

## Baseline: does the default branch fail the same way?

Use it when a test fails and you do not know if you caused it. Do not use `git stash`, `git checkout` or `git reset` in the user's folder.

1. Pick a scratch folder: `<temp>/pre-push/baseline`.
2. Make a worktree of the default branch there, detached:
   `git worktree add --detach "<temp>/pre-push/baseline" origin/main`
3. Prepare it the way the repo says. A fresh worktree has none of the ignored files (installed packages, generated assets, local config). If the repo has a prepare script or a setup page, run it; otherwise install dependencies there.
4. Run **only** the failing test or suite there.
5. Remove it: `git worktree remove --force "<temp>/pre-push/baseline"`.
6. Report: "also fails on origin/main" (not caused by this change) or "new" (caused by it).

If you cannot prepare the worktree, say the baseline was not checked. Do not guess.

## Smoke test: rebuild first, every time

A smoke test on an old build shows what the code no longer does, and sends people to fix something that is already fixed.

1. **Ask whether the build is older than the source.** If the repo has its own freshness check, use it. Otherwise ask the skill's script, which compares the build's time with the newest source file git knows (tracked and new; not tests, docs or Markdown):

   ```
   python3 "<skill-folder>/scripts/prepush_scan.py" --build <build-output-file-or-folder>
   ```

   It prints `FRESH` or `STALE` with the file that is newer, and exits 0, 1 or 2 (no build found).
2. **Rebuild** with the repo's build command. Stop the running app first if the build replaces its file.
3. **Ask again.** It must now say fresh.
4. **Write down what you tested:** the build path, `git rev-parse --short HEAD`, and how many files are uncommitted. Say this in the report.
5. **Test** with the repo's own driver or a person's steps. Prefer a way that reads the screen or state over guessing.
6. **Clean up:** stop what you started, put back any setting or file the test changed, and keep screenshots only in the temp folder.

For a **device or emulator** build, the install can finish after the tool says "started". An old app on the device may still answer. Prove the install: read the package's last-update time before and after, or check a file you know changed. Name the device; never take "the first one" when two are connected.

For a **config-only** change that the app reads at start, a rebuild may not be needed, but a restart is.
