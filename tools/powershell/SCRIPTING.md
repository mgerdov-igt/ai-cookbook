# PowerShell Scripting Rules

Rules for scripts that AI tools write or run, such as the `.ps1` files bundled with [skills](../../skills/README.md). They target PowerShell 7+ on Windows 11. For setup, see [PowerShell environment setup](./SETUP.md). For interactive commands, see [PowerShell basics](./BASICS.md).

## Write scripts that are safe to run

- Add `[CmdletBinding()]` and a `param()` block. Take input through parameters, never `Read-Host`, so the script runs unattended.
- Use `[switch]` for on/off flags. Never use `[bool]` and never give a switch a default value.
- Add `[ValidateSet()]` or `[ValidateNotNullOrEmpty()]` where it limits bad input.
- Set `$ErrorActionPreference = 'Stop'` near the top, or pass `-ErrorAction Stop` on calls that must not fail silently. Wrap risky steps in `try`/`catch` and print a clear message.
- For scripts that change or delete things, use `[CmdletBinding(SupportsShouldProcess)]` and call `$PSCmdlet.ShouldProcess(<target>, <action>)` right before the change. This gives the user `-WhatIf` and `-Confirm`.
- Treat paths as data: use `-LiteralPath` for paths that may contain `[` or `]`, and quote paths with spaces.
- Never store credentials in a script. Use the tool's own sign-in or an environment variable.

## Write output other tools can read

- Return objects, not formatted text. Use `[pscustomobject]@{ ... }`, and `ConvertTo-Json` when a skill needs JSON. Do not use `Format-Table` or `Write-Host` for data.
- Use `Write-Verbose` for details, `Write-Warning` for risks, and `Write-Error` or `throw` for failures.
- Give a fixed final line or one JSON object, and clear exit codes: `0` success, non-zero for each failure type. Document them in the skill.

## Keep the style plain

- Name functions `Verb-Noun` with an approved verb (`Get-Verb`) and a singular noun, in PascalCase.
- Use full cmdlet names in scripts: `Get-ChildItem`, not `ls`, `dir`, or `gci`. Aliases are fine in an interactive shell.
- Use 4-space indentation, opening braces on the same line, and `param` names in PascalCase.
- Add comment-based help (`.SYNOPSIS`, `.PARAMETER`, `.EXAMPLE`) at the top of every script a person runs.

## Let the tool write files, not the shell

Do not create or edit a file by sending its content through a shell command: `Set-Content`, `Out-File`, `>`, `>>`, or a here-string. Multi-line text can be cut off or garbled by quoting, backticks, and special characters. Use the AI tool's file create and edit feature. Use a shell only to run programs and read results. See [Failure recovery](../../knowledge/FAILURE-RECOVERY.md#7-a-file-is-garbled-or-truncated-after-the-tool-wrote-it).

## Check a script

```powershell
pwsh -NoProfile -File .\script.ps1 -WhatIf
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile("$PWD\script.ps1", [ref]$null, [ref]$errors)
$errors
```

The second command parses the file without running it. No output means no syntax errors.

## Source

Adapted from the [PowerShell guidelines](https://github.com/github/awesome-copilot/blob/main/instructions/powershell.instructions.md) in github/awesome-copilot (MIT; see [THIRD-PARTY-NOTICES](../../THIRD-PARTY-NOTICES.md)), which follow Microsoft's cmdlet guidelines.
