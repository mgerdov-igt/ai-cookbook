---
name: android-screenshot
description: Capture a screenshot from a connected Android device or emulator with ADB. Wake the device, find the open app, save a PNG in the temp folder, and return its path.
---

# android-screenshot

Capture an Android device screenshot via ADB and return the saved local path.

## When to use

Use this skill when the user asks for a screenshot from a connected Android device or emulator.

Typical trigger phrases:
- "take Android screenshot"
- "capture screenshot from connected phone"
- "grab screenshot of current Android app"
- "screenshot emulator app"

## When not to use

Do not use when:
- User needs screenshot of a native Windows app window (use windows-screenshot)
- User needs a browser screenshot

## Inputs

Required:
- None

Optional:
- `-DeviceId`: specific adb serial, otherwise first connected `device` state target is used
- `-OutDir`: local output directory (default is `%TEMP%\gsd-screenshots`)

## How to invoke

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-folder>\capture.ps1"
```

Replace `<skill-folder>` with the folder containing this `SKILL.md` file.

Or with a specific device:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-folder>\capture.ps1" -DeviceId "emulator-5554"
```

## Output Format

- The last printed line is the full PNG path.
- The script wakes the device before the screenshot.
- The script uses the open app's name in the file name.
- Other messages print before the final path.
- Error messages cover missing tools, device problems, and failed screenshots or copies.

## Exit codes

- `0`: success
- `2`: adb not found (SDK/platform-tools not installed or not discoverable)
- `3`: no connected Android device in `device` state
- `4`: requested device id not found in connected devices
- `5`: unable to detect foreground app
- `6`: screenshot capture failed on device
- `7`: screenshot pull to local machine failed
- `8`: unexpected error caught and reported gracefully

## Safety Rules

- Do not read PNG bytes into chat unless user asks to inspect image.
- If multiple devices are connected, either use `-DeviceId` or accept first detected device.

## Why this skill saves tokens

- Saves the ADB wake, capture, and copy steps in one place.
- Returns one path line, like windows-screenshot.
- Avoids repeating ADB and device-selection fixes.
