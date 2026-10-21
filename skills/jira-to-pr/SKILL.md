---
name: jira-to-pr
description: Take one Jira story or bug/TIR from requirements to a merged PR. Digest the issue, ask clarifying questions in the session and/or as one Jira comment, write a plan and get it approved, implement it in a separate worktree, open one PR linked both ways with the issue, drive it to merge, then move the issue to its configured status, with a few clean, edited-in-place comments on both sides. Resumable when answers or approval arrive later on Jira. Invoke on "implement VTA-123", "jira-to-pr VTA-123", "work on this ticket", "fix TIR ABC-456", "resume VTA-123", "any Jira replies?".
---

# Jira to PR

One Jira issue (Story or Bug/TIR) → one PR in the current repo → merged. It needs the `jira-flow` skill (`jira.py`, configured by the repo's `.jira-flow.json`) and `github-pr-flow` (PR scripts). Full procedure: `PROCEDURE.md` next to this file.

## What to do when invoked

- **`pending` / "any Jira replies?":** run `jira.py pending` and offer to resume the issues it lists.
- **`<KEY>` (new or resume):** do Phases 0 to 2 of `PROCEDURE.md` **inline**, because they need the user: intake, clarifying questions and plan approval. Read only the sections for those phases. If `.jira-flow/<KEY>/state.json` exists, continue from the phase it records.
- **Once the plan is approved:** spawn **one background general-purpose agent** for Phases 3 to 6 and return at once:
  - Copilot CLI: `task` tool, `agent_type: general-purpose`, `mode: background`.
  - Claude Code: `Agent` tool, `subagent_type: general-purpose`, run in background.

  Use this prompt with the placeholders filled in. Do not paste the procedure or the plan into it:

  ```
  Implement Jira issue <KEY> in <REPO_ROOT> and drive it to a merged PR, autonomously.
  Read and follow PROCEDURE.md next to the jira-to-pr skill's SKILL.md
  (~/.copilot/skills/jira-to-pr/PROCEDURE.md or ~/.claude/skills/jira-to-pr/PROCEDURE.md),
  starting at Phase 3. State, digest and the approved plan are in <REPO_ROOT>/.jira-flow/<KEY>/.
  ```

  Tell the user in one or two sentences that the run has started, that the result arrives as a background-agent notification, and that their folder and branch are untouched.

- **When the agent reports back:** relay its short report. For a defect, it leaves a resolution-fields draft for the user to confirm. Finish Phase 6b of the procedure inline.

The user can stop at any gate. Answers and approval can come later as Jira replies; the run then ends cleanly and resumes with `jira-to-pr <KEY>`.
