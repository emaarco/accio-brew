# Troubleshooting

Syncs run in the background, so failures only show up in `~/Library/Logs/accio-brew.log`. Every sync is recorded there, also the ones `init`, `propose`, `apply` or you start by hand. Run `accio-brew sync` to see the same events in your terminal.

| Event | Meaning | What to do |
|---|---|---|
| `no-change` | This Mac's file on the default branch matches what is installed. | — |
| `pushed` | A new dump is on `sync/<host-id>`. | Merge its request. |
| `unmerged` | The dump on `sync/<host-id>` is current, its request is not merged yet. | Merge its request. |
| `fetch-failed` | The remote was unreachable. | Nothing if you were offline; the next sync tries again. Otherwise check [background authentication](./getting-started.md#background-authentication). |
| `push-failed` | The remote refused the push to `sync/<host-id>`. | Check that this Mac may push to `sync/*`. |
| `request-failed` | `gh` or `glab` could not open the request. | Run `gh auth status` or `glab auth status`; the next sync tries again. |
| `clone-failed` | The first sync could not clone the data repo. | Check the network and `REPO_URL`. |
| `dump-failed` | `brew bundle dump` failed or returned nothing. | Run `brew bundle dump --file=-` to see why. |

## Messages

- **`no config found, run accio-brew init`** — this Mac is not set up yet.
- **`local clone belongs to another repo`** — `REPO_URL` was edited by hand. Run `accio-brew init`.
- **`target Brewfile not found on remote`** — the default branch has no file at `BREWFILE_PATH`. Run `accio-brew init` again to get a proposal for it.
- **`github.com repos need gh`** · **`gitlab.com repos need glab`** — install the CLI and log in; the message shows the commands.
- **`gh is not logged in`** · **`glab is not logged in`** — run `gh auth login` or `glab auth login`.
- **`cannot open a pull request for sync/<host-id>`** · **`cannot open a merge request for sync/<host-id>`** — `gh` or `glab` refused; its own message stands above this one.
- **`cannot push propose/<host-id>`** — this Mac may not push to `propose/*`, or the remote is unreachable.
- **`cannot determine the default branch`** — the remote's `HEAD` points to a branch that does not exist. Set the default branch in your host's web UI.
