# Codex CLI Troubleshooting

## `codex` is not recognized

- Confirm Node.js and npm are installed with `node --version` and `npm --version`.
- Reopen PowerShell after installation so the global npm path is refreshed.
- Check `npm prefix -g` and confirm its executable directory is on `PATH`.

## Sign-in does not complete

- Run `codex` again and follow the sign-in prompt.
- Choose the authentication method enabled for your account; API-key authentication may need separate configuration.
- See the official [authentication guide](https://developers.openai.com/codex/auth/).

## Codex does not use the expected repository context

- Start it from the repository root.
- Check repository instructions and include the relevant files or paths in your request.

## Official docs

- [Codex CLI](https://developers.openai.com/codex/cli/)
- [Authentication](https://developers.openai.com/codex/auth/)