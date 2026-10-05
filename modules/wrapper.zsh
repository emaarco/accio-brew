accio_brew_binary=${${(%):-%x}:h:h}/bin/accio-brew

brew() {
  local real_brew=${HOMEBREW_PREFIX:-/opt/homebrew}/bin/brew argument subcommand exit_code
  "$real_brew" "$@"
  exit_code=$?
  for argument; do
    [[ $argument == -* ]] || { subcommand=$argument; break }
  done
  case $subcommand in
    install|uninstall|upgrade)
      ( "$accio_brew_binary" sync </dev/null >>"$HOME/Library/Logs/accio-brew.log" 2>&1 & )
      ;;
  esac
  return $exit_code
}
