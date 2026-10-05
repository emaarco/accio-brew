probed_host=
probed_repository=

creation_page_on() {
  case $1 in
    github.com) echo https://github.com/new ;;
    gitlab.com) echo https://gitlab.com/projects/new ;;
  esac
}

gh_can_create_on() {
  [ "$1" = github.com ] && command -v gh >/dev/null
}

explain_unreachable_repo() {
  local creation_page
  creation_page=$(creation_page_on "$probed_host")
  if [ -z "$creation_page" ]; then
    echo "Cannot reach $probed_candidates. Create the repo in your host's web UI or check access."
    return
  fi
  echo "Cannot reach $probed_candidates."
  echo "No repo yet? Create it private and empty, without a README: $creation_page"
  if gh_can_create_on "$probed_host"; then
    echo "Or run: gh repo create $probed_repository --private"
  fi
  echo "It exists already? Then check your access."
}
