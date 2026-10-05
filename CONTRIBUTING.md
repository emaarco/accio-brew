# Contributing

Bug reports, ideas and pull requests are welcome.

- **Report a bug or request a feature** → [open an issue](https://github.com/emaarco/accio-brew/issues/new).
- **Change the formula** → it lives in [`emaarco/homebrew-tap`](https://github.com/emaarco/homebrew-tap).

## Run the tests

```sh
tests/run.sh              # all tests
tests/run.sh wrapper      # tests whose name contains "wrapper"
```

The tests use fake binaries, local bare repositories and a temporary `HOME`. They never touch your real Homebrew, `~/.zshrc` or launchd, and need nothing beyond macOS. `shellcheck` is used when installed.

## Cut a release

Merging to `main` keeps a release pull request up to date via [release-please](https://github.com/googleapis/release-please). Merging that pull request tags `vX.Y.Z`, publishes the GitHub release and points `url` and `sha256` of the formula in [`emaarco/homebrew-tap`](https://github.com/emaarco/homebrew-tap) at the new tarball. Everything else in the formula is edited in the tap by hand.

## Find your way around

| Path | Responsibility |
|---|---|
| `bin/accio-brew` | Entry point: loads `lib/` and dispatches the subcommand. |
| `lib/` | One file per concern, e.g. `config.sh`, `clone.sh`, `sync.sh`, `apply.sh`, `repo_choice.sh`, `prompt_gum.sh`, `prompt_plain.sh`, `wrapper_trigger.sh`, `launchd_trigger.sh`. |
| `modules/` | What gets installed on the Mac: the zsh `brew` wrapper and the launchd plist template. |
| `tests/test_*.sh` | Tests grouped by behaviour; every `test_*` function runs in its own sandbox. |
| `tests/fakes/` | Stand-ins for `brew`, `scutil`, `launchctl`, `ssh` and `gum`. |
| `docs/` | User documentation linked from the README. |

## House rules

- **Plain git only.** No GitHub or GitLab API, no `gh`, no `glab`.
- **bash 3.2.** `bin/` and `lib/` must run with the bash that ships with macOS.
- **No comments.** Small functions with telling names instead.
- **Small files.** A test fails when a file grows beyond 150 lines; split by responsibility.
- **One behaviour per test.** Name the test after the behaviour, not the function.
- **Test first.** Reproduce a bug with a failing test before fixing it.
- **Conventional Commits** for commit messages and pull request titles, e.g. `fix: keep configured ssh command`.
