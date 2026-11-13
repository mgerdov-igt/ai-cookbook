# Writing a Portable Skill

Use this when you add a skill to [skills/](../skills/README.md). A skill is a folder with a `SKILL.md` file that any compatible AI tool can load. For the format, install paths, and index, see the [skills guide](../skills/README.md). Start from [TEMPLATE-SKILL.md](../skills/TEMPLATE-SKILL.md).

## How tools load a skill

1. **Discovery:** the tool reads only `name` and `description` of every installed skill.
2. **Instructions:** when a request matches, it reads the whole `SKILL.md`.
3. **Resources:** it reads or runs scripts and reference files only when `SKILL.md` points to them.

So the description decides whether the skill is ever used. The body decides whether it works.

## Write the description

The description must say what the skill does, when to use it, and the words people actually type.

| Good | Poor |
|---|---|
| `Capture a PNG of a native Windows app window. Match by window title and return the path. Do not use for browser pages.` | `Screenshot helper` |

- Keep it to 1024 characters or fewer. Aim for much less: every installed description shares the tool's context budget.
- Put trigger phrases in it, for example `Use for "commit this" or "/commit"`.
- Name the boundary with neighbors, for example "not for browser pages".
- Quote the value if it contains `: ` or starts with a special character, or the YAML breaks.
- `name` uses lowercase words joined by hyphens, 64 characters or fewer, and matches the folder name.

## Write the body

Teach only what the model would get wrong without you: your conventions, defaults, and traps. Skip what is on the first page of the official docs.

| Section | Use |
|---|---|
| When to use / When not to use | Repeat the triggers and set the boundary |
| Inputs and prerequisites | Exact install and check commands |
| Steps | Numbered, only where order matters |
| Gotchas | Warnings that prevent a mistake: "**Never** do X, because Y" |
| Troubleshooting | Symptom and fix pairs for after something breaks |
| Verification | One command and the signal that means success |

- Give decision rules for open-ended work and numbered steps for repeatable procedures.
- Add a Gotcha each time the tool gets a result wrong.
- State safety defaults: read-only first, a dry run before a write, and approval before anything that is hard to undo.
- Keep `SKILL.md` under about 200 lines. Move long procedures to `references/<topic>.md` and link them. Say when to read each one. Hard maximum: 500 lines.

## Bundle files

| Folder | Holds | Loaded into context |
|---|---|---|
| `scripts/` | Code the skill runs | Only its output |
| `references/` | Docs the tool reads when needed | When referenced |
| `assets/` | Files used as-is in output | No |

Put the repeatable part in a script and keep the instructions short. The script should print a fixed format, such as one JSON object or a final path line, and use clear exit codes. See [PowerShell scripting rules](../tools/powershell/SCRIPTING.md). Refer to files by a path relative to the skill folder, never an absolute path or a home folder.

## Keep it tool-neutral

- Avoid one tool's slash commands, frontmatter fields, and tool names in the shared instructions. Tool-specific fields such as `allowed-tools` or `applyTo` are not portable.
- List required programs and operating systems.
- Never store credentials or secrets in a skill.

## Before you publish

- [ ] `name` and `description` are valid and match the rules above.
- [ ] The description has what, when, and keywords, and is short.
- [ ] The body has When to use, When not to use, and a safe default.
- [ ] Gotchas cover each non-obvious trap.
- [ ] Long procedures are in `references/`.
- [ ] Scripts print a fixed format and handle errors.
- [ ] Paths are relative to the skill folder. No secrets.
- [ ] The skill is in the [skill index](../skills/README.md#skill-index) and the decision table, and, for [TauShell](https://github.com/ma99us/tau-shell), in [`tau-shell.yaml`](../tau-shell.yaml).
- [ ] The link and name check passes: `pwsh -NoProfile -File skills\docs-sync-audit\scripts\Test-DocsLinks.ps1 -CheckSkills`.

## Sources

Adapted from the [Agent Skills file guidelines](https://github.com/github/awesome-copilot/blob/main/instructions/agent-skills.instructions.md) in github/awesome-copilot (MIT; see [THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES.md)). The open format is at [agentskills.io](https://agentskills.io/).
