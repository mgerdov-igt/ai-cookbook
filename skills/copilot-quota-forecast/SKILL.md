---
name: copilot-quota-forecast
description: Forecast monthly quota burn rate and report risk before reset date. Use when user asks about quota, burn rate, credits remaining, or whether they will run out before month end.
---

# copilot-quota-forecast

Run a local script that gathers quota data and returns a compact, structured forecast.

## When to use

Use this skill when the user asks:
- "how much quota do I have left"
- "am I going to run out this month"
- "show quota burn forecast"
- "what is my daily safe budget"

## How to invoke

Preferred command:

```powershell
& "$PSScriptRoot\forecast.ps1"
```

If shell is not PowerShell:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "skills/copilot-quota-forecast/forecast.ps1"
```

## Output contract

- Script prints exactly one JSON object to stdout.
- If script fails, do not fabricate values.
- Treat null fields as `n/a` in rendered output.

Primary fields:
- `used`, `remaining`, `entitlement`, `percent_used`
- `days_elapsed`, `days_remaining`
- `burn_per_day`, `burn_last_24h`, `burn_last_7d`
- `projected_month_end`, `projected_percent`, `safe_daily_budget`
- `verdict_icon`, `verdict_text`, `verdict_note`

## Guardrails

- Never store raw JSON in workspace files unless user asks.
- Never echo tracking IDs, org IDs, enterprise fields, or location fields unless user asks.
- If `gh` is not authenticated, report fix: run `gh auth login`.

## Why this skill saves tokens

- Data collection and calculations happen in script, not chat.
- Report format is stable and compact.
- Repeated prompt boilerplate is replaced by one invocation.
