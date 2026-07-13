# Skills and Scripts for Token-Saving Automation

Use skills when a task is repetitive, has stable inputs, and needs a predictable output.

## What skills are best for

Use a skill when:
- You run the same workflow multiple times a day
- You keep re-explaining the same steps to an agent
- The task can be reduced to a series of commands with structured input and output
- You want safer defaults (read-only first, explicit guardrails)

Do not use a skill when:
- The task is one-off and exploratory
- Inputs change wildly every run
- You still do not know what "good output" looks like

## How skills save context and tokens

Skills reduce token usage by moving long instructions out of chat (context window) and into reusable files, to be read on demand.

They save tokens by:
- Replacing repeated prompt boilerplate with one short invocation
- Returning compact script output instead of long natural-language reasoning
- Avoiding back-and-forth on known steps and guardrails
- Keeping workflow logic versioned in files, not retyped per session

## Skill-first, script-second

1. Write the skill contract first:
- Trigger phrases
- Required inputs
- Output contract
- Guardrails

2. Implement the script second:
- One command that runs end-to-end
- Structured output (JSON or one deterministic final line)
- Clear non-zero exit codes for common failures

3. Add a minimal prompt/command wrapper only if needed.

## What makes a good skill description (auto-detect)

Good descriptions are concrete and match real user phrasing.

Include:
- Exact trigger phrases users type (for example: "screenshot app window", "quota forecast")
- Clear tool boundary (when to use this skill, when not to)
- Input normalization rules (substring match, expected date format)
- Output contract (which line/field is authoritative)
- Failure and fallback behavior

Avoid:
- Vague descriptions like "helps with debugging"
- Missing boundaries with other tools
- Output formats that change run to run

## Recommended folder pattern

```text
skills/
  <skill-name>/
    SKILL.md
    <script>.ps1
    README.md (optional)
```

Keep each skill folder self-contained so it can be copied and reused.

## 30-second preflight

Before running any skill, verify:
- Required command exists (provider CLI, `adb`, or other required tool)
- Required runtime is available (connected device/app/session)
- Expected output contract is known (JSON object or final path line)

## Skill index

| Skill | Platform | Requires | Output contract |
| --- | --- | --- | --- |
| [copilot-quota-forecast](./copilot-quota-forecast/SKILL.md) | Windows | authenticated provider CLI (`gh` in this example) | Single JSON object |
| [windows-screenshot](./windows-screenshot/SKILL.md) | Windows | desktop app window | Final stdout line is PNG path |
| [android-screenshot](./android-screenshot/SKILL.md) | Android device/emulator + Windows host | `adb`, connected device | Final stdout line is PNG path |

## Quick decision table

| Request type | Use this | Example phrase | Common wrong choice |
| --- | --- | --- | --- |
| Quota and burn forecast | [copilot-quota-forecast](./copilot-quota-forecast/SKILL.md) | "Will I run out of quota this month?" | Long ad-hoc prompt without running the forecast script |
| Screenshot of native Windows app | [windows-screenshot](./windows-screenshot/SKILL.md) | "Capture a screenshot of the Flutter app window" | Browser screenshot tooling for non-browser native app windows |
| Screenshot of connected Android device app | [android-screenshot](./android-screenshot/SKILL.md) | "Take screenshot from connected Android phone" | `windows-screenshot` when target is Android device/emulator |
| Browser page screenshot (harness/browser tool) | Browser screenshot tooling | "Screenshot this web page in the browser" | `windows-screenshot` for browser pages |

## Reusable skill template

Use [TEMPLATE-SKILL.md](./TEMPLATE-SKILL.md) as a starting point for new skills.
It includes required metadata, trigger phrases, boundaries, output contract, exit codes, and guardrails.

## Reusing a skill in another repo or tool

If you created a skill for one repo or one tool and want to reuse it elsewhere, the easiest path is to ask the AI agent to "import" the existing skill and provide the file system path to that skill folder.

Practical prompt example:
- "Import existing skill from C:/path/to/skills/windows-screenshot into this repo."

Copy/paste starters:
- Same repo: "Import existing skill from ./skills/windows-screenshot into this repo."
- Cross repo/tool: "Import existing skill from C:/path/to/other-repo/skills/android-screenshot into this repo and adapt paths only if needed."

This avoids rebuilding the same skill from scratch and helps preserve proven trigger phrases, output contracts, and guardrails.

## Example skills in this repo

- [Copilot quota forecast example](./copilot-quota-forecast/SKILL.md)
- [Windows screenshot capture example](./windows-screenshot/SKILL.md)
- [Android screenshot capture example](./android-screenshot/SKILL.md)

## Example 1: Copilot quota forecast

How it works:
1. Skill runs [forecast.ps1](./copilot-quota-forecast/forecast.ps1).
2. Script calls a provider quota endpoint via provider CLI.
3. Script enriches with country + holidays + local history.
4. Script emits one JSON object.
5. Skill formats that JSON into a compact report and hides sensitive fields by default.

Why it saves tokens:
- No need to re-explain API fields and reporting format every run.
- Script handles data collection deterministically.
- Skill enforces compact, repeatable output.

Source this was ported from:
- `<user-home>/.copilot-quota/`

Fast fail:
- If provider CLI call fails, run auth status and re-authenticate (`gh auth status`, `gh auth login` in this example).

## Example 2: Windows screenshot capture

How it works:
1. Skill runs [capture.ps1](./windows-screenshot/capture.ps1) with a title substring.
2. Script finds a visible top-level window, restores it if minimized, and captures with `PrintWindow`.
3. Script saves PNG to temp and prints the absolute path as the final line.
4. Skill returns the saved file path without trying to inline image bytes.

Why it saves tokens:
- Avoids repeated troubleshooting for DPI/window-capture edge cases.
- Output contract is tiny: one path line.
- Prevents expensive "read image into context" behavior unless explicitly requested.

Source this was ported from:
- `<other-repo>/.gsd/skills/screenshot/`

Fast fail:
- If no window matches, list candidates with `Get-Process | Where-Object MainWindowTitle | Select-Object Id,ProcessName,MainWindowTitle`.

## Example 3: Android screenshot capture

How it works:
1. Skill runs [capture.ps1](./android-screenshot/capture.ps1).
2. Script detects connected adb device (or uses provided device id).
3. Script wakes device to avoid screensaver/idle lock visual state.
4. Script detects foreground app and uses it in output filename.
5. Script captures screenshot on device, pulls it to temp, and returns local path as final line.

Why it saves tokens:
- Encodes repeated adb wake/detect/capture/pull workflow once.
- Same deterministic path-only output pattern as windows-screenshot.
- Reduces repeated device-selection and command-debug prompting.

Fast fail:
- If no device is usable, run `adb devices` and resolve `unauthorized` by accepting USB debugging prompt on device.

Rule of thumb:
- If you repeat the same workflow 3+ times in a week, create a skill.
- If a script can emit deterministic JSON or a deterministic final line, prefer script-backed skill flow.

