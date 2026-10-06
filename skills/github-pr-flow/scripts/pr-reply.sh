#!/usr/bin/env bash
# Reply in-thread to one PR review comment (REST, not GraphQL — see
# pr-resolve.sh for why these are two different id spaces).
#
#   bash <skill-folder>/scripts/pr-reply.sh <PR-number> <comment-id> "Fixed in abc123. ..."
#   bash <skill-folder>/scripts/pr-reply.sh <PR-number> <comment-id> --file reply.txt
#
# <comment-id> is the REST databaseId — get it from pr-threads.sh's output
# (3rd column), not the GraphQL thread id (that one's for pr-resolve.sh).
#
# This posts a reply only. It does not resolve the thread. Use
# pr-resolve.sh after the discussion is complete.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

pr=${1:?usage: pr-reply.sh <PR#> <comment-id> <body|--file path>}
comment_id=${2:?usage: pr-reply.sh <PR#> <comment-id> <body|--file path>}
shift 2

if [ "${1:-}" = "--file" ]; then
  body=$(cat "${2:?--file needs a path}")
else
  body=${1:?reply body is required}
fi

read -r owner name < <(repo_owner_name)

gh api "repos/$owner/$name/pulls/$pr/comments/$comment_id/replies" -f body="$body" \
  -q '.html_url'
