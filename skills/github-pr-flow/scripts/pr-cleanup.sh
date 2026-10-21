#!/usr/bin/env bash
# Post-merge cleanup for the worktree-per-PR workflow: remove the PR's
# worktree, prune, delete its local branch, then bring the parent tree's
# current branch up to date with the newly-merged main — never resetting
# or checking out anything else in the parent tree beyond what's verified
# below.
#
#   tools/pr-review/pr-cleanup.sh ../myrepo-pr150 pr150-local
#
# Run this from inside the PARENT tree (the checkout you want folded back
# into), not from inside the worktree being removed.
#
# A dirty parent tree does NOT automatically stop this script. The
# pr-to-main skill's Phase 1 copies the parent tree's pending changes into
# the worktree without ever committing them in the parent itself, so after
# a merge the parent is routinely left dirty with files that are now stale
# duplicates of what's on the default branch (sometimes OLDER duplicates —
# review fixes land on the branch but never flow back here). This script
# verifies that before touching anything: every dirty file is checked
# against the default branch, content-for-content (ignoring only line endings). If
# all of it is a confirmed-stale duplicate, the parent tree is reset clean
# to match the default branch. If anything dirty is NOT found there, it
# might be real unique work that never shipped — this script stops without
# resetting and names exactly which file(s) it's unsure about, same as the
# pr-to-main skill's own Phase 5.
set -euo pipefail

worktree=${1:?usage: pr-cleanup.sh <worktree-path> <local-branch>}
branch=${2:?usage: pr-cleanup.sh <worktree-path> <local-branch>}

# Ignored files that are only rebuildable output: a package manager's or
# build tool's cache and generated files. A worktree whose ONLY ignored files
# match these is safe to remove — they come back from the next build. Anything
# ignored that is NOT matched here (an .env, a keystore, local notes, a data
# file) still stops the script, because that could be the only copy.
# Matched against each ignored path as git prints it (relative to the worktree).
is_rebuildable_ignored() {
  local p=$1 base=${1##*/}
  # Secrets-style files are never rebuildable, wherever they sit and whatever
  # they are named after: any path component starting with ".env" stops it.
  case "/$p" in */.env*) return 1 ;; esac
  # A C-quoted path (leading quote) means the caller did not read raw paths.
  case "$p" in \"*) return 1 ;; esac
  # Credential and hand-edited config files are never rebuildable, even inside
  # a build directory (a keystore under build/, a designer.json beside the exe).
  case "$base" in
    *.jks|*.keystore|*.p12|*.pfx|*.pem|*.key|designer.json|settings.local.json|secrets.env) return 1 ;;
  esac
  # Whole directory components only (never a prefix or suffix of one).
  case "/$p" in
    */.dart_tool/*|*/build/*|*/.gradle/*|*/node_modules/*|*/.pub-cache/*) return 0 ;;
    */ephemeral/*|*/Pods/*|*/.fvm/*) return 0 ;;
  esac
  # Generated files, by exact basename or extension.
  case "$base" in
    .flutter-plugins|.flutter-plugins-dependencies|.packages|local.properties) return 0 ;;
    GeneratedPluginRegistrant.java|generated_plugins.cmake|gradle-wrapper.jar) return 0 ;;
    gradlew|gradlew.bat|.metadata|pubspec.lock|seed-bundle.zip) return 0 ;;
    generated_plugin_registrant.*|*.iml|*.dill|*.g.dart|*.freezed.dart|*.mocks.dart) return 0 ;;
  esac
  case "/$p" in
    */assets/*-config.zip|*/assets/designer-seed*) return 0 ;;
  esac
  return 1
}

# Removes a directory tree that "git worktree remove" could not, because a path
# inside it is longer than Windows allows (MAX_PATH). Only runs on Windows
# (Git Bash / MSYS / Cygwin), only on a folder that is no longer a registered
# worktree, and only on the exact path given. Mirroring an empty folder over it
# with robocopy deletes deep paths that "rm -r" and git cannot.
long_path_remove() {
  local dir=$1
  command -v robocopy >/dev/null 2>&1 || command -v robocopy.exe >/dev/null 2>&1 || return 1
  command -v cygpath >/dev/null 2>&1 || return 1
  [ -d "$dir" ] || return 0
  # Never on a folder git still tracks, and never on a git work tree root of
  # a real clone (its .git is a directory, a worktree's is a file).
  if git worktree list --porcelain | grep -qF "worktree $(cd "$dir" && pwd)"; then return 1; fi
  if [ -d "$dir/.git" ]; then
    echo "REFUSING long-path delete: $dir has a .git directory (a real clone, not a worktree)" >&2
    return 1
  fi
  local empty
  empty=$(mktemp -d)
  # Git Bash rewrites "/MIR"-style switches into paths unless conversion is off.
  MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' robocopy "$(cygpath -w "$empty")" "$(cygpath -w "$dir")" /MIR /NFL /NDL /NJH /NJS /NP /R:1 /W:1 >/dev/null 2>&1 || true
  rmdir "$empty" 2>/dev/null || true
  rm -rf "$dir" 2>/dev/null || true
  [ ! -d "$dir" ]
}

# Nothing is removed until the parent tree has been validated (below): a
# refusal must leave the PR worktree and its branch exactly as they were.
remove_worktree_and_branch() {
  if [ -d "$worktree" ]; then
    # Identity first: this must be a REGISTERED linked worktree root, recorded
    # before anything is removed. An ordinary sub-folder of some checkout (which
    # would pass every inventory check below) is never removed, and the long-path
    # fallback only ever acts on this recorded root.
    wt_root=$(cd "$worktree" && pwd -P) || { echo "STOP: cannot resolve $worktree" >&2; exit 1; }
    top=$(git -C "$worktree" rev-parse --show-toplevel 2>/dev/null) || top=""
    [ -n "$top" ] && top=$(cd "$top" && pwd -P)
    if [ "$top" != "$wt_root" ] || [ ! -f "$wt_root/.git" ]; then
      echo "STOP: $worktree is not the root of a linked git worktree; refusing to remove it." >&2
      exit 1
    fi
    registered=0
    while IFS= read -r line; do
      case "$line" in
        "worktree "*) p=$(cd "${line#worktree }" 2>/dev/null && pwd -P) || continue
                      [ "$p" = "$wt_root" ] && registered=1 ;;
      esac
    done < <(git worktree list --porcelain)
    if [ "$registered" -ne 1 ]; then
      echo "STOP: $worktree is not a registered worktree of this repository; refusing to remove it." >&2
      exit 1
    fi
    # Ignored files stop the removal only when they are NOT plain rebuildable
    # output (see is_rebuildable_ignored). Paths are read NUL-delimited and raw
    # (git's default quoting would turn a non-ASCII name into "\303..." with a
    # leading quote that defeats the component checks). A failed scan aborts: an
    # empty result from a failed command must never read as "nothing to protect".
    scan_file=$(mktemp) || { echo "STOP: cannot create a temp file" >&2; exit 1; }
    if ! git -C "$worktree" ls-files -z --others --ignored --exclude-standard > "$scan_file"; then
      rm -f "$scan_file"
      echo "STOP: could not list git-ignored files in $worktree; refusing to remove it." >&2; exit 1
    fi
    keep=()
    while IFS= read -r -d '' ig; do
      is_rebuildable_ignored "$ig" || keep+=("$ig")
    done < "$scan_file"
    rm -f "$scan_file"
    if [ ${#keep[@]} -gt 0 ]; then
      echo "STOP: $worktree has git-ignored files that are not rebuildable build output,"
      echo "and 'git worktree remove' would delete them:"
      printf '  %q\n' "${keep[@]:0:20}"
      echo "Move anything you need out of the worktree, then re-run this script."
      exit 1
    fi
    # Uncommitted work in the PR worktree itself (tracked edits, staged changes,
    # or untracked files that are not ignored) is never thrown away: --force
    # below would delete it. Stop and say what it is. Porcelain output leaves out
    # ignored files by default.
    unsaved=$(git -C "$worktree" status --porcelain --untracked-files=all) || {
      echo "STOP: could not read the status of $worktree; refusing to remove it." >&2; exit 1; }
    if [ -n "$unsaved" ]; then
      echo "STOP: $worktree has uncommitted work that removing it would delete:"
      printf '%s\n' "$unsaved" | head -20
      echo "Commit or move it, then re-run this script."
      exit 1
    fi
    # --force is safe now: nothing unsaved is left, and the only ignored files
    # are rebuildable output (checked above).
    if ! git worktree remove --force "$worktree" 2>/dev/null; then
      echo "note: 'git worktree remove' did not finish (often a Windows long path); trying a long-path-safe delete"
      git worktree prune
      if long_path_remove "$wt_root"; then
        echo "removed $wt_root (long-path-safe delete)"
      else
        echo "WARNING: could not remove $worktree — remove it by hand and run 'git worktree prune'." >&2
        left_behind=1
      fi
    fi
  else
    echo "note: $worktree does not exist, skipping worktree remove"
  fi
  git worktree prune

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git branch -D "$branch"
  else
    echo "note: local branch $branch does not exist, skipping branch delete"
  fi
}

left_behind=0

if git remote get-url origin >/dev/null 2>&1; then
  remote=origin
else
  remote=$(git remote | head -1)
fi
: "${remote:?no git remote configured}"

git fetch "$remote"

# Ask gh about the repo $remote actually points at, not whatever repo gh
# would pick by its own default resolution (e.g. `gh repo set-default`
# pointing at a different remote such as upstream) — those can disagree
# on a fork, and using the wrong one picks the wrong default branch name.
remote_url=$(git remote get-url "$remote")
default_branch=$(gh repo view "$remote_url" --json defaultBranchRef -q '.defaultBranchRef.name')
remote_ref="$remote/$default_branch"

# Every dirty path (tracked-modified or untracked) must be a confirmed-
# stale duplicate of what's now on $remote_ref before we touch anything.
# Only line-ending-only differences (trailing CR) are tolerated: a CRLF vs
# LF rewrite upstream is the same content, but any other whitespace change
# (inside a JSON string, say) is a real, unique edit. Staged changes are
# never tolerated: this compares the working file only, so a file with
# unique staged work and a matching working copy would be silently lost.
# NUL-delimited lists throughout: git C-quotes paths with tabs or non-ASCII
# characters in text mode, and `status --porcelain` collapses an untracked
# directory into one entry, so neither can be compared path-for-path.
dirty_files=()
while IFS= read -r -d '' f; do dirty_files+=("$f"); done < <(
  { git diff -z --name-only HEAD; git diff -z --cached --name-only; git ls-files -z --others --exclude-standard; } | sort -zu)
unique=""
if [ ${#dirty_files[@]} -gt 0 ]; then
  if ! git diff --cached --quiet; then
    unique="${unique}  STAGED changes present (index not verified): $(git diff --cached --name-only | tr '\n' ' ')\n"
  fi
  # Ignored files are not in dirty_files; a reset --hard would overwrite one
  # if the remote now tracks the same path, a directory over it, or a file at
  # one of its parent directories.
  while IFS= read -r -d '' ig; do
    hit=0
    # exact path or incoming descendants (path-limited ls-tree matches on
    # directory boundaries only)
    [ -n "$(git ls-tree -r --name-only "$remote_ref" -- "${ig%/}")" ] && hit=1
    anc="$ig"
    while [ "$hit" -eq 0 ]; do
      anc=$(dirname "$anc")
      { [ "$anc" = "." ] || [ "$anc" = "/" ]; } && break
      [ "$(git cat-file -t "${remote_ref}:${anc}" 2>/dev/null)" = "blob" ] && hit=1
    done
    if [ "$hit" -eq 1 ]; then
      unique="${unique}  IGNORED file collides with a path on ${remote_ref}: ${ig}\n"
    fi
  done < <(git ls-files -z --others --ignored --exclude-standard)
  for f in "${dirty_files[@]}"; do
    if ! git cat-file -e "${remote_ref}:${f}" 2>/dev/null; then
      unique="${unique}  NEW (not on ${remote_ref} at all): ${f}\n"
      continue
    fi
    # File type / mode must match too: identical bytes under a changed
    # executable bit, or a local symlink standing in for a regular file (diff
    # would follow it), is still a real, unique change.
    remote_mode=$(git ls-tree "$remote_ref" -- "$f" | cut -d' ' -f1)
    index_mode=$(git ls-files -s -- "$f" | cut -d' ' -f1)
    if [ -L "$f" ] || [ "$remote_mode" = "120000" ] \
       || { [ -n "$index_mode" ] && [ "$index_mode" != "$remote_mode" ]; } \
       || git diff --summary -- "$f" | grep 'mode change' >/dev/null; then
      unique="${unique}  FILE TYPE/MODE differs from ${remote_ref}: ${f}\n"
      continue
    fi
    if ! diff -q --strip-trailing-cr <(git show "${remote_ref}:${f}" 2>/dev/null) "$f" >/dev/null 2>&1; then
      unique="${unique}  DIFFERS from ${remote_ref}: ${f}\n"
    fi
  done
fi

if [ -n "$unique" ]; then
  echo "STOP: parent tree is dirty, and the item(s) below are not confirmed"
  echo "stale duplicates of ${remote_ref} — they may be unique work that"
  echo "never made it into the shipped PR. Not resetting anything."
  printf '%b' "$unique"
  echo "Review these yourself (commit/ship them, or discard if you're sure"
  echo "they're not needed), then re-run this script."
  exit 1
fi

if [ ${#dirty_files[@]} -gt 0 ]; then
  echo "parent tree was dirty but every file is a confirmed-stale duplicate"
  echo "of ${remote_ref} — resetting to match it."
  # Verified untracked duplicates become tracked by the reset itself, so
  # nothing is deleted here (and no blanket `git clean`).
  git reset --hard "$remote_ref"
  remove_worktree_and_branch
  echo "parent tree is now clean, at ${remote_ref}."
  # A worktree folder that could not be removed is a loud, non-zero result, so
  # the caller (the pr-to-main skill) reports it instead of calling it done.
  if [ "${left_behind:-0}" = "1" ]; then
    echo "DONE with a leftover: $worktree is still on disk (see the WARNING above)." >&2
    exit 3
  fi
  exit 0
fi

remove_worktree_and_branch

current=$(git branch --show-current)

# A fast-forward pull/merge silently overwrites a locally-ignored file (an
# .env, a build artifact) the instant the incoming branch starts tracking
# that same path, or even that same path as a different type (an ignored
# FILE `cache` vs. an incoming tracked DIRECTORY `cache/result.txt`) — git
# does not warn or refuse by default, it just clobbers it, and a plain
# path-string collision check misses the file-vs-directory case entirely.
# `--no-overwrite-ignore` makes git itself refuse (and leave the ignored
# path untouched) instead of us trying to pre-detect every collision shape.
if [ "$current" = "$default_branch" ]; then
  git merge "$remote_ref" --ff-only --no-overwrite-ignore
else
  git merge "$remote_ref" --no-edit --no-overwrite-ignore
fi

if [ "${left_behind:-0}" = "1" ]; then
  echo "DONE with a leftover: $worktree is still on disk (see the WARNING above)." >&2
  exit 3
fi
