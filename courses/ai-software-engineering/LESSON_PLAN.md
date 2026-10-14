# Lesson Plan and Exercise Rubrics

The tutor follows these six lessons in order. It presents one exercise at a time and does not reveal the expected answer before the student tries. Show the answer key only after the attempt. `✅ Strong` means the key points are present; `🟠❓ Needs one more piece` means the answer is incomplete but not contradictory; `❌ Not correct yet` means it conflicts with a fixed requirement or safety rule. A close paraphrase counts.

Whenever the student is expected to respond, put the exact question and response choices/instructions in a compact ASCII box headed `YOUR TURN`. Keep feedback and progress outside the box so the learner can immediately see what to answer. Use a fresh box for the `Try again` / `Continue` choice after feedback. Do not append another question or competing action after the box.

Example:

```text
Progress: Lesson 2 of 6 | Exercise 2 of 6

+-----------------------------------------------------------+
| YOUR TURN | Exercise 2 of 6                               |
| Question: Which detail is stated in the business request? |
|                                                          |
| A) Exact matching is required                            |
| B) The user needs to focus on a stage or teammate;        |
|    matching rules are not specified                      |
| C) Sorting is required                                    |
|                                                          |
| Reply with A, B, or C.                                    |
+-----------------------------------------------------------+
```

## Lesson 1 — Understand the Business Request (3 exercises)

**Introduce before the first question:** This course uses a tiny work tracker for a software team. Show the four rows in `practice/README.md`. Explain that each row is a task, status shows its stage, and owner is the teammate responsible. Then show both business requests exactly as written in `practice/README.md`. Explain that these are the only starting requirements. They intentionally do not specify detailed behavior.

**Teach:** A business requirement explains the user, their need, and why it matters. It does not yet say exactly how the software behaves. A specification makes that behavior clear and testable. The student chooses one supplied request, not a feature design.

1. **Choose a request.** Offer the two business requests as written. Record the matching track ID privately in progress; do not rename the request to “status filter” or “owner filter” yet.
2. **Restate the need.** Ask who needs what outcome and why. **Key:** the status request is about focusing on work at a particular stage; the owner request is about reviewing work assigned to a teammate to coordinate workload. Do not require an implementation idea.
3. **Spot what is missing.** Ask for one important question that should be answered before implementation. Accept questions that affect observable behavior, such as how a user identifies the stage/teammate, what counts as a match, or what happens when the user has not chosen a value. Do not present one answer as the only valid question.

**Finish when:** The student can state the user need and identify at least one consequential behavior that the business request leaves open.

## Lesson 2 — Gather Context and Clarify Behavior (6 exercises)

**Teach:** Clarifying questions turn an incomplete request into shared decisions. Ask about behavior that changes the result. Do not ask about implementation details before the expected behavior is clear. The tutor must ask one clarification at a time and record the student's decision.

1. **Find project facts.** Ask which file defines the current task data and retrieval behavior: `A: practice/WorkItems.ps1` / `B: a personal project` / `C: an unrelated tool guide`. **Key:** A. Show the actual four tasks from that file or the practice guide.
2. **Separate facts from unknowns.** Ask which statement is established by the business request: `A: exact matching is required` / `B: the user needs to focus on a stage/teammate; matching rules are not specified` / `C: sorting is required`. **Key:** B. Keep the detailed key hidden until the student answers.
3. **Clarify what to match.** First state that the business request does not say whether the student should enter a complete stage/name or just part of the text. Ask which rule is clearer for this small exercise: one complete value or partial text. Show examples using the selected field but do not give the recommendation before the attempt. **Key:** choose one complete value as the bounded course scope; for example, `Open` matches the two Open tasks, not `In Progress`. If the student prefers partial text, explain how that changes the exercise's fixed baseline, then let them choose the bounded course scope or pause. Do not mark the initial preference wrong; assess whether they understand the trade-off.
4. **Clarify case handling.** Point out that the source has `Open` but a user may type `open`. Ask whether these should count as the same value and why. **Key:** yes, ignore letter case to make matching predictable and convenient. Record this as a clarified decision, not text from the original request.
5. **Clarify an omitted value.** Ask what should happen when no stage/name is supplied: `A: return the full original list in its original order` / `B: return no tasks` / `C: treat the missing value as an error`. The bounded exercise scope is A because it preserves existing behavior. Explain the alternatives before asking; record the choice as a requirement.

6. **Clarify an unmatched value.** Ask what the result should be when the user supplies a value that matches no task, such as `Blocked` for status or `Casey` for owner. **Key:** return no items. Explain that this is the published check's bounded behavior if the student proposes a different valid product choice, and record the source accurately.

For each clarification, capture: the question, decision, and effect on the result. Accept student questions and requests for examples. Never claim these details were present in the original BA request.

The published checks define the bounded implementation contract. If a student proposes a different valid behavior, acknowledge the trade-off, then explain the relevant course constraint before asking them to approve the specification. Label its source as a course constraint; do not claim the BA requested it or that the student chose it. Do not ask the student to approve a spec containing a behavior they have not seen and discussed.

**Finish when:** The student can distinguish facts in the BA request from product alternatives and fixed course constraints, and can explain matching, case handling, omitted-value, and unmatched-value behavior in the bounded exercise.

## Lesson 3 — Build and Approve the Specification (4 exercises)

**Teach:** A useful specification connects the original user need to observable behavior, decisions, acceptance criteria, and checks. Acceptance criteria state results a tester can verify. Keep the original business requirement separate from clarified functional requirements.

1. **Separate requirement levels.** Show the original BA request and ask which line belongs in the specification as the user need versus which is a detailed behavior decision or course constraint. **Key:** preserve the BA request as the problem/user need; record the matching rule, case handling, omitted-value behavior, and unmatched-value behavior as detailed requirements with their source labeled—not as claims from the original request.
2. **Write an acceptance criterion.** Ask the student to turn one decision into a testable “Given/When/Then” or equivalent statement. Keep the expected result hidden until after the attempt. A strong criterion names the sample data, the selected input, and exactly which item IDs should and should not be returned. Do not require a particular sentence format if the expected result is precise.
3. **Choose meaningful checks.** Ask which checks cover the agreed behavior: matching value, case variation, no value, and unmatched value. **Key:** all are needed; use the published sample data and check actual results. Keep check results blank until executed.
4. **Review and approve the spec.** Draft `spec.md` inside `.course-progress/` with the original request, clarified decisions, functional requirements, acceptance criteria with expected results, checks, and non-goals. Include no implementation design unless needed. Ask the student to review and approve or correct it. Do not edit code before approval.

**Finish when:** The approved specification preserves the high-level request, labels clarified decisions, defines testable behavior, and lists checks with expected results.

## Lesson 4 — Controlled Implementation (2 exercises)

**Teach:** Work only in `.course-progress/workspace/`. Change the smallest needed part. Do not edit the tracked starter or add features. Run the selected track's checks after coding.

1. **Choose the allowed action.** `A: edit the private copy of WorkItems.ps1 to add the approved filter` / `B: change the tracked starter and both tracks` / `C: install a new framework`. **Key:** A.
2. **Review the proposed result.** The tutor makes the change in the private copy, then summarizes changed lines and checks. Ask whether it stayed in scope. **Key:** only the selected filter and necessary local tests; retain all starter items and unfiltered ordering. If not, correct the code before proceeding.

**Finish when:** The private copy implements only the approved track. If tool permissions prevent edits, report that blocker and do not claim completion.

## Lesson 5 — Checks and Review (3 exercises)

**Teach:** A test result is evidence for a specific behavior. A passing result does not prove unrelated behavior. Keep failures and missing checks visible.

1. **Run the check.** Ask the student to choose: `A: run Run-Checks.ps1 in the private copy with the selected track` / `B: trust the tutor's explanation` / `C: test the tracked starter`. **Key:** A. The tutor runs it and records the actual output.
2. **Interpret a failed check.** Give the real result if a check failed, or a fixed example failure if all pass. **Key:** investigate the behavior, keep the failure visible, correct within approved scope, rerun. Never call a failure a pass.
3. **Accept or reject.** Present actual results. **Key:** accept only if all selected checks pass, the diff stays in scope, and there are no unresolved correctness findings. Otherwise report the exact blocker.

**Finish when:** Each check has an actual result and the acceptance decision follows that evidence.

## Lesson 6 — Pause, Resume, and Transfer (2 exercises)

**Teach:** A local progress record carries the course position, selected track, completion, skips, and actual checks. It is not a substitute for rechecking changed code.

1. **Resume safely.** Ask what the tutor should do with existing progress: `A: read and summarize it, then confirm before continuing` / `B: overwrite it and start over` / `C: guess the next lesson`. **Key:** A.
2. **Transfer the method.** Ask for one short instruction the student could use on future AI work. **Key:** mention a bounded goal, relevant project context, approval before edits, and evidence from checks. Accept any useful combination that does not claim tests replace review.

**Finish when:** Progress is saved, the next action is clear, and the student can name a reusable practice.
