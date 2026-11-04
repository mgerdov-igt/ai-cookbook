# TauShell Setup (Windows)

[TauShell](https://github.com/ma99us/tau-shell) is a Windows desktop app that runs AI coding tools in persistent PowerShell 7 sessions. Use it instead of installing and wiring each tool by hand. It installs missing tools after you confirm, resumes conversations, and loads the skills and prompts from this cookbook ([ai-cookbook](https://github.com/mgerdov-igt/ai-cookbook)) automatically.

TauShell is optional. The manual guides in [tools/](../README.md) still work.

## What It Replaces

| Manual step | In TauShell |
|---|---|
| [Install PowerShell 7](../PREREQUISITES-TOOLS.md) | First run offers a confirmed install |
| Install Copilot CLI, Claude Code, GSD, Codex CLI, or OpenCode | The Tools panel installs with winget or npm after you confirm |
| Copy skills into `~/.claude` or `~/.copilot` | Skills load from this cookbook with `--plugin-dir`; nothing is copied |
| Copy prompts from [Prompt templates](../../knowledge/PROMPT-TEMPLATES.md) | The Prompts menu offers them |
| Reopen and resume work by hand | Start, Stop, and Restore per session |

TauShell does not sign you in. Sign in to each AI tool once, inside its session.

## Prerequisites

- Windows 10 or later (Windows 11 recommended)
- Microsoft Edge WebView2 Runtime (already on current Windows 11)
- PowerShell 7 (TauShell offers to install it)

## Install

1. Download `TauShell-<version>-windows-x64.zip` from the [TauShell releases page](https://github.com/ma99us/tau-shell/releases).
2. Unblock the ZIP, then extract it to any folder:

   ```powershell
   Unblock-File .\TauShell-<version>-windows-x64.zip
   Expand-Archive .\TauShell-<version>-windows-x64.zip -DestinationPath $HOME\TauShell
   ```

3. Run `taushell.exe`. There is no installer, and no admin rights are needed.

Builds are not code-signed yet. If Windows SmartScreen shows "Windows protected your PC", choose **More info**, then **Run anyway**. To check a download first, see [Download](https://github.com/ma99us/tau-shell#download) in the TauShell README.

## Verify

1. TauShell opens on the Home page. Accept the PowerShell 7 install if it asks.
2. Open the Tools panel and install one AI tool, for example Copilot CLI.
3. Create a session in a project folder and start it. Sign in when the tool asks.
4. In the session, confirm the tool runs, for example `copilot --version`.

## First Run: Cookbook Skills and Prompts

TauShell reads [`tau-shell.yaml`](../../tau-shell.yaml) from this repository. A bundled copy works offline. Home checks GitHub for new commits and offers **Update skills**; it applies them only when you click.

- **Skills:** each skill listed in `tau-shell.yaml` loads into new or resumed Copilot CLI and Claude Code sessions. A skill you installed yourself wins. Toggle skills on Home. See the [skills guide](../../skills/README.md).
- **Prompts:** open **Prompts** in a running session. Entries named `Template - ...` come from [Prompt templates](../../knowledge/PROMPT-TEMPLATES.md). They are inserted, not sent, so fill in the `<placeholders>` first.

To try cookbook changes before they reach GitHub, point TauShell at your clone in `%USERPROFILE%\.tau_shell\config.yaml`:

```yaml
version: 1
skills:
  local_sources:
    - C:/path/to/your/ai-cookbook
```

See the [TauShell YAML schema](https://github.com/ma99us/tau-shell/blob/main/docs/v2/18-yaml-schema.md) for all settings.

## Add a Skill or Prompt to the Cookbook

1. Add the skill folder under `skills/` as described in the [skills guide](../../skills/README.md).
2. Add its name to the `skills` list in `tau-shell.yaml`. Unlisted skills stay hidden from TauShell.
3. For a prompt, add a `presets` entry on one line. A newline would send the prompt early.

## Troubleshooting

| Problem | Fix |
|---|---|
| SmartScreen blocks the app | Choose **More info**, then **Run anyway**, or unblock the ZIP before extracting |
| Smart App Control blocks it | It blocks unsigned apps and the prompt cannot bypass it. Use the manual guides in [tools/](../README.md) |
| A tool install fails | Use the vendor page or the tool's own guide in [tools/](../README.md) |
| A skill is missing | Check that `tau-shell.yaml` lists it, then click **Update skills** on Home |
| Skills do not show in Codex CLI, OpenCode, or GSD | TauShell does not load skills for them yet. Install skills by hand with the [skills guide](../../skills/README.md) |

Current status and known gaps are in the [TauShell README](https://github.com/ma99us/tau-shell#readme). For other problems, see [Failure recovery](../../knowledge/FAILURE-RECOVERY.md).
