git_as_tool() {
  git -c user.name=accio-brew -c user.email="accio-brew@$HOST_ID" -c commit.gpgsign=false "$@" 9>&-
}

configured_ssh_command() {
  printf '%s' "${GIT_SSH_COMMAND:-$(git config --get core.sshCommand || echo ssh)}"
}

use_unattended_git() {
  export GIT_TERMINAL_PROMPT=0
  GIT_SSH_COMMAND="$(configured_ssh_command) -o BatchMode=yes -o ConnectTimeout=10"
  export GIT_SSH_COMMAND
}

list_remote_refs() {
  (use_unattended_git && git ls-remote "$1" 2>/dev/null)
}
