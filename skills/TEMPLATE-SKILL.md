---
name: <skill-name>
description: <Say what it does and give example requests that should start it.>
---

# <skill-name>

One short sentence that says what this skill does.

## Naming convention

- Add a platform prefix when needed: `windows-`, `android-`, `linux-`.
- Name the action: `screenshot`, `quota-forecast`, `log-scan`.
- Do not use vague names that hide what the skill does.

## When to use

Use this skill when the user asks things like:
- "<trigger phrase 1>"
- "<trigger phrase 2>"
- "<trigger phrase 3>"

## When not to use

Do not use when:
- <Boundary 1>
- <Boundary 2>

## Inputs

Required:
- `<input-name>`: <expected format>

Optional:
- `<input-name>`: <default and meaning>

## How to Run It

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-folder>/<script>.ps1" <args>
```

Replace `<skill-folder>` with the path to the folder containing this `SKILL.md` file.

## Output Format

- On success: <what the output contains, e.g. JSON or a final file path>
- Missing values: <how to show them>
- Failure behavior: do not fabricate results

Expected fields (if JSON):
- `<field-1>`
- `<field-2>`
- `<field-3>`

## Exit codes

- `0`: success
- `<code>`: <failure condition>
- `<code>`: <failure condition>

## Safety Rules

- <Safety rule 1>
- <Safety rule 2>
- <Privacy rule>

## Verification

Run:

```powershell
<verify command>
```

Success signal:
- <what to look for>

Top failure signatures and fixes:
- <error text> -> <fix>
- <error text> -> <fix>

## Why This Skill Helps

- <How it avoids repeating instructions>
- <How it keeps results short and clear>
- <How it avoids repeat questions>
