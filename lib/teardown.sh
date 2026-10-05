command_teardown() {
  remove_launchd
  rm -f "$BINARY_LINK"
  echo "launchd agent removed. Still on disk: $TOOL_ROOT, $CONFIG_FILE, $CLONE, $LOG_FILE"
  echo "Your hosts/<id> branch on the remote is untouched."
}
