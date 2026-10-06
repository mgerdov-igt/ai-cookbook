#!/usr/bin/env bash
# Resolve one or more PR review threads (GraphQL mutation).
#
#   bash <skill-folder>/scripts/pr-resolve.sh <thread-id>
#   bash <skill-folder>/scripts/pr-resolve.sh <thread-id> <thread-id> ...
#
# Each argument is a GraphQL thread id — get it from pr-threads.sh's output
# (2nd column), not the REST comment id (that one's for pr-reply.sh).
# Reply to and address the review comment before resolving its thread.
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
