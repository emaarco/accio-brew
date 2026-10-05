# accio-brew

> *Accio Brew!* — summon your Homebrew setup onto any Mac.

Every Mac drifts: a formula here, a cask there, and nobody remembers what the new laptop is missing. **accio-brew** records what each Mac has installed in a git repo of yours, and installs one curated Brewfile wherever you call for it. It speaks plain `git` only, so it works with GitHub, GitLab, Bitbucket, Gitea and self-hosted servers alike.

> Early development. Expect the shape to move.

## ⚡ Install

```sh
brew install emaarco/tap/accio-brew
accio-brew init
```

`init` asks where your Brewfile repo lives and how to trigger the sync, then pushes this Mac's first dump. All you bring is an empty private repo. → [Getting started](./docs/getting-started.md)

## 🪄 The spell

| Branch in your repo | Its `Brewfile` holds | Written by |
|---|---|---|
| `main` | the target: what a Mac *should* have | you, via merge requests |
| `hosts/<host-id>` | what that Mac *has* installed | accio-brew on that Mac, automatically |

Each Mac only pushes to its own branch — no conflicts between Macs, and `main` can stay protected. → [How it works](./docs/how-it-works.md)

## 📜 Usage

| Command | Does |
|---|---|
| `accio-brew init` | Guided setup. Cast it again to change the repo or the trigger. |
| `accio-brew sync` | Dump the installed packages and push them to `hosts/<host-id>`. |
| `accio-brew apply` | Install everything from the target Brewfile on `main`. |
| `accio-brew apply --cleanup` | Also uninstall what is not in the target — **without asking**. |
| `accio-brew teardown` | Remove the trigger. |

## ⏳ Triggers

| `wrapper` | `launchd` |
|---|---|
| Syncs right after `brew install`, `uninstall` or `upgrade` in your zsh. | Syncs every hour in the background. |

→ [Triggers compared](./docs/triggers.md) · [Troubleshooting](./docs/troubleshooting.md)

## 🤝 Contributing

Bug, idea or new spell? See [CONTRIBUTING.md](./CONTRIBUTING.md). Tests run with `tests/run.sh` and need nothing beyond macOS.

## 🎭 Companions

More spells live in [`hogwarts`](https://github.com/emaarco/hogwarts). *Patronum guards, Revelio reveals — Accio summons.*

---

*Created with ♥ by [Marco Schaeck](https://www.linkedin.com/in/schaeckm) · [LinkedIn](https://www.linkedin.com/in/schaeckm) · [Medium](https://medium.com/@emaarco)*
