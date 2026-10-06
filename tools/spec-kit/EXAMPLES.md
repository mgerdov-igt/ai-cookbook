# Spec Kit Practical Examples

Use Spec Kit when a feature needs an agreed scope, clear checks, and a plan before coding.

## Feature Flow

In your AI coding tool's chat, create and review the files in order:

```text
/speckit-specify Add CSV export to the existing orders page. Preserve current filters and authorization behavior. Export only rows visible to the signed-in user. Do not change the existing JSON API.
/speckit-clarify
/speckit-plan Reuse the existing export and authorization patterns. Include a test strategy.
/speckit-tasks
/speckit-analyze
```

Review the spec before planning. Add missing business or security details to the tasks before coding. Then:

```text
/speckit-implement
/speckit-converge
```

Repeat coding and final checks until all required checks pass. Record test results. A person decides whether to accept the change.

## Link Requirements to Tests

For each required result, note the task and the test that checks it:

```text
AC-01 -> TASK-02 -> tests/orders/export.test.ts -> pass
```

See the [Spec-driven feature workflow](../../knowledge/SPEC-DRIVEN-WORKFLOW.md) for the full lightweight process.