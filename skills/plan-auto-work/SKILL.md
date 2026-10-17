---
name: plan-auto-work
description: Implement an already-approved plan end to end, autonomously, with verified work and a short final summary. Use for "plan-auto-work", "implement the plan", "go build it", "do it autonomously", or "run the plan end to end". Accepts a plan path and optional scope hint, or the plan most recently approved in the conversation.
---

# Plan Auto-Work

Build an approved plan without check-ins for routine decisions. Return verified work and a short, honest summary. Follow the host tool's instructions, permissions, and repository rules.

## Input

- A plan path, optionally followed by a scope hint such as "steps 2-4 only".
- No path: use the plan most recently approved in the conversation. If no clear approved plan exists, ask before starting.
- Optional `model=<name>`: a model identifier supported by the host tool. Do not assume a provider, fixed model list, or subscription tier.

## Model Recommendations

Choose by task complexity, risk, and the models currently available in the host:

| Work | Recommended capability |
| --- | --- |
| Small, mechanical, low-risk edits | Fast, lightweight coding model |
| Routine implementation with tests | Balanced coding and reasoning model |
| Complex cross-module work, ambiguous design, security, money, or data integrity | Strongest available reasoning and coding model |

These are capability recommendations, not model names or guarantees. Check the host's current model picker or official model documentation before naming a model. Cost and speed are tradeoffs; model choice never replaces verification.

A skill has no model of its own. Without `model=`, work in the current session on its current model. If a model is explicitly requested:

1. If it is already active, continue.
2. If the host supports delegation to that model, delegate once using its supported agent tool. Pass this skill, the plan, scope, project rules, and settled conversation decisions. Do not duplicate the work.
3. If the model is unknown or selection is unsupported, explain the limitation. Ask the user to select an available model or approve using the current one. Never silently substitute a model or claim a switch occurred.
4. Use background delegation only when the host supports it; otherwise await the result. Relay the delegate's final summary.

Before delegation, ensure the plan includes settled decisions and stop conditions. A delegate that cannot reach the user must park questions in its report.

## Lock the Plan

1. Read the whole plan, linked specifications and decision records, project rules, and relevant memory.
2. Turn the approved scope into a numbered checklist. Give every step a done-when: a test, command, or observable result proving completion.
3. List settled decisions. Do not reopen them or ask about them again.
4. Read each step's code before editing. Match existing patterns, names, formatting, and file conventions.
5. Send one short update with the checklist and stop conditions, then start without waiting for routine approval.

## Working Rules

**Decide routine details.** Choose names, file placement, helpers, test shape, and other implementation details within the approved scope. Follow repository patterns. Record non-obvious choices in the decision log.

**Stop the affected step only when:**

- The plan contradicts itself, the code, or a specification, and the alternatives change behavior.
- A missing decision belongs to the user: product behavior, money or security policy, a public contract, or a specification reversal.
- Work would destroy or rewrite data, irreversibly migrate storage, or substantially rewrite working code beyond the approved plan.
- An external blocker, such as unavailable credentials, hardware, or a service, prevents progress.

Park blocked steps and finish independent work. Halt the whole run only when nothing else can move. State the condition, evidence, and recommended resolution. Always respect host approval requirements.

Do not stop for a failure you caused: fix it. Resolve routine details from nearby code. Update tests when the approved plan deliberately changes expected behavior, and report that change. Work around tooling problems without bypassing safety controls.

**Keep scope narrow.** Build only the approved plan. Do not add features or unrelated refactors. Fix nearby bugs only when small and blocking or corrupting the step; otherwise report them as found but not fixed. Call out intentional behavior changes. Keep diffs minimal and avoid mass-formatting.

## Verify Every Step

1. Add or update tests for the done-when. Prefer real schemas, configuration, and stores when the repository supports them.
2. Run affected checks and the analyzer or linter. Fix failures caused by the step before continuing. Report blocked checks honestly.
3. Update the plan's status with one line saying what was built and where, so another session can resume.
4. Send a short progress update. Incorporate new user requirements and identify conflicts with settled decisions.

## Verify the Whole

- Run affected suites in full. Rerun a suspected flaky failure once before classifying it.
- When changing user-visible behavior or money/data handling, exercise an available real runtime using project tooling. Fix in-scope findings, add regression tests, and identify what the live run found.
- Update documents named by the plan to reflect completed work and remaining gaps.
- Report unavailable runtime checks and their impact rather than claiming success.

## Respect the Workspace

- Keep temporary artifacts in the system temporary directory, such as `$env:TEMP/plan-auto-work-<id>/` in PowerShell. Remove artifacts you created when finished unless the user needs them; report retained paths.
- Remove worktrees and local branches you created after their work is merged or abandoned. Never remove uncommitted or unpushed work without permission.
- Do not commit, push, or open a pull request unless the user or approved plan authorizes it.
- Do not touch files outside scope, discard another contributor's changes, or run destructive commands on work you did not create.

## Decision Log

Keep one line per non-obvious decision: choice, reason, and implementation location. Include it in the final summary and in the plan when future readers need it.

## Final Summary

Keep the report short and in this order:

1. **Result:** done, done with parked steps, or stopped with the stop condition.
2. **Built:** one line per plan step with its main files.
3. **Verified:** checks and counts where available, analyzer status, and runtime checks or why they were not run.
4. **Behavior and bugs:** intentional behavior changes and bugs fixed during implementation.
5. **Decisions:** the concise decision log.
6. **Still open:** parked steps with recommendations, unfixed findings, and plan gaps. State whether changes were committed or published.
7. **Next:** at most two next actions and the recommended one.

## Using This From Another Agent

A coordinator can pass this skill and a plan path with a scope hint to a delegate. The delegate treats the plan as its brief, records progress there, and returns the summary above. Parallel delegates are appropriate only for steps the plan marks independent that touch different files. The coordinator owns combined verification and the final report.