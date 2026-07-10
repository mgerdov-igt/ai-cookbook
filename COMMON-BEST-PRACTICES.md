# Common Best Practices

Use these with all AI coding tools.

## Before running an AI task

- Start in a clean git branch.
- Define one clear outcome for the session.
- Keep prompts concrete: goal, constraints, done criteria.

## During a session

- Ask for a short plan before major edits.
- Limit each request to one logical change set.
- Prefer small, reviewable diffs.
- Validate with local tests and linters.

## Keep context window healthy

- Keep each prompt focused on one objective.
- Reference only the files and logs needed for the current step.
- Ask for short summaries after each completed step, then continue from that summary.
- Start a fresh session after major milestones instead of one very long thread.
- Avoid pasting large raw logs; ask for filtered excerpts (errors, timestamps, thread IDs, affected modules).
- Re-anchor often with a compact state block: goal, current status, next action, blockers.

Why this helps:
- Reduces forced context compression.
- Preserves response quality on long tasks.
- Lowers token usage and improves iteration speed.

## Prompt pattern that works

Use this template:

```text
Goal: <what to achieve>
Context: <relevant files, stack, constraints>
Do not: <forbidden changes>
Done when: <verification criteria>
```

## Safety and quality

- Never paste secrets into prompts.
- Treat generated code as draft until reviewed.
- Require explanation for destructive operations.
- For destructive operations (cleanup/refactoring), use two phases:
	1. Dry run: summary only of suggested file deletions and moves.
	2. Actual run: apply changes only from the confirmed (or partially confirmed) dry-run plan.

## Suggested workflow

1. Plan
2. Implement
3. Verify
4. Summarize changes and risks

## Tool-specific follow-up

- [GSD commands](./gsd/COMMANDS.md)
- [Copilot CLI commands](./copilot-cli/COMMANDS.md)
- [Claude Code commands](./claude-code/COMMANDS.md)
