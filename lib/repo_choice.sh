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
  ask_text "Repository (owner/name)"
  repo_path=${answer#/}
  repo_path=${repo_path%/}
  repo_path=${repo_path%.git}
  probe_candidates "https://$host/$repo_path.git" "git@$host:$repo_path.git"
}

probe_pasted_url() {
  ask_text "Clone URL"
  probe_candidates "$answer"
}

ask_repo_url() {
  ask_choice "Where is your Brewfile repo?" 1 github.com gitlab.com "paste clone URL"
  case $choice in
    2) probe_repository_on gitlab.com ;;
    3) probe_pasted_url ;;
    *) probe_repository_on github.com ;;
  esac
}

keeps_current_repo() {
  [ -n "${REPO_URL:-}" ] || return 1
  [ -n "$mode_flag" ] && return 0
  ask_yes_no "Keep repo $REPO_URL?"
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
