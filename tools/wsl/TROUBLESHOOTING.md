# WSL Troubleshooting

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