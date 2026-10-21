---
name: jira-flow
description: Read and update Jira Server/Data Center issues from an agent with a generic, config-driven, stdlib-only CLI (jira.py). Compact issue digests (fields, links, comments, attachments with big logs reduced), status walks along a configured workflow path with required screen fields, edited-in-place bot comments, PR remote links, and a pending-replies inbox. Writes are dry runs unless --yes. Use for "read this Jira", "what's in VTA-123", "move it to In Development", "comment on the ticket", "which of my issues got answers".
---

# jira-flow

One script, `jira.py` (Python 3.8+, standard library only), plus `jira_text.py` (pure helpers). Everything project-specific lives in the repo's `.jira-flow.json`.

**Script location:** `<repo>/tools/jira/jira.py` if the repo carries a synced copy, else `~/.copilot/skills/jira-flow/scripts/jira.py` (or `~/.claude/...`). Run it from the repo root, so it finds `.jira-flow.json` and the token file. `python3 jira.py` with no arguments prints the full usage.

## Rules

1. **Writes are dry runs.** Run every write once without `--yes`, read the `PLAN` lines, then repeat with `--yes` only if the user asked for that change. `"read_only": true` in the config (or `JIRA_FLOW_READ_ONLY=1`) disables writes entirely.
2. **Ownership.** Writes skip issues assigned to someone else (`SKIP`). Use `--force-owner` only when the user says so.
3. **Never statuses.** A profile's `never` list (wildcards allowed, for example `Closed*`) is refused by `walk` and by `transition` unless `--allow-never` is given with the user's explicit OK.
4. **Token.** From `JIRA_TOKEN`, or the gitignored notes file named in the config (`ai-jira-token: <value>`). Never print it, never paste it into a command line or a comment.
5. **Text is wiki markup.** Jira Server renders wiki markup, not Markdown. `comment --md`, `upsert-comment` and `md2wiki` convert. Avoid emoji: Jira Server on MySQL utf8 may reject 4-byte characters.

## Token-saving habits

- Start with `digest KEY`: it writes `.jira-flow/KEY/digest.md` once (fields by profile, links, comments, attachments). Read that file; do not call `show --full`, `comments` and `transitions` separately.
- Logs are never read whole. `digest` writes `<log>.reduced.txt`: line count, time span, level counts, first/last lines, every distinct error/warning block with context and stack-trace tail, deduplicated with repeat counts. If the issue gives a time window ("between 00:10 and 00:20"), pass `--window 00:10-00:20`. Grep the full file only for something specific.
- xlsx → csv preview, zip → listing with reduced text members, pdf → text (with `pdftotext`), video → frames (with `ffmpeg`), images: view them.
- Re-running `digest` marks only new comments and attachments as `NEW`, so a resumed run reads the delta.
- `brief`, `mine`, `pi` and `search` print one line per issue.

If attachment downloads come back as a login page (SSO or 2FA plugins block token downloads), `digest` says `NOT DOWNLOADED` and names the file. Ask the user to save it into `.jira-flow/KEY/attachments/` from the browser and re-run `digest`; it picks the file up by name and size.

## Common commands

| Need | Command |
|---|---|
| Who am I, which config | `whoami` |
| Everything about one issue, cached | `digest KEY [--window HH:MM-HH:MM]` |
| My open work | `mine [--project P] [--pi V] [--type T] [--status S] [--text W] [--jql J] [--max N]`: loose names allowed ("Terminal App", "PI 3"); it prints what they matched |
| Move forward along the workflow | `walk KEY --event plan_approved\|pr_opened\|merged` or `--to "<status>"`; screen fields from `--fields-file f.json` |
| See what a transition requires | `transitions KEY --fields` (`*` = required) |
| One edited-in-place bot comment | `upsert-comment KEY --marker questions\|plan\|status --title T --file f.md` |
| Human answers to it | `replies KEY --marker questions` (prints `APPROVED` for a plan approval) |
| My issues with new answers | `pending` |
| Link a PR | `remotelink KEY --url <PR url> --title "PR #n" [--resolved]` |
| New project setup | `init --project P --sample KEY --out .jira-flow.json` |

`walk` moves one step at a time toward the target along the profile's `path`, never backward, never past the target, never into a `never` status. It stops and names any required screen field missing from `--fields-file` (keys are field names or ids). Run `walk` once without `--yes` to see the first step. It is a no-op when the issue is already at or past the target.

Configuration schema and setup: [README.md](README.md). End-to-end issue-to-merged-PR automation: the `jira-to-pr` skill.
