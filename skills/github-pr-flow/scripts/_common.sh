#!/usr/bin/env bash
# Shared helpers for this skill's scripts. Not a standalone entry point;
# the other scripts load it.
#
# These scripts work in any GitHub repo. Install this whole skill folder
# anywhere your AI tool can read it, as long as:
#   - it's invoked with cwd somewhere inside a git repo that has a GitHub
#     remote (any repo — nothing here is specific to this one);
#   - `gh` is installed and authenticated (`gh auth status`);
#   - `python3` is on PATH (used for JSON shaping; no third-party packages).
# Nothing hardcodes an owner/repo name. Scripts discover the repo at runtime
# with `gh repo view`.
#
# Provides:
#   require_tools     exits with a clear message if gh/python3 are missing
#   repo_owner_name   prints "<owner> <name>" (space-separated), from `gh`'s
#                     own notion of the current repo (works from any cwd
#                     inside the repo, including a PR worktree)
#   gql <query> [-f k=v ...]   wrapper around `gh api graphql`
set -euo pipefail

require_tools() {
  local missing=()
  command -v gh >/dev/null 2>&1 || missing+=("gh (https://cli.github.com)")
  command -v python3 >/dev/null 2>&1 || missing+=("python3")
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "missing required tool(s): ${missing[*]}" >&2
    exit 1
  fi
}
require_tools

repo_owner_name() {
  gh repo view --json owner,name -q '.owner.login + " " + .name'
}

gql() {
  gh api graphql -f query="$1" "${@:2}"
}
