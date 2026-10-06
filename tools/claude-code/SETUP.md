# Claude Code Setup (Windows 11 + PowerShell 7)

## Prerequisites

- [Prerequisite tools](../PREREQUISITES-TOOLS.md)
- [PowerShell environment setup](../powershell/SETUP.md)
- Claude subscription or Anthropic Console account

If you are still choosing a tool, start with [Tool selection cheat sheet](../TOOL-SELECTION.md).

## Install (WinGet recommended)

```powershell
winget install Anthropic.ClaudeCode
```

If install is blocked by permissions, rerun in Administrator PowerShell.

Alternative (native PowerShell installer):

```powershell
irm https://claude.ai/install.ps1 | iex
```

## Verify

```powershell
claude --version
```

## First run

From your project directory:

```powershell
claude
```

Sign in when prompted.

## Optional recommendation

Install Git for Windows so Claude can use Bash tooling where needed.

## TODO

- Add Claude Code settings guidance for environments that require auth keys or related authentication settings.

## Next

- [10-minute onboarding](../../10-MINUTE-ONBOARDING.md)
- [Claude Code commands](./COMMANDS.md)
- [Claude Code examples](./EXAMPLES.md)
- [Common failure patterns and fastest recovery](../../knowledge/FAILURE-RECOVERY.md)

## Official docs

- https://code.claude.com/docs/en/overview
