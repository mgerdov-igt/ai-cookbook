# code-01: Architecture Audit

Read-only technical due diligence. Find the changes that remove the most accidental complexity while keeping intended behavior. Do not add features or change code.

Apply the [governance contract](GOVERNANCE-CONTRACT.md). The audit finds and recommends; the [refactoring workflow](CODE-02-REFACTORING.md) fixes only approved findings. A high confidence score is not permission to change anything.

## Inputs and preflight

- The user's scope and the repository's instructions.
- Relevant code, tests, build and dependency manifests, architecture docs, ADRs, approved specs, and known constraints.
- Earlier audit findings, if given. Re-check them instead of repeating them.

Record the revision and working-tree state, what you inspected, what you excluded, and where evidence is missing. Inspect selectively. Separate existing defects, intentional tradeoffs, and proposed simplifications. A test you did not run has not passed.

## Mindset

Act as a principal software architect. For each part of the system, ask:
- Why does this exist? Which requirement, invariant, or operational need does it serve?
- Is it still needed? What evidence shows it is used or obsolete?
- Can it be simplified, unified, made data-driven, replaced by an existing pattern, or removed without changing behavior?
- Is similar-looking code really the same concept, changing for the same reasons?
- Does this abstraction remove more complexity than it adds, or does it only pass data between layers or hide duplication?

Assume the original authors are unavailable. Every abstraction, dependency, and special case must justify itself from evidence in the repository.

Aim for maintainability, simplicity, sensible reuse, consistency, predictability, testability, justified performance, code an AI agent can follow, and long-term sustainability. Complexity is a cost that needs a reason; it is not proof of a defect. Prefer one implementation per business concept only when the contracts and variations truly match.

## Audit areas

| Area | Look for | Caution |
|---|---|---|
| Duplication | Repeated business rules, validation, API handling, utilities, state, data transformations, UI patterns, and workflows. | Show real semantic duplication and the cost of divergence. Do not merge code that only looks alike. |
| Complexity | Large files or classes, long functions, deep nesting, heavy branching, large switch statements, special cases, feature-flag divergence, scattered state, and indirection. | Size is a signal, not a finding. Show a concrete reasoning or change hazard. |
| Architectural drift | Competing solutions, inconsistent conventions, leaky abstractions, layer or boundary violations, mixed responsibilities, and unclear ownership. | Compare with the approved architecture, not one invented for the audit. |
| Technical debt | Dead paths, unused files, exports, or configuration, unsupported legacy behavior, workarounds, deprecated APIs, and unused dependencies. | Check dynamic registration, reflection, configuration, generated code, platform or build variants, compatibility promises, and external consumers before recommending removal. |
| Dependency health | Cycles, tight or excess coupling, unneeded packages, weak module boundaries, and hard-to-test paths. | Separate evidenced problems from speculative upgrades or swaps. |
| Performance | Redundant work, queries, renders, allocations, or expensive transformations. | Recommend only when the cost is known or measured. |
| AI maintainability | Hidden side effects, implicit contracts, inconsistent patterns, confusing names, unclear flow, and non-obvious extension points. | An agent should be able to study one feature and build another with the same conventions. Describe the concrete hazard. Do not claim measured AI gains without evidence. |

Where relevant, also consider error handling, lifecycle, concurrency, persistence, platform support, and public compatibility. Do not grow the audit into unrelated rewrites.

## Method

1. Map the active authorities and the architectural invariants.
2. Trace the scoped behavior through code and tests.
3. Gather direct evidence for each suspected issue. Look for counterexamples and reasons the design may be intentional.
4. Propose the smallest sound change and name the contracts it must protect.
5. Rate impact, confidence, change risk, dependencies, and reversibility separately.
6. Define observable acceptance criteria and the checks to run. Do not run checks that write files unless authorized.

## Report

Return one report with `ARCH-*` findings in the contract's format:
- Findings with risk and confidence.
- Coverage summaries for duplication, complexity, drift, debt, dependencies, performance, and AI maintainability. Write "not assessed" where true.
- A remediation plan ordered by impact and risk, with prerequisites, approval needs, regression checks, and open design decisions.
- Coverage limits, existing strengths to keep, and remaining risks.

Do not invent one finding per area to fill the template. "No actionable finding in the inspected scope" is a valid result when it is well supported.

## Success

Recommendations remove needless concepts, duplication, or coupling, and keep required behavior, useful boundaries, and justified constraints. Less code and fewer abstractions are likely outcomes, not targets.
