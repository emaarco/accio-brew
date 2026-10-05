parse_init_flags() {
  repo_url_flag=
  mode_flag=
  while [ $# -gt 0 ]; do
    [ -n "${2:-}" ] || fail "missing value for $1"
    case $1 in
      --repo-url) repo_url_flag=$2 ;;
      --mode)
        mode_flag=$2
        validate_mode "$mode_flag"
        ;;
      *) fail "unknown option: $1" ;;
    esac
    shift 2
  done
}

ask_mode() {
  local default_choice=1
  [ "${SYNC_MODE:-}" = launchd ] && default_choice=2
  echo "How should sync be triggered?"
  echo "  1) wrapper  - after every brew install/uninstall/upgrade"
  echo "  2) launchd  - hourly in the background"
  ask "Choice [$default_choice]: " "$default_choice"
  case $answer in
    2) SYNC_MODE=launchd ;;
    *) SYNC_MODE=wrapper ;;
  esac
}

choose_mode() {
  if [ -n "$mode_flag" ]; then
    SYNC_MODE=$mode_flag
  else
    ask_mode
  fi
}

prepare_probed_remote() {
  $remote_was_probed || return 0
  confirm_host_id
  seed_empty_remote
}

command_init() {
  parse_init_flags "$@"
  command -v brew >/dev/null || fail "Homebrew is not installed"
  load_config_if_present
  choose_repo_url
  default_host_id
  prepare_probed_remote
  choose_mode
  write_config
  drop_foreign_clone
  link_binary
  command_sync
  install_trigger
  echo "Done. Run 'accio-brew apply' to install the target Brewfile on this Mac."
}
