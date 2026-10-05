# accio-brew

> *Accio Brew!* — summon your Homebrew setup onto any Mac.

Every Mac you own drifts: a formula here, a cask there, and nobody remembers what the new laptop is missing. **accio-brew** writes down what each Mac has installed in a git repo of yours, and installs one curated Brewfile wherever you call for it.

It speaks plain `git` only — no GitHub or GitLab API — so it works with GitHub, GitLab, Bitbucket, Gitea and self-hosted servers alike.

> Early development. Expect the shape to move.

## 🪄 The spell

You bring an empty private repo, your **data repo**. accio-brew keeps two kinds of branches in it:

| Branch | Its `Brewfile` holds | Written by |
|---|---|---|
| `main` | the target: what a Mac *should* have | you, via merge requests |
| `hosts/<host-id>` | what that Mac *has* installed | accio-brew on that Mac, automatically |

Each Mac only ever pushes to its own branch. Macs never conflict with each other, and `main` can stay protected.

## ⚡ Install

```sh
brew install emaarco/tap/accio-brew
accio-brew init
```

`init` guides you through two questions: where your data repo lives (github.com, gitlab.com or a pasted clone URL) and how sync should be triggered (`wrapper` or `launchd`). With [`gum`](https://github.com/charmbracelet/gum) installed — the formula recommends it — you pick with the arrow keys; without it, or with `brew install --without-gum`, you get plain numbered questions:

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

It checks that the repo is reachable without a password prompt, creates `main` with an empty Brewfile if the repo is empty, pushes this Mac's first dump and installs the trigger you chose. Self-hosted server? Paste the clone URL.

Onboarding a whole team? Skip the questions:

```sh
accio-brew init --repo-url git@gitlab.example.com:team/brewfiles.git --mode launchd </dev/null
```

Update with `brew upgrade accio-brew`.

<details>
<summary>Without the tap</summary>

```sh
git clone https://github.com/emaarco/accio-brew.git ~/.local/share/accio-brew/tool
~/.local/share/accio-brew/tool/bin/accio-brew init
```

Keep the clone outside `~/Documents`, `~/Desktop` and `~/Downloads` — macOS blocks background agents from reading those. Update with `git pull`.

</details>

## 📜 Usage

| Command | Does |
|---|---|
| `accio-brew init` | Guided setup. Cast it again to change the repo or the trigger. |
| `accio-brew sync` | Dump the installed packages and push them to `hosts/<host-id>`. |
| `accio-brew apply` | Install everything from the target Brewfile on `main`. Also upgrades what is already installed. |
| `accio-brew apply --cleanup` | Additionally uninstall every tap, formula and cask that is not in the target. |
| `accio-brew teardown` | Remove the trigger. Run it before `brew uninstall accio-brew`. |

> `apply --cleanup` is the vanishing spell: it removes software **without asking** and resets Homebrew's tap trust settings to the ones in the target Brewfile.

## ⏳ Two triggers

| | `wrapper` | `launchd` |
|---|---|---|
| Syncs | right after `brew install`, `uninstall` or `upgrade` in an interactive zsh | every hour and at login |
| Hooks in via | a `brew` function in `~/.zshrc` that calls the real brew and syncs in the background | an agent in `~/Library/LaunchAgents/io.accio-brew.plist` |
| Misses | brew runs from scripts, other shells and GUI tools; `remove`, `tap` and other subcommands | nothing, up to an hour late |
| After a failed push | retries on the next triggering brew command | retries within the hour |

Only one trigger is installed at a time. Switch with `accio-brew init --mode launchd` or `--mode wrapper`.

## 🧪 Maintaining the target

See what a Mac has that the target does not:

```sh
cd ~/.local/share/accio-brew/repo
git fetch origin
git diff origin/main origin/hosts/<host-id> -- Brewfile
```

Then change the target like any other file: branch from `main`, edit `Brewfile`, `git push`, open a merge request in your host's web UI.

A host branch shares no history with `main`, so it cannot be merged into it. That is on purpose — one Mac's full dump is rarely what everyone should get.

## 🔧 Changing things later

- **Other repo or other trigger** → `accio-brew init` again. Enter keeps the current value.
- **Brewfile location inside the repo** → edit `BREWFILE_PATH` in `~/.config/accio-brew/config`.
- **Stop using it** → `accio-brew teardown`, `brew uninstall accio-brew`, then delete `~/.local/share/accio-brew`, `~/.config/accio-brew` and your `hosts/<host-id>` branch.

## 🔐 Background authentication

Syncs run unattended and never prompt. `init` only accepts a repo URL that already works that way.

- **HTTPS** → credentials in the macOS keychain (`git config --global credential.helper osxkeychain`).
- **SSH** → a key that loads without a prompt: `UseKeychain yes` and `AddKeysToAgent yes` in `~/.ssh/config`, then `ssh-add --apple-use-keychain <key>` once. Agents that ask for a fingerprint on every use make background syncs fail.

## 🔍 What happened?

Every sync writes lines like `2026-10-04T12:00:03Z my-mac pushed` to `~/Library/Logs/accio-brew.log`. Failures only show up there.

| Event | Meaning |
|---|---|
| `no-change` · `committed` · `pushed` | Nothing new · new dump recorded · dump is on the remote. |
| `push-failed` | The remote was unreachable. The commit stays local and the next sync pushes it. |
| `diverged` | Another Mac pushes to the same host branch, or this Mac was restored from an older state. Give it a unique `HOST_ID` in the config, or take over the branch with `rm -rf ~/.local/share/accio-brew/repo && accio-brew sync`. |
| `clone-failed` · `dump-failed` | The first clone needs the network · `brew bundle dump` failed or returned nothing. |

`local clone belongs to another repo` means `REPO_URL` was edited by hand — run `accio-brew init`.

The same log answers how the two triggers compare:

| Criterion | How to measure |
|---|---|
| Latency | Time between the end of `brew install` and the `pushed` line. |
| Conflicts | None between Macs by design; `grep -c diverged` shows two Macs sharing a host id. |
| Offline | Wi-Fi off, install something, Wi-Fi on; time until `pushed`. |
| Everyday impact | `time brew list` with and without the wrapper; the macOS "Background Items Added" notice for launchd. |

## 🚫 Non-goals

- No drift alarm — host branches are an inventory. Use the `git diff` above.
- No Mac App Store apps, VS Code extensions or language packages — only taps, formulae and casks are dumped and cleaned up.
- No host API, no pick-list of your repos, no repo creation. Plain git stays the only hard dependency; `gum` only decorates the setup dialog and never runs during a sync.
- No signed sync commits — a server rule that requires them rejects the pushes.
- No privacy between Macs — everyone with access to the data repo sees what each Mac has installed, and every Mac needs push access to `hosts/*`.

## 📐 Differences from the original spec

- Sync does not `git pull`: each host branch has a single writer, so there is nothing to pull.
- The dump goes to `BREWFILE_PATH` on the host branch instead of into the shared target file.
- The config has an additional `HOST_ID`, because the macOS host name can change.

## 🤝 Contributing

```sh
tests/run.sh              # all tests
tests/run.sh wrapper      # tests whose name contains "wrapper"
```

| Path | Responsibility |
|---|---|
| `bin/accio-brew` | Entry point: loads `lib/` and dispatches the subcommand. |
| `lib/` | One file per concern, e.g. `config.sh`, `clone.sh`, `sync.sh`, `apply.sh`, `repo_choice.sh`, `prompt_gum.sh`, `prompt_plain.sh`, `wrapper_trigger.sh`, `launchd_trigger.sh`. |
| `modules/` | What gets installed on the Mac: the zsh `brew` wrapper and the launchd plist template. |
| `tests/test_*.sh` | Tests grouped by behaviour; every `test_*` function runs in its own sandbox. |
| `tests/fakes/` | Stand-ins for `brew`, `scutil`, `launchctl`, `ssh` and `gum`. |

The formula lives in [`emaarco/homebrew-tap`](https://github.com/emaarco/homebrew-tap).

The tests use local bare repositories and a temporary `HOME`. They need nothing beyond macOS; `shellcheck` is used when installed.

## 🎭 Companions

More spells live in [`hogwarts`](https://github.com/emaarco/hogwarts), a spellbook of Claude Code plugins. *Patronum guards, Revelio reveals — Accio summons.*

---

*Created with ♥ by [Marco Schaeck](https://www.linkedin.com/in/schaeckm) · [LinkedIn](https://www.linkedin.com/in/schaeckm) · [Medium](https://medium.com/@emaarco)*
