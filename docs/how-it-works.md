# How it works

## Two repositories

- **accio-brew** contains the tool.
- **Your data repo** is where the tool writes. It is the only thing you configure.

## Two kinds of branches

| Branch | Its `Brewfile` holds | Written by |
|---|---|---|
| default branch (`main`) | the target: what a Mac *should* have | you, by merging requests |
| `hosts/<host-id>` | what that Mac *has* installed | accio-brew on that Mac, automatically |
| `propose/<host-id>` | the target plus what that Mac has on top | `accio-brew propose` on that Mac |

A sync runs `brew bundle dump` for taps, formulae and casks, commits the result as `sync(<host-id>): <timestamp>` and pushes it to the host branch. Each host branch has exactly one writer, so a sync never pulls and Macs never conflict.

The sync is triggered by a launchd agent in `~/Library/LaunchAgents/io.accio-brew.plist`, every hour and at login. A failed push is retried with the next run.

`apply` reads the Brewfile from the default branch and hands it to `brew bundle install`, which also upgrades packages that are already installed.

`apply --cleanup` additionally runs `brew bundle cleanup --force` for taps, formulae and casks. It removes software without asking and resets Homebrew's tap trust settings to the ones in the target Brewfile.

## Maintaining the target

A host branch shares no history with `main`, so it cannot be merged into it. That is on purpose — one Mac's full dump is rarely what everyone should get. Packages reach the target through a request instead:

```sh
accio-brew propose
```

`propose` syncs, branches `propose/<host-id>` from the default branch and appends every line of this Mac's dump that the target does not have yet. It only adds: nothing is removed or reordered, and lines are compared as a whole, so `brew "x"` is proposed again when the target holds `brew "x", restart_service: true`. Drop what should stay local in the review.

| Repo on | The request |
|---|---|
| github.com | opened with `gh` |
| gitlab.com | opened with `glab` |
| anywhere else | the branch is pushed; open the request in your host's web UI |

The branch is rebuilt from the default branch on every run, so running `propose` again updates a request that is still open. `init` runs the same proposal once while the target Brewfile is empty.

To remove packages from the target or to look first, use plain git:

```sh
cd ~/.local/share/accio-brew/repo
git fetch origin
git diff origin/main origin/hosts/<host-id> -- Brewfile
```

## Where things live

| Path | Content |
|---|---|
| `~/.config/accio-brew/config` | `REPO_URL`, `BREWFILE_PATH`, `HOST_ID` |
| `~/.local/share/accio-brew/repo` | The tool's clone of your data repo, checked out on the host branch |
| `~/Library/Logs/accio-brew.log` | One line per sync event |

## Non-goals

- No drift alarm — host branches are an inventory. Use the `git diff` above.
- No Mac App Store apps, VS Code extensions or language packages — only taps, formulae and casks are dumped and cleaned up.
- No pick-list of your repos, no repo creation. Syncing needs plain git only; `gum` only decorates the setup dialog. `gh` and `glab` are required for repos on github.com and gitlab.com, and only `init` and `propose` call them — never a background sync.
- No signed sync commits — a server rule that requires them rejects the pushes.
- No privacy between Macs — everyone with access to the data repo sees what each Mac has installed, and every Mac needs push access to `hosts/*` and `propose/*`.

## Differences from the original spec

- Sync does not `git pull`: each host branch has a single writer, so there is nothing to pull.
- The dump goes to `BREWFILE_PATH` on the host branch instead of into the shared target file.
- The config has an additional `HOST_ID`, because the macOS host name can change.
