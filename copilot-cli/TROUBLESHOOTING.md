# GitHub Copilot CLI Troubleshooting

## `copilot` not found

Check:

```powershell
Get-Command copilot
copilot --version
```

If missing, reinstall from [SETUP](./SETUP.md).

## Login fails or loops

- Run `copilot`
- Run `/login`
- Complete browser auth again
- If needed, try terminal login path:

```powershell
copilot login
```

## Resume does not show expected session

- Try `copilot --continue` for the latest local session
- Try `copilot --resume` and pick from the list
- Make sure you are in the expected working directory

## Too many permission prompts

- Stay in normal mode for risky work
- Use `/yolo` only in trusted branches/worktrees
- Keep prompts explicit about tests and boundaries
