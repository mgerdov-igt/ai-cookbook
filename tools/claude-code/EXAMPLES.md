# Claude Code Practical Examples

Before you choose:
- [Tool selection cheat sheet](../TOOL-SELECTION.md)
- [Task-to-tool matrix](../TASK-TOOL-MATRIX.md)

## Example 1: Add tests for legacy module

Model to start with:
- A balanced model that can add focused tests without changing much code.

```powershell
claude -p "Add unit tests for src/auth/token.ts. Keep behavior unchanged and run tests."
```

## Example 2: Diagnose and fix bug

Model to start with:
- A coding model that can follow the code and make a focused fix.

```powershell
claude -p "Find why login fails for expired refresh tokens, implement fix, and show diff summary."
```

## Example 3: Documentation pass

Model to start with:
- A balanced model that can write clear docs.

```powershell
claude -p "Read recent changes and update setup docs with concise steps and links."
```

## Example 4: Iterate on Spring Boot unit test coverage to 60%

Model to start with:
- A coding model that can add tests in small batches.

Use this when you want to add tests carefully to an existing Java project.

1. Run Claude Code in project root:

```powershell
claude
```

2. Start coverage-improvement loop with explicit constraints:

```text
Goal: Increase unit test coverage to at least 60% in this Spring Boot codebase.
Process:
- Measure the current test coverage and report the starting result.
- Add unit tests following Spring Boot and JUnit best practices.
- Prefer testing service/domain logic; avoid brittle tests on private methods or framework internals.
- Run tests and coverage after each batch and report progress.
- Repeat until coverage reaches 60%.
Stop conditions:
- Stop when coverage >= 60%, OR
- Stop if new tests need many mocks or test private methods or framework internals.
Output each iteration:
- Files changed
- New tests added
- Coverage before/after
- Why next targets were chosen
```

3. Ask for verification commands and final summary:

```text
Run the project test and coverage commands, then provide final report with:
- Final coverage percent
- Remaining uncovered high-risk areas
- Clear reason if stopping below 60%
```

Example coverage command (use the command for your project):

```powershell
mvn -q test jacoco:report
```

## Example 5: Investigate an Intermittent Problem Using Code and Logs

Model to start with:
- A strong reasoning model for unclear problems that involve several files or parallel tasks.

To balance cost and quality:
- Investigate with a strong reasoning model. Build a timeline and list likely causes.
- Use a coding or balanced model for a focused fix and tests.
- Use a stronger model for the final review if the risk calls for it.

A race condition is a problem where timing between tasks changes the result.

Use this when production is not directly accessible and you only have:
- Source repository
- Incident-time application logs

Customer report (intentionally vague):
- "Terminal sometimes freezes after a ticket is printed."
- "Buttons lag or stop responding for 10-30 seconds."
- "Sometimes the same action seems to run twice."
- "Issue is random and hard to reproduce."

Goal:
- Find the likely cause, show how to reproduce it, and suggest a safe fix.

1. Start Claude Code in repo root:

```powershell
claude
```

2. Ask for an investigation plan first:

```text
Customer reports intermittent buggy terminal behavior:
- freeze after printing
- delayed or blocked input
- occasional duplicate action execution

We suspect parallel work or a blocked task is involved.
Limits:
- No direct access to production terminal.
- Use only this codebase and provided incident logs.
Make an investigation plan. Build a timeline from the logs, find related tasks and locks, list likely causes with evidence, and plan a local test.
```

3. Compare the logs with the code:

```text
Analyze incident logs and correlate with code paths.
Deliver:
- Timeline of key events
- Tasks and locks that may be involved
- Places where code may wait (locks, queues, database, or network)
- Three likely causes, with confidence and supporting facts
```

4. Ask how to reproduce the problem locally:

```text
Find a way to reproduce the most likely cause with a test or simulation.
Use repeatable triggers where possible, such as timeouts, delays, parallel tasks, or limited resources.
```

5. Implement minimal fix options and validation:

```text
Suggest and make the smallest safe fix for the most likely cause.
Give one other option.
Run tests and show whether the problem is less likely to happen.
```

6. Write an incident report:

```text
Create final incident report with:
- Likely cause
- Evidence from logs + code
- Reproduction steps
- Fix diff summary
- Remaining risks
- Logs or measures to add for next time
```

When to use:
- Parallel-task problems that are hard to reproduce on a live system.
- Strict production access limits.

Pitfalls to avoid:
- Assuming nearby timestamps prove that one event caused another.
- Ignoring different system clocks or delayed log messages.
- Adding only timeouts or retries without checking lock order and state changes.
- Releasing the fix without adding logs or measures to check it.

## How to Check Claude Code Work

- Tests: new tests are clear, repeatable, and follow the project style.
- Bug fixes: reproduce or show the failure, make a small fix, and run related tests.
- Coverage: record the coverage change after each test batch and state when to stop.
- Incidents: list likely causes and supporting facts, show how to reproduce the problem, and suggest useful logs or measures.

## Tips

- Include files or directories in prompt when possible.
- Ask for explicit risk summary before finalizing.

## Next

- [Claude Code commands](./COMMANDS.md)
- [10-minute onboarding](../../10-MINUTE-ONBOARDING.md)
- [Prompt templates](../../knowledge/PROMPT-TEMPLATES.md)
- [Session management patterns](../../knowledge/SESSION-MANAGEMENT.md)
- [Common failure patterns and fastest recovery](../../knowledge/FAILURE-RECOVERY.md)
- [Common best practices](../../knowledge/COMMON-BEST-PRACTICES.md)
