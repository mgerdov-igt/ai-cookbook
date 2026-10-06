# Spec Kit Setup (Windows 11 + PowerShell 7)

## Prerequisites

- [Prerequisite tools](../PREREQUISITES-TOOLS.md)
- Python 3.11 or later
- `uv` package manager
- A supported AI coding agent; see the official [integration list](https://github.github.io/spec-kit/reference/integrations.html)

Install `uv` using its [official Windows instructions](https://docs.astral.sh/uv/getting-started/installation/).

## Install

Install the published CLI with `uv`:

```powershell
uv tool install specify-cli
```

## Verify

```powershell
uv --version
python --version
specify version
specify self check
```

## Initialize an Existing Repository

First commit or stash current work and use a reviewable branch. From the repository root:

```powershell
specify init --here --force --integration copilot
```

Replace `copilot` with the integration key for the agent your team uses. `--force` permits initialization in a non-empty directory and may replace files at managed paths. Review the resulting diff before accepting it.

## First Run

Start your AI coding tool in the repo. Run `/speckit-constitution` to record the project's agreed rules. Then use the skills in [Commands](./COMMANDS.md) for one feature.

## Next

- [Spec Kit overview](./OVERVIEW.md)
- [Spec Kit commands](./COMMANDS.md)
- [Spec Kit examples](./EXAMPLES.md)
- [Existing-project setup guide](https://github.github.io/spec-kit/guides/existing-projects.html)

## Official docs

- [Installation](https://github.github.io/spec-kit/installation.html)
- [Existing projects](https://github.github.io/spec-kit/guides/existing-projects.html)