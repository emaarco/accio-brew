enter_home() {
  export HOME=$SANDBOX/home-$1
  export FAKE_HOST=$1
  mkdir -p "$HOME/Library/Logs"
  CONFIG=$HOME/.config/accio-brew/config
  CLONE=$HOME/.local/share/accio-brew/repo
  PLIST=$HOME/Library/LaunchAgents/io.accio-brew.plist
}

use_isolated_git_config() {
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_CONFIG_GLOBAL=$SANDBOX/gitconfig
  git config --global user.name tester
  git config --global user.email tester@example.com
  git config --global commit.gpgsign false
}

setup_sandbox() {
  SANDBOX=$(mktemp -d)
  trap 'rm -rf "$SANDBOX"' EXIT
  export PATH=$TOOL_ROOT/tests/fakes:/usr/bin:/bin:/usr/sbin:/sbin
  export FAKE_INSTALLED=$SANDBOX/installed
  export FAKE_DEPENDENCIES=$SANDBOX/dependencies
  export FAKE_REQUESTED=$SANDBOX/requested
  export FAKE_CASKS=$SANDBOX/casks
  use_isolated_git_config
  enter_home a
  set_installed git
  set_dependencies "git:"
  set_requested git
  : > "$FAKE_CASKS"
  REMOTE=$SANDBOX/remote.git
}

set_installed() {
  printf 'brew "%s"\n' "$@" > "$FAKE_INSTALLED"
}

set_dependencies() {
  printf '%s\n' "$@" > "$FAKE_DEPENDENCIES"
}

set_requested() {
  printf '%s\n' "$@" > "$FAKE_REQUESTED"
}

set_casks() {
  printf '%s\n' "$@" > "$FAKE_CASKS"
}

answer_with() {
  printf '%s\n' "$@" > "$SANDBOX/answers"
}
