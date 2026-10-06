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

This skill works with any AI tool that can run PowerShell. Use the script stored beside this `SKILL.md` file. Replace `<skill-folder>` with its installed folder path.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-folder>\forecast.ps1"
```

If shell is not PowerShell:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "<skill-folder>\forecast.ps1"
```

## Output Format

- Script prints exactly one JSON object to stdout.
- If script fails, do not fabricate values.
- Treat null fields as `n/a` in rendered output.
- Treat `today` as the user's local calendar day, not a rolling 24-hour window.

Primary fields:
- `used`, `remaining`, `entitlement`, `percent_used`
- `days_elapsed`, `days_remaining`
- `burn_per_day`, `burn_today_local`, `burn_last_24h`, `burn_last_7d`
- `projected_month_end`, `projected_percent`, `safe_daily_budget`
- `today_usage_note`
- `verdict_icon`, `verdict_text`, `verdict_note`

Render guidance:
- Use `burn_today_local` for "today budget usage" and "today progress".
- If `today_usage_note` is present, print it as a note instead of substituting `burn_last_24h`.
- Keep `burn_last_24h` and `burn_last_7d` as separate rolling reference metrics.

## Safety Rules

- Never store raw JSON in workspace files unless user asks.
- Never echo tracking IDs, org IDs, enterprise fields, or location fields unless user asks.
- If `gh` is not authenticated, report fix: run `gh auth login`.

## Why this skill saves tokens

- Data collection and calculations happen in script, not chat.
- Report format is stable and compact.
- Repeated prompt boilerplate is replaced by one invocation.
