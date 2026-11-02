# docs-01: Docs Audit

Read-only documentation audit. Find what is authoritative, accurate, obsolete, duplicated, missing, or needs a human decision. Keep truth and unique knowledge, not every document.

Apply the [governance contract](GOVERNANCE-CONTRACT.md): exclusions, authority, trust labels, freshness and debt scoring, confidence, and the `DOC-*` finding format. The audit recommends KEEP, UPDATE, MERGE, CONVERT, ARCHIVE, DELETE, or ESCALATE. It performs none of them. Return the report without writing to the repository unless the user asks you to save it.

## Inputs and inventory

Find the user's scope, the repository's instructions, the documentation index, relevant code and tests, approved specs, accepted ADRs, and earlier audits. Use plans, research, and history selectively; they are not automatically current requirements.

Classify each piece of permitted knowledge by role:
- Architecture, ADR, specification, plan, roadmap, handoff.
- Runbook or recipe, research, lessons learned, tradeoff analysis, meeting notes.
- Audit, navigation or agent context, historical artifact, or UNKNOWN.

For each document or section, record: role; status (current, proposed, completed, superseded, or historical); declared authority; trust based on evidence; owner where known; incoming and outgoing links; and coverage limits. Classify mixed documents by section. Never open excluded notes to complete the inventory.

## Governance invariants

- Recent activity is not evidence of truth. A document edited daily can be wrong; one unchanged for a year can be right.
- Classify knowledge, not file names or folders.
- Losing knowledge is worse than temporary document clutter.
- Code is evidence of implementation, not final product authority.
- A valid requirement is not obsolete just because the code lacks it.
- Correct historical rationale is not stale because it describes the past.

## Method

1. Map the authorities and find competing claims of current truth.
2. Check important claims against the right evidence: code and test results for behavior, approved specs for intent, accepted decisions for rationale, reliable sources for history.
3. Find drift, missing constraints, open contradictions, unsupported implementation claims, broken links, duplicate authority, and gaps in operational or architectural knowledge.
4. Before recommending removal, list the unique decisions, tradeoffs, rejected alternatives, lessons, and constraints in the material.
5. Score each fully assessable unit with the contract's four-part freshness score and categories. Mark UNKNOWN where evidence is missing, and show the part scores with reasons.
6. Report documentation debt with the contract's inventory, counting-unit, coverage, and baseline rules. Debt groups can overlap; explain the overlap instead of adding the groups as unique issues.
7. Assess the layout against the [docs structure](DOCS-00-STRUCTURE.md) reference. Do not penalize other layouts or recommend a migration only for neatness.

## Anti-patterns to look for

| Pattern | Concern |
|---|---|
| Zombie plans | Completed, abandoned, or replaced plans still shown as active work. |
| Handoff graveyards | Lasting constraints or decisions stuck in handoff notes with no maintained home. |
| Duplicate truth | Several live sources making overlapping or conflicting claims. |
| Spec rot | Approved specs no longer separate intended behavior, implementation status, and changed decisions. |
| Architecture shadowing | Unmaintained parallel architecture summaries that hide the real authority. |

These names are prompts to investigate. They are not grounds for deletion on their own.

## Recommendations

| Action | Use when |
|---|---|
| KEEP | The knowledge is useful, correctly labeled, and fit for purpose. |
| UPDATE | Local errors, missing context, status, or links can be fixed in place. |
| MERGE | Overlapping sources should have one maintained home. Name it and keep unique content. |
| CONVERT | Lasting knowledge belongs in another document type. Keep its status and approval. |
| ARCHIVE | The material is historical but still has rationale or reference value. |
| DELETE | No unique valuable knowledge and no historical or operational role remain. Record the evidence and the links to fix. |
| ESCALATE | Authority, ownership, intent, or preservation cannot be settled safely from the evidence. |

## Report

Return the contract's audit report with:
- The authority and content-role map and the inventory, including excluded areas and samples.
- `DOC-*` findings with claim-level evidence, confidence, impact, change risk, where knowledge should go, and acceptance criteria.
- Freshness part scores and categories, and the debt baseline with inventory size, UNKNOWN coverage, and counting rules.
- A prioritized reconcile plan with dependencies and approval needs.
- Missing knowledge, open decisions, and scope limits.

The goal is the most useful truth in the fewest words without losing institutional knowledge. Do not reward deletion volume, and do not declare a whole repository trustworthy from a sample.
