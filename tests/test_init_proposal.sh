test_init_proposes_first_dump_for_new_repo() {
  create_empty_remote "$REMOTE"
  assert_exit 0 init_with_flags
  assert_eq 'brew "git"' "$(remote_file propose/a)"
}

test_init_proposes_first_dump_for_empty_target() {
  create_empty_remote "$REMOTE"
  publish_file "$REMOTE" Brewfile
  assert_exit 0 init_with_flags
  assert_eq 'brew "git"' "$(remote_file propose/a)"
}

test_init_proposes_first_dump_for_missing_target() {
  create_empty_remote "$REMOTE"
  publish_file "$REMOTE" README.md
  assert_exit 0 init_with_flags
  assert_eq 'brew "git"' "$(remote_file propose/a)"
}

test_init_keeps_empty_target_empty() {
  create_empty_remote "$REMOTE"
  assert_exit 0 init_with_flags
  assert_eq "" "$(remote_file main)"
}

test_init_proposes_nothing_for_filled_target() {
  given_initialised_host
  remote_has_branch propose/a && fail_test "unexpected propose/a"
  return 0
}

test_init_again_with_unmerged_proposal_succeeds() {
  create_empty_remote "$REMOTE"
  assert_exit 0 init_with_flags
  assert_exit 0 init_with_flags
  assert_eq 'brew "git"' "$(remote_file propose/a)"
}

test_init_opens_pull_request_for_empty_target_on_github() {
  create_empty_remote "$REMOTE"
  map_url_to "https://github.com/acme/brewfiles.git" "$REMOTE"
  given_platform_clis_are_installed
  assert_exit 0 "$ACCIO_BREW" init --repo-url https://github.com/acme/brewfiles.git </dev/null
  assert_contains "pr create --base main --head propose/a" "$(gh_calls)"
}
