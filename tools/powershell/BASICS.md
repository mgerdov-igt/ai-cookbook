# PowerShell Basics for AI Tooling

A minimal command set you will use often.

## Navigation and file checks

```powershell
Get-Location
Get-ChildItem
Set-Location <path>
Test-Path <path>
```

## Git and command checks

```powershell
git status
Get-Command gsd
Get-Command copilot
Get-Command claude
```

## Profiles and environment

```powershell
$PROFILE
notepad $PROFILE
$env:Path
[Environment]::GetEnvironmentVariable('Path', 'User')
[Environment]::GetEnvironmentVariable('Path', 'Machine')
$env:NODE_EXTRA_CA_CERTS
```

## Logs and text search

```powershell
Get-Content .\README.md -TotalCount 40
Get-ChildItem -Recurse -Filter *.md
```

## Recommended habits

- Run commands from the repo root unless needed otherwise.
- Keep one terminal for edits and one for verification.
- Copy exact error output into AI prompts.

## Next

- [Common best practices](../../knowledge/COMMON-BEST-PRACTICES.md)
- [Quickstart](../../QUICKSTART.md)
