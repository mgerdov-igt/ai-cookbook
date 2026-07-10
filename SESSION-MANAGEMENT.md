# Session Management Patterns

Use this to keep long-running work understandable.

## Resume vs start fresh

Resume when:
- The goal is unchanged
- The previous session ended mid-task
- The existing context is still accurate

Start fresh when:
- The objective changed
- The last session became noisy or confused
- You reached a milestone and want a clean next phase

## Good session habit

For each milestone, capture:
- Goal
- Current status
- Files changed
- Verification completed
- Next action

## Naming and summaries

If the tool supports naming or explicit summaries:
- Use short task names
- End each milestone with a 5-line summary
- Keep the summary factual, not conversational

## Branch and worktree hygiene

- Use one branch per logical task
- Avoid mixing large refactors with small fixes
- Commit or stash before starting a new AI-driven thread
- Use a separate worktree if you need parallel experiments

## Handoff pattern

Use this summary format:

```text
Goal: <current objective>
Status: <done / in progress / blocked>
Files: <key files touched>
Verified: <tests or checks completed>
Next: <single next step>
```

## Simple rule

If the session summary is harder to read than the code diff, the session is too long.

## Related docs

- [Common best practices](./COMMON-BEST-PRACTICES.md)
- [Copilot CLI commands](./copilot-cli/COMMANDS.md)
- [Claude Code commands](./claude-code/COMMANDS.md)
