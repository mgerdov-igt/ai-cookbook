# Task-to-Tool Matrix

Use this for common engineering tasks. Tiers (Fast, Everyday, Strong) and effort levels are defined in [Model and effort selection](./MODEL-SELECTION.md), which lists current models and ratings.

| Task | Best first choice | Model tier and effort | Why | Escalate to |
| --- | --- | --- | --- | --- |
| Small bug fix | Copilot CLI | Everyday, medium | Fast edit and verify loop | Strong, high if root cause is unclear |
| Large bug investigation | Claude Code | Strong, high | Strong code plus log reasoning | GSD Pi with Strong for phased repo-wide work |
| Refactor in one area | Copilot CLI | Everyday, medium | Good for focused diffs | Strong, high for higher-risk refactors |
| Cross-module refactor | GSD Pi | Strong, high | Better for slicing and phased execution | Claude Code Strong, xhigh for risky modules |
| Unit test generation | Copilot CLI | Everyday, medium | Quick local iteration | Strong, high for coverage goals and flaky tests |
| Coverage improvement loop | Claude Code | Strong, high | Good at deliberate test strategy | GSD Pi with Strong for repo-wide rollout |
| Architecture research | GSD Pi | Strong, high | Broad exploration and synthesis | Claude Code Strong, xhigh for trade-off analysis |
| Incident debugging | Claude Code | Strong, high | Best fit for ambiguous failures | GSD Pi with Strong for large system mapping |
| Docs update | Copilot CLI | Fast, low | Fastest for concise edits | Everyday, medium if many docs must be aligned |
| Migration planning | GSD Pi | Strong, high | Strong phased execution model | Claude Code Strong, xhigh for critical design reviews |
| Implement, then request an independent review | Codex CLI | Everyday, medium to implement; Strong, high to review | A separate review pass can expose missed assumptions | Claude Code or Copilot CLI, on a different model, for a second perspective |
| Use a multi-provider terminal agent | OpenCode | Pick the tier from [Model and effort selection](./MODEL-SELECTION.md) | One agent can use different configured providers | Use the provider's native CLI when configuration is unclear |

## Short rules

- Prefer Copilot CLI for the shortest path to a reviewable diff.
- Prefer Claude Code for unclear, risky, or debugging-heavy work.
- Prefer GSD Pi for large efforts that span several parts or need stages.

## Model tier quick guide

For current model names, effort levels, and ratings, see [Model and effort selection](./MODEL-SELECTION.md).

- Fast, low effort: docs, renames, quick lookups.
- Everyday, medium effort: focused fixes, tests, small refactors, implementing an approved plan.
- Strong, high effort: unclear bugs, architecture, migrations, planning, review.
- Raise effort one level before you raise the tier. Lower it again when the work becomes mechanical.

## Example picks

### Fix one failing unit test

Start with Copilot CLI.

Why:
- Low ambiguity
- Short verify loop
- Likely one or two files

### Debug a production-only race from logs

Start with Claude Code.

Why:
- High ambiguity
- Stronger investigation flow
- Better fit for evidence-driven debugging

### Break a migration into milestones

Start with GSD Pi.

Why:
- Better task slicing
- Better for repo-wide coordination
- Easier to keep phased output organized

## Related docs

- [Tool selection cheat sheet](./TOOL-SELECTION.md)
- [Prompt templates](../knowledge/PROMPT-TEMPLATES.md)
- [Failure recovery](../knowledge/FAILURE-RECOVERY.md)
