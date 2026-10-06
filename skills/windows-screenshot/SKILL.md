---
name: windows-screenshot
description: Capture a full-content PNG of a native Windows app window at the correct display scale. Match by window title and return the saved path. Use for apps such as Flutter, VS Code, PowerShell, or Chrome. Do not use for browser pages.
---

# windows-screenshot

Capture a visible Windows app window as a PNG and return the saved path.

## When to use

Use this skill when the user asks for a screenshot of a running Windows app.

Typical trigger phrases:
- "screenshot the app"
- "grab a screenshot of the Windows app"
- "capture the Flutter window"
- "show me the VS Code window screenshot"

Do not use this skill for browser pages. Use the browser screenshot tool instead.

## How to invoke

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-folder>\capture.ps1" -Match "<window-title>"
```

Replace `<skill-folder>` with the folder containing this `SKILL.md` file.

Optional flags:
- `-OutDir "C:/some/dir"`
- `-WaitMs 500`

## Output Format

- The last printed line is the full PNG path.
- Other messages print before it.
- Exit codes:
- `0` success
- `2` no match
- `3` `GetWindowRect` failed
- `4` zero-size window
- `5` `PrintWindow` failed

## Safety Rules

- Do not read PNG bytes into chat unless user asks to inspect image.
- If multiple windows match, narrow with a more specific `-Match` value.

## Why this skill saves tokens

- Saves the display-scale and window-capture steps in one place.
- Returns one path line.
- Avoids repeating fixes for common capture problems.
