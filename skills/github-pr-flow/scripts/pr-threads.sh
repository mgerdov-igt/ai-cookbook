#!/usr/bin/env bash
# List a PR's review threads in one paginated GraphQL call — every thread,
# not just the first 100, and with both ID spaces you need for the other
# scripts in this directory: the GraphQL thread id (pr-resolve.sh) and the
# REST comment databaseId of its first comment (pr-reply.sh).
#
# The query can return more than 100 threads. This script paginates and
# prints both IDs needed for replying and resolving.
#
#   bash <skill-folder>/scripts/pr-threads.sh <PR-number>
#   bash <skill-folder>/scripts/pr-threads.sh <PR-number> --open
#   bash <skill-folder>/scripts/pr-threads.sh <PR-number> --json
#
# Output columns (table form): resolved, thread-id, comment-databaseId, path, line
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

pr=${1:?usage: pr-threads.sh <PR#> [--open] [--json]}
mode=${2:-}

read -r owner name < <(repo_owner_name)

query='
query($endCursor: String) {
  repository(owner: "'"$owner"'", name: "'"$name"'") {
    pullRequest(number: '"$pr"') {
      reviewThreads(first: 100, after: $endCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          path
          line
          comments(first: 10) { nodes { databaseId body } }
        }
      }
    }
  }
}'

json=$(gh api graphql --paginate -f query="$query" \
  -q '.data.repository.pullRequest.reviewThreads.nodes' | python3 -c '
import json, sys
nodes = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    nodes.extend(json.loads(line))
print(json.dumps(nodes))
')

if [ "$mode" = "--json" ]; then
  echo "$json"
  exit 0
fi

filter_open=$([ "$mode" = "--open" ] && echo 1 || echo 0)

echo "$json" | python3 -c "
import json, sys
nodes = json.load(sys.stdin)
only_open = $filter_open
for n in nodes:
    if only_open and n['isResolved']:
        continue
    first = n['comments']['nodes'][0] if n['comments']['nodes'] else {}
    db_id = first.get('databaseId', '')
    body = (first.get('body', '') or '').replace(chr(10), ' ')[:70]
    print(f\"{'resolved' if n['isResolved'] else 'OPEN    '} | {n['id']} | {db_id} | {n['path']}:{n.get('line')} | {body}\")
"
