#!/usr/bin/env bash
# Keep every copy of the PR and Jira tooling identical to the cookbook (the canonical source).
#
#   sync.sh --check [--repo <path>]... [--global]   report drift, change nothing (exit 1 if any)
#   sync.sh --apply [--repo <path>]... [--global]   copy the canonical files over the copies
#
#   --repo <path>   a repo that carries the scripts: <path>/tools/pr-review/*.sh, and, when the
#                   repo has tools/jira/ or .jira-flow.json, <path>/tools/jira/*.py from jira-flow
#   --global        the personal skill folders: ~/.claude/skills and ~/.copilot/skills get
#                   github-pr-flow, pr-to-main, jira-flow and jira-to-pr
#
# Repo-specific files (README.md, playbooks, .jira-flow.json, backlog) are never touched.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS="$(cd "$HERE/.." && pwd)"

mode=""; repos=(); global=0
while [ $# -gt 0 ]; do
  case "$1" in
    --check|--apply) mode="$1" ;;
    --repo) shift; repos+=("${1:?--repo needs a path}") ;;
    --global) global=1 ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
  shift
done
[ -n "$mode" ] || { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

drift=0
sync_file() { # src dst
  if [ -f "$2" ] && cmp -s "$1" "$2"; then return 0; fi
  drift=1
  if [ "$mode" = "--apply" ]; then
    mkdir -p "$(dirname "$2")" && cp "$1" "$2" && echo "updated  $2"
  else
    echo "DRIFT    $2"
  fi
}
sync_tree() { # srcdir dstdir
  local f rel
  while IFS= read -r f; do
    rel="${f#"$1"/}"
    sync_file "$f" "$2/$rel"
  done < <(find "$1" -type f -not -path "*/__pycache__/*")
}

for r in "${repos[@]}"; do
  [ -d "$r" ] || { echo "no such repo: $r" >&2; exit 1; }
  for f in "$HERE"/scripts/*.sh; do sync_file "$f" "$r/tools/pr-review/$(basename "$f")"; done
  if [ -d "$r/tools/jira" ] || [ -f "$r/.jira-flow.json" ]; then
    for f in "$SKILLS"/jira-flow/scripts/*.py; do
      case "$f" in */test_*) continue ;; esac
      sync_file "$f" "$r/tools/jira/$(basename "$f")"
    done
  fi
done

if [ "$global" -eq 1 ]; then
  for root in "$HOME/.claude/skills" "$HOME/.copilot/skills"; do
    sync_tree "$HERE" "$root/github-pr-flow"
    for sk in pr-to-main jira-flow jira-to-pr; do
      [ -d "$SKILLS/$sk" ] && sync_tree "$SKILLS/$sk" "$root/$sk"
    done
  done
fi

[ "$drift" -eq 0 ] && echo "in sync"
[ "$mode" = "--check" ] && exit "$drift"
exit 0
