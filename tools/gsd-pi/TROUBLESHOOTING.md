# GSD Pi Troubleshooting

## `gsd` not found

Check:

```powershell
where.exe gsd
npm list -g @opengsd/gsd-pi
```

If missing, reinstall from [SETUP](./SETUP.md).

## Provider login did not complete

- Re-run `gsd`
- Open `/gsd config`
- Repeat provider auth flow
- Confirm status with `/gsd status`

## Old install is shadowing new one

Use the migration steps in [SETUP](./SETUP.md).

## Global npm install permission errors

If npm reports that elevation is required, check your Windows account and current PowerShell session:

```powershell
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
[pscustomobject]@{
	LocalAdministrator = $identity.Groups.Value -contains 'S-1-5-32-544'
	ElevatedSession = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
```

If `LocalAdministrator` is `True` but `ElevatedSession` is `False`, reopen PowerShell with **Run as administrator** for that installation step only. If `LocalAdministrator` is `False`, ask IT or a local administrator to perform the step. Normal tool use does not need elevation.

## Auto mode drifts or produces weak results

- Split work into smaller slices
- Tighten acceptance criteria
- Review slice output before continuing
- Use stronger model for planning and gate reviews
