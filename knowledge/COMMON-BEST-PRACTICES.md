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

## Keep Chats Focused

The context window is the amount of chat and project text an AI tool can use at once. Keep only useful information in it.

- Keep each prompt focused on one objective.
- Reference only the files and logs needed for the current step.
- Ask for a short summary after each step. Use it to continue.
- Start a fresh session after major milestones instead of one very long thread.
- Avoid pasting large raw logs; ask for filtered excerpts (errors, timestamps, thread IDs, affected modules).
- Restate the goal, status, next step, and blockers when the chat gets long.

Why this helps:
- The tool has less old chat to shorten or drop.
- Replies stay useful on long tasks.
- You repeat yourself less and spend fewer tokens.

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
	1. Preview: list the files to delete or move. Do not change them.
	2. Apply: make only the changes the user approved.

## Suggested workflow

1. Plan
2. Implement
3. Verify
4. Summarize changes and risks

## Tool-specific follow-up

- [GSD commands](../tools/gsd-pi/COMMANDS.md)
- [Copilot CLI commands](../tools/copilot-cli/COMMANDS.md)
- [Claude Code commands](../tools/claude-code/COMMANDS.md)
