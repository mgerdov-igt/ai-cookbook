# Tool-Neutral Skills and Scripts

Use a skill when you repeat a task, use known inputs, and want the same kind of result each time.

## Portable Skill Format

Each skill is a folder with a `SKILL.md` file. The open [Agent Skills format](https://agentskills.io/) uses `name` and `description` in YAML frontmatter, followed by Markdown instructions. Compatible AI tools can use the same folder.

Keep `SKILL.md` focused on the task, not one AI tool. Avoid tool-specific slash commands and frontmatter fields in the shared instructions. A skill can include scripts and reference files, but list their required programs and operating systems. The instructions should tell the AI tool what to do; scripts should do repeatable work.

## Install for Personal Use

Copy the whole skill folder to the personal skills folder used by your AI tool. The path varies by tool. For example:

- Claude Code: `~/.claude/skills/<skill-name>/`
- OpenCode: `~/.config/opencode/skills/<skill-name>/` or `~/.agents/skills/<skill-name>/`

For any other compatible tool, check its docs for the global skills folder and how to reload skills. Restart or reload the tool after installing. If a tool does not support Agent Skills, adapt only the wrapper; keep the shared instructions and scripts unchanged where possible.

In PowerShell, copy a whole skill folder to the destination used by your tool:

```powershell
$skill = "skills\windows-screenshot"
$personalSkills = "$HOME\.claude\skills"
New-Item -ItemType Directory -Force -Path $personalSkills | Out-Null
Copy-Item -Recurse -Path $skill -Destination $personalSkills
```

Change `$personalSkills` to the global skills folder for your AI tool.

## What skills are best for

Use a skill when:
- You run the same task often
- You keep explaining the same steps to an AI tool
- The task uses known inputs and returns a set format
- You want safe defaults, such as read-only checks first

Do not use a skill when:
- The task is one-off and exploratory
- Inputs change wildly every run
- You still do not know what "good output" looks like

## How Skills Save Time and Tokens

Skills save tokens by keeping long instructions in files instead of repeating them in every chat. The tool reads them when needed.

They save tokens by:
- Replacing repeated prompt text with one short request
- Returning short script output instead of a long explanation
- Avoiding repeat questions about known steps and safety rules
- Keeping instructions in files instead of retyping them each time

## Write the Instructions, Then the Script

1. Write the skill instructions first:
- When to use it
- Required inputs
- Expected output
- Safety rules

2. Implement the script second:
- One command that runs the full task
- Fixed-format output (JSON or one final result line)
- Clear error codes for common failures

3. Add a minimal prompt/command wrapper only if needed.

## Write a Clear Skill Description

Good descriptions are concrete and match real user phrasing.

Include:
- Example requests that should start the skill (such as "screenshot app window")
- When to use it and when not to
- How to read inputs (such as date format)
- What the result must contain and where to find it
- What to do when it fails

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

Keep each skill's files together so you can copy and reuse the whole folder.

## Before You Run a Skill

Before running any skill, verify:
- Required command exists (provider CLI, `adb`, or other required tool)
- Required runtime is available (connected device/app/session)
- Expected result format is known (JSON object or final path line)

## Skill index

| Skill | Platform | Requires | Result |
| --- | --- | --- | --- |
| [copilot-quota-forecast](./copilot-quota-forecast/SKILL.md) | Windows | authenticated provider CLI (`gh` in this example) | Single JSON object |
| [windows-screenshot](./windows-screenshot/SKILL.md) | Windows | desktop app window | Final stdout line is PNG path |
| [android-screenshot](./android-screenshot/SKILL.md) | Android device/emulator + Windows host | `adb`, connected device | Final stdout line is PNG path |
| [github-pr-flow](./github-pr-flow/SKILL.md) | Windows, macOS, Linux | Git, `gh`, Bash, Python 3 | PR readiness verdict or ordered PR-splitting workflow |
| [repository-cleanup](./repository-cleanup/SKILL.md) | Any repository and supported OS | Repository instructions and local verification tools | Approved cleanup proposal, then verified change report |
| [flutter-upgrade](./flutter-upgrade/SKILL.md) | Flutter/Dart projects | Flutter/Dart toolchain, package manager, repository CI guidance | Upgrade plan and verification report |

## Quick decision table

| Request type | Use this | Example phrase | Common wrong choice |
| --- | --- | --- | --- |
| Quota and burn forecast | [copilot-quota-forecast](./copilot-quota-forecast/SKILL.md) | "Will I run out of quota this month?" | Long ad-hoc prompt without running the forecast script |
| Screenshot of native Windows app | [windows-screenshot](./windows-screenshot/SKILL.md) | "Capture a screenshot of the Flutter app window" | Browser screenshot tooling for non-browser native app windows |
| Screenshot of connected Android device app | [android-screenshot](./android-screenshot/SKILL.md) | "Take screenshot from connected Android phone" | `windows-screenshot` when target is Android device/emulator |
| Prepare or split GitHub PRs | [github-pr-flow](./github-pr-flow/SKILL.md) | "Check this PR for merge readiness" | Running cleanup before verifying the PR merged |
| Plan or perform repository cleanup | [repository-cleanup](./repository-cleanup/SKILL.md) | "Propose a safe cleanup pass" | Deleting ignored files without inspecting them |
| Upgrade Flutter, Dart, or pub packages | [flutter-upgrade](./flutter-upgrade/SKILL.md) | "Plan a safe Flutter SDK upgrade" | Updating only the obvious SDK pin or sharing credentials in logs |
| Browser page screenshot | Browser screenshot tool | "Screenshot this web page in the browser" | Do not use `windows-screenshot` for browser pages |

## Reusable skill template

Use [TEMPLATE-SKILL.md](./TEMPLATE-SKILL.md) as a starting point for new skills.
It includes required fields, example requests, limits, expected results, error codes, and safety rules.

## Reusing a skill in another repo or tool

To reuse a skill, ask the AI tool to import it and give the path to its folder.

Practical prompt example:
- "Import the skill from C:/path/to/ai-cookbook/skills/windows-screenshot into this repo."

Copy/paste starters:
- Same repo: "Import the skill from ./skills/windows-screenshot into this repo."
- Another repo: "Import the skill from C:/path/to/other-repo/skills/android-screenshot and adapt only the file paths that need to change."

This saves setup time and keeps the skill's tested requests, results, and safety rules.

## Example skills in this repo

- [Copilot quota forecast example](./copilot-quota-forecast/SKILL.md)
- [Windows screenshot capture example](./windows-screenshot/SKILL.md)
- [Android screenshot capture example](./android-screenshot/SKILL.md)
- [GitHub PR flow](./github-pr-flow/SKILL.md)
- [Repository cleanup](./repository-cleanup/SKILL.md)
- [Flutter and Dart upgrade](./flutter-upgrade/SKILL.md)

## Example 1: Copilot quota forecast

How it works:
1. Skill runs [forecast.ps1](./copilot-quota-forecast/forecast.ps1).
2. Script uses the provider CLI to get quota data.
3. Script adds local country, holiday, and history data.
4. Script emits one JSON object.
5. Skill turns that JSON into a short report and hides sensitive fields by default.

Why the skill helps:
- No need to repeat the data and report details each time.
- Script gathers the data the same way each time.
- Skill keeps the report short and consistent.

Original files came from:
- `<user-home>/.copilot-quota/`

If it fails:
- If provider CLI call fails, run auth status and re-authenticate (`gh auth status`, `gh auth login` in this example).

## Example 2: Windows screenshot capture

How it works:
1. Skill runs [capture.ps1](./windows-screenshot/capture.ps1) with a title substring.
2. Script finds the visible app window, restores it if minimized, and captures it with `PrintWindow`.
3. Script saves the PNG in a temporary folder and prints the full path as the last line.
4. Skill returns the file path instead of pasting image data into chat.

Why the skill helps:
- Avoids repeat fixes for display scaling and window capture.
- The result is one path line.
- It does not send the image into chat unless asked.

Source this was ported from:
- `<other-repo>/.gsd/skills/screenshot/`

If it fails:
- If no window matches, list candidates with `Get-Process | Where-Object MainWindowTitle | Select-Object Id,ProcessName,MainWindowTitle`.

## Example 3: Android screenshot capture

How it works:
1. Skill runs [capture.ps1](./android-screenshot/capture.ps1).
2. Script finds a connected adb device or uses the requested device ID.
3. Script wakes device to avoid screensaver/idle lock visual state.
4. Script finds the open app and uses its name in the output file.
5. Script takes the screenshot, copies it to a temporary folder, and prints the path as the last line.

Why the skill helps:
- Saves the repeated adb steps in one place.
- Returns one path line, like windows-screenshot.
- Avoids repeating device-selection and command fixes.

If it fails:
- If no device is usable, run `adb devices`. If it says `unauthorized`, accept the USB debugging prompt on the device.

Rule of thumb:
- If you repeat a workflow three or more times in a week, consider making a skill.
- If a script can return the same JSON or final line each time, use the script from the skill.

