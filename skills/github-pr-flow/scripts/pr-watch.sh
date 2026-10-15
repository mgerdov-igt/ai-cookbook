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
#   1   error      usage error or a gh/API failure.
#
# Other forms:
#   pr-watch.sh --cancel-ci <pr>   cancel queued/running CI runs for the PR's current
#                                  head commit. Never touches other branches' runs
#                                  or the review bot's own run.
#   pr-watch.sh --loop <pr>        poll every 30s and print one line per poll until
#                                  the exit code is not 14/11/15 (i.e. until there is
#                                  something to act on). Cancels stale CI by itself
#                                  when threads appear, then returns 10.
#
# Poll loop for a caller that wants its own cadence:
#   while :; do tools/pr-review/pr-watch.sh <pr>; rc=$?; [ $rc -ne 14 ] && [ $rc -ne 11 ] && [ $rc -ne 15 ] && break; sleep 30; done
#
# Needs only `gh` (no python).
set -uo pipefail

command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }

cancel_ci() {
  local pr="$1" head runs id
  head="$(gh pr view "$pr" --json headRefOid --jq .headRefOid)" || return 1
  # Queued or in-progress runs of the PR's own head commit only. Skip runs whose
  # workflow name suggests the review bot (Copilot) so its scan is never killed.
  runs="$(gh run list --commit "$head" --json databaseId,status,workflowName \
    --jq '.[]|select(.status=="queued" or .status=="in_progress")|select(.workflowName|test("copilot|review";"i")|not)|.databaseId')" || return 1
  for id in $runs; do
    gh run cancel "$id" >/dev/null 2>&1 && echo "cancelled CI run $id"
  done
  return 0
}

unresolved_count() {
  local pr="$1" repo owner name cursor out total=0 page
  repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)" || return 1
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

poll() {
  local pr="$1" threads state info n pend fail
  # 1. threads first
  threads="$(unresolved_count "$pr")" || { echo "#$pr: cannot read review threads" >&2; return 1; }
  if [ "$threads" -gt 0 ]; then
    echo "#$pr threads=$threads -> THREADS: stop waiting on CI, cancel it and resolve the threads now"
    return 10
  fi
  # 2. branch state
  state="$(gh pr view "$pr" --json state,mergeStateStatus --jq '.state+" "+.mergeStateStatus')" \
    || { echo "#$pr: cannot read the PR" >&2; return 1; }
  case "$state" in MERGED*|CLOSED*) echo "#$pr threads=0 ${state%% *}"; return 0 ;; esac
  case "${state#OPEN }" in
    BEHIND)
      if bash "$(dirname "${BASH_SOURCE[0]}")/pr-update-branch.sh" "$pr" >/dev/null 2>&1; then
        echo "#$pr threads=0 BEHIND -> base merged in; CI restarts on the new tip"; return 11
      fi
      echo "#$pr threads=0 BEHIND -> update failed" >&2; return 1 ;;
    DIRTY) echo "#$pr threads=0 DIRTY -> merge conflict, resolve in the worktree"; return 12 ;;
    UNKNOWN) echo "#$pr threads=0 merge state UNKNOWN -> poll again"; return 15 ;;
  esac
  # 3. CI on the current tip
  info="$(gh pr view "$pr" --json statusCheckRollup --jq '[(.statusCheckRollup|length), ([.statusCheckRollup[]|select(.status!="COMPLETED")]|length), ([.statusCheckRollup[]|select(.conclusion=="FAILURE" or .conclusion=="CANCELLED" or .conclusion=="TIMED_OUT")]|length)]|@tsv')" \
    || { echo "#$pr: cannot read checks" >&2; return 1; }
  n="$(echo "$info" | cut -f1)"; pend="$(echo "$info" | cut -f2)"; fail="$(echo "$info" | cut -f3)"
  if [ "$fail" -gt 0 ]; then echo "#$pr threads=0 checks=$n failed=$fail -> CI_FAILED"; return 13; fi
  if [ "$n" -eq 0 ] || [ "$pend" -gt 0 ]; then
    echo "#$pr threads=0 checks=$n pending=$pend -> CI_PENDING (an empty list is not green)"; return 14
  fi
  echo "#$pr threads=0 checks=$n pending=0 failed=0 -> CLEAN (one clean poll; need two, 30s apart)"
  return 0
}

case "${1:-}" in
  --cancel-ci) [ $# -eq 2 ] || { echo "usage: pr-watch.sh --cancel-ci <pr>" >&2; exit 1; }; cancel_ci "$2"; exit $? ;;
  --loop)
    [ $# -eq 2 ] || { echo "usage: pr-watch.sh --loop <pr>" >&2; exit 1; }
    while :; do
      poll "$2"; rc=$?
      if [ "$rc" -eq 10 ]; then cancel_ci "$2"; exit 10; fi
      case "$rc" in 14|11|15) sleep 30 ;; *) exit "$rc" ;; esac
    done ;;
  ""|-*) echo "usage: pr-watch.sh <pr> | --cancel-ci <pr> | --loop <pr>" >&2; exit 1 ;;
  *) poll "$1"; exit $? ;;
esac
