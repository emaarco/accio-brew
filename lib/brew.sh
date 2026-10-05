DUMPED_TYPES=(--tap --formula --cask)

dump_installed_packages() {
  local dump=$1
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump --force --no-describe --no-restart "${DUMPED_TYPES[@]}" --file="$dump" >/dev/null 9>&- && [ -s "$dump" ]
}

install_brewfile() {
  brew bundle install --file="$1"
}

uninstall_everything_missing_in() {
  brew bundle cleanup --force "${DUMPED_TYPES[@]}" --file="$1"
}
