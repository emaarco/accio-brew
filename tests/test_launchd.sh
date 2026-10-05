test_init_renders_valid_plist() {
  given_initialised_host
  assert_exit 0 plutil -lint "$PLIST"
  assert_not_contains "__" "$(cat "$PLIST")"
}

test_plist_runs_the_tool() {
  given_initialised_host
  assert_contains "<string>$TOOL_ROOT/bin/accio-brew</string>" "$(cat "$PLIST")"
}

test_plist_puts_brew_on_path() {
  given_initialised_host
  assert_contains "<string>$TOOL_ROOT/tests/fakes:/usr/bin:/bin:/usr/sbin:/sbin</string>" "$(cat "$PLIST")"
}

test_plist_sends_only_errors_to_log_file() {
  given_initialised_host
  assert_not_contains "StandardOutPath" "$(cat "$PLIST")"
  assert_contains "StandardErrorPath" "$(cat "$PLIST")"
}

test_init_loads_agent() {
  given_initialised_host
  assert_contains "bootstrap gui/$(id -u) $PLIST" "$(launchctl_calls)"
}

test_first_init_unloads_no_agent() {
  given_initialised_host
  assert_not_contains "bootout" "$(launchctl_calls)"
}

test_repeated_init_reloads_agent() {
  given_initialised_host
  assert_exit 0 init_with_flags
  assert_eq "bootstrap bootout bootstrap" "$(launchctl_calls | cut -d ' ' -f 1 | xargs)"
}

test_init_leaves_zshrc_alone() {
  given_initialised_host
  assert_missing "$HOME/.zshrc"
}

test_teardown_removes_agent() {
  given_initialised_host
  assert_exit 0 "$ACCIO_BREW" teardown
  assert_missing "$PLIST"
  assert_contains "bootout gui/$(id -u)/io.accio-brew" "$(launchctl_calls)"
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
