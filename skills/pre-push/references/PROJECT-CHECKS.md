# Project checks

The `pre-push` skill is generic. A repo tells it what to run in one section of `AGENTS.md`, so the skill holds no language or tool names.

## Add this to the repo's `AGENTS.md`

Copy it, delete the lines that do not apply, and fill in real commands. One line per check. Say the folder to run it from.

````markdown
## Pre-push checks

The `pre-push` skill reads this section. Run these from the repo root unless a line says otherwise.

- **Base:** `origin/main` (the branch PRs go to).
- **Static:** `npm run lint` and `npm run typecheck`, in every package with a changed file.
- **Tests:** what CI runs for the changed files: `npm test --workspace <pkg>`, from the repo root.
  CI selection: `<how CI picks tests, and the command that answers it for a work folder>`.
- **Slow tests:** `npm run e2e`. Needed only when `e2e/` or `ci.yml` changed.
- **Fresh build before a smoke test:** `<command that says whether the build is older than the source>`, then `<build command>`.
- **Keep in step:** `<file A>` and `<file B>` must stay equal (a mirror, a generated file, a translation set).
- **Never edit by script:** `<files or folders where scripted rewrites are not allowed>`.
- **Docs to update with a change:** `<the index or plan that must change with it>`.
- **Not mine:** other agents may change files here; leave files you did not change.
````

Keep it short. Link to the long docs instead of copying them.

## No section yet: discover the commands

Look in this order and stop at the first that answers. Say which source you used.

| Look at | It tells you |
|---|---|
| CI workflow (`.github/workflows/*`, `.gitlab-ci.yml`, `azure-pipelines.yml`) | The exact commands and the order CI runs them. The best source. |
| `AGENTS.md`, `CONTRIBUTING*`, `docs/` test pages | Conventions, and where to run things from. |
| `package.json` `scripts` | `lint`, `typecheck`, `test`, `build`. |
| `Makefile`, `justfile`, `Taskfile.yml` | `make check`, `make test`. |
| `pyproject.toml`, `tox.ini`, `noxfile.py` | `pytest`, `ruff`, `mypy`. |
| `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle*`, `*.sln` | `cargo clippy` and `cargo test`, `go vet` and `go test ./...`, `mvn verify`, `./gradlew check`, `dotnet test`. |
| `pubspec.yaml`, `melos.yaml` | `dart analyze`, `flutter test` from each package folder. |

If nothing answers, ask the user once or mark the step "not run: no command found". Do not guess a command that could change files.

## Which tests CI will run

Many repos run only the tests a change can affect. Do not copy the CI selection and run it blind (see the gotcha in [SKILL.md](../SKILL.md)). Instead:

1. Find how CI decides (a script, a path filter in the workflow, a monorepo tool such as `nx affected` or `turbo --filter`).
2. Ask the same question of the right files: everything that differs from the base, committed or not, plus new files. `python3 scripts/prepush_scan.py --json` lists them in `changed`.
3. If the tool takes a base ref, use it: `nx affected --base=origin/main`, `turbo run test --filter=...[origin/main]`.
4. If you cannot answer it, run the full suite, or the packages with changed files plus the ones that depend on them, and say that is what you did.

A repo that wants this exact would add a small helper and name it in its `## Pre-push checks` section. That helper should import the CI rule, not copy it, so the two cannot drift.

## Two kinds of failure to avoid

- **Skipping a check because it is slow.** Run it, or write "not run: <reason>".
- **Running everything every time.** If CI would run all packages only because of a file no test reads, say which file and let CI do the full run.
