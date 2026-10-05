test_offline_sync_commits_locally() {
  given_initialised_host
  unplug_remote
  set_installed git jq
  assert_exit 0 sync
  assert_contains "committed" "$(last_output)"
  assert_contains "push-failed" "$(last_output)"
}

test_sync_pushes_offline_commit_once_remote_is_back() {
  given_initialised_host
  unplug_remote
  set_installed git jq
  assert_exit 0 sync
  replug_remote
  assert_exit 0 sync
  assert_contains "pushed" "$(last_output)"
  assert_contains 'brew "jq"' "$(remote_file hosts/a)"
}

test_first_sync_while_offline_fails() {
  given_initialised_host
  rm -rf "$CLONE"
  unplug_remote
  assert_exit 1 sync
  assert_contains "clone-failed" "$(last_output)"
}

test_sync_recovers_after_failed_clone() {
  given_initialised_host
  rm -rf "$CLONE"
  unplug_remote
  assert_exit 1 sync
  replug_remote
  assert_exit 0 sync
}

test_server_rejection_is_reported_as_push_failure() {
  given_initialised_host
  printf '#!/bin/sh\nexit 1\n' > "$REMOTE/hooks/pre-receive"
  chmod +x "$REMOTE/hooks/pre-receive"
  set_installed git jq
  assert_exit 0 sync
  assert_contains "push-failed" "$(last_output)"
  assert_not_contains "diverged" "$(last_output)"
}

test_sync_keeps_configured_ssh_command() {
  given_initialised_host
  git config --global core.sshCommand "$TOOL_ROOT/tests/fakes/recording-ssh"
  git -C "$CLONE" remote set-url origin git@example.com:acme/brewfiles.git
  point_config_to git@example.com:acme/brewfiles.git
  set_installed git jq
  assert_exit 0 sync
  assert_contains "BatchMode=yes" "$(cat "$HOME/ssh.calls")"
}
