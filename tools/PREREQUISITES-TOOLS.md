# Prerequisite Tools (Windows 11)

Install these first before any tool-specific setup.

## 0) Install or verify WinGet

On Windows 11, WinGet is provided by App Installer.

Verify first:

```powershell
winget --version
```

If the command is missing:

1. Install or update App Installer from Microsoft Store:
	- https://apps.microsoft.com/detail/9NBLGGH4NNS1
2. Restart PowerShell.
3. Verify again with `winget --version`.

If Microsoft Store is blocked in your environment, use the official WinGet project releases for enterprise/offline guidance:
- https://github.com/microsoft/winget-cli/releases

Note on Administrator mode:
- Checking `winget --version` does not require admin.
- Installing system components (like App Installer in managed environments) can require Administrator PowerShell.

## 1) PowerShell 7+

Recommended install with WinGet:

```powershell
winget search --id Microsoft.PowerShell --exact
winget install --id Microsoft.PowerShell --source winget
```

If install is blocked by permissions, rerun in Administrator PowerShell.

If WinGet is unavailable, install from the official MSI release page:
- https://github.com/PowerShell/PowerShell/releases

Verify:

```powershell
pwsh -v
$PSVersionTable.PSVersion
```

## 2) NVM for Windows (Node Version Manager)

Administrator PowerShell is typically required for standard NVM for Windows install and version-switch operations.

Install with WinGet:

```powershell
winget install CoreyButler.NVMforWindows
```

Run the install command in Administrator PowerShell when required by your setup.

If WinGet is unavailable, install from the official NVM for Windows releases page:
- https://github.com/coreybutler/nvm-windows/releases

Install and use the latest Node.js version:

```powershell
nvm install latest
nvm use latest
node -v
npm -v
```

Run `nvm install` and `nvm use` in Administrator PowerShell when required by your setup.

If `nvm` is not recognized right after install, close and reopen PowerShell.

If you prefer LTS instead:

```powershell
nvm install lts
nvm use lts
node -v
npm -v
```

## 3) Git for Windows

Install with WinGet:

```powershell
winget install Git.Git
```

If install is blocked by permissions, rerun in Administrator PowerShell.

If WinGet is unavailable, install from:
- https://git-scm.com/download/win

Verify:

```powershell
git --version
```

Optional initial identity setup:

```powershell
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

## 4) Quick verification for this repo

```powershell
pwsh -v
node -v
npm -v
git --version
```

## If you're in WSL

This page's commands target Windows. In WSL, install tools inside Linux; Windows installs do not carry over. Start with [WSL2 setup](./wsl/SETUP.md). See [networking](./wsl/NETWORKING.md) or [company certificates](./wsl/CERTIFICATES.md) if needed.

## Official docs

- PowerShell: https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows?view=powershell-7.6#msi
- NVM for Windows: https://github.com/coreybutler/nvm-windows
- Git for Windows: https://git-scm.com/download/win
