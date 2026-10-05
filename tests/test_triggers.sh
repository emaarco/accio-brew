test_wrapper_mode_adds_one_block_to_zshrc() {
  given_initialised_host wrapper
  assert_eq 1 "$(wrapper_block_count)"
}

test_wrapper_block_sources_wrapper_module() {
  given_initialised_host wrapper
  assert_contains "source $TOOL_ROOT/modules/wrapper.zsh" "$(cat "$HOME/.zshrc")"
}

test_repeated_init_keeps_a_single_wrapper_block() {
  given_initialised_host wrapper
  assert_exit 0 switch_mode wrapper
  assert_eq 1 "$(wrapper_block_count)"
}

test_wrapper_block_starts_on_its_own_line() {
  printf 'export EDITOR=vim' > "$HOME/.zshrc"
  given_initialised_host wrapper
  assert_eq "export EDITOR=vim" "$(head -1 "$HOME/.zshrc")"
}

test_teardown_restores_zshrc() {
  printf 'export EDITOR=vim\n' > "$HOME/.zshrc"
  cp "$HOME/.zshrc" "$SANDBOX/zshrc.before"
  given_initialised_host wrapper
  assert_exit 0 "$ACCIO_BREW" teardown
  assert_same_file "$SANDBOX/zshrc.before" "$HOME/.zshrc"
}

test_teardown_refuses_incomplete_wrapper_block() {
  given_initialised_host wrapper
  grep -v '^# <<< accio-brew <<<$' "$HOME/.zshrc" > "$SANDBOX/zshrc.damaged"
  cp "$SANDBOX/zshrc.damaged" "$HOME/.zshrc"
  assert_exit 1 "$ACCIO_BREW" teardown
  assert_same_file "$SANDBOX/zshrc.damaged" "$HOME/.zshrc"
}

test_launchd_mode_renders_valid_plist() {
  given_initialised_host launchd
  assert_exit 0 plutil -lint "$PLIST"
  assert_not_contains "__" "$(cat "$PLIST")"
}

test_launchd_plist_runs_the_tool() {
  given_initialised_host launchd
  assert_contains "<string>$TOOL_ROOT/bin/accio-brew</string>" "$(cat "$PLIST")"
}

test_launchd_plist_puts_brew_on_path() {
  given_initialised_host launchd
  assert_contains "<string>$TOOL_ROOT/tests/fakes:/usr/bin:/bin:/usr/sbin:/sbin</string>" "$(cat "$PLIST")"
}

test_launchd_mode_loads_agent() {
  given_initialised_host launchd
  assert_contains "bootstrap gui/$(id -u) $PLIST" "$(launchctl_calls)"
}

test_launchd_mode_adds_no_wrapper_block() {
  given_initialised_host launchd
  assert_missing "$HOME/.zshrc"
}

test_switching_to_launchd_removes_wrapper_block() {
  given_initialised_host wrapper
  assert_exit 0 switch_mode launchd
  assert_eq 0 "$(wrapper_block_count)"
}

test_switching_to_wrapper_removes_launchd_agent() {
  given_initialised_host launchd
  assert_exit 0 switch_mode wrapper
  assert_missing "$PLIST"
  assert_contains "bootout gui/$(id -u)/io.accio-brew" "$(launchctl_calls)"
}

test_teardown_removes_launchd_agent() {
  given_initialised_host launchd
  assert_exit 0 "$ACCIO_BREW" teardown
  assert_missing "$PLIST"
}

test_teardown_removes_binary_link() {
  given_initialised_host
  assert_exit 0 "$ACCIO_BREW" teardown
  assert_missing "$HOME/.local/bin/accio-brew"
}

test_teardown_keeps_config() {
  given_initialised_host
  assert_exit 0 "$ACCIO_BREW" teardown
  assert_exists "$CONFIG"
}
