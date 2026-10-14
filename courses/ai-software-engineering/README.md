# Interactive AI Software Engineering Course

A self-paced course for software engineers who want to guide AI coding work with better requirements, context, checks, and review. The AI tutor leads the course in the chat. Lessons use a bundled practice project, not a project the student must invent or bring.

## Start the course

1. Start Copilot CLI from `.course-progress/`:

   ```powershell
   Set-Location 'C:\path\to\ai-cookbook\courses\ai-software-engineering'
   New-Item -ItemType Directory -Path '.course-progress' -Force | Out-Null
   Set-Location '.course-progress'
   copilot
   ```

2. Copy and send this exact prompt:

   ```text
   Start the interactive AI Software Engineering course.
   The course folder is the parent of my current working directory.
   Read ..\RUN_COURSE.md and follow its Tutor Rules.
   Do not create or modify files outside .course-progress/.
   Begin or resume my local course progress. Show me the choices and wait.
   ```

3. Answer the tutor's questions or choose from its options. Type `pause` to save and return later.

Use the same commands and prompt in a later AI session. The tutor checks the saved progress and resumes from it; you do not need to write a separate resume prompt.

See [Run the interactive course](./RUN_COURSE.md) for setup, tutor behavior, progress storage, and safety boundaries.

## Course materials

- [Start here](./START_HERE.md): prerequisites and the first step
- [Course map](./COURSE_PLAN.md): outcomes and lesson order
- [Lesson plan](./LESSON_PLAN.md): fixed exercises and assessment rubrics
- [Tutor workflow](./PLANNER_WORKFLOW.md): how the tutor teaches and evaluates
- [Bundled practice project](./practice/README.md): two predefined feature tracks, starter files, and checks

## Student data and workspace

The course saves progress and a writable copy of the practice project in `.course-progress/`. Git ignores this folder. The tracked lessons and starter files remain unchanged. Keep private or employer data out of course answers and saved progress.

## Intended learner

You can already read and review code. The course teaches how to direct an AI coding assistant; it does not teach programming basics. The course is free, self-paced, and does not require registration. Your AI tool may have separate costs.
