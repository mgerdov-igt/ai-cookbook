# Start Here

The tutor leads the lessons. You do not need to prepare a project, invent a feature, write separate homework, or study the whole course first.

## Prerequisites

- A local checkout of this cookbook.
- An AI coding tool that can read course files and follow the course's file boundary. Copilot CLI is the default example.
- Windows 11 with PowerShell 7 for the bundled practice project.

The practice project has no package dependencies. Tool setup and costs are separate from the course; see [required tools](../../tools/PREREQUISITES-TOOLS.md) and the [Copilot setup guide](../../tools/copilot-cli/SETUP.md) if needed.

## Start or resume

Open PowerShell in the course folder, then start Copilot from `.course-progress/`:

```powershell
Set-Location 'C:\path\to\ai-cookbook\courses\ai-software-engineering'
New-Item -ItemType Directory -Path '.course-progress' -Force | Out-Null
Set-Location '.course-progress'
copilot
```

Then copy and send this exact prompt:

```text
Start the interactive AI Software Engineering course.
The course folder is the parent of my current working directory.
Read ..\RUN_COURSE.md and follow its Tutor Rules.
Do not create or modify files outside .course-progress/.
Begin or resume my local course progress. Show me the choices and wait.
```

Choose one of the two prepared task-board feature tracks. The tutor creates a private, ignored workspace copy and keeps lesson progress there. Answer each prompt in the AI chat. You may choose an option or type a short answer. Type `pause` to stop and `resume` to continue later.

To continue in a new AI session, repeat the same PowerShell setup and send the same prompt. It starts the course if no progress exists and resumes from saved progress if it does.

## What you will learn

You will practice defining a bounded change, giving the AI useful context, reviewing a plan, approving code work, running checks, and evaluating results. The AI makes the proposed code change in the practice copy; you remain in control of decisions and acceptance.

The AI's feedback evaluates each exercise against its published rubric. It does not certify professional skill or replace software tests and review. Do not share private code, credentials, personal data, or employer information.
