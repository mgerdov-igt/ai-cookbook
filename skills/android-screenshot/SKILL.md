---
name: android-screenshot
description: Capture a screenshot from the currently connected Android device using ADB, wake the device first, detect the foreground app, save a PNG to system temp, and return the saved path. Use when users ask for screenshots from Android apps running on a connected device or emulator.
---

# android-screenshot

Capture an Android device screenshot via ADB and return the saved local path.

## When to use

Use this skill when user asks for screenshot evidence from a connected Android device or emulator.

Typical trigger phrases:
- "take Android screenshot"
- "capture screenshot from connected phone"
- "grab screenshot of current Android app"
- "screenshot emulator app"

## When not to use

Do not use when:
- User needs screenshot of a native Windows app window (use windows-screenshot)
- User needs browser-harness screenshot tooling

## Inputs

Required:
- None

Optional:
- `-DeviceId`: specific adb serial, otherwise first connected `device` state target is used
- `-OutDir`: local output directory (default is `%TEMP%\gsd-screenshots`)

## How to invoke

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "skills/android-screenshot/capture.ps1"
```

Or with a specific device:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "skills/android-screenshot/capture.ps1" -DeviceId "emulator-5554"
```

## Output contract

- Final stdout line is absolute PNG path.
- Script wakes device before capture to avoid blank/screensaver frames.
- Script detects current foreground app and uses it in the output file name.
- Diagnostics are printed on earlier lines.
- Script gracefully reports setup/runtime problems with clear messages (missing SDK/adb, no device, unauthorized/offline device state, capture or pull failures).

## Exit codes

- `0`: success
- `2`: adb not found (SDK/platform-tools not installed or not discoverable)
- `3`: no connected Android device in `device` state
- `4`: requested device id not found in connected devices
- `5`: unable to detect foreground app
- `6`: screenshot capture failed on device
- `7`: screenshot pull to local machine failed
- `8`: unexpected error caught and reported gracefully

## Guardrails

- Do not read PNG bytes into chat unless user asks to inspect image.
- If multiple devices are connected, either use `-DeviceId` or accept first detected device.

## Why this skill saves tokens

- Encodes repetitive ADB wake + capture + pull workflow once.
- Produces deterministic output contract identical to windows-screenshot style.
- Avoids repeated troubleshooting for adb/device selection and output naming.
