given_wrapped_brew() {
  INSTALLED_TOOL=$SANDBOX/installed-tool
  mkdir -p "$INSTALLED_TOOL/bin" "$INSTALLED_TOOL/modules"
  cp "$TOOL_ROOT/modules/wrapper.zsh" "$INSTALLED_TOOL/modules/"
  ln -s "$TOOL_ROOT/tests/fakes/recording-accio-brew" "$INSTALLED_TOOL/bin/accio-brew"
}

wrapped_brew() {
  HOMEBREW_PREFIX=$TOOL_ROOT/tests/fakes/homebrew-prefix zsh -c 'source "$1"; shift; brew "$@"' wrapper "$INSTALLED_TOOL/modules/wrapper.zsh" "$@"
}

sync_was_triggered() {
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -e "$HOME/sync.calls" ] && return 0
    sleep 0.2
  done
  return 1
}

assert_sync_after() {
  assert_exit 0 wrapped_brew "$@"
  sync_was_triggered || fail_test "no sync after: $*"
}

test_wrapper_passes_arguments_through() {
  given_wrapped_brew
  assert_exit 0 wrapped_brew list --formula "two words"
  assert_eq "list|--formula|two words|" "$(tr '\n' '|' < "$HOME/brew.arguments")"
}

test_wrapper_returns_exit_code_of_brew() {
  given_wrapped_brew
  FAKE_BREW_EXIT=3 assert_exit 3 wrapped_brew list
}

test_wrapper_does_not_sync_after_list() {
  given_wrapped_brew
  assert_exit 0 wrapped_brew list
  sync_was_triggered && fail_test "sync was triggered by list"
  return 0
}

test_wrapper_syncs_after_install() {
  given_wrapped_brew
  assert_sync_after install jq
}

test_wrapper_syncs_after_uninstall() {
  given_wrapped_brew
  assert_sync_after uninstall jq
}

test_wrapper_syncs_after_upgrade() {
  given_wrapped_brew
  assert_sync_after upgrade
}

test_wrapper_finds_subcommand_behind_flags() {
  given_wrapped_brew
  assert_sync_after --verbose install jq
}

test_wrapper_syncs_after_failed_install() {
  given_wrapped_brew
  FAKE_BREW_EXIT=1 assert_exit 1 wrapped_brew install jq missing
  sync_was_triggered || fail_test "no sync after failed install"
}

test_wrapper_calls_sync_subcommand() {
  given_wrapped_brew
  assert_sync_after install jq
  assert_eq "sync" "$(cat "$HOME/sync.calls")"
}
