# Claude Code Practical Examples

Best fit check:
- [Tool selection cheat sheet](../TOOL-SELECTION.md)
- [Task-to-tool matrix](../TASK-TOOL-MATRIX.md)

## Example 1: Add tests for legacy module

Suggested initial model:
- Balanced general-purpose model (for example, Sonnet-class): quick and reliable for adding focused unit tests with minimal disruption.

```powershell
claude -p "Add unit tests for src/auth/token.ts. Keep behavior unchanged and run tests."
```

## Example 2: Diagnose and fix bug

Suggested initial model:
- Code-focused model (for example, Codex-class): strong for deep code tracing and targeted bug-fix edits across files.

```powershell
claude -p "Find why login fails for expired refresh tokens, implement fix, and show diff summary."
```

## Example 3: Documentation pass

Suggested initial model:
- Balanced general-purpose model (for example, Sonnet-class): efficient for concise documentation rewriting and cleanup.

```powershell
claude -p "Read recent changes and update setup docs with concise steps and links."
```

## Example 4: Iterate on Spring Boot unit test coverage to 60%

Suggested initial model:
- Code-focused model (for example, Codex-class): strong for repetitive test authoring, coverage-driven loops, and Java test quality.

Use this when you want controlled, best-practice test expansion on an existing Java codebase.

1. Run Claude Code in project root:

```powershell
claude
```

2. Start coverage-improvement loop with explicit constraints:

```text
Goal: Increase unit test coverage to at least 60% in this Spring Boot codebase.
Process:
- Analyze current unit test coverage and report baseline.
- Add unit tests following Spring Boot and JUnit best practices.
- Prefer testing service/domain logic; avoid brittle tests on private methods or framework internals.
- Run tests and coverage after each batch and report progress.
- Repeat until coverage reaches 60%.
Stop conditions:
- Stop when coverage >= 60%, OR
- Stop if further unit tests would violate best practices or require excessive mocking of framework internals.
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

Suggested coverage command pattern (adapt to project):

```powershell
mvn -q test jacoco:report
```

## Example 5: Debug production race condition using code + logs only

Suggested initial model:
- Strong reasoning model (for example, Opus-class or GPT reasoning-tier): best for ambiguous, cross-file concurrency analysis and high-confidence hypothesis ranking.

Practical model strategy:
This phased approach is optimized for token cost versus quality of result.
- Phase 1 (analysis): use a strong reasoning model to reconstruct timeline, map thread interactions, and rank root-cause hypotheses.
- Phase 2 (implementation): switch to a code-focused or balanced model for focused code changes, test updates, and validation loops.
- Phase 3 (final review): optionally switch back to a strong reasoning model for final risk challenge and observability recommendations.

Use this when production is not directly accessible and you only have:
- Source repository
- Incident-time application logs

Customer report (intentionally vague):
- "Terminal sometimes freezes after a ticket is printed."
- "Buttons lag or stop responding for 10-30 seconds."
- "Sometimes the same action seems to run twice."
- "Issue is random and hard to reproduce."

Goal:
- Identify likely race/blocking root cause, produce reproducible evidence, and propose safe fixes.

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

We suspect a thread race/blocking issue.
Constraints:
- No direct access to production terminal.
- Use only this codebase and provided incident logs.
Create a debugging plan: log timeline reconstruction, thread interaction map, lock/block analysis, hypothesis ranking, and reproduction strategy.
```

3. Run structured log + code correlation:

```text
Analyze incident logs and correlate with code paths.
Deliver:
- Timeline of key events
- Suspected thread/lock interactions
- Candidate blocking points (mutexes, queues, DB/network waits)
- Top 3 root-cause hypotheses with confidence and evidence
```

4. Ask for offline reproduction harness:

```text
Build a local reproduction approach for the top hypothesis using tests or simulation.
Include deterministic triggers where possible (timeouts, injected delays, concurrent task burst, resource contention).
```

5. Implement minimal fix options and validation:

```text
Propose and implement the safest minimal fix for top hypothesis.
Also provide one alternative fix.
Then run tests and provide evidence that blocking/race risk is reduced.
```

6. Produce production-safe output package:

```text
Create final incident report with:
- Root cause summary
- Evidence from logs + code
- Reproduction steps
- Fix diff summary
- Residual risks
- Runtime observability additions (extra logs/metrics/traces) for next incident
```

When to use:
- Intermittent concurrency issues hard to reproduce live.
- Strict production access limits.

Pitfalls to avoid:
- Treating timestamp proximity as proof of causality.
- Ignoring clock skew and async logging delays.
- Fixing symptoms (timeouts/retries only) without lock-order or state-transition analysis.
- Shipping fix without adding observability for post-deploy confirmation.

## Verification standards for Claude Code workflows

- Test generation: new tests are readable, deterministic, and aligned with existing project conventions.
- Bug fixes: failing case is reproduced or strongly evidenced, fix is minimal, and relevant tests pass.
- Coverage loops: coverage delta is measured each round and stop conditions are explicit.
- Incident debugging: hypotheses are evidence-based, reproduction path is documented, and observability improvements are proposed.

## Tips

- Include files or directories in prompt when possible.
- Ask for explicit risk summary before finalizing.

## Next

- [Claude Code commands](./COMMANDS.md)
- [10-minute onboarding](../10-MINUTE-ONBOARDING.md)
- [Prompt templates](../PROMPT-TEMPLATES.md)
- [Session management patterns](../SESSION-MANAGEMENT.md)
- [Common failure patterns and fastest recovery](../FAILURE-RECOVERY.md)
- [Common best practices](../COMMON-BEST-PRACTICES.md)
