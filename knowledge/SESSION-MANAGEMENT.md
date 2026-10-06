# Managing Long AI Chats

Use these steps to keep long tasks clear.

## Continue or start over

Resume when:
- The goal is unchanged
- The previous session ended mid-task
- The existing context is still accurate

Start fresh when:
- The objective changed
- The last session became noisy or confused
- You reached a milestone and want a clean next phase

## Save a short update

For each milestone, capture:
- Goal
- Current status
- Files changed
- Verification completed
- Next action

## Names and summaries

If the tool supports naming or explicit summaries:
- Use short task names
- End each milestone with a 5-line summary
- Keep the summary factual, not conversational

## Keep work separate

 Use one branch for each related change.
 Keep a large refactor separate from a small fix.
 Save or commit your changes before starting a new AI chat.
 Use `git worktree` (a second working copy) for parallel experiments.

## Pass work to a new chat

Use this summary format:

```text
Goal: <current objective>
Status: <done / in progress / blocked>
Files: <key files touched>
Verified: <tests or checks completed>
Next: <single next step>
```

## Simple rule

If the summary is harder to read than the code changes, the chat ran too long.

## Related docs

- [Common best practices](./COMMON-BEST-PRACTICES.md)
- [Copilot CLI commands](../tools/copilot-cli/COMMANDS.md)
- [Claude Code commands](../tools/claude-code/COMMANDS.md)
