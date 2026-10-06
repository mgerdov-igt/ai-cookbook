# WSL2 Setup (Windows 11 + PowerShell)

## Prerequisites

- Windows 11
- Administrator access for the first install

## Install WSL2 and Ubuntu

Open **Administrator PowerShell** and run:

```powershell
wsl --install -d Ubuntu
```

Restart Windows if asked. Open Ubuntu from the Start menu. The first run asks you to create a Linux username and password. The password does not appear while you type.

New WSL installs use WSL2 by default. If the install command only shows help, list available distributions and install Ubuntu:

```powershell
wsl --list --online
wsl --install -d Ubuntu
```

If the download stays at 0%, try:

```powershell
wsl --install --web-download -d Ubuntu
```

## Verify

From PowerShell:

```powershell
wsl --status
wsl --list --verbose
```

Confirm Ubuntu shows version `2`. If it shows version `1`, convert it:

```powershell
wsl --set-version Ubuntu 2
```

## Prepare Linux

In the Ubuntu terminal, update package information and install basic tools:

```bash
sudo apt update
sudo apt install git curl ca-certificates
```

Install Node.js and other development tools inside Ubuntu when a project needs them. Windows installs are separate.

Keep active projects in the Linux home folder for better file performance:

```bash
mkdir -p ~/src
cd ~/src
```

Clone the project there. To open the current folder in VS Code, install the WSL extension, then run `code .` from Ubuntu.

## Next

- [Networking](./NETWORKING.md)
- [Company certificates](./CERTIFICATES.md)
- [Common commands](./COMMANDS.md)

## Official docs

- [Install WSL](https://learn.microsoft.com/en-us/windows/wsl/install)
- [Set up a WSL development environment](https://learn.microsoft.com/en-us/windows/wsl/setup/environment)