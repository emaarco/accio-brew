test_sync_records_packages_in_host_file() {
  given_initialised_host
  assert_eq 'brew "git"' "$(remote_host_file a)"
}

test_sync_builds_on_target_branch() {
  given_initialised_host
  assert_eq "$(remote_commit main)" "$(remote_commit sync/a^)"
}

test_sync_leaves_target_branch_untouched() {
  given_initialised_host
  assert_eq 1 "$(remote_commit_count main)"
}

test_sync_after_merge_changes_nothing() {
  given_initialised_host
  merge_sync_request a
  assert_exit 0 sync
  assert_contains "no-change" "$(last_output)"
  assert_not_contains "pushed" "$(last_output)"
}

test_sync_of_unmerged_state_does_not_push_again() {
  given_initialised_host
  assert_exit 0 sync
  assert_contains "unmerged" "$(last_output)"
  assert_not_contains "pushed" "$(last_output)"
}

test_sync_pushes_changed_state() {
  given_initialised_host
  set_installed git jq
  assert_exit 0 sync
  assert_contains "pushed" "$(last_output)"
  assert_contains 'brew "jq"' "$(remote_host_file a)"
}

test_sync_replaces_unmerged_state() {
  given_initialised_host
  set_installed git jq
  assert_exit 0 sync
  assert_eq 2 "$(remote_commit_count sync/a)"
}

test_sync_follows_moved_target_branch() {
  given_initialised_host
  publish_target "$REMOTE" newer-target
  assert_exit 0 sync
  assert_eq "$(remote_commit main)" "$(remote_commit sync/a^)"
}

test_sync_pushes_again_after_merged_branch_was_deleted() {
  given_initialised_host
  merge_sync_request a
  git -C "$REMOTE" branch -q -D sync/a
  set_installed git jq
  assert_exit 0 sync
  assert_contains 'brew "jq"' "$(remote_host_file a)"
}

test_sync_asks_for_merge_request_on_other_hosts() {
  given_initialised_host
  assert_exit 0 sync
  assert_contains "Open a merge request from sync/a into main" "$(last_output)"
}

test_sync_commit_names_host() {
  given_initialised_host
  assert_eq "chore: record packages of a" "$(last_remote_commit %s)"
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

test_host_file_ignores_configured_target_path() {
  given_initialised_host
  echo 'BREWFILE_PATH=./macs/Brewfile' >> "$CONFIG"
  set_installed git jq
  assert_exit 0 sync
  assert_contains 'brew "jq"' "$(remote_host_file a)"
}

test_sync_ignores_untracked_files_in_clone() {
  given_initialised_host
  merge_sync_request a
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
