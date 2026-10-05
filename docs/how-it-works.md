# How it works

## Two repositories

- **accio-brew** contains the tool.
- **Your data repo** is where the tool writes. It is the only thing you configure.

## Two kinds of branches

| Branch | Its `Brewfile` holds | Written by |
|---|---|---|
| default branch (`main`) | the target: what a Mac *should* have | you, via merge requests |
| `hosts/<host-id>` | what that Mac *has* installed | accio-brew on that Mac, automatically |

A sync runs `brew bundle dump` for taps, formulae and casks, commits the result as `sync(<host-id>): <timestamp>` and pushes it to the host branch. Each host branch has exactly one writer, so a sync never pulls and Macs never conflict.

`apply` reads the Brewfile from the default branch and hands it to `brew bundle install`, which also upgrades packages that are already installed.

`apply --cleanup` additionally runs `brew bundle cleanup --force` for taps, formulae and casks. It removes software without asking and resets Homebrew's tap trust settings to the ones in the target Brewfile.

## Maintaining the target

See what a Mac has that the target does not:

```sh
cd ~/.local/share/accio-brew/repo
git fetch origin
git diff origin/main origin/hosts/<host-id> -- Brewfile
```

Then change the target like any other file: branch from `main`, edit `Brewfile`, `git push`, open a merge request in your host's web UI.

A host branch shares no history with `main`, so it cannot be merged into it. That is on purpose — one Mac's full dump is rarely what everyone should get.

## Where things live

| Path | Content |
|---|---|
| `~/.config/accio-brew/config` | `REPO_URL`, `BREWFILE_PATH`, `SYNC_MODE`, `HOST_ID` |
| `~/.local/share/accio-brew/repo` | The tool's clone of your data repo, checked out on the host branch |
| `~/Library/Logs/accio-brew.log` | One line per sync event |

## Non-goals

- No drift alarm — host branches are an inventory. Use the `git diff` above.
- No Mac App Store apps, VS Code extensions or language packages — only taps, formulae and casks are dumped and cleaned up.
- No host API, no pick-list of your repos, no repo creation. Plain git stays the only hard dependency; `gum` only decorates the setup dialog and never runs during a sync.
- No signed sync commits — a server rule that requires them rejects the pushes.
- No privacy between Macs — everyone with access to the data repo sees what each Mac has installed, and every Mac needs push access to `hosts/*`.

## Differences from the original spec

- Sync does not `git pull`: each host branch has a single writer, so there is nothing to pull.
- The dump goes to `BREWFILE_PATH` on the host branch instead of into the shared target file.
- The config has an additional `HOST_ID`, because the macOS host name can change.
