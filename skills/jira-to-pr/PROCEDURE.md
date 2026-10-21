# jira-to-pr: procedure

One Jira issue `<KEY>` → clarified requirements → approved plan → implementation → one PR → merged → Jira status updated. Phases 0 to 2 run in the user's session; Phases 3 to 6a run in one background agent; Phase 6b is back in the session.

## Conventions

- **`<jira>`** is `python3 <REPO_ROOT>/tools/jira/jira.py` if that file exists, else `python3 ~/.copilot/skills/jira-flow/scripts/jira.py` (or `~/.claude/...`). Always run it from `<REPO_ROOT>`. Its usage text (no arguments) is the command reference; the `jira-flow` SKILL.md has the rules.
- **`<scripts>`** is the PR tooling: `<REPO_ROOT>/tools/pr-review/` if present, else `~/.copilot/skills/github-pr-flow/scripts/`. Run each as `bash <scripts>/<name>`.
- **Work folder:** `<REPO_ROOT>/.jira-flow/<KEY>/` (gitignored). It holds `digest.md`, `attachments/`, `state.json`, `questions.md`, `plan.md`, comment drafts and `resolve-fields.json`. Sub-agents get **paths** to these files, never pasted content.
- **`state.json`:** `{"key", "profile", "phase", "branch", "worktree", "pr", "updated"}`. `phase` is one of `intake`, `waiting_answers`, `planning`, `waiting_approval`, `approved`, `implementing`, `pr_open`, `merged`, `closed`, `stopped`. Update it at every phase change; resuming means reading it.
- **Jira writes:** run each write once without `--yes` and check the `PLAN` line, then run it with `--yes`. The user's request to run this workflow authorises the writes listed in this procedure, and only those. If the tool says read-only mode, carry on and list every skipped write in the final report.
- **Comments:** few, each edited in place with `upsert-comment --marker <m> --title "<Title>" --file <draft.md>`. Markers: `questions`, `plan`, then `fixed` (root cause, the fix and local test results, for the reviewer), `dev-integration` (PR open, CI and review progress) and `qa` (the merge outcome for QA). A story uses `status` instead of the last three. Write Markdown; it is converted to wiki markup. No emoji. Mention a person (`[~username]`) only when you ask them something. Never quote tokens, terminal or retailer IDs, or other secrets from logs.
- **Status moves:** the issue follows the work. Each move is `<jira> walk <KEY> --event <e>` (plus `--fields-file .jira-flow/<KEY>/resolve-fields.json` from `fixed` on). The profile's `status` map decides the target; an unmapped event does nothing. For a TIR (`defect` profile in VTA/POA):

  | Event | When | Status |
  |---|---|---|
  | `started` | Phase 0, the user picked the issue | Assigned (if not yet), then In Progress |
  | `fixed` | Phase 3, fix committed and unit tests pass | Resolved, Ready for Unit Test/Review/Inspection |
  | `pr_opened` | Phase 4, PR open, CI and Copilot review running | Ready for Dev Integration |
  | `merged` | Phase 6a, PR merged | Ready for QA Test |

  A walk that stops ("stuck": the next move belongs to another role; or a missing field) does not stop the work: note it in `state.json` as `jira_stuck`, carry on, and report it.
- **Profile:** `digest` prints the issue's profile. `story` means requirements are acceptance criteria (AC). `defect` (and variants such as `defect-dev`) means requirements are repro steps, actual result and the expected result. Neither (Epic, Task, unknown type): stop and say the unit of work must be one Story or one Bug/TIR.

## Phase 0: Intake (session)

0. **No key given ("next ticket"):** pick candidates in this order:
   1. `<jira> pending`: anything waiting on you resumes first.
   2. Your in-flight work: `.jira-flow/*/state.json` with a phase other than `closed` or `stopped`.
   3. `<jira> mine` with the request's filters. It lists your own issues first, then unassigned ones, at most 30 (`--max N`).

      | The user says | Flag |
      |---|---|
      | project name or key ("Terminal App", "VTA") | `--project "<as said>"` |
      | release / PI / iteration / fix version ("Project Iteration 3", "PI 3") | `--pi "<as said>"` |
      | "a story", "a TIR", "a defect" | `--type <word>`: a config profile name or issue-type words |
      | a status ("in development", "reopened") | `--status "<part of the name>"` |
      | a topic ("about printing") | `--text "<words>"` |
      | anything else | `--jql "<clause>"` |
      | "including other people's" | `--all` |

      With no PI given, ask for it if the repo docs name a current one, otherwise list without it. A line like `fix version: 'PI 3' -> 'Product Increment 3'` shows what the loose name matched: repeat it to the user. If `mine` stops with "matches several" or "matches nothing", ask; do not retry with guesses.
   
   Skip Epics, Tasks and anything not matched by a profile. Prefer, in order: issues already assigned to you; `Reopened` defects; defects by severity; stories already `In Development` or `Assigned to Sprint`. Run `brief` on the top few to judge whether the AC are clear enough. Present the top three and let the user choose. Then continue with that key.
1. `<jira> whoami`, then `<jira> digest <KEY>` (add `--window HH:MM-HH:MM` when the description gives a time window). Read `digest.md` and the reduced or preview companions of the attachments, not the raw files. If attachments say `NOT DOWNLOADED`, ask the user to save them into `.jira-flow/<KEY>/attachments/` and re-run `digest`.
2. **Ownership:** assigned to someone else → stop and report. Unassigned → `<jira> assign <KEY>`.
3. **Re-entry:**
   - Status `Reopened`, or a resolved remote link to an earlier PR: this is a fix that failed QA. Read the `NEW` comments and attachments and the earlier PR (`gh pr view <n>`), and treat the old fix as a suspect. Always use a new branch and a new PR.
   - `state.json` exists: resume at its phase.
4. `<jira> walk <KEY> --event started` (dry run, then `--yes`): Assigned if it was not, then In Progress.
5. Write `state.json` with `phase: intake`.

## Phase 1: Clarify (session)

Read the code areas the issue touches: targeted search, not whole trees. List only questions whose answer would change the implementation or the tests. Number them Q1..Qn, each with your proposed default answer.

- **story:** missing or ambiguous AC, edge cases, config versus code (in a config-driven repo, ask whether the behaviour belongs in config), UI text, out-of-scope items.
- **defect:** the issue rarely states an **expected result**. Always state the expected behaviour you infer and ask for confirmation. Also ask for missing build, environment or logs. If the steps do not reproduce from the code reading, say so and offer a hypothesis. "Cannot reproduce" is a question to ask, never an automatic close.
- **Size:** if the work clearly does not fit one reviewable PR (several independent features, or several modules each with their own AC), propose a split into sub-tasks with one line each. Stop after posting it; the user or PO creates the sub-tasks.

Ask the user in the session (`ask_user`), offering two choices: answer now, or post the questions to Jira for the reporter or PO. If they choose Jira:
1. Write `questions.md`.
2. Run `upsert-comment <KEY> --marker questions --title "Questions before planning"`.
3. Set `phase: waiting_answers` and stop with a one-line resume hint.

On resume, `<jira> replies <KEY> --marker questions` prints only the new answers. No questions at all is fine: say so and move on.

## Phase 2: Plan and approval (session)

Write `plan.md`:

- **story:** AC → implementation steps → tests or evidence per AC, plus files and modules touched, risks, and what is out of scope.
- **defect:**
  - Root-cause hypothesis with evidence (reduced-log lines with their `@L` numbers, code path).
  - A **failing test first** that reproduces the defect.
  - The fix.
  - Regression test(s).
  - Risk and impact on other paths.
  - **Resolution fields:** draft `resolve-fields.json` now, because the issue is resolved mid-run (`fixed`), not after the merge. It is a flat object keyed by field name and must fill every field in the profile's `required_fields` on the way to Ready for Dev Integration (`walk` refuses to start otherwise; `"?"` counts as missing). For VTA/POA TIRs (as filled on POA-44717):
    - Resolution Description: the intended fix in one or two sentences (Phase 3 rewrites it from the real fix).
    - Repair Code: one of Code, Configuration, Data, Hardware, Procedure, Requirement.
    - Defect Origination Activity: one of Requirements Analysis, Design, Code and Unit Test, Baseline, Planning.
    - Modules Affected: the packages the plan touches.
    - Release Considerations, Test Considerations: one line each, or `none`.
    - Fix Version/s: ask the user. Code Branch: the planned branch name.
    - Resolution: `Fixed`.
    - Evaluation Notes (optional): the root cause.

    Show the fields with the plan; approving the plan approves them. `<jira> transitions <KEY> --fields` (on an issue in In Progress) shows any extra screen field.

Show the plan to the user. Post a short version (15 lines at most: approach, steps, tests, "reply *approved* to proceed") with `upsert-comment --marker plan --title "Implementation plan"`.

**Approval** is either the user approving in the session, or `<jira> replies <KEY> --marker plan` printing `APPROVED`. That means a reply posted after the plan comment's last edit that starts with *approved*, *lgtm* or *go ahead*. If neither has happened yet, set `phase: waiting_approval` and stop. If the plan changes after feedback, edit the plan comment; that resets the approval clock.

After approval:
1. Run `<jira> walk <KEY> --event plan_approved`.
2. Set `phase: approved`.
3. Hand Phases 3 to 6a to one background agent (see SKILL.md).

## Phase 3: Implement (background agent)

1. Default branch `<default>` comes from `git symbolic-ref refs/remotes/origin/HEAD`. Branch `<KEY>-<short-slug>`. Worktree: `git fetch origin && git worktree add ../<repo-name>--<KEY> -b <branch> origin/<default>`. Never touch the user's folder or branch. Save `branch` and `worktree` in `state.json` and set `phase: implementing`.
2. Implement `plan.md` step by step in the worktree, applying `plan-auto-work`'s method: verify each step before the next, and record real evidence. Follow the repo's own instructions (AGENTS.md, playbooks, protected contracts).
3. **defect:** commit the failing test first and show that it fails; then commit the fix and show that the test passes. Both results go in the PR body.
4. Commit messages start with `<KEY>: `. Run the repo's local checks (analyze, affected tests) before pushing.
5. **defect, fix done and unit tests green:** in `resolve-fields.json`, rewrite only the free-text fields from the real change (Resolution Description, Modules Affected, Evaluation Notes, and Unit Test Results with the test names and the local result). Keep the user-approved choices (Repair Code, Origination, Fix Version). Then `<jira> walk <KEY> --event fixed --fields-file .jira-flow/<KEY>/resolve-fields.json` (dry run, then `--yes`) → Resolved, Ready for Unit Test/Review/Inspection.
   Then the **fix comment** (`--marker fixed --title "Fixed, unit tests pass"`), written for the reviewer. Fill it from the real commits and test output, not from the plan; write "none" rather than leaving out a line:
   ```markdown
   Root cause: <what was wrong and why, one or two sentences; file/function if useful>.
   Fix: <what changed, one or two sentences>. Modules: <Modules Affected>.
   Regression test: `<test name>` - failed before the fix (`<short failure line>`), passes now.
   Unit tests: `<command>` - <N passed, 0 failed>. Analyze/lint: <clean, or the warnings left>.
   Branch: `<branch>`, commits `<sha>` (test) and `<sha>` (fix). Not yet pushed for review; the PR follows.
   Deviations from the plan: <none, or one line each and why>.
   Risk / test considerations: <nearby paths that could regress>.
   ```
6. If the plan proves wrong in a way that changes scope or behaviour, stop. Report the gap; do not improvise a different feature.

## Phase 4: PR and links (background agent)

1. Push, then `gh pr create --base <default> --title "<KEY>: <summary>" --body-file <body.md>`, then `gh pr edit <n> --add-reviewer "@copilot"`.
2. `<jira> remotelink <KEY> --url <PR url> --title "PR #<n>: <title>"`, then `<jira> walk <KEY> --event pr_opened --fields-file .jira-flow/<KEY>/resolve-fields.json` → Ready for Dev Integration (TIR; Resolution = Fixed is set on this step).
3. **Dev-integration comment** (`--marker dev-integration --title "Ready for Dev Integration: PR #<n>"`; a story uses `--marker status --title "Status"`):
   ```markdown
   PR: [#<n> <title>](<PR url>) on branch `<branch>`, into `<default>`.
   Fix: <one or two sentences>. Regression test: `<test name>` (failed before, passes now).
   Unit tests: <command> - <N passed>.
   CI: running. Copilot review: requested.
   ```
4. Set `pr` and `phase: pr_open` in `state.json`.

**PR body: story**

```markdown
Jira: [<KEY>](<url>/browse/<KEY>) - <summary>

## Acceptance criteria
| AC | Status | Evidence |
|---|---|---|
| AC1 <short> | MET | `path/to/test.dart` "test name"; screenshot/log |

## Changes
- <one line per logical change>

## Testing
<commands run and results>
```

**PR body: defect**

```markdown
Jira: [<KEY>](<url>/browse/<KEY>) - <summary>

## Root cause
## Fix
## Regression test
<test name>: failed before the fix (<commit>), passes after.
## Log evidence
<reduced-log lines with @L numbers>
## Risk
```

The PR body is the source of truth. Edit it (`gh pr edit --body-file`); do not add comments.

## Phase 5: Merge (background agent)

Follow `pr-to-main`'s `PROCEDURE.md`, **Phases 3 and 4 only**:
- the repo's merge-readiness playbook if it has one;
- the `bash <scripts>/pr-watch.sh --loop <n>` exit codes;
- the round limit of 4 with parking;
- `bash <scripts>/pr-merge.sh <n> --admin`.

Keep the AC table in the PR body current when review changes something. When the PR is ready to merge (or parked), edit the dev-integration comment's last line once with the outcome: `CI: green (<run url>). Copilot review: <r> rounds, <n> findings fixed, <p> parked (<one line each>).` Do not edit it on every round. After the merge, set `phase: merged`.

## Phase 6a: Close-out (background agent)

1. Run `<jira> remotelink <KEY> --url <PR url> --title "PR #<n>: <title>" --resolved`.
2. **story:** re-check every AC against the merged code and tests: MET, PARTIAL or NOT MET, with evidence.
   - All MET: run `<jira> walk <KEY> --event merged`.
   - Otherwise: do not transition; list the gaps.
3. **defect:**
   1. `<jira> walk <KEY> --event merged --fields-file .jira-flow/<KEY>/resolve-fields.json` (dry run, then `--yes`) → Ready for QA Test.
   2. **QA comment** (`--marker qa --title "Ready for QA Test"`), written for the tester:
      ```markdown
      Merged: PR [#<n>](<PR url>) as `<merge sha>` into `<default>` on <date>. Build/version: <fix version or CI artifact, if known>.
      What changed: <one or two sentences, user-visible>.
      How to verify: <the issue's repro steps, and the expected result now>.
      Also check: <Test Considerations: nearby paths that could regress>.
      Evidence: regression test `<name>`; CI <green, run url>; Copilot review <r> rounds, <n> fixed, <p> parked (<one line each>).
      ```
4. **story:** edit the status comment: merged commit, the AC table, parked review items, and the next step.
5. Remove the worktree and the merged local branch (`git worktree remove`, `git branch -d`).
6. Set `phase: closed`.
7. Report: PR URL, merged or why not, AC verdicts or fix summary, Jira status before and after (and any `jira_stuck`), Jira writes skipped in read-only mode.

## Phase 6b: Jira follow-up (session, only if needed)

Only when a walk stopped (`jira_stuck` in `state.json`), or the run ended in read-only mode:
1. If it stopped on a missing field, ask the user for it, update `resolve-fields.json`, and re-run the same walk.
2. If it stopped with "stuck" (the next transition belongs to another role, such as a lead moving the issue to QA), report where it stopped and who needs to act.
3. In read-only mode, list the walks and comments that were dry runs, so the user can run them after flipping `read_only`.

## Final report (always short)

`<KEY>`, PR number and URL, merged yes/no, Jira status before → after, AC or fix verdicts, parked items, leftovers (worktree, branch, `.jira-flow/<KEY>/` is kept as the local record). Resume hint if the run stopped at a gate.
