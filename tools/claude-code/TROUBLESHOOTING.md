# Claude Code Troubleshooting

## Installation needs administrator access

If the installer reports that elevation is required, check your Windows account and current PowerShell session:

```powershell
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
[pscustomobject]@{
	LocalAdministrator = $identity.Groups.Value -contains 'S-1-5-32-544'
	ElevatedSession = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
```

If `LocalAdministrator` is `True` but `ElevatedSession` is `False`, reopen PowerShell with **Run as administrator** for that installation step only. If `LocalAdministrator` is `False`, ask IT or a local administrator to perform the step. Normal tool use does not need elevation.

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
