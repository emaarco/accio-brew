apply() {
  "$ACCIO_BREW" apply "$@"
}

test_apply_installs_target_brewfile() {
  given_initialised_host
  assert_exit 0 apply
  assert_eq 'brew "target"' "$(cat "$HOME/installed.target")"
}

test_apply_does_not_clean_up_by_default() {
  given_initialised_host
  assert_exit 0 apply
  assert_not_contains "bundle cleanup" "$(brew_calls)"
}

test_apply_with_cleanup_removes_only_dumped_types() {
  given_initialised_host
  assert_exit 0 apply --cleanup
  assert_contains "bundle cleanup --force --tap --formula --cask --file=" "$(brew_calls)"
}

test_apply_sees_target_changes_made_after_init() {
  given_initialised_host
  publish_target "$REMOTE" newer-target
  assert_exit 0 apply
  assert_eq 'brew "newer-target"' "$(cat "$HOME/installed.target")"
}

test_apply_syncs_afterwards() {
  given_initialised_host
  set_installed git jq
  assert_exit 0 apply
  assert_contains 'brew "jq"' "$(remote_file hosts/a)"
}

test_apply_rejects_unknown_option() {
  given_initialised_host
  assert_exit 1 apply --clean
  assert_contains "unknown option: --clean" "$(last_output)"
}

test_apply_returns_brew_failure() {
  given_initialised_host
  FAKE_INSTALL_EXIT=7 assert_exit 7 apply
}

test_apply_skips_cleanup_after_brew_failure() {
  given_initialised_host
  FAKE_INSTALL_EXIT=7 assert_exit 7 apply --cleanup
  assert_not_contains "bundle cleanup" "$(brew_calls)"
}

test_apply_fails_when_default_branch_is_unknown() {
  git init -q --bare -b master "$REMOTE"
  assert_exit 0 init_with_flags
  assert_exit 1 apply
  assert_contains "cannot determine the default branch" "$(last_output)"
  assert_missing "$HOME/installed.target"
}

test_apply_fails_while_offline() {
  given_initialised_host
  unplug_remote
  assert_exit 1 apply
  assert_contains "cannot reach" "$(last_output)"
}
