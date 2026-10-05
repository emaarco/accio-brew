# Getting started

## Install

```sh
brew install emaarco/tap/accio-brew
```

The formula recommends [`gum`](https://github.com/charmbracelet/gum) for nicer setup dialogs. Skip it with `brew install --without-gum emaarco/tap/accio-brew`. Update with `brew upgrade accio-brew`.

<details>
<summary>Without the tap</summary>

```sh
git clone https://github.com/emaarco/accio-brew.git ~/.local/share/accio-brew/tool
~/.local/share/accio-brew/tool/bin/accio-brew init
```

Keep the clone outside `~/Documents`, `~/Desktop` and `~/Downloads` — macOS blocks background agents from reading those. Update with `git pull`.

</details>

## Set up a Mac

Create an empty private repository on the git host of your choice. For github.com install and log in `gh` (`brew install gh && gh auth login`), for gitlab.com `glab` (`brew install glab && glab auth login`) — `init` stops without them. Any other host needs nothing but git. Then run:

```sh
accio-brew init
```

With `gum` you pick with the arrow keys. Without it you get plain numbered questions:

```
Where is your Brewfile repo?
  1) github.com
  2) gitlab.com
  3) paste clone URL
Choice [1]:
Repository (owner/name):
```

`init` then

1. checks that the repo is reachable without a password prompt,
2. creates `main` with an empty Brewfile if the repo is empty,
3. pushes this Mac's first dump as `sync/<host-id>` and requests it as `hosts/<host-id>/Brewfile`,
4. installs a launchd agent that syncs every hour and at login,
5. proposes this Mac's packages as `propose/<host-id>` while the target Brewfile is still empty.

On github.com and gitlab.com both requests are opened for you. Merge them and `main` holds this Mac's inventory and your first target. Later packages travel the same way with `accio-brew propose`.

Self-hosted server? Choose `paste clone URL`.

## Set up many Macs

Skip the questions with flags, for example in an onboarding script:

```sh
accio-brew init --repo-url git@gitlab.example.com:team/brewfiles.git </dev/null
accio-brew apply
```

## Background authentication

Syncs run unattended and never prompt. `init` only accepts a repo URL that already works that way. On github.com and gitlab.com the sync also calls `gh` or `glab`, which must stay logged in.

- **HTTPS** → credentials in the macOS keychain (`git config --global credential.helper osxkeychain`).
- **SSH** → a key that loads without a prompt: `UseKeychain yes` and `AddKeysToAgent yes` in `~/.ssh/config`, then `ssh-add --apple-use-keychain <key>` once. Agents that ask for a fingerprint on every use make background syncs fail.

## Changing things later

- **Other repo** → `accio-brew init` again. Enter keeps the current value.
- **Target Brewfile location inside the repo** → edit `BREWFILE_PATH` in `~/.config/accio-brew/config`. Host files stay in `hosts/<host-id>/Brewfile`.
- **Stop using it** → `accio-brew teardown`, `brew uninstall accio-brew`, then delete `~/.local/share/accio-brew`, `~/.config/accio-brew`, your `sync/<host-id>` and `propose/<host-id>` branches and `hosts/<host-id>/` on `main`.
