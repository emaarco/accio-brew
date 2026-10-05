# Troubleshooting

Syncs run in the background, so failures only show up in `~/Library/Logs/accio-brew.log`. Run `accio-brew sync` by hand to see the same events in your terminal.

| Event | Meaning | What to do |
|---|---|---|
| `no-change` | Nothing was installed or removed. | — |
| `committed` · `pushed` | A new dump was recorded · it is on the remote. | — |
| `push-failed` | The remote was unreachable or refused the push. The commit stays local. | Nothing if you were offline; the next sync pushes it. Otherwise check [background authentication](./getting-started.md#background-authentication). |
| `diverged` | Another Mac pushes to the same host branch, or this Mac was restored from an older state. | Give this Mac a unique `HOST_ID` in `~/.config/accio-brew/config`, or take over the branch with `rm -rf ~/.local/share/accio-brew/repo && accio-brew sync`. |
| `clone-failed` | The first sync could not clone the data repo. | Check the network and `REPO_URL`. |
| `dump-failed` | `brew bundle dump` failed or returned nothing. | Run `brew bundle dump --file=-` to see why. |

## Messages

- **`no config found, run accio-brew init`** — this Mac is not set up yet.
- **`local clone belongs to another repo`** — `REPO_URL` was edited by hand. Run `accio-brew init`.
- **`incomplete accio-brew block in ~/.zshrc`** — one of the two marker lines is missing. Remove the block by hand, then run `accio-brew init` again.
- **`target Brewfile not found on remote`** — the default branch has no file at `BREWFILE_PATH`.
