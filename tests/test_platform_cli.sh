init_on() {
  "$ACCIO_BREW" init --repo-url "https://$1/acme/brewfiles.git" </dev/null
}

given_reachable_repo_on() {
  create_remote "$REMOTE"
  map_url_to "https://$1/acme/brewfiles.git" "$REMOTE"
}

test_init_on_github_fails_without_gh() {
  given_reachable_repo_on github.com
  assert_exit 1 init_on github.com
  assert_contains "github.com repos need gh" "$(last_output)"
}

test_init_on_gitlab_fails_without_glab() {
  given_reachable_repo_on gitlab.com
  assert_exit 1 init_on gitlab.com
  assert_contains "gitlab.com repos need glab" "$(last_output)"
}

test_init_fails_when_cli_is_logged_out() {
  given_reachable_repo_on github.com
  given_platform_clis_are_installed
  FAKE_CLI_AUTH_EXIT=1 assert_exit 1 init_on github.com
  assert_contains "gh is not logged in" "$(last_output)"
}

test_init_without_cli_writes_no_config() {
  given_reachable_repo_on github.com
  assert_exit 1 init_on github.com
  assert_missing "$CONFIG"
}

test_init_on_other_hosts_needs_no_cli() {
  given_initialised_host
  assert_missing "$HOME/gh.calls"
}

test_propose_opens_pull_request_on_github() {
  given_initialised_host_on github.com
  assert_exit 0 propose
  assert_contains "pr create --base main --head propose/a --title feat: add packages from a" "$(gh_calls)"
  assert_contains "https://github.com/acme/brewfiles/pull/1" "$(last_output)"
}

test_propose_opens_merge_request_on_gitlab() {
  given_initialised_host_on gitlab.com
  assert_exit 0 propose
  assert_contains "mr create --source-branch propose/a --target-branch main --title feat: add packages from a" "$(glab_calls)"
}

test_propose_lists_packages_in_request_body() {
  given_initialised_host_on github.com
  assert_exit 0 propose
  assert_contains '--body brew "git"' "$(gh_calls)"
}

test_propose_again_keeps_single_pull_request() {
  given_initialised_host_on github.com
  assert_exit 0 propose
  set_installed git jq
  assert_exit 0 propose
  assert_eq 1 "$(gh_calls | grep -c "pr create .*--head propose/a")"
  assert_contains "Updated the open pull request" "$(last_output)"
}

test_propose_again_keeps_single_merge_request() {
  given_initialised_host_on gitlab.com
  assert_exit 0 propose
  assert_exit 0 propose
  assert_eq 1 "$(glab_calls | grep -c "mr create --source-branch propose/a")"
}

test_sync_opens_pull_request_on_github() {
  given_initialised_host_on github.com
  assert_contains "pr create --base main --head sync/a --title chore: record packages of a" "$(gh_calls)"
}

test_sync_opens_merge_request_on_gitlab() {
  given_initialised_host_on gitlab.com
  assert_contains "mr create --source-branch sync/a --target-branch main --title chore: record packages of a" "$(glab_calls)"
}

test_sync_again_keeps_single_pull_request() {
  given_initialised_host_on github.com
  set_installed git jq
  assert_exit 0 sync
  assert_eq 1 "$(gh_calls | grep -c "pr create .*--head sync/a")"
}

test_sync_reports_failed_pull_request() {
  given_reachable_repo_on github.com
  given_platform_clis_are_installed
  FAKE_PR_CREATE_EXIT=1 assert_exit 1 init_on github.com
  assert_contains "request-failed" "$(last_output)"
}
