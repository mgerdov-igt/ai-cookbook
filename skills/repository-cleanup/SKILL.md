---
name: repository-cleanup
description: Plan and perform a behavior-preserving repository cleanup, refactor, or disk-hygiene pass. Use when asked to remove clutter, simplify code, or clean generated files. Requires the target repository's instructions and verification commands.
---

# Repository Cleanup

Use this skill for scoped code cleanup, refactoring, Git hygiene, or removal of generated artifacts. It is project-neutral: discover the target repo's contracts, instructions, and commands instead of assuming a framework or directory layout.

## First Pass

Read the repository's agent instructions, cleanup/refactor guidance, contribution rules, and relevant CI or test configuration. Check the working-tree state without changing it. Then read [the cleanup workflow](references/CLEANUP-WORKFLOW.md).

On the first cleanup pass in a repository, make no edits or deletions. Propose the exact scope, candidates, risk tier, nearby contracts or invariants, and verification steps. Wait for the user's confirmation. Later work is authorized only within the confirmed scope; stop and ask before expanding it.

## Safety Rules

- Preserve observable behavior unless the user explicitly requests a behavior change. Report bugs found during cleanup separately instead of hiding them inside a refactor.
- Treat public interfaces, persisted formats, protocols, configuration, generated files, and architectural boundaries as protected until repository guidance says otherwise.
- Do not infer that code is dead or a file disposable from its name, age, lack of imports, or Git ignore status. Search static and dynamic references and inspect ownership first.
- Never discard user changes. Do not reset, stash, force-update, or run broad cleanup commands to make the tree look clean.
- Treat ignored files as potentially valuable local data. Preview exact targets and preserve evidence, settings, and user-created files.
- Use the target repo's own platform, working-directory, formatting, analysis, test, and CI conventions. Do not copy commands from another project blindly.

## Finish

Run the agreed checks, inspect the final diff and Git status, and report what changed, what was verified, and any blocked checks or remaining risks. Do not commit or push unless asked.