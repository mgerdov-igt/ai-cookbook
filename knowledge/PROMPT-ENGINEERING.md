# Prompt Engineering

A prompt is a work order. The clearer the order, the less rework. Use this page for habits that work in any AI coding tool. For copy-paste prompts, see [Prompt templates](./PROMPT-TEMPLATES.md).

## The basics

Say four things:

```text
Goal: <what to achieve>
Context: <relevant files, stack, constraints>
Do not: <forbidden changes>
Done when: <how to check it works>
```

Weak:

```text
Fix the login bug.
```

Better:

```text
Goal: Fix the login failure when the password has a "+" character.
Context: src\auth\login.ts, test in tests\auth\login.test.ts. Error: "401 invalid credentials".
Do not: Change the API response shape or other auth files.
Done when: A new test for "+" fails before the fix, and `npm test` passes after it.
```

More basics:
- **One goal per prompt.** One prompt should produce one diff you can review.
- **Name files.** Use `@path` in tools that support it. Otherwise write the path.
- **Paste the exact error.** Do not describe it. Cut long logs to the relevant lines.
- **Ask for a plan before big edits.** Approve it, then say "implement".
- **Keep the chat short.** Start a new session after a milestone. See [Keep chats focused](./COMMON-BEST-PRACTICES.md#keep-chats-focused).

## Past the basics

### Give the check, not only the goal
Give the exact command that proves success, such as `npm test` or `dotnet build`. The tool can then run it and fix its own mistakes.

### Investigate before you edit
For unclear problems, split the work:

```text
Read only. Do not edit files. Find the cause of <symptom>. Cite file and line for each claim. List what you could not confirm.
```

Review the findings, then ask for the fix in a second prompt.

### Point at an example
"Follow the pattern in `src\orders\OrderService.ts`" beats a long style description.

### Let it ask questions
```text
If anything is unclear, ask me up to 3 questions before you start.
```
Use this when the request is new or vague. Skip it for mechanical work.

### Limit the scope in files, not adjectives
"Only change files under `src\billing\`" works. "Keep it minimal" does not.

### Ask for evidence
Ask for file paths, command output, or test results with each claim. Treat claims with no evidence as guesses.

### Control the output
Say what you want back: a plan, a patch, a root-cause note, or a short summary of changed files and risks.

### Save rules you repeat
If you keep typing the same rule, move it to the project instruction file: `AGENTS.md`, `CLAUDE.md`, or `.github\copilot-instructions.md`. If you keep typing the same steps, make it a [skill](../skills/README.md).

### Use a second opinion for review
Review in a fresh session, or with a different model than the one that wrote the code. The author tends to repeat its own blind spots. See [Model selection](../tools/MODEL-SELECTION.md).

### Match the model to the task
Start with a fast or everyday model. Move up a tier when answers are shallow or miss constraints. See [Model selection](../tools/MODEL-SELECTION.md).

## When the output is wrong

1. Do not argue. Paste the failing test, error, or diff and say what is wrong.
2. If two corrections do not help, stop. Revert the change.
3. Restate the goal with the new facts you learned and start a fresh session.
4. If the goal is still unclear, write a short spec first. See [Spec-driven feature workflow](./SPEC-DRIVEN-WORKFLOW.md).

More fixes: [Failure recovery](./FAILURE-RECOVERY.md).

## Checklist

Before you press Enter:
- [ ] One goal
- [ ] Files or errors named
- [ ] Limits stated
- [ ] A check the tool can run
- [ ] No secrets in the prompt

## Related docs

- [Prompt templates](./PROMPT-TEMPLATES.md)
- [Common best practices](./COMMON-BEST-PRACTICES.md)
- [Session management](./SESSION-MANAGEMENT.md)
- [Model selection by task](../tools/MODEL-SELECTION.md)
- [Plain-language skill](../skills/plain-language/SKILL.md) for rewriting a dense reply
- [Plan-only skill](../skills/plan-only/SKILL.md) for planning without code changes
