# No-nonsense AI Software Engineering: Maintainer Guide

This is a maintainer reference.
It is not required student reading.
Use the current course pages for lesson details.

## Purpose and Learner

Help an experienced engineer direct AI coding work with clear requirements,
useful project information, human design decisions, and reliable checks.
The learner has about 20 years of software development experience.
This is not a beginner programming course or a course about writing prompts.
Build on the learner's engineering judgment.
Explain why a method helps.
Keep methods that improve real work.

The course is free and self-paced.
There is no registration.
External AI tools can have separate costs.
Teach methods that work across vendors.
Use specific products only as examples.

## Core Principle: No-nonsense

This course is part of the No-nonsense AI Cookbook.
Respect the time and experience of busy engineers.
Start with what to do, why it matters, and how to check the result.
Use plain English that is easy to read.
Formal STE compliance is not a course goal.

- Use short sentences.
- Give one instruction per sentence.
- Use common words.
- Explain necessary technical terms when first used.
- Remove jargon that does not help the reader.
- Keep examples and instructions clear and concise.
- Link to detailed sources instead of repeating their content.
- Add work or tools only when they solve a real problem.

Use the [optional source review](./ai-software-engineering/COURSE_PLAN.md) when considering outside course ideas.
Keep only ideas that improve decisions or checks without adding unnecessary work.
Keep tool-specific setup in linked product guides.

## Current Course Pages

- [Start here](./ai-software-engineering/START_HERE.md): preparation and first steps.
- [Course map](./ai-software-engineering/COURSE_PLAN.md): current names and order.
- [Lesson plan](./ai-software-engineering/LESSON_PLAN.md): explanations and exercises.
- [Planner workflow](./ai-software-engineering/PLANNER_WORKFLOW.md): planning and approvals.
- [Baseline worksheet](./ai-software-engineering/experiments/baseline.md): record current work.
- [Feature template](./ai-software-engineering/templates/feature-spec.md): requirements and checks.
- [Task template](./ai-software-engineering/templates/agent-task.md): small work assignments.
- [Learning log](./ai-software-engineering/LEARNING_LOG.md): observations and results.

## Course Order

Start with the baseline before changing the learner's method.
Record what works, recurring problems, and available measurements.
Use one real feature that the learner is authorized to change.
Keep requirements, decisions, tasks, and check results in shared notes.
Do not require a separate document for every lesson.

The nine core lessons are:

0. Record how you work now
1. Make requirements clear
2. Give useful project information
3. Write the specification and plan checks
4. Approve the system design
5. Approve small tasks
6. Write code and check it
7. Improve your method
8. Review the final project

The optional extensions are:

- A. Reduce wasted effort
- B. Use more AI tools
- C. Improve code without changing behavior

Do not require automated coordination of agents or a code refactor.
Use either only when it solves a concrete problem.

## Planner and Human Approval

The planner is the central planning partner.
It asks questions, drafts requirements, plans checks, and requests design advice.
It coordinates developer, tester, and reviewer work as needed.
These roles can be separate steps with one agent.
They do not need to run at the same time.

The human owns decisions and approvals.
An approval step is called a gate.
G1 approves the goal.
G2 approves the specification, which states required behavior, and the system design.
G3 approves a small task with clear limits and stop rules.
G4 accepts work after checks and review.
Plan checks while writing requirements.
Approve design decisions before final task approval.
Do not start code changes before the required approvals.
Request new approval when requirements or design rules change.

## Checks, Safety, and Useful Experiments

Match planning and review effort to the size, complexity, and risk of the change.
Give the agent relevant code, tests, and project rules.
Keep templates simple.
Stop repeated corrections to check for unclear requirements or missing information.
A fresh session can remove outdated assumptions.
Fresh context alone does not prove correctness or independent review.

Use actual test results and review findings as evidence.
Check required behavior, failure cases, and existing behavior that must remain unchanged.
Tests can repeat the same mistaken assumptions as the code.
Review what the tests check.
Label example results as examples.
Do not present reported learner outcomes as proof of course effectiveness.
State what was observed and what remains uncertain.

Do not put passwords, keys, personal data, or confidential material in course notes.
Remove private details from examples. Use tools only with permission.
Compare methods using total cost: tool charges, human effort, time, risk, and rework.
Token counts, which measure chunks of model input and output, are only one measure.
Record available measurements and their limits in the learning log.
Keep only the reusable rules and templates that helped.
