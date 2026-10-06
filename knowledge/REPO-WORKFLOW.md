# Repeatable Repo Workflow

Use this as a starting point for team work with AI tools. This example is optional. Keep the parts that help your team and skip the rest.

## Example Structure

```text
.
|-- AGENTS.md
|-- CLAUDE.md                     # Optional Claude Code notes or a link to shared rules
|-- README.md
|-- docs/
|   |-- architecture/             # How the system works
|   |-- decisions/                # Recorded product and design choices
|   `-- standards/                # Team coding rules
|-- .requirements/                # Optional product and design requirements
|   |-- requirements.md
|   `-- features/
|-- specs/
|   `-- <feature>/                # Files for one change
|       |-- spec.md
|       |-- plan.md
|       |-- tasks.md
|       `-- validation/
|-- .planning/                    # Optional plans, status, and approvals
|-- .process/                     # Optional team steps and checks
|-- .claude/commands/             # Optional commands for Claude Code
|-- src/
|-- tests/
|-- scripts/                      # Commands used by developers and CI
`-- .github/
    `-- workflows/                # Automated checks
```

This is one possible layout, not a rule. Keep each requirement, plan, task list, or test result in one place and link to it instead of making copies. A small fix may need only a pull request and the usual tests.

## Why Some Folders Start With a Dot

A name that starts with a dot is a way to mark repo settings or team work folders. Git still tracks these folders unless `.gitignore` says to ignore them. Some file browsers hide them by default.

- `.requirements/` holds product and design requirements that may cover more than one feature.
- `.planning/` holds plans, status, and approvals for team work.
- `.process/` holds team steps, checks, and helper scripts.
- `.claude/commands/` holds commands for Claude Code. Other tools may use a different folder.

Use `docs/` to explain the project, such as how it works and why the team made certain choices. Use `specs/<feature>/` for the requirements, plan, tasks, and test results for one change. This keeps project information separate from files for current work. Teams can choose other names; follow the repo's existing layout.

## Keep Responsibilities Clear

**Shared rules:** Keep root `AGENTS.md` short. State what the repo is for, rules that must not change, where details live, and useful commands. Add folder-level rules only when needed. Use `CLAUDE.md` for Claude-only notes or as a link to shared rules.

**Project facts:** Keep design notes, system limits, and agreed choices in project docs. Update them when the system changes.

**Reusable tools:** Keep repeatable commands, scripts, templates, skills, and checks with the project. Run required checks in CI.

**Current work:** Keep one feature's requirements, plan, tasks, prompts, and test notes together. Commit the files the team needs to review or continue work. Use ignored `.todo/` only for private scratch notes.

Know which files describe current behavior and which files describe the requested change. Use code, settings, and tests to see what the system does now. Use approved requirements and decisions to see what it should do. Use plans and tasks to guide the work. If they disagree, ask the owner instead of guessing.

## Make Quality Gates Verifiable

List the commands for formatting, code checks, tests, builds, and required security or integration checks. Run the required checks in CI. Agent instructions should point to the same commands.

For a large change, keep a short test record beside the plan. List commands, results, and known gaps. Do not treat a prompt or an unverified claim that tests passed as proof.

## Adapt It

- Follow the repo's existing tools and folder rules before creating new folders.
- Keep plans and working notes proportional to the change; do not create ceremony for a small fix.
- Choose file names and approval steps with the team. This example does not require a particular AI tool or process.
- Start small. Add folders, commands, and checks only when they solve a repeated problem. Try a practice on real work before making it a team rule.
- See [knowledge structure](./KNOWLEDGE-STRUCTURE.md) for the four-layer model.