# Claude Code Troubleshooting

## `claude` not found

Check:

```powershell
Get-Command claude
claude --version
```

If missing, reinstall from [SETUP](./SETUP.md).

## Sign-in did not persist

Check auth status:

```powershell
claude auth status --text
```

If needed, sign in again:

```powershell
claude auth login
```

## Resume did not continue expected session

- Use `claude -c` for the latest session in current directory
- Use `claude -r <session-id-or-name>` for a specific session
- Name important sessions so they are easier to resume later

## Too many permission prompts

- Keep normal permissions for risky work
- Use `--dangerously-skip-permissions` only in isolated/trusted environments
- Add clearer constraints and verification instructions
