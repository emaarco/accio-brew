test_sync_without_change_makes_no_commit() {
  given_initialised_host
  assert_exit 0 sync
  assert_contains "no-change" "$(last_output)"
  assert_eq 1 "$(remote_commit_count hosts/a)"
}

test_sync_without_change_does_not_push() {
  given_initialised_host
  assert_exit 0 sync
  assert_not_contains "pushed" "$(last_output)"
}

test_sync_pushes_changed_state() {
  given_initialised_host
  set_installed git jq
  assert_exit 0 sync
  assert_contains "pushed" "$(last_output)"
  assert_contains 'brew "jq"' "$(remote_file hosts/a)"
}

test_sync_commit_names_host_and_time() {
  given_initialised_host
  set_installed git jq
  assert_exit 0 sync
  last_remote_commit %s | grep -Eq '^sync\(a\): [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$' || fail_test "unexpected subject: $(last_remote_commit %s)"
}

test_sync_commits_as_tool_identity() {
  given_initialised_host
  assert_eq "accio-brew <accio-brew@a>" "$(last_remote_commit '%an <%ae>')"
}

test_sync_requests_only_taps_formulae_and_casks() {
  given_initialised_host
  assert_contains "bundle dump --force --no-describe --no-restart --tap --formula --cask --file=" "$(brew_calls)"
}

test_sync_fails_when_nothing_is_installed() {
  given_initialised_host
  : > "$FAKE_INSTALLED"
  assert_exit 1 sync
  assert_contains "dump-failed" "$(last_output)"
}

test_sync_writes_brewfile_into_configured_subdirectory() {
  given_initialised_host
  echo 'BREWFILE_PATH=./macs/Brewfile' >> "$CONFIG"
  assert_exit 0 sync
  assert_eq 'brew "git"' "$(git -C "$REMOTE" show hosts/a:macs/Brewfile)"
}

test_sync_ignores_untracked_files_in_clone() {
  given_initialised_host
  touch "$CLONE/.DS_Store"
  assert_exit 0 sync
  assert_contains "no-change" "$(last_output)"
  assert_not_contains "nothing added" "$(last_output)"
}

test_sync_refuses_clone_of_another_repo() {
  given_initialised_host
  point_config_to "$SANDBOX/other.git"
  assert_exit 1 sync
  assert_contains "run accio-brew init" "$(last_output)"
}

test_host_branch_shares_no_history_with_target() {
  given_initialised_host
  assert_exit 1 git -C "$REMOTE" merge-base main hosts/a
}
