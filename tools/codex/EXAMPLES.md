# Codex CLI Practical Examples

Start Codex from the repository root:

```powershell
Set-Location C:\path\to\repository
codex
```

## Implement

```text
Implement <change> to meet these acceptance criteria: <criteria>. Keep the diff focused, follow repository instructions, and run the relevant tests. Summarize changed files and verification results.
```

## Review

In a separate session, ask for an independent, read-only review:

```text
Review the current diff for correctness, regressions, and missing tests. Do not edit files. Report actionable findings first with file references; say clearly if you find none.
```

Keep the implementation and review passes separate so the review can challenge the first pass rather than continue it.