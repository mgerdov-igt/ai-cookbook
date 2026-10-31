---
name: architecture-cleanup
description: "Audit a software repository for duplication, architectural drift, complexity, technical debt, and performance concerns; produce a prioritized refactoring roadmap and carry out approved behavior-preserving changes. Use for architecture reviews, refactor roadmaps, or technical due diligence."
---

# Architecture Cleanup

Run an evidence-based architecture audit before proposing or making systemic refactoring changes. Keep the scope explicit, preserve observable behavior, and prefer the smallest changes that measurably improve maintainability.

## When to use

Use this skill when the user asks to:
- Audit a codebase's architecture or technical debt
- Find systemic duplication, inconsistent patterns, or unnecessary layers
- Produce or execute a prioritized refactoring roadmap
- Assess a codebase before taking ownership or making substantial changes

## When not to use

Do not use this skill for feature development or a small, already-scoped cleanup. Use a focused implementation workflow for features and a repository-cleanup workflow for disk or Git hygiene.

## Workflow

### 1. Establish the constraints

Read repository instructions, architecture and contribution guidance, relevant CI/test configuration, and the working-tree state. Identify protected interfaces, data formats, ownership boundaries, and available verification commands. Leave existing user changes untouched.

Do not edit code during the initial audit. If repository guidance or essential constraints are missing, state the gap rather than inventing project policy.

### 2. Audit with evidence

Inspect the relevant code and its callers, tests, configuration, and runtime registration paths. Look for:
- Duplication in business rules, validation, API handling, state, utilities, data transformations, and UI patterns
- Complexity such as deeply nested or oversized functions, branching, special cases, and hard-to-follow control flow
- Architectural drift, mixed responsibilities, boundary violations, inconsistent patterns, and unclear ownership
- Technical debt such as dead code, unused dependencies, legacy paths, temporary workarounds, and stale configuration
- Dependency health, coupling, circular references, and difficult testing or debugging paths
- Performance concerns such as redundant work, queries, renders, allocations, or expensive transformations

Treat these as investigation prompts, not findings. Support each finding with concrete paths and evidence. Do not call code unused or safe to remove based only on its name or lack of direct imports; check dynamic use, configuration, generated references, and external consumers where relevant. Recommend performance work only when there is a known or measured cost.

### 3. Propose a prioritized roadmap

Before implementation, report each substantial candidate with:
- Problem and evidence
- Impact on complexity, maintenance, defect risk, performance, or AI-assisted development
- Recommended behavior-preserving change
- Risk tier and relevant contracts or invariants
- Expected benefit and verification method

Prioritize high-impact, low-risk work first. Name the exact files or bounded area and identify deferred ideas separately. Wait for the user's approval of the concrete scope before changing code.

### 4. Refactor in approved slices

Work only within the approved scope. Prefer small, reviewable changes that remove duplication or complexity without moving it elsewhere. Favor established project patterns, direct behavior, and existing dependencies. Do not add frameworks, dependencies, broad rewrites, or aesthetic-only refactors without clear justification and approval.

Preserve external behavior unless a behavior change is explicitly approved. Stop and ask before crossing a protected interface, changing data or configuration contracts, expanding the scope, or acting on uncertain deletion candidates. Report unrelated bugs and larger opportunities separately.

### 5. Validate each slice

Use the repository's own checks. Run the narrowest relevant check after each meaningful change, then any broader required gates for the approved scope. Confirm that behavior is preserved and that the result is simpler, more consistent, or less duplicated. If it is not, reconsider the change.

## Report

After the audit or each approved pass, summarize:
- Architectural findings and evidence
- Files changed, if any
- Duplication or complexity actually removed
- Remaining technical debt and deferred refactors
- Risks and verification results, including blocked checks

Do not claim improvements that were not demonstrated. Do not commit or push unless asked.

## Safety rules

- Repository instructions and project contracts take precedence over generic architecture preferences.
- Preserve user changes and observable behavior; never use broad cleanup or reset commands.
- Do not remove code, dependencies, or files without evidence that they are unused and within the approved scope.
- Prefer measured performance evidence over premature optimization.
- Keep architectural consistency and simplicity in service of the codebase, not as goals that justify unnecessary rewrites.