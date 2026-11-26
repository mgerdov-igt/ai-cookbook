---
name: pre-push
description: "Check work before it is pushed or a PR is opened. Scan the branch for secrets, conflict markers and leftovers, read the diff as a strict reviewer, run the analyzer and the tests CI will run, compare unexpected failures with the default branch, rebuild before any smoke test, and list what is uncommitted. Use for \"pre-push\", \"check before I push\", \"is this ready\", or before opening a PR. Never commits, pushes or opens a PR. Not for reviewing someone else's PR (use github-pr-flow)."
---

# Pre-push

Make the work ready to push, then report. This skill checks and fixes; it never commits, pushes, stashes, resets, switches branches or opens a PR. The user does that next.

## When to use

- "pre-push", "check this before I push", "is this ready for a PR?"
- Right before [pr-to-main](../pr-to-main/SKILL.md), `git push` or opening a PR.
- After a large or scripted change, to catch what it broke.

## When not to use

- Reviewing a PR that already exists: use [github-pr-flow](../github-pr-flow/SKILL.md).
- Writing the commit: use [git-commit](../git-commit/SKILL.md).
- A one-line docs fix: do steps 1 and 2 only and say so.

## Needs

Git and Python 3.8+ (`python3`; on Windows `python` or `py -3`). The repo's own build and test tools for steps 3 to 6.

## First: the repo's own checks win

Read the repo's `AGENTS.md`, `CONTRIBUTING`, CI workflow and test docs. Look for a `## Pre-push checks` section. If it exists, use its commands and rules instead of the defaults below. If it does not, discover the commands and say which you used. See [Project checks](references/PROJECT-CHECKS.md) for the section to add, and how to discover commands.

## Rules

- **Never** commit, push, stash, reset, rebase, or switch branches in the user's folder. Other agents may share it.
- **Never** report a check as passed when you did not run it. Write "not run" and why.
- Put logs and scratch files in the system temp folder, in a folder named `pre-push`, never in the repo. Delete it at the end.
- Files you did not change and cannot explain: leave them alone and list them.
- Change code with your editing tool, not with shell redirects or scripted rewrites. After any scripted bulk edit, re-read the result and run the analyzer.

## Steps

### 1. Scan

```
python3 "<skill-folder>/scripts/prepush_scan.py"
```

Replace `<skill-folder>` with the folder that holds this `SKILL.md`. It prints the branch, how far ahead or behind the default branch you are, who wrote the commits, every changed file (committed, staged, edited or new), and hygiene hits.

- On the default branch: stop and say so.
- Behind the default branch: say so; the user decides when to update.
- Commits by other authors: review them too, and say they are not yours.
- Any **secret-looking** or **conflict marker** hit: stop and fix before anything else. A real secret in a commit needs a history clean-up, so tell the user before they push.
- Sensitive file names, large files, debug or focus leftovers: fix or explain each one.
- Add `--json` for scripts and `--base <ref>` for another base.

### 2. Review the diff

Read the diff against the base (`git diff <base>` shows committed, staged and edited changes). Read it as a strict reviewer who has not seen the task. Fix what you find:

- A bug in the changed lines, and in the callers of anything whose signature changed.
- A changed contract (interface, schema, API, config key): every implementer, fake, mock, fixture and doc that names it.
- New reads of config, environment or files: code and tests that run without them.
- Duplicated copies that must stay equal (mirrors, generated files, translations).
- A new behaviour with no test, or a test that cannot fail.
- Dead code, leftover debugging, and docs the change makes wrong.

End the step with a short list: what you changed because of the review.

### 3. Static checks

Run the analyzer, linter and formatter check for every package or folder with a changed file. Fix every error and warning your change causes. Warnings that were already there are not yours; mention them only if asked.

### 4. Tests CI will run

Run what CI runs for this change, on the right file set. See the gotcha below before you reuse a CI script.

- Run each test command from the folder the repo says (many monorepos need the package folder).
- A failure you caused: fix it, rerun that file, then the whole suite.
- A failure that looks flaky: rerun that file once before you call it real.
- If CI would run everything only because of a file no test reads, say which file and skip the local full run.

### 5. A failure you did not expect: is it yours?

Find out whether the default branch fails the same way without touching this folder. Follow [Smoke test and baseline](references/SMOKE-AND-BASELINE.md): a throwaway worktree of the default branch, only that test, then remove it. Report each failure as "also fails on <default>" or "new".

### 6. Smoke test, only if the change is visible or runs on a device

**Rebuild before every smoke test.** Check the build is newer than the source (`python3 "<skill-folder>/scripts/prepush_scan.py" --build <build-output>` prints FRESH or STALE), rebuild if not, and say which build and commit you tested. The routine is in [Smoke test and baseline](references/SMOKE-AND-BASELINE.md).

### 7. Report

Short and plain, in this order:

1. **Result:** ready to push, or not ready and why.
2. **Fixed by this review:** the list from step 2.
3. **Checks:** scan clean or what it found; static checks (which folders); tests (which suites and counts); baseline comparison (none needed, or each failure); smoke (which fresh build and commit, or not needed). Mark each "not run" if it was not.
4. **Not yours:** commits by other authors and files you left alone.
5. **Uncommitted:** every changed or new file from `git status`.
6. **Next:** one or two options, such as [pr-to-main](../pr-to-main/SKILL.md) or `git push`.

Clean up the temp folder and any throwaway worktree first.

## Gotchas

- **Never run a CI test-selection script as it is in a work folder.** Many CI scripts diff the pull request's merge commit (`HEAD^1..HEAD`). In a work folder that is only your last commit, with nothing uncommitted, so it picks the wrong tests, often all of them. Ask the same rule about the right files (the base to the working tree), or run the broader set.
- **A green local run on a stale base is not green.** If the branch is behind, the tests ran against old code.
- **A secret never goes in the report.** The scan prints where, never the value. Do not paste it, even to explain.
- **A scripted edit that "worked" may not have.** Backslashes, quoting and named arguments are the usual casualties. Re-read the file.
- **A smoke test on an old build tests the old code.** Rebuild first, every time.
- **"It passed" needs a number.** Say how many tests ran. A suite that ran zero tests passes.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `no base to compare with` | `git fetch origin`, or pass `--base <ref>`. |
| Scan says the default branch is the current one | You are on `main`. Switch to a work branch first; do not do it in the user's folder without asking. |
| `python3` not found on Windows | Use `python` or `py -3`. |
| Hygiene hit that is a false alarm | Say so in the report and name the file and line. Do not edit the pattern list. |
| No analyzer or test command can be found | Ask once, or mark the step "not run: no command found". |

## Verify the skill itself

```
python3 "<skill-folder>/scripts/test_prepush_scan.py"
```

Success: `OK` after 18 tests (about a minute: each test builds a throwaway repo in the temp folder and touches nothing else).
