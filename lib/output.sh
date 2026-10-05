LOG_FILE=$HOME/Library/Logs/accio-brew.log

fail() {
  printf 'accio-brew: %s\n' "$*" >&2
  exit 1
}

utc_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

log() {
  printf '%s %s %s\n' "$(utc_now)" "$HOST_ID" "$*"
}
