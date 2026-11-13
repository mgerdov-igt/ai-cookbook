---
name: git-commit
description: Make a Git commit, or split changes into several commits, with a Conventional Commits message written from the diff. Use for "commit this", "/commit", "make a conventional commit", "split these changes into commits", or "commit my changes". Stages only related files, checks for secrets, and never pushes, opens a PR, or rewrites history. Do not use when the user wants only a message, not a commit.
license: MIT
---

# Git Commit

Commit related changes with a clear [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) message. Take the type, scope, and summary from the diff.

Adapted from [`git-commit`](https://github.com/github/awesome-copilot/tree/main/skills/git-commit) in [github/awesome-copilot](https://github.com/github/awesome-copilot) (MIT). See [THIRD-PARTY-NOTICES](../../THIRD-PARTY-NOTICES.md).

## When to use

- "Commit this."
- "Make a conventional commit."
- "Split these changes into separate commits."

## When not to use

- The user wants only a message to copy: write the message and stop.
- The user wants to push, open a PR, amend, rebase, or change history. Use [github-pr-flow](../github-pr-flow/SKILL.md) or [pr-to-main](../pr-to-main/SKILL.md) for PRs, and ask before anything that rewrites history.

## Message format

```text
<type>(<scope>): <summary>

<body>

<footer>
```

- Scope, body, and footer are optional. Without a scope, write `<type>: <summary>`.
- Write the summary in the imperative mood ("add", not "added"). Keep the first line to 72 characters. No final period.
- Use the body for what changed and why.
- Write footers as `Token: value`, for example `Closes: #123`. Git reads only this form as a trailer.
- Mark a breaking change with `!` before the colon or a `BREAKING CHANGE:` footer.

| Type | Use for |
|---|---|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only |
| `style` | Formatting only, no logic change |
| `refactor` | Code change that is not a feature or fix |
| `perf` | Performance improvement |
| `test` | New or changed tests |
| `build` | Build system or dependencies |
| `ci` | CI configuration |
| `chore` | Other maintenance |
| `revert` | Revert of an earlier commit |

Only `feat` and `fix` come from the specification. The rest follow the common Angular convention.

## Steps

1. **Read the repository rules first.** Look for a commitlint config, `CONTRIBUTING.md`, `AGENTS.md`, and recent messages with `git log --oneline -10`. If they differ from this skill, follow the repository. Follow your host tool's rules for commit trailers, such as a co-author line.
2. **Look at the changes.**

   ```powershell
   git status --porcelain
   git diff --staged
   git diff
   ```

   No changes: tell the user. Do not make an empty commit.
3. **Check for a Git operation in progress.** Run `git status --long`. If it shows a merge, rebase, cherry-pick, revert, or unmerged files, stop. Do not unstage or split. Ask the user how to continue. Once the user has resolved every conflict, `git commit --no-edit` keeps the message Git prepared.
4. **Stage one logical change per commit.** Name files or folders. Use `git reset -q -- <paths>` to remove files that belong to another change. Never use `git add -A` or `git add .` when unrelated changes are present. Never use `git add -p` or `git add -i`, which wait for input.

   ```powershell
   git add -- path\to\file1 path\to\file2
   git diff --staged --name-only
   ```

5. **Check for secrets.** Do not commit `.env` files, credentials, tokens, or private keys. Ask first if a staged file looks sensitive.
6. **Commit.** Use one `-m` for each paragraph. This works in PowerShell and Bash. For a long message, write it to a temporary file and use `git commit -F <file>`.

   ```powershell
   git commit -m "fix(parser): accept empty input" -m "An empty file crashed the parser." -m "Closes: #123"
   ```

7. **Verify.**

   ```powershell
   git log -1 --stat
   git status --porcelain
   ```

## Gotchas

- **Never** use `--no-verify` unless the user says so. Hooks protect the repository.
- If a hook fails, no commit exists. Fix the problem, stage again, and run a new `git commit`. Do **not** use `--amend`, which would change the previous commit.
- **Never** change Git configuration, run `git reset --hard`, `git rebase`, or force push.
- **Do not** push. Push only when the user asks.
- Unquoted globs such as `*.test.*` may be expanded by the shell. Quote them: `git add -- '*.test.*'`.
- Git quotes paths with non-ASCII characters in `status --porcelain`. If `git add` fails on a quoted path, ask the user.
