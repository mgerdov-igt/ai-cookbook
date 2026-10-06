# Repository Cleanup Workflow

Use this workflow after the skill's first-pass approval gate. Keep the work within the exact scope the user confirmed.

## 1. Map the Scope

Classify the request as one or more of:

- Code-quality cleanup or refactor
- Git index hygiene
- Disk cleanup of generated or ignored artifacts
- Documentation or tooling cleanup

Inspect the current Git status before planning. Identify user changes and leave them untouched. Read the nearest project instructions, package/module ownership rules, protected-file guidance, and CI/test definitions. For disk cleanup, inspect ignored and untracked files as well as tracked files; ignored does not mean disposable.

For the first proposal, list each candidate path or bounded group, why it is a candidate, its risk tier, relevant contracts/invariants, and the check that will prove the change is safe. Do not use vague scopes such as "clean the repo" when a narrower inventory is possible.

## 2. Assess Contracts and Risk

Stop and ask for clarification when a change may:

- Alter a public API, command-line behavior, wire protocol, serialized or persisted format, configuration contract, migration, or externally consumed output.
- Cross a package/module ownership boundary or change dependency direction without an explicit design decision.
- Change lifecycle, ordering, concurrency, state-machine, security, or data-retention behavior that is not understood.
- Remove code whose behavior is exercised through reflection, configuration, registration, generated code, plugins, scripts, or external consumers.
- Delete or overwrite files whose ownership, reproducibility, or active use is uncertain.

Build a project-specific protected-surface list from repository docs and nearby tests. Do not invent generic rules as if they were the project's policy. For suspected dead code, search all relevant source, tests, configuration, registries, generated references, and runtime lookup paths. Lack of a direct import is not proof.

Use risk tiers to choose the verification depth:

- **Low:** local duplication, obvious temporary output, or a small isolated helper with direct tests.
- **Medium:** shared modules, package boundaries, configuration wiring, or behavior used by multiple callers.
- **High:** public or persisted contracts, protocol adapters, security-sensitive code, stateful lifecycles, data deletion, or broad mechanical changes.

If the repository defines its own risk categories, use those instead.

## 3. Make Small, Behavior-Preserving Changes

Prefer small reviewable slices. Fix the underlying cause instead of suppressing a warning or moving complexity elsewhere. Preserve public APIs and observable behavior unless the confirmed request says otherwise.

For code cleanup:

1. Remove only references proven unused across static and dynamic use sites.
2. Extract shared logic only after its ownership and stable boundary are clear.
3. Keep project-specific behavior in the project's declared source of truth, such as configuration or data, when its architecture requires that.
4. Validate each meaningful slice before continuing. If a check exposes a local defect, repair that slice and rerun the same check.
5. Record unrelated bugs or larger design ideas separately; do not expand scope without approval.

## 4. Clean Git and Disk Artifacts Safely

First determine whether each path is tracked, untracked, or ignored. Do not remove tracked files as "generated" without explicit scope approval and a plan to preserve or intentionally remove their history. For ignored or untracked paths, inspect the actual contents and establish that they are regenerable and not active evidence, settings, credentials, source data, or user work.

For bulk cleanup:

1. Discover candidates from the repository's ignore rules, status, build configuration, and known generators. Measure size only when useful; size alone does not make a path safe to remove.
2. Produce an exact target list and identify any required restore or bootstrap step.
3. Use a dry run scoped to those paths. For example, `git clean -nd -- <path>` previews untracked files under one path; inspect every line before any corresponding deletion.
4. Get explicit confirmation for destructive targets that were not explicitly named and authorized by the user.
5. Delete only the approved paths. Never run an unscoped `git clean`, recursive delete, cache purge, or equivalent broad command.
6. Run required regeneration or bootstrap steps, then inspect Git status and confirm the expected files remain or are recreated.

Do not assume a cache can be removed independently: repository workspaces may need a bootstrap, dependency resolution, or generated metadata before tests work again. Preserve logs, screenshots, test evidence, local settings, and runtime state unless the user specifically includes them and their loss is understood.

Use commands appropriate to the current shell and operating system. If a command is destructive or shell-specific, explain the target and effect before running it; do not paste POSIX commands into PowerShell unchanged.

## 5. Verify and Report

Discover the checks from project docs, package scripts, and CI. Respect required working directories and setup steps. Choose the smallest checks that cover the changed behavior, then run broader required gates for shared or high-risk changes. Typical checks may include formatting, static analysis, focused tests, integration tests, builds, and contract or snapshot tests; run only those that apply.

Before finishing:

- Review the diff for unrelated edits, accidental contract changes, and generated churn.
- Check Git status for unexpected deletions, untracked files, or remaining scratch output.
- For disk cleanup, verify the targeted leftovers and required regenerated state.
- State exactly which checks passed, failed, or could not run, with a brief reason.
- Summarize the changes, remaining risks, and deferred candidates. Do not claim full verification when a required check was blocked.