default_branch() {
  git_in_clone remote set-head origin -a >/dev/null 2>&1
  git_in_clone symbolic-ref --short -q refs/remotes/origin/HEAD
}

fetch_target_brewfile() {
  local target_branch
  ensure_clone || fail "cannot reach $REPO_URL"
  git_in_clone fetch -q origin || fail "cannot reach $REPO_URL"
  target_branch=$(default_branch) || fail "cannot determine the default branch of $REPO_URL"
  git_in_clone show "$target_branch:$BREWFILE" > "$1" 2>/dev/null || fail "target Brewfile not found on remote"
}

install_target() {
  local target=$1 cleanup=$2
  install_brewfile "$target" || return
  [ "$cleanup" = --cleanup ] || return 0
  uninstall_everything_missing_in "$target"
}

command_apply() {
  local cleanup=${1:-} target install_status
  case $cleanup in
    ''|--cleanup) ;;
    *) fail "unknown option: $cleanup" ;;
  esac
  load_config
  target=$(mktemp)
  fetch_target_brewfile "$target"
  install_target "$target" "$cleanup"
  install_status=$?
  rm -f "$target"
  command_sync
  return $install_status
}
