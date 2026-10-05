given_tool_installed_by_brew() {
  export ACCIO_BREW_ROOT=$SANDBOX/opt/accio-brew/libexec
  mkdir -p "$SANDBOX/opt/accio-brew"
  ln -s "$TOOL_ROOT" "$ACCIO_BREW_ROOT"
}

given_tool_on_path() {
  mkdir -p "$SANDBOX/brew-bin"
  ln -s "$TOOL_ROOT/bin/accio-brew" "$SANDBOX/brew-bin/accio-brew"
  export PATH=$SANDBOX/brew-bin:$PATH
}

test_wrapper_block_uses_stable_brew_path() {
  given_tool_installed_by_brew
  given_initialised_host wrapper
  assert_contains "source $ACCIO_BREW_ROOT/modules/wrapper.zsh" "$(cat "$HOME/.zshrc")"
}

test_launchd_plist_uses_stable_brew_path() {
  given_tool_installed_by_brew
  given_initialised_host launchd
  assert_contains "<string>$ACCIO_BREW_ROOT/bin/accio-brew</string>" "$(cat "$PLIST")"
}

test_init_links_no_binary_when_tool_is_on_path() {
  given_tool_on_path
  given_initialised_host
  assert_missing "$HOME/.local/bin/accio-brew"
}

test_init_gives_no_path_hint_when_tool_is_on_path() {
  given_tool_on_path
  given_initialised_host
  assert_not_contains "Add accio-brew to your PATH" "$(last_output)"
}
