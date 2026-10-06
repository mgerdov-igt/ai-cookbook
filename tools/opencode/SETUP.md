# OpenCode Setup (Windows 11 + PowerShell 7)

## Prerequisites

- [Prerequisite tools](../PREREQUISITES-TOOLS.md), including Node.js and npm
- [PowerShell environment setup](../powershell/SETUP.md)
- Access to an approved AI provider and its API key

If you are still choosing a tool, start with [Tool selection](../TOOL-SELECTION.md).

## Install

```powershell
npm install -g opencode-ai
```

OpenCode recommends WSL for the best Windows compatibility. If you use WSL, install OpenCode and configure its API key and config file inside Linux; Windows and WSL environments are separate. See [WSL2 setup](../wsl/SETUP.md), [networking](../wsl/NETWORKING.md), and [company certificates](../wsl/CERTIFICATES.md).

## Configure a Provider

Create or edit the global config file:

```text
%USERPROFILE%\.config\opencode\opencode.json
```

Set `AI_PROVIDER_BASE_URL` and `AI_PROVIDER_API_KEY` in your user environment using your approved secure method. Use the endpoint, key, provider ID, and model ID given by your provider. Restart the terminal after changing environment variables. Do not publish internal endpoints or real keys.

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/glm-5.3",
  "provider": {
    "anthropic": {
      "options": {
        "baseURL": "{env:AI_PROVIDER_BASE_URL}",
        "apiKey": "{env:AI_PROVIDER_API_KEY}"
      },
      "models": {
        "claude-sonnet-5": { "name": "Claude Sonnet 5" },
        "claude-opus-5": { "name": "Claude Opus 5" },
        "claude-haiku-4-5": { "name": "Claude Haiku 4.5" },
        "glm-5.3": { "name": "GLM 5.3" }
      }
    }
  }
}
```

Keep this file private if it contains an internal endpoint. Never put a real API key in source control. Use GLM-5.3 only if your approved provider offers it. Some providers support models in OpenCode that may not work in other coding tools.

## Verify

```powershell
opencode --version
opencode models
opencode run "say pong"
```

The model list should include the models from your config, and the test prompt should receive a response.

## First Run

From your project directory:

```powershell
opencode
```

Switch models with `/models` in the TUI or `--model anthropic/<model-id>` on the CLI.

## Troubleshooting

- If configured models do not appear, check the config path and JSON syntax.
- If authentication fails, confirm `AI_PROVIDER_BASE_URL` and `AI_PROVIDER_API_KEY` are set without printing their values.
- In WSL, install Node.js and set the key inside Linux. See [WSL troubleshooting](../wsl/TROUBLESHOOTING.md) if needed.

## Next

- [OpenCode overview](./OVERVIEW.md)
- [OpenCode commands](./COMMANDS.md)
- [OpenCode examples](./EXAMPLES.md)
- [OpenCode troubleshooting](./TROUBLESHOOTING.md)
- [OpenCode cost control](./COST-CONTROL.md)
- [Tool selection](../TOOL-SELECTION.md)
- [Task-to-tool matrix](../TASK-TOOL-MATRIX.md)

## Official docs

- [OpenCode](https://opencode.ai/docs/)
- [Configuration](https://opencode.ai/docs/config/)
- [Providers](https://opencode.ai/docs/providers/)
- [Windows and WSL](https://opencode.ai/docs/windows-wsl)