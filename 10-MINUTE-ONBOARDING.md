# 10-Minute Onboarding

Use this when you want the shortest path to first success.

Follow these steps in order.
If you are still deciding which tool to use, go to [Quickstart](./QUICKSTART.md) first.

## 1) Prepare the machine

1. Install the tools in [Prerequisite tools](tools/PREREQUISITES-TOOLS.md).
2. Apply [PowerShell environment setup](tools/powershell/SETUP.md).
3. Open a new PowerShell 7 session.

Using WSL? Follow [WSL2 setup](tools/wsl/SETUP.md) and install tools inside Linux instead.

## 2) Install one AI tool

For most work, start with Copilot CLI. Choose Claude Code when you need deeper debugging or more careful review:
- [Copilot CLI setup](tools/copilot-cli/SETUP.md)
- [Claude Code setup](tools/claude-code/SETUP.md)

Install one tool first. Add another only when a task needs it.

Other options for specific needs:
- [GSD Pi](tools/gsd-pi/SETUP.md) for large, staged work
- [OpenCode](tools/opencode/SETUP.md) when you need multiple model providers or an approved GLM-5.3 provider
- [Codex CLI](tools/codex/SETUP.md) for implementation followed by a separate review

## 3) Login

Use the tool-specific login flow from the setup page.

If browser auth opens:
- Complete the sign-in in your default browser
- Return to the terminal
- Re-run the version or status command if needed

## 4) Verify

Run only the commands for the tool you installed.

### GSD Pi

```powershell
gsd --version
```

### GitHub Copilot CLI

```powershell
copilot --version
```

### Claude Code

```powershell
claude --version
```

## 5) Run one useful task

Pick one:
- [GSD examples](tools/gsd-pi/EXAMPLES.md)
- [Copilot CLI examples](tools/copilot-cli/EXAMPLES.md)
- [Claude Code examples](tools/claude-code/EXAMPLES.md)

## 6) Verify the result

Before you trust the output:
- Check the changed files yourself
- Run the relevant tests or commands
- Confirm the tool stayed within your constraints

## Tool-specific fast paths

If you only want the minimum sequence for one tool, use one of these and skip the rest of the page.

### GSD Pi fast path

1. Follow [GSD setup](tools/gsd-pi/SETUP.md)
2. Run `gsd --version`
3. Open [GSD examples](tools/gsd-pi/EXAMPLES.md)
4. Start with the smallest practical example

### Copilot CLI fast path

1. Follow [Copilot CLI setup](tools/copilot-cli/SETUP.md)
2. Run `copilot --version`
3. Open [Copilot CLI examples](tools/copilot-cli/EXAMPLES.md)
4. Start with a focused repo task

### Claude Code fast path

1. Follow [Claude Code setup](tools/claude-code/SETUP.md)
2. Run `claude --version`
3. Open [Claude Code examples](tools/claude-code/EXAMPLES.md)
4. Start with a small debugging or implementation task

## If something breaks

Go to [Failure recovery](knowledge/FAILURE-RECOVERY.md).
