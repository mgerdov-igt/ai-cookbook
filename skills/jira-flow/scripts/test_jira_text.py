"""Offline tests for jira_text.py:  python3 -m unittest discover -s <scripts dir> -p "test_*.py" """
import io
import os
import sys
import unittest
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jira_text as jt  # noqa: E402


class MdToWiki(unittest.TestCase):
    def test_blocks(self):
        md = "# Title\n## Sub\n- a\n  - b\n1. one\n> quote\n---"
        self.assertEqual(jt.md_to_wiki(md), "h1. Title\nh2. Sub\n* a\n** b\n# one\nbq. quote\n----")

    def test_inline(self):
        self.assertEqual(jt.md_to_wiki("**bold** and *it* and `x{y}` and [PR #5](https://g/h/5)"),
                         "*bold* and _it_ and {{x{y}}} and [PR #5|https://g/h/5]")

    def test_braces_escaped_outside_code(self):
        self.assertEqual(jt.md_to_wiki("map {a}"), r"map \{a\}")

    def test_table(self):
        md = "| AC | Evidence |\n|---|---|\n| AC1 | `a_test.dart` |"
        self.assertEqual(jt.md_to_wiki(md), "||AC||Evidence||\n|AC1|{{a_test.dart}}|")

    def test_code_fence_untouched(self):
        md = "```dart\nfinal x = {**a};\n```"
        self.assertEqual(jt.md_to_wiki(md), "{code:dart}\nfinal x = {**a};\n{code}")


class Markers(unittest.TestCase):
    def setUp(self):
        self.cs = [
            {"id": "1", "author": {"name": "ME"}, "created": "2026-10-01T10:00", "updated": "2026-10-02T10:00",
             "body": "Q1?\n" + jt.marker_footer("questions")},
            {"id": "2", "author": {"name": "PO"}, "created": "2026-10-01T11:00", "body": "A1"},
            {"id": "3", "author": {"name": "OTHER"}, "created": "2026-10-01T12:00", "body": "x " + jt.marker_footer("plan")},
            {"id": "4", "author": {"name": "ME"}, "created": "2026-10-03T10:00", "updated": "2026-10-03T10:00",
             "body": "plan " + jt.marker_footer("plan")},
            {"id": "5", "author": {"name": "PO"}, "created": "2026-10-03T11:00", "body": "Approved, go."},
        ]

    def test_find_own_marker_only(self):
        self.assertEqual(jt.find_marked(self.cs, "plan", "ME")["id"], "4")
        self.assertIsNone(jt.find_marked(self.cs, "plan", "NOBODY"))

    def test_replies_and_approval(self):
        q = jt.find_marked(self.cs, "questions", "ME")
        self.assertEqual([c["id"] for c in jt.replies_after(self.cs, q, "ME")], ["2", "5"])
        p = jt.find_marked(self.cs, "plan", "ME")
        reps = jt.replies_after(self.cs, p, "ME", "updated")
        self.assertEqual([c["id"] for c in reps], ["5"])
        self.assertTrue(jt.APPROVAL_RE.match(reps[0]["body"]))
        self.assertFalse(jt.APPROVAL_RE.match("not approved yet"))


class Token(unittest.TestCase):
    def test_same_line_label(self):
        self.assertEqual(jt.token_from_text("x\n##### My JIRA access:\nJira url: https://j/\nai-jira-token: ABC123\n"), "ABC123")

    def test_label_then_next_line(self):
        self.assertEqual(jt.token_from_text("##### My JIRA access token:\nXYZ789\n"), "XYZ789")

    def test_missing(self):
        self.assertIsNone(jt.token_from_text("nothing here"))


def _t(name, to, **fields):
    return {"id": name, "name": name, "to": {"name": to}, "fields": fields}


class Walk(unittest.TestCase):
    path = ["Opened", "Reopened", "Assigned", "In Progress", "Resolved", "Ready for Dev Integration", "Ready for QA Test"]

    def test_picks_nearest_forward(self):
        ts = [_t("Close", "Closed"), _t("Resolve", "Resolved"), _t("Start", "In Progress")]
        t, _ = jt.choose_transition(ts, self.path, "Assigned", "Ready for QA Test")
        self.assertEqual(t["name"], "Start")

    def test_never_and_overshoot(self):
        ts = [_t("Fwd", "Ready for QA Test")]
        self.assertIsNone(jt.choose_transition(ts, self.path, "In Progress", "Resolved")[0])
        self.assertIsNone(jt.choose_transition(ts, self.path, "In Progress", "Ready for QA Test", ["Ready for QA Test"])[0])
        self.assertIsNone(jt.choose_transition([_t("Close it", "Resolved")], self.path, "In Progress",
                                               "Resolved", ["close*"])[0])
        self.assertTrue(jt.is_banned("Closed, No Fix", ["Closed*"]))
        self.assertFalse(jt.is_banned("Reopened", ["Closed*"]))

    def test_already_there_or_past(self):
        self.assertEqual(jt.choose_transition([], self.path, "Resolved", "Resolved")[1], "already there")
        self.assertTrue(jt.choose_transition([], self.path, "Ready for QA Test", "Resolved")[1].startswith("already past"))

    def test_off_path(self):
        self.assertIn("off the configured path", jt.choose_transition([], self.path, "Defer", "Resolved")[1])

    def test_missing_required(self):
        t = _t("Resolve", "Resolved", customfield_1={"name": "Resolution Description", "required": True},
               resolution={"name": "Resolution", "required": True, "hasDefaultValue": True},
               customfield_2={"name": "Notes", "required": False})
        self.assertEqual(jt.missing_required(t, {}), ["Resolution Description"])
        self.assertEqual(jt.missing_required(t, {"resolution description": "x"}), [])

    def test_coerce(self):
        self.assertEqual(jt.coerce({"schema": {"type": "option"}}, "Code"), {"value": "Code"})
        self.assertEqual(jt.coerce({"schema": {"type": "resolution"}}, "Fixed"), {"name": "Fixed"})
        self.assertEqual(jt.coerce({"schema": {"type": "array", "items": "version"}}, "SM09"), [{"name": "SM09"}])
        self.assertEqual(jt.coerce({"schema": {"type": "string"}}, "text"), "text")
        self.assertEqual(jt.coerce({"schema": {"type": "number"}}, "5"), 5)

    def test_profile_regex(self):
        profs = {"story": {"issue_types": ["Story"]}, "defect": {"issue_types": ["Bug", "re:^TIR\\b"]}}
        self.assertEqual(jt.profile_for("TIR - BTC", profs)[0], "defect")
        self.assertEqual(jt.profile_for("story", profs)[0], "story")
        self.assertIsNone(jt.profile_for("Epic", profs)[0])


class Logs(unittest.TestCase):
    LOG = [
        "00:09:59.100 INFO boot",
        "00:10:05.000 ERROR credit device 17 unavailable",
        "java.lang.IllegalStateException: no device",
        "\tat a.b.C.run(C.java:10)",
        "\tat a.b.D.go(D.java:20)",
        "00:10:06.000 INFO retry",
        "00:10:07.000 ERROR credit device 18 unavailable",
        "00:15:00.000 WARN slow response 250ms",
        "00:25:00.000 ERROR outside window",
        "00:26:00.000 INFO done",
    ]

    def test_dedup_and_trace(self):
        r = jt.reduce_log(self.LOG)
        self.assertIn("x2", r)  # two 'credit device N unavailable' collapse
        self.assertIn("at a.b.D.go", r)
        self.assertIn("time span: 00:09:59 .. 00:26:00", r)

    def test_window(self):
        r = jt.reduce_log(self.LOG, jt.parse_window("00:10-00:20"))
        self.assertNotIn("outside window", r.split("--- problems")[1])
        self.assertIn("WARN=1", r)

    def test_cap(self):
        many = ["00:00:%02d ERROR unique problem %s" % (i % 60, chr(65 + i % 26) * (i + 1)) for i in range(300)]
        r = jt.reduce_log(many, max_lines=60)
        self.assertLessEqual(len(r.splitlines()), 62)
        self.assertIn("more signatures not shown", r)

    def test_bad_window(self):
        with self.assertRaises(ValueError):
            jt.parse_window("10 to 20")

    def test_long_lines_clipped(self):
        r = jt.reduce_log(["00:00:01 INFO a", "00:00:02 ERROR " + "x" * 5000], max_width=100)
        self.assertLess(len(r), 1000)
        self.assertIn("...[+", r)


class Office(unittest.TestCase):
    def test_xlsx(self):
        buf = io.BytesIO()
        with zipfile.ZipFile(buf, "w") as z:
            z.writestr("xl/sharedStrings.xml",
                       '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
                       "<si><t>Step</t></si><si><t>Result</t></si></sst>")
            z.writestr("xl/worksheets/sheet1.xml",
                       '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>'
                       '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c></row>'
                       '<row r="2"><c r="A2"><v>1</v></c><c r="C2" t="inlineStr"><is><t>fail</t></is></c></row>'
                       "</sheetData></worksheet>")
        self.assertEqual(jt.xlsx_preview(buf.getvalue()), "## sheet1.xml\nStep,Result\n1,,fail\n")

    def test_text_names(self):
        self.assertTrue(jt.is_text_name("GT28 - Betslip reader app.log"))
        self.assertTrue(jt.is_text_name("app.log.3"))
        self.assertFalse(jt.is_text_name("credit device.png"))


if __name__ == "__main__":
    unittest.main()
