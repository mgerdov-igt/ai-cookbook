#!/usr/bin/env python3
"""Generic Jira client for agents (Jira Server/DC REST v2). Python 3.8+, standard library only.

    python3 jira.py <command> [args] [--yes]

Repo settings live in `.jira-flow.json` (found from the current directory upward, or
JIRA_FLOW_CONFIG): Jira URL, issue-type profiles (fields, status path, event -> status,
never-take statuses) and saved queries. See the skill README for the schema.

Read commands (always safe):
    whoami
    search "<jql>" [--max 200]              one line per issue
    show <KEY> [--full]                     summary, status, owner, AC (+ description)
    brief <KEY...>                          status, owner, one line per AC heading
    mine [--pi "<fix version>"] [--all]     open issues you may work on (config queries.mine)
    pi "<fix version>"                      status counts and owners (config queries.pi)
    transitions <KEY> [--fields]            moves available now (+ screen fields, * = required)
    comments <KEY>
    fields [--grep text]                    field ids and names
    digest <KEY> [--window HH:MM-HH:MM] [--no-attachments] [--out DIR]
                                            one compact markdown file for an agent: fields by
                                            profile, links, comments (NEW marked), attachments
                                            downloaded and reduced (logs, xlsx, zip, pdf, video)
    replies <KEY> [--marker questions|plan] human replies after the bot's marked comment;
                                            prints APPROVED for an approval of the plan
    pending [--jql "<jql>"]                 your issues whose questions/plan got replies
    init --project <P> [--sample KEY...] [--out .jira-flow.json] [--force]
                                            discover issue types, statuses, field ids and
                                            transition screens; write a config skeleton
Offline helpers (no Jira call):
    md2wiki [FILE]                          Markdown -> Jira wiki markup (stdin by default)
    reduce-log FILE [--window HH:MM-HH:MM] [--max-lines 200]
Write commands (print a plan and change NOTHING unless --yes is given):
    assign <KEY...> [--to USER]             default: the token's owner; --to none unassigns
    comment <KEY...> (--text "..." | --file F) [--md]
    upsert-comment <KEY> --marker NAME (--text "..." | --file F) [--title T] [--raw]
                                            edit your comment carrying the marker, else add it;
                                            Markdown is converted unless --raw
    remotelink <KEY> --url URL --title T [--resolved]   idempotent (globalId = URL)
    transition <KEY...> --to "<transition name|id>" [--allow-never]
    walk <KEY...> [--to "<status>" | --event plan_approved|pr_opened|merged] [--fields-file F.json]
                                            forward along the profile's path; fills screen
                                            fields from F.json ({"Field name": value}); stops
                                            on a missing required field; never takes a
                                            `never` status; no-op when already there or past
    set <KEY...> --field <id|name> --value V
    bulk --jql "<jql>" --do assign|comment|transition|walk|set [that command's flags]

Safety: every write skips an issue assigned to someone else and prints SKIP. Pass
--force-owner only when the user has said so. Unassigned issues and your own are allowed.
Read-only mode (config "read_only": true, or JIRA_FLOW_READ_ONLY=1) ignores --yes and
refuses any non-GET request.

Auth: JIRA_TOKEN env var, else a notes file (config token.file, default
LOCAL-ENVIRONMENT.md in the cwd or repo root) holding `ai-jira-token: <value>` (labels
configurable). Base URL: JIRA_URL, else config `url`. The token is never printed.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from glob import escape as glob_escape
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import jira_text as jt  # noqa: E402

BOOL_FLAGS = {"yes", "full", "all", "force-owner", "fields", "md", "raw", "resolved", "no-attachments",
              "force", "allow-never"}
DEFAULT_PROFILES = {
    "story": {"issue_types": ["Story", "Enabler Story", "User Story"], "fields": {"ac": "Acceptance Criteria"}},
    "defect": {"issue_types": ["Bug", "Defect", "Defects", "re:^TIR\\b"], "fields": {}},
}
VIDEO_EXT = {"mp4", "mov", "avi", "webm", "mkv", "wmv"}
IMAGE_EXT = {"png", "jpg", "jpeg", "gif", "bmp", "webp"}
MAX_DOWNLOAD = 100 * 1024 * 1024

for _s in (sys.stdout, sys.stderr):
    try:
        _s.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass


def die(msg):
    print("error: " + msg, file=sys.stderr)
    sys.exit(1)


# --------------------------------------------------------------------------------------
# Config, paths, token
# --------------------------------------------------------------------------------------
def git_root(start=None):
    d = Path(start or Path.cwd()).resolve()
    for p in [d] + list(d.parents):
        if (p / ".git").exists():
            return p
    return None


def load_config():
    env = os.environ.get("JIRA_FLOW_CONFIG")
    if env:
        p = Path(env)
        return (json.loads(p.read_text(encoding="utf-8")), p) if p.exists() else die("JIRA_FLOW_CONFIG not found: " + env)
    d = Path.cwd().resolve()
    stop = git_root(d)
    for p in [d] + list(d.parents):
        f = p / ".jira-flow.json"
        if f.exists():
            return json.loads(f.read_text(encoding="utf-8")), f
        if stop and p == stop:
            break
    return {}, None


CFG, CFG_PATH = load_config()
BASE = (os.environ.get("JIRA_URL") or CFG.get("url") or "").rstrip("/")
API = BASE + "/rest/api/2"
READ_ONLY = ("JIRA_FLOW_READ_ONLY" if os.environ.get("JIRA_FLOW_READ_ONLY", "") not in ("", "0")
             else "config read_only" if CFG.get("read_only") else "")


def token():
    t = os.environ.get("JIRA_TOKEN", "").strip()
    if t:
        return t
    tc = CFG.get("token") or {}
    name = tc.get("file", "LOCAL-ENVIRONMENT.md")
    dirs = [Path.cwd(), git_root(), CFG_PATH.parent if CFG_PATH else None, Path(__file__).resolve().parent.parent.parent]
    for d in dirs:
        if not d:
            continue
        f = Path(name) if Path(name).is_absolute() else Path(d) / name
        if f.exists():
            v = jt.token_from_text(f.read_text(encoding="utf-8", errors="replace"), tc.get("labels"))
            if v:
                return v
    die("No Jira token. Set JIRA_TOKEN, or put `ai-jira-token: <token>` in %s (gitignored)." % name)


def work_dir():
    root = git_root() or Path.cwd()
    return root / CFG.get("work_dir", ".jira-flow")


# --------------------------------------------------------------------------------------
# REST client
# --------------------------------------------------------------------------------------
class Jira:
    def __init__(self, tok):
        if not BASE:
            die("No Jira URL. Set JIRA_URL or `url` in .jira-flow.json.")
        self.tok = tok
        self._fields = None

    def _open(self, url, method="GET", data=None, accept="application/json"):
        if READ_ONLY and method != "GET":
            die("read-only mode (%s): refusing %s %s" % (READ_ONLY, method, url))
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", "Bearer " + self.tok)
        req.add_header("Accept", accept)
        if data is not None:
            req.add_header("Content-Type", "application/json")
        return urllib.request.urlopen(req, timeout=120)

    def call(self, method, path, body=None):
        data = json.dumps(body).encode() if body is not None else None
        try:
            with self._open(API + path, method, data) as r:
                text = r.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            die("%s %s -> HTTP %s %s" % (method, path, e.code, e.read().decode("utf-8", "replace")[:400]))
        except urllib.error.URLError as e:
            die("%s %s -> %s" % (method, path, e.reason))
        return json.loads(text) if text else None

    def raw(self, url):
        """(bytes, final_url, content_type). Callers must check the result: SSO/2FA plugins answer
        a token-authenticated download with a redirect to an HTML login page."""
        try:
            with self._open(url, accept="*/*") as r:
                return r.read(), r.geturl(), r.headers.get("Content-Type", "")
        except urllib.error.HTTPError as e:
            die("GET %s -> HTTP %s" % (url, e.code))

    def search(self, jql, fields, limit=None):
        """All matching issues, paged. `limit` caps the total."""
        out, start = [], 0
        while True:
            q = urllib.parse.urlencode({"jql": jql, "fields": fields, "maxResults": 100, "startAt": start})
            r = self.call("GET", "/search?" + q)
            out.extend(r["issues"])
            start += len(r["issues"])
            if not r["issues"] or start >= r["total"] or (limit and len(out) >= limit):
                return out[:limit] if limit else out, r["total"]

    def fields(self):
        if self._fields is None:
            self._fields = self.call("GET", "/field")
        return self._fields

    def fid(self, name_or_id):
        """Field id for a field name or id (ids pass through)."""
        if not name_or_id:
            return None
        for f in self.fields():
            if f["id"] == name_or_id:
                return f["id"]
        hits = [f["id"] for f in self.fields() if f["name"].lower() == name_or_id.lower()]
        return hits[0] if hits else None


# --------------------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------------------
def parse(argv):
    flags, pos, i = {}, [], 0
    while i < len(argv):
        a = argv[i]
        if a.startswith("--"):
            name = a[2:]
            if name in BOOL_FLAGS:
                flags[name] = True
            else:
                i += 1
                flags[name] = argv[i] if i < len(argv) else die("--%s needs a value" % name)
        else:
            pos.append(a)
        i += 1
    return flags, pos


def render(v):
    if v is None:
        return ""
    if isinstance(v, dict):
        return str(v.get("value") or v.get("name") or v.get("displayName") or v.get("key") or "")
    if isinstance(v, list):
        return ", ".join(x for x in (render(i) for i in v) if x)
    s = str(v)
    m = re.search(r"greenhopper\.service\.sprint\.Sprint@.*?name=([^,\]]+).*?state=([^,\]]+)", s)
    if m:
        return "%s (%s)" % (m.group(1), m.group(2))
    return s.replace("\r", "")


def read_text_arg(flags):
    if flags.get("file"):
        return Path(flags["file"]).read_text(encoding="utf-8")
    if "text" in flags:
        return flags["text"]
    die('Give --text "..." or --file F.')


class Tool:
    def __init__(self, jira, flags, pos):
        self.j, self.f, self.pos = jira, flags, pos
        self.yes = bool(flags.get("yes")) and not READ_ONLY
        if flags.get("yes") and READ_ONLY:
            print("read-only mode (%s): --yes ignored, nothing will change" % READ_ONLY)
        self._me = None
        self.profiles = CFG.get("profiles") or DEFAULT_PROFILES

    # -- helpers ---------------------------------------------------------------------
    def me(self):
        if self._me is None:
            self._me = self.j.call("GET", "/myself")["name"]
        return self._me

    def plan(self, line):
        print(("DO   " if self.yes else "PLAN ") + line)

    def may_write(self, key):
        """Writes are limited to unassigned issues and the token owner's own."""
        if self.f.get("force-owner"):
            return True
        a = (self.j.call("GET", "/issue/%s?fields=assignee" % key)["fields"].get("assignee") or {}).get("name")
        if not a or a == self.me():
            return True
        print("SKIP %s: assigned to %s, not you (use --force-owner only if the user said so)" % (key, a))
        return False

    def profile(self, issue_type):
        return jt.profile_for(issue_type, self.profiles)

    def ac_field(self):
        for p in self.profiles.values():
            ac = (p.get("fields") or {}).get("ac")
            if ac:
                return self.j.fid(ac)
        return None

    def keys(self):
        if self.f.get("jql"):
            # Collect every key first: a write can move issues out of the JQL result.
            issues, _ = self.j.search(self.f["jql"], "key")
            return [i["key"] for i in issues]
        return self.pos or die("Give at least one issue key (or --jql with bulk).")

    def comments(self, k):
        return self.j.call("GET", "/issue/%s/comment?maxResults=1000" % k)["comments"]

    # -- write actions -----------------------------------------------------------------
    def do_assign(self, k):
        if not self.may_write(k):
            return
        to = self.f.get("to") or self.me()
        self.plan("%s: assignee -> %s" % (k, to))
        if self.yes:
            self.j.call("PUT", "/issue/%s/assignee" % k, {"name": None if to == "none" else to})

    def do_comment(self, k):
        if not self.may_write(k):
            return
        text = read_text_arg(self.f)
        if self.f.get("md"):
            text = jt.md_to_wiki(text)
        self.plan("%s: comment (%d chars)" % (k, len(text)))
        if self.yes:
            self.j.call("POST", "/issue/%s/comment" % k, {"body": text})

    def do_transition(self, k):
        if not self.may_write(k):
            return
        want = self.f.get("to") or die("--to is required.")
        iss = self.j.call("GET", "/issue/%s?fields=issuetype" % k)
        _, prof = self.profile(iss["fields"]["issuetype"]["name"])
        ts = self.j.call("GET", "/issue/%s/transitions" % k)["transitions"]
        t = next((x for x in ts if x["id"] == want or x["name"].lower() == want.lower()), None)
        if not t:
            die("%s: no transition %r. Available: %s" % (k, want, ", ".join(x["name"] for x in ts)))
        never = prof.get("never", [])
        if (jt.is_banned(t["name"], never) or jt.is_banned(t["to"]["name"], never)) and not self.f.get("allow-never"):
            die("%s: %r -> %r is on this profile's never list. Only with the user's explicit OK: --allow-never"
                % (k, t["name"], t["to"]["name"]))
        self.plan("%s: %s -> %s" % (k, t["name"], t["to"]["name"]))
        if self.yes:
            self.j.call("POST", "/issue/%s/transitions" % k, {"transition": {"id": t["id"]}})

    def do_walk(self, k):
        if not self.may_write(k):
            return
        iss = self.j.call("GET", "/issue/%s?fields=status,issuetype" % k)["fields"]
        pname, prof = self.profile(iss["issuetype"]["name"])
        path = prof.get("path") or die("%s: profile %r has no `path` in .jira-flow.json." % (k, pname))
        event = self.f.get("event")
        target = self.f.get("to") or (prof.get("status") or {}).get(event or "merged")
        if not target:
            print("%s: profile %r maps no status to event %r; nothing to do" % (k, pname, event or "merged"))
            return
        provided = json.loads(Path(self.f["fields-file"]).read_text(encoding="utf-8")) if self.f.get("fields-file") else {}
        cur = iss["status"]["name"]
        if jt.is_banned(cur, prof.get("never", [])):
            print('%s: "%s" is a final status for this profile; nothing to do' % (k, cur))
            return
        for _ in range(len(path) + 2):
            ts = self.j.call("GET", "/issue/%s/transitions?expand=transitions.fields" % k)["transitions"]
            t, why = jt.choose_transition(ts, path, cur, target, prof.get("never", []))
            if t is None:
                if why == "already there" or why.startswith("already past"):
                    print('%s: "%s" (%s)' % (k, cur, why))
                    return
                die('%s: stuck in "%s": %s' % (k, cur, why))
            miss = jt.missing_required(t, provided)
            self.plan('%s: %s --[%s]--> %s' % (k, cur, t["name"], t["to"]["name"]))
            if miss:
                print("     needs: %s  (pass them in --fields-file)" % ", ".join(miss))
                return
            body = {"transition": {"id": t["id"]}}
            vals = {}
            for fid, meta in (t.get("fields") or {}).items():
                for key, v in provided.items():
                    if key.lower() in (fid.lower(), (meta.get("name") or "").lower()):
                        vals[fid] = jt.coerce(meta, v)
            if vals:
                body["fields"] = vals
                for fid, v in vals.items():
                    print("     set %s = %s" % (t["fields"][fid].get("name", fid), json.dumps(v)[:120]))
            if not self.yes:
                if _norm_eq(t["to"]["name"], target):
                    return
                print('     ... then more steps toward "%s" (a dry run can only preview the first step)' % target)
                return
            self.j.call("POST", "/issue/%s/transitions" % k, body)
            cur = t["to"]["name"]
        print('%s: now "%s"' % (k, cur))

    def do_set(self, k):
        if not self.may_write(k):
            return
        field = self.f.get("field") or die("--field and --value are required.")
        fid = self.j.fid(field) or die("unknown field %r" % field)
        raw = self.f.get("value") if "value" in self.f else die("--field and --value are required.")
        val = float(raw) if re.fullmatch(r"-?\d+\.\d+", raw) else int(raw) if re.fullmatch(r"-?\d+", raw) else raw
        self.plan("%s: %s = %s" % (k, fid, json.dumps(val)))
        if self.yes:
            self.j.call("PUT", "/issue/" + k, {"fields": {fid: val}})

    ACTIONS = ("assign", "comment", "transition", "walk", "set")

    def cmd_upsert_comment(self):
        k = self.pos[0] if self.pos else die("Give an issue key.")
        name = self.f.get("marker") or die("--marker is required.")
        if not re.fullmatch(r"[a-z][a-z0-9-]*", name):
            die("--marker must be lowercase letters, digits, dashes")
        if not self.may_write(k):
            return
        text = read_text_arg(self.f)
        body = text if self.f.get("raw") else jt.md_to_wiki(text)
        stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
        head = "h4. [jira-to-pr] %s\n" % self.f["title"] if self.f.get("title") else ""
        body = "%s%s\n\n%s  {color:#97a0af}%s{color}" % (head, body.strip(), jt.marker_footer(name), stamp)
        old = jt.find_marked(self.comments(k), name, self.me())
        if old:
            self.plan("%s: edit comment %s [%s] (%d chars)" % (k, old["id"], name, len(body)))
            if self.yes:
                self.j.call("PUT", "/issue/%s/comment/%s" % (k, old["id"]), {"body": body})
        else:
            self.plan("%s: add comment [%s] (%d chars)" % (k, name, len(body)))
            if self.yes:
                self.j.call("POST", "/issue/%s/comment" % k, {"body": body})
        if not self.yes:
            print("\n(dry run - add --yes to apply)")

    def cmd_remotelink(self):
        k = self.pos[0] if self.pos else die("Give an issue key.")
        url = self.f.get("url") or die("--url is required.")
        title = self.f.get("title") or url
        if not self.may_write(k):
            return
        obj = {"url": url, "title": title,
               "icon": {"url16x16": "https://github.com/favicon.ico", "title": "GitHub"},
               "status": {"resolved": bool(self.f.get("resolved"))}}
        self.plan("%s: remote link %s -> %s%s" % (k, title, url, " (resolved)" if self.f.get("resolved") else ""))
        if self.yes:
            self.j.call("POST", "/issue/%s/remotelink" % k, {"globalId": url, "object": obj})
        else:
            print("\n(dry run - add --yes to apply)")

    # -- read commands -----------------------------------------------------------------
    def cmd_whoami(self):
        me = self.j.call("GET", "/myself")
        print("%s (%s)  %s  config: %s" % (me["name"], me["displayName"], BASE, CFG_PATH or "none"))

    def cmd_search(self):
        jql = self.pos[0] if self.pos else die("Give a JQL string.")
        issues, total = self.j.search(jql, "summary,status,assignee,issuetype", int(self.f.get("max", 200)))
        for i in issues:
            f = i["fields"]
            print(" | ".join([i["key"], f["issuetype"]["name"], f["status"]["name"],
                              (f.get("assignee") or {}).get("name", "-"), f["summary"]]))
        print("-- %d of %d" % (len(issues), total))

    def cmd_show(self):
        k = self.pos[0] if self.pos else die("Give an issue key.")
        ac = self.ac_field()
        pts = self.j.fid((self.profiles.get("story", {}).get("fields") or {}).get("points") or "Story Points")
        want = ["summary", "status", "assignee", "fixVersions", "issuetype", "description"] + [x for x in (ac, pts) if x]
        f = self.j.call("GET", "/issue/%s?fields=%s" % (k, ",".join(want)))["fields"]
        print("%s: %s\n%s   status: %s   assignee: %s   points: %s" % (
            k, f["summary"], f["issuetype"]["name"], f["status"]["name"],
            (f.get("assignee") or {}).get("name", "-"), f.get(pts) if pts and f.get(pts) is not None else "-"))
        print("fixVersions: " + (", ".join(v["name"] for v in f["fixVersions"]) or "-"))
        if ac and f.get(ac):
            print("\nAcceptance Criteria:\n" + f[ac].replace("\r", ""))
        if self.f.get("full") or not (ac and f.get(ac)):
            print("\nDescription:\n" + (f.get("description") or "(none)").replace("\r", ""))

    def cmd_brief(self):
        ac_id = self.ac_field()
        for k in self.pos or die("Give issue keys."):
            f = self.j.call("GET", "/issue/%s?fields=summary,status,assignee,%s" % (k, ac_id or "description"))["fields"]
            print("%s | %s | %s | %s" % (k, f["status"]["name"], (f.get("assignee") or {}).get("name", "-"), f["summary"]))
            ac = (f.get(ac_id or "description") or "").replace("\r", "")
            heads = [m.group(1).strip() for m in re.finditer(r"(?:h3\.\s*)?(AC\s?\d+[:.]?[^\n]*)", ac, re.I)]
            for h in heads:
                print("   " + h[:110])
            if not heads:
                print("   " + next((l for l in ac.split("\n") if l.strip()), "(no AC)")[:110])

    def _query(self, name):
        q = (CFG.get("queries") or {}).get(name)
        return q or die("Set queries.%s in .jira-flow.json." % name)

    def cmd_mine(self):
        jql = self._query("mine")
        if self.f.get("pi"):
            jql += ' AND fixVersion = "%s"' % self.f["pi"]
        if not self.f.get("all"):
            jql += " AND (assignee is EMPTY OR assignee = currentUser())"
        jql += " AND statusCategory != Done ORDER BY key"
        issues, _ = self.j.search(jql, "summary,status,assignee")
        for i in issues:
            f = i["fields"]
            print(" | ".join([i["key"], f["status"]["name"], (f.get("assignee") or {}).get("name", "-"), f["summary"]]))
        print("-- %d open issues%s" % (len(issues), "" if self.f.get("all") else " (unassigned or yours)"))

    def cmd_pi(self):
        pi = self.pos[0] if self.pos else die('Give a fix version name, e.g. "Product Increment 2".')
        issues, _ = self.j.search(self._query("pi").replace("{pi}", pi) + " ORDER BY key", "summary,status,assignee")
        counts = {}
        for i in issues:
            n = i["fields"]["status"]["name"]
            counts[n] = counts.get(n, 0) + 1
        print("   ".join("%s: %d" % kv for kv in counts.items()))
        for i in issues:
            f = i["fields"]
            print(" | ".join([i["key"], f["status"]["name"], (f.get("assignee") or {}).get("name", "-"), f["summary"][:60]]))

    def cmd_transitions(self):
        k = self.pos[0] if self.pos else die("Give an issue key.")
        exp = "?expand=transitions.fields" if self.f.get("fields") else ""
        for t in self.j.call("GET", "/issue/%s/transitions%s" % (k, exp))["transitions"]:
            line = "%s\t%s\t-> %s" % (t["id"], t["name"], t["to"]["name"])
            if self.f.get("fields"):
                fl = ["%s%s" % (v.get("name", fid), "*" if v.get("required") else "") for fid, v in (t.get("fields") or {}).items()]
                line += "\t[" + "; ".join(fl) + "]"
            print(line)

    def cmd_comments(self):
        k = self.pos[0] if self.pos else die("Give an issue key.")
        for c in self.comments(k):
            print("[%s] %s: %s\n" % (c["created"][:10], c["author"]["name"], c["body"]))

    def cmd_fields(self):
        g = (self.f.get("grep") or "").lower()
        for f in sorted(self.j.fields(), key=lambda x: x["name"].lower()):
            if g in f["name"].lower() or g in f["id"].lower():
                print("%-22s %s" % (f["id"], f["name"]))

    def cmd_replies(self):
        k = self.pos[0] if self.pos else die("Give an issue key.")
        name = self.f.get("marker", "questions")
        cs = self.comments(k)
        mc = jt.find_marked(cs, name, self.me())
        if not mc:
            print("%s: no [%s] comment of yours" % (k, name))
            return
        since = "updated" if name == "plan" else "created"
        reps = jt.replies_after(cs, mc, self.me(), since)
        for c in reps:
            print("[%s] %s:\n%s\n" % (c["created"][:16], c["author"]["name"], c["body"].replace("\r", "")))
            if name == "plan" and jt.APPROVAL_RE.match(c["body"] or ""):
                print("APPROVED by %s at %s" % (c["author"]["name"], c["created"][:16]))
        print("-- %d replies after [%s] (%s %s)" % (len(reps), name, since, mc.get(since, "")[:16]))

    def cmd_pending(self):
        jql = self.f.get("jql") or "assignee = currentUser() AND statusCategory != Done AND updated >= -90d"
        issues, _ = self.j.search(jql + " ORDER BY updated DESC", "summary,status", 200)
        n = 0
        for i in issues:
            cs = self.comments(i["key"])
            for name, since, nxt in (("questions", "created", "plan"), ("plan", "updated", "status")):
                mc = jt.find_marked(cs, name, self.me())
                if not mc or jt.find_marked(cs, nxt, self.me()):
                    continue  # no such stage, or the run already moved past it
                reps = jt.replies_after(cs, mc, self.me(), since)
                if reps:
                    ok = name == "plan" and any(jt.APPROVAL_RE.match(c["body"] or "") for c in reps)
                    print("%s | %s | %d new repl%s on [%s]%s | %s" % (
                        i["key"], i["fields"]["status"]["name"], len(reps), "y" if len(reps) == 1 else "ies",
                        name, " APPROVED" if ok else "", i["fields"]["summary"][:60]))
                    n += 1
        print("-- %d waiting item(s) across %d issues checked" % (n, len(issues)))

    # -- digest ------------------------------------------------------------------------
    def cmd_digest(self):
        k = self.pos[0] if self.pos else die("Give an issue key.")
        win = jt.parse_window(self.f.get("window"))
        out = Path(self.f["out"]) if self.f.get("out") else work_dir() / k
        att_dir = out / "attachments"
        att_dir.mkdir(parents=True, exist_ok=True)
        seen_f = out / "seen.json"
        seen = json.loads(seen_f.read_text(encoding="utf-8")) if seen_f.exists() else {"attachments": [], "comments": []}
        first_run = not seen_f.exists()
        i = self.j.call("GET", "/issue/%s?expand=names" % k)
        f, names = i["fields"], i.get("names", {})
        pname, prof = self.profile(f["issuetype"]["name"])
        me = self.me()
        md = ["# %s: %s" % (k, f["summary"]), "",
              "| | |", "|---|---|",
              "| Type / profile | %s / %s |" % (f["issuetype"]["name"], pname or "none"),
              "| Status | %s |" % f["status"]["name"],
              "| Assignee / reporter | %s / %s |" % (render(f.get("assignee")) or "-", render(f.get("reporter")) or "-"),
              "| Priority | %s |" % (render(f.get("priority")) or "-"),
              "| Project / components | %s / %s |" % (f["project"]["key"], render(f.get("components")) or "-"),
              "| Affects / fix versions | %s / %s |" % (render(f.get("versions")) or "-", render(f.get("fixVersions")) or "-"),
              "| Labels | %s |" % (render(f.get("labels")) or "-"),
              "| Link | %s/browse/%s |" % (BASE, k)]
        if f.get("environment"):
            md.append("| Environment | %s |" % render(f["environment"]).replace("\n", " "))
        long_fields = []
        for label, name in (prof.get("fields") or {}).items():
            fid = self.j.fid(name)
            v = render(f.get(fid)) if fid else ""
            if not v:
                continue
            if len(v) > 80 or "\n" in v:
                long_fields.append((names.get(fid, label), v))
            else:
                md.append("| %s | %s |" % (names.get(fid, label), v))
        epic_id = self.j.fid((prof.get("fields") or {}).get("epic") or "Epic Link")
        parent = f.get("parent") or ({"key": f.get(epic_id)} if epic_id and f.get(epic_id) else None)
        if parent:
            p = self.j.call("GET", "/issue/%s?fields=summary,issuetype" % parent["key"])
            md.append("| Parent / epic | %s (%s): %s |" % (parent["key"], p["fields"]["issuetype"]["name"], p["fields"]["summary"]))
        for label, v in long_fields:
            md += ["", "## %s" % label, "", v]
        md += ["", "## Description", "", (f.get("description") or "(none)").replace("\r", "")]
        links = f.get("issuelinks") or []
        if links:
            md += ["", "## Linked issues", ""]
            for l in links:
                o = l.get("outwardIssue") or l.get("inwardIssue")
                rel = l["type"]["outward"] if "outwardIssue" in l else l["type"]["inward"]
                md.append("- %s %s (%s, %s): %s" % (rel, o["key"], o["fields"]["issuetype"]["name"],
                                                    o["fields"]["status"]["name"], o["fields"]["summary"]))
        if f.get("subtasks"):
            md += ["", "## Sub-tasks", ""]
            md += ["- %s (%s): %s" % (s["key"], s["fields"]["status"]["name"], s["fields"]["summary"]) for s in f["subtasks"]]
        rl = self.j.call("GET", "/issue/%s/remotelink" % k)
        if rl:
            md += ["", "## Remote links", ""] + ["- [%s](%s)" % (r["object"]["title"], r["object"]["url"]) for r in rl]
        atts = f.get("attachment") or []
        new_att = 0
        if atts:
            md += ["", "## Attachments", "", "| | File | Size | Local | Reduced / preview |", "|---|---|---|---|---|"]
            for a in sorted(atts, key=lambda x: x["created"]):
                is_new = a["id"] not in seen["attachments"]
                new_att += is_new
                local, extra = self._attachment(a, att_dir, win)
                md.append("| %s | %s | %s | %s | %s |" % ("NEW" if is_new and not first_run else "", a["filename"],
                                                          _size(a["size"]), local or "-", extra or "-"))
                seen["attachments"].append(a["id"])
        cs = self.comments(k)
        new_c = 0
        if cs:
            md += ["", "## Comments (oldest first)", ""]
            for c in cs:
                mk = jt.comment_markers(c.get("body"))
                who = c["author"]["name"]
                if mk and who == me:
                    md.append("- (bot) [%s] by %s, updated %s" % (",".join(sorted(mk)), who, c["updated"][:16]))
                    continue
                is_new = c["id"] not in seen["comments"]
                new_c += is_new
                body = c["body"].replace("\r", "")
                md += ["", "### %s%s, %s" % ("NEW " if is_new and not first_run else "", who, c["created"][:16]), "",
                       body[:3000] + ("\n... (truncated)" if len(body) > 3000 else "")]
                seen["comments"].append(c["id"])
        seen = {kk: sorted(set(v)) for kk, v in seen.items()}
        (out / "digest.md").write_text("\n".join(md) + "\n", encoding="utf-8")
        seen_f.write_text(json.dumps(seen, indent=1), encoding="utf-8")
        print("%s  (%s, %s, profile %s)" % (out / "digest.md", f["issuetype"]["name"], f["status"]["name"], pname or "none"))
        print("attachments: %d (%d new)   comments: %d (%d new)%s" % (
            len(atts), 0 if first_run else new_att, len(cs), 0 if first_run else new_c, "   first run" if first_run else ""))

    def _attachment(self, a, att_dir, win):
        """Download one attachment and write an agent-sized companion. Returns (local, extra)."""
        name = re.sub(r'[<>:"/\\|?*]', "_", a["filename"])
        dst = att_dir / ("%s-%s" % (a["id"], name))
        ext = name.rsplit(".", 1)[-1].lower() if "." in name else ""
        if self.f.get("no-attachments"):
            return None, None
        if a["size"] > MAX_DOWNLOAD:
            return None, "too big to download (%s)" % _size(a["size"])
        if dst.exists() and dst.stat().st_size != a["size"]:
            dst.unlink()  # a stale partial or login page from an earlier run
        if not dst.exists():
            for old in att_dir.glob(glob_escape(dst.name) + ".*"):
                shutil.rmtree(old) if old.is_dir() else old.unlink()  # companions of a previous copy
        manual = att_dir / name
        if not dst.exists() and manual.exists() and manual.stat().st_size == a["size"]:
            manual.rename(dst)  # saved by hand from the browser
        if not dst.exists():
            if getattr(self, "_download_blocked", False):
                return None, "NOT DOWNLOADED (server blocks token downloads): save it into attachments/ as %s" % name
            data, final, ctype = self.j.raw(a["content"])
            if len(data) != a["size"]:
                self._download_blocked = True
                why = "redirected to %s" % urllib.parse.urlsplit(final).path if final.split("?")[0] != a["content"] \
                    else "got %d bytes of %s" % (len(data), ctype or "?")
                print("warning: %s: download blocked (%s). The server probably requires a browser login/2FA for "
                      "attachments. Download them in the browser into %s and re-run digest." % (a["filename"], why, att_dir),
                      file=sys.stderr)
                return None, "NOT DOWNLOADED (server blocks token downloads): save it into attachments/ as %s" % name
            dst.write_bytes(data)
        rel = lambda p: str(p.relative_to(att_dir.parent)).replace("\\", "/")  # noqa: E731
        data = None
        try:
            if jt.is_text_name(name) or a.get("mimeType", "").startswith("text/"):
                red = dst.with_name(dst.name + ".reduced.txt")
                if not red.exists() or win:
                    lines = jt.decode_text(dst.read_bytes()).splitlines()
                    red.write_text(jt.reduce_log(lines, win), encoding="utf-8")
                return rel(dst), rel(red)
            if ext in ("xlsx", "xlsm"):
                prev = dst.with_name(dst.name + ".preview.csv")
                if not prev.exists():
                    prev.write_text(jt.xlsx_preview(dst.read_bytes()), encoding="utf-8")
                return rel(dst), rel(prev)
            if ext == "zip":
                lst = dst.with_name(dst.name + ".listing.txt")
                data = dst.read_bytes()
                listing, z = jt.zip_listing(data)
                parts = [listing]
                for info in z.infolist():
                    if info.file_size and info.file_size <= 50 * 1024 * 1024 and jt.is_text_name(info.filename):
                        lines = jt.decode_text(z.read(info)).splitlines()
                        parts.append("\n===== %s (reduced)\n%s" % (info.filename, jt.reduce_log(lines, win, max_lines=120)))
                lst.write_text("".join(parts), encoding="utf-8")
                return rel(dst), rel(lst)
            if ext == "pdf" and shutil.which("pdftotext"):
                txt = dst.with_name(dst.name + ".txt")
                if not txt.exists():
                    subprocess.run(["pdftotext", "-layout", str(dst), str(txt)], check=False, capture_output=True)
                return rel(dst), rel(txt) if txt.exists() else "pdftotext failed"
            if ext in VIDEO_EXT:
                if not shutil.which("ffmpeg"):
                    return rel(dst), "video: install ffmpeg for frames, or ask the user what it shows"
                frames = dst.with_name(dst.name + ".frames")
                if not frames.exists():
                    frames.mkdir()
                    subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(dst), "-vf", "fps=1/4,scale=960:-1",
                                    "-frames:v", "8", str(frames / "f%02d.png")], check=False, capture_output=True)
                return rel(dst), rel(frames) + "/ (frames every 4 s)"
            if ext in IMAGE_EXT:
                return rel(dst), "image (view it)"
        except Exception as e:  # a broken attachment must not break the digest
            return rel(dst), "could not preview: %s" % e
        return rel(dst), "listed only"

    # -- init --------------------------------------------------------------------------
    def cmd_init(self):
        proj = self.f.get("project") or die("--project is required.")
        p = self.j.call("GET", "/project/" + proj)
        st = self.j.call("GET", "/project/%s/statuses" % proj)
        print("project %s: %s" % (proj, p["name"].strip()))
        groups = {}
        for t in st:
            groups.setdefault(tuple(s["name"] for s in t["statuses"]), []).append(t["name"])
        for sts, types in groups.items():
            print("\ntypes: %s\n  statuses (API order, not workflow order): %s" % (", ".join(types), " | ".join(sts)))
        wanted = ["Acceptance Criteria", "Story Points", "Epic Link", "Severity", "Environment", "Defect Symptom",
                  "Reproducible Category", "Found-In Batch", "Product", "Test Considerations", "Resolution Description",
                  "Evaluation Notes", "Unit Test Results", "Modules Affected", "Repair Code", "Code Branch",
                  "Release Considerations", "Defect Origination Activity"]
        print("\nfields:")
        for w in wanted:
            print("  %-28s %s" % (w, self.j.fid(w) or "-"))
        for k in self.f.get("sample", "").split(",") + self.pos:
            k = k.strip()
            if not k:
                continue
            print("\nsample %s transitions (* = required):" % k)
            self.pos = [k]
            self.f["fields"] = True
            self.cmd_transitions()
        types = [t["name"] for t in p.get("issueTypes", [])]
        skel = {"url": BASE, "work_dir": ".jira-flow",
                "token": {"file": "LOCAL-ENVIRONMENT.md", "labels": jt.DEFAULT_TOKEN_LABELS},
                "queries": {"mine": "project = %s AND issuetype = Story" % proj,
                            "pi": 'project = %s AND issuetype = Story AND fixVersion = "{pi}"' % proj},
                "profiles": {}}
        for pname, prof in DEFAULT_PROFILES.items():
            its = [t for t in types if jt.profile_for(t, {pname: prof})[0]]
            if not its:
                continue
            sts = next((list(s) for s, ts in groups.items() if its[0] in ts), [])
            skel["profiles"][pname] = {"issue_types": its, "fields": dict(prof.get("fields", {})),
                                       "path": sts, "_todo": "order `path` as the forward workflow and trim it",
                                       "status": {"plan_approved": None, "pr_opened": None, "merged": None},
                                       "never": []}
        txt = json.dumps(skel, indent=2)
        if self.f.get("out"):
            dst = Path(self.f["out"])
            if dst.exists() and not self.f.get("force"):
                die("%s exists (use --force to overwrite)" % dst)
            dst.write_text(txt + "\n", encoding="utf-8")
            print("\nwrote %s (review `path`, `status` and `never` before use)" % dst)
        else:
            print("\nconfig skeleton (use --out FILE to write it):\n" + txt)

    def cmd_bulk(self):
        act = self.f.get("do")
        if act not in self.ACTIONS:
            die("--do must be one of " + ", ".join(self.ACTIONS))
        if not self.f.get("jql"):
            die("bulk needs --jql.")
        for k in self.keys():
            getattr(self, "do_" + act)(k)


def _norm_eq(a, b):
    return (a or "").strip().lower() == (b or "").strip().lower()


def _size(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return ("%d %s" if unit == "B" else "%.1f %s") % (n, unit)
        n /= 1024.0


def offline(cmd, flags, pos):
    if cmd == "md2wiki":
        src = Path(pos[0]).read_text(encoding="utf-8") if pos else sys.stdin.read()
        print(jt.md_to_wiki(src))
        return True
    if cmd == "reduce-log":
        f = pos[0] if pos else die("Give a log file.")
        lines = jt.decode_text(Path(f).read_bytes()).splitlines()
        sys.stdout.write(jt.reduce_log(lines, jt.parse_window(flags.get("window")), int(flags.get("max-lines", 200))))
        return True
    return False


def main():
    argv = sys.argv[1:]
    if not argv or argv[0] in ("help", "-h", "--help"):
        print(__doc__)
        return
    cmd, (flags, pos) = argv[0], parse(argv[1:])
    if offline(cmd, flags, pos):
        return
    t = Tool(Jira(token()), flags, pos)
    meth = "cmd_" + cmd.replace("-", "_")
    if cmd in Tool.ACTIONS:
        for k in t.keys():
            getattr(t, "do_" + cmd)(k)
    elif hasattr(t, meth):
        getattr(t, meth)()
    else:
        die("unknown command %r (run with no arguments for help)" % cmd)
    acts = flags.get("do") if cmd == "bulk" else cmd
    if not t.yes and acts in Tool.ACTIONS:
        print("\n(dry run - add --yes to apply)")


if __name__ == "__main__":
    main()
