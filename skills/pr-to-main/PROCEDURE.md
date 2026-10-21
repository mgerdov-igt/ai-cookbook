# pr-to-main: procedure

You ship every pending change in `<REPO_ROOT>` to the default branch as a reviewed, merged PR, end to end, autonomously. Take as many turns as needed; nobody waits turn by turn.

**Hard rule:** never mutate `<REPO_ROOT>` (working tree, index, current branch) until Phase 5, and then only after proving the dirty content is already on the new default branch. The end state is a clean `<REPO_ROOT>` in sync with `main`.

Keep your own context small: read only failing log steps, never whole CI logs or whole files you do not need; use the scripts' compact output.

**Scripts.** Use `<REPO_ROOT>/tools/pr-review/` if it exists (it travels with the repo, also present in the worktree); otherwise `~/.copilot/skills/github-pr-flow/scripts/` or `~/.claude/skills/github-pr-flow/scripts/`. Call them as `bash <scripts>/<name>`. Call this directory `<scripts>` below. Each script's header comment is its usage doc.

**Temp files** go under `$TEMP/pr-to-main-<ship-branch>/` only (never in `<REPO_ROOT>`, never in the worktree), deleted in Phase 6.

## Phase 0: Orient (read-only)

- Default branch: `git symbolic-ref refs/remotes/origin/HEAD`, else `main`. Note the current branch `<user-branch>`.
- `git status --short`, and `git log --oneline @{u}..HEAD` if an upstream is set.
- If on the default branch with a clean tree and nothing ahead of origin: report "nothing to ship" and stop.

## Phase 1: Snapshot into a worktree (copy, not move)

1. Name `<ship-branch>` from the real theme of the change (read the diff and commit messages): readable kebab-case, never a timestamp, different from `<user-branch>`.
2. If `<REPO_ROOT>` has uncommitted changes (tracked or untracked): `git stash create` (never `stash push`), save the SHA as `<stash-sha>`. Untracked files are not in a stash commit; copy those into the worktree afterwards by hand.
3. `git worktree add ../<repo-name>--<ship-branch> -b <ship-branch>` (replace `/` by `-` in the folder name only).
4. In the worktree: `git stash apply <stash-sha>`.
5. Verify `git -C <REPO_ROOT> status --short` and `branch --show-current` are exactly as before. If not, stop and report.
6. Message the spawning session once: `<REPO_ROOT>` is untouched and safe to use; shipping continues in the worktree.

## Phase 2: Commit, push, open the PR (worktree only)

- Read the whole diff once as a reviewer would (regressions, missing consumers, resource cleanup, error paths, leftovers) and fix what you find **before** pushing: each finding caught here saves a review round and a CI cycle.
- Split into logical commits when the change separates naturally; write real messages from the diff, ending with the trailer `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`.
- `git push -u origin <ship-branch>`; reuse an existing PR (`gh pr list --head <ship-branch>`) or `gh pr create --base <default> --title ... --body ...`.
- **Request the review bot immediately, always:** `gh pr edit <n> --add-reviewer "@copilot"`. Only an actual API/permission failure excuses skipping it. The bot may be invisible in `reviewRequests` (it posts as `copilot-pull-request-reviewer`); judge it by `gh api repos/<owner>/<repo>/pulls/<n>/reviews`.
- Do not wait for the review before continuing: it runs in parallel with CI, and `pr-watch.sh` will not report CLEAN until the bot has looked at the current tip.

## Phase 3: Drive to merge-ready

If the repo has `docs/PR-MERGE-READINESS-PLAYBOOK.md`, read it (its core is short; its separate gotchas file only when something fails) and follow it: its protected-contract list and CI commands override anything generic here. Without one, apply the same method: reproduce CI locally, classify each failure as caused-by-this-PR (fix) or pre-existing (document, do not fix unless trivial).

The loop is one blocking call: `bash <scripts>/pr-watch.sh --loop <n>`. Never write your own wait loop; never wait on CI alone. Act on its exit code:

- **10** threads open (CI already cancelled): `pr-threads.sh <n> --text`; decide each thread on its merits (regression: fix; real but pre-existing: backlog entry; false positive: evidence); **fix all of them, validate locally, push once**; `pr-reply.sh` with evidence, `pr-resolve.sh` (several ids per call); loop again.
- **11** branch was behind and was updated: loop again. **12** DIRTY: merge the base in the worktree, resolve (never pick a side in code you do not own), test, push.
- **13** CI failed on the tip: read only the failing step's log, fix, `pr-watch.sh --cancel-ci <n>` if another run is still going, push.
- **17** nothing to act on yet: call the loop again.
- **16** PARK (round limit, default 4 bot reviews; `PR_ROUND_LIMIT`): do not fix, do not cancel CI. Add one entry per open thread to `docs/backlog/<topic>-known-issues.md` (thread link, file, finding, failure scenario, severity, suggested fix); push that one documentation commit; reply with the link and resolve each thread; list the parked items in the PR description under "Known issues (parked after N review rounds)", flagging any that touch money, security or data; then loop again and merge.
- **0** CLEAN: go to Phase 4.

Judgment calls: never touch a protected contract to make a check pass; only additive shims under CI pressure, never rewrites of untested business logic. If a real non-trivial pre-existing bug surfaces, message the spawning session (fix now / skip and document / investigate) and keep going on everything else. Never approve your own PR.

## Phase 4: Merge

`bash <scripts>/pr-merge.sh <n> --admin`

This skill carries a standing, pre-authorized bypass for the required-human-approval gate; it is used only through `pr-merge.sh`, which first requires two clean polls 30 seconds apart (CI green, zero open threads, branch current, bot has reviewed the tip). Do not stop to ask for permission, and do not hand back a green PR unmerged. A `write` permission reading is not grounds to refuse: run it and let the result decide. Exit codes: 0 merged; 20 not merged (read `mergeStateStatus`, do not hammer retries); 21 CHANGES_REQUESTED (do not bypass); anything else is a `pr-watch.sh` code, handle it as in Phase 3.

## Phase 5 and 6: Fold main back, clean up

From `<REPO_ROOT>`: `bash <scripts>/pr-cleanup.sh <worktree-path> <ship-branch>`. It removes the worktree and local branch, fetches, proves every dirty file in `<REPO_ROOT>` is already on the new default branch (content, mode and symlink target; CRLF-only differences ignored), then resets the tree and folds the default branch into `<user-branch>`. It stops and names files it cannot prove, and exits non-zero (for example 3 = a folder still left on disk). A non-zero exit is not done: read it, fix what is safe, or report it. Never add `--force` yourself, never reset by hand on unproven content, never auto-resolve a merge conflict.

Without the script: `git fetch origin`, compare every dirty file against `origin/<default>` yourself, reset and merge only if all are proven duplicates, then `git worktree remove` and `git branch -d`.

Verify `git worktree list` and the parent folder no longer show the worktree; delete `$TEMP/pr-to-main-<ship-branch>/`.

## Phase 7: Final report (short)

State: `<REPO_ROOT>` untouched until Phase 5; PR number/URL; one line per shipped commit; merged or why not (with parked known issues, if any); Phase 5 outcome, exactly one of **Clean and in sync** / **Stopped on unique content** (name the files) / **Stopped on a merge conflict**; **Leftovers** (worktree, branch, temp folder: removed or exact path and why). List, but do not delete, any other sibling worktree whose branch is already merged.
