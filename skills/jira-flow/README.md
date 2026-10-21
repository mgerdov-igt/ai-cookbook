# jira-flow: setup and configuration

`scripts/jira.py` is a generic Jira Server/Data Center REST v2 client for agents and people. It uses only the Python 3.8+ standard library. `scripts/jira_text.py` holds the pure helpers (Markdown → wiki markup, log reduction, comment markers, transition choice), tested offline by `scripts/test_jira_text.py`.

## Install

- **Personal:** copy `skills/jira-flow` (and `skills/jira-to-pr`) to `~/.copilot/skills/` and/or `~/.claude/skills/`, or run `bash skills/github-pr-flow/sync.sh --apply --global`.
- **In a repo:** `sync.sh --apply --repo <path>` copies the scripts to `<path>/tools/jira/` when that folder or `<path>/.jira-flow.json` exists. The repo then carries its own copy and needs no personal install.
- **Token:** create a Jira personal access token (Profile → Personal Access Tokens). Put it in a gitignored notes file at the repo root (default `LOCAL-ENVIRONMENT.md`) as `ai-jira-token: <token>`, or export `JIRA_TOKEN`.
- **Repo files:** add `.jira-flow/` (the per-issue work folder) to `.gitignore`. Commit `.jira-flow.json`; it holds no secret.

## Set up a new project

```bash
python3 tools/jira/jira.py init --project VTA --sample VTA-123,VTA-456
```

`init` prints the issue types with their statuses, the ids of the common fields, and the transition screens of the sample issues (`*` marks a required field). Use samples that are **assigned to you**: a workflow often shows the developer screens (for example "Resolve") only to the assignee. Add `--out .jira-flow.json` to write a skeleton. Then edit three things per profile:

- `path`: the forward workflow, in order. The API lists statuses in no particular order.
- `status`: which status each event should reach.
- `never`: statuses the tool must never enter.

## .jira-flow.json

```json
{
  "url": "https://jira.example.com",
  "read_only": false,
  "work_dir": ".jira-flow",
  "token": {"file": "LOCAL-ENVIRONMENT.md", "labels": ["ai-jira-token", "jira-token"]},
  "queries": {
    "mine": "project = ABC AND issuetype = Story",
    "pi": "project = ABC AND issuetype = Story AND fixVersion = \"{pi}\""
  },
  "profiles": {
    "story": {
      "issue_types": ["Story"],
      "fields": {"ac": "Acceptance Criteria", "points": "Story Points", "epic": "Epic Link"},
      "path": ["Opened", "Assigned", "In Development", "In Test", "Done"],
      "status": {"plan_approved": "In Development", "pr_opened": "In Development", "merged": "In Test"},
      "never": ["Done", "Descoped"]
    },
    "defect": {
      "issue_types": ["Bug", "re:^TIR\\b"],
      "fields": {"severity": "Severity", "found_in": "Found-In Batch"},
      "path": ["Opened", "Reopened", "Assigned", "In Progress", "Resolved", "Ready for QA Test"],
      "required_fields": {"Resolved": ["Resolution Description", "Repair Code", "Fix Version/s"]},
      "status": {"plan_approved": "In Progress", "pr_opened": "In Progress", "merged": "Ready for QA Test"},
      "never": ["Closed*", "Defer*"]
    }
  }
}
```

| Key | Meaning |
|---|---|
| `url` | Jira base URL (`JIRA_URL` overrides). |
| `read_only` | `true`: `--yes` is ignored and any non-GET request is refused. Good for a first trial. `JIRA_FLOW_READ_ONLY=1` does the same per shell. |
| `work_dir` | Per-issue cache under the repo root: `digest.md`, `attachments/`, `seen.json`, plus the `jira-to-pr` state and drafts. Gitignore it. |
| `token` | Notes file and labels searched for the token (`label: value` on one line, or the label line followed by the value). |
| `queries.mine` / `queries.pi` | JQL behind `mine` and `pi`; `{pi}` is replaced by the fix-version argument. |
| `profiles` | The first profile whose `issue_types` matches wins (exact name, case-insensitive, or `re:<regex>`). List the narrower profile first, for example `TIR - Developer` before `re:^TIR`. |
| `profiles.*.fields` | Label → Jira field **name** (or id). `digest` shows these fields; `ac` is the acceptance-criteria field; `epic` and `points` are optional. |
| `profiles.*.path` | Forward status order that `walk` may move along. Statuses not on the path are never entered by `walk`. |
| `profiles.*.status` | Event → target status: `plan_approved`, `pr_opened`, `merged`. Leave an event out to skip it. |
| `profiles.*.never` | Statuses or transition names never taken automatically; `*` and `?` wildcards. Walking from a `never` status is a no-op (the issue is final). |
| `profiles.*.required_fields` | Optional. `{status: [field names]}` that your team treats as mandatory when entering that status, even if Jira's screen does not. `walk` checks the whole route before its first write; empty or `"?"` values count as missing. A listed field that is not on the transition screen is set by an issue edit right after that step. |

Transition screens are filled from `walk --fields-file f.json`, a flat object keyed by field name or id: `{"Resolution Description": "...", "Repair Code": "Code", "Fix Version/s": "2.1.18"}`. Values are converted to the shape the field needs: option, user, version, resolution, number or array. A missing required field stops the walk and names the field.

## Comment markers

`upsert-comment --marker <name>` appends a small grey footer (`jiraflow:<name>` and the UTC update time) to a comment posted under your token. Later calls edit that same comment instead of adding a new one. `replies` and `pending` use the markers to find human answers posted after the bot's comment. Only your own marked comments count; other people's comments are never edited.

## Test

```bash
python3 -m unittest discover -s skills/jira-flow/scripts -p "test_*.py"
```
