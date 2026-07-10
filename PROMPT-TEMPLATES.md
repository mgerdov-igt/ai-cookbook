# Prompt Templates

Use these as starting points. Keep them short.

## Bug investigation

```text
Goal: Find the root cause of <bug>
Context: <relevant files, logs, recent changes>
Do not: Change unrelated files or guess without evidence
Done when: You can explain the cause and propose the smallest safe fix
```

## Feature implementation

```text
Goal: Implement <feature>
Context: <files, stack, constraints>
Do not: Change public behavior outside this feature
Done when: Code is updated, tests pass, and changed files are summarized
```

## Refactor with safety checks

```text
Goal: Refactor <area> for <reason>
Context: <files, architecture notes, tests>
Do not: Change external behavior or delete files without a dry run
Done when: The diff is reviewable, behavior is preserved, and verification steps are listed
```

## Test generation

```text
Goal: Add tests for <module or behavior>
Context: <test framework, current gaps, target files>
Do not: Rewrite production code unless required for testability
Done when: New tests fail before the fix or cover the intended behavior and pass locally
```

## Incident review

```text
Goal: Investigate <incident or symptom>
Context: <logs, timeline, affected services, recent deploys>
Do not: Assume the first suspicious signal is the root cause
Done when: You provide likely causes, confidence level, missing evidence, and safest next checks
```

## Use with any tool

After the template, add:
- Verification: <commands or checks>
- Constraints: <branch, files, approval limits>
- Output format: <plan, patch, summary, root cause note>

## Related docs

- [Common best practices](./COMMON-BEST-PRACTICES.md)
- [Task-to-tool matrix](./TASK-TOOL-MATRIX.md)
