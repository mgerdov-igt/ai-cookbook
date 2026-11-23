# Model and Effort Selection

Pick a model and an effort level (how much the model reasons) for Claude Code or GitHub Copilot CLI. For the tool choice, see the [Task-to-tool matrix](./TASK-TOOL-MATRIX.md).

Last verified: 2026-11-23. Model names change often; tiers do not. Pick the tier, then confirm the name with `/model`. The picks are our recommendations based on vendor model descriptions.

## Pick by task

| Task | Tier | Effort | If the first pass fails |
| --- | --- | --- | --- |
| Rename, format, docs, quick lookup | Fast | low | Everyday |
| Failing test, small bug, unit tests | Everyday | medium | high, then Strong |
| Refactor in one module | Everyday | medium | high, then Strong |
| Unclear bug, flaky test, incident | Strong | high | xhigh, then Long |
| Plan a feature or migration | Strong | high | xhigh |
| Cross-module refactor | Strong | high | Long |
| Implement an approved plan | Everyday | medium | Strong |
| Review a change | Strong, other model than the author | high | A second tool |
| Hours-long unattended task | Long | medium | Strong, smaller steps |
| Security or critical design review | Strong | xhigh | Long |

## Tier to model

| Tier | Claude Code | Copilot CLI |
| --- | --- | --- |
| Fast | `haiku` (Haiku 5.5) | Claude Haiku 5.5, GPT-6 Luna |
| Everyday | `sonnet` (Sonnet 5.5) | GPT-6.2 Sol (best value), Claude Sonnet 5.5, GPT-6.1 Terra |
| Strong | `opus` (Opus 5.5) | Claude Opus 5.5, Gemini 4 Carbon |
| Long (autonomous) | `fable` (Fable 5.2) | Claude Fable 5.2, GPT-6.2 Astra, Gemini 4 Neon |
| Plan, then build | `opusplan` | `/model plan <model>`, then an Everyday model |
| Tool decides | `default` | `auto` |

- Claude Code aliases track the newest model. Pin with a full name, such as `claude-opus-5-5`.
- Your Copilot plan and org policy decide which models appear. Admins must enable each Fable model.
- Fable models may retain prompts and outputs for safety checks. Check your data rules first.
- Claude Code needs a recent version for new models. Run `claude update` if one fails.

## Model ratings

Scores from the [Models Engineering Index (Mei)](https://git-aarvin.github.io/mei/): a composite of 16 coding benchmarks, averaging 50. Cost and tokens are relative to a typical model (1x). Snapshot taken 2026-11-23.

| Model | Tier | Score | Cost | Tokens |
| --- | --- | --- | --- | --- |
| Claude Fable 5.2 | Long | 67.2 | 7.7x | 1.4x |
| Gemini 4 Neon | Long | 67.0 | 3.1x | 0.84x |
| GPT-6.2 Astra | Long | 66.0 | 3.7x | 0.4x |
| Claude Opus 5.5 | Strong | 62.8 | 5.6x | 1.5x |
| Gemini 4 Carbon | Strong | 61.6 | 3.5x | 1x |
| GPT-6.2 Sol | Everyday | 60.8 | 0.75x | 0.3x |
| Claude Sonnet 5.5 | Everyday | 60.0 | 4.2x | 2.4x |
| Gemini 4 Hydrogen | Everyday | 58.9 | 2.2x | 1.1x |
| GPT-6.1 Terra | Everyday | 55.4 | 1x | 1.1x |
| Claude Haiku 5.5 | Fast | 47.8 | 0.71x | 1.6x |
| Grok 4.7 | Other | 46.8 | 5.5x | 0.76x |
| GPT-6 Luna | Fast | 40.6 | 0.084x | 0.5x |

How to read it:
- Gaps under about 3 points are noise. The index has no error bars.
- GPT-6.2 Sol scores near Sonnet 5.5 at a fraction of the benchmark cost. Try it first for Everyday work in Copilot CLI.
- The top three models are within 1.2 points of each other. Choose among them by cost, availability, and data rules.
- Cost is the benchmark run cost, not your Copilot credits or Claude plan usage. Check each tool's cost page for real billing.
- Scores are published results, not independently verified. Benchmarks are a proxy for your codebase. Run one real task before you standardize on a model.

## Pick the effort level

| Level | Use for |
| --- | --- |
| low | One obvious answer: renames, formatting, docs |
| medium | Most coding: focused fixes, tests, small refactors |
| high | Unclear cause, multi-file change, planning, review |
| xhigh | Hard bugs, risky design, costly mistakes |
| max | One stuck problem only. Slow and expensive; do not leave it on |

Rules:
- Raise effort one level before you raise the tier. If `high` still fails, move up a tier.
- Use high effort to plan and medium to implement.
- Lower effort again when the work becomes mechanical.
- On hard problems, a Strong model at medium beats a Fast model at high.

| | Claude Code | Copilot CLI |
| --- | --- | --- |
| Levels | `low` to `max` | `none` to `max`; varies by model |
| Default | `medium` | Model default, usually `medium` |
| In session | `/effort` | `/model`, then left and right arrows |
| At launch | `--effort high` | `--reasoning-effort high` |
| Save default | `Enter` in `/effort` | `/settings effortLevel high` |
| Plan mode | `opusplan` | `/settings planEffortLevel high` |

Claude Code applies `max` to the current session only. An unsupported level falls back to the nearest lower one.

## Typical flows

- **Unknown bug:** Strong, high, read-only, cite file and line. Then Everyday, medium, to fix.
- **Feature:** plan on Strong, high. Implement on Everyday, medium. Review in a new session on a different model.
- **Large unattended task:** Long, medium. State the outcome and the check command, not the steps.

## Switch and verify

```text
/model sonnet
/effort high
```

```powershell
claude --model opus --effort high
copilot --model <model-id> --reasoning-effort high
```

1. Run `/model` and confirm the active model. Copilot lists only models your plan allows; use the exact ID shown.
2. Confirm the effort: `/effort` in Claude Code, or `/settings footer.showModelEffort on` in Copilot CLI.

## Sources

- [Claude Code model configuration](https://code.claude.com/docs/en/model-config)
- [Models Engineering Index (Mei)](https://git-aarvin.github.io/mei/)
- [Supported models in GitHub Copilot](https://docs.github.com/en/copilot/reference/ai-models/supported-models)
- [Copilot model comparison](https://docs.github.com/en/copilot/reference/ai-models/model-comparison)

## Related docs

- [Task-to-tool matrix](./TASK-TOOL-MATRIX.md)
- [Tool selection](./TOOL-SELECTION.md)
- [Prompt engineering](../knowledge/PROMPT-ENGINEERING.md)
- Cost control: [Claude Code](./claude-code/COST-CONTROL.md), [Copilot CLI](./copilot-cli/COST-CONTROL.md)
