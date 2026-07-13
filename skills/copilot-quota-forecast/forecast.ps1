#Requires -Version 5.1
# Copilot quota forecast example script.
# Prints a single JSON object to stdout. Warnings go to stderr.
#
# Files (all under %USERPROFILE%\.copilot-quota\):
#   config.json                       Optional. { "country": "US", "state": null, "holidays_enabled": true, "use_work_days_only": true }
#   holidays.txt                      Optional. Extra manual YYYY-MM-DD exclusions.
#   holidays-cache-<year>-<CC>.json   Auto-populated Nager.Date cache.
#   history.csv                       Rolling snapshot log (append-only).

[CmdletBinding()]
param()

# Only stop on critical failures (gh CLI). Holiday code has its own try/catch.
$ErrorActionPreference = 'Continue'

$configDir      = Join-Path $env:USERPROFILE '.copilot-quota'
if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir | Out-Null }
$historyFile    = Join-Path $configDir 'history.csv'
$manualHolidays = Join-Path $configDir 'holidays.txt'
$configFile     = Join-Path $configDir 'config.json'
$templateFile   = Join-Path $configDir 'template.config.json'

# --- Config & locale ------------------------------------------------------
$country          = $null
$state            = $null
$holidaysEnabled  = $true
$useWorkDaysOnly  = $true
$configSource     = 'auto-detect'
$configHint       = $null

if (Test-Path $configFile) {
    try {
        $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
        if ($cfg.PSObject.Properties.Match('country').Count -gt 0 -and $cfg.country) { $country = $cfg.country }
        if ($cfg.PSObject.Properties.Match('state').Count   -gt 0 -and $cfg.state)   { $state   = $cfg.state }
        if ($cfg.PSObject.Properties.Match('holidays_enabled').Count -gt 0) { $holidaysEnabled = [bool]$cfg.holidays_enabled }
        if ($cfg.PSObject.Properties.Match('use_work_days_only').Count -gt 0) { $useWorkDaysOnly = [bool]$cfg.use_work_days_only }
        elseif ($cfg.PSObject.Properties.Match('include_calendar_days').Count -gt 0) { $useWorkDaysOnly = -not [bool]$cfg.include_calendar_days }
        $configSource = 'active'
    } catch {
        Write-Warning "config.json parse failed: $_"
        $configSource = 'parse-error'
    }
} elseif (Test-Path $templateFile) {
    $configSource = 'template-only'
    $configHint   = "A template exists at $templateFile but no config.json. To customise country/state/holiday behaviour, copy the template to config.json in the same folder and edit values. Until then, the skill uses auto-detected defaults."
}
if (-not $country) {
    try {
        $geoId = (Get-WinHomeLocation).GeoId
        $country = ([System.Globalization.RegionInfo]::new([int]$geoId)).TwoLetterISORegionName
    } catch {}
}
if (-not $country) {
    try {
        $culture = (Get-Culture).Name
        if ($culture -match '-([A-Z]{2})$') { $country = $matches[1] }
    } catch {}
}

# --- Fetch quota via gh CLI (critical — must succeed) ---------------------
$raw = & gh api /copilot_internal/user 2>$null
if ($LASTEXITCODE -ne 0 -or -not $raw) {
    throw "gh api /copilot_internal/user failed. Ensure the GitHub CLI is installed and authenticated (gh auth status)."
}
$data = $raw | ConvertFrom-Json
$snap = $data.quota_snapshots.premium_interactions
$used        = [double]$snap.entitlement - [double]$snap.remaining
$remaining   = [double]$snap.remaining
$entitlement = [double]$snap.entitlement
$overageOk   = [bool]$snap.overage_permitted
$reset       = [datetime]::Parse($data.quota_reset_date_utc).ToUniversalTime()
$now         = [datetime]::UtcNow

# --- Append snapshot to rolling history -----------------------------------
try {
    if (-not (Test-Path $historyFile)) {
        'timestamp_utc,used,remaining,entitlement,percent_remaining' | Out-File -Encoding utf8 $historyFile
    }
    "$($now.ToString('o')),$([int]$used),$([int]$remaining),$([int]$entitlement),$($snap.percent_remaining)" |
        Add-Content -Encoding utf8 $historyFile
} catch { Write-Warning "History write failed: $_" }

# --- Holidays (fully optional, never fatal) -------------------------------
$holidayMap     = @{}
$holidaysSource = 'none'
try {
    if (-not $holidaysEnabled) {
        $holidaysSource = 'disabled'
    } elseif (-not $country) {
        $holidaysSource = 'no-country'
    } else {
        $year         = $now.Year
        $holidayCache = Join-Path $configDir ("holidays-cache-{0}-{1}.json" -f $year, $country)
        $rawHolidays  = @()

        # 1. Try cache
        if (Test-Path $holidayCache) {
            try {
                $parsed = Get-Content $holidayCache -Raw | ConvertFrom-Json
                if ($parsed -is [array]) { $rawHolidays = $parsed } elseif ($parsed) { $rawHolidays = @($parsed) }
                if ($rawHolidays.Count -gt 0) { $holidaysSource = 'cache' }
            } catch { Write-Warning ("Holiday cache read failed for {0}: {1}" -f $country, $_) }
        }

        # 2. Otherwise try Nager.Date (short timeout, no retry)
        if ($rawHolidays.Count -eq 0) {
            try {
                $url  = "https://date.nager.at/api/v3/PublicHolidays/{0}/{1}" -f $year, $country
                $resp = Invoke-RestMethod -Uri $url -TimeoutSec 4
                if ($resp) {
                    if ($resp -is [array]) { $rawHolidays = $resp } else { $rawHolidays = @($resp) }
                    if ($rawHolidays.Count -gt 0) {
                        $holidaysSource = 'api'
                        try { $resp | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 $holidayCache } catch {}
                    }
                }
            } catch {
                Write-Warning ("Holiday fetch failed for {0}/{1}: {2}" -f $country, $year, $_.Exception.Message)
                $holidaysSource = 'failed'
            }
        }

        # 3. Filter to current month + optional state
        if ($rawHolidays.Count -gt 0) {
            $monthStart = [datetime]::new($now.Year, $now.Month, 1)
            $monthEnd   = $monthStart.AddMonths(1).AddDays(-1)
            $stateCode  = if ($country -and $state) { "{0}-{1}" -f $country, $state } else { $null }
            foreach ($h in $rawHolidays) {
                try {
                    $d = [datetime]::Parse($h.date).Date
                    if ($d -lt $monthStart -or $d -gt $monthEnd) { continue }
                    $isNationwide = -not $h.counties -or $h.counties.Count -eq 0
                    $isForState   = $stateCode -and ($h.counties -contains $stateCode)
                    if ($isNationwide -or $isForState) { $holidayMap[$d] = $h.localName }
                } catch {}
            }
        }
    }
} catch {
    Write-Warning "Holiday processing failed unexpectedly: $_"
    $holidaysSource = 'failed'
    $holidayMap = @{}
}

# Merge manual holidays (also non-fatal)
try {
    if (Test-Path $manualHolidays) {
        $monthStart = [datetime]::new($now.Year, $now.Month, 1)
        $monthEnd   = $monthStart.AddMonths(1).AddDays(-1)
        Get-Content $manualHolidays | ForEach-Object {
            $line = $_.Trim()
            if (-not $line -or $line.StartsWith('#')) { return }
            try {
                $d = [datetime]::Parse($line).Date
                if ($d -ge $monthStart -and $d -le $monthEnd -and -not $holidayMap.ContainsKey($d)) {
                    $holidayMap[$d] = 'personal'
                }
            } catch {}
        }
    }
} catch { Write-Warning "Manual holidays read failed: $_" }

# --- Working-day counts ---------------------------------------------------
$monthStart = [datetime]::new($now.Year, $now.Month, 1)
$monthEnd   = $monthStart.AddMonths(1).AddDays(-1)
$workingDaysThisMonth = 0
$workingDaysRemaining = 0
$cur = $monthStart
while ($cur -le $monthEnd) {
    $isWeekend = $cur.DayOfWeek -eq [DayOfWeek]::Saturday -or $cur.DayOfWeek -eq [DayOfWeek]::Sunday
    $isHoliday = $holidayMap.ContainsKey($cur.Date)
    if (-not $isWeekend -and -not $isHoliday) {
        $workingDaysThisMonth++
        if ($cur.Date -gt $now.Date) { $workingDaysRemaining++ }
    }
    $cur = $cur.AddDays(1)
}

# --- Burn rate & projection (configurable basis) --------------------------
$periodStart   = $reset.AddMonths(-1)
$calendarDaysElapsed   = [math]::Max(0, ($now - $periodStart).TotalDays)
$calendarDaysRemaining = [math]::Max(0, ($reset - $now).TotalDays)

if ($useWorkDaysOnly) {
    $daysElapsed   = [math]::Max(0, $workingDaysThisMonth - $workingDaysRemaining)
    $daysRemaining = $workingDaysRemaining
    $burnPerDay    = if ($daysElapsed -gt 0) { $used / $daysElapsed } else { $null }
    $safeBudget    = if ($workingDaysRemaining -gt 0) { [math]::Round($remaining / $workingDaysRemaining) } else { $null }
} else {
    $daysElapsed   = $calendarDaysElapsed
    $daysRemaining = $calendarDaysRemaining
    $burnPerDay    = if ($daysElapsed -gt 0.5) { $used / $daysElapsed } else { $null }
    $safeBudget    = if ($daysRemaining -gt 0.01) { [math]::Round($remaining / $daysRemaining) } else { $null }
}

$projectedEnd  = if ($null -ne $burnPerDay) { [math]::Round($used + $burnPerDay * $daysRemaining) } else { $null }
$projectedPct  = if ($null -ne $projectedEnd) { [math]::Round($projectedEnd / $entitlement * 100, 1) } else { $null }

# --- Rolling burn from history --------------------------------------------
$burn24 = $null
$burn7d = $null
try {
    $history = @(Import-Csv $historyFile)
    if ($history.Count -gt 1) {
        $ago24 = $now.AddHours(-24)
        $ago7d = $now.AddDays(-7)
        $e24 = $history | Where-Object { [datetime]::Parse($_.timestamp_utc) -le $ago24 } | Select-Object -Last 1
        $e7d = $history | Where-Object { [datetime]::Parse($_.timestamp_utc) -le $ago7d } | Select-Object -Last 1
        if ($e24) { $burn24 = [int]$used - [int]$e24.used }
        if ($e7d) { $burn7d = [int]$used - [int]$e7d.used }
    }
} catch { Write-Warning "History read failed: $_" }

# --- Verdict --------------------------------------------------------------
if ($null -eq $projectedPct) {
    $vIcon = '?'; $vText = 'Insufficient data'; $vNote = 'Not enough elapsed time to project.'
} elseif ($projectedPct -le 90) {
    $vIcon = 'OK'; $vText = 'Safe'; $vNote = "At current pace you will finish the month at $projectedPct% of quota."
} elseif ($projectedPct -le 100) {
    $vIcon = 'WARN'; $vText = 'Tight'; $vNote = "Projected $projectedPct% - track daily."
} elseif ($overageOk -and $projectedPct -le 120) {
    $vIcon = 'WARN'; $vText = 'Will exceed (overage allowed)'; $vNote = "Projected $projectedPct% - overage is permitted on your plan."
} else {
    $vIcon = 'FAIL'; $vText = 'On track to run out'; $vNote = "Projected $projectedPct% - reduce daily usage."
}

# --- Emit JSON ------------------------------------------------------------
$holidayList = @()
foreach ($kv in ($holidayMap.GetEnumerator() | Sort-Object Key)) {
    $holidayList += [PSCustomObject]@{ date = $kv.Key.ToString('yyyy-MM-dd'); name = $kv.Value }
}

[PSCustomObject]@{
    now_utc                  = $now.ToString('o')
    login                    = $data.login
    plan                     = $data.copilot_plan
    reset_utc                = $reset.ToString('o')
    country                  = $country
    state                    = $state
    config_source            = $configSource
    config_hint              = $configHint
    use_work_days_only       = $useWorkDaysOnly
    holidays_source          = $holidaysSource
    used                     = [int]$used
    remaining                = [int]$remaining
    entitlement              = [int]$entitlement
    percent_used             = [math]::Round(100 - $snap.percent_remaining, 1)
    percent_remaining        = $snap.percent_remaining
    days_elapsed             = [math]::Round($daysElapsed, 1)
    days_remaining           = [math]::Round($daysRemaining, 1)
    working_days_this_month  = $workingDaysThisMonth
    working_days_remaining   = $workingDaysRemaining
    holidays_this_month      = $holidayList
    burn_per_day             = if ($null -ne $burnPerDay) { [math]::Round($burnPerDay) } else { $null }
    burn_last_24h            = $burn24
    burn_last_7d             = $burn7d
    projected_month_end      = $projectedEnd
    projected_percent        = $projectedPct
    safe_daily_budget        = $safeBudget
    overage_permitted        = $overageOk
    verdict_icon             = $vIcon
    verdict_text             = $vText
    verdict_note             = $vNote
    history_file             = $historyFile
} | ConvertTo-Json -Depth 4
