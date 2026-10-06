# WSL Troubleshooting

## First install needs administrator access

Run this check in Windows PowerShell or PowerShell 7 on Windows, not inside Linux:

```powershell
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
[pscustomobject]@{
	LocalAdministrator = $identity.Groups.Value -contains 'S-1-5-32-544'
	ElevatedSession = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
```

If `LocalAdministrator` is `True` but `ElevatedSession` is `False`, reopen PowerShell with **Run as administrator** before following [Setup](./SETUP.md). If `LocalAdministrator` is `False`, ask IT or a local administrator to perform the installation. Linux `sudo` privileges do not grant Windows administrator access.

## `wsl` is not recognized

- Install or update Windows Subsystem for Linux from the Microsoft Store or Windows Features.
- Restart Windows, then run `wsl --status` in PowerShell.
- See Microsoft's [install guide](https://learn.microsoft.com/en-us/windows/wsl/install).

## A distribution will not start

From PowerShell, update WSL and restart its virtual machine:

```powershell
wsl --update
wsl --shutdown
wsl -d Ubuntu
```

## A tool works in Windows but not WSL

Install the Linux version of the tool inside your distribution. Windows and WSL have separate programs, `PATH` values, config files, and certificates.

## VPN, proxy, or DNS problems

Keep the default network settings unless a connection fails. See [Networking](./NETWORKING.md) for the optional mirrored mode and proxy settings.

## TLS or certificate errors

See [Company certificates](./CERTIFICATES.md). Use only a certificate provided by your IT or security team.