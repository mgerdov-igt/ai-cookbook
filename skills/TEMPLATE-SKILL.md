---
name: <skill-name>
description: <One-sentence purpose. Include clear trigger phrases users actually say.>
---

# <skill-name>

One-line summary of what this skill does.

## Naming convention

- Use platform prefix when platform-specific: `windows-`, `android-`, `linux-`.
- Keep names action-focused: `screenshot`, `quota-forecast`, `log-scan`.
- Avoid overloaded generic names that hide scope.

## When to use

Use this skill when user asks things like:
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

## How to invoke

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "skills/<skill-name>/<script>.ps1" <args>
```

## Output contract

- Success output: <what must be present, e.g., JSON object or final stdout line path>
- Null handling: <how to render missing values>
- Failure behavior: do not fabricate results

Expected fields (if JSON):
- `<field-1>`
- `<field-2>`
- `<field-3>`

## Exit codes

- `0`: success
- `<code>`: <failure condition>
- `<code>`: <failure condition>

## Guardrails

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

## Why this skill saves tokens

- <How it removes repeated prompting>
- <How it keeps output compact>
- <How it reduces back-and-forth>
