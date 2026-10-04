# Feature Specification

## Use What You Need

For a small, low-risk change, keep the problem, required behavior, checks, rules, and one approval. State work that is not included. Remove unused sections.

For changes to shared interfaces, data, or system design, use the detailed sections below. Record existing rules first. Resolve new design questions before G2 approval. Add actual results only after checks run. See the [planner guide](../PLANNER_WORKFLOW.md) for approval steps and an example.

## Feature

<!-- Short name -->

## Problem

<!-- What problem does this solve? -->

## Required Behavior

Describe what users or other code must observe, not how to write the code.

## Acceptance criteria

These are the results required for acceptance. Give each one an ID. Mark it complete only after the required check passes.

- [ ] AC-1:
- [ ] AC-2:
- [ ] AC-3:

## Decisions

| Question or guess | Confirmed answer or open question | Does this prevent work? | Who decides? |
| --- | --- | --- | --- |
|  |  |  |  |

## System Design Rules

- Existing code, data, and access rules to keep:
- Link to the design decision, or explain why no new decision is needed:
- Design questions still needing approval:

The design can be pending while you draft this page. Approve it before G2 passes.

## Checks and Results

Plan checks and expected results before G2. Add actual results after running checks on the changed code. Do not change expected results to hide a failure. Ask for approval if requirements must change.

| Requirement ID | Planned check and expected result | Actual result after the check runs |
| --- | --- | --- |
| AC-1 |  |  |

## Approvals

A gate is an approval step. Use [the planner guide](../PLANNER_WORKFLOW.md) for its rules. Combine early approvals for low-risk work. A draft is not approval.

| Gate | Status: pending / passed / blocked | Supporting facts or results | Your approval |
| --- | --- | --- | --- |
| G1: Goal ready | pending |  |  |
| G2: Design ready | pending |  |  |
| G4: Change checked | pending |  |  |

Approve each code task at G3 in the [task template](./agent-task.md).

## Rules and Limits

- Rule:

## Not Included

- Item:

## Shared Inputs and Outputs

State API, event, file, or command-line rules. Include required error behavior.

## Limits and Error Cases

- Case:

## Finish When

- [ ] Required code changes are complete
- [ ] Tests are added or updated
- [ ] Existing tests pass
- [ ] Each requirement has passed its checks
- [ ] Documentation is updated if needed
- [ ] Code follows the approved system design
