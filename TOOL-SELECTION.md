# Tool Selection Cheat Sheet

Use this when you need the fastest good-enough choice.

## Start with the task

Pick GSD Pi when you want:
- Broad repo exploration
- Multi-step implementation with agent-like delegation
- Large migrations or phased work
- Heavy codebase analysis before editing

Pick GitHub Copilot CLI when you want:
- Fast edits in an existing repo
- Short implementation loops
- Lightweight terminal-first coding help
- Parallel work with `/fleet`

Pick Claude Code when you want:
- Careful reasoning on messy bugs
- Strong debugging from code and logs
- Long-form implementation with explicit approvals
- Test and quality improvement loops

## Fastest good-enough default

If you are unsure:
1. Start with GitHub Copilot CLI for a focused code change.
2. Use Claude Code if the task is ambiguous, risky, or debugging-heavy.
3. Use GSD Pi if the work is large, cross-cutting, or needs staged delegation.

## Model selection quick picks

Use a fast/default model when:
- The task is clear and bounded
- You are editing one or a few files
- You mainly need speed for implement-and-verify loops

Use a strong reasoning model when:
- Root cause is unknown
- You need architecture trade-off analysis
- The change is high risk (production paths, concurrency, state handling)

Escalation rule:
- If the first pass is shallow, misses constraints, or loops without progress, move up one model tier.

De-escalation rule:
- Once plan and constraints are stable, move back to a fast/default model for implementation passes.

## By work style

Choose Copilot CLI if you prefer:
- Quick prompts
- Tight terminal loop
- Fast iteration on one branch

Choose Claude Code if you prefer:
- More deliberate reasoning
- Stronger investigation output
- Extra caution around risky actions

Choose GSD Pi if you prefer:
- Task slicing
- Higher autonomy on large efforts
- Research plus implementation in phases

## Escalate when

Escalate from Copilot CLI to Claude Code when:
- The bug is still unclear after one pass
- You need deeper reasoning from logs and code
- The change touches risky production paths

Escalate from Copilot CLI or Claude Code to GSD Pi when:
- The repo is large and unfamiliar
- The task spans many modules or milestones
- You want explicit phased execution or sub-task management

Escalate model strength when:
- The first answer is shallow or misses constraints
- The task needs architecture trade-offs
- You are debugging concurrency, state, or production incidents

## Avoid the wrong fit

Avoid starting with the most powerful option when:
- The task is a small doc edit
- You only need one file changed
- The verification path is short and obvious

Avoid high-autonomy or unsafe modes when:
- You have not reviewed the plan
- The repo is not clean enough to inspect changes safely
- The task involves production, secrets, or destructive operations

## Related docs

- [Task-to-tool matrix](./TASK-TOOL-MATRIX.md)
- [10-minute onboarding](./10-MINUTE-ONBOARDING.md)
- [Common best practices](./COMMON-BEST-PRACTICES.md)
