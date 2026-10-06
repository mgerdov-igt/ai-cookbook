# WSL Networking

Start with the default settings. WSL2 uses NAT networking, which is enough for most development:

- Windows can reach a web server running in WSL through `localhost`.
- WSL can reach Windows services using the Windows host address.
- Current Windows 11 versions pass DNS and proxy settings into WSL by default.

## If a VPN or Localhost Connection Fails

On Windows 11 version 22H2 or later with an updated WSL, mirrored networking can improve VPN support and let Windows and WSL reach each other through `localhost`.

Add these settings to `%USERPROFILE%\.wslconfig`. Keep any settings already in the file:

```ini
[wsl2]
networkingMode=mirrored
dnsTunneling=true
autoProxy=true
```

These settings apply to all WSL2 distributions for your Windows user. Restart WSL to apply them:

```powershell
wsl --shutdown
```

If Windows already uses an HTTP proxy, `autoProxy=true` passes its proxy settings to WSL. Follow your IT team's instructions for custom proxies; do not guess proxy addresses.

## Safety

Do not open Linux services to your local network unless other devices need to reach them. Avoid binding services to `0.0.0.0` for local development; use `localhost` when possible.

## Official docs

- [Access network applications with WSL](https://learn.microsoft.com/en-us/windows/wsl/networking)
- [WSL configuration](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)