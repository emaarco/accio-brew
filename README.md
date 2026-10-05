# accio-brew

> *Accio Brew!* — summon your Homebrew setup onto any Mac.

Every Mac drifts: a formula here, a cask there, and nobody remembers what the new laptop is missing. **accio-brew** records what each Mac has installed in a git repo of yours, and installs one curated Brewfile wherever you call for it. Syncing speaks plain `git` only, so it works with GitHub, GitLab, Bitbucket, Gitea and self-hosted servers alike. On github.com and gitlab.com it also opens the pull request that brings new packages into the target, through `gh` or `glab`.

> Early development. Expect the shape to move.

## ⚡ Install

```sh
brew install emaarco/tap/accio-brew
accio-brew init
```

`init` asks where your Brewfile repo lives, pushes this Mac's first dump, proposes it as the first target and schedules the hourly sync. All you bring is an empty private repo — and `gh` or `glab`, logged in, when it lives on github.com or gitlab.com. → [Getting started](./docs/getting-started.md)

The formula is served from the [`emaarco/homebrew-tap`](https://github.com/emaarco/homebrew-tap) repository.

## 🪄 The spell

| Branch in your repo | Its `Brewfile` holds | Written by |
|---|---|---|
| `main` | the target: what a Mac *should* have | you, by merging the requests `propose` opens |
| `propose/<host-id>` | the target plus what that Mac has on top | `accio-brew propose` on that Mac |
| `hosts/<host-id>` | what that Mac *has* installed | accio-brew on that Mac, automatically |

Each Mac only pushes to its own branches — no conflicts between Macs, and `main` can stay protected. → [How it works](./docs/how-it-works.md)

## 📜 Usage

| Command | Does |
|---|---|
| `accio-brew init` | Guided setup. Cast it again to change the repo. |
| `accio-brew sync` | Dump the installed packages and push them to `hosts/<host-id>`. |
| `accio-brew propose` | Open a pull request that adds this Mac's extra packages to the target. |
| `accio-brew apply` | Install everything from the target Brewfile on `main`. |
| `accio-brew apply --cleanup` | Also uninstall what is not in the target — **without asking**. |
| `accio-brew teardown` | Remove the launchd agent. |

## ⏳ Trigger

A launchd agent syncs every hour and at login, in the background.

→ [Troubleshooting](./docs/troubleshooting.md)

## 🤝 Contributing

Bug, idea or new spell? See [CONTRIBUTING.md](./CONTRIBUTING.md). Tests run with `tests/run.sh` and need nothing beyond macOS.

## 🎭 Companions

More spells live in [`hogwarts`](https://github.com/emaarco/hogwarts). *Patronum guards, Revelio reveals — Accio summons.*

---

*Created with ♥ by [Marco Schaeck](https://www.linkedin.com/in/schaeckm) · [LinkedIn](https://www.linkedin.com/in/schaeckm) · [Medium](https://medium.com/@emaarco)*
