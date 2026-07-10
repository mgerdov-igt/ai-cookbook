# Common Failure Patterns and Fastest Recovery

Use this when setup or first run fails.

## 1) Command not found

Symptoms:
- `gsd` is not recognized
- `copilot` is not recognized
- `claude` is not recognized
- `pwsh` is not recognized

Fastest recovery:
1. Close the terminal.
2. Open a new PowerShell 7 window.
3. Re-run the version command.
4. If it still fails, return to [Prerequisite tools](./PREREQUISITES-TOOLS.md).
5. Re-check [PowerShell environment setup](./powershell/SETUP.md).

## 2) Browser login completed but terminal still looks unauthenticated

Symptoms:
- Login page succeeded in the browser
- The CLI still asks you to login
- Status commands do not reflect the signed-in state

Fastest recovery:
1. Wait a few seconds.
2. Press Enter once in the terminal.
3. Re-run the tool status or version command.
4. Start a fresh terminal if needed.
5. Retry the setup page for that tool:
   - [GSD setup](./gsd/SETUP.md)
   - [Copilot CLI setup](./copilot-cli/SETUP.md)
   - [Claude Code setup](./claude-code/SETUP.md)

## 3) Node or npm problems

Symptoms:
- Global install fails
- Wrong Node version
- npm permission issues

Fastest recovery:
1. Run `node -v`
2. Run `npm -v`
3. If versions look wrong, return to [Prerequisite tools](./PREREQUISITES-TOOLS.md)
4. Re-open the terminal after install changes
5. Retry the install command from the setup page

## 4) Resume or continue does not behave as expected

Symptoms:
- The tool resumes the wrong context
- There is too much old context
- The task feels stale or confused

Fastest recovery:
1. Stop and summarize the current goal in one paragraph.
2. Start a fresh session for the next attempt.
3. Resume only if the old session still matches the same goal.
4. Use the tool's session commands page if needed:
   - [Copilot CLI commands](./copilot-cli/COMMANDS.md)
   - [Claude Code commands](./claude-code/COMMANDS.md)

## 5) Unsafe or high-autonomy mode was enabled too early

Symptoms:
- The tool is ready to make broader changes than you want
- You no longer trust the next step

Fastest recovery:
1. Stop the current run.
2. Restart with explicit constraints.
3. Ask for a plan before edits.
4. Avoid `/yolo` and `--dangerously-skip-permissions` until the path is clear.
5. Review [Common best practices](./COMMON-BEST-PRACTICES.md).

## 6) Setup works on one machine but not another

Symptoms:
- Same commands, different result
- Browser auth works on one machine only
- Corporate machine behaves differently

Fastest recovery:
1. Compare `pwsh -v`, `node -v`, and `npm -v`.
2. Compare PATH behavior using [PowerShell environment setup](./powershell/SETUP.md).
3. Check for managed-browser or certificate restrictions.
4. Keep notes on what is different before retrying.

## Good fallback rule

If you lose more than 10 minutes on setup:
1. Stop changing multiple things at once.
2. Go back to the exact setup page.
3. Re-run only the minimum verify commands.
4. Fix one failure at a time.

## Related docs

- [10-minute onboarding](./10-MINUTE-ONBOARDING.md)
- [Prerequisite tools](./PREREQUISITES-TOOLS.md)
- [PowerShell environment setup](./powershell/SETUP.md)
- [Common best practices](./COMMON-BEST-PRACTICES.md)
