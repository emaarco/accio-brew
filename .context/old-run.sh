#!/bin/bash
set -u

TOOL_ROOT=$(cd "$(dirname "$0")/.." && pwd)
ACCIO_BREW=$TOOL_ROOT/bin/accio-brew
DEVELOPER_PATH=$PATH

fail_test() {
  printf 'assertion failed: %s\n' "$*"
  exit 1
}

assert_eq() {
  [ "$1" = "$2" ] || fail_test "expected '$1', got '$2'"
}

assert_contains() {
  case $2 in
    *"$1"*) ;;
    *) fail_test "expected '$1' in '$2'" ;;
  esac
}

assert_not_contains() {
  case $2 in
    *"$1"*) fail_test "did not expect '$1' in '$2'" ;;
  esac
}

assert_exit() {
  local expected=$1 actual
  shift
  "$@" > "$SANDBOX/last.out" 2>&1
  actual=$?
  [ "$actual" = "$expected" ] || fail_test "expected exit $expected, got $actual from: $* ($(cat "$SANDBOX/last.out"))"
}

last_output() {
  cat "$SANDBOX/last.out"
}

write_fake() {
  cat > "$FAKE_BIN/$1"
  chmod +x "$FAKE_BIN/$1"
}

install_fakes() {
  write_fake brew <<'FAKE'
#!/bin/bash
echo "$*" >> "$HOME/brew.calls"
for argument; do
  case $argument in
    --file=*) file=${argument#--file=} ;;
  esac
done
case "$1 $2" in
  "bundle dump")
    sleep "${FAKE_DUMP_SECONDS:-0}"
    cp "$FAKE_INSTALLED" "$file"
    ;;
  "bundle install")
    cp "$file" "$HOME/installed.target"
    exit "${FAKE_INSTALL_EXIT:-0}"
    ;;
esac
FAKE
  write_fake scutil <<'FAKE'
#!/bin/bash
echo "$FAKE_HOST"
FAKE
  write_fake launchctl <<'FAKE'
#!/bin/bash
echo "$*" >> "$HOME/launchctl.calls"
FAKE
  write_fake ssh <<'FAKE'
#!/bin/bash
exit 255
FAKE
}

enter_home() {
  export HOME=$SANDBOX/home-$1
  export FAKE_HOST=$1
  mkdir -p "$HOME/Library/Logs"
}

set_installed() {
  printf 'brew "%s"\n' "$@" > "$FAKE_INSTALLED"
}

setup_sandbox() {
  SANDBOX=$(mktemp -d)
  trap 'rm -rf "$SANDBOX"' EXIT
  FAKE_BIN=$SANDBOX/bin
  mkdir -p "$FAKE_BIN"
  export PATH=$FAKE_BIN:/usr/bin:/bin:/usr/sbin:/sbin
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_CONFIG_GLOBAL=$SANDBOX/gitconfig
  export FAKE_INSTALLED=$SANDBOX/installed
  unset ZDOTDIR HOMEBREW_PREFIX
  git config --global user.name tester
  git config --global user.email tester@example.com
  git config --global commit.gpgsign false
  install_fakes
  enter_home a
  set_installed git
  REMOTE=$SANDBOX/remote.git
}

create_empty_remote() {
  git init -q --bare -b main "$1"
}

create_remote() {
  local work
  work=$SANDBOX/work-$(basename "$1")
  create_empty_remote "$1"
  git init -q -b main "$work"
  echo 'brew "target"' > "$work/Brewfile"
  git -C "$work" add Brewfile
  git -C "$work" commit -q -m "chore: add target"
  git -C "$work" push -q "$1" main
}

init_with_flags() {
  "$ACCIO_BREW" init --repo-url "$REMOTE" --mode "${1:-wrapper}" </dev/null
}

sync() {
  "$ACCIO_BREW" sync
}

remote_file() {
  git -C "$REMOTE" show "$1:Brewfile"
}

remote_commit_count() {
  git -C "$REMOTE" rev-list --count "$1"
}

config_value() {
  (source "$HOME/.config/accio-brew/config" && eval "printf '%s' \"\$$1\"")
}

wrapper_block_count() {
  grep -c '^# >>> accio-brew >>>$' "$HOME/.zshrc"
}

test_sync_without_config_points_to_init() {
  assert_exit 1 sync
  assert_contains "run accio-brew init" "$(last_output)"
}

test_sync_with_incomplete_config_points_to_init() {
  mkdir -p "$HOME/.config/accio-brew"
  echo 'REPO_URL=' > "$HOME/.config/accio-brew/config"
  assert_exit 1 sync
  assert_contains "run accio-brew init" "$(last_output)"
}

test_init_rejects_unknown_mode() {
  assert_exit 1 "$ACCIO_BREW" init --mode cron
  assert_contains "mode must be wrapper or launchd" "$(last_output)"
}

test_init_with_flags_configures_and_syncs() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  assert_eq "$REMOTE" "$(config_value REPO_URL)"
  assert_eq "./Brewfile" "$(config_value BREWFILE_PATH)"
  assert_eq "wrapper" "$(config_value SYNC_MODE)"
  assert_eq "a" "$(config_value HOST_ID)"
  assert_eq 'brew "git"' "$(remote_file hosts/a)"
  assert_eq 'brew "target"' "$(remote_file main)"
  assert_eq 1 "$(wrapper_block_count)"
  [ -x "$HOME/.local/bin/accio-brew" ] || fail_test "binary link missing"
}

test_init_builds_url_from_host_and_repository() {
  create_remote "$REMOTE"
  git config --global "url.$REMOTE.insteadOf" "https://github.com/acme/brewfiles.git"
  printf '1\n/acme/brewfiles.git\n\n' > "$SANDBOX/answers"
  assert_exit 0 "$ACCIO_BREW" init < "$SANDBOX/answers"
  assert_eq "https://github.com/acme/brewfiles.git" "$(config_value REPO_URL)"
  assert_eq 'brew "git"' "$(remote_file hosts/a)"
  assert_exit 0 sync
  assert_contains "no-change" "$(last_output)"
}

test_init_falls_back_to_ssh_url() {
  create_remote "$REMOTE"
  git config --global "url.$REMOTE.insteadOf" "git@gitlab.com:acme/brewfiles.git"
  git config --global "url.$SANDBOX/missing.git.insteadOf" "https://gitlab.com/acme/brewfiles.git"
  printf '2\nacme/brewfiles\n2\n' > "$SANDBOX/answers"
  assert_exit 0 "$ACCIO_BREW" init < "$SANDBOX/answers"
  assert_eq "git@gitlab.com:acme/brewfiles.git" "$(config_value REPO_URL)"
  assert_eq "launchd" "$(config_value SYNC_MODE)"
}

test_init_accepts_pasted_clone_url() {
  create_remote "$REMOTE"
  printf '3\n%s\n1\n' "$REMOTE" > "$SANDBOX/answers"
  assert_exit 0 "$ACCIO_BREW" init < "$SANDBOX/answers"
  assert_eq "$REMOTE" "$(config_value REPO_URL)"
}

test_init_seeds_empty_remote_with_empty_target() {
  create_empty_remote "$REMOTE"
  assert_exit 0 init_with_flags
  assert_eq "" "$(remote_file main)"
  assert_eq 'brew "git"' "$(remote_file hosts/a)"
}

test_init_with_unreachable_repo_writes_no_config() {
  assert_exit 1 "$ACCIO_BREW" init --repo-url "$SANDBOX/missing.git" --mode wrapper
  assert_contains "cannot reach" "$(last_output)"
  [ ! -e "$HOME/.config/accio-brew/config" ] || fail_test "config was written"
}

test_init_reasks_until_repo_is_reachable() {
  create_remote "$REMOTE"
  printf '3\n%s\n3\n%s\n1\n' "$SANDBOX/missing.git" "$REMOTE" > "$SANDBOX/answers"
  assert_exit 0 "$ACCIO_BREW" init < "$SANDBOX/answers"
  assert_contains "Create the repo in your host's web UI" "$(last_output)"
  assert_eq "$REMOTE" "$(config_value REPO_URL)"
}

test_init_again_switches_trigger_module() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags wrapper
  assert_exit 0 "$ACCIO_BREW" init --mode launchd </dev/null
  assert_eq 0 "$(wrapper_block_count)"
  assert_exit 0 plutil -lint "$HOME/Library/LaunchAgents/io.accio-brew.plist"
  assert_not_contains "__" "$(cat "$HOME/Library/LaunchAgents/io.accio-brew.plist")"
  assert_contains "$TOOL_ROOT/bin/accio-brew" "$(cat "$HOME/Library/LaunchAgents/io.accio-brew.plist")"
  assert_contains "bootstrap gui/" "$(cat "$HOME/launchctl.calls")"
  assert_exit 0 "$ACCIO_BREW" init --mode wrapper </dev/null
  assert_eq 1 "$(wrapper_block_count)"
  [ ! -e "$HOME/Library/LaunchAgents/io.accio-brew.plist" ] || fail_test "plist still present"
  assert_exit 0 "$ACCIO_BREW" init --mode wrapper </dev/null
  assert_eq 1 "$(wrapper_block_count)"
}

test_init_keeps_existing_zshrc_content() {
  create_remote "$REMOTE"
  printf 'export EDITOR=vim\n' > "$HOME/.zshrc"
  cp "$HOME/.zshrc" "$SANDBOX/zshrc.before"
  assert_exit 0 init_with_flags wrapper
  assert_contains "export EDITOR=vim" "$(cat "$HOME/.zshrc")"
  assert_exit 0 "$ACCIO_BREW" teardown
  assert_exit 0 cmp "$SANDBOX/zshrc.before" "$HOME/.zshrc"
}

test_wrapper_block_starts_on_its_own_line() {
  create_remote "$REMOTE"
  printf 'export EDITOR=vim' > "$HOME/.zshrc"
  assert_exit 0 init_with_flags wrapper
  assert_eq "export EDITOR=vim" "$(head -1 "$HOME/.zshrc")"
  assert_eq 1 "$(wrapper_block_count)"
}

test_teardown_refuses_incomplete_wrapper_block() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags wrapper
  grep -v '^# <<< accio-brew <<<$' "$HOME/.zshrc" > "$SANDBOX/zshrc.damaged"
  echo 'export IMPORTANT=1' >> "$SANDBOX/zshrc.damaged"
  cp "$SANDBOX/zshrc.damaged" "$HOME/.zshrc"
  assert_exit 1 "$ACCIO_BREW" teardown
  assert_exit 0 cmp "$SANDBOX/zshrc.damaged" "$HOME/.zshrc"
}

test_init_requires_flag_values() {
  assert_exit 1 "$ACCIO_BREW" init --repo-url
  assert_contains "missing value for --repo-url" "$(last_output)"
}

test_init_reads_final_answer_without_newline() {
  create_remote "$REMOTE"
  printf '3\n%s' "$REMOTE" > "$SANDBOX/answers"
  assert_exit 0 "$ACCIO_BREW" init --mode wrapper < "$SANDBOX/answers"
  assert_eq "$REMOTE" "$(config_value REPO_URL)"
}

test_sync_ignores_untracked_files_in_clone() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  touch "$HOME/.local/share/accio-brew/repo/.DS_Store"
  assert_exit 0 sync
  assert_contains "no-change" "$(last_output)"
  assert_not_contains "nothing added" "$(last_output)"
}

test_sync_is_not_blocked_by_lingering_child_of_previous_sync() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  write_fake brew <<'FAKE'
#!/bin/bash
for argument; do
  case $argument in
    --file=*) cp "$FAKE_INSTALLED" "${argument#--file=}" ;;
  esac
done
sleep 5 >/dev/null 2>&1 &
FAKE
  assert_exit 0 sync
  SECONDS=0
  assert_exit 0 sync
  [ "$SECONDS" -lt 3 ] || fail_test "second sync waited ${SECONDS}s for the lock"
}

test_sync_reports_server_rejection_as_push_failure() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  printf '#!/bin/sh\nexit 1\n' > "$REMOTE/hooks/pre-receive"
  chmod +x "$REMOTE/hooks/pre-receive"
  set_installed git jq
  assert_exit 0 sync
  assert_contains "push-failed" "$(last_output)"
  assert_not_contains "diverged" "$(last_output)"
}

test_sync_keeps_configured_ssh_command() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  git config --global core.sshCommand "$SANDBOX/myssh"
  printf '#!/bin/sh\necho "$*" >> "%s/myssh.calls"\nexit 255\n' "$SANDBOX" > "$SANDBOX/myssh"
  chmod +x "$SANDBOX/myssh"
  git -C "$HOME/.local/share/accio-brew/repo" remote set-url origin git@example.com:acme/brewfiles.git
  sed -i '' "s|^REPO_URL=.*|REPO_URL=git@example.com:acme/brewfiles.git|" "$HOME/.config/accio-brew/config"
  set_installed git jq
  assert_exit 0 sync
  assert_contains "push-failed" "$(last_output)"
  assert_contains "BatchMode=yes" "$(cat "$SANDBOX/myssh.calls")"
}

test_apply_fails_when_default_branch_is_unknown() {
  git init -q --bare -b master "$REMOTE"
  assert_exit 0 init_with_flags
  assert_exit 1 "$ACCIO_BREW" apply
  assert_contains "cannot determine the default branch" "$(last_output)"
  [ ! -e "$HOME/installed.target" ] || fail_test "something was installed"
}

test_apply_returns_brew_failure_and_skips_cleanup() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  FAKE_INSTALL_EXIT=7 assert_exit 7 "$ACCIO_BREW" apply --cleanup
  assert_not_contains "bundle cleanup" "$(cat "$HOME/brew.calls")"
}

test_init_again_with_new_repo_replaces_clone() {
  local first_remote=$REMOTE
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  REMOTE=$SANDBOX/second.git
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  assert_eq "$REMOTE" "$(git -C "$HOME/.local/share/accio-brew/repo" config --get remote.origin.url)"
  assert_eq 'brew "git"' "$(remote_file hosts/a)"
  assert_eq 1 "$(git -C "$first_remote" rev-list --count hosts/a)"
}

test_sync_refuses_clone_of_another_repo() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  sed -i '' "s|^REPO_URL=.*|REPO_URL=$SANDBOX/other.git|" "$HOME/.config/accio-brew/config"
  assert_exit 1 sync
  assert_contains "run accio-brew init" "$(last_output)"
}

test_sync_without_change_makes_no_commit() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  assert_exit 0 sync
  assert_contains "no-change" "$(last_output)"
  assert_not_contains "pushed" "$(last_output)"
  assert_eq 1 "$(remote_commit_count hosts/a)"
}

test_sync_commits_and_pushes_changed_state() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  set_installed git jq
  assert_exit 0 sync
  assert_contains "pushed" "$(last_output)"
  assert_eq 2 "$(remote_commit_count hosts/a)"
  assert_contains 'brew "jq"' "$(remote_file hosts/a)"
  git -C "$REMOTE" log -1 --format=%s hosts/a | grep -Eq '^sync\(a\): [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$' || fail_test "unexpected commit subject"
  assert_eq "accio-brew" "$(git -C "$REMOTE" log -1 --format=%an hosts/a)"
}

test_host_branch_shares_no_history_with_target() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  assert_exit 1 git -C "$REMOTE" merge-base main hosts/a
}

test_two_hosts_push_to_separate_branches() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  enter_home b
  set_installed wget
  assert_exit 0 init_with_flags
  assert_eq 'brew "git"' "$(remote_file hosts/a)"
  assert_eq 'brew "wget"' "$(remote_file hosts/b)"
  assert_eq 'brew "target"' "$(remote_file main)"
}

test_offline_sync_commits_locally_and_heals_later() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  mv "$REMOTE" "$SANDBOX/unplugged.git"
  set_installed git jq
  assert_exit 0 sync
  assert_contains "committed" "$(last_output)"
  assert_contains "push-failed" "$(last_output)"
  mv "$SANDBOX/unplugged.git" "$REMOTE"
  assert_exit 0 sync
  assert_contains "no-change" "$(last_output)"
  assert_contains "pushed" "$(last_output)"
  assert_contains 'brew "jq"' "$(remote_file hosts/a)"
}

test_first_sync_while_offline_fails_and_recovers() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  rm -rf "$HOME/.local/share/accio-brew/repo"
  mv "$REMOTE" "$SANDBOX/unplugged.git"
  assert_exit 1 sync
  assert_contains "clone-failed" "$(last_output)"
  mv "$SANDBOX/unplugged.git" "$REMOTE"
  assert_exit 0 sync
}

test_duplicate_host_id_is_reported_as_diverged() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  enter_home twin
  export FAKE_HOST=a
  assert_exit 0 init_with_flags
  assert_contains "hosts/a exists" "$(last_output)"
  set_installed wget
  assert_exit 0 sync
  enter_home a
  set_installed jq
  assert_exit 1 sync
  assert_contains "diverged" "$(last_output)"
}

test_init_lets_second_mac_pick_another_name() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  enter_home twin
  export FAKE_HOST=a
  printf 'Office Mac\n' > "$SANDBOX/answers"
  assert_exit 0 "$ACCIO_BREW" init --repo-url "$REMOTE" --mode wrapper < "$SANDBOX/answers"
  assert_eq "office-mac" "$(config_value HOST_ID)"
  assert_eq 'brew "git"' "$(remote_file hosts/office-mac)"
}

test_concurrent_syncs_run_one_after_another() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  set_installed git jq
  FAKE_DUMP_SECONDS=1 sync >> "$SANDBOX/events" 2>&1 &
  FAKE_DUMP_SECONDS=1 sync >> "$SANDBOX/events" 2>&1 &
  wait
  assert_eq "start committed pushed done start no-change done" "$(awk '{print $3}' "$SANDBOX/events" | tr '\n' ' ' | sed 's/ $//')"
  assert_eq 2 "$(remote_commit_count hosts/a)"
}

test_apply_installs_target_brewfile() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  assert_exit 0 "$ACCIO_BREW" apply
  assert_eq 'brew "target"' "$(cat "$HOME/installed.target")"
  assert_contains "bundle install --file=" "$(cat "$HOME/brew.calls")"
  assert_not_contains "bundle cleanup" "$(cat "$HOME/brew.calls")"
}

test_apply_with_cleanup_removes_only_dumped_types() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  assert_exit 0 "$ACCIO_BREW" apply --cleanup
  assert_contains "bundle cleanup --force --tap --formula --cask --file=" "$(cat "$HOME/brew.calls")"
}

test_apply_sees_target_changes_made_after_init() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  echo 'brew "newer-target"' > "$SANDBOX/work-remote.git/Brewfile"
  git -C "$SANDBOX/work-remote.git" commit -q -am "feat: change target"
  git -C "$SANDBOX/work-remote.git" push -q "$REMOTE" main
  assert_exit 0 "$ACCIO_BREW" apply
  assert_eq 'brew "newer-target"' "$(cat "$HOME/installed.target")"
}

test_apply_rejects_unknown_option() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
  assert_exit 1 "$ACCIO_BREW" apply --clean
}

test_teardown_removes_triggers_and_link() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags launchd
  assert_exit 0 "$ACCIO_BREW" teardown
  [ ! -e "$HOME/Library/LaunchAgents/io.accio-brew.plist" ] || fail_test "plist still present"
  [ ! -e "$HOME/.local/bin/accio-brew" ] || fail_test "binary link still present"
  assert_contains "bootout gui/" "$(cat "$HOME/launchctl.calls")"
  [ -e "$HOME/.config/accio-brew/config" ] || fail_test "config was removed"
}

install_wrapper_fakes() {
  mkdir -p "$SANDBOX/prefix/bin" "$HOME/.local/bin"
  cat > "$SANDBOX/prefix/bin/brew" <<'FAKE'
#!/bin/bash
printf '%s\n' "$@" > "$HOME/brew.arguments"
exit "${FAKE_BREW_EXIT:-0}"
FAKE
  cat > "$HOME/.local/bin/accio-brew" <<'FAKE'
#!/bin/bash
echo "$*" >> "$HOME/sync.calls"
FAKE
  chmod +x "$SANDBOX/prefix/bin/brew" "$HOME/.local/bin/accio-brew"
}

wrapped_brew() {
  HOMEBREW_PREFIX=$SANDBOX/prefix zsh -c 'source "$1"; shift; brew "$@"' wrapper "$TOOL_ROOT/modules/wrapper.zsh" "$@"
}

sync_was_triggered() {
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -e "$HOME/sync.calls" ] && return 0
    sleep 0.2
  done
  return 1
}

test_wrapper_passes_arguments_and_exit_code_through() {
  install_wrapper_fakes
  FAKE_BREW_EXIT=3 assert_exit 3 wrapped_brew list --formula "two words"
  assert_eq "list|--formula|two words|" "$(tr '\n' '|' < "$HOME/brew.arguments")"
  sleep 0.5
  [ ! -e "$HOME/sync.calls" ] || fail_test "sync was triggered by list"
}

test_wrapper_triggers_sync_after_state_changes() {
  local subcommand
  install_wrapper_fakes
  for subcommand in install uninstall upgrade; do
    rm -f "$HOME/sync.calls"
    assert_exit 0 wrapped_brew "$subcommand" jq
    sync_was_triggered || fail_test "no sync after $subcommand"
    assert_eq "sync" "$(cat "$HOME/sync.calls")"
  done
}

test_wrapper_triggers_sync_after_failed_install_with_leading_flag() {
  install_wrapper_fakes
  FAKE_BREW_EXIT=1 assert_exit 1 wrapped_brew --verbose install jq missing
  sync_was_triggered || fail_test "no sync after failed install"
}

test_scripts_pass_static_checks() {
  export PATH=$DEVELOPER_PATH
  assert_exit 0 zsh -n "$TOOL_ROOT/modules/wrapper.zsh"
  assert_exit 0 plutil -lint "$TOOL_ROOT/modules/launchd.plist"
  if ! command -v shellcheck >/dev/null; then
    echo "shellcheck not installed, skipped"
    return
  fi
  assert_exit 0 shellcheck --exclude=SC1090,SC1091,SC2329 "$ACCIO_BREW" "$TOOL_ROOT/tests/run.sh"
}

run_test() {
  local name=$1 output
  output=$(mktemp)
  if (setup_sandbox && "$name") > "$output" 2>&1; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    sed 's/^/     /' "$output"
    failures=$((failures + 1))
  fi
  rm -f "$output"
}

failures=0
for test_name in $(declare -F | awk '{print $3}' | grep '^test_'); do
  case $test_name in
    *"${1:-}"*) run_test "$test_name" ;;
  esac
done
[ "$failures" -eq 0 ] || echo "$failures test(s) failed"
exit "$failures"
