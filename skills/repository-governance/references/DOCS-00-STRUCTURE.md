# docs-00: Docs Structure

A reference layout for AI-friendly project knowledge. It is a preference, not a required standard.

Apply the [governance contract](GOVERNANCE-CONTRACT.md). Reading this file does not authorize creating folders, moving files, or editing docs. Assess the current layout read-only. Migrate only under an approved plan, normally through [docs reconcile](DOCS-02-RECONCILE.md).

Classify by content, declared lifecycle, and authority. Folder names are hints, not proof. Keeping knowledge matters more than matching folders.

## Reference layout

Use existing equivalent locations. Add a folder only when it has a real maintained document to hold.

```text
docs/
  architecture/
    adrs/
  planning/
    roadmap/
    active-plans/
    backlog/
    technical-debt/
  specs/
    active/
    proposed/
  recipes/
  knowledge/
    lessons-learned/
    research/
    tradeoff-analysis/
  audit/
    architecture/
    documentation/
    governance/
  archive/
AI_CONTEXT.md
```

The example puts the context file at the repository root. An existing equivalent index elsewhere is just as good; follow the repository's convention instead of adding a duplicate.

## What each area answers

| Area | Question |
|---|---|
| Architecture | What exists, how is it bounded, and which constraints apply? |
| ADRs | Which decision was made, why, with what status, alternatives, and consequences? |
| Planning | What do we plan to do, in what order, and what is still uncertain? |
| Active specs | What approved behavior should be built or kept? Track implementation status separately. |
| Proposed specs | What behavior is under consideration but not approved? |
| Recipes and runbooks | How do we perform or recover an operation safely? |
| Knowledge | What did we learn, with what evidence and limits? |
| Audit | What did a scoped review find, at which revision? |
| Archive | What is kept for history, not current authority? |
| Agent context or index | Which authoritative links and constraints should an agent read first? |

## Compatibility example

Many repositories use another layout, such as versioned folders. Suppose the instructions say `docs/v2` is current, `docs/v1` is historical, and `docs/v3` is future-only planning. Record that mapping. Do not assume the highest version is authoritative, and do not move all three into the reference layout.

An active architecture page in `docs/v2` can stay where it is. A future proposal in `docs/v3` stays proposed, not implemented. Old decisions can keep their place with a clear status and selected links. Often a navigation index solves discoverability without moving any file.

## Migration (only when authorized)

1. List in-scope knowledge, current authority, incoming links, and tools that read these paths. Respect private and excluded paths.
2. Write an old-to-new mapping with reasons, where each piece of knowledge goes, risks, and checks. Prefer no move when a label or index is enough.
3. Get approval for the mapping and for every merge, archive, or deletion. High confidence supports a proposal; it does not replace permission.
4. Create only the needed folders. Never overwrite a different existing document. On a name clash, compare content and keep unique knowledge.
5. Move or merge in small, reviewable steps. Update links, indexes, tool paths, and status labels together.
6. Verify kept knowledge, links, and tools before retiring a source. Keep a move record so history can be traced.

Pure reorganization keeps all unique content. Removing duplicate or obsolete material needs its own evidenced reconcile action; it is not an automatic part of migration. Do not leave contradictory live copies to avoid deleting, and do not erase unique knowledge to get a tidy tree.

## Report

Report the content-to-area mapping, compatible areas left unchanged, approved moves, kept knowledge, link checks, and open questions. "No migration needed" is a successful result.
