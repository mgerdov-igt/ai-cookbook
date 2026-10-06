# PowerShell Environment Setup for AI Tools

This page configures PowerShell after prerequisite installs.

Install prerequisites first:
- [Prerequisite tools](../PREREQUISITES-TOOLS.md)

Need the quick version for items 1, 3, and optional 4?
- [PowerShell bootstrap](./BOOTSTRAP.md)

## 1) Execution policy for user scripts

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## 2) Confirm required commands are on PATH

```powershell
Get-Command pwsh
Get-Command git
Get-Command node
Get-Command npm
```

## 3) Environment variables that often matter

These are the most common environment issues that break AI CLI tools.

### Custom CA certificates for Node-based tools

```powershell
[Environment]::SetEnvironmentVariable('NODE_EXTRA_CA_CERTS', 'C:\certs\corp-ca.pem', 'User')
```

This is useful when installs or logins fail with TLS or certificate errors.

If your environment uses zScaler or another HTTPS inspection layer, set `NODE_EXTRA_CA_CERTS` to the exported corporate root certificate.

TODO:
- Replace `C:\certs\corp-ca.pem` with the actual zScaler/custom certificate path used in your environment.

### Quick PATH refresh for current shell

```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
```

Use this after installs if you do not want to reopen PowerShell immediately.

### Basic environment sanity checks

```powershell
$env:USERPROFILE
$env:TEMP
$env:TMP
Test-Path $env:USERPROFILE
Test-Path $env:TEMP
```

Broken or unwritable profile/temp locations can cause CLI installs, auth flows, or logs to fail.

## 4) Optional but recommended

- Install Windows Terminal for better tabbed workflows.
- Use Git Credential Manager (bundled with Git for Windows).
- Configure SSH keys for GitHub if you use SSH remotes.
- Use a PowerShell profile only if you want persistent aliases/functions.

## Troubleshooting

- If a command is not found after install, restart terminal.
- If npm global tools are missing, verify your npm global bin path is in PATH.
- If installer scripts are blocked, confirm `RemoteSigned` policy in current session.
- If HTTPS requests fail with trust errors, check `NODE_EXTRA_CA_CERTS` or corporate certificate setup.

## Next

- [PowerShell bootstrap](./BOOTSTRAP.md)
- [PowerShell basics](./BASICS.md)
- [GSD setup](../gsd-pi/SETUP.md)
- [Copilot CLI setup](../copilot-cli/SETUP.md)
- [Claude Code setup](../claude-code/SETUP.md)
