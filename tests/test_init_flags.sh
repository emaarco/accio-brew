test_init_rejects_unknown_mode() {
  assert_exit 1 "$ACCIO_BREW" init --mode cron
  assert_contains "mode must be wrapper or launchd" "$(last_output)"
}

test_init_rejects_unknown_option() {
  assert_exit 1 "$ACCIO_BREW" init --host github.com
  assert_contains "unknown option: --host" "$(last_output)"
}

test_init_requires_flag_values() {
  assert_exit 1 "$ACCIO_BREW" init --repo-url
  assert_contains "missing value for --repo-url" "$(last_output)"
}

test_init_with_unreachable_repo_fails() {
  assert_exit 1 "$ACCIO_BREW" init --repo-url "$SANDBOX/missing.git" --mode wrapper
  assert_contains "cannot reach" "$(last_output)"
}

test_init_with_unreachable_repo_writes_no_config() {
  assert_exit 1 "$ACCIO_BREW" init --repo-url "$SANDBOX/missing.git" --mode wrapper
  assert_missing "$CONFIG"
}

test_init_links_binary() {
  given_initialised_host
  [ -x "$HOME/.local/bin/accio-brew" ] || fail_test "binary link missing"
}

test_init_pushes_first_dump() {
  given_initialised_host
  assert_eq 'brew "git"' "$(remote_file hosts/a)"
}

test_init_leaves_target_untouched() {
  given_initialised_host
  assert_eq 'brew "target"' "$(remote_file main)"
}
