# AGENTS

Instructions for AI coding agents working in this repository.

## Purpose

This repo is a concise documentation cookbook for Windows 11 + PowerShell 7+ usage of:
- GSD Pi
- GitHub Copilot CLI
- Claude Code

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

## Authoring conventions

- Markdown only.
- Prefer sections in this order: Prerequisites, Install, Verify, First Run, Troubleshooting.
- Use Windows PowerShell command examples by default.
- Keep command snippets minimal and runnable.
- Favor clear checklists and numbered steps.
- Prefer one-screen pages where practical.
- If a page starts getting dense, split it instead of expanding it indefinitely.
- Each page should clearly answer: what do I run, how do I verify, what can go wrong?

## Required cross-linking

When adding or changing pages:
- Ensure [README](./README.md) links to the page.
- Ensure [QUICKSTART](./QUICKSTART.md) still reflects the fastest path.
- Ensure [PREREQUISITES-TOOLS](./PREREQUISITES-TOOLS.md) is referenced by setup pages.
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
