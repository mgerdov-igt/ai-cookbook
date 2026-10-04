# No-nonsense AI Software Engineering: Lesson Plan

## Use One Feature

Read [Start here](./START_HERE.md). Use one useful feature through Lessons 1-8. Keep its requirements, decisions, tasks, and test results together. One document can be enough.

Use [Working with your planner](./PLANNER_WORKFLOW.md) for example requests and approval rules. An approval step is called a gate. You approve the goal at G1, the design at G2, and each task at G3. You accept checked work at G4.

Combine early approvals for a small, low-risk change. You can draft tasks early. Do not start code changes while important questions remain unanswered.

Each exercise improves the same feature. Record a short note after each lesson. No separate homework or submission is required.

The No-nonsense rule: use the fewest steps that give clear decisions and reliable checks. Optional [source courses](./COURSE_PLAN.md) add detail, not required work.

## Lesson 0 — Record How You Work Now

**Main idea:** Understand your process before you change it. Quick work with AI can be useful. Find where unclear requests, errors, or repeated corrections cause problems.

**Common mistake:** Changing tools before you know what went wrong.

**Example:** Three export corrections may come from an unanswered question: export the current page or all matching rows?

**Exercise:** Complete the [current-work worksheet](./experiments/baseline.md) for a recent task. Record what happened. Choose one possible cause to check.

**Finish when:** You can describe the task from request to commit. Name one method to keep and one idea to test. Write `unknown` for missing measurements.

## Lesson 1 — Make Requirements Clear

**Main idea:** Tell the planner what you want and what must not change. Ask questions in small groups. A guess is not an approved decision. You decide what to build. The AI can choose code details within your rules.

**Common mistake:** Asking for an export feature without stating what it must include.

**Example:** "Current page or all filtered results?" changes the required behavior, amount of data, and design.

**Exercise:** Select your course feature. Use the planner guide's first example request. Ask for no more than three important questions at a time. Record confirmed requirements, guesses, unanswered questions, and work not included. Answer questions that prevent approval. Approve G1, or record why work cannot continue.

Compare the original request with the agreed requirements. Mark the decisions that the AI would otherwise have guessed.

**Finish when:** The planner can restate the goal without making decisions for you. You know what is approved. Code changes have not started.

## Lesson 2 — Give Useful Project Information

**Main idea:** Context means information that the AI receives. Keep long-term rules in project files. Keep task details with the task. Give links to related code, tests, and shared input and output rules. Ask the planner to show the source of its claims.

**Common mistake:** Pasting all project files into a chat or repeating the same rules in each request.

**Example:** "Keep each customer's data separate" is a project rule. "Limit this export to 5,000 rows" is a feature requirement.

**Exercise:** Ask the planner to read the related code and tests without changing them. Add useful links to your notes. Correct an old or missing rule if needed. Ask for new G1 approval if the code shows that the approved goal must change.

**Finish when:** Each piece of information has a purpose. The planner can show where its claims came from. A new chat can find the rules without the old conversation.

## Lesson 3 — Write the Specification and Plan Checks

**Main idea:** A specification is a written description of required behavior. Acceptance criteria are the specific results you must check. Give each one an ID, such as AC-1. Plan a check for each result before writing code.

**Common mistake:** Writing "secure and fast" without access rules, error behavior, or response-time requirements.

**Example:** "If more than 5,000 rows match, return the agreed error and no file" is testable. "Handle large exports" is not clear enough.

**Exercise:** Write the [feature specification](./templates/feature-spec.md) with the planner. State required behavior, limits, and work not included. List planned checks and expected results by ID. Ask a tester to check a normal case, a limit, and an error case in the plan. Correct the specification before design approval.

**Finish when:** Each requirement has a clear check. Unanswered questions are listed. Keep actual results empty until tests run. Leave G2 pending until you approve the design.

## Lesson 4 — Approve the System Design

**Main idea:** Architecture means the system's main parts and how they work together. Ask the architect to check data ownership, access rules, shared interfaces, and operating limits. Prefer existing designs unless a change has a clear benefit. You do not need to choose every function.

**Common mistake:** Asking for several complex designs and letting the AI select one without your approval.

**Example:** The export may reuse the current data query instead of adding a background job system. A row limit does not prove that the query is fast enough.

**Exercise:** Ask the planner to request a design review of your specification and current code. Compare the simplest suitable choice with another choice when needed. Record your decision, reasons, risks, and required checks. Update the specification. Approve G2 only after important design questions are answered.

**Finish when:** You can explain what stays unchanged and why you chose the design. Investigate unresolved safety or performance risks. Do not replace missing results with guesses.

## Lesson 5 — Approve Small Tasks

**Main idea:** Each task needs a useful result, clear limits, and a check. Split work by behavior and required order. Work can run at the same time only when shared interfaces and responsibilities are agreed. A small feature may need one task.

**Common mistake:** Assigning a whole feature with no stop rules, or creating too many small tasks.

**Example:** "Export this customer's matching orders within the row limit, with tests" has a result. "Create helpers" may not.

**Exercise:** Ask the planner for a short task list. Complete the [task template](./templates/agent-task.md) for the first task. Include requirement IDs, work that must finish first, allowed changes, test commands, and stop rules. Approve G3. Add detail to later tasks only when needed.

Check tool permissions before starting. Let planning and review roles read without changing files where the tool supports this. Written instructions alone do not restrict tool access. Use tool settings and safe test environments for needed limits.

**Finish when:** The developer knows what to change, what to check, and when to stop. It does not need to guess the goal or design.

## Lesson 6 — Write Code and Check It

**Main idea:** Writing code and checking it are different jobs. Developer, tester, and reviewer can be separate steps with one tool. Start a new chat for review to reduce influence from the coding discussion. A new chat alone does not prove that the review is independent or correct.

**Common mistake:** Letting the coding chat write tests from its own assumptions and then declare success.

**Example:** A file-format test passes, but a full request test finds another customer's data. Test the requirement, not just the new function.

**Exercise:** Write code for the approved task. Run the planned tests, error-case tests, build, and other required checks. Give a reviewer the approved specification, design, code changes, and actual results. Ask the planner to list failures, review findings, and results for each requirement. Repeat for the other approved tasks.

Where practical, confirm that one important test rejects known bad behavior in a safe test setup. Restore the correct version and rerun it. Review unattended changes more closely. Focus review findings on errors, missing requirements, and broken design rules, not optional style choices.

**Finish when:** Mark each requirement passed, failed, or not checked. Explain missing checks. Required checks that fail or have not run prevent acceptance. Inspect changes for extra work or broken design rules. Get new approval if requirements or shared interfaces change. Fixing a local error within approved rules does not require a new design.

## Lesson 7 — Improve Your Method

**Main idea:** Keep only the templates and rules that helped. Clear project notes make new chats easier. Too many notes can waste time and hide important information.

**Common mistake:** Building a large AI tool system before proving that it solves a repeated problem.

**Example:** One access rule and a short task template can replace repeated explanations. Five similar review lists may not help.

**Exercise:** Review unclear decisions, corrections, errors, and your review time for this feature. Keep useful project rules and specification, task, and review templates. In a new chat, ask an AI to find the rules and propose a task plan. Do not allow changes yet. Remove unused notes and add missing information.

Before ending a long chat, save a short restart note: goal, approved decisions, changed files, checks still needed, and next action. Check the note before giving it to a new chat.

**Finish when:** You can use the saved material without the old chat or a specific AI product. Each item has a purpose. Code cleanup is optional and needs a specific reason.

## Lesson 8 — Review the Final Project

**Main idea:** Show decisions and actual results, not a large set of documents. Your course feature can be the final project. You do not need to start another project.

**Common mistake:** Showing a working demo without explaining the requirements, approvals, or missing checks.

**Example:** The export review links each requirement to an approved task, code change, test result, and acceptance decision.

**Exercise:** Finish the feature. Review requirements, design, approved tasks, code changes, test results, review findings, and documentation. Check that the final code follows the approved design. Explain why any optional work was not needed. Compare results with your first worksheet. Note differences in task difficulty and tools.

If the feature will be released, state how to check it after release and how to undo it. Use the project's existing release process. A public deployment or new monitoring system is not required.

**Finish when:** Explain what you assigned to AI, what you approved, and why you accepted the result. State what is not checked. Record three methods to keep, one to stop, and one idea to test next.

## Optional Topics

### A. Reduce Wasted Effort

**Main idea:** Include errors, repeated work, and your time when comparing AI costs. Extra useful information can cost less than repeated corrections. Tokens are small units of text that AI tools process.

**Common mistake:** Saving tokens while increasing debugging time, or treating message counts as token counts.

**Example:** A new chat with clear requirements can avoid repeated explanations. It also takes time to supply the information again.

**Exercise:** Compare two similar tasks or repeat a task from notes. Record messages, corrections, errors, review time, and tool use when known. Use the [experiment guide](./experiments/README.md). Mark missing measurements `unknown`. Note differences in the tasks and the order you tried them.

**Finish when:** Choose a clear rule for when to stop or start a new chat. If the same misunderstanding keeps returning, correct the requirements or project information first.

### B. Use More AI Tools

**Main idea:** A skill stores instructions for repeated work. A subagent is an AI assigned a separate task. MCP connects an AI tool to other tools or data. A hook runs an action when a named event occurs. Use these tools only when they solve a problem.

**Common mistake:** Connecting tools or adding agents before finding a repeated need.

**Example:** A local test may need a script, not another agent or an external data connection.

**Exercise:** Compare instructions, a script, a separate AI step, and no automation for a repeated task. For external access, list data sent, required access keys, possible changes, and how to disable the connection. Give only the permissions needed. Try a part that you can undo. Use official product guides for setup.

**Finish when:** Each added tool has a clear benefit. You do not need a live MCP connection or a fixed number of agents.

### C. Improve Code Without Changing Behavior

**Main idea:** Refactoring means changing code structure without changing its required behavior. Do it to fix a specific maintenance or design problem. A change must be worth its risk.

**Common mistake:** Removing code because it looks AI-written, or turning a small cleanup into a new design.

**Example:** Two copies of an access check can give different answers later. An unfamiliar helper name alone may not need a change.

**Exercise:** If review found a specific problem, choose one small improvement. Add tests that protect existing behavior. Approve the change, make it, rerun tests, and review the result. Skip this topic if no useful improvement is needed.

**Finish when:** The change solves a named problem and keeps the approved behavior. If required behavior changes, update and approve the specification first.