---
name: plain-language
description: Restate a dense, jargon-heavy AI reply in plain words, using Simplified Technical English (ASD-STE100) rules. Facts, paths, commands, and numbers stay exact. Use for "plain-language", "/bro", "wait what", "explain that simply", "I did not follow that", "say that in plain English", or "ELI5 your last answer".
---

# Plain Language

Say the last reply again in plain words. Do not add new facts. Do not drop facts that matter.

## When to use

Use this skill when the user asks things like:
- "Explain that simply"
- "I did not follow that"
- "Wait, what?"
- "Plain English please"

## When not to use

Do not use when:
- The user wants more detail or a deeper technical answer.
- The user asks for a new answer, not a rewrite of the last one.

## Input

- No input: rewrite your last reply.
- Optional: a message, file, or text the user pastes. Rewrite that instead.

## Rules

Write in the style of ASD-STE100 Simplified Technical English:

1. Use common words. Replace a big word with a small one. If a technical term must stay, explain it in one short phrase right after.
2. Use active voice. Say who does what.
3. Write one idea or one instruction per sentence. Keep sentences short.
4. Keep paragraphs short. Use a numbered list for steps.
5. Do not use metaphors, idioms, or filler.

Keep these exact, never reworded:
- File paths, commands, code, and product names
- Numbers, versions, dates, and limits
- Warnings that change what the user should do

## Output Format

Use this order. Skip a part that does not apply.

1. **What happened:** one or two sentences.
2. **Did it work:** yes, no, or partly, and why in one sentence.
3. **What to do now:** numbered steps.
4. **Decision needed:** at most two options, the context to choose fast, and which one you recommend.

Put the one note that matters most first. Remove side notes the user cannot act on. If you removed a caveat that might matter, say so in one line and offer to show it.

## Safety Rules

- Do not invent facts or hide a failure to sound simple. If something failed, say it failed.
- Do not change the meaning. When you are unsure that a simpler word keeps the meaning, keep the original word and explain it.
- Do not change files. This skill only rewrites text.

## Verification

Check the rewrite before you send it:
- Every path, command, and number matches the original.
- The user can act on it without a glossary.
- No sentence holds more than one idea.

## Make it the default

To get this voice in every reply, put one line in your tool's always-on instructions, such as `CLAUDE.md`, `AGENTS.md`, or `.github/copilot-instructions.md`:

```text
Write replies in ASD-STE100 Simplified Technical English: common words, active voice, one idea per sentence. Keep paths, commands, and numbers exact.
```

Use the skill when you only need it for one reply that lost you. Use the line when you want it always on.

## Sources

- [ASD-STE100 on Wikipedia](https://en.wikipedia.org/wiki/Simplified_Technical_English)
- Claude Code [output styles](https://code.claude.com/docs/en/output-styles), a session-wide alternative
