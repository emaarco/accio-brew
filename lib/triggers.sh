BINARY_LINK=$HOME/.local/bin/accio-brew

validate_mode() {
  case $1 in
    wrapper|launchd) ;;
    *) fail "mode must be wrapper or launchd" ;;
  esac
}

remove_triggers() {
  remove_wrapper
  remove_launchd
}

install_trigger() {
  remove_triggers
  "install_$SYNC_MODE"
}

link_binary() {
  mkdir -p "$(dirname "$BINARY_LINK")"
  ln -sf "$TOOL_ROOT/bin/accio-brew" "$BINARY_LINK"
  case ":$PATH:" in
    *":$(dirname "$BINARY_LINK"):"*) ;;
    *) echo "Add accio-brew to your PATH: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
  esac
}

command_teardown() {
  remove_triggers
  rm -f "$BINARY_LINK"
  echo "Triggers removed. Still on disk: $TOOL_ROOT, $CONFIG_FILE, $CLONE, $LOG_FILE"
  echo "Your hosts/<id> branch on the remote is untouched."
}
