# OpenCode Practical Examples

Start OpenCode from the repository you want it to work in:

```powershell
Set-Location C:\path\to\repository
opencode
```

## Explore Before Editing

```text
Map the relevant code for <change>. Explain the current behavior and identify likely files. Do not edit yet.
```

## Implement a Bounded Change

```text
Implement <change> to meet these acceptance criteria: <criteria>. Follow the repository instructions, keep the diff focused, and run the relevant tests. Report checks and any gaps.
```

## Review a Change

```text
Review the current diff for correctness, regressions, and missing tests. Do not edit. Report findings first with file references; say clearly if you find none.
```

Use the [provider setup](./SETUP.md) and its model ID when selecting GLM-5.3 or another provider-specific model.