wait_for_other_syncs() {
  local lock_file=$DATA_DIR/lock
  mkdir -p "$DATA_DIR"
  exec 9>"$lock_file"
  /usr/bin/lockf 9 || fail "cannot lock $lock_file"
}

fetch_remote_state() {
  git_in_clone fetch -q --prune origin 2>/dev/null
}

resolve_target_branch() {
  local remote_target_branch
  remote_target_branch=$(default_branch) || fail "cannot determine the default branch of $REPO_URL"
  target_branch=${remote_target_branch#origin/}
}

checkout_sync_branch() {
  git_in_clone checkout -q -f -B "$SYNC_BRANCH" "origin/$target_branch"
}

update_host_brewfile() {
  local dump
  dump=$(mktemp)
  if dump_installed_packages "$dump"; then
    mkdir -p "$(dirname "$CLONE/$HOST_FILE")"
    mv "$dump" "$CLONE/$HOST_FILE"
  else
    rm -f "$dump"
    return 1
  fi
}

host_file_is_unchanged() {
  git_in_clone add -- "$HOST_FILE"
  git_in_clone diff --cached --quiet
}

tree_of() {
  git_in_clone rev-parse -q --verify "$1^{tree}"
}

sync_branch_is_pushed() {
  [ "$(tree_of HEAD)" = "$(tree_of "refs/remotes/origin/$SYNC_BRANCH")" ]
}

push_sync_branch() {
  if sync_branch_is_pushed; then
    log unmerged
    return
  fi
  git_in_clone push -q --force origin "$SYNC_BRANCH" 2>/dev/null || stop_sync_because push-failed
  log pushed
}

request_host_file_change() {
  local title="chore: record packages of $HOST_ID"
  if host_file_is_unchanged; then
    log no-change
    return
  fi
  git_as_tool -C "$CLONE" commit -q -m "$title"
  push_sync_branch
  REQUEST_BRANCH=$SYNC_BRANCH
  open_request "$CLONE" "$title" "Installed packages on $HOST_ID." || stop_sync_because request-failed
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
  fetch_remote_state || stop_sync_because fetch-failed
  resolve_target_branch
  checkout_sync_branch
  update_host_brewfile || stop_sync_because dump-failed
  request_host_file_change
  log "done $((SECONDS - started_at))s"
}
