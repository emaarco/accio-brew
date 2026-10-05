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

Create an empty private repository on the git host of your choice, then run:

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
3. pushes this Mac's first dump to `hosts/<host-id>`,
4. installs a launchd agent that syncs every hour and at login.

Self-hosted server? Choose `paste clone URL`.

## Set up many Macs

Skip the questions with flags, for example in an onboarding script:

```sh
accio-brew init --repo-url git@gitlab.example.com:team/brewfiles.git </dev/null
accio-brew apply
```

## Background authentication

Syncs run unattended and never prompt. `init` only accepts a repo URL that already works that way.

- **HTTPS** → credentials in the macOS keychain (`git config --global credential.helper osxkeychain`).
- **SSH** → a key that loads without a prompt: `UseKeychain yes` and `AddKeysToAgent yes` in `~/.ssh/config`, then `ssh-add --apple-use-keychain <key>` once. Agents that ask for a fingerprint on every use make background syncs fail.

## Changing things later

- **Other repo** → `accio-brew init` again. Enter keeps the current value.
- **Brewfile location inside the repo** → edit `BREWFILE_PATH` in `~/.config/accio-brew/config`.
- **Stop using it** → `accio-brew teardown`, `brew uninstall accio-brew`, then delete `~/.local/share/accio-brew`, `~/.config/accio-brew` and your `hosts/<host-id>` branch.
