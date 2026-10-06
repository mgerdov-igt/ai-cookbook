# GitHub Copilot CLI Basic Commands

## Launch

```powershell
copilot
```

## Useful in-session commands

```text
/login
/model
/yolo
/fleet
/resume
/help
```

`/yolo` lets Copilot make wider changes with fewer prompts. Use it with care.
`/fleet` is for splitting large work into parallel sub-tasks when parts are independent.

Use `/yolo` with caution:
- Prefer only on non-production branches/worktrees.
- Keep a clean git state before enabling.
- Require explicit verification steps (tests/lint/build) in your prompt.
- Avoid for secrets, production config, or destructive operations.

## Resume interrupted sessions

Resume from inside an interactive session:

```text
/resume
```

Resume from terminal:

```powershell
copilot --resume
```

Quickly continue the most recent local session:

```powershell
copilot --continue
```

## Prompt pattern

```text
Goal: Refactor X safely
Constraints: Keep public API unchanged
Done when: Tests pass and docs updated
```

## Fast iterative cycle

1. Ask for plan.
2. Approve one step.
3. Run tests.
4. Repeat.

## Keep it reliable

- Ask for minimal diffs.
- Ask for explicit verification commands.
- Require summary of changes and risks.

## Next

- [Copilot CLI setup](./SETUP.md)
- [Copilot CLI examples](./EXAMPLES.md)
- [Common best practices](../../knowledge/COMMON-BEST-PRACTICES.md)
