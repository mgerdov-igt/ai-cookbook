# GitHub Copilot CLI Practical Examples

Before you choose:
- [Tool selection cheat sheet](../TOOL-SELECTION.md)
- [Task-to-tool matrix](../TASK-TOOL-MATRIX.md)

## Example 1: Understand a codebase quickly

Model to start with:
- A balanced model that can map a project and write short notes.

Start in repo root:

```powershell
copilot
```

Then ask:

```text
Map the project structure, key modules, and build/test commands. Keep output under 20 lines.
```

## Example 2: Safe refactor

Model to start with:
- A coding model that can make careful changes while keeping behavior the same.

```text
Refactor duplicate validation logic in files A and B.
Do not change behavior.
Run tests and show what changed.
```

## Example 3: Add docs from code changes

Model to start with:
- A balanced model that can summarize changes and write clear docs.

```text
Summarize the last commit and draft concise README updates.
```

## Example 4: Run parallel work with `/fleet`

Model to start with:
- A balanced model that can split work into smaller tasks.

Use this for large tasks that can be split up without changing the same files.

1. Start Copilot CLI:

```powershell
copilot
```

2. Ask for a plan first:

```text
Create a plan to add Draw game support across rules engine, protocol transactions, printing templates, and tests.
```

3. Run separate tasks at the same time with `/fleet`:

```text
/fleet Implement the approved plan. Run separate tasks at the same time when they do not edit the same files: rules, protocol messages, print templates, and tests. Keep shared APIs and message formats unchanged. Run tests before summarizing.
```

4. Review outputs and verification summary:

```text
List finished tasks, changed files, tests run, and anything still waiting on other work.
```

When to use:
- Work that can be split into parts that do not edit the same files.
- Tasks that would take much longer one at a time.

Points to watch:
- `/fleet` can consume more AI credits because multiple subagents may run.
- If work is highly sequential, parallelization gives little benefit.
- State what must not change to avoid conflicting edits.

## How to Check Copilot CLI Work

- Project review: list key modules, build and test commands, and open questions.
- Refactor: tests pass, public behavior stays the same, and changes stay focused.
- Docs: commands run, links work, and wording matches the current tool.
- `/fleet`: each task reports changed files, tests run, and anything still waiting.

## Tips

- Keep each prompt single-purpose.
- Add constraints and done criteria every time.

## Next

- [Copilot CLI commands](./COMMANDS.md)
- [10-minute onboarding](../../10-MINUTE-ONBOARDING.md)
- [Prompt templates](../../knowledge/PROMPT-TEMPLATES.md)
- [Session management patterns](../../knowledge/SESSION-MANAGEMENT.md)
- [Common failure patterns and fastest recovery](../../knowledge/FAILURE-RECOVERY.md)
- [Common best practices](../../knowledge/COMMON-BEST-PRACTICES.md)
