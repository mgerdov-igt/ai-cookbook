# Claude Code Basic Commands

## Start in current project

```powershell
claude
```

## One-shot prompt mode

```powershell
claude -p "Explain this repository architecture in 10 bullets"
```

## High-autonomy mode (use with caution)

```powershell
claude --dangerously-skip-permissions
```

This bypasses normal permission prompts and can perform risky actions without confirmation.

Use with caution:
- Prefer only in isolated/non-production environments.
- Start from a clean branch and commit often.
- Include strict constraints and required verification commands in your prompt.
- Do not use when secrets, credentials, or production systems are in scope.

## Resume interrupted sessions

Continue the most recent conversation in current directory:

```powershell
claude -c
```

Resume a specific session by ID or name:

```powershell
claude -r <session-id-or-name>
```

Tip:
- Name important sessions when starting work so they are easier to resume later.

## Practical prompt pattern

```text
Goal: Implement feature X
Constraints: Keep API Y unchanged; no new dependencies
Done when: Tests pass and docs updated
```

## Session habits

- Ask for a short plan first.
- Approve changes in small batches.
- Request verification commands explicitly.

## Next

- [Claude Code setup](./SETUP.md)
- [Claude Code examples](./EXAMPLES.md)
- [Common best practices](../COMMON-BEST-PRACTICES.md)
