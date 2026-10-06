# GitHub Copilot CLI Cost and Token Control

## Use the right mode first

- Use plan mode before large edits.
- Use `/fleet` only when work is truly parallelizable.

## Watch session usage

- Use `/usage` to inspect spend and model usage.
- Use `/context` to check context-window pressure.
- Use `/compact` before quality drops in long sessions.

## Keep prompts scoped

- One task per prompt.
- Attach only the files needed.
- Ask for short diffs and short summaries.

## Prefer cheaper models for routine loops

- Use stronger reasoning models for planning or hard diagnosis.
- Use code-focused or balanced models for implementation and verification loops.
