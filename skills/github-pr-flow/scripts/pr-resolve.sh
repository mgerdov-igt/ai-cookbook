#!/usr/bin/env bash
# Resolve one or more PR review threads (GraphQL mutation).
#
#   tools/pr-review/pr-resolve.sh PRRT_kwDOSxLQvc6pASzv
#   tools/pr-review/pr-resolve.sh PRRT_kwDOSxLQvc6pASzv PRRT_kwDOSxLQvc6pAS0k ...
#
# Each argument is a GraphQL thread id — get it from pr-threads.sh's output
# (2nd column), not the REST comment id (that one's for pr-reply.sh).
# Resolving does not require a reply to exist, but per
# PR-MERGE-READINESS-PLAYBOOK.md §4 every thread should get a reply first —
# this script only clears the "conversation" checkbox, it says nothing.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

if [ "$#" -eq 0 ]; then
  echo "usage: pr-resolve.sh <thread-id> [<thread-id> ...]" >&2
  exit 1
fi

query='mutation($id: ID!) { resolveReviewThread(input: {threadId: $id}) { thread { isResolved } } }'

for id in "$@"; do
  gh api graphql -f query="$query" -f id="$id" -q '.data.resolveReviewThread.thread.isResolved' \
    | xargs -I{} echo "$id resolved={}"
done
