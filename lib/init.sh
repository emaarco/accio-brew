parse_init_flags() {
  repo_url_flag=
  while [ $# -gt 0 ]; do
    [ -n "${2:-}" ] || fail "missing value for $1"
    case $1 in
      --repo-url) repo_url_flag=$2 ;;
      *) fail "unknown option: $1" ;;
    esac
    shift 2
  done
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
  require_platform_cli
  default_host_id
  prepare_probed_remote
  write_config
  drop_foreign_clone
  link_binary
  command_sync
  install_launchd
  propose_first_target
  echo "Done. Run 'accio-brew apply' to install the target Brewfile on this Mac."
}
