# Spec Kit Troubleshooting

## `specify` is not recognized

- Confirm `uv tool install specify-cli` completed.
- Restart PowerShell after installing or changing `PATH`.
- Run `uv tool list` to confirm the package is installed.
- See the official [installation guide](https://github.github.io/spec-kit/installation.html) for PATH and package-manager options.

## Agent skills are missing

- Confirm initialization completed successfully with the intended `--integration` key.
- Check the generated integration files and restart the coding-agent session.
- Use the official [integration reference](https://github.github.io/spec-kit/reference/integrations.html) to confirm supported integrations and invocation syntax.

## Initialization reports existing files

Spec Kit may need `--here --force` to initialize an existing repository. Commit or stash first, review the diff, and resolve managed-file conflicts instead of overwriting local guidance blindly.

## A generated task is too thin

Pause before implementation. Add domain, security, integration, and repository context to the task, then review its acceptance criteria and verification method.