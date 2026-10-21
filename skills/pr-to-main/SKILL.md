---
name: pr-to-main
description: Ship every pending change in the current repo as a PR to main, fully autonomously, in the background — without ever touching the current working folder or branch. Snapshots the current commits (and any uncommitted changes) into a separate worktree on its own branch, does all push/PR/merge-readiness/merge work there, and finally folds the merged main back into the current folder's current branch — so the user can keep committing on the same branch in the same folder the whole time. Invoke on "PR to main", "ship this", "open a PR and merge it", "land pending changes".
disable-model-invocation: false
---

# PR to main

Global skill, works in any git repo. It lands everything pending (uncommitted, or committed-but-unpushed) on `main` through a real PR, **copying** the work into a separate worktree; the user's folder and branch are never reset, switched or stashed, and stay usable from the first second.

## What to do when invoked

Do not do the work inline. Spawn **one background general-purpose agent** and return immediately:

- Copilot CLI: `task` tool, `agent_type: general-purpose`, `mode: background`.
- Claude Code: `Agent` tool, `subagent_type: general-purpose`, run in background.

Use this prompt, with `<REPO_ROOT>` (the current repo root) and any scope hint from the user filled in. **Do not paste the procedure into the prompt**; the agent reads it itself:

```
Ship the pending changes of <REPO_ROOT> to its default branch as a reviewed, merged PR, autonomously.
Read and follow, in full, the procedure file `PROCEDURE.md` that sits next to this skill's SKILL.md
(~/.copilot/skills/pr-to-main/PROCEDURE.md, or ~/.claude/skills/pr-to-main/PROCEDURE.md).
Scope: <everything pending | the user's scope hint>.
```

Then tell the user in one or two sentences: the run has started, the result arrives as a background-agent completion notification, and their current folder and branch are untouched and safe to use right now. Do not wait on it.
