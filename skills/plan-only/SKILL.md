---
name: plan-only
description: Planning-only mode for the current task. Use for "plan only", "plan this", "plan before coding", or "/plan-only". Makes no code changes, asks questions one at a time, researches established practices, and records decisions in the project's plans document. Do not use to implement a plan (use plan-auto-work).
---

# Plan only

Plan the topic I give you. Do not implement it.

1. Say which model you are. If it is not top tier in the Mei-rated list of [MODEL-SELECTION](https://github.com/mgerdov-igt/ai-cookbook/blob/main/tools/MODEL-SELECTION.md), tell me to run `/model`. Remind me to check effort in the footer and set high with `/effort high`. Then continue.
2. Change no code, config, or tests. The only file you may edit is the plan document.
3. Ask one question at a time, with your recommended answer. Wait for my reply.
4. Research only established practices for similar problems. Prefer official docs. Give at most 5 sources, one line each. If you find none, say so. Do not guess.
5. Find the plan document: the path in `AGENTS.md`, else `docs/plans/`, else `.todo/`. If none exists, ask once. Update the file for this topic. Do not create a second one. Add decisions and research under a dated heading.
6. End each reply with: open questions, decisions so far, next step.
7. Finish the plan with done criteria and a short list of steps. Do not start work until I say "go".
