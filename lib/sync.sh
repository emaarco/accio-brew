wait_for_other_syncs() {
  local lock_file=$DATA_DIR/lock
  mkdir -p "$DATA_DIR"
  exec 9>"$lock_file"
  /usr/bin/lockf 9 || fail "cannot lock $lock_file"
}

remote_host_branch_is_known() {
  git_in_clone rev-parse -q --verify "refs/remotes/origin/$HOST_BRANCH" >/dev/null
}

checkout_host_branch() {
  [ "$(git_in_clone symbolic-ref --short -q HEAD)" = "$HOST_BRANCH" ] && return
  if remote_host_branch_is_known; then
    git_in_clone checkout -q -f -B "$HOST_BRANCH" "origin/$HOST_BRANCH"
  else
    git_in_clone switch -q --orphan "$HOST_BRANCH"
  fi
}

update_host_brewfile() {
  local dump
  dump=$(mktemp)
  if dump_installed_packages "$dump"; then
    mkdir -p "$(dirname "$CLONE/$BREWFILE")"
    mv "$dump" "$CLONE/$BREWFILE"
  else
    rm -f "$dump"
    return 1
  fi
}

commit_if_changed() {
  git_in_clone add -- "$BREWFILE"
  if git_in_clone diff --cached --quiet; then
    log no-change
    return
  fi
  git_as_tool -C "$CLONE" commit -q -m "sync($HOST_ID): $(utc_now)" && log committed
}

host_branch_is_pushed() {
  local local_head
  local_head=$(git_in_clone rev-parse -q --verify HEAD) || return 0
  [ "$local_head" = "$(git_in_clone rev-parse -q --verify "refs/remotes/origin/$HOST_BRANCH")" ]
}

push_host_branch() {
  local push_output
  host_branch_is_pushed && return
  if push_output=$(LC_ALL=C git_in_clone push -q -u origin "$HOST_BRANCH" 2>&1); then
    log pushed
    return
  fi
  case $push_output in
    *'! [rejected]'*)
      log diverged
      exit 1
      ;;
  esac
  log push-failed
}

stop_sync_because() {
  log "$1"
  exit 1
}

command_sync() {
  local started_at=$SECONDS
  load_config
  use_unattended_git
  wait_for_other_syncs
  log start
  ensure_clone || stop_sync_because clone-failed
  checkout_host_branch
  update_host_brewfile || stop_sync_because dump-failed
  commit_if_changed
  push_host_branch
  log "done $((SECONDS - started_at))s"
}
