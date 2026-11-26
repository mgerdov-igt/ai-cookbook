#!/usr/bin/env python3
"""Self-test for prepush_scan.py. Builds throwaway git repos in a temp folder.

  python3 test_prepush_scan.py

Needs Git and Python 3.8+. Touches nothing outside the temp folder.
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "prepush_scan.py")
ENV = {**os.environ,
       "GIT_AUTHOR_NAME": "Test Dev", "GIT_AUTHOR_EMAIL": "dev@example.invalid",
       "GIT_COMMITTER_NAME": "Test Dev", "GIT_COMMITTER_EMAIL": "dev@example.invalid",
       "GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_SYSTEM": os.devnull}


def git(cwd, *args, **env):
    r = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True,
                       env={**ENV, **env}, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        raise AssertionError(f"git {' '.join(args)}: {r.stderr}")
    return r.stdout


def write(path, text, mode="w"):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if "b" in mode:
        with open(path, mode) as f:
            f.write(text)
    else:
        with open(path, mode, encoding="utf-8", newline="") as f:
            f.write(text)


class ScanTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.remote = os.path.join(self.tmp.name, "remote.git")
        self.work = os.path.join(self.tmp.name, "work")
        git(self.tmp.name, "init", "-q", "--bare", "-b", "main", self.remote)
        git(self.tmp.name, "clone", "-q", self.remote, self.work)
        git(self.work, "checkout", "-q", "-b", "main")
        write(os.path.join(self.work, "README.md"), "# demo\n")
        git(self.work, "add", "-A")
        git(self.work, "commit", "-q", "-m", "chore: start")
        git(self.work, "push", "-q", "-u", "origin", "main")
        git(self.work, "remote", "set-head", "origin", "main")

    def scan(self, *args, cwd=None):
        r = subprocess.run([sys.executable, SCRIPT, "--json", *args], cwd=cwd or self.work,
                           capture_output=True, text=True, env=ENV, encoding="utf-8",
                           errors="replace")
        return r, (json.loads(r.stdout) if r.stdout.strip() else None)

    def branch(self, name="feature/x"):
        git(self.work, "checkout", "-q", "-b", name)

    def commit(self, rel, text, who="Test Dev", msg="feat: change"):
        write(os.path.join(self.work, rel), text)
        git(self.work, "add", "-A")
        git(self.work, "-c", f"user.name={who}", "commit", "-q", "--author",
            f"{who} <dev@example.invalid>", "-m", msg)

    def test_clean_default_branch(self):
        r, d = self.scan()
        self.assertEqual(r.returncode, 0)
        self.assertTrue(d["onDefaultBranch"])
        self.assertEqual((d["ahead"], d["behind"], d["changedFiles"]), (0, 0, 0))
        self.assertEqual(d["defaultRef"], "origin/main")
        self.assertEqual({k: v for k, v in d["hygiene"].items() if v}, {})

    def test_work_branch_counts_authors_and_every_kind_of_change(self):
        self.branch()
        self.commit("src/a.txt", "one\n", who="Other Dev")
        self.commit("src/b.txt", "two\n", who="Test Dev")
        write(os.path.join(self.work, "README.md"), "# demo\nedited\n")
        write(os.path.join(self.work, "docs/new.md"), "new\n")
        r, d = self.scan()
        self.assertFalse(d["onDefaultBranch"])
        self.assertEqual(d["ahead"], 2)
        self.assertEqual(d["commitsByAuthor"], {"Other Dev": 1, "Test Dev": 1})
        self.assertEqual(sorted(d["changed"]),
                         ["README.md", "docs/new.md", "src/a.txt", "src/b.txt"])
        self.assertEqual(sorted(d["uncommittedFiles"]), ["README.md", "docs/new.md"])
        self.assertEqual(d["untrackedFiles"], ["docs/new.md"])

    def test_staged_changes_count_as_changed(self):
        self.branch()
        write(os.path.join(self.work, "s.txt"), "staged\n")
        git(self.work, "add", "s.txt")
        _, d = self.scan()
        self.assertIn("s.txt", d["changed"])

    def test_behind_is_reported(self):
        other = os.path.join(self.tmp.name, "other")
        git(self.tmp.name, "clone", "-q", self.remote, other)
        write(os.path.join(other, "later.txt"), "later\n")
        git(other, "add", "-A")
        git(other, "commit", "-q", "-m", "chore: later")
        git(other, "push", "-q", "origin", "main")
        git(self.work, "fetch", "-q")
        self.branch()
        _, d = self.scan()
        self.assertEqual(d["behind"], 1)

    def test_conflict_marker_is_found_and_strict_fails(self):
        self.branch()
        self.commit("src/m.txt", "ok\n<<<<<<< HEAD\nmine\n")
        r, d = self.scan()
        self.assertEqual(d["hygiene"]["conflictMarkers"], [{"file": "src/m.txt", "line": 2}])
        self.assertEqual(self.scan("--strict")[0].returncode, 1)

    def test_a_markdown_rule_is_not_a_conflict(self):
        self.branch()
        self.commit("notes.md", "Title\n=======\n")
        _, d = self.scan()
        self.assertEqual(d["hygiene"]["conflictMarkers"], [])

    def test_secret_is_located_and_never_printed(self):
        self.branch()
        value = "AK" + "IA" + "A" * 16  # built here so no secret-looking literal is in the repo
        self.commit("src/c.txt", f"key = {value}\n")
        write(os.path.join(self.work, "src/u.txt"), f"token: {value}\n")  # untracked too
        r = subprocess.run([sys.executable, SCRIPT], cwd=self.work, capture_output=True, text=True,
                           env=ENV, encoding="utf-8", errors="replace")
        self.assertNotIn(value, r.stdout)
        _, d = self.scan()
        kinds = {(h["file"], h["kind"]) for h in d["hygiene"]["secrets"]}
        self.assertEqual(kinds, {("src/c.txt", "aws-access-key"), ("src/u.txt", "aws-access-key")})
        self.assertNotIn(value, json.dumps(d))
        self.assertEqual(self.scan("--strict")[0].returncode, 1)

    def test_sensitive_file_names(self):
        self.branch()
        self.commit(".env", "A=1\n")
        self.commit(".env.example", "A=\n")
        self.commit("certs/server.pem", "x\n")
        _, d = self.scan()
        self.assertEqual(sorted(d["hygiene"]["sensitivePaths"]), [".env", "certs/server.pem"])

    def test_debug_and_focus_leftovers_but_not_in_docs(self):
        self.branch()
        self.commit("test/a.js", "it.only('x', () => {});\n")
        self.commit("docs/a.md", "use it.only( to focus\n")
        _, d = self.scan()
        self.assertEqual(d["hygiene"]["leftovers"], [{"file": "test/a.js", "line": 1}])

    def test_large_file_is_flagged(self):
        self.branch()
        write(os.path.join(self.work, "big.bin"), b"\0" * 6_000_000, mode="wb")
        _, d = self.scan()
        self.assertEqual([b["file"] for b in d["hygiene"]["bigFiles"]], ["big.bin"])

    def test_explicit_base(self):
        self.branch()
        self.commit("a.txt", "a\n")
        _, d = self.scan("--base", "HEAD~1")
        self.assertEqual(d["ahead"], 1)

    def test_text_output_is_short_and_has_the_headlines(self):
        self.branch()
        self.commit("a.txt", "a\n", who="Other Dev")
        r = subprocess.run([sys.executable, SCRIPT], cwd=self.work, capture_output=True, text=True,
                           env=ENV, encoding="utf-8", errors="replace")
        self.assertEqual(r.returncode, 0)
        for needle in ("branch   : feature/x", "1 ahead, 0 behind", "Other Dev: 1",
                       "hygiene  : nothing found"):
            self.assertIn(needle, r.stdout)
        self.assertLess(len(r.stdout.splitlines()), 20)

    def _build(self, name, age_seconds):
        """A build output file whose modified time is `age_seconds` in the past."""
        path = os.path.join(self.tmp.name, name)
        write(path, "built\n")
        t = os.path.getmtime(os.path.join(self.work, "README.md")) - age_seconds
        os.utime(path, (t, t))
        return path

    def _freshness(self, build):
        r = subprocess.run([sys.executable, SCRIPT, "--build", build], cwd=self.work,
                           capture_output=True, text=True, env=ENV, encoding="utf-8",
                           errors="replace")
        return r.returncode, r.stdout

    def test_build_older_than_a_source_file_is_stale(self):
        self.commit("src/app.txt", "code\n")
        code, out = self._freshness(self._build("old.bin", 3600))
        self.assertEqual(code, 1)
        self.assertIn("STALE", out)
        self.assertIn("src/app.txt", out)

    def test_build_newer_than_every_source_is_fresh(self):
        self.commit("src/app.txt", "code\n")
        path = os.path.join(self.tmp.name, "new.bin")
        write(path, "built\n")
        future = os.path.getmtime(os.path.join(self.work, "src/app.txt")) + 60
        os.utime(path, (future, future))
        code, out = self._freshness(path)
        self.assertEqual(code, 0)
        self.assertIn("FRESH", out)

    def test_docs_and_tests_do_not_make_a_build_stale(self):
        build = self._build("b.bin", 0)
        later = os.path.getmtime(build) + 120
        for rel in ("docs/guide.md", "tests/a_test.txt"):
            write(os.path.join(self.work, rel), "x\n")
            os.utime(os.path.join(self.work, rel), (later, later))
        code, out = self._freshness(build)
        self.assertEqual(code, 0, out)

    def test_a_build_folder_is_judged_by_its_newest_file(self):
        self.commit("src/app.txt", "code\n")
        folder = os.path.join(self.tmp.name, "out")
        stale = os.path.join(folder, "a.bin")
        write(stale, "x\n")
        old = os.path.getmtime(os.path.join(self.work, "src/app.txt")) - 3600
        os.utime(stale, (old, old))
        self.assertEqual(self._freshness(folder)[0], 1)
        newer = os.path.join(folder, "b.bin")
        write(newer, "x\n")
        future = os.path.getmtime(os.path.join(self.work, "src/app.txt")) + 60
        os.utime(newer, (future, future))
        self.assertEqual(self._freshness(folder)[0], 0)

    def test_missing_build_is_exit_2(self):
        code, out = self._freshness(os.path.join(self.tmp.name, "nope"))
        self.assertEqual(code, 2)
        self.assertIn("no build found", out)

    def test_not_a_repo_and_no_base_exit_2(self):
        empty = tempfile.TemporaryDirectory()
        self.addCleanup(empty.cleanup)
        r, _ = self.scan(cwd=empty.name)
        self.assertEqual(r.returncode, 2)
        lone = os.path.join(self.tmp.name, "lone")
        os.makedirs(lone)
        git(lone, "init", "-q", "-b", "trunk")
        write(os.path.join(lone, "a.txt"), "a\n")
        git(lone, "add", "-A")
        git(lone, "commit", "-q", "-m", "chore: a")
        r, _ = self.scan(cwd=lone)
        self.assertEqual(r.returncode, 2)
        self.assertIn("no base", r.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
