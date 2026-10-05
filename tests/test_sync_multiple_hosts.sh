given_twin_with_same_host_id() {
  enter_home twin
  export FAKE_HOST=a
  assert_exit 0 init_with_flags
}

test_two_hosts_push_to_separate_branches() {
  given_initialised_host
  enter_home b
  set_installed wget
  assert_exit 0 init_with_flags
  assert_eq 'brew "git"|brew "wget"' "$(remote_file hosts/a)|$(remote_file hosts/b)"
}

test_second_host_leaves_target_untouched() {
  given_initialised_host
  enter_home b
  assert_exit 0 init_with_flags
  assert_eq 'brew "target"' "$(remote_file main)"
}

test_duplicate_host_id_is_reported_as_diverged() {
  given_initialised_host
  given_twin_with_same_host_id
  set_installed wget
  assert_exit 0 sync
  enter_home a
  set_installed jq
  assert_exit 1 sync
  assert_contains "diverged" "$(last_output)"
}

test_concurrent_syncs_run_one_after_another() {
  given_initialised_host
  set_installed git jq
  FAKE_DUMP_SECONDS=1 sync >> "$SANDBOX/events" 2>&1 &
  FAKE_DUMP_SECONDS=1 sync >> "$SANDBOX/events" 2>&1 &
  wait
  assert_eq "start committed pushed done start no-change done" "$(awk '{print $3}' "$SANDBOX/events" | tr '\n' ' ' | sed 's/ $//')"
}

test_sync_is_not_blocked_by_lingering_child_of_previous_sync() {
  given_initialised_host
  FAKE_LINGERING_SECONDS=5 assert_exit 0 sync
  SECONDS=0
  assert_exit 0 sync
  [ "$SECONDS" -lt 3 ] || fail_test "second sync waited ${SECONDS}s for the lock"
}
