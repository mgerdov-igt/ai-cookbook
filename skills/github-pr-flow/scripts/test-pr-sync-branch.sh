#!/usr/bin/env bash
# Self-test for pr-sync-branch.sh. Builds throw-away git repos that reproduce the
# squash-merge drift (a local "origin", a working branch, a PR that lands as ONE new
# commit) and checks what the script does in each case. Needs no GitHub: `gh` is
# replaced by a stub on PATH that answers the three calls the script makes.
#
#   bash test-pr-sync-branch.sh          # prints PASS/FAIL per case, exit 1 on any FAIL
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$here/pr-sync-branch.sh"
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
fails=0; passes=0
ok()   { passes=$((passes+1)); echo "PASS  $1"; }
bad()  { fails=$((fails+1));   echo "FAIL  $1"; shift; [ $# -gt 0 ] && printf '      %s\n' "$@"; }

# ---- a gh stub: default branch main; `pr view N --json state` and `--json commits` ----
mkdir -p "$root/bin"
cat > "$root/bin/gh" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"repo view"*defaultBranchRef*) echo main ;;
  *"pr view"*"--json state"*) cat "$GH_STATE_FILE" ;;
  *"pr view"*"--json commits"*) cat "$GH_COMMITS_FILE" ;;
  *) echo "gh stub: unexpected $*" >&2; exit 1 ;;
esac
EOF
chmod +x "$root/bin/gh"
export PATH="$root/bin:$PATH"
export GH_STATE_FILE="$root/state" GH_COMMITS_FILE="$root/commits"
git_() { git -c user.name=t -c user.email=t@t -c commit.gpgsign=false "$@"; }

# ---- build a scenario -------------------------------------------------------
# main:    A
# develop: A - p1 - p2 [- n1 ...]      (p1,p2 = the PR; n* = newer work)
# the PR lands on origin/main as ONE squash commit S (same content as p1+p2, plus a review fix)
new_repo() { # name newer_count -> sets $R (working clone), $O (bare origin)
  local name=$1 newer=$2
  O="$root/$name-origin.git"; R="$root/$name"; local seed="$root/$name-seed"
  git init -q --bare -b main "$O"
  git init -q -b main "$seed"; cd "$seed"
  echo "a" > a.txt; echo "shared" > shared.txt; git_ add -A; git_ commit -q -m "A base"
  git remote add origin "$O"; git push -q origin main
  git_ checkout -q -b develop
  echo "feature one" > f1.txt; git_ add -A; git_ commit -q -m "feat: one"
  echo "feature two" > f2.txt; git_ add -A; git_ commit -q -m "feat: two"
  for i in $(seq 1 "$newer"); do echo "newer $i" > "n$i.txt"; git_ add -A; git_ commit -q -m "newer $i"; done
  git push -q origin develop
  # the squash on main: both features + a review fix to f2
  git_ checkout -q main
  echo "feature one" > f1.txt; printf 'feature two\nreview fix\n' > f2.txt
  git_ add -A; git_ commit -q -m "feat: one and two (#9)"; git push -q origin main
  git clone -q "$O" "$R"; cd "$R"; git_ checkout -q develop 2>/dev/null || git_ checkout -q -b develop origin/develop
  git config user.name t; git config user.email t@t
  echo OPEN > "$root/state"
  printf 'feat: one\nfeat: two\n' > "$root/commits"
}
run() { (cd "$R" && bash "$SCRIPT" "$@" 2>&1); }
expect_exit() { # name wanted actual output
  if [ "$3" = "$2" ]; then ok "$1"; else bad "$1 (wanted exit $2, got $3)" "$(printf '%s' "$4" | head -4)"; fi
}

# 1. PR not merged -> exit 4, nothing moves
new_repo c1 0; echo OPEN > "$root/state"
before=$(git -C "$R" rev-parse HEAD); out=$(run 9); rc=$?
expect_exit "an open PR is refused (exit 4)" 4 $rc "$out"
[ "$(git -C "$R" rev-parse HEAD)" = "$before" ] && ok "  ...and the branch did not move" || bad "  ...the branch MOVED"

# 2. dirty tree -> exit 3
new_repo c2 0; echo MERGED > "$root/state"; echo x > "$R/untracked.txt"
out=$(run 9); rc=$?; expect_exit "a dirty tree is refused (exit 3)" 3 $rc "$out"
echo "$out" | grep -q untracked.txt && ok "  ...and it names the file" || bad "  ...it did not name the file"

# 3. nothing newer -> reset to main, no merge commit, the squash content wins
new_repo c3 0; echo MERGED > "$root/state"
out=$(run 9); rc=$?; expect_exit "nothing newer: reset (exit 0)" 0 $rc "$out"
[ "$(git -C "$R" rev-parse HEAD)" = "$(git -C "$R" rev-parse origin/main)" ] && ok "  ...develop == origin/main" || bad "  ...develop != origin/main"
grep -q "review fix" "$R/f2.txt" && ok "  ...the review fix from main is there" || bad "  ...the review fix is missing"
[ "$(git -C "$R" rev-list --merges origin/main..HEAD | wc -l)" = 0 ] && ok "  ...no merge commit" || bad "  ...a merge commit appeared"

# 4. newer commits on top -> rebase --onto: only the newer work stays
new_repo c4 2; echo MERGED > "$root/state"
out=$(run 9); rc=$?; expect_exit "newer work: rebase (exit 0)" 0 $rc "$out"
[ "$(git -C "$R" rev-list --count origin/main..HEAD)" = 2 ] && ok "  ...exactly the 2 newer commits are ahead of main" || bad "  ...wrong ahead count: $(git -C "$R" rev-list --count origin/main..HEAD)"
[ "$(git -C "$R" rev-list --count HEAD..origin/main)" = 0 ] && ok "  ...0 behind main" || bad "  ...still behind main"
grep -q "review fix" "$R/f2.txt" && ok "  ...main's review fix kept (not the old copy)" || bad "  ...the old copy of f2 won"
[ -f "$R/n1.txt" ] && [ -f "$R/n2.txt" ] && ok "  ...the newer work is intact" || bad "  ...newer work lost"
[ "$(git -C "$R" log --format=%s origin/main..HEAD | tr '\n' ',')" = "newer 2,newer 1," ] && ok "  ...and only those subjects remain" || bad "  ...unexpected commits ahead"

# 5. --dry-run changes nothing
new_repo c5 2; echo MERGED > "$root/state"; before=$(git -C "$R" rev-parse HEAD)
out=$(run 9 --dry-run); rc=$?; expect_exit "--dry-run (exit 0)" 0 $rc "$out"
[ "$(git -C "$R" rev-parse HEAD)" = "$before" ] && ok "  ...nothing moved" || bad "  ...dry run moved the branch"

# 6. someone else pushed to origin/develop -> refuse, do not erase their commit
new_repo c6 1; echo MERGED > "$root/state"
other="$root/c6-other"; git clone -q "$O" "$other"; (cd "$other" && git_ checkout -q develop && echo theirs > theirs.txt && git_ add -A && git_ commit -q -m "someone else" && git push -q origin develop)
git -C "$R" fetch -q; before=$(git -C "$R" rev-parse HEAD)
out=$(run 9); rc=$?; expect_exit "a teammate's push to origin/develop is refused (exit 3)" 3 $rc "$out"
[ "$(git -C "$R" rev-parse HEAD)" = "$before" ] && ok "  ...nothing moved" || bad "  ...it moved anyway"

# 7. the rebase conflicts -> stops in progress, never picks a side
new_repo c7 1; echo MERGED > "$root/state"
(cd "$R" && printf 'newer touches f2\n' > f2.txt && git_ add -A && git_ commit -q -m "newer edits f2" && git push -q origin develop 2>/dev/null)
out=$(run 9); rc=$?; expect_exit "a rebase conflict stops (exit 6)" 6 $rc "$out"
[ -d "$R/.git/rebase-merge" ] || [ -d "$R/.git/rebase-apply" ] && ok "  ...left in progress for a human" || bad "  ...no rebase in progress"
git -C "$R" rebase --abort 2>/dev/null

# 8. PR commits cannot be matched -> exit 5 (never guesses)
new_repo c8 0; echo MERGED > "$root/state"; printf 'a commit that is not on the branch\n' > "$root/commits"
before=$(git -C "$R" rev-parse HEAD)
out=$(run 9); rc=$?; expect_exit "a PR none of whose commits are on the branch is a no-op (exit 0)" 0 $rc "$out"
[ "$(git -C "$R" rev-parse HEAD)" = "$before" ] && ok "  ...nothing moved" || bad "  ...it moved the branch"

# 9. giving the last shipped commit directly works without gh state
new_repo c9 1; tip=$(git -C "$R" log --format=%H --grep='feat: two' -1)
out=$(run "$tip"); rc=$?; expect_exit "a commit id works instead of a PR number (exit 0)" 0 $rc "$out"
[ "$(git -C "$R" rev-list --count origin/main..HEAD)" = 1 ] && ok "  ...1 newer commit kept" || bad "  ...wrong count"

# 10. --push with a lease: moves origin/develop; a second pusher in between makes it refuse
new_repo c10 1; echo MERGED > "$root/state"
out=$(run 9 --push); rc=$?; expect_exit "--push syncs the remote too (exit 0)" 0 $rc "$out"
[ "$(git -C "$R" rev-parse HEAD)" = "$(git -C "$O" rev-parse develop)" ] && ok "  ...origin/develop == local develop" || bad "  ...remote differs"

# 11. the default branch itself is never rewritten
new_repo c11 0; echo MERGED > "$root/state"; git -C "$R" checkout -q main
out=$(run 9); rc=$?; expect_exit "running on the default branch is refused (exit 3)" 3 $rc "$out"

# 12. GitHub shortens long subjects with "…" in `messageHeadline`: still matches (by prefix)
new_repo c12 1; echo MERGED > "$root/state"
printf 'feat: o…\nfeat: tw…\n' > "$root/commits"
out=$(run 9); rc=$?; expect_exit "shortened PR subjects (ending in an ellipsis) still match (exit 0)" 0 $rc "$out"
[ "$(git -C "$R" rev-list --count origin/main..HEAD)" = 1 ] && ok "  ...1 newer commit kept" || bad "  ...wrong count: $(git -C "$R" rev-list --count origin/main..HEAD)"

# 13. already synced: none of the PR's commits are on the branch -> exit 0, nothing moved
new_repo c13 1; echo MERGED > "$root/state"
run 9 >/dev/null 2>&1                       # first sync does the work
before=$(git -C "$R" rev-parse HEAD)
out=$(run 9); rc=$?; expect_exit "running it again when already synced is a no-op (exit 0)" 0 $rc "$out"
[ "$(git -C "$R" rev-parse HEAD)" = "$before" ] && ok "  ...nothing moved" || bad "  ...the second run moved the branch"
echo "$out" | grep -qi "nothing to do" && ok "  ...and it says so" || bad "  ...it did not say nothing to do"

# 14. a PR whose commits are only PARTLY on the branch is refused, not guessed
new_repo c14 0; echo MERGED > "$root/state"; printf 'feat: one\nfeat: two\nfeat: three\n' > "$root/commits"
out=$(run 9); rc=$?; expect_exit "a PR matched only in part is refused (exit 5)" 5 $rc "$out"

# 15. a local sync (not pushed) followed by a run with --push: the push still happens
new_repo c15 1; echo MERGED > "$root/state"
run 9 >/dev/null 2>&1                                   # local sync only
[ "$(git -C "$R" rev-parse HEAD)" != "$(git -C "$O" rev-parse develop)" ] && ok "after a local-only sync the remote still has the old commits" || bad "the remote was already updated"
out=$(run 9 --push); rc=$?; expect_exit "a second run with --push pushes the earlier local sync (exit 0)" 0 $rc "$out"
[ "$(git -C "$R" rev-parse HEAD)" = "$(git -C "$O" rev-parse develop)" ] && ok "  ...origin/develop == local develop" || bad "  ...the remote was not updated"

# 16. a teammate's commit is STILL refused after our own earlier local sync
new_repo c16 1; echo MERGED > "$root/state"
run 9 >/dev/null 2>&1
other="$root/c16-other"; git clone -q "$O" "$other"; (cd "$other" && git_ checkout -q develop && echo theirs > theirs.txt && git_ add -A && git_ commit -q -m "someone else" && git push -q origin develop)
git -C "$R" fetch -q; before=$(git -C "$R" rev-parse HEAD)
out=$(run 9 --push); rc=$?; expect_exit "a teammate's commit is refused even after our own earlier sync (exit 3)" 3 $rc "$out"
[ "$(git -C "$R" rev-parse HEAD)" = "$before" ] && ok "  ...nothing moved" || bad "  ...it moved"
[ "$(git -C "$O" log -1 --format=%s develop)" = "someone else" ] && ok "  ...and the teammate's commit is still on the remote" || bad "  ...the teammate's commit was ERASED"

echo
echo "$passes passed, $fails failed"
[ "$fails" -eq 0 ]
