#!/usr/bin/env python3
"""State and hygiene scan for the pre-push skill. Read-only. Python 3.8+, Git.

Answers, in one short output, what a pre-push check needs to know first:

  * which branch this is, what the default branch is, and what the work is based on;
  * how far ahead and behind the default branch it is, and who wrote the commits;
  * every file that differs from that base, whether committed, staged, edited or new;
  * hygiene hits in the added lines and new files: conflict markers, secret-looking
    strings (never printed, only located), sensitive file names, very large files,
    and debug or focus leftovers.

Usage (run from inside the repo):

  python3 prepush_scan.py                 # short text
  python3 prepush_scan.py --json          # one JSON object, for scripts
  python3 prepush_scan.py --base origin/develop
  python3 prepush_scan.py --strict        # exit 1 when a conflict marker or secret is found
  python3 prepush_scan.py --build PATH    # is the build at PATH older than the newest source?

On Windows use `python` or `py -3` if `python3` is not on PATH.

Exit codes: 0 done (hits are information, unless --strict; with --build: fresh); 1 --strict
and a conflict marker or a secret hit, or --build and the build is stale; 2 not a git repo,
no base to compare with, or no build at PATH.

It never prints a secret value, changes the repo, or reads outside it.
"""
import argparse
import datetime
import json
import os
import re
import subprocess
import sys

MAX_SCAN_BYTES = 1_000_000  # an untracked file larger than this is flagged, not read
BIG_FILE_BYTES = 5_000_000
LIST_LIMIT = 40

# Added lines only. The patterns are deliberately narrow: a hit is a reason to look, not a verdict.
CONFLICT = re.compile(r"^(<<<<<<<|>>>>>>>) ")
SECRETS = [
    ("private-key", re.compile(r"-----BEGIN (?:RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY")),
    ("aws-access-key", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("github-token", re.compile(r"\bgh[pousr]_[A-Za-z0-9]{36,}\b")),
    ("slack-token", re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}")),
    ("google-api-key", re.compile(r"\bAIza[0-9A-Za-z_\-]{35}\b")),
    ("assigned-secret", re.compile(
        r"""(?i)\b(?:api[_-]?key|secret|token|passw(?:or)?d)\b\s*[:=]\s*['"][^'"\s]{12,}['"]""")),
]
LEFTOVER = re.compile(
    r"\.only\(|\bfdescribe\(|\bdebugger;|\bbinding\.pry\b|\bpdb\.set_trace\(\)|\bbreakpoint\(\)")
SENSITIVE_NAME = re.compile(
    r"(?i)(^|/)(\.env(\.[^/]*)?|id_(rsa|dsa|ecdsa|ed25519)|[^/]*\.(pem|key|p12|pfx|jks|keystore)|"
    r"credentials[^/]*\.json|secrets?\.[^/]+)$")
SENSITIVE_OK = re.compile(r"(?i)\.(example|sample|template|dist)$")
DOC_SUFFIXES = (".md", ".mdx", ".txt", ".rst")


def git(root, *args, check=True):
    r = subprocess.run(["git", *args], cwd=root, capture_output=True, text=True,
                       encoding="utf-8", errors="replace")
    if check and r.returncode != 0:
        raise RuntimeError(r.stderr.strip() or f"git {' '.join(args)} failed")
    return r


def lines(root, *args):
    return [ln for ln in git(root, *args).stdout.splitlines() if ln.strip()]


def repo_root():
    r = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True,
                       encoding="utf-8", errors="replace")
    return r.stdout.strip() if r.returncode == 0 else None


def verify(root, ref):
    return git(root, "rev-parse", "--verify", "-q", f"{ref}^{{commit}}", check=False).returncode == 0


def default_ref(root):
    """origin/HEAD when the remote says it, else the first of the usual names that exists."""
    r = git(root, "symbolic-ref", "--short", "-q", "refs/remotes/origin/HEAD", check=False)
    if r.returncode == 0 and r.stdout.strip():
        return r.stdout.strip()
    for ref in ("origin/main", "origin/master", "main", "master"):
        if verify(root, ref):
            return ref
    return None


def find_secrets_and_leftovers(path, text_lines, hits):
    """text_lines: [(line_number or None, text)] of ADDED lines for this file."""
    is_doc = path.lower().endswith(DOC_SUFFIXES)
    for no, text in text_lines:
        if CONFLICT.match(text):
            hits["conflictMarkers"].append({"file": path, "line": no})
        for kind, pat in SECRETS:
            if pat.search(text):
                # Locate only. The value is never copied into the report.
                hits["secrets"].append({"file": path, "line": no, "kind": kind})
                break
        if not is_doc and LEFTOVER.search(text):
            hits["leftovers"].append({"file": path, "line": no})


def scan(root, base_arg):
    ref = base_arg or default_ref(root)
    if not ref or not verify(root, ref):
        raise LookupError(f"no base to compare with ({base_arg or 'no default branch found'}); "
                          "fetch the remote or pass --base <ref>")
    merge_base = git(root, "merge-base", "HEAD", ref, check=False).stdout.strip() or ref
    branch = git(root, "branch", "--show-current", check=False).stdout.strip()
    default_short = ref.split("/", 1)[1] if ref.startswith("origin/") else ref

    behind, ahead = (int(x) for x in lines(root, "rev-list", "--left-right", "--count",
                                           f"{ref}...HEAD")[0].split())
    commits = []
    authors = {}
    for ln in lines(root, "log", f"{ref}..HEAD", "--format=%h%x09%an%x09%s"):
        sha, author, subject = (ln.split("\t", 2) + ["", ""])[:3]
        commits.append({"sha": sha, "author": author, "subject": subject})
        authors[author] = authors.get(author, 0) + 1

    tracked = lines(root, "diff", "--no-renames", "--name-only", merge_base)
    untracked = lines(root, "ls-files", "-o", "--exclude-standard")
    # -uall lists every new file; without it git folds a new folder into one `dir/` line.
    status = lines(root, "status", "--porcelain", "-uall")
    uncommitted = sorted({ln[3:].strip().strip('"') for ln in status})
    changed = sorted(set(tracked) | set(untracked))

    dirs = {}
    for f in changed:
        top = f.split("/", 1)[0] if "/" in f else "(root)"
        dirs[top] = dirs.get(top, 0) + 1

    hits = {"conflictMarkers": [], "secrets": [], "leftovers": [],
            "sensitivePaths": [], "bigFiles": []}

    # Added lines of tracked files (committed, staged and edited), against the merge base.
    path, no = None, None
    patch = git(root, "diff", "--no-renames", "-U0", "--no-color", merge_base, check=False).stdout
    pending = {}
    for ln in patch.splitlines():
        if ln.startswith("+++ b/"):
            path = ln[6:]
        elif ln.startswith("@@"):
            m = re.search(r"\+(\d+)", ln)
            no = int(m.group(1)) if m else None
        elif ln.startswith("+") and not ln.startswith("+++") and path:
            pending.setdefault(path, []).append((no, ln[1:]))
            no = no + 1 if no is not None else None
    for p, ls in pending.items():
        find_secrets_and_leftovers(p, ls, hits)

    # New untracked files: read whole, unless too large or binary.
    for f in untracked:
        full = os.path.join(root, f)
        try:
            size = os.path.getsize(full)
        except OSError:
            continue
        if size > MAX_SCAN_BYTES:
            continue
        try:
            with open(full, encoding="utf-8") as fh:
                text = fh.read().splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        find_secrets_and_leftovers(f, list(enumerate(text, 1)), hits)

    for f in changed:
        if SENSITIVE_NAME.search(f) and not SENSITIVE_OK.search(f):
            hits["sensitivePaths"].append(f)
        full = os.path.join(root, f)
        try:
            size = os.path.getsize(full)
        except OSError:
            continue
        if size > BIG_FILE_BYTES:
            hits["bigFiles"].append({"file": f, "megabytes": round(size / 1_000_000, 1)})

    return {
        "root": root,
        "branch": branch or "(detached HEAD)",
        "onDefaultBranch": branch == default_short,
        "defaultRef": ref,
        "base": merge_base[:10],
        "ahead": ahead,
        "behind": behind,
        "commitsByAuthor": authors,
        "commits": commits,
        "changedFiles": len(changed),
        "uncommittedFiles": uncommitted,
        "untrackedFiles": sorted(untracked),
        "byTopFolder": dict(sorted(dirs.items(), key=lambda kv: -kv[1])),
        "changed": changed,
        "hygiene": hits,
    }


def cap(items, n=LIST_LIMIT):
    return items[:n], max(0, len(items) - n)


def render(r):
    out = [f"repo     : {r['root']}",
           f"branch   : {r['branch']}   default: {r['defaultRef']}   base: {r['base']}",
           f"position : {r['ahead']} ahead, {r['behind']} behind {r['defaultRef']}"]
    if r["onDefaultBranch"]:
        out.append("WARNING  : this IS the default branch; pre-push checks assume a work branch.")
    if r["behind"]:
        out.append(f"NOTE     : {r['behind']} commit(s) on {r['defaultRef']} are not in this branch; "
                   "update it before you push, or expect conflicts.")
    if r["commits"]:
        who = ", ".join(f"{a}: {n}" for a, n in sorted(r["commitsByAuthor"].items(),
                                                       key=lambda kv: -kv[1]))
        out.append(f"authors  : {who}")
        shown, more = cap(r["commits"], 15)
        for c in shown:
            out.append(f"  {c['sha']} {c['author']}: {c['subject']}")
        if more:
            out.append(f"  ... and {more} more")
    out.append(f"changed  : {r['changedFiles']} file(s) differ from the base "
               f"({len(r['uncommittedFiles'])} uncommitted, {len(r['untrackedFiles'])} new)")
    out.append("folders  : " + ", ".join(f"{k} {v}" for k, v in list(r["byTopFolder"].items())[:12]))
    if r["uncommittedFiles"]:
        shown, more = cap(r["uncommittedFiles"])
        out.append("uncommitted:")
        out += [f"  {f}" for f in shown]
        if more:
            out.append(f"  ... and {more} more")
    h = r["hygiene"]
    found = False
    for key, label in (("conflictMarkers", "CONFLICT MARKER"), ("secrets", "SECRET-LIKE (value hidden)"),
                       ("leftovers", "debug/focus leftover")):
        for item in h[key][:LIST_LIMIT]:
            found = True
            kind = f" [{item['kind']}]" if "kind" in item else ""
            out.append(f"hygiene  : {label}{kind} {item['file']}:{item['line']}")
    for f in h["sensitivePaths"]:
        found = True
        out.append(f"hygiene  : sensitive file name {f}")
    for b in h["bigFiles"]:
        found = True
        out.append(f"hygiene  : large file {b['file']} ({b['megabytes']} MB)")
    if not found:
        out.append("hygiene  : nothing found")
    return "\n".join(out)


def is_source(path):
    """Counts toward 'the build is older than the source': not docs, not tests."""
    p = path.replace("\\", "/").lower()
    if p.endswith((".md", ".mdx", ".rst")):  # not .txt: a text file may be data a build reads
        return False
    parts = p.split("/")
    return not (parts[0] in ("docs", "doc") or any(x in ("test", "tests", "__tests__") for x in parts[:-1]))


def newest_mtime(paths, limit=50_000):
    best = (0.0, None)
    for i, p in enumerate(paths):
        if i >= limit:
            break
        try:
            m = os.path.getmtime(p)
        except OSError:
            continue
        if m > best[0]:
            best = (m, p)
    return best


def check_build(root, build):
    """Is the build at `build` (a file or a folder) older than the newest source file?"""
    target = build if os.path.isabs(build) else os.path.join(os.getcwd(), build)
    if not os.path.exists(target):
        print(f"no build found at {build}")
        return 2
    if os.path.isdir(target):
        inside = [os.path.join(d, f) for d, _, fs in os.walk(target) for f in fs]
        built, _ = newest_mtime(inside)
        if not built:
            print(f"no build found at {build} (the folder is empty)")
            return 2
    else:
        built = os.path.getmtime(target)
    names = lines(root, "ls-files", "-c", "-o", "--exclude-standard")
    src, src_file = newest_mtime([os.path.join(root, n) for n in names if is_source(n)])
    def when(t):
        return datetime.datetime.fromtimestamp(t).strftime("%Y-%m-%d %H:%M:%S")

    if src_file is None:
        print("FRESH: no source files found to compare with")
        return 0
    rel = os.path.relpath(src_file, root).replace("\\", "/")
    if src > built:
        mins = int((src - built) // 60)
        print(f"STALE: build {build} was made {when(built)}; {rel} changed {when(src)} "
              f"({mins} min later). Rebuild before you test.")
        return 1
    print(f"FRESH: build {build} ({when(built)}) is newer than every source file "
          f"(newest: {rel}, {when(src)}).")
    return 0


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--base", help="ref to compare with (default: the remote's default branch)")
    ap.add_argument("--json", action="store_true", help="print one JSON object")
    ap.add_argument("--strict", action="store_true",
                    help="exit 1 when a conflict marker or a secret-looking string is found")
    ap.add_argument("--build", metavar="PATH",
                    help="only say whether the build at PATH (file or folder) is older than the "
                         "newest source file; exit 0 fresh, 1 stale, 2 no build")
    args = ap.parse_args(argv)

    root = repo_root()
    if not root:
        print("not inside a git repository", file=sys.stderr)
        return 2
    if args.build:
        return check_build(root, args.build)
    try:
        result = scan(root, args.base)
    except (LookupError, RuntimeError) as e:
        print(str(e), file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2) if args.json else render(result))
    bad = result["hygiene"]["conflictMarkers"] or result["hygiene"]["secrets"]
    return 1 if args.strict and bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
