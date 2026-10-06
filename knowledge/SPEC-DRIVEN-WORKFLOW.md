# Spec-Driven Feature Workflow

Use this when a feature's behavior is unclear, it needs several checks, or it needs approval before coding. Acceptance criteria are the checks that show the feature works. Spec Kit is the recommended tool. It keeps the request, plan, tasks, and test results in the repo. Start with the [Spec Kit overview](../tools/spec-kit/OVERVIEW.md) and [setup guide](../tools/spec-kit/SETUP.md).

For a small, safe change with clear behavior, use a short prompt and the repo's usual tests.

## Keep Feature Files Together

Follow the repo's existing layout. One option is:

```text
specs/<feature>/
|-- spec.md          # Intent, scope, assumptions, acceptance criteria
|-- plan.md          # Design, affected areas, risks, test approach
|-- tasks.md         # Ordered, bounded implementation tasks
`-- validation.md    # Checks run, results, and known gaps
```

Commit the files the team needs to review or continue the work. Keep one copy and link back to the original request.

## The Workflow

1. **Write down the request.** Note who needs what, why, limits, and what is not included. Start with:

   ```text
   Goal and why:
   Users or systems affected:
   Desired behavior:
   Acceptance criteria:
   Constraints and out of scope:
   Open questions:
   ```

2. **Write and clarify the spec.** Use the [Spec Kit skills](../tools/spec-kit/COMMANDS.md). Ask a few focused questions about unclear requirements. Add the answers to the spec, not just the chat.

3. **Review the spec.** A person approves what is included and how to check it before planning or coding starts.

4. **Make a plan and tasks.** Write the technical plan, then split it into ordered tasks with clear results and checks. Before coding, an engineer adds missing business, security, system, and repo details. Require this review for business or high-risk work.

5. **Build one small task at a time.** Give the agent the reviewed task and links to its spec, plan, and repo rules. Run the needed tests after each task.

6. **Check and accept the result.** Compare the working feature with every required check. Fix problems, rerun tests, and record results and limits. A person approves the final result.

## Link Requirements to Tests

For each required result, show the task and test that check it. For example:

```text
REQ-01 -> AC-01 -> TASK-02 -> tests/orders/approval.test.ts -> pass
```

Every required result should link to a task and a test. If a full user-flow test cannot cover it, say why and name the unit or integration test that does.

Use the [Spec Kit commands guide](../tools/spec-kit/COMMANDS.md) for current skill names. Follow the [Spec Kit setup guide](../tools/spec-kit/SETUP.md) to add it to an existing repo. Skill names can differ by coding tool. Review each file before moving to the next step.

GSD is an alternative only after it has the required Architecture Review Board (ARB) approval. Until then, use Spec Kit. See [GSD overview](../tools/gsd-pi/OVERVIEW.md), [GSD setup](../tools/gsd-pi/SETUP.md), and [GSD commands](../tools/gsd-pi/COMMANDS.md).

## References

- [Spec Kit overview](../tools/spec-kit/OVERVIEW.md)
- [Spec Kit setup](../tools/spec-kit/SETUP.md)
- [Spec Kit commands](../tools/spec-kit/COMMANDS.md)
- [GSD overview](../tools/gsd-pi/OVERVIEW.md)
- [GSD setup](../tools/gsd-pi/SETUP.md)
- [GSD commands](../tools/gsd-pi/COMMANDS.md)
- [Official Spec Kit project](https://github.com/github/spec-kit)
- [Spec Kit spec-driven development](https://github.github.io/spec-kit/quickstart.html)
- [Repeatable repo workflow](./REPO-WORKFLOW.md)