---
name: repository-governance
description: "Audit and improve a repository's architecture and documentation with evidence, approval gates, and knowledge preservation. Use for architecture reviews, technical due diligence, refactoring roadmaps, approved behavior-preserving refactors, documentation audits, stale or duplicate docs cleanup, syncing architecture docs after code changes, and promoting decisions into ADRs. Example requests: \"audit this codebase for duplication and propose a refactor roadmap\", \"apply ARCH-002 from the audit\", \"audit our docs\", \"clean up stale documentation\", \"update the architecture docs after this refactor\"."
---

# Repository Governance

Keep a codebase simple and its documentation trustworthy. Each change is backed by evidence, approved before it happens, and never loses unique knowledge.

## Pick a workflow

Workflow names carry their run order: `code-01` -> `code-02` -> `code-03`, and `docs-00` -> `docs-01` -> `docs-02`. Each step uses the output of the step before it. A step can also start alone when its input already exists (for example, approved findings from an earlier audit).

| Step | Request | Workflow | Writes? |
|---|---|---|---|
| code-01 | Audit architecture, duplication, debt, or drift; refactor roadmap; due diligence | [code-01 architecture audit](references/CODE-01-ARCHITECTURE-AUDIT.md) | No |
| code-02 | Apply approved `ARCH-*` findings | [code-02 refactoring](references/CODE-02-REFACTORING.md) | Code, within approval |
| code-03 | Update architecture docs, ADRs, or agent context after a verified code change | [code-03 architecture docs sync](references/CODE-03-ARCHITECTURE-DOCS-SYNC.md) | Affected docs |
| docs-00 | Assess or plan a documentation layout | [docs-00 structure](references/DOCS-00-STRUCTURE.md) | No, unless a migration is approved |
| docs-01 | Audit docs for stale, duplicate, missing, or conflicting knowledge | [docs-01 audit](references/DOCS-01-AUDIT.md) | No |
| docs-02 | Apply approved `DOC-*` findings | [docs-02 reconcile](references/DOCS-02-RECONCILE.md) | Docs, within approval |

Always read the [governance contract](references/GOVERNANCE-CONTRACT.md) with the chosen workflow. It defines scope rules, trust labels, confidence, the finding format, freshness scoring, documentation debt, and AI context.

Flows:
- **Code:** code-01 audit -> user approves `ARCH-*` IDs -> code-02 refactoring -> code-03 docs sync.
- **Docs:** docs-00 structure (optional reference) -> docs-01 audit -> user approves `DOC-*` IDs -> docs-02 reconcile.

If the user gives no scope, propose one and start with the read-only audit (code-01 or docs-01).

## Rules that always apply

- Read the repository's own instructions first. They win over this skill.
- Audits are read-only and return a report. An audit request never authorizes fixes.
- Execute only approved finding IDs. Re-check each one against the current tree first.
- Confidence is not permission. Only high-confidence (90-100), low-risk, approved changes may proceed without asking again.
- Preserve observable behavior and public contracts unless a change is approved.
- Before removing any document or section, ask: what unique knowledge disappears? Merge or convert it first.
- Never open excluded or private notes. Never copy secrets into reports or context files.
- Use the repository's own checks. Report checks that failed or did not run. Never claim an unproven result.
- Do not commit or push unless asked.

## When not to use

- Feature work or a small, already-scoped fix: use a normal implementation workflow.
- Git hygiene or removing generated files from disk: use `repository-cleanup`.
- Implementing an already-approved plan end to end: use `plan-auto-work`.

## Output

- Audits: one report with scope, coverage limits, `ARCH-*` or `DOC-*` findings, and a prioritized plan.
- Execution workflows: APPLIED, SKIPPED, BLOCKED, or SUPERSEDED per finding, with changed files, checks run, and remaining risks.
