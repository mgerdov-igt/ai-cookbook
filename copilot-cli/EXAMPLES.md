# GitHub Copilot CLI Practical Examples

Best fit check:
- [Tool selection cheat sheet](../TOOL-SELECTION.md)
- [Task-to-tool matrix](../TASK-TOOL-MATRIX.md)

## Example 1: Understand a codebase quickly

Suggested initial model:
- Balanced general-purpose model (for example, Sonnet-class): fast and clear for repository mapping and concise technical summaries.

Start in repo root:

```powershell
copilot
```

Then ask:

```text
Map the project structure, key modules, and build/test commands. Keep output under 20 lines.
```

## Example 2: Safe refactor

Suggested initial model:
- Code-focused model (for example, Codex-class): strong for careful refactoring and preserving behavior under constraints.

```text
Refactor duplicate validation logic in files A and B.
Do not change behavior.
Run tests and show what changed.
```

## Example 3: Add docs from code changes

Suggested initial model:
- Balanced general-purpose model (for example, Sonnet-class): efficient for summarization and clean, human-readable documentation updates.

```text
Summarize the last commit and draft concise README updates.
```

## Example 4: Run parallel work with `/fleet`

Suggested initial model:
- Balanced general-purpose model (for example, Sonnet-class): good baseline for orchestrating multiple subtasks with strong speed/cost balance.

Use this for large tasks that can be split into independent parts.

1. Start Copilot CLI:

```powershell
copilot
```

2. Ask for a plan first:

```text
Create a plan to add Draw game support across rules engine, protocol transactions, printing templates, and tests.
```

3. Run the plan with parallel subagents:

```text
/fleet Implement the approved plan. Run independent tasks in parallel where safe: rules engine updates, protocol handler updates, printing template updates, and test implementation. Keep shared contracts unchanged and run tests before final summary.
```

4. Review outputs and verification summary:

```text
Show completed subtasks, changed files by area, tests run, and any unresolved dependencies.
```

When to use:
- Multi-part work with low coupling between parts.
- Tasks that are slow when done strictly one-by-one.

Points to watch:
- `/fleet` can consume more AI credits because multiple subagents may run.
- If work is highly sequential, parallelization gives little benefit.
- Keep constraints explicit to avoid conflicting edits.

## Verification standards for Copilot CLI workflows

- Codebase understanding: output names key modules, build/test commands, and known unknowns.
- Refactor work: tests pass, public behavior is unchanged, and diff scope stays narrow.
- Docs work: commands are runnable, links are valid, and wording matches current tool behavior.
- Parallel `/fleet` work: each subtask reports changed files, tests run, and unresolved dependencies.

## Tips

- Keep each prompt single-purpose.
- Add constraints and done criteria every time.

## Next

- [Copilot CLI commands](./COMMANDS.md)
- [10-minute onboarding](../10-MINUTE-ONBOARDING.md)
- [Prompt templates](../PROMPT-TEMPLATES.md)
- [Session management patterns](../SESSION-MANAGEMENT.md)
- [Common failure patterns and fastest recovery](../FAILURE-RECOVERY.md)
- [Common best practices](../COMMON-BEST-PRACTICES.md)
