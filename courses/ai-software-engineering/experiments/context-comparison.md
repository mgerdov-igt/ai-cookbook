# Lesson 2 — See What Context Changes

Use this short experiment to see whether useful project information changes an AI's answer. Use the feature from Lesson 1. Do not write code or add project files.

## Before you start

- Use the same AI tool and model for both attempts.
- Open two fresh conversations so the first attempt does not carry over into the second.
- Keep the task request the same. Only the approved project context changes.
- Use a sanitized practice project. Do not include private code or data.

If your AI tool cannot open a fresh conversation, use a separate temporary session or skip this comparison. Do not ask it to forget earlier messages; that does not reliably remove context.

## Attempt A — Task request only

In the first fresh conversation, send:

```text
I am exploring a small expression calculator. Draft a concise behavior
checklist for its first version. Separate stated requirements from
assumptions. Do not inspect files, ask questions, or write code.
```

Keep the answer for comparison. Do not correct its assumptions.

## Attempt B — Add the approved goal

In the second fresh conversation, send the same request with the approved goal as context:

```text
I am exploring a small expression calculator.
Read LESSON_1_SUMMARY.md and use its G1-approved goal and scope as the
source of truth. Draft a concise behavior checklist for its first version.
Separate approved requirements from assumptions and open questions.
Do not write code.
```

If your summary has a different filename, replace `LESSON_1_SUMMARY.md` with its path. Keep the course's Lesson 1 summary as the only added context for this comparison.

## Compare

Look at both checklists. Record short answers:

1. What did Attempt A guess, add, or leave unclear?
2. Which of those changed in Attempt B because the approved goal was available?
3. Did Attempt B still invent anything? What should remain an open question?
4. Where should the approved goal live so a new conversation can find it?

Do not measure which answer is "smarter" from tone or length. Check whether each answer follows the approved scope. The calculator's excluded multiplication and division are useful checks, not required guesses to provoke.

## Finish when

You can name one concrete difference the approved context made, or explain why this comparison did not show a difference. You know where the approved goal is recorded. Keep using the Lesson 1 summary; do not create another context document unless the project needs one.

Record the observation in your private course notes if useful. Saving the AI answers is optional. Do not put private project information in this cookbook.
