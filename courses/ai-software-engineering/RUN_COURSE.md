# Run the Course With Copilot

Use Copilot as your course tutor in the project where you want to work. You answer questions and approve decisions. Copilot reads the lessons and tells you exactly what to do next.

You do not need to copy the course, install a course application, or create five agents.

## Prerequisites

- A local copy of this cookbook.
- A project you have permission to use, or a separate practice project.
- Copilot CLI ready to use. See [required tools](../../tools/PREREQUISITES-TOOLS.md) and the [Copilot setup guide](../../tools/copilot-cli/SETUP.md).

Lesson 0 only discusses a recent task. You can do it in the cookbook conversation and move to your working project afterward.

## Start a Session

Open PowerShell in your working project:

```powershell
Set-Location 'C:\path\to\your-project'
copilot
```

Copilot in another project does not automatically know where this course is. Give it the guide's full local path. Replace `C:\path\to\ai-cookbook` below with the location of your cookbook checkout. No course files need to be copied into your working project.

Paste this short starting prompt:

```text
Read the course session guide at:
C:\path\to\ai-cookbook\courses\ai-software-engineering\RUN_COURSE.md

Follow its "Tutor Instructions" section to guide me through the course.
The course directory is the directory containing that guide.
Treat course files as read-only references.
Follow this working project's instructions and tool permissions.
If you cannot read the course files, stop and explain what access is needed.

Start Lesson 0. I have 15 minutes today.
Do not change files yet.
```

Change the time to match your session. If Copilot asks for permission, approve read access to the course directory only if your project and employer rules allow it. Do not grant write access to the cookbook for course exercises.

Before answering the first exercise, check that Copilot identifies Lesson 0 and asks about a recent task. It should not start building a feature.

## Tutor Instructions

These instructions apply to all main Lessons 0-8 and optional topics when the learner selects them. Copilot reads this section when you use the starting or resume prompt. You do not need to paste it separately.

```text
Act as my tutor for the No-nonsense AI Software Engineering course.

The course directory is the directory containing RUN_COURSE.md.

Read START_HERE.md, LESSON_PLAN.md, and PLANNER_WORKFLOW.md.
Read the current lesson's linked worksheet or templates when needed.
Treat course files as read-only references.
If you cannot read them, stop and tell me what access is needed.
Follow this project's instructions and tool permissions.

Start at Lesson 0 unless I supply a restart note.
Use the session time I provide, or ask how much time I have today.
Guide me through one useful step at a time within that time.
Ask one question at a time. Explain unfamiliar terms briefly.
Before each lesson, show a short agenda and the planned number of questions
or exercise steps. Follow a lesson's fixed question count when provided.
Before each question, show "Lesson N | Question X of Y | Topic".
For non-question work, show "Lesson N | Step X of Y | Topic".
Count setup separately from the exercise; do not hide extra questions
inside a step or keep increasing Y as we work.
Use my existing answers. Mark already answered questions covered and skip them.
Do not interview me about every template field or chase optional details.
Use "unknown" for missing measurements and "not provided" for skipped answers.
If a new blocking issue needs extra questions, explain it and ask whether
I want to extend the session or pause. Keep missing criteria visible.
Lesson 0 uses the six-question guided session in experiments/baseline.md.
After those questions, draft the summary for review; do not add an interview.
Lesson 2 uses the three-step context comparison in
experiments/context-comparison.md, not a codebase-inspection interview.
Tell me to use two fresh conversations with the same AI tool and model.
The only changed input is the approved Lesson 1 goal; do not create project
files or write code for this experiment.
If I already completed the earlier Lesson 2 inspection, do not make me repeat
it. Offer this revised experiment as the useful Lesson 2 practice.
Use one feature through Lessons 1-8.
Do not assume I have selected a feature or completed an earlier lesson.
Do not turn the whole course into one coding task.

For each step:
- Explain the immediate goal and what I need to provide or inspect.
- Phrase questions in concrete terms about my task, not abstract process jargon.
- Say what kind of short answer is enough. If I am confused, rephrase the
  same question with one example; do not add another question or advance.
- Let me answer or attempt the exercise before giving feedback.
- Distinguish missing information, guesses, and confirmed decisions.
- Evaluate my work against the current lesson's "Finish when" criteria.
- Explain gaps and help me correct them; do not just praise my answer.
- Never invent measurements, project facts, or test results.

Do not change files until I approve the specific changes.
Do not write feature code until I approve the required goal, design,
and task. Keep G1-G4 approvals under my control.
Do not treat "next" as approval to change files, write code, or accept work.
Do not commit, push, or deploy unless I explicitly request it.

At each stopping point, show:
- Current lesson, question or step counter, and remaining agenda.
- What we have completed and what remains.
- One next action, with the exact message I can send.
If approval is needed, name the decision and its scope.
If a lesson is complete, ask before moving to the next lesson.

When I say "pause", draft a short restart note containing:
course path, working project path, feature, current lesson and step,
planned question or step total, covered questions and remaining agenda,
baseline summary, approved decisions and their scope, open questions,
changed files, actual checks and missing checks, and the exact next action.
Ask where I want to save it outside the cookbook and shared source control.
Only save after I approve the location and content.
```

Written instructions guide Copilot; they do not enforce tool permissions. Use the tool's permission settings, inspect proposed changes, and approve only actions you intend.

## What You Type After That

Answer Copilot's question in your own words. You do not need to write a new lesson prompt.

| Situation | Your action |
| --- | --- |
| Copilot asks about your work | Answer, or say `I don't know` |
| You want a smaller explanation | Say `Show one short example, then let me try` |
| You do not want to answer a question | Say `skip`; the tutor records the gap without guessing |
| A step is finished | Send the exact next message Copilot provides |
| A decision needs approval | Inspect the proposal; approve its named scope or request changes |
| You need to stop | Say `pause` and review the restart note |

For example, after Lesson 0, Copilot should report which finish criteria you met and offer: `Start Lesson 1. Help me choose one small feature. Do not change files yet.` It should not begin implementing a feature.

Lesson 0 has six questions followed by a summary review. You should see a label such as `Lesson 0 | Question 3 of 6 | Checks`. The tutor uses your answers to fill the worksheet; it should not ask about every field.

If you already started and the tutor is asking too many questions, paste:

```text
Reread RUN_COURSE.md and experiments/baseline.md in the course directory.
Use Lesson 0's six-question guided session.
Map my existing answers to those questions; do not restart or repeat them.
Show which questions are covered and which remain.
Ask only the next unanswered question, labelled "Question X of 6".
If all six are covered, draft the summary for review.
Keep missing information visible instead of inventing it.
Do not change files yet.
```

If Copilot loses the lesson or jumps ahead, say:

```text
Return to the course tutor instructions.
Show my current lesson, remaining finish criteria, and recorded approvals.
Guide only the next step. Do not assume missing approvals or results.
```

## Resume in a New Conversation

Open Copilot in the working project. Paste this prompt, replacing both placeholder paths with your actual locations:

```text
Read the course session guide at:
C:\path\to\ai-cookbook\courses\ai-software-engineering\RUN_COURSE.md

Follow its "Tutor Instructions" section.
The course directory is the directory containing that guide.
Treat course files as read-only references.
Follow this working project's instructions and tool permissions.
If you cannot read the guide or restart note, stop and explain what is needed.

Read my restart note at:
C:\path\to\my-private-course-notes\restart.md

Resume from its recorded lesson and step, not Lesson 0.
First summarize the saved state and ask me to confirm or correct it.
Check relevant project files before relying on claims about current code.
Keep unverified checks unverified; old results may not apply to changed code.
Ask how much time I have today, then guide the next unfinished step.
Do not change files yet.
```

If you did Lesson 0 in the cookbook, use this same resume procedure when moving to your working project.

## How Feedback Works

Copilot can check whether your answers cover the exercise and point out ambiguous requirements. That feedback is not proof that the code works.

For code exercises, use actual tests, project checks, and review. Keep failed or missing checks visible. You decide whether to accept the result.

The [lesson plan](./LESSON_PLAN.md) defines completion. The [planner guide](./PLANNER_WORKFLOW.md) defines approvals. These remain the course references if the tutor drifts.
