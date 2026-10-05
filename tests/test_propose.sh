test_propose_appends_packages_missing_in_target() {
  given_initialised_host
  assert_exit 0 propose
  assert_eq 'brew "target"
brew "git"' "$(remote_file propose/a)"
}

test_propose_does_not_repeat_packages_of_target() {
  given_initialised_host
  set_installed target git
  assert_exit 0 propose
  assert_eq 'brew "target"
brew "git"' "$(remote_file propose/a)"
}

test_propose_builds_on_target_branch() {
  given_initialised_host
  assert_exit 0 propose
  assert_eq "$(remote_commit main)" "$(remote_commit propose/a^)"
}

test_propose_leaves_target_untouched() {
  given_initialised_host
  assert_exit 0 propose
  assert_eq 'brew "target"' "$(remote_file main)"
}

test_propose_uses_fresh_dump() {
  given_initialised_host
  set_installed git jq
  assert_exit 0 propose
  assert_contains 'brew "jq"' "$(remote_file propose/a)"
}

test_propose_without_missing_packages_pushes_nothing() {
  given_initialised_host
  publish_target "$REMOTE" git
  assert_exit 0 propose
  assert_contains "Nothing to propose." "$(last_output)"
  remote_has_branch propose/a && fail_test "unexpected propose/a"
  return 0
}

test_propose_again_replaces_unmerged_proposal() {
  given_initialised_host
  assert_exit 0 propose
  set_installed git jq
  assert_exit 0 propose
  assert_contains 'brew "jq"' "$(remote_file propose/a)"
  assert_eq 2 "$(remote_commit_count propose/a)"
}

test_propose_asks_for_merge_request_on_other_hosts() {
  given_initialised_host
  assert_exit 0 propose
  assert_contains "Open a merge request into main" "$(last_output)"
}

test_propose_fails_when_default_branch_is_unknown() {
  git init -q --bare -b master "$REMOTE"
  assert_exit 0 init_with_flags
  assert_exit 1 propose
  assert_contains "cannot determine the default branch" "$(last_output)"
}

test_propose_requires_init() {
  assert_exit 1 propose
  assert_contains "no config found" "$(last_output)"
}
