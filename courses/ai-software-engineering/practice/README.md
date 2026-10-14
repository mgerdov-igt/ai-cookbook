# Bundled Practice Project

The course uses this small PowerShell task list instead of a student's own project. It runs with PowerShell 7 and has no package dependencies.

The sample is a tiny work tracker for a software team. Each work item is one task with an ID, a short title, a status, and an owner. The status tells the team where the task is: `Open`, `In Progress`, or `Done`. The owner is the teammate responsible for it.

Here is the complete starter list:

| ID | Title | Status | Owner |
| --- | --- | --- | --- |
| 101 | Review sign-in errors | Open | Ava |
| 102 | Update deployment guide | In Progress | Ben |
| 103 | Check backup alert | Open | Ben |
| 104 | Close old access request | Done | Ava |

## Business requests

Choose one request to work from. These are intentionally high-level business
requirements. They describe a user need, not a complete feature design. The
student and tutor will clarify the behavior and write a specification before
any code changes.

| Track ID (for progress only) | Business request |
| --- | --- |
| `status-filter` | “As a team lead, I need to focus on work items at a particular stage so I can see which work is open, underway, or finished.” |
| `owner-filter` | “As a team lead, I need to review work assigned to a particular teammate so I can coordinate the team's workload.” |

The request does not decide how a user selects a value, how values match, what
happens when no value is supplied, or how unmatched values behave. Do not
present those details as already agreed. The tutor guides the student through
clarifying them and records the decisions in a local specification before
implementation.

## Starter files

- `WorkItems.ps1`: tracked, read-only starter source.
- `Run-Checks.ps1`: dependency-free checks for the selected feature.

The tutor copies these files to `workspace/` under the current `.course-progress/` directory before coding. All code changes and test runs use that copy. The initial feature check is expected to fail because the starter does not yet support the selected behavior. The baseline list check should pass.

From the `.course-progress/` directory, run the check for the chosen track:

```powershell
pwsh -NoProfile -File .\workspace\Run-Checks.ps1 -Track status-filter
```

Use `owner-filter` instead when that track was selected. Do not run checks against the tracked starter or edit the tracked files.
