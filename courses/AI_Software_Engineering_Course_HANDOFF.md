# AI Software Engineering Course — Handoff

This file records durable course decisions and open design questions. Update it when the course model changes. Do not use it as student progress storage; student progress is local and ignored in `ai-software-engineering/.course-progress/`.

## Vision

The student checks out the cookbook, opens the course folder in an AI coding tool, and asks the tool to start the interactive course. The AI tutor drives short lessons, asks one exercise at a time, evaluates against explicit answer keys, lets the student retry or continue, and keeps progress visible. The student should not need to invent a project, select personal features, or compose prompts as homework. The course begins with a high-level business request and guides the student to elicit missing behavior and build a testable specification before coding.

The course optimizes for logical progression, clear feedback, engagement, and the ability to pause and resume. It is a guided learning experience, not a project planner that happens to contain lessons.

## Decisions made

| Topic | Decision |
| --- | --- |
| Default tool | GitHub Copilot CLI; course instructions should also work with other AI coding tools that can read files and save local state. |
| Course workspace | A small, bundled PowerShell practice project. The student selects one of two predefined feature tracks: task status filter or task owner filter. |
| Business request and context | Start from one of two user-focused, high-level business requests. Explain the work-tracker scenario, define status and owner, and show the sample rows. Do not reveal detailed filtering behavior as if it were in the request. |
| Specification practice | Guide the student from the original request through unknowns and clarification decisions to functional requirements, acceptance criteria, planned checks, non-goals, and an approved `spec.md` in `.course-progress/`. Preserve the original request separately from clarified decisions and label fixed exercise behavior as a course constraint. |
| Response-target visibility | Put the exact current exercise/question and answer choices or response cue inside a compact ASCII `YOUR TURN` box. Keep feedback and progress outside it; do not place competing questions after the box. |
| State assumptions before testing | Restate the agreed requirement before a scope/correctness question. Do not score students against unstated requirements; clarify and allow another attempt if the missing context caused confusion. |
| Student work | Interact with the tutor, choose options or answer in chat, approve a bounded task, and review the sample change. No personal project or self-invented feature is required. |
| File boundary | Start the AI tool in `.course-progress/`. Tell it to create and change files only there. Put the selected starter copy under `.course-progress/workspace/`; never edit tracked course or starter files. |
| Local state | `.course-progress/` inside the course folder stores progress and the writable workspace. Root `.gitignore` excludes it. Never store learner state in tracked files. |
| Course path | Six lessons: understand the business request, gather context and clarify behavior, build and approve a specification, implement within scope, check and review, pause/resume/transfer. |
| Exercise feedback | Fixed rubrics with three outcomes: `✅ Strong`, `🟠❓ Needs one more piece`, and `❌ Not correct yet`. Offer retry or continue; continuing past unmet material records it as skipped, not mastered. |
| Progress UX | Show lesson/exercise position, completed and skipped exercises, remaining lesson work, and exact next action. Save after meaningful progress events; confirm saved state before resuming. |
| Safety | Keep student setup short: do not require sandbox commands or status checks. Tutor instructions say to write only under `.course-progress/` and stop if a write elsewhere is needed. No package installation, unrelated project access, course source edits, Git state changes, commit, push, or deployment. |
| Student data | Keep answers and progress free of secrets, private source, personal, or employer data. |

## Current course structure

- `ai-software-engineering/RUN_COURSE.md`: launch prompt and tutor operating contract.
- `ai-software-engineering/LESSON_PLAN.md`: six lesson definitions, fixed exercise counts, and rubrics.
- `ai-software-engineering/practice/`: read-only PowerShell starter and dependency-free check script.
- `ai-software-engineering/.course-progress/`: ignored runtime progress/workspace (created when a student starts).

The feedback icons distinguish answer quality, not necessarily objective pass/fail in all contexts. Rubrics are designed to avoid marking a partial answer as correct.

## Open decisions / validation needed

1. **Path-following behavior:** Try the course with Copilot CLI and another coding assistant. Confirm they honor the `.course-progress/` write-only instruction and do not modify tracked files.
2. **PowerShell output behavior:** Execute the starter checks on PowerShell 7 and verify both selected-track scripts fail initially only for missing filtering, then pass after the tutor's intended minimal implementation.
3. **Progress file robustness:** Decide whether plain JSON is sufficient or whether a small versioned recovery/backup mechanism is warranted. Avoid adding infrastructure unless real tool behavior requires it.
4. **Cross-tool portability:** Try the launch prompt in at least one additional AI coding tool. Keep product-specific differences in tool setup guides rather than complicating the shared lesson flow.
5. **Pedagogy and engagement:** Try the full path as a learner. Check that material remains concise, the question rhythm is engaging, retries are constructive, and six lessons have a coherent progression.
6. **Scope of course workspace:** Current practice is a small function over an in-memory task list. Reassess whether it sufficiently teaches AI software engineering (especially tests and review) without expanding the sample into a full application.
7. **Language and accessibility:** Keep student-facing language plain. Confirm icons are supplemented with text labels so feedback is understandable without color or emoji rendering.

## Validation status and next steps

The provided check script was run for both tracks. In each case, the baseline list check passes and the selected feature check fails because the starter intentionally has no filter parameter yet. This is the expected pre-implementation state. Temporary, untracked implementations matching the published contract were also tested for both tracks; all checks passed. This validates the script and contract, not the tutor's future generated code or the end-to-end student workflow.

1. Walk through each lesson as a simulated student, checking counters, answer feedback, retry/continue and skip behavior.
2. Validate the progress JSON read/write and pause/resume behavior using only a temporary `.course-progress/` workspace; do not commit learner files.
3. Verify Copilot CLI can read course files, create local state, copy and edit the practice workspace, and run `pwsh`.
4. Try the launch prompt in another AI coding tool and check that the six-lesson experience remains usable.
5. Revise this handoff with observed decisions and evidence after the first end-to-end trial.
