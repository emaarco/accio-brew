LAUNCHD_LABEL=io.accio-brew
LAUNCHD_PLIST=$HOME/Library/LaunchAgents/$LAUNCHD_LABEL.plist

remove_launchd() {
  [ -f "$LAUNCHD_PLIST" ] || return 0
  launchctl bootout "gui/$(id -u)/$LAUNCHD_LABEL" 2>/dev/null
  rm -f "$LAUNCHD_PLIST"
}

render_launchd_plist() {
  local agent_path
  agent_path=$(dirname "$(command -v brew)"):/usr/bin:/bin:/usr/sbin:/sbin
  sed -e "s|__ACCIO_BREW__|$TOOL_ROOT/bin/accio-brew|" \
    -e "s|__PATH__|$agent_path|" \
    -e "s|__LOG__|$LOG_FILE|" \
    "$TOOL_ROOT/modules/launchd.plist"
}

install_launchd() {
  mkdir -p "$(dirname "$LAUNCHD_PLIST")" "$(dirname "$LOG_FILE")"
  render_launchd_plist > "$LAUNCHD_PLIST"
  launchctl bootstrap "gui/$(id -u)" "$LAUNCHD_PLIST" || fail "cannot load $LAUNCHD_PLIST"
  echo "launchd agent installed. It syncs hourly."
}
