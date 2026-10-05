test_wizard_builds_https_url_for_github() {
  given_platform_clis_are_installed
  create_remote "$REMOTE"
  map_url_to "https://github.com/acme/brewfiles.git" "$REMOTE"
  answer_with 1 acme/brewfiles
  assert_exit 0 init_with_answers
  assert_eq "https://github.com/acme/brewfiles.git" "$(config_value REPO_URL)"
}

test_wizard_strips_slashes_and_git_suffix_from_repository() {
  given_platform_clis_are_installed
  create_remote "$REMOTE"
  map_url_to "https://github.com/acme/brewfiles.git" "$REMOTE"
  answer_with 1 /acme/brewfiles.git
  assert_exit 0 init_with_answers
  assert_eq "https://github.com/acme/brewfiles.git" "$(config_value REPO_URL)"
}

test_wizard_falls_back_to_ssh_url() {
  given_platform_clis_are_installed
  create_remote "$REMOTE"
  map_url_to "git@gitlab.com:acme/brewfiles.git" "$REMOTE"
  map_url_to "https://gitlab.com/acme/brewfiles.git" "$SANDBOX/missing.git"
  answer_with 2 acme/brewfiles
  assert_exit 0 init_with_answers
  assert_eq "git@gitlab.com:acme/brewfiles.git" "$(config_value REPO_URL)"
}

test_wizard_accepts_pasted_clone_url() {
  create_remote "$REMOTE"
  answer_with 3 "$REMOTE"
  assert_exit 0 init_with_answers
  assert_eq "$REMOTE" "$(config_value REPO_URL)"
}

test_wizard_reasks_until_repo_is_reachable() {
  create_remote "$REMOTE"
  answer_with 3 "$SANDBOX/missing.git" 3 "$REMOTE"
  assert_exit 0 init_with_answers
  assert_contains "Create the repo in your host's web UI" "$(last_output)"
  assert_eq "$REMOTE" "$(config_value REPO_URL)"
}

test_wizard_reads_final_answer_without_newline() {
  create_remote "$REMOTE"
  printf '3\n%s' "$REMOTE" > "$SANDBOX/answers"
  assert_exit 0 init_with_answers
  assert_eq "$REMOTE" "$(config_value REPO_URL)"
}

test_wizard_keeps_current_repo_on_enter() {
  given_initialised_host
  answer_with ""
  assert_exit 0 init_with_answers
  assert_eq "$REMOTE" "$(config_value REPO_URL)"
}

test_wizard_fails_without_answer_for_repository() {
  answer_with 1
  assert_exit 1 init_with_answers
  assert_contains "missing answer for: Repository" "$(last_output)"
}
