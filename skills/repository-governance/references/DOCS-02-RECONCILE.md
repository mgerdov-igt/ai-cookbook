# docs-02: Docs Reconcile

Apply approved findings from the [docs audit](DOCS-01-AUDIT.md). The audit finds; this workflow cleans up while keeping knowledge.

Apply the [governance contract](GOVERNANCE-CONTRACT.md), especially approval, the finding format, freshness and debt reporting, truth promotion, and AI context rules. Inputs are the audit report, the selected `DOC-*` IDs, the approval limits, and the current docs. A recommendation is not permission.

This workflow handles audit-driven cleanup. After code changes, use [architecture docs sync](CODE-03-ARCHITECTURE-DOCS-SYNC.md) instead. Never change code to make docs match.

## Check before changing

1. Re-check each finding: source and destination, current authority, incoming links, and relevant code. Look for newer decisions or edits that replace it.
2. Keep unrelated work and repository exclusions. Mark outdated findings SUPERSEDED, unsafe ones BLOCKED, and unchanged ones SKIPPED, with reasons.
3. Recover the audit's baseline: inventory, freshness part scores, UNKNOWN coverage, and debt counting rules.
4. Confirm prerequisites and approval before changing content.

Proceed without asking again only for approved, high-confidence (90-100), low-risk actions where knowledge is clearly kept. Ask before any unapproved archive or deletion, an uncertain change of authority, wider restructuring, or newly found scope. Lower confidence or higher risk needs the specific approval the contract describes.

## Knowledge check before removal

Before you replace, merge, archive, or delete anything, ask: **What unique knowledge disappears from the maintained record?**

Protect decision rationale, tradeoff analysis, rejected alternatives, lessons learned, architectural and operational constraints, and institutional knowledge.
- List each unique claim and its source.
- Verify it where you can; where you cannot, keep it marked as uncertain.
- Map it to a maintained home, a clearly labeled historical reference, or an approved reason to discard it.
- MERGE or CONVERT valuable knowledge before retiring its source.
- Keep enough history to trace decisions and what replaced them.

Version control history alone is not enough for knowledge that maintainers still need to find. Keeping knowledge does not mean keeping every redundant live copy.

## Actions

| Action | How |
|---|---|
| UPDATE | Fix evidenced claims, status labels, missing constraints, and links. Do not quietly change approved requirements. |
| MERGE | Pick one home, keep all unique valuable knowledge, resolve or label contradictions, then fix links. |
| CONVERT | Move verified rationale to an approved ADR, procedures to runbooks, constraints to architecture docs, or lessons to knowledge pages. |
| ARCHIVE | Keep useful history, label its status and replacement, and remove misleading links that present it as current. Keep selected historical links. |
| DELETE | Needs explicit approval, evidence that no unique needed knowledge remains, and fixed links and tool paths. |

KEEP findings need no change. ESCALATE findings stay open until a human decision or new evidence arrives; never settle them by guessing.

Never delete these automatically, whatever the confidence: ADRs and other decision records, architecture docs, security docs, and recorded design constraints. Archive, supersede, or convert them only with explicit approval.

Freshness suggests a starting action, not a decision: 90+ KEEP; 70-89 KEEP or UPDATE; 50-69 UPDATE; 25-49 ESCALATE unless the fix is clear; 0-24 consider ARCHIVE, CONVERT, or DELETE after the knowledge check. Evidence overrides the default.

AI-generated plans must prove their ongoing value. A completed plan should almost never stay active: convert its lasting knowledge, then archive or delete it with approval.

If the repository already uses review metadata, update it on reviewed documents (for example status, last-reviewed date, and freshness score). Do not add a new header convention without approval.

## Structure and AI context

Use the [docs structure](DOCS-00-STRUCTURE.md) reference with its compatibility rules. Create only approved, needed folders. Never overwrite different content, force folder compliance, or leave contradictory copies. When moves are approved, keep old-to-new and knowledge mappings.

Maintain the existing agent context file or index. Link current architecture, applicable accepted ADRs, approved active specs, key invariants, and validation guidance. Leave archives, old handoffs, session notes, and completed plans out of default context, not necessarily out of the repository. Never include private notes or secrets. If a new context file is authorized, use the contract's one-page template.

## Validate

Check final claims, status labels, authority links, knowledge mappings, and relative links. Check navigation and any tool paths affected by moves. Run the repository's documentation checks if any; report missing checks and manual coverage honestly. Make sure the repository's instructions still point to the right active sources.

Re-score changed units with the same freshness score. Report mean freshness and debt before and after, using the same baseline inventory. Map merged, converted, and archived sources to their destinations. List new units, removals, UNKNOWNs, and open findings separately. Do not inflate results by dropping weak units or giving unverified perfect scores.

## Report

- Per-finding APPLIED, SKIPPED, BLOCKED, or SUPERSEDED, with evidence and the human decisions applied.
- Changed files grouped by action (updated, merged, converted, archived, deleted); knowledge and old-to-new mappings.
- Comparable freshness and debt results, inventory sizes, and measurement limits.
- Checks actually run and their results, remaining conflicts, and approval needs.

The goal is small, current, trustworthy, AI-friendly documentation with the most useful truth per word. Keeping knowledge matters more than surface tidiness. Do not commit or push unless asked.
