# Task-to-Tool Matrix

Use this for common engineering tasks.

| Task | Best first choice | Why | Escalate to |
| --- | --- | --- | --- |
| Small bug fix | Copilot CLI | Fast edit and verify loop | Claude Code if root cause is unclear |
| Large bug investigation | Claude Code | Strong code plus log reasoning | GSD Pi for phased repo-wide work |
| Refactor in one area | Copilot CLI | Good for focused diffs | Claude Code for higher-risk refactors |
| Cross-module refactor | GSD Pi | Better for slicing and phased execution | Claude Code for deep reasoning on risky modules |
| Unit test generation | Copilot CLI | Quick local iteration | Claude Code for coverage goals and flaky tests |
| Coverage improvement loop | Claude Code | Good at deliberate test strategy | GSD Pi for repo-wide rollout |
| Architecture research | GSD Pi | Broad exploration and synthesis | Claude Code for sharper trade-off analysis |
| Incident debugging | Claude Code | Best fit for ambiguous failures | GSD Pi for large system mapping |
| Docs update | Copilot CLI | Fastest for concise edits | GSD Pi if many docs must be aligned |
| Migration planning | GSD Pi | Strong phased execution model | Claude Code for critical design reviews |

## Short rules

- Prefer Copilot CLI for the shortest path to a reviewable diff.
- Prefer Claude Code for unclear, risky, or debugging-heavy work.
- Prefer GSD Pi for large, cross-cutting, or staged efforts.

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
- [Prompt templates](./PROMPT-TEMPLATES.md)
- [Failure recovery](./FAILURE-RECOVERY.md)
