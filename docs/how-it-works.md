# How it works

## Two repositories

- **accio-brew** contains the tool.
- **Your data repo** is where the tool writes. It is the only thing you configure.

## Everything on the default branch

| File on the default branch (`main`) | Holds | Changed by |
|---|---|---|
| `Brewfile` | the target: what a Mac *should* have | you, by merging requests from `propose/<host-id>` |
| `hosts/<host-id>/Brewfile` | what that Mac *has* installed | you, by merging requests from `sync/<host-id>` |

A sync runs `brew bundle dump` for taps, formulae and casks and compares the result with this Mac's file on the default branch. Without a difference it stops. Otherwise it rebuilds `sync/<host-id>` from the default branch, commits the dump as `chore: record packages of <host-id>`, pushes the branch and opens the request for it. Each Mac writes only its own file, so requests of different Macs never conflict.

| Repo on | The request |
|---|---|
| github.com | opened with `gh` |
| gitlab.com | opened with `glab` |
| anywhere else | the branch is pushed; open the request in your host's web UI |

While a request is unmerged, later syncs update it in place. A request that is closed without merging is opened again by the next sync that still sees a difference.

The sync is triggered by a launchd agent in `~/Library/LaunchAgents/io.accio-brew.plist`, every hour and at login. A sync that cannot reach the remote is retried with the next run.

`apply` reads the Brewfile from the default branch and hands it to `brew bundle install`, which also upgrades packages that are already installed.

`apply --cleanup` additionally runs `brew bundle cleanup --force` for taps, formulae and casks. It removes software without asking and resets Homebrew's tap trust settings to the ones in the target Brewfile.

Earlier versions pushed each dump to a branch `hosts/<host-id>`. Those branches are no longer written or read. Remove them with `git push origin --delete hosts/<host-id>`.

## Maintaining the target

One Mac's full dump is rarely what everyone should get, so a host file never changes the target. Packages reach the target through a request of their own:

```sh
accio-brew propose
```

`propose` syncs, branches `propose/<host-id>` from the default branch and appends every line of this Mac's dump that the target does not have yet. It only adds: nothing is removed or reordered, and lines are compared as a whole, so `brew "x"` is proposed again when the target holds `brew "x", restart_service: true`. Drop what should stay local in the review. The request is opened the same way as the one of a sync.

The branch is rebuilt from the default branch on every run, so running `propose` again updates a request that is still open. `init` runs the same proposal once while the target Brewfile is empty.

To remove packages from the target or to look first, use plain git:

```sh
git diff --no-index Brewfile hosts/<host-id>/Brewfile
```

Run the diff in a checkout of the default branch.

## Where things live

| Path | Content |
|---|---|
| `~/.config/accio-brew/config` | `REPO_URL`, `BREWFILE_PATH`, `HOST_ID` |
| `~/.local/share/accio-brew/repo` | The tool's clone of your data repo, checked out on `sync/<host-id>` |
| `~/Library/Logs/accio-brew.log` | One line per sync event |

## Non-goals

- No drift alarm — host files are an inventory. Use the `git diff` above.
- No Mac App Store apps, VS Code extensions or language packages — only taps, formulae and casks are dumped and cleaned up.
- No pick-list of your repos, no repo creation. Syncing needs plain git only; `gum` only decorates the setup dialog. `gh` and `glab` are required for repos on github.com and gitlab.com, where every sync that finds a difference calls them.
- No signed sync commits — a server rule that requires them rejects the pushes.
- No privacy between Macs — everyone with access to the data repo sees what each Mac has installed, and every Mac needs push access to `sync/*` and `propose/*`.

## Differences from the original spec

- Sync does not `git pull`: it rebuilds its branch from the default branch on every run.
- The dump goes to `hosts/<host-id>/Brewfile` instead of into the shared target file, and reaches the default branch through a request.
- The config has an additional `HOST_ID`, because the macOS host name can change.
