CONFIG_FILE=$HOME/.config/accio-brew/config

apply_config_defaults() {
  BREWFILE_PATH=${BREWFILE_PATH:-./Brewfile}
  BREWFILE=${BREWFILE_PATH#./}
}

load_config() {
  [ -f "$CONFIG_FILE" ] || fail "no config found, run accio-brew init"
  source "$CONFIG_FILE"
  [ -n "${REPO_URL:-}" ] && [ -n "${HOST_ID:-}" ] || fail "incomplete config, run accio-brew init"
  apply_config_defaults
  HOST_BRANCH=hosts/$HOST_ID
}

load_config_if_present() {
  [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
  apply_config_defaults
}

write_config() {
  mkdir -p "$(dirname "$CONFIG_FILE")"
  {
    printf 'REPO_URL=%q\n' "$REPO_URL"
    printf 'BREWFILE_PATH=%q\n' "$BREWFILE_PATH"
    printf 'SYNC_MODE=%q\n' "$SYNC_MODE"
    printf 'HOST_ID=%q\n' "$HOST_ID"
  } > "$CONFIG_FILE"
}
