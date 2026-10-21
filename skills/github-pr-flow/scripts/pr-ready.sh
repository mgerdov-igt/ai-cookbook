#!/usr/bin/env bash
# One-shot "is this PR ready?" check for a human or a script. It is a thin wrapper
# over pr-watch.sh, so there is a single implementation of the readiness rules
# (open threads, branch state, required checks on the current tip, review bot).
#
#   pr-ready.sh <pr>      exit 0 = READY (this poll), 1 = NOT READY
#
# One clean poll is not enough to merge: pr-merge.sh does the two polls 30 seconds
# apart and the merge. To wait, use `pr-watch.sh --loop`.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pr="${1:?usage: pr-ready.sh <pr>}"

bash "$SCRIPT_DIR/pr-watch.sh" "$pr"; rc=$?
decision="$(gh pr view "$pr" --json reviewDecision --jq '.reviewDecision // ""' 2>/dev/null || true)"
[ "$decision" = "CHANGES_REQUESTED" ] && { echo "NOT READY: reviewDecision=CHANGES_REQUESTED"; exit 1; }
if [ "$rc" -eq 0 ]; then echo "READY (this poll), reviewDecision=${decision:-none}"; exit 0; fi
echo "NOT READY (pr-watch exit $rc)"; exit 1
