---
name: flutter-upgrade
description: Plan or execute a safe Flutter SDK, Dart SDK floor, or Dart pub dependency upgrade. Use for incremental SDK hops, dependency campaigns, or upgrade verification. Requires the target repository's instructions, package manager, and CI rules.
---

# Flutter and Dart Upgrade

Use this skill to plan or carry out a Flutter SDK, Dart SDK constraint, or Dart package upgrade. It is project-agnostic: discover the target project's real version pins, package graph, build commands, protected contracts, and CI gates. Do not copy versions, paths, commands, thresholds, or assumptions from another repository.

Read [the upgrade workflow](references/UPGRADE-WORKFLOW.md) before changing files. First inspect the repository instructions, current Git state, SDK/package-manager configuration, and CI workflows. For a multi-hop or major-version campaign, write a baseline and ordered plan before editing. Execute only the scope the user requested; stop and ask when a gate or unknown contract requires a scope change.

## Safety Rules

- Preserve the user's worktree and local changes. Do not reset, stash, force-update, or switch the active branch without explicit authorization. Use isolated worktrees when that fits the repository's workflow.
- Upgrade by compatible coupling unit, not by arbitrary package list. Check target SDK floors before choosing batch order.
- Move SDKs through exact, documented versions and validate each hop. Do not jump to whatever `flutter upgrade` currently selects.
- Use the repository's actual CI and build commands, including required wrappers, working directories, profiles, and setup.
- Do not weaken tests, protected contracts, security controls, or project-specific gates to make an upgrade pass. Stop if a fix requires that.
- Never read out, print, copy, commit, or include GitHub secret values, tokens, signing material, `.env` contents, or credential-bearing build definitions in chat, logs, reports, diffs, or artifacts. Use only the repository's approved local or CI secret mechanism. Do not ask the user to paste a secret into chat.
- Do not commit, push, publish, or create a PR unless the user requests it.

Report the baseline, upgrade units, checks run, failures or waivers, deferred work, and remaining risks. Redact sensitive values and avoid publishing private repository details outside their authorized context.