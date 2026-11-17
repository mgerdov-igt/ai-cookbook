# Model Selection by Task

Use this to pick a model in Claude Code and GitHub Copilot CLI. For the tool choice, see the [Task-to-tool matrix](./TASK-TOOL-MATRIX.md).

Last verified: 2026-11-17. Model names change often. Pick the tier first, then check the live list with `/model`.

## Pick a tier

| Tier | Use for | Claude Code (`/model`) | Copilot CLI (`/model`) |
| --- | --- | --- | --- |
| Fast | Docs, small edits, simple tests, quick questions | `haiku` (Haiku 5.5) | Claude Haiku 5.5, GPT-6 Luna, GPT-5.6 Luna, Gemini 3.8 Flash |
| Everyday | Most coding, focused refactors, test writing | `sonnet` (Sonnet 5.5) | Claude Sonnet 5.5, GPT-6.1 Terra, GPT-6 Sol |
| Strong | Unclear bugs, architecture, risky refactors, migrations | `opus` (Opus 5.5) | Claude Opus 5.5, GPT-6.1 Sol, GPT-5.6 Sol |
| Long autonomous | Large tasks that run a long time with little input | `fable` (Fable 5.2) | Claude Fable 5.2, GPT-6 Astra |
| Plan, then build | Plan with a strong model, then build with an everyday one | `opusplan` | Plan with a Strong model, then switch to Everyday |
| Let the tool choose | You do not want to decide | `default` | Auto |

Notes:
- Claude Code aliases move to the newest model over time. To pin one, use the full name, such as `claude-opus-5-5`.
- Your Copilot plan and organization policy decide which models you see. An admin must enable each Claude Fable model.
- Claude Fable models can keep prompts and outputs for safety checks. Check your data rules before you use them.
- Claude Code needs a recent version for new models. Run `claude update` if a model fails.

## Pick by task

| Task | Start with | Escalate to |
| --- | --- | --- |
| Fix one failing test | Fast or Everyday | Strong if the cause is unclear |
| Small bug fix | Everyday | Strong |
| Docs update | Fast | Everyday if many pages must agree |
| Unit test generation | Everyday | Strong for flaky tests or coverage goals |
| Refactor in one area | Everyday | Strong for risky code |
| Cross-module refactor | Strong | Long autonomous |
| Large bug or incident investigation | Strong | Long autonomous |
| Architecture research or migration plan | Strong, or Plan then build | Long autonomous |
| Independent code review | Strong, from a different model family than the author | A second tool |
| Feature that runs unattended for hours | Long autonomous | Strong with smaller steps |

Rules:
- Start lower. Move up one tier when the first pass misses constraints or gives shallow answers.
- Move down again when the plan is clear and the work is mechanical.
- For a review, use a different model than the one that wrote the change.
- Higher tiers cost more. See each tool's cost control page: [Claude Code](./claude-code/COST-CONTROL.md), [Copilot CLI](./copilot-cli/COST-CONTROL.md).

## Switch models

Claude Code:

```text
/model sonnet
```

Or start with a model:

```powershell
claude --model opus
```

Copilot CLI:

```text
/model
```

Pick from the list. The list shows only models your plan allows.

## Verify

1. Run `/model` and check that the active model is the one you chose.
2. If a model is missing in Copilot CLI, ask your admin to enable it.
3. If a model fails in Claude Code, run `claude update` and try again.

## Official sources

- [Claude Code model configuration](https://code.claude.com/docs/en/model-config)
- [Supported AI models in GitHub Copilot](https://docs.github.com/en/copilot/reference/ai-models/supported-models)
- [GitHub Copilot AI model comparison](https://docs.github.com/en/copilot/reference/ai-models/model-comparison)

## Related docs

- [Task-to-tool matrix](./TASK-TOOL-MATRIX.md)
- [Tool selection cheat sheet](./TOOL-SELECTION.md)
- [Claude Code commands](./claude-code/COMMANDS.md)
- [Copilot CLI commands](./copilot-cli/COMMANDS.md)
