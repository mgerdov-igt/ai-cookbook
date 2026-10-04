# No-nonsense AI Software Engineering: Course Map

A free course for experienced engineers. Study at your own pace. Begin with [Start here](./START_HERE.md). Use the [lesson plan](./LESSON_PLAN.md) for explanations and exercises.

## Core path

Use one useful feature throughout. Keep its requirements, decisions, tasks, and test results together. You do not need a new document for each lesson. The planner helps you plan. You approve the work.

| Lesson | Practice | Result |
| --- | --- | --- |
| 0. Record how you work now | Describe your process before you change it | Current-work worksheet |
| 1. Make requirements clear | Answer questions about the goal and limits | Approved goal; G1 |
| 2. Give useful project information | Separate project rules from task details | Links to code, tests, and rules |
| 3. Write the specification and plan checks | Describe required behavior and how to test it | Written requirements and planned checks |
| 4. Approve the system design | Compare choices and confirm rules to preserve | Approved design; G2 |
| 5. Approve small tasks | State the result, needed work, checks, and stop rules | Approved first task; G3 |
| 6. Write code and check it | Use developer, tester, and reviewer steps as needed | Actual check results; G4 |
| 7. Improve your method | Keep useful templates and rules | A small set of reusable tools |
| 8. Review the final project | Check the full feature and compare your results | Final review and comparison |

Use [Working with your planner](./PLANNER_WORKFLOW.md) for example requests and approval steps. Each approval step is called a gate. G1 approves the goal. G2 approves the specification and design. G3 approves a task. G4 accepts checked work.

You can draft tasks early. Do not start code changes until the required decisions are approved. Ask for new approval if requirements or design rules change.

## Optional extensions

These topics are not required. Use them when you have a problem that they can help solve.

| Extension | When useful |
| --- | --- |
| A. Reduce wasted effort | Repeated corrections, high tool use, or long reviews |
| B. Use more AI tools | A repeated task needs automation or external data |
| C. Improve code without changing behavior | A review finds a specific code or design problem |

## Completion

Show what you assigned to AI, what you approved, and how you checked the result. State what you would change next time. Use actual test results, not the AI's confidence. More documents or more agents do not prove success.

## Optional Sources

Reviewed on 2026-10-04: public course outlines and official guides. The full courses were not completed for this review.

- [AI Dev Tools Zoomcamp 2026](https://github.com/DataTalksClub/ai-dev-tools-zoomcamp): closest match for the full development process.
- Anthropic Academy: [Claude Code 101](https://academy.claude.com/courses/claude-code-101) and [Claude Code in Action](https://academy.claude.com/courses/claude-code-in-action). Useful for planning, project information, permissions, and review.
- Supporting Claude Code guides: [good working practices](https://code.claude.com/docs/en/best-practices) and [permissions](https://code.claude.com/docs/en/permissions).

| Source idea | How we use it |
| --- | --- |
| Zoomcamp compares a rough idea with specified work | Lesson 1 compares the original request with agreed requirements |
| Zoomcamp checks the tests and release process | Lesson 6 checks that a test catches bad behavior. Lesson 8 adds release checks only when needed. |
| Academy separates planning from code changes and limits tools | Lesson 5 checks tool permissions before code work |
| Academy manages long chats and checks unattended work | Lesson 7 saves a short restart note. Lesson 6 gives unattended changes closer review. |

Both sources support methods we already teach: clear requirements, short project rules, small tasks, and separate review.

We do not adopt required cloud services, a fixed software stack, registration, certificates, or mandatory parallel agents. Read more only when it helps your current task. These links are optional, not course prerequisites.
