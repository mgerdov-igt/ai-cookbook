# GSD Pi Setup (Windows 11 + PowerShell 7)

## Prerequisites

- [Prerequisite tools](../PREREQUISITES-TOOLS.md)
- [PowerShell environment setup](../powershell/SETUP.md)

If you are still choosing a tool, start with [Tool selection cheat sheet](../TOOL-SELECTION.md).

## Install

Install globally with npm:

```powershell
npm install -g @opengsd/gsd-pi@latest
```

If global npm install is blocked by permissions, run PowerShell as Administrator and retry.

## Verify

```powershell
where.exe gsd
gsd --version
```

## First run

```powershell
gsd
```

Follow the in-terminal setup flow and choose your provider.

## Login with GitHub Copilot provider (browser auth)

If you want to use GitHub Copilot through GSD:

1. Start GSD:

```powershell
gsd
```

2. Open provider configuration in GSD:

```text
/gsd config
```

3. Select the GitHub Copilot provider.
4. Follow the prompt to open the browser authorization page.
5. Sign in to GitHub and approve the authorization request.
6. Return to GSD and confirm provider status.

Check status in-session:

```text
/gsd status
```

If provider auth did not complete, run `/gsd config` again and repeat browser authorization.

## Migration from old install (if needed)

```powershell
npm uninstall -g gsd-pi @opengsd/gsd-pi
Remove-Item "$env:USERPROFILE\.gsd\.update-check" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\.gsd\agent\managed-resources.json" -Force -ErrorAction SilentlyContinue
npm install -g @opengsd/gsd-pi@latest
```

If uninstall/install reports permission errors, run PowerShell as Administrator.

## Upgrade gotcha (new version just released)

Sometimes `gsd upgrade` can fail shortly after a new GSD version is published.

Manual fallback:

```powershell
npm uninstall -g @opengsd/gsd-pi
npm install -g @opengsd/gsd-pi@latest
```

Then verify:

```powershell
gsd --version
```

## Next

- [10-minute onboarding](../../10-MINUTE-ONBOARDING.md)
- [GSD commands](./COMMANDS.md)
- [GSD examples](./EXAMPLES.md)
- [Common failure patterns and fastest recovery](../../knowledge/FAILURE-RECOVERY.md)

## Official docs

- https://github.com/open-gsd/gsd-pi
