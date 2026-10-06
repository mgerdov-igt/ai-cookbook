# Codex CLI Setup (Windows 11 + PowerShell 7)

## Prerequisites

- [Prerequisite tools](../PREREQUISITES-TOOLS.md), including Node.js and npm
- [PowerShell environment setup](../powershell/SETUP.md)
- An eligible ChatGPT plan or configured API access

If you are still choosing a tool, start with [Tool selection](../TOOL-SELECTION.md).

## Install

```powershell
npm install -g @openai/codex
```

## Verify

```powershell
codex --version
```

## First Run

From your project directory:

```powershell
codex
```

Follow the sign-in prompt. To use Codex with a ChatGPT plan, choose **Sign in with ChatGPT**. API-key authentication requires separate setup; see the official [authentication guide](https://developers.openai.com/codex/auth/).

## Next

- [Codex CLI overview](./OVERVIEW.md)
- [Codex CLI commands](./COMMANDS.md)
- [Codex CLI examples](./EXAMPLES.md)
- [Common failure patterns and fastest recovery](../../knowledge/FAILURE-RECOVERY.md)

## Official docs

- [Codex CLI](https://developers.openai.com/codex/cli/)
- [Codex CLI repository](https://github.com/openai/codex)
