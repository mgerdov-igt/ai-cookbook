#!/usr/bin/env bash
# Reply in-thread to one PR review comment (REST, not GraphQL — see
# pr-resolve.sh for why these are two different id spaces).
#
#   tools/pr-review/pr-reply.sh 150 4183285021 "Fixed in 2663db74. ..."
#   tools/pr-review/pr-reply.sh 150 4183285021 --file reply.txt
#
# <comment-id> is the REST databaseId — get it from pr-threads.sh's output
# (3rd column), not the GraphQL thread id (that one's for pr-resolve.sh).
#
# This posts a reply only. It does NOT resolve the thread — always follow
# up with pr-resolve.sh once every comment in the thread has a reply,
# per PR-MERGE-READINESS-PLAYBOOK.md §4 steps 4-5.
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
