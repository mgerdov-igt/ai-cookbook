"""Pure helpers for jira.py: no network, no Jira calls, so they are unit-testable offline.

Markdown -> Jira wiki markup, log reduction, xlsx/zip previews, token lookup, comment
markers, transition choice and field-value coercion. Python 3.8+, standard library only.
"""
import csv
import fnmatch
import io
import re
import zipfile
from xml.etree import ElementTree as ET

# --------------------------------------------------------------------------------------
# Markdown -> Jira wiki markup (Jira Server renders wiki markup, not Markdown)
# --------------------------------------------------------------------------------------
_FENCE = re.compile(r"^\s*```\s*([\w+-]*)\s*$")
_TABLE_SEP = re.compile(r"^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$")


def _inline(s):
    codes = []

    def keep(m):
        codes.append(m.group(1))
        return "\x00%d\x00" % (len(codes) - 1)

    s = re.sub(r"`([^`]+)`", keep, s)
    s = s.replace("{", r"\{").replace("}", r"\}")
    s = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", r"[\1|\2]", s)
    s = re.sub(r"\*\*(.+?)\*\*", "\x01\\1\x01", s)
    s = re.sub(r"__(.+?)__", "\x01\\1\x01", s)
    s = re.sub(r"(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])", r"_\1_", s)
    s = re.sub(r"~~(.+?)~~", r"-\1-", s)
    s = s.replace("\x01", "*")
    return re.sub(r"\x00(\d+)\x00", lambda m: "{{%s}}" % codes[int(m.group(1))], s)


def _cells(line):
    line = line.strip()
    if line.startswith("|"):
        line = line[1:]
    if line.endswith("|"):
        line = line[:-1]
    return [c.strip() for c in line.split("|")]


def md_to_wiki(md):
    """Convert the Markdown subset agents write (headings, lists, tables, code, links,
    bold/italic, quotes) to Jira wiki markup."""
    out, lines, i, in_code = [], md.replace("\r", "").split("\n"), 0, False
    while i < len(lines):
        line = lines[i]
        m = _FENCE.match(line)
        if m:
            if in_code:
                out.append("{code}")
            else:
                out.append("{code:%s}" % m.group(1) if m.group(1) else "{code}")
            in_code = not in_code
            i += 1
            continue
        if in_code:
            out.append(line)
            i += 1
            continue
        if "|" in line and i + 1 < len(lines) and _TABLE_SEP.match(lines[i + 1]):
            out.append("||" + "||".join(_inline(c) for c in _cells(line)) + "||")
            i += 2
            while i < len(lines) and lines[i].strip().startswith("|"):
                out.append("|" + "|".join(_inline(c) or " " for c in _cells(lines[i])) + "|")
                i += 1
            continue
        h = re.match(r"^(#{1,6})\s+(.*)$", line)
        b = re.match(r"^(\s*)[-*+]\s+(.*)$", line)
        n = re.match(r"^(\s*)\d+[.)]\s+(.*)$", line)
        q = re.match(r"^>\s?(.*)$", line)
        if h:
            out.append("h%d. %s" % (len(h.group(1)), _inline(h.group(2))))
        elif b:
            out.append("*" * (len(b.group(1).expandtabs(2)) // 2 + 1) + " " + _inline(b.group(2)))
        elif n:
            out.append("#" * (len(n.group(1).expandtabs(2)) // 2 + 1) + " " + _inline(n.group(2)))
        elif q:
            out.append("bq. " + _inline(q.group(1)))
        elif re.match(r"^\s*(-{3,}|\*{3,})\s*$", line):
            out.append("----")
        else:
            out.append(_inline(line))
        i += 1
    if in_code:
        out.append("{code}")
    return "\n".join(out)


# --------------------------------------------------------------------------------------
# Comment markers: the bot's comments carry a footer marker so they are edited in place
# --------------------------------------------------------------------------------------
MARKER_RE = re.compile(r"jiraflow:([a-z][a-z0-9-]*)")


def marker_footer(name):
    return "{color:#97a0af}jiraflow:%s{color}" % name


def comment_markers(body):
    return set(MARKER_RE.findall(body or ""))


def find_marked(comments, name, me):
    """The newest comment by `me` carrying marker `name`, or None."""
    hits = [c for c in comments
            if (c.get("author") or {}).get("name") == me and name in comment_markers(c.get("body"))]
    return hits[-1] if hits else None


APPROVAL_RE = re.compile(r"^\W*(approved?|lgtm|go ahead)\b", re.I)


def replies_after(comments, marker_comment, me, since="created"):
    """Human replies posted after the marker comment (bot comments excluded)."""
    t0 = marker_comment.get(since) or marker_comment.get("created")
    return [c for c in comments
            if c.get("created", "") > t0 and not comment_markers(c.get("body"))
            and c is not marker_comment]


# --------------------------------------------------------------------------------------
# Token lookup
# --------------------------------------------------------------------------------------
DEFAULT_TOKEN_LABELS = ["ai-jira-token", "jira-token", "My JIRA access token"]


def token_from_text(text, labels=None):
    """Find a token in a notes file: `label: value` on one line, or the label on its own
    line (`#### My JIRA access token:`) followed by the value line."""
    lines = text.replace("\r", "").split("\n")
    for label in labels or DEFAULT_TOKEN_LABELS:
        pat = re.compile(r"^[\s#>*-]*%s\s*:?\s*(.*)$" % re.escape(label), re.I)
        for i, line in enumerate(lines):
            m = pat.match(line)
            if not m:
                continue
            val = m.group(1).strip().strip("`")
            if not val:
                val = next((x for x in lines[i + 1:] if x.strip()), "")
                val = re.sub(r"^[^:]*:\s*", "", val).strip().strip("`") if ":" in val else val.strip().strip("`")
            if val and " " not in val:
                return val
    return None


# --------------------------------------------------------------------------------------
# Workflow: choose the next forward transition toward a target status
# --------------------------------------------------------------------------------------
def _norm(s):
    return (s or "").strip().lower()


def is_banned(name, never):
    """True if `name` matches an entry of `never` (case-insensitive; `*` and `?` are wildcards)."""
    n = _norm(name)
    return any(fnmatch.fnmatchcase(n, _norm(p)) for p in never or ())


def choose_transition(transitions, path, current, target, never=()):
    """One forward step along `path` (ordered status names) from `current` toward `target`.

    Returns (transition | None, reason). Never picks a transition whose name or target
    status is in `never`, never moves backward and never overshoots `target`."""
    order = [_norm(s) for s in path]
    cur, tgt = _norm(current), _norm(target)
    if tgt not in order:
        return None, "target %r is not on the configured path" % target
    if cur not in order:
        return None, "current status %r is off the configured path" % current
    ci, ti = order.index(cur), order.index(tgt)
    if ci == ti:
        return None, "already there"
    if ci > ti:
        return None, "already past %r" % target
    best = None
    for t in transitions:
        to = _norm(t["to"]["name"])
        if is_banned(to, never) or is_banned(t["name"], never) or to not in order:
            continue
        idx = order.index(to)
        if ci < idx <= ti and (best is None or idx < order.index(_norm(best["to"]["name"]))):
            best = t
    if best is None:
        return None, "no forward transition offered (offered: %s)" % ", ".join(
            "%s->%s" % (t["name"], t["to"]["name"]) for t in transitions)
    return best, "ok"


def missing_required(transition, provided):
    """Names of required screen fields that have no default and were not provided."""
    have = {_norm(k) for k in provided}
    out = []
    for fid, f in (transition.get("fields") or {}).items():
        if f.get("required") and not f.get("hasDefaultValue") and _norm(fid) not in have and _norm(f.get("name")) not in have:
            out.append(f.get("name") or fid)
    return out


def coerce(meta, value):
    """Shape a plain value for a field's REST schema (from transitions?expand=transitions.fields
    or editmeta)."""
    schema = meta.get("schema") or {}
    typ, items = schema.get("type"), schema.get("items")
    allowed = meta.get("allowedValues") or []
    key = "value" if allowed and "value" in allowed[0] else "name"

    def one(kind, v):
        if isinstance(v, dict):
            return v
        if kind in ("option", "option-with-child"):
            return {"value": v}
        if kind in ("user", "version", "component", "resolution", "priority", "group", "issuetype"):
            return {"name": v}
        return v

    if typ == "array":
        vals = value if isinstance(value, list) else [value]
        if items == "string":
            return [str(v) for v in vals]
        return [one(items or ("option" if key == "value" else "version"), v) for v in vals]
    if typ == "number":
        return float(value) if "." in str(value) else int(value)
    if typ in ("string", "date", "datetime", "any") or typ is None and not allowed:
        return value
    if typ in (None, "option") and allowed:
        return {key: value} if not isinstance(value, dict) else value
    return one(typ, value)


def profile_for(issue_type, profiles):
    """(name, profile) whose `issue_types` matches; entries starting with `re:` are regexes."""
    for name, p in (profiles or {}).items():
        for t in p.get("issue_types", []):
            if t.startswith("re:") and re.search(t[3:], issue_type or ""):
                return name, p
            if _norm(t) == _norm(issue_type):
                return name, p
    return None, {}


# --------------------------------------------------------------------------------------
# Log reduction: big text attachments -> a short, deduplicated digest
# --------------------------------------------------------------------------------------
LEVEL_RE = re.compile(
    r"\b(FATAL|CRITICAL|SEVERE|ERROR|ERR|WARNING|WARN)\b|Exception\b|Traceback|\bpanic\b|"
    r"segfault|Segmentation fault|SIGSEGV|core dumped|\bE/|\bW/|\[E\]|\[W\]", re.I)
CONT_RE = re.compile(r"^(\s+|\tat |\s*at |\s*#\d+\s|\s*Caused by|\s*\.\.\. \d+ more|\s*File \")")
TIME_RE = re.compile(r"(?<!\d)([01]?\d|2[0-3]):([0-5]\d):([0-5]\d)(?:[.,](\d{1,6}))?")
_NOISE_RE = re.compile(r"0x[0-9a-fA-F]+|\b\d+\b|[0-9a-f]{8}-[0-9a-f-]{27,}")


def _secs(m):
    return int(m.group(1)) * 3600 + int(m.group(2)) * 60 + int(m.group(3))


def parse_window(spec):
    """'00:10-00:20' or '00:10:00-00:20:30' -> (start_secs, end_secs)."""
    if not spec:
        return None
    m = re.match(r"^\s*(\d{1,2}:\d{2}(?::\d{2})?)\s*[-–]\s*(\d{1,2}:\d{2}(?::\d{2})?)\s*$", spec)
    if not m:
        raise ValueError("window must look like HH:MM-HH:MM or HH:MM:SS-HH:MM:SS")

    def s(x):
        p = [int(v) for v in x.split(":")] + [0]
        return p[0] * 3600 + p[1] * 60 + p[2]

    return s(m.group(1)), s(m.group(2))


def reduce_log(lines, window=None, max_lines=200, context=2, max_trace=15, max_width=300):
    """Return a short report: size/time span, level counts, first/last lines and every
    error/warning block (with a stack-trace tail), deduplicated by a normalized signature.
    Output lines longer than `max_width` are clipped."""
    lines = [l.rstrip("\r\n") for l in lines]
    total = len(lines)
    head = [l for l in lines[:200] if l.strip()]
    stamped = bool(head) and sum(1 for l in head if TIME_RE.search(l)) >= len(head) // 2

    def continues(l):
        # In a timestamped log a line without a time continues the previous record.
        return bool(CONT_RE.match(l)) or (stamped and l.strip() != "" and not TIME_RE.search(l))

    first_t = last_t = None
    counts = {}
    blocks, seen, order = {}, {}, []
    cur_t = None
    i = 0
    while i < total:
        line = lines[i]
        tm = TIME_RE.search(line)
        if tm:
            cur_t = "%02d:%s:%s" % (int(tm.group(1)), tm.group(2), tm.group(3))
            first_t = first_t or cur_t
            last_t = cur_t
        in_win = True
        if window and tm:
            s = _secs(tm)
            a, b = window
            in_win = a <= s <= b if a <= b else (s >= a or s <= b)
        elif window and cur_t is None:
            in_win = False
        lm = LEVEL_RE.search(line)
        if lm and in_win:
            lvl = (lm.group(1) or lm.group(0)).upper().strip("[]/")
            lvl = {"ERR": "ERROR", "WARNING": "WARN", "E": "ERROR", "W": "WARN"}.get(lvl, lvl)
            counts[lvl] = counts.get(lvl, 0) + 1
            j = i + 1
            while j < total and j - i <= max_trace and continues(lines[j]):
                j += 1
            start = max(0, i - context)
            body = lines[start:j]
            sig = _NOISE_RE.sub("#", TIME_RE.sub("", line)).strip()[:200]
            if sig in seen:
                seen[sig]["n"] += 1
                seen[sig]["last"] = cur_t or seen[sig]["last"]
            else:
                seen[sig] = {"n": 1, "first": cur_t, "last": cur_t, "line": i + 1, "body": body}
                order.append(sig)
            i = j
            continue
        i += 1
    out = ["lines: %d   time span: %s .. %s%s" % (total, first_t or "?", last_t or "?",
           "   window: %02d:%02d:%02d-%02d:%02d:%02d" % (window[0] // 3600, window[0] // 60 % 60, window[0] % 60,
                                                         window[1] // 3600, window[1] // 60 % 60, window[1] % 60)
           if window else "")]
    out.append("levels: " + (", ".join("%s=%d" % kv for kv in sorted(counts.items(), key=lambda x: -x[1])) or "none"))
    out.append("distinct problem signatures: %d" % len(order))
    out.append("--- first lines")
    out.extend(lines[:5])
    out.append("--- last lines")
    out.extend(lines[-5:] if total > 5 else [])
    out.append("--- problems (first occurrence; xN = repeats)")
    budget = max_lines - len(out)
    shown = 0
    for sig in order:
        b = seen[sig]
        head = "@L%d  x%d  %s..%s" % (b["line"], b["n"], b["first"] or "?", b["last"] or "?")
        need = 1 + len(b["body"])
        if budget - need < 0:
            out.append("... %d more signatures not shown (grep the full file)" % (len(order) - shown))
            break
        out.append(head)
        out.extend("    " + l for l in b["body"])
        budget -= need
        shown += 1
    clip = lambda l: l if len(l) <= max_width else l[:max_width] + " ...[+%d chars]" % (len(l) - max_width)  # noqa: E731
    return "\n".join(clip(l) for l in out) + "\n"


# --------------------------------------------------------------------------------------
# Office/zip previews (stdlib only)
# --------------------------------------------------------------------------------------
_NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}


def _col_index(ref):
    letters = re.match(r"[A-Z]+", ref or "A").group(0)
    n = 0
    for ch in letters:
        n = n * 26 + ord(ch) - 64
    return n - 1


def xlsx_preview(data, max_rows=40, max_sheets=3):
    """CSV text of the first rows of the first sheets of an .xlsx file."""
    z = zipfile.ZipFile(io.BytesIO(data))
    shared = []
    if "xl/sharedStrings.xml" in z.namelist():
        root = ET.fromstring(z.read("xl/sharedStrings.xml"))
        for si in root.findall("m:si", _NS):
            shared.append("".join(t.text or "" for t in si.iter("{%s}t" % _NS["m"])))
    sheets = sorted(n for n in z.namelist() if re.match(r"xl/worksheets/sheet\d+\.xml$", n))
    sheets.sort(key=lambda n: int(re.search(r"(\d+)", n.rsplit("/", 1)[1]).group(1)))
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    for name in sheets[:max_sheets]:
        buf.write("## %s\n" % name.rsplit("/", 1)[1])
        root = ET.fromstring(z.read(name))
        rows = root.findall(".//m:sheetData/m:row", _NS)
        for row in rows[:max_rows]:
            vals = {}
            for c in row.findall("m:c", _NS):
                v = c.find("m:v", _NS)
                isv = c.find("m:is", _NS)
                if c.get("t") == "s" and v is not None:
                    txt = shared[int(v.text)] if v.text and int(v.text) < len(shared) else ""
                elif isv is not None:
                    txt = "".join(t.text or "" for t in isv.iter("{%s}t" % _NS["m"]))
                else:
                    txt = v.text if v is not None else ""
                vals[_col_index(c.get("r"))] = txt
            if vals:
                w.writerow([vals.get(k, "") for k in range(max(vals) + 1)])
        if len(rows) > max_rows:
            buf.write("... %d more rows\n" % (len(rows) - max_rows))
    return buf.getvalue()


TEXT_EXT = {"log", "txt", "csv", "json", "xml", "ini", "cfg", "conf", "yml", "yaml", "properties", "out", "trace"}


def is_text_name(name):
    ext = name.rsplit(".", 1)[-1].lower() if "." in name else ""
    return ext in TEXT_EXT or bool(re.search(r"\.log\.\d+$", name.lower()))


def decode_text(data):
    for enc in ("utf-8", "utf-16") if data[:2] in (b"\xff\xfe", b"\xfe\xff") else ("utf-8",):
        try:
            return data.decode(enc)
        except UnicodeDecodeError:
            pass
    return data.decode("latin-1")


def zip_listing(data, max_entries=60):
    z = zipfile.ZipFile(io.BytesIO(data))
    infos = z.infolist()
    out = ["%10d  %s" % (i.file_size, i.filename) for i in infos[:max_entries]]
    if len(infos) > max_entries:
        out.append("... %d more entries" % (len(infos) - max_entries))
    return "\n".join(out) + "\n", z
