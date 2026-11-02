# code-03: Architecture Docs Sync

Keep architecture and engineering knowledge in line with verified code changes. This workflow follows [refactoring](CODE-02-REFACTORING.md) or any other verified code change. It is not a general documentation cleanup or reorganization; for that, use the [docs audit](DOCS-01-AUDIT.md) and [docs reconcile](DOCS-02-RECONCILE.md) workflows.

Apply the [governance contract](GOVERNANCE-CONTRACT.md): authority, evidence, approval, truth promotion, AI context, and knowledge preservation.

## Inputs

- The code diff and the refactoring report, including checks run and limits.
- Architecture findings, approved requirements, accepted ADRs, and existing docs.
- The repository's instructions and its current documentation index or authority map.

Re-check every claim you change. If the code is untested or a finding is still blocked, say so in the docs. Never document a proposed or partial change as done.

## Truth promotion

Important lasting knowledge should not stay trapped in plans, meeting notes, or AI handoffs you are allowed to read. Never open private or excluded notes to find it.

| Knowledge | Where it belongs |
|---|---|
| Verified boundaries and implementation constraints | Current architecture docs. |
| Decision rationale, tradeoffs, and rejected alternatives | An ADR with the right status and the decision owner's approval. |
| Verified operating and recovery procedures | A runbook or recipe. |
| Supported lessons and research conclusions | A knowledge page with evidence and limits. |
| Navigation, active authority, key invariants, validation links | The existing agent context file or index. |

A plan does not become an accepted ADR by moving. Do not invent rationale or claim approval after the fact. Do not rewrite an accepted old decision to hide that it was replaced; propose a new decision that supersedes it.

## Steps

1. Map each verified change to the affected architecture docs, ADRs, runbooks, active specs, developer or user docs, and context links.
2. Update only the affected knowledge and its direct navigation. Describe behavior accurately, including constraints, error paths, and unproven areas.
3. Keep requirements separate from implementation status. If code and approved scope disagree, escalate; do not quietly change the scope to match the code.
4. Keep rationale, tradeoffs, lessons, rejected alternatives, and constraints before replacing text.
5. Update the existing agent context file instead of creating a competing summary. If a new one is authorized, use the contract's one-page template.
6. Use the [docs structure](DOCS-00-STRUCTURE.md) reference only when it helps. Do not force a migration or create empty folders, ADRs, or context files to match it.

## Validate and report

Check edited claims against real evidence, check relative links and navigation, and run the repository's existing documentation checks if any. Do not say tests passed because the refactoring report expected them to.

Report:
- Changed documents, each mapped to a verified code change.
- Promoted knowledge with source, destination, evidence, and decision status.
- Link and documentation checks, with actual results.
- Open contradictions, ownership or approval questions, and known limits.

The goal is a small, trustworthy architecture knowledge base, not more summaries. Archive or delete unrelated material only through a separately approved docs reconcile.
