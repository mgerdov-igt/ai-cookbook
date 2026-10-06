# PowerShell Bootstrap (Items 1, 3, 4)

This page is a fast setup pass for:
- 1) Execution policy
- 3) PATH/command validation
- 4) Optional environment checks

## Run once in PowerShell

```powershell
# 1) Execution policy (CurrentUser only)
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force

# 3) Validate required commands are available
$required = @('pwsh', 'git', 'node', 'npm', 'nvm')
$results = foreach ($cmd in $required) {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        Command = $cmd
        Found = [bool]$found
        Source = if ($found) { $found.Source } else { '' }
    }
}

$results | Format-Table -AutoSize

if ($results.Where({ -not $_.Found }).Count -gt 0) {
    Write-Host "Missing required commands. Install prerequisites first:" -ForegroundColor Yellow
    Write-Host (Join-Path (Split-Path $PSScriptRoot) 'PREREQUISITES-TOOLS.md') -ForegroundColor Yellow
} else {
    Write-Host "All required commands are available." -ForegroundColor Green
}

# 4) Optional checks
$optionalChecks = @(
    [PSCustomObject]@{ Name = 'Windows Terminal'; Found = [bool](Get-Command wt -ErrorAction SilentlyContinue) },
    [PSCustomObject]@{ Name = 'SSH key exists'; Found = Test-Path "$env:USERPROFILE\.ssh\id_ed25519.pub" }
)

$optionalChecks | Format-Table -AutoSize
```

## If nvm or node is missing

Install prerequisites and restart terminal:
- [Prerequisite tools](../PREREQUISITES-TOOLS.md)

## Next

- [PowerShell environment setup](./SETUP.md)
- [PowerShell basics](./BASICS.md)
