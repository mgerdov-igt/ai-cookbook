# OpenCode Troubleshooting

## Configured models are missing

- Confirm the config is at `%USERPROFILE%\.config\opencode\opencode.json`.
- Validate the JSON from PowerShell:

```powershell
Get-Content "$env:USERPROFILE\.config\opencode\opencode.json" -Raw | ConvertFrom-Json | Out-Null
```

- Run `opencode models` again.

## Authentication fails

- Confirm the key is available to the current process without displaying it:

```powershell
Test-Path Env:AI_PROVIDER_API_KEY
```

- If you just added or changed the user variable, start a new terminal.
- Confirm the provider URL and API key are active, then review [setup](./SETUP.md).

## In WSL

Windows and WSL have separate config files, environment variables, and Node.js installs. Install and configure OpenCode in the same environment where you run it. See [WSL networking](../wsl/NETWORKING.md) and [company certificates](../wsl/CERTIFICATES.md) for connection problems.

## Official docs

- [Provider troubleshooting](https://opencode.ai/docs/providers/#troubleshooting)
- [Windows and WSL](https://opencode.ai/docs/windows-wsl)