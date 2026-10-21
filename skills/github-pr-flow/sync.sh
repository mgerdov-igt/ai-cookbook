#!/usr/bin/env bash
# Keep every copy of the PR tooling identical to this folder (the canonical source).
#
#   sync.sh --check [--repo <path>]... [--global]   report drift, change nothing (exit 1 if any)
#   sync.sh --apply [--repo <path>]... [--global]   copy the canonical files over the copies
#
#   --repo <path>   a repo that carries the scripts: <path>/tools/pr-review/*.sh
#   --global        the personal skill folders: ~/.claude/skills and ~/.copilot/skills get
#                   github-pr-flow (SKILL.md, references, scripts) and pr-to-main
#
# Repo-specific files (the repo's own README.md, playbook, backlog) are never touched.
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
[ -n "$mode" ] || { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

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
  done < <(find "$1" -type f)
}

for r in "${repos[@]}"; do
  [ -d "$r" ] || { echo "no such repo: $r" >&2; exit 1; }
  for f in "$HERE"/scripts/*.sh; do sync_file "$f" "$r/tools/pr-review/$(basename "$f")"; done
done

if [ "$global" -eq 1 ]; then
  for root in "$HOME/.claude/skills" "$HOME/.copilot/skills"; do
    sync_tree "$HERE" "$root/github-pr-flow"
    [ -d "$SKILLS/pr-to-main" ] && sync_tree "$SKILLS/pr-to-main" "$root/pr-to-main"
  done
fi

[ "$drift" -eq 0 ] && echo "in sync"
[ "$mode" = "--check" ] && exit "$drift"
exit 0
