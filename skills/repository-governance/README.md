# Repository Governance

A tool-neutral skill for long-lived, AI-assisted projects. It audits architecture and documentation, then applies only approved, verified changes.

## Philosophy

A repository exists to keep knowledge, not documents. Documents are expendable; knowledge is not. Remove accidental complexity, not useful boundaries. The goal is a maintainable codebase and a small, current, trustworthy, AI-friendly knowledge base, not fewer files or lines for their own sake.

## Two flows

The number in each workflow name is its run order. Approval sits between the audit and the step that changes things.

Code:
1. [code-01 architecture audit](references/CODE-01-ARCHITECTURE-AUDIT.md): read-only findings and a prioritized plan.
2. You approve a bounded set of `ARCH-*` findings.
3. [code-02 refactoring](references/CODE-02-REFACTORING.md): re-check, change in small slices, verify behavior.
4. [code-03 architecture docs sync](references/CODE-03-ARCHITECTURE-DOCS-SYNC.md): update docs, ADRs, and agent context to match.

Docs:
1. [docs-00 structure](references/DOCS-00-STRUCTURE.md): optional reference layout, not a required migration.
2. [docs-01 audit](references/DOCS-01-AUDIT.md): read-only inventory, claim checks, freshness scores, and recommendations.
3. You approve a bounded set of `DOC-*` findings.
4. [docs-02 reconcile](references/DOCS-02-RECONCILE.md): apply them while keeping unique knowledge.

code-03 follows code changes; docs-02 follows a docs audit. They share the same knowledge rules but do different jobs. All workflows use the [governance contract](references/GOVERNANCE-CONTRACT.md).

## Core ideas

- **Evidence first:** cite code, tests, decisions, and approved requirements. Separate observed behavior from intended behavior.
- **Trust is earned:** file type, folder, edit date, and confident wording do not prove truth.
- **Approval gates:** audits never change anything; execution covers only approved finding IDs.
- **Knowledge preservation:** before removing anything, ask what unique knowledge disappears.
- **Truth promotion:** move verified, lasting knowledge from notes and handoffs into ADRs, architecture docs, runbooks, or knowledge pages.
- **Freshness score:** a 0-100 score of fitness for purpose, not age (CURRENT, HEALTHY, AGING, AT RISK, ROTTING).
- **Documentation debt:** counted drift, redundancy, obsolescence, and missing knowledge, compared on the same baseline.
- **AI context hygiene:** a short, link-first index points agents to authoritative sources and never competes with them.
- **Compatibility:** content matters more than matching a preferred layout.

## Install

Copy the whole `repository-governance` folder to your AI tool's personal skills folder, as described in the [skills guide](../README.md#install-for-personal-use). Keep `references/` with `SKILL.md`.

## Example requests

- "Use repository-governance to audit the session lifecycle module. No writes."
- "Apply ARCH-001 and ARCH-003 from that audit. Low-risk, behavior-preserving changes only."
- "Update the architecture docs affected by those changes. Do not reorganize anything else."
- "Audit our docs and suggest a layout mapping, not a migration."
- "Apply the approved DOC findings. Ask before any archive or deletion that is not approved."
