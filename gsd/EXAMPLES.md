# GSD Pi Practical Examples

Concrete, repeatable workflows for common engineering tasks.

Best fit check:
- [Tool selection cheat sheet](../TOOL-SELECTION.md)
- [Task-to-tool matrix](../TASK-TOOL-MATRIX.md)

## Example 1: Document existing code into specs for future agents

Suggested initial model:
- Balanced general-purpose model (for example, Sonnet-class): strong balance of speed and quality for repo analysis and documentation structuring.

Goal:
- Create durable project docs that future agents can use for feature work, testing, and framework migration.

1. Start GSD in repo root:

```powershell
gsd
```

2. Create architecture and behavior docs from current code:

```text
/gsd quick "Analyze this codebase and produce concise docs for: architecture map, key modules, API contracts, data model, and runtime dependencies. Save docs under /docs/engineering. Keep each file short and actionable."
```

3. Create implementation specs for future work:

```text
/gsd quick "From current behavior, generate implementation specs for 3 likely next features. Include acceptance criteria, test strategy, and migration risks. Save under /docs/specs."
```

4. Add agent-ready guidance for tests and framework porting:

```text
/gsd quick "Create a framework-port playbook and test playbook from existing code patterns. Include what must stay invariant during migration. Save under /docs/engineering."
```

5. Check progress:

```text
/gsd status
```

When to use:
- Legacy code with weak docs
- Teams onboarding new agents or new engineers

## Example 2: Add a new Draw game using spec-derived tests

Suggested initial model:
- Code-focused model (for example, Codex-class): strong fit for test-first implementation, protocol-level reasoning, and precise code edits.

Goal:
- Add a new Draw game to an existing game collection.
- Validate behavior using tests derived from game specs and similarity to existing games.
- Verify protocol transactions and printing outputs.

1. Start GSD:

```powershell
gsd
```

2. Generate implementation spec from existing similar games:

```text
/gsd quick "Analyze existing games similar to Draw (same transaction flow and ticket printing style). Create a concise spec for new Draw game: game rules, transaction states, protocol messages, print layout, and edge cases. Save under /docs/specs/draw-game.md."
```

3. Create tests first from spec + similarity baseline:

```text
/gsd quick "From /docs/specs/draw-game.md and similar existing games, create tests only (no feature code yet): unit tests for game rules, integration tests for protocol transactions, and print snapshot/golden tests for ticket output."
```

4. Confirm red phase (expected failures):

```text
/gsd quick "Run new Draw game tests and summarize expected failures that define missing functionality."
```

5. Implement the Draw game with minimum change set:

```text
/gsd quick "Implement new Draw game to satisfy tests. Reuse existing game architecture, protocol transaction pipeline, and printer adapter patterns. Keep shared APIs and message contracts unchanged."
```

6. Validate protocol and printing parity:

```text
/gsd quick "Run full relevant test suite and report: game-rule pass rate, protocol transaction pass rate, print output parity vs expected snapshots, and any remaining gaps."
```

7. Final confidence check against similar games:

```text
/gsd quick "Compare new Draw game behavior against 2-3 similar games and list differences that are intentional vs accidental."
```

When to use:
- New game/variant added to an established game platform.
- Features where protocol correctness and printed artifacts are business-critical.

Pitfalls to avoid:
- Implementing first without spec-derived tests.
- Skipping protocol error/timeout scenarios.
- Validating print only visually instead of snapshot/golden tests.
- Breaking shared contracts used by other games.

## Example 3: Blue-sky design and solution research

Suggested initial model:
- Strong general-purpose model (for example, Sonnet-class): good for broad option exploration, trade-off analysis, and readable recommendation output.

Goal:
- Explore options before coding and select the best path with evidence.

1. Start GSD:

```powershell
gsd
```

2. Generate multiple solution approaches:

```text
/gsd quick "Problem: redesign async job processing for scale. Propose 3-4 architecture options with trade-offs in complexity, cost, reliability, and latency."
```

3. Evaluate third-party libraries:

```text
/gsd quick "For each option, evaluate top libraries/frameworks. Compare maturity, maintenance, ecosystem fit, migration effort, and vendor lock-in risk."
```

4. Produce POC plan:

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

- Multi-step refactor with safety checkpoints
- Dependency upgrade campaigns with staged verification
- Cross-repo change planning and execution tracking
- Performance optimization loop (baseline, change, measure, iterate)
- Reliability hardening (failure-mode mapping, test gaps, recovery playbooks)
- Release-readiness checks (risks, rollout plan, rollback plan)

## Example 4: Large milestone with multiple slices and tasks

Suggested initial model:
- Strong reasoning model (for example, Opus-class or GPT reasoning-tier) for initial milestone planning and major decision gates.

Practical model strategy:
This phased approach is optimized for token cost versus quality of result.
- Phase 1 (planning): use a strong reasoning model to design slices/tasks, dependencies, acceptance criteria, and rollback triggers.
- Phase 2 (execution): switch to a code-focused or balanced model for implementation-heavy slice work and fast test/fix loops.
- Phase 3 (gate reviews): optionally switch back to a strong reasoning model at slice boundaries and pre-rollout for risk challenge.

Scenario:
- You are migrating a large Java desktop/terminal application to Flutter, targeting Embedded Linux terminals and Android terminals.

Milestone goal:
- Deliver Flutter Terminal App v1 with parity for critical flows, stable device integration, and safe staged rollout.

How to get real value from `/gsd auto`:

1. Prepare guardrails before auto mode
- Ensure tests and build commands are runnable from terminal.
- Define hard constraints: protocol compatibility, offline behavior, security rules.
- Define rollback conditions and stop criteria.

2. Ask GSD to create milestone and slices first

```text
/gsd quick "Create a migration milestone plan for Java -> Flutter (Embedded Linux + Android terminals). Build Slice 1..5 with Task x.y format, acceptance criteria, verification commands, and rollback triggers."
```

3. Validate plan quality before auto execution
- Confirm each slice is independently verifiable.
- Confirm each task has explicit done criteria.
- Confirm device test matrix includes real hardware paths.

4. Start auto mode for execution

```text
/gsd auto
```

5. Keep auto mode bounded
- Let auto run one slice at a time.
- After each slice, review diff, test output, and risks.
- Continue only when slice acceptance criteria are met.

6. Use status checks frequently

```text
/gsd status
```

Suggested slices and tasks to feed into auto mode:

1. Slice 1: Discovery and baseline
- Task 1.1: Inventory Java modules, screens, and hardware integrations (scanner, printer, card/NFC, serial/USB).
- Task 1.2: Capture baseline behavior/performance (startup time, transaction latency, memory, crash rate).
- Task 1.3: Define migration invariants (business logic, protocol compatibility, offline behavior, security controls).

2. Slice 2: Architecture and integration design
- Task 2.1: Define Flutter architecture (modules, state management, navigation, error boundaries).
- Task 2.2: Define platform channel/plugin approach for Embedded Linux and Android.
- Task 2.3: Define API compatibility and local storage migration plan.

3. Slice 3: Core implementation
- Task 3.1: Build Flutter shell app and shared terminal UI components.
- Task 3.2: Implement top 3 critical transaction flows (happy path + failure paths).
- Task 3.3: Implement telemetry (structured logs, metrics, trace IDs).

4. Slice 4: Validation and hardening
- Task 4.1: Add parity tests comparing Java vs Flutter outcomes.
- Task 4.2: Add device-level tests on Embedded Linux and Android terminals.
- Task 4.3: Run performance/soak tests and fix high-risk regressions.

5. Slice 5: Rollout and fallback
- Task 5.1: Define staged rollout by device groups/sites with feature flags.
- Task 5.2: Run canary rollout and monitor success rate, error budget, and device health.
- Task 5.3: Validate rollback to Java path with data-sync safeguards and runbook.

When to use this pattern:
- Work is large, multi-team, and multi-platform.
- You already have enough tests/commands for autonomous verification.
- You can review slice outputs at checkpoints instead of letting auto run unchecked.

Pitfalls to avoid:
- Starting `/gsd auto` before acceptance criteria are explicit.
- Running auto across all slices without human checkpoint reviews.
- Treating simulated device tests as sufficient for terminal hardware migration.
- Missing rollback triggers and clear stop conditions.

## Verification standards for GSD workflows

- Feature delivery: relevant tests pass, shared contracts stay stable, and user-visible behavior matches spec.
- Migration work: parity tests pass, platform/device matrix is covered, and rollback path is documented.
- Research/design: options, assumptions, trade-offs, and recommendation are captured in a short artifact.
- Auto-mode milestones: each slice has explicit acceptance criteria, verification commands, and checkpoint review.

## Prompt pattern that works well in GSD

```text
Goal: <outcome>
Constraints: <what must not change>
Deliverables: <files, docs, tests>
Done when: <explicit verification criteria>
```

## Next

- [GSD commands](./COMMANDS.md)
- [10-minute onboarding](../10-MINUTE-ONBOARDING.md)
- [Prompt templates](../PROMPT-TEMPLATES.md)
- [Session management patterns](../SESSION-MANAGEMENT.md)
- [Common failure patterns and fastest recovery](../FAILURE-RECOVERY.md)
- [Common best practices](../COMMON-BEST-PRACTICES.md)
