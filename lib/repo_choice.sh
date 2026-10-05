remote_was_probed=false

probe_candidates() {
  local candidate
  probed_candidates=$*
  for candidate; do
    printf 'Checking %s ... ' "$candidate"
    if remote_refs=$(list_remote_refs "$candidate"); then
      echo ok
      REPO_URL=$candidate
      remote_was_probed=true
      return 0
    fi
    echo failed
  done
  return 1
}

probe_repository_on() {
  local host=$1 repo_path
  ask "Repository (owner/name): "
  repo_path=${answer#/}
  repo_path=${repo_path%/}
  repo_path=${repo_path%.git}
  probe_candidates "https://$host/$repo_path.git" "git@$host:$repo_path.git"
}

probe_pasted_url() {
  ask "Clone URL: "
  probe_candidates "$answer"
}

ask_repo_url() {
  echo "Where is your Brewfile repo?"
  echo "  1) github.com"
  echo "  2) gitlab.com"
  echo "  3) paste clone URL"
  ask "Choice [1]: " 1
  case $answer in
    2) probe_repository_on gitlab.com ;;
    3) probe_pasted_url ;;
    *) probe_repository_on github.com ;;
  esac
}

keeps_current_repo() {
  [ -n "${REPO_URL:-}" ] || return 1
  [ -n "$mode_flag" ] && return 0
  ask "Keep repo $REPO_URL? [Y/n]: " y
  case $answer in
    n|N) return 1 ;;
  esac
}

choose_repo_url() {
  if [ -n "$repo_url_flag" ]; then
    probe_candidates "$repo_url_flag" || fail "cannot reach $repo_url_flag"
    return
  fi
  keeps_current_repo && return
  until ask_repo_url; do
    echo "Cannot reach $probed_candidates. Create the repo in your host's web UI or check access."
  done
}
