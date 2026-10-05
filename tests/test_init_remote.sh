test_init_seeds_empty_remote_with_empty_target() {
  create_empty_remote "$REMOTE"
  assert_exit 0 init_with_flags
  assert_eq "" "$(remote_file main)"
}

test_init_pushes_first_dump_to_seeded_remote() {
  create_empty_remote "$REMOTE"
  assert_exit 0 init_with_flags
  assert_eq 'brew "git"' "$(remote_file hosts/a)"
}

test_init_reuses_existing_host_branch_on_enter() {
  given_initialised_host
  enter_home twin
  export FAKE_HOST=a
  assert_exit 0 init_with_flags
  assert_contains "hosts/a exists" "$(last_output)"
  assert_eq "a" "$(config_value HOST_ID)"
}

test_init_lets_second_mac_pick_another_name() {
  given_initialised_host
  enter_home twin
  export FAKE_HOST=a
  answer_with "Office Mac"
  assert_exit 0 init_with_answers --repo-url "$REMOTE"
  assert_eq "office-mac" "$(config_value HOST_ID)"
}

test_init_again_with_new_repo_replaces_clone() {
  given_initialised_host
  REMOTE=$SANDBOX/second.git
  given_initialised_host
  assert_eq "$REMOTE" "$(git -C "$CLONE" config --get remote.origin.url)"
}

test_init_again_with_new_repo_pushes_there() {
  given_initialised_host
  REMOTE=$SANDBOX/second.git
  given_initialised_host
  assert_eq 'brew "git"' "$(remote_file hosts/a)"
}

test_init_again_with_new_repo_leaves_old_repo_alone() {
  local first_remote=$REMOTE
  given_initialised_host
  REMOTE=$SANDBOX/second.git
  given_initialised_host
  assert_eq 1 "$(git -C "$first_remote" rev-list --count hosts/a)"
}
