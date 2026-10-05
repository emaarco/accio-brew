test_sync_without_config_points_to_init() {
  assert_exit 1 sync
  assert_contains "run accio-brew init" "$(last_output)"
}

test_sync_with_incomplete_config_points_to_init() {
  mkdir -p "$(dirname "$CONFIG")"
  echo 'REPO_URL=' > "$CONFIG"
  assert_exit 1 sync
  assert_contains "run accio-brew init" "$(last_output)"
}

test_init_writes_repo_url() {
  given_initialised_host
  assert_eq "$REMOTE" "$(config_value REPO_URL)"
}

test_init_writes_default_brewfile_path() {
  given_initialised_host
  assert_eq "./Brewfile" "$(config_value BREWFILE_PATH)"
}

test_init_derives_host_id_from_local_host_name() {
  export FAKE_HOST="Marcos MacBook"
  given_initialised_host
  assert_eq "marcos-macbook" "$(config_value HOST_ID)"
}
