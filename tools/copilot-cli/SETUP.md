# GitHub Copilot CLI Setup (Windows 11 + PowerShell 7)

This section uses the current Copilot CLI (`copilot` command).

## Prerequisites

- [Prerequisite tools](../PREREQUISITES-TOOLS.md)
- [PowerShell environment setup](../powershell/SETUP.md)
- Active GitHub Copilot subscription

If you are still choosing a tool, start with [Tool selection cheat sheet](../TOOL-SELECTION.md).

## Install (WinGet)

```powershell
winget install GitHub.Copilot
```

If install is blocked by permissions, rerun in Administrator PowerShell.

Alternative via npm:

```powershell
npm install -g @github/copilot
```

If global npm install is blocked by permissions, run PowerShell as Administrator.

## Verify

```powershell
copilot --version
```

## First run and login

```powershell
copilot
```

Inside the tool, run:

```text
/login
```

Then complete GitHub Copilot authorization in the browser:

1. Copilot CLI shows a login URL and/or one-time code.
2. Open the URL in your browser.
3. Sign in to GitHub.
4. Approve the Copilot CLI authorization request.
5. Return to terminal and confirm you are logged in.

Quick verification after login:

```powershell
copilot
```

If auth is still missing, run `/login` again.

## Note on older CLI extension

Older `gh copilot` extension is deprecated in favor of Copilot CLI.

## Next

- [10-minute onboarding](../../10-MINUTE-ONBOARDING.md)
- [Copilot CLI commands](./COMMANDS.md)
- [Copilot CLI examples](./EXAMPLES.md)
- [Common failure patterns and fastest recovery](../../knowledge/FAILURE-RECOVERY.md)

## Official docs

- https://github.com/github/copilot-cli
- https://docs.github.com/copilot/concepts/agents/about-copilot-cli
