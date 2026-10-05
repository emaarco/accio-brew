# Triggers

Both triggers run the same `accio-brew sync`. Only one is installed at a time; switch with `accio-brew init --mode wrapper` or `--mode launchd`.

| | `wrapper` | `launchd` |
|---|---|---|
| Syncs | right after `brew install`, `uninstall` or `upgrade` in an interactive zsh | every hour and at login |
| Hooks in via | a `brew` function in `~/.zshrc` that calls the real brew and syncs in the background | an agent in `~/Library/LaunchAgents/io.accio-brew.plist` |
| Misses | brew runs from scripts, other shells and GUI tools; `remove`, `tap` and other subcommands | nothing, up to an hour late |
| After a failed push | retries on the next triggering brew command | retries within the hour |

## Comparing them

Every sync writes lines like `2026-10-04T12:00:03Z my-mac pushed` to `~/Library/Logs/accio-brew.log`. That log answers how the triggers behave on your Macs:

| Criterion | How to measure |
|---|---|
| Latency | Time between the end of `brew install` and the `pushed` line. |
| Conflicts | None between Macs by design; `grep -c diverged` shows two Macs sharing a host id. |
| Offline | Wi-Fi off, install something, Wi-Fi on; time until `pushed`. |
| Everyday impact | `time brew list` with and without the wrapper; the macOS "Background Items Added" notice for launchd. |
