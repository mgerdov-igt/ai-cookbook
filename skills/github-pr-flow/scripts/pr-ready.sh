#!/usr/bin/env bash
# Use pr-watch.sh as the poll loop: it checks unresolved review threads FIRST,
# then branch state, then CI, so a wait loop never sits on CI with a thread open.
# This script is the final readiness check, not the loop.
#
# One poll of the merge-readiness checks. Prints a verdict and exits 0
# (ready for this poll) or 1 (not ready). It does not wait or retry; call
# it again after time has passed and after CI completes.
#
# Cadence: poll every 30 SECONDS from the moment you push. Do not wait for
# CI to finish first — review bots re-scan independently of CI, so findings
# land mid-run. If a fix needs a push while CI is in flight, cancel the
# superseded runs for this PR and push; CI restarts on the new commit.
#
#   bash <skill-folder>/scripts/pr-ready.sh <PR-number>
#
# Checks, in order:
#   1. every REAL check-run (not a no-op/neutral placeholder) is successful
#   2. zero unresolved review threads (paginated — see pr-threads.sh)
#   3. mergeable == MERGEABLE, and the branch is not BEHIND or in conflict (a
#      BEHIND branch is updated first through pr-update-branch.sh)
#
# One clean run is not enough. The merge-readiness guide requires two clean
# polls with time between them, including one after CI is green.
# This script checks only the current state. The calling workflow tracks
# how many clean polls have passed and whether one was after CI completed.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

pr=${1:?usage: pr-ready.sh <PR-number>}
read -r owner name < <(repo_owner_name)

# A PR that is BEHIND its base can never pass the merge gate (even --admin is
# refused with a misleading "Waiting on code owner review"). Bring it up to date
# first; the new tip restarts CI, so this poll reports NOT READY.
merge_state=$(gh pr view "$pr" --json mergeStateStatus --jq .mergeStateStatus) || {
  echo "NOT READY — cannot read the merge state"; exit 1; }
# UNKNOWN means GitHub is still computing it. Ask a few times; if it never
# settles, the state is not known, so the PR is not ready.
for _ in 1 2 3 4; do
  [ "$merge_state" = "UNKNOWN" ] || break
  sleep 5
  merge_state=$(gh pr view "$pr" --json mergeStateStatus --jq .mergeStateStatus) || {
    echo "NOT READY — cannot read the merge state"; exit 1; }
done
if [ "$merge_state" = "UNKNOWN" ]; then
  echo "NOT READY — merge state still UNKNOWN (retry later)"
  exit 1
fi
if [ "$merge_state" = "BEHIND" ]; then
  echo "== branch is BEHIND its base: updating =="
  # Run it through bash so it works even when the executable bit was lost
  # (a Windows checkout, a zip copy).
  if bash "$SCRIPT_DIR/pr-update-branch.sh" "$pr"; then
    echo "NOT READY — branch was behind and is updated; CI restarts on the new tip (poll again)"
  else
    echo "NOT READY — branch is behind and the update FAILED (see above); fix that first"
  fi
  exit 1
fi
if [ "$merge_state" = "DIRTY" ]; then
  echo "NOT READY — merge conflict with the base (DIRTY): resolve in the PR worktree, merge the base, push"
  exit 1
fi


echo "== checks =="
checks_ok=0
checks_json=$(gh pr checks "$pr" --json name,state,bucket) || { echo "gh pr checks failed — treating as NOT READY"; checks_json=""; checks_ok=1; }
if [ -n "$checks_json" ]; then
  real_checks=$(echo "$checks_json" | python3 -c "import json,sys; print(sum(1 for c in json.load(sys.stdin) if c.get('bucket') != 'skipping'))")
  if [ "$real_checks" -eq 0 ]; then
    echo "  No real CI checks found."
    checks_ok=1
  else
    echo "$checks_json" | python3 -c "
import json, sys
checks = json.load(sys.stdin)
bad = [c for c in checks if c['bucket'] not in ('pass', 'skipping')]
for c in checks:
    print(f\"  {c['bucket']:10s} {c['name']}\")
sys.exit(1 if bad else 0)
" || checks_ok=1
  fi
else
  echo "  No CI checks returned."
  checks_ok=1
fi

echo "== review threads =="
threads_out=$("$SCRIPT_DIR/pr-threads.sh" "$pr" --json | python3 -c "
import json, sys
nodes = json.load(sys.stdin)
open_ = [n for n in nodes if not n['isResolved']]
for n in open_:
    print(f\"  OPEN {n['id']} {n['path']}:{n.get('line')}\")
print(len(open_))
")
echo "$threads_out" | head -n -1
open_count=$(echo "$threads_out" | tail -1)

echo "== mergeable =="
state_json=$(gh pr view "$pr" --json mergeable,mergeStateStatus,reviewDecision)
echo "$state_json" | python3 -m json.tool
mergeable=$(echo "$state_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['mergeable'])")
review_decision=$(echo "$state_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('reviewDecision') or '')")
final_state=$(echo "$state_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['mergeStateStatus'])")
# The base can move while the checks and threads above are being read, so the
# verdict re-checks the state: a BEHIND or DIRTY branch is never ready, even if
# GitHub still says MERGEABLE.
state_ok=1
case "$final_state" in BEHIND|DIRTY|UNKNOWN) state_ok=0 ;; esac

echo "== verdict =="
if [ "$checks_ok" -eq 0 ] && [ "$open_count" -eq 0 ] && [ "$mergeable" = "MERGEABLE" ] && [ "$state_ok" -eq 1 ] && [ "$review_decision" != "REVIEW_REQUIRED" ] && [ "$review_decision" != "CHANGES_REQUESTED" ]; then
  echo "READY for this poll. Run a second clean poll at least 30s later, including one after CI is green."
  echo "Then merge with the method this repo allows, e.g.:"
  echo "    gh pr merge $pr --squash --delete-branch"
  exit 0
else
  echo "NOT READY — checks_ok=$([ "$checks_ok" -eq 0 ] && echo yes || echo no), open_threads=$open_count, mergeable=$mergeable, review_decision=${review_decision:-none}"
  if [ "$checks_ok" -eq 0 ] && [ "$open_count" -eq 0 ] && [ "$mergeable" = "MERGEABLE" ] && [ "$review_decision" = "REVIEW_REQUIRED" ]; then
    echo
    echo "NOTE: the only thing missing is a human approval. The engineering work is done."
    echo "  * Default: stop here and report who must approve. Do not bypass."
    echo "  * If the user has authorized an admin bypass AND this repo permits one,"
    echo "    finish the job instead of handing the PR back:"
    echo "        gh pr merge $pr --squash --delete-branch --admin"
    echo "    --admin grants nothing; it invokes rights the account already has, and"
    echo "    fails harmlessly otherwise. A 'write' permission level does NOT prove it"
    echo "    will fail -- a ruleset bypass is granted separately from that level, so"
    echo "    do not refuse based on a collaborator-permission reading alone."
    echo "    It is also intermittent: re-confirm clean, then simply retry."
    echo "  * Never approve your own PR -- GitHub blocks that regardless of any flag."
    echo "  See references/MERGE-READINESS.md section 5."
  fi
  exit 1
fi
