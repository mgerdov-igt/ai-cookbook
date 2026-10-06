# Task-to-Tool Matrix

Use this for common engineering tasks.

| Task | Best first choice | Model suggestion | Why | Escalate to |
| --- | --- | --- | --- | --- |
| Small bug fix | Copilot CLI | Fast/default model first | Fast edit and verify loop | Strong reasoning model if root cause is unclear |
| Large bug investigation | Claude Code | Strong reasoning model first | Strong code plus log reasoning | GSD Pi with strong model for phased repo-wide work |
| Refactor in one area | Copilot CLI | Fast/default model first | Good for focused diffs | Strong reasoning model for higher-risk refactors |
| Cross-module refactor | GSD Pi | Strong reasoning model first | Better for slicing and phased execution | Claude Code strong model for risky modules |
| Unit test generation | Copilot CLI | Fast/default model first | Quick local iteration | Strong reasoning model for coverage goals and flaky tests |
| Coverage improvement loop | Claude Code | Strong reasoning model first | Good at deliberate test strategy | GSD Pi strong model for repo-wide rollout |
| Architecture research | GSD Pi | Strong reasoning model first | Broad exploration and synthesis | Claude Code strongest model for trade-off analysis |
| Incident debugging | Claude Code | Strong reasoning model first | Best fit for ambiguous failures | GSD Pi strong model for large system mapping |
| Docs update | Copilot CLI | Fast/default model first | Fastest for concise edits | Strong reasoning model only if many docs must be aligned |
| Migration planning | GSD Pi | Strong reasoning model first | Strong phased execution model | Claude Code strongest model for critical design reviews |
| Implement, then request an independent review | Codex CLI | Match model strength to change risk | A separate review pass can expose missed assumptions | Claude Code or Copilot CLI for a second perspective |
| Use a multi-provider terminal agent | OpenCode | Match model strength to task risk | One agent can use different configured providers | Use the provider's native CLI when configuration is unclear |

## Short rules

- Prefer Copilot CLI for the shortest path to a reviewable diff.
- Prefer Claude Code for unclear, risky, or debugging-heavy work.
- Prefer GSD Pi for large efforts that span several parts or need stages.

## Model tier quick guide

- Start with a fast/default model for small edits, docs, and straightforward tests.
- Start with a strong reasoning model for ambiguous bugs, architecture, and migrations.
- Escalate model strength when the first pass misses constraints or gives shallow analysis.
- De-escalate back to fast/default once the plan is clear and work becomes mechanical.

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
