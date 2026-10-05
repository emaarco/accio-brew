ACCIO_BREW=$TOOL_ROOT/bin/accio-brew

init_with_flags() {
  "$ACCIO_BREW" init --repo-url "$REMOTE" </dev/null
}

init_with_answers() {
  "$ACCIO_BREW" init "$@" < "$SANDBOX/answers"
}

sync() {
  "$ACCIO_BREW" sync
}

given_initialised_host() {
  create_remote "$REMOTE"
  assert_exit 0 init_with_flags
}

config_value() {
  (source "$CONFIG" && eval "printf '%s' \"\$$1\"")
}

point_config_to() {
  sed -i '' "s|^REPO_URL=.*|REPO_URL=$1|" "$CONFIG"
}

brew_calls() {
  cat "$HOME/brew.calls"
}

launchctl_calls() {
  cat "$HOME/launchctl.calls"
}
