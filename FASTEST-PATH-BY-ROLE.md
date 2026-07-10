# Fastest Path by Role

Use this when you want the shortest useful starting point for your kind of work.

## Backend engineer

Best first tool:
- GitHub Copilot CLI for small to medium code changes
- Claude Code for debugging-heavy or riskier backend work

Fastest path:
1. Read [Tool selection cheat sheet](./TOOL-SELECTION.md)
2. Follow [Prerequisite tools](./PREREQUISITES-TOOLS.md)
3. Pick one setup page:
   - [Copilot CLI setup](./copilot-cli/SETUP.md)
   - [Claude Code setup](./claude-code/SETUP.md)
4. Use [Task-to-tool matrix](./TASK-TOOL-MATRIX.md) for the exact task type
5. Start with a prompt from [Prompt templates](./PROMPT-TEMPLATES.md)

Good starting tasks:
- Small bug fix
- Unit test generation
- Coverage increase loop
- Focused refactor

Use Claude Code first when:
- The issue depends on logs and timing
- The failure is intermittent
- The change touches concurrency, retries, or transactions

## Frontend engineer

Best first tool:
- GitHub Copilot CLI for focused UI/component changes
- Claude Code for tricky state bugs or cross-file behavior investigation

Fastest path:
1. Read [Tool selection cheat sheet](./TOOL-SELECTION.md)
2. Follow [Prerequisite tools](./PREREQUISITES-TOOLS.md)
3. Start with [Copilot CLI setup](./copilot-cli/SETUP.md)
4. Use [Copilot CLI examples](./copilot-cli/EXAMPLES.md) for tight edit loops
5. Keep [Common best practices](./COMMON-BEST-PRACTICES.md) open during work

Good starting tasks:
- Component cleanup
- Docs updates after UI changes
- Small behavior fix
- Snapshot or test additions

Use Claude Code first when:
- State transitions are unclear
- A regression spans multiple screens
- The problem is only visible from logs or vague bug reports

## Platform engineer

Best first tool:
- GSD Pi for broad repo exploration, migration planning, and staged execution
- Claude Code for incident analysis and cautious implementation

Fastest path:
1. Read [Tool selection cheat sheet](./TOOL-SELECTION.md)
2. Follow [Prerequisite tools](./PREREQUISITES-TOOLS.md)
3. Start with [GSD setup](./gsd/SETUP.md)
4. Review [GSD examples](./gsd/EXAMPLES.md) for large, phased work
5. Use [Session management patterns](./SESSION-MANAGEMENT.md) before long-running efforts

Good starting tasks:
- Migration planning
- Cross-module refactor planning
- Architecture research
- Reliability hardening

Use Claude Code first when:
- You are debugging production behavior from logs only
- You need stronger evidence ranking before changing code
- The incident needs a concise investigation artifact

## Default recommendation if you are unsure

1. Start with [Copilot CLI setup](./copilot-cli/SETUP.md)
2. Use [Copilot CLI examples](./copilot-cli/EXAMPLES.md) for one focused task
3. Escalate using [Task-to-tool matrix](./TASK-TOOL-MATRIX.md) if the task becomes larger or more ambiguous

## If setup or first run breaks

- [10-minute onboarding](./10-MINUTE-ONBOARDING.md)
- [Common failure patterns and fastest recovery](./FAILURE-RECOVERY.md)
