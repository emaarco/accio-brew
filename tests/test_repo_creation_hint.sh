given_gh_is_installed() {
  export PATH=$TOOL_ROOT/tests/fakes/optional:$PATH
}

init_after_unreachable_repository_on() {
  create_remote "$REMOTE"
  map_url_to "https://$2/acme/brewfiles.git" "$SANDBOX/missing.git"
  map_url_to "git@$2:acme/brewfiles.git" "$SANDBOX/missing.git"
  answer_with "$1" acme/brewfiles 3 "$REMOTE" ""
  assert_exit 0 init_with_answers
}

test_unreachable_github_repo_links_its_creation_page() {
  init_after_unreachable_repository_on 1 github.com
  assert_contains "https://github.com/new" "$(last_output)"
}

test_unreachable_gitlab_repo_links_its_creation_page() {
  init_after_unreachable_repository_on 2 gitlab.com
  assert_contains "https://gitlab.com/projects/new" "$(last_output)"
}

test_unreachable_repo_still_mentions_access() {
  init_after_unreachable_repository_on 1 github.com
  assert_contains "check your access" "$(last_output)"
}

test_unreachable_github_repo_offers_gh_command_when_gh_is_installed() {
  given_gh_is_installed
  init_after_unreachable_repository_on 1 github.com
  assert_contains "gh repo create acme/brewfiles --private" "$(last_output)"
}

test_unreachable_github_repo_omits_gh_command_without_gh() {
  init_after_unreachable_repository_on 1 github.com
  assert_not_contains "gh repo create" "$(last_output)"
}

test_unreachable_gitlab_repo_omits_gh_command() {
  given_gh_is_installed
  init_after_unreachable_repository_on 2 gitlab.com
  assert_not_contains "gh repo create" "$(last_output)"
}

test_unreachable_pasted_url_links_no_creation_page() {
  create_remote "$REMOTE"
  answer_with 3 "$SANDBOX/missing.git" 3 "$REMOTE" ""
  assert_exit 0 init_with_answers
  assert_not_contains "https://github.com/new" "$(last_output)"
}
