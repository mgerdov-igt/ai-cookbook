# jira-to-pr: quick start

Turns one Jira story or bug/TIR into one merged GitHub PR, cross-linked with the issue. The agent asks you questions and gets your plan approval before it writes any code. The steps are in [PROCEDURE.md](PROCEDURE.md); the Jira tool and its config are in [`jira-flow`](../jira-flow/README.md).

## One-time setup

1. Install both skills (and `github-pr-flow`): `bash skills/github-pr-flow/sync.sh --apply --global`, or copy the folders to `~/.copilot/skills/` or `~/.claude/skills/`.
2. Make sure the repo has:
   - `.jira-flow.json` at its root (create one with `jira.py init --project <P> --sample <your issue>`);
   - `.jira-flow/` in `.gitignore`;
   - your Jira personal access token in a gitignored notes file, as `ai-jira-token: <token>`, or in `JIRA_TOKEN`.
3. Check: `python3 tools/jira/jira.py whoami` (or the skill's own `scripts/jira.py`).
4. `"read_only": true` in `.jira-flow.json` lets you try the whole flow without changing Jira. Every Jira write becomes a dry run. Set it to `false` when the team agrees.

## Use

| Say | What happens |
|---|---|
| "list my Jira tickets" / "what TIRs do I have in PI 3?" | A list with severity and a one-line description per issue. You reply with a key ("run with POA-27666") and the flow starts on it. |
| "take the next Jira ticket" | The agent lists your pending replies, your in-flight issues and the top candidates, and you pick one. |
| "take the next Jira ticket for Terminal App VTA, Project Iteration 3" (also: "a TIR", "in development", "about printing") | The same, narrowed. Loose names are matched to the real project and fix version, and the agent tells you what it matched. |
| "implement VTA-123" / "fix TIR POA-456" | Digest, then questions, then plan, each with your approval. Then a background agent implements, opens the PR and merges it. |
| "any Jira replies?" | `pending`: your issues whose questions or plan got answers on Jira. |
| "resume VTA-123" | Continues from `.jira-flow/VTA-123/state.json`. |

What you see on Jira: the issue moves with the work. For a TIR: In Progress when the agent starts on it (via Assigned), Resolved once the fix and unit tests pass, Ready for Dev Integration when the PR is open and CI plus Copilot review run, Ready for QA Test when the PR merges. The mandatory resolution fields are drafted with the plan, so approving the plan approves them. Comments from you, each edited in place: Questions, Implementation plan, Ready for Dev Integration (PR, tests, then the CI and review outcome) and Ready for QA Test (merge, what changed, how to verify, evidence). A story uses one Status comment instead of the last two and moves only when every AC is met.

What you see on GitHub: one PR titled `<KEY>: <summary>`, whose body links the issue. For a story, the body has an AC-to-evidence table; for a defect, it has root cause, fix, regression test, log evidence and risk.

Your working folder and branch are never touched: implementation happens in a sibling worktree.
