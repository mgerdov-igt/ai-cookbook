# AGENTS

Instructions for AI coding agents working in this repository.

## Purpose

This repo is a concise documentation cookbook for Windows 11 + PowerShell 7+ usage of:
- GSD Pi
- GitHub Copilot CLI
- Claude Code
- Codex CLI and OpenCode
- GLM-5.3 through an approved provider, when available

Prioritize clarity and speed to first success.

## What to optimize for

- Short pages that can be completed in one reading
- Step-by-step setup with copy-paste commands
- Practical examples over theory
- Internal links instead of duplicated content
- Minimal framing and no filler

## Content boundaries

- Keep this repository lightweight.
- Do not turn pages into full vendor documentation.
- Link out to official docs for advanced topics.

## Knowledge structure

- Keep this file as stable steering and routing, not a status log or procedure catalog.
- Put reusable procedures and examples in maintained topic pages.
- Treat ignored `.todo/` content as temporary notes; move lasting decisions into project docs. See [knowledge structure](./knowledge/KNOWLEDGE-STRUCTURE.md).

## Authoring conventions

- Markdown only.
- Use plain, concise language. Write short sentences and say who does what.
- Prefer common words over internal jargon. Explain a technical term the first time it matters.
- Keep official product names, commands, code, and required engineering terms exact.
- Remove filler, repeated setup, and claims that do not help the reader act.
- Prefer sections in this order: Prerequisites, Install, Verify, First Run, Troubleshooting.
- Use Windows PowerShell command examples by default.
- Keep command snippets minimal and runnable.
- Favor clear checklists and numbered steps.
- Prefer one-screen pages where practical.
- If a page starts getting dense, split it instead of expanding it indefinitely.
- Each page should clearly answer: what do I run, how do I verify, what can go wrong?
- Create and edit files with your tool's file create and edit feature. Do not write file content through the shell with `Set-Content`, `Out-File`, `>`, or here-strings. See [PowerShell scripting rules](./tools/powershell/SCRIPTING.md).
- Write PowerShell scripts as in [PowerShell scripting rules](./tools/powershell/SCRIPTING.md). Write skills as in [Writing a portable skill](./knowledge/WRITING-SKILLS.md).
- Commit with [git-commit](./skills/git-commit/SKILL.md) rules: one logical change per commit and a Conventional Commits message. Do not push unless asked.
- After a change that renames, moves, or removes a page, skill, command, or setting, run the link and name check: `pwsh -NoProfile -File skills\docs-sync-audit\scripts\Test-DocsLinks.ps1 -CheckSkills`. Use [docs-sync-audit](./skills/docs-sync-audit/SKILL.md) for a full drift check.

## Required cross-linking

When adding or changing pages:
- Ensure [README](./README.md) routes readers to the relevant maintained guide.
- Ensure [tools/README](./tools/README.md) indexes tool documentation.
- Keep [QUICKSTART](./QUICKSTART.md), [10-minute onboarding](./10-MINUTE-ONBOARDING.md), and [fastest path by role](./FASTEST-PATH-BY-ROLE.md) at the project root.
- Ensure [tools/PREREQUISITES-TOOLS](./tools/PREREQUISITES-TOOLS.md) is referenced by setup pages.
- Ensure [knowledge/README](./knowledge/README.md) lists shared advice and work guides.
- Ensure [skills/README](./skills/README.md) explains the shared Agent Skills format and global installation.
- Ensure [knowledge/WRITING-SKILLS](./knowledge/WRITING-SKILLS.md) and [tools/powershell/SCRIPTING](./tools/powershell/SCRIPTING.md) stay linked from the skills guide and the hub pages.
- Ensure [tau-shell.yaml](./tau-shell.yaml) lists every skill under `skills/`.
- Keep [THIRD-PARTY-NOTICES](./THIRD-PARTY-NOTICES.md) current when adapting material from another project.
- Add links between setup, commands, and examples for the same tool.

## External references

Use official sources for install details:
- PowerShell install docs: https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows
- GSD Pi repo: https://github.com/open-gsd/gsd-pi
- GitHub Copilot CLI repo: https://github.com/github/copilot-cli
- Claude Code docs: https://code.claude.com/docs/en/overview

## Review checklist

Before finalizing changes:
1. Commands are current and executable on Windows 11.
2. Steps are concise and easy to scan.
3. Links are not broken.
4. No duplicated long-form reference text.
