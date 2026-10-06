# Spec Kit Commands

Use terminal commands to install and check Spec Kit. Run the `/speckit-*` skills in your AI coding tool's chat, not in PowerShell.

## PowerShell CLI

```powershell
specify version
specify self check
specify init --help
```

For setup, see [Setup](./SETUP.md). Add an optional workflow, such as bug fixing, with `specify extension add bug`.

## Agent Skills

Use the skills in order as needed. Review each file before continuing:

1. `/speckit-constitution` — record the project's agreed rules
2. `/speckit-specify` — capture feature intent and acceptance criteria
3. `/speckit-clarify` — resolve important ambiguity and update the spec
4. `/speckit-plan` — create the technical plan
5. `/speckit-tasks` — generate implementation tasks
6. `/speckit-analyze` — check that the spec, plan, and tasks agree
7. `/speckit-implement` — execute reviewed tasks
8. `/speckit-converge` — check for work that is still missing

Skill names can vary by AI coding tool. See the official [integration reference](https://github.github.io/spec-kit/reference/integrations.html#command-invocation).