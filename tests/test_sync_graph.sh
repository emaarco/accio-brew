test_sync_records_dependency_graph() {
  given_initialised_host
  assert_contains 'n_git["git"]' "$(remote_graph_file a)"
}

test_sync_requests_change_of_dependencies_alone() {
  given_initialised_host
  merge_sync_request a
  set_dependencies "git: pcre2" "pcre2:"
  assert_exit 0 sync
  assert_contains "pushed" "$(last_output)"
  assert_contains 'n_git --> n_pcre2' "$(remote_graph_file a)"
}

test_sync_records_packages_when_graph_fails() {
  given_initialised_host
  rm "$FAKE_DEPENDENCIES"
  set_installed git jq
  assert_exit 0 sync
  assert_contains "graph-failed" "$(last_output)"
  assert_contains 'brew "jq"' "$(remote_host_file a)"
}

test_sync_keeps_last_graph_when_graph_fails() {
  given_initialised_host
  merge_sync_request a
  rm "$FAKE_DEPENDENCIES"
  assert_exit 0 sync
  assert_contains "no-change" "$(last_output)"
}
