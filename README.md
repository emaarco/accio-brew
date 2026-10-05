# accio-brew

Keep the Homebrew packages of your Macs in a git repository. Every Mac records what it has installed, and one curated Brewfile describes what a Mac *should* have.

accio-brew talks to your repository with plain `git` only. It works with GitHub, GitLab, Bitbucket, Gitea and self-hosted servers alike.

## How it works

You need two repositories:

- **This one** contains the tool.
- **Your data repo** is where accio-brew writes. Create an empty private repository on the host of your choice.

Inside the data repo:

| Branch | `Brewfile` contains | Written by |
|---|---|---|
| default branch (`main`) | the target state | you, via merge requests |
| `hosts/<host-id>` | what that Mac has installed | accio-brew on that Mac, automatically |

Each Mac only ever pushes to its own branch, so Macs never conflict with each other and `main` can be protected.

## Install

```sh
git clone https://github.com/emaarco/brew-sync.git ~/.local/share/accio-brew/tool
~/.local/share/accio-brew/tool/bin/accio-brew init
```

`init` asks two questions:

```
Where is your Brewfile repo?
  1) github.com
  2) gitlab.com
  3) paste clone URL
Choice [1]:
Repository (owner/name):
How should sync be triggered?
  1) wrapper  - after every brew install/uninstall/upgrade
  2) launchd  - hourly in the background
Choice [1]:
```

It then checks that the repo is reachable without a password prompt, creates `main` with an empty Brewfile if the repo is empty, pushes this Mac's first dump and installs the trigger you chose.

For self-hosted servers choose `3` and paste the clone URL.

Scripted setup, for example for onboarding:

```sh
accio-brew init --repo-url git@gitlab.example.com:team/brewfiles.git --mode launchd </dev/null
```

Keep the tool outside `~/Documents`, `~/Desktop` and `~/Downloads`; macOS blocks background agents from reading those folders.

To update the tool, run `git pull` in `~/.local/share/accio-brew/tool`.

## Commands

| Command | What it does |
|---|---|
| `accio-brew init` | Guided setup. Run it again to change the repo or the trigger. |
| `accio-brew sync` | Dump the installed packages and push them to `hosts/<host-id>`. |
| `accio-brew apply` | Install everything from the target Brewfile on `main`. |
| `accio-brew apply --cleanup` | Also uninstall every tap, formula and cask that is not in the target. |
| `accio-brew teardown` | Remove the trigger and the `~/.local/bin/accio-brew` link. |

`apply` uses `brew bundle install`, which also upgrades packages that are already installed.

`apply --cleanup` removes software without asking and resets Homebrew's tap trust settings to the ones in the target Brewfile.

## Changing things later

- **Other repo or other trigger:** run `accio-brew init` again. Enter keeps the current value; `accio-brew init --mode launchd` switches the trigger without further questions.
- **Brewfile location inside the repo:** edit `BREWFILE_PATH` in `~/.config/accio-brew/config`.
- **Stop using it:** run `accio-brew teardown`, then delete `~/.local/share/accio-brew`, `~/.config/accio-brew` and your `hosts/<host-id>` branch.

## Maintaining the target Brewfile

See what a Mac has that the target does not:

```sh
cd ~/.local/share/accio-brew/repo
git fetch origin
git diff origin/main origin/hosts/<host-id> -- Brewfile
```

Then change the target the way you change any file: create a branch from `main`, edit `Brewfile`, `git push`, and open a merge request in your host's web UI.

A host branch shares no history with `main`, so it cannot be merged into it directly. That is intentional: a single Mac's full dump is rarely what everyone should get.

## The two triggers

| | wrapper | launchd |
|---|---|---|
| When it syncs | right after `brew install`, `uninstall` or `upgrade` in an interactive zsh | every hour and at login |
| How it hooks in | a `brew` function sourced from `~/.zshrc` that calls the real brew and starts the sync in the background | an agent in `~/Library/LaunchAgents/io.accio-brew.plist` |
| What it misses | brew runs from scripts, other shells and GUI tools; `remove`, `tap` and other subcommands | nothing, up to an hour late |
| After a failed push | retried on the next triggering brew command | retried within the hour |

Only one trigger is installed at a time.

### Comparing them

Every sync writes lines like `2026-10-04T12:00:03Z my-mac pushed` to `~/Library/Logs/accio-brew.log`. The events are `start`, `no-change`, `committed`, `pushed`, `push-failed`, `diverged`, `clone-failed`, `dump-failed` and `done <seconds>s`.

| Criterion | How to measure |
|---|---|
| Latency | Time between the end of `brew install` and the `pushed` line. |
| Conflicts | None between Macs by design. `grep -c diverged` shows collisions of two Macs using the same host id. |
| Offline | Turn Wi-Fi off, install something, turn it on again; time until `pushed`. |
| Everyday impact | `time brew list` with and without the wrapper; visible output; the macOS "Background Items Added" notice for launchd. |

## Authentication in the background

Syncs run unattended and never prompt. `init` only accepts a repo URL that already works that way.

- **HTTPS:** the credentials must be in the macOS keychain (`git config --global credential.helper osxkeychain`).
- **SSH:** the key must load without a prompt. Put `UseKeychain yes` and `AddKeysToAgent yes` in `~/.ssh/config` and run `ssh-add --apple-use-keychain <key>` once. SSH agents that ask for a fingerprint on every use will make background syncs fail.

Failures are only visible in the log.

## Troubleshooting

- **`diverged` in the log:** another Mac pushes to the same `hosts/<host-id>` branch, or this Mac was restored from an older state. Give this Mac a unique `HOST_ID` in `~/.config/accio-brew/config`, or take over the branch with `rm -rf ~/.local/share/accio-brew/repo && accio-brew sync`.
- **`push-failed`:** the remote was unreachable. The commit stays local and is pushed by the next sync.
- **`local clone belongs to another repo`:** `REPO_URL` was edited by hand. Run `accio-brew init`.

## How this differs from the original spec

- Sync does not `git pull`. Each host branch has a single writer, so there is nothing to pull.
- The dump is written to `BREWFILE_PATH` on the host branch instead of into the shared target file.
- The config has an additional `HOST_ID`, because the macOS host name can change.
- Only taps, formulae and casks are dumped and cleaned up. Mac App Store apps, VS Code extensions and language packages are left alone.

## Limitations

- Host branches are an inventory. Nothing warns you about drift from the target; use the `git diff` above.
- Every Mac needs push access to `hosts/*`, and everyone with access to the data repo can see what is installed on each Mac.
- Sync commits are unsigned. A server rule that requires signed commits rejects them.
- A Mac with nothing installed through Homebrew is not synced.

## Development

```sh
tests/run.sh              # all tests
tests/run.sh wrapper      # tests whose name contains "wrapper"
```

| Path | Responsibility |
|---|---|
| `bin/accio-brew` | Entry point: loads `lib/` and dispatches the subcommand. |
| `lib/` | One file per concern, e.g. `config.sh`, `clone.sh`, `sync.sh`, `apply.sh`, `repo_choice.sh`, `wrapper_trigger.sh`, `launchd_trigger.sh`. |
| `modules/` | What gets installed on the Mac: the zsh `brew` wrapper and the launchd plist template. |
| `tests/test_*.sh` | Tests grouped by behaviour; every `test_*` function runs in its own sandbox. |
| `tests/fakes/` | Stand-ins for `brew`, `scutil`, `launchctl` and `ssh` that are put first on `PATH`. |

The tests use local bare repositories and a temporary `HOME`. They need nothing beyond macOS; `shellcheck` is used when installed.
