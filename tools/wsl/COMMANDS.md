# WSL Basic Commands

Run these from PowerShell unless the line says Bash.

## PowerShell

```powershell
wsl --status
wsl --list --verbose
wsl --list --online
wsl --update
wsl --shutdown
wsl -d Ubuntu
```

- `wsl --list --verbose` shows installed distributions and whether each uses WSL1 or WSL2.
- `wsl --shutdown` stops all running distributions. Use it to apply `.wslconfig` changes.
- `wsl -d Ubuntu` opens Ubuntu.

## Run Linux Commands from PowerShell

```powershell
wsl pwd
wsl git --version
```

## Bash

```bash
pwd
ls -la
git status
```

See [Setup](./SETUP.md) to install the distribution and tools.