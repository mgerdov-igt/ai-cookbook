# GSD Pi Practical Examples

Concrete, repeatable workflows for common engineering tasks.

Best fit check:
- [Tool selection cheat sheet](../TOOL-SELECTION.md)
- [Task-to-tool matrix](../TASK-TOOL-MATRIX.md)

## Example 1: Write Project Docs from Existing Code

Model to start with:
- A balanced model that can read code and write clear notes.

Goal:
- Create long-term project notes that engineers and AI tools can use for features, tests, and framework changes.

1. Start GSD in repo root:

```powershell
gsd
```

2. Create architecture and behavior docs from current code:

```text
/gsd quick "Analyze this codebase and write short docs for: system design, key modules, API requests and responses, data model, and the libraries or services needed to run it. Save under /docs/engineering. Keep each file short and useful."
```

3. Create implementation specs for future work:

```text
/gsd quick "From current behavior, generate implementation specs for 3 likely next features. Include acceptance criteria, test strategy, and migration risks. Save under /docs/specs."
```

4. Add instructions future AI tools can use for tests and framework changes:

```text
/gsd quick "Create a framework-port playbook and test playbook from existing code patterns. Include what must stay invariant during migration. Save under /docs/engineering."
```

5. Check progress:

```text
/gsd status
```

When to use:
- Older code with little documentation
- A team is bringing in new AI tools or engineers

## Example 2: Add a New Draw Game Using Tests from a Spec

Model to start with:
- A coding model that can write tests and make focused code changes.

Goal:
- Add a new Draw game to an existing game collection.
- Check behavior with tests from the game spec and similar games.
- Verify protocol transactions and printing outputs.

1. Start GSD:

```powershell
gsd
```

2. Generate implementation spec from existing similar games:

```text
/gsd quick "Analyze existing games similar to Draw (same transaction flow and ticket printing style). Create a concise spec for new Draw game: game rules, transaction states, protocol messages, print layout, and edge cases. Save under /docs/specs/draw-game.md."
```

3. Create tests from the spec and similar games before writing code:

```text
/gsd quick "From /docs/specs/draw-game.md and similar existing games, create tests only (no feature code yet): unit tests for game rules, integration tests for protocol transactions, and print snapshot/golden tests for ticket output."
```

4. Confirm the new tests fail before code is added:

```text
/gsd quick "Run new Draw game tests and summarize expected failures that define missing functionality."
```

5. Implement the Draw game with the smallest suitable change:

```text
/gsd quick "Implement the new Draw game so the tests pass. Reuse the current game design, protocol message flow, and printer code patterns. Keep shared APIs and message formats unchanged."
```

6. Check the protocol and printed tickets against expected output:

```text
/gsd quick "Run the relevant tests and report: game-rule pass rate, protocol test pass rate, how many printed outputs match expected snapshots, and remaining gaps."
```

7. Final confidence check against similar games:

```text
/gsd quick "Compare new Draw game behavior against 2-3 similar games and list differences that are intentional vs accidental."
```

When to use:
- New game/variant added to an established game platform.
- Features where protocol messages and printed tickets are critical to the business.

Pitfalls to avoid:
- Writing code before tests based on the spec.
- Skipping protocol error/timeout scenarios.
- Validating print only visually instead of snapshot/golden tests.
- Changing shared APIs or message formats used by other games.

## Example 3: Compare Design Options

Model to start with:
- A strong reasoning model to compare options and explain its choice.

Goal:
- Compare options before coding and choose one using clear reasons.

1. Start GSD:

```powershell
gsd
```

2. Generate multiple solution approaches:

```text
/gsd quick "Problem: redesign async job processing for scale. Propose 3-4 architecture options with trade-offs in complexity, cost, reliability, and latency."
```

3. Compare outside libraries:

```text
/gsd quick "For each option, evaluate top libraries/frameworks. Compare maturity, maintenance, ecosystem fit, migration effort, and vendor lock-in risk."
```

4. Write proof-of-concept plans for the two best options:

```text
/gsd quick "Create POC proposals for top 2 options with scope, success metrics, implementation steps, and rollback plan."
```

5. Choose recommendation:

```text
/gsd quick "Recommend one option and provide a 2-phase execution plan (POC then production rollout)."
```

When to use:
- Early-stage architecture decisions
- Re-platforming or large subsystem changes

## Other topics where GSD works very well

- Refactor code in steps, checking each step
- Upgrade many packages, checking each change
- Plan and track work across repos
- Improve speed by measuring before and after changes
- Improve reliability by listing failure cases, adding tests, and writing recovery steps
- Check release risks, release steps, and how to restore the old version

## Example 4: Large milestone with multiple slices and tasks

Model to start with:
- A strong reasoning model for the first plan and important reviews.

Choose a model for each step:
- Planning: use a strong reasoning model to split the work, list what must happen first, define checks, and state when to stop or restore the old app.
- Coding: use a coding or balanced model to make changes and run short test-and-fix rounds.
- Review: use a strong reasoning model for important reviews, such as before release.

Scenario:
- You are migrating a large Java desktop/terminal application to Flutter, targeting Embedded Linux terminals and Android terminals.

Milestone goal:
- Deliver the first Flutter terminal app with the same behavior on critical tasks, reliable device connections, and a step-by-step release.

How to use `/gsd auto` safely:

1. Set rules before auto mode
- Ensure tests and build commands are runnable from terminal.
- State what must not change: protocol messages, offline behavior, and security rules.
- State when to stop and how to restore the old app.

2. Ask GSD to create a milestone and parts first

```text
/gsd quick "Plan the Java to Flutter migration for Embedded Linux and Android terminals. Split it into 5 parts. Give each task a number, required checks, and a clear condition to stop or restore the Java app."
```

3. Check the plan before auto mode
- Make sure each part has its own checks.
- Make sure each task says how to tell it is done.
- Make sure device tests include real hardware.

4. Start auto mode for execution

```text
/gsd auto
```

5. Limit auto mode
- Let it work on one part at a time.
- After each part, review the changes, test results, and risks.
- Continue only when the part passes its required checks.

6. Check status often

```text
/gsd status
```

Example parts and tasks for auto mode:

1. Part 1: Learn how the current app works
- Task 1.1: List Java modules, screens, and device connections (scanner, printer, card/NFC, serial/USB).
- Task 1.2: Measure current behavior (startup time, transaction time, memory use, and crash rate).
- Task 1.3: List what must not change (business rules, protocol messages, offline behavior, and security).

2. Part 2: Design the Flutter app and device connections
- Task 2.1: Plan app parts, how screen data is stored, navigation, and error handling.
- Task 2.2: Choose how Flutter will use Embedded Linux and Android device features.
- Task 2.3: Keep the API working and plan how to move local data.

3. Part 3: Build the main features
- Task 3.1: Build the base Flutter app and shared screen parts.
- Task 3.2: Build the three most important transactions, including success and failure cases.
- Task 3.3: Add logs and measures that help find problems (such as request IDs).

4. Part 4: Test and improve the app
- Task 4.1: Add tests that compare Java and Flutter results.
- Task 4.2: Test on Embedded Linux and Android devices.
- Task 4.3: Run speed and long-running tests. Fix serious problems.

5. Part 5: Release and restore if needed
- Task 5.1: Release to device groups in steps, using feature flags.
- Task 5.2: Release to a small group first. Watch success rate, allowed error rate, and device health.
- Task 5.3: Check that the Java app can be restored without losing data. Write down the steps.

When to use this pattern:
- The work is large and spans teams or platforms.
- Tests and commands can check the changes.
- You can review each part instead of letting auto mode run unchecked.

Pitfalls to avoid:
- Starting `/gsd auto` before the required checks are clear.
- Running all parts without stopping for human review.
- Relying only on simulated device tests when real devices are needed.
- Forgetting when to stop or restore the old app.

## How to Check GSD Work

- Feature work: tests pass, shared APIs still work, and the result matches the spec.
- Migration work: comparison tests pass on target devices, and the restore steps are written down.
- Research/design: options, assumptions, trade-offs, and recommendation are in a short report.
- Auto mode: each part has required checks and a human review.

## Prompt pattern that works well in GSD

```text
Goal: <outcome>
Must not change: <rules or behavior to keep>
Files to update: <files, docs, tests>
How to check: <tests or commands>
```

## Next

- [GSD commands](./COMMANDS.md)
- [10-minute onboarding](../../10-MINUTE-ONBOARDING.md)
- [Prompt templates](../../knowledge/PROMPT-TEMPLATES.md)
- [Session management patterns](../../knowledge/SESSION-MANAGEMENT.md)
- [Common failure patterns and fastest recovery](../../knowledge/FAILURE-RECOVERY.md)
- [Common best practices](../../knowledge/COMMON-BEST-PRACTICES.md)
