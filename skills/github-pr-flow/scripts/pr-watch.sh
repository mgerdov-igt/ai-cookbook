#!/usr/bin/env bash
# One poll of a PR, in the only order that is allowed:
#
#   1. unresolved review threads  (a thread beats CI: never wait on CI with one open)
#   2. branch state              (BEHIND is updated, DIRTY is reported)
#   3. CI checks                 (pending, failed, or complete on the current tip)
#
# Print one status line per poll and exit with a code the caller acts on. A
# wait loop built on this script cannot skip the thread check, because the
# check is the first thing it does.
#
#   tools/pr-review/pr-watch.sh <pr-number>
#
# Loop it every 30 seconds (see "Poll loop" below). Never write a wait loop that
# reads only CI status.
#
# Exit codes:
#   10  THREADS    unresolved review threads exist. ACT NOW: cancel this PR's
#                  in-flight CI (pr-watch.sh --cancel-ci <pr>), then fix, reply,
#                  resolve, push. Do not wait for CI.
#   11  BEHIND     the branch was behind its base and has just been updated; CI
#                  restarts on the new tip. Keep polling.
#   12  DIRTY      merge conflict with the base. Resolve in the PR's worktree.
#   13  CI_FAILED  a required check failed on the current tip. Read the log, fix.
#   14  CI_PENDING checks are missing or still running. Keep polling, and keep
#                  fetching threads every poll (this script does it for you).
#   15  UNKNOWN    GitHub has not settled the merge state. Poll again.
#   0   CLEAN      no open threads, not behind, every required check exists and
#                  passed on the current tip. This is ONE clean poll. A merge needs
#                  two such polls at least 30 seconds apart.
#   17  TIMEOUT    --loop only: nothing to act on yet and PR_WATCH_MAX_SECS (default 540,
#                  under the usual 10-minute tool limit) elapsed. Call --loop again.
#   16  PARK       review threads are open at or after the round limit (PR_ROUND_LIMIT bot
#                  reviews, default 4). Do NOT fix them and do NOT cancel CI: document each as a known issue
#                  (docs/backlog/<topic>-known-issues.md), push that one doc commit, reply with the link, resolve
#                  the thread, then merge on green CI after two clean polls. A PR that
#                  never converges is merged with its findings parked, not held forever.
#   1   error      usage error or a gh/API failure.
#
# Other forms:
#   pr-watch.sh --cancel-ci <pr>   cancel queued/running CI runs for the PR's current
#                                  head commit. Never touches other branches' runs
#                                  or the review bot's own run.
#   pr-watch.sh --loop <pr>        poll every 30s until there is something to act on.
#                                  Prints a line only when the status CHANGES (a quiet
#                                  wait costs almost no tokens). Cancels stale CI by
#                                  itself when threads appear, then returns 10. Returns
#                                  17 after PR_WATCH_MAX_SECS so the caller's tool call
#                                  never times out: just call it again.
#
# CLEAN also requires that the review bot has looked at the current tip, or that
# PR_BOT_WAIT_SECS (default 600; 0 disables) have passed since the tip was committed.
# Without this a fast CI can report CLEAN before the bot has posted its first review.
#
# Needs only `gh` (no python).
set -uo pipefail

# Round limit (see exit code 16). A round is one submitted review by the review bot.
ROUND_LIMIT="${PR_ROUND_LIMIT:-4}"
REVIEW_BOT="${PR_REVIEW_BOT:-copilot-pull-request-reviewer}"
BOT_WAIT_SECS="${PR_BOT_WAIT_SECS:-600}"

_REPO_NWO=""
repo_nwo() {
  [ -n "$_REPO_NWO" ] || _REPO_NWO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)" || return 1
  printf '%s\n' "$_REPO_NWO"
}

command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }

cancel_ci() {
  local pr="$1" head branch runs id rc=0
  # Isolate this PR's runs by head branch AND head commit: another branch can
  # point at the same SHA, and its runs must never be cancelled.
  head="$(gh pr view "$pr" --json headRefOid --jq .headRefOid)" || return 1
  branch="$(gh pr view "$pr" --json headRefName --jq .headRefName)" || return 1
  # Queued or in-progress runs only. Skip workflows whose name suggests the
  # review bot (Copilot), so its scan is never killed.
  runs="$(gh run list --branch "$branch" --commit "$head" --json databaseId,status,workflowName \
    --jq '.[]|select(.status=="queued" or .status=="in_progress")|select(.workflowName|test("copilot|review";"i")|not)|.databaseId')" || return 1
  for id in $runs; do
    if gh run cancel "$id" >/dev/null; then
      echo "cancelled CI run $id"
    else
      echo "could not cancel CI run $id (permission or already finished)" >&2
      rc=1
    fi
  done
  return "$rc"
}

unresolved_count() {
  local pr="$1" repo owner name cursor out total=0 page
  repo="$(repo_nwo)" || return 1
  owner="${repo%%/*}"; name="${repo##*/}"
  cursor=""
  while :; do
    out="$(gh api graphql -f query='
query($o:String!,$r:String!,$n:Int!,$c:String){repository(owner:$o,name:$r){pullRequest(number:$n){
 reviewThreads(first:100,after:$c){pageInfo{hasNextPage endCursor} nodes{isResolved}}}}}' \
      -f o="$owner" -f r="$name" -F n="$pr" ${cursor:+-f c="$cursor"} \
      --jq '.data.repository.pullRequest.reviewThreads | ([.nodes[]|select(.isResolved|not)]|length|tostring) + " " + (.pageInfo.hasNextPage|tostring) + " " + (.pageInfo.endCursor // "-")')" || return 1
    set -- $out
    page="$1"; total=$((total + page))
    [ "$2" = "true" ] || break
    cursor="$3"
  done
  echo "$total"
}

# Line 1: the PR head commit. Line 2: "total<TAB>pending<TAB>failed". Line 3+: one
# normalized result per check, sorted, so two snapshots compare with plain text.
ci_snapshot() {
  local pr="$1"
  gh pr view "$pr" --json headRefOid,statusCheckRollup --jq '
    .headRefOid,
    ([.statusCheckRollup[] |
      if .__typename == "StatusContext" then
        {name: .context, done: (.state != "PENDING" and .state != "EXPECTED"), ok: (.state == "SUCCESS")}
      else
        {name: .name, done: (.status == "COMPLETED"), ok: (.conclusion == "SUCCESS" or .conclusion == "NEUTRAL" or .conclusion == "SKIPPED")}
      end
    ] as $c |
      ([$c|length, ([$c[]|select(.done|not)]|length), ([$c[]|select(.done and (.ok|not))]|length)] | @tsv),
      ($c | sort_by(.name) | .[] | "\(.name) done=\(.done) ok=\(.ok)"))'
}

# Number of review rounds the review bot has made on the PR: each submitted bot
# review is one round. The bot login can be overridden with PR_REVIEW_BOT.
review_rounds() {
  local pr="$1" repo bot out
  repo="$(repo_nwo)" || return 1
  # The bot login is compared literally (not as a pattern), case-insensitively,
  # and with the optional "[bot]" suffix ignored on both sides, so an override
  # such as renovate[bot] or renovate both match.
  bot="$(printf '%s' "$REVIEW_BOT" | tr 'A-Z' 'a-z' | sed 's/\[bot\]$//')"
  # One count per page (the reviews API is paginated). The calls are captured
  # first so a failed call is an error, never "zero rounds".
  out="$(gh api --paginate "repos/$repo/pulls/$pr/reviews" \
    --jq "[.[]|select((.user.login|ascii_downcase|rtrimstr(\"[bot]\")) == \"$bot\")]|length")" || return 1
  printf '%s\n' "$out" | awk '{n+=$1} END{print n+0}'
}

# Prints nothing and returns 0 when the review bot has reviewed commit $2, or when
# the tip is older than BOT_WAIT_SECS (the bot is not coming). Otherwise prints
# the tip's age in seconds and returns 1.
bot_pending() {
  local pr="$1" head="$2" repo bot out n age
  [ "$BOT_WAIT_SECS" -gt 0 ] 2>/dev/null || return 0
  repo="$(repo_nwo)" || return 0
  bot="$(printf '%s' "$REVIEW_BOT" | tr 'A-Z' 'a-z' | sed 's/\[bot\]$//')"
  out="$(gh api --paginate "repos/$repo/pulls/$pr/reviews" \
    --jq "[.[]|select((.user.login|ascii_downcase|rtrimstr(\"[bot]\")) == \"$bot\" and .commit_id == \"$head\")]|length")" || return 0
  n="$(printf '%s\n' "$out" | awk '{n+=$1} END{print n+0}')"
  [ "$n" -gt 0 ] && return 0
  age="$(gh api "repos/$repo/commits/$head" --jq '(now - (.commit.committer.date|fromdate))|floor')" || return 0
  case "$age" in ""|*[!0-9]*) return 0 ;; esac
  [ "$age" -ge "$BOT_WAIT_SECS" ] && return 0
  echo "$age"
  return 1
}

poll() {

  local pr="$1" threads state behind n pend fail snap snap2 head1 head2 rounds
  # 1. threads first
  threads="$(unresolved_count "$pr")" || { echo "#$pr: cannot read review threads" >&2; return 1; }
  if [ "$threads" -gt 0 ]; then
    rounds="$(review_rounds "$pr")" || { echo "#$pr: cannot read review rounds" >&2; return 1; }
    # Round limit: after PR_ROUND_LIMIT bot reviews, new findings are not fixed.
    # They are parked as known issues and the PR merges on green CI.
    if [ "$rounds" -ge "$ROUND_LIMIT" ]; then
      echo "#$pr threads=$threads round=$rounds/$ROUND_LIMIT -> PARK: round limit reached. Document each open thread as a known issue (docs/backlog), reply with the link, resolve, then merge on green CI. Do not fix more."
      return 16
    fi
    echo "#$pr threads=$threads round=$rounds/$ROUND_LIMIT -> THREADS: stop waiting on CI, cancel it and resolve the threads now"
    return 10
  fi
  # 2. branch state. Ancestry comes from the compare API (--behind-by), not from
  # mergeStateStatus: BLOCKED or CLEAN can both hide a stale branch.
  state="$(gh pr view "$pr" --json state,mergeStateStatus --jq '.state+" "+.mergeStateStatus')" \
    || { echo "#$pr: cannot read the PR" >&2; return 1; }
  case "$state" in MERGED*|CLOSED*) echo "#$pr threads=0 ${state%% *}"; return 0 ;; esac
  case "${state#OPEN }" in
    DIRTY) echo "#$pr threads=0 DIRTY -> merge conflict, resolve in the worktree"; return 12 ;;
    UNKNOWN) echo "#$pr threads=0 merge state UNKNOWN -> poll again"; return 15 ;;
  esac
  behind="$(bash "$(dirname "${BASH_SOURCE[0]}")/pr-update-branch.sh" "$pr" --behind-by)" \
    || { echo "#$pr: cannot compare the branch with its base" >&2; return 1; }
  case "$behind" in ""|*[!0-9]*) echo "#$pr: unexpected --behind-by answer: $behind" >&2; return 1 ;; esac
  if [ "$behind" != "0" ]; then
    if bash "$(dirname "${BASH_SOURCE[0]}")/pr-update-branch.sh" "$pr" >/dev/null 2>&1; then
      echo "#$pr threads=0 behind=$behind -> base merged in; CI restarts on the new tip"; return 11
    fi
    echo "#$pr threads=0 behind=$behind -> update failed" >&2; return 1
  fi
  # 3. CI on the current tip. The rollup mixes CheckRun entries (status +
  # conclusion) and StatusContext entries (state). Normalize both:
  #   pending = not finished; failed = finished and not SUCCESS/NEUTRAL/SKIPPED.
  # Anything unknown counts as failed, never as passing.
  snap="$(ci_snapshot "$pr")" || { echo "#$pr: cannot read checks" >&2; return 1; }
  head1="$(echo "$snap" | sed -n 1p)"; n="$(echo "$snap" | sed -n 2p | cut -f1)"
  pend="$(echo "$snap" | sed -n 2p | cut -f2)"; fail="$(echo "$snap" | sed -n 2p | cut -f3)"
  if [ "$fail" -gt 0 ]; then echo "#$pr threads=0 checks=$n failed=$fail -> CI_FAILED"; return 13; fi
  if [ "$n" -eq 0 ] || [ "$pend" -gt 0 ]; then
    echo "#$pr threads=0 checks=$n pending=$pend -> CI_PENDING (an empty list is not green)"; return 14
  fi
  # The list can be partial for a moment after a push (a bot's check is
  # published before the CI jobs are). The required checks are not readable
  # through the API on every repo, so take a second full snapshot a few seconds
  # later: the head commit, the check count and every result must be identical.
  sleep 8
  snap2="$(ci_snapshot "$pr")" || { echo "#$pr: cannot read checks" >&2; return 1; }
  if [ "$snap" != "$snap2" ]; then
    echo "#$pr threads=0 -> CI_PENDING (the head or the check list changed during the poll)"; return 14
  fi
  # Identical snapshots do not prove the required jobs exist (a bot's check can
  # be the only entry while CI never starts). Ask for the required checks by
  # name and insist every one is present and passing. If the required set
  # cannot be established, stay pending (PR_WATCH_ALLOW_NO_REQUIRED=1 accepts
  # an empty set on a repo that has no required checks).
  local req req_n req_bad
  req="$(gh pr checks "$pr" --required --json name,bucket --jq '[length, ([.[]|select(.bucket != "pass" and .bucket != "skipping")]|length)]|@tsv' 2>/dev/null)" \
    || req=""
  req_n="$(echo "$req" | cut -f1)"; req_bad="$(echo "$req" | cut -f2)"
  case "$req_n$req_bad" in ""|*[!0-9]*) echo "#$pr threads=0 -> CI_PENDING (cannot read the required checks)"; return 14 ;; esac
  if [ "$req_n" -eq 0 ] && [ "${PR_WATCH_ALLOW_NO_REQUIRED:-0}" != "1" ]; then
    echo "#$pr threads=0 -> CI_PENDING (no required check is reported yet; set PR_WATCH_ALLOW_NO_REQUIRED=1 if this repo has none)"; return 14
  fi
  if [ "$req_bad" -gt 0 ]; then
    echo "#$pr threads=0 -> CI_PENDING ($req_bad of $req_n required checks are not passing)"; return 14
  fi
  # Ancestry again, last: another PR may have merged into the base while the
  # snapshots were being taken. A branch that is behind now is not CLEAN.
  behind="$(bash "$(dirname "${BASH_SOURCE[0]}")/pr-update-branch.sh" "$pr" --behind-by)" \
    || { echo "#$pr: cannot compare the branch with its base" >&2; return 1; }
  case "$behind" in ""|*[!0-9]*) echo "#$pr: unexpected --behind-by answer: $behind" >&2; return 1 ;; esac
  if [ "$behind" != "0" ]; then
    echo "#$pr threads=0 behind=$behind -> CI_PENDING (the base moved during the poll; poll again to update the branch)"; return 14
  fi
  # And the head last of all: a push after the snapshots makes every result above
  # describe a previous commit.
  head2="$(gh pr view "$pr" --json headRefOid --jq .headRefOid)" || { echo "#$pr: cannot read the PR head" >&2; return 1; }
  if [ "$head2" != "$head1" ]; then
    echo "#$pr threads=0 -> CI_PENDING (the head moved to ${head2:0:8} during the poll)"; return 14
  fi
  local bot_age
  if ! bot_age="$(bot_pending "$pr" "$head1")"; then
    echo "#$pr threads=0 -> CI_PENDING (review bot has not reviewed ${head1:0:8} yet; tip is ${bot_age}s old, waiting up to ${BOT_WAIT_SECS}s)"; return 14
  fi
  echo "#$pr threads=0 checks=$n required=$req_n pending=0 failed=0 head=${head1:0:8} -> CLEAN (one clean poll; need two, 30s apart; use pr-merge.sh)"
  return 0
}

case "${1:-}" in
  --cancel-ci) [ $# -eq 2 ] || { echo "usage: pr-watch.sh --cancel-ci <pr>" >&2; exit 1; }; cancel_ci "$2"; exit $? ;;
  --loop)
    [ $# -eq 2 ] || { echo "usage: pr-watch.sh --loop <pr>" >&2; exit 1; }
    deadline=$(( $(date +%s) + ${PR_WATCH_MAX_SECS:-540} )); last=""
    while :; do
      out="$(poll "$2")"; rc=$?
      if [ "$out" != "$last" ] && [ -n "$out" ]; then printf '%s\n' "$out"; last="$out"; fi
      if [ "$rc" -eq 10 ]; then cancel_ci "$2"; exit 10; fi
      # PARK keeps CI running: the park commit (backlog entries) restarts it on the final tip.
      if [ "$rc" -eq 16 ]; then exit 16; fi
      case "$rc" in
        14|11|15)
          if [ "$(date +%s)" -ge "$deadline" ]; then echo "#$2 still waiting -> TIMEOUT: call --loop again"; exit 17; fi
          sleep 30 ;;
        *) exit "$rc" ;;
      esac
    done ;;
  ""|-*) echo "usage: pr-watch.sh <pr> | --cancel-ci <pr> | --loop <pr>" >&2; exit 1 ;;
  *) poll "$1"; exit $? ;;
esac
