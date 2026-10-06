# Fastest Path by Role

Use this when you want the shortest useful starting point for your kind of work.

## Backend engineer

Best first tool:
- GitHub Copilot CLI for small to medium code changes
- Claude Code for debugging-heavy or riskier backend work

Fastest path:
1. Read [Tool selection cheat sheet](tools/TOOL-SELECTION.md)
2. Follow [Prerequisite tools](tools/PREREQUISITES-TOOLS.md)
3. Pick one setup page:
   - [Copilot CLI setup](tools/copilot-cli/SETUP.md)
   - [Claude Code setup](tools/claude-code/SETUP.md)
4. Use [Task-to-tool matrix](tools/TASK-TOOL-MATRIX.md) for the exact task type
5. Start with a prompt from [Prompt templates](knowledge/PROMPT-TEMPLATES.md)

Good starting tasks:
- Small bug fix
- Unit test generation
- Improve test coverage
- Focused refactor

Use Claude Code first when:
- The issue depends on logs and timing
- The failure is intermittent
- The change touches concurrency, retries, or transactions

## Frontend engineer

Best first tool:
- GitHub Copilot CLI for small UI changes
- Claude Code for tricky state bugs or cross-file behavior investigation

Fastest path:
1. Read [Tool selection cheat sheet](tools/TOOL-SELECTION.md)
2. Follow [Prerequisite tools](tools/PREREQUISITES-TOOLS.md)
3. Start with [Copilot CLI setup](tools/copilot-cli/SETUP.md)
4. Use [Copilot CLI examples](tools/copilot-cli/EXAMPLES.md) for short edit-and-check cycles
5. Keep [Common best practices](knowledge/COMMON-BEST-PRACTICES.md) open during work

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
- GitHub Copilot CLI for small platform changes
- Claude Code for incident analysis and cautious implementation
- GSD Pi for large migrations and staged work

Fastest path:
1. Read [Tool selection cheat sheet](tools/TOOL-SELECTION.md)
2. Follow [Prerequisite tools](tools/PREREQUISITES-TOOLS.md)
3. Choose [Copilot CLI](tools/copilot-cli/SETUP.md) for a small change or [Claude Code](tools/claude-code/SETUP.md) for incident work
4. Use [GSD Pi](tools/gsd-pi/SETUP.md) when the task spans many parts or needs stages
5. Review [GSD examples](tools/gsd-pi/EXAMPLES.md) for large work; use [Session management](knowledge/SESSION-MANAGEMENT.md) for long tasks

Good starting tasks:
- Migration planning
- Cross-module refactor planning
- Architecture research
- Reliability hardening

Use Claude Code first when:
- You are debugging production behavior from logs only
- You need stronger evidence ranking before changing code
- The incident needs a short investigation report

## Default recommendation if you are unsure

1. Start with [Copilot CLI setup](tools/copilot-cli/SETUP.md) for a focused change.
2. Use [Claude Code setup](tools/claude-code/SETUP.md) if the issue needs deeper debugging.
3. Use [GSD Pi](tools/gsd-pi/SETUP.md) for large, staged work. Use [Codex CLI](tools/codex/SETUP.md) for a separate review or [OpenCode](tools/opencode/SETUP.md) for multiple model providers.
4. Use the [Task-to-tool matrix](tools/TASK-TOOL-MATRIX.md) when you need more detail.

## If setup or first run breaks

- [10-minute onboarding](./10-MINUTE-ONBOARDING.md)
- [Common failure patterns and fastest recovery](knowledge/FAILURE-RECOVERY.md)
