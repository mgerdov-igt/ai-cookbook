---
name: windows-screenshot
description: Capture a DPI-correct, full-content PNG of a native Windows app window by title substring and return the saved file path. Use when users ask for screenshots of running Windows apps (for example Flutter desktop apps, VS Code, PowerShell, or Chrome app windows). Do not use for browser-harness page screenshots.
---

# windows-screenshot

Capture a native Windows top-level window as a PNG and return the saved path.

## When to use

Use this skill when user asks for screenshot evidence of a running Windows app window.

Typical trigger phrases:
- "screenshot the app"
- "grab a screenshot of the Windows app"
- "capture the Flutter window"
- "show me the VS Code window screenshot"

Do not use this skill for browser pages controlled by browser tooling.

## How to invoke

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "skills/windows-screenshot/capture.ps1" -Match "rtp_retailer"
```

Optional flags:
- `-OutDir "C:/some/dir"`
- `-WaitMs 500`

## Output contract

- Final stdout line is absolute PNG path.
- Diagnostics print on earlier lines.
- Exit codes:
- `0` success
- `2` no match
- `3` `GetWindowRect` failed
- `4` zero-size window
- `5` `PrintWindow` failed

## Guardrails

- Do not read PNG bytes into chat unless user asks to inspect image.
- If multiple windows match, narrow with a more specific `-Match` value.

## Why this skill saves tokens

- Encodes complex DPI/window-capture behavior once.
- Produces tiny deterministic output (one path).
- Avoids repeated troubleshooting prompts for common capture failures.
