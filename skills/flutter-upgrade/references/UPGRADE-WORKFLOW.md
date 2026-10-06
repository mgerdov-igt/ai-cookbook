# Flutter and Dart Upgrade Workflow

This workflow applies to Flutter SDK hops and Dart pub dependency campaigns. Adapt it to the target repository. Repository documentation, package-manager behavior, CI workflows, and explicit project gates are authoritative over generic examples.

## 1. Establish the Baseline

Read the repository's agent instructions, upgrade/dependency guidance, package layering, build scripts, CI workflows, and release or device-test requirements. Check `git status` and preserve all existing work. Establish whether the request is planning only or authorizes execution, and keep the scope bounded.

Record only information needed for the campaign:

- Current Flutter and Dart versions, including how CI and local development select them.
- Current package constraints and lockfile state.
- Analyzer, focused and full test, build, and other required gate results.
- Shipping targets and any documented coverage, performance, artifact-size, or runtime baselines.
- Existing overrides, vendored patches, generated-file boundaries, and known protected contracts.

Do not dump full environments, credentials, secret-bearing config, or unredacted build logs into campaign notes. Store notes in the project's approved location and keep them within the repository's access boundary.

## 2. Discover Pins and Constraints

Find every active Flutter SDK pin across the whole repository and its build inputs: CI workflow inputs, SDK-manager files, container images, scripts, dev containers, and release tooling. Distinguish active pins from historical prose. Check whether any required pin is owned by an external workflow or service. If it cannot be updated consistently, stop; local success would not represent CI.

Keep these concepts separate:

- Flutter version selection is usually configured by CI, an SDK manager, or a toolchain checkout.
- Dart ships with Flutter, but Dart package manifests declare Dart SDK constraints. Those constraints do not necessarily select the Flutter SDK.
- A monorepo or pub workspace may have one controlling resolution and lockfile, or each package may resolve independently. Discover its actual rules before editing constraints or running upgrades.

After an SDK hop, search repository-wide for the old Flutter and Dart versions. Classify matches as active pins or historical records; update all active pins together and leave intentional history intact.

## 3. Map Dependency Coupling and Plan Order

Refresh the dependency inventory with the repository's package manager. Build the relevant internal package graph and identify third-party groups that must move together, such as tightly coupled plugins, code generators and generated APIs, or adapters and their integrations. Prefer an existing ownership/layering document over a graph reconstructed from imports alone.

For each candidate upgrade, record its current and target versions, owner manifest, release notes, migration guide, maintenance or end-of-life state, known breaks, consumers, and expected validation. Check the target version's SDK floor from authoritative package metadata before ordering batches. A dependency that requires a newer SDK must follow the SDK hop that satisfies it.

Review dependency overrides and vendored or patched copies before resolution changes. Do not remove an override or local patch as cleanup until the upstream fix is released, the project has confirmed it is no longer needed, and tests prove the resolved dependency is the intended one.

Produce a dependency-ordered plan. Keep each coupling unit isolated so a failure has a narrow cause. Land low-risk independent units separately; serialize shared lockfile, SDK, platform-toolchain, and high-risk changes. Parallelize only independent units in isolated worktrees when repository policy allows it.

## 4. Upgrade the SDK Incrementally

Choose an explicit hop chain supported by the project's current version, platform requirements, and target. For each hop, review official release notes, migration guides, deprecations, removed APIs, platform/toolchain changes, and the Flutter-to-Dart version mapping. Document an exact rollback target.

Use the project's SDK manager or documented toolchain mechanism to select the exact version. Do not silently move to the latest channel version. Update all active SDK pins and the appropriate Dart SDK constraint in one coherent change, respecting workspace resolution rules.

After each hop:

1. Confirm the selected Flutter and bundled Dart versions.
2. Inspect any proposed automated migration before applying it; use a dry run where available.
3. Clear only caches invalidated by the SDK, using supported project commands. If many failures share a stale asset or generated artifact, test the cache hypothesis before changing source code.
4. Inspect all files the SDK or build system rewrote. Keep required, reviewable migrations; do not blindly revert or stage generated changes.
5. Run the focused checks, then the required broader gates before starting another hop.

Treat deprecations as behavior changes until proven otherwise. Read the old and replacement implementations or authoritative migration docs; make the smallest equivalent change and document a non-obvious equivalence at the call site.

## 5. Upgrade Dependencies in Batches

For each coupling unit, update constraints and resolve using the repository's real workspace procedure. Do not assume that a root-level upgrade command updates member manifests or that each package owns a separate lockfile.

After each batch, inspect the manifest and lockfile diff. Run the affected package's formatter, analyzer, and tests from the correct working directory, then run the repository's required workspace checks. Build affected shipping targets when platform code, plugins, code generation, or packaging changes.

Keep generated files regenerate-only unless the project says otherwise. Regenerate them through their owner tool and platform workflow rather than hand-editing them. Test custom lints, code generators, registries, and generated contracts against known expected behavior; a tool can stop working without causing an obvious compile error.

## 6. Validate Failures and Runtime Behavior

Use actual CI workflow definitions and repository scripts. Do not invent a substitute invocation or bypass a project guard. Respect test working-directory requirements and confirmed build profiles.

When a gate fails, inspect the first actionable error and numeric pass/fail/skip totals. Confirm the failure is not caused by a stale cache, wrong working directory, unsupported target, local toolchain mismatch, telemetry/network problem, or a deliberate repository guard. Do not treat a matching word in test output as a failure without checking the result summary.

Assess blast radius by affected packages, APIs, features, and platforms. Isolate one coupling unit at a time. If the cause remains unclear after a small number of focused isolation steps, restore the last verified state and report the blocker instead of continuing speculative edits.

If the project ships to real devices or hardware, define a repeatable smoke path from its own docs and test only against an explicitly approved non-production environment. Confirm the selected profile and destination before building or installing. Never use a live service, real transaction, or device-management workaround as an upgrade test. Do not publish test builds that contain credentials.

For artifact-size or performance gates, compare equivalent clean builds using the same configuration and toolchain conditions. Identify the files or measurements driving a regression before changing a threshold. Threshold changes require the project's documented approval and written rationale; never waive a gate silently.

## 7. Recovery, Campaign State, and Completion

Keep recoverable checkpoints at each successful SDK hop or coupling unit. Verify a rollback point with the repository's required restore and validation steps; do not assume a branch or commit is usable merely because it exists. If a documented gate trips, stop, preserve evidence safely, and return to the last verified state only as authorized by the user and repository workflow.

For work that spans sessions, keep a concise campaign record with current versions re-read from the tree, completed and blocked units, exact blockers such as an SDK floor, checks and evidence, and the next safe action. Re-verify mutable facts on resume; do not trust stale version tables or old CI status.

Complete only when:

- All active SDK pins and applicable Dart constraints agree with the selected toolchain.
- Planned dependency units resolve without unintended overrides or lockfile churn.
- Required analysis, tests, builds, and applicable runtime/device checks pass.
- Project-specific safety gates remain satisfied or have an explicitly approved, documented waiver.
- The final diff contains no accidental contract changes, secret values, local-only credentials, or unrelated edits.
- The report records changes, deferred upgrades, verification results, and any remaining risks without exposing secrets.

If a required gate is blocked, say so plainly and leave the campaign incomplete rather than claiming success.