param(
    [Parameter(Mandatory)]
    [ValidateSet('status-filter', 'owner-filter')]
    [string]$Track
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'WorkItems.ps1')

$failures = 0
$items = @(Get-WorkItems)

if ($items.Count -ne 4) {
    Write-Host "[FAIL] Baseline list should contain 4 items; found $($items.Count)."
    $failures++
} else {
    Write-Host '[PASS] Baseline list contains 4 items.'
}

try {
    if ($Track -eq 'status-filter') {
        $filtered = @(Get-WorkItems -Status 'open')
        if ($filtered.Count -ne 2 -or @($filtered | Where-Object Status -ne 'Open').Count -ne 0) {
            Write-Host '[FAIL] Status filter should return only both Open items.'
            $failures++
        } else {
            Write-Host '[PASS] Status filter matches without regard to case.'
        }

        $noMatch = @(Get-WorkItems -Status 'Blocked')
        if ($noMatch.Count -ne 0) {
            Write-Host '[FAIL] An unmatched status should return no items.'
            $failures++
        } else {
            Write-Host '[PASS] An unmatched status returns no items.'
        }
    } else {
        $filtered = @(Get-WorkItems -Owner 'ava')
        if ($filtered.Count -ne 2 -or @($filtered | Where-Object Owner -ne 'Ava').Count -ne 0) {
            Write-Host '[FAIL] Owner filter should return only both Ava items.'
            $failures++
        } else {
            Write-Host '[PASS] Owner filter matches without regard to case.'
        }

        $noMatch = @(Get-WorkItems -Owner 'Casey')
        if ($noMatch.Count -ne 0) {
            Write-Host '[FAIL] An unmatched owner should return no items.'
            $failures++
        } else {
            Write-Host '[PASS] An unmatched owner returns no items.'
        }
    }

    $unfiltered = @(Get-WorkItems)

    if ($unfiltered.Count -ne 4 -or (($unfiltered.Id -join ',') -ne '101,102,103,104')) {
        Write-Host '[FAIL] Omitting the filter should preserve all items and their order.'
        $failures++
    } else {
        Write-Host '[PASS] Omitting the filter preserves the original list and order.'
    }
} catch {
    Write-Host "[FAIL] The $Track checks could not run: $($_.Exception.Message)"
    $failures++
}

if ($failures -gt 0) {
    Write-Host "$failures check(s) failed."
    exit 1
}

Write-Host 'All checks passed.'
