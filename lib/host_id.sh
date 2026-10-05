as_host_id() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-'
}

default_host_id() {
  HOST_ID=${HOST_ID:-$(as_host_id "$(scutil --get LocalHostName)")}
}

host_id_is_taken_on_remote() {
  printf '%s\n' "$remote_refs" | grep -Eq "refs/heads/(sync|hosts)/$HOST_ID\$"
}

confirm_host_id() {
  clone_matches_repo && return
  host_id_is_taken_on_remote || return 0
  ask_text "$HOST_ID exists. Name for this Mac" "$HOST_ID"
  HOST_ID=$(as_host_id "$answer")
}
