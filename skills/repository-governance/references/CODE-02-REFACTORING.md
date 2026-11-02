# code-02: Refactoring

Carry out approved findings from the [architecture audit](CODE-01-ARCHITECTURE-AUDIT.md). The audit finds; this workflow fixes.

Apply the [governance contract](GOVERNANCE-CONTRACT.md), especially approval, the finding format, evidence, and safety rules. Inputs are the audit report, the selected finding IDs, the approval limits, and the current tree. If there is no usable report or clear approval, ask for it. Do not invent a refactoring program.

## Check before changing

For each selected finding:
1. Confirm the files and symbols still exist, the issue still applies, and no newer code or decision replaces it.
2. Re-check intended behavior, public contracts, compatibility promises, platform or build variants, and consumers.
3. Look at current local edits and do not overwrite unrelated work.
4. Confirm prerequisites and that the proposed fix is still valid. Mark outdated findings SUPERSEDED or BLOCKED instead of forcing the original plan.
5. Choose regression checks and record a baseline. Separate failures that already existed from new ones.

Missing tests do not mean behavior is unimportant. Where needed, add focused characterization tests within scope before changing the code. If you cannot pin down the behavior safely, pause that finding.

## Order and autonomy

Do high-impact, low-risk changes first, in prerequisite order. Then do high-impact, medium-risk changes that were specifically approved, then the remaining approved work. Inside the approved scope, confidence 90-100 with low change risk lets you proceed without asking again. Confidence alone never permits a rewrite or a deletion. Follow the contract's escalation rules for lower confidence, wider scope, or higher risk.

## Suitable changes

- Remove code proven unreachable, or dependencies proven unused, after checking dynamic use, platform variants, and public consumers.
- Merge duplicate utilities, business rules, or workflows that have the same meaning and compatible variations.
- Remove pass-through layers that add no real boundary.
- Make naming consistent and clarify ownership or module boundaries without changing external contracts.
- Simplify state and control flow while keeping error, cancellation, lifecycle, persistence, and concurrency behavior.

Expect old code to have built up over time, but prove redundancy before removing it. Reuse an existing helper before adding a new one. Every abstraction must earn its complexity; this does not mean flattening useful isolation or coupling code that changes for different reasons.

Where they fit the codebase, prefer simplicity over cleverness, explicit over implicit behavior, data-driven logic over repeated branching, composition over inheritance, shared patterns over one-off code, and consistency over local optimization.

## Not allowed without separate approval

- Framework replacement, full rewrites, or large rewrites where targeted fixes exist.
- Speculative optimization, purely cosmetic churn, or abstractions for imagined needs.
- New features, changed public APIs or behavior, unapproved dependencies, or weakened tests.
- Unrelated cleanup, silent fallbacks, or claims of guarantees you have not shown.

## Change and validate

Work in small, reviewable slices. Follow existing patterns and keep type safety, visible errors, formatting, and line endings.

After each slice, run the smallest existing checks that cover it: focused tests, type or build checks, lint and format checks, and relevant platform or contract checks. Run broader checks when shared boundaries change or targeted checks fail. Do not install tools just to get a green result unless authorized.

Verify the acceptance criteria, not only that it compiles or got shorter. Compare observable behavior and protected contracts with the baseline. Explain any needed deviation. Stop on unexpected regressions until they are resolved. Then challenge the result: is it simpler, easier to understand and extend, with fewer concepts, code paths, and special cases? If not, reconsider the slice.

## Report

For each finding, report APPLIED, SKIPPED, BLOCKED, or SUPERSEDED, with:
- Files changed, problems removed, duplication and abstractions removed, and behavior protected.
- The exact checks run and their results, failures that already existed, and checks not run with reasons.
- Evidence of less code, lower cognitive load, less coupling or duplication, and better testability. Give numbers only when you measured them.
- Remaining technical debt, risks introduced or remaining, and proposed next refactors, listed separately.
- A short handoff for the [architecture docs sync](CODE-03-ARCHITECTURE-DOCS-SYNC.md) listing verified architectural changes and the documents they affect.

Do not claim completion while required checks are blocked. Never revert unrelated user edits to recover from a failed refactor. Do not commit or push unless asked.
