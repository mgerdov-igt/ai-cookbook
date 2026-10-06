# GitHub Copilot CLI Troubleshooting

## Installation needs administrator access

If WinGet or npm reports that elevation is required, check your Windows account and current PowerShell session:

```powershell
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
[pscustomobject]@{
	LocalAdministrator = $identity.Groups.Value -contains 'S-1-5-32-544'
	ElevatedSession = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
```

If `LocalAdministrator` is `True` but `ElevatedSession` is `False`, reopen PowerShell with **Run as administrator** for that installation step only. If `LocalAdministrator` is `False`, ask IT or a local administrator to perform the step. Normal tool use does not need elevation.

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
- Use `/yolo` only in a test branch or separate working copy
- Keep prompts explicit about tests and boundaries
