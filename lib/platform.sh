platform_cli() {
  case $REPO_URL in
    *github.com[:/]*) echo gh ;;
    *gitlab.com[:/]*) echo glab ;;
  esac
}

platform_host() {
  case $1 in
    gh) echo github.com ;;
    glab) echo gitlab.com ;;
  esac
}

require_platform_cli() {
  local cli host
  cli=$(platform_cli)
  [ -n "$cli" ] || return 0
  host=$(platform_host "$cli")
  command -v "$cli" >/dev/null || fail "$host repos need $cli: brew install $cli && $cli auth login"
  "$cli" auth status --hostname "$host" >/dev/null 2>&1 || fail "$cli is not logged in: $cli auth login"
}

request_is_open_on_github() {
  [ "$(gh pr list --head "$REQUEST_BRANCH" --json number --jq length)" != 0 ]
}

request_is_open_on_gitlab() {
  [ "$(glab mr list --source-branch "$REQUEST_BRANCH" --output json)" != "[]" ]
}

open_request_with_gh() {
  if request_is_open_on_github; then
    echo "Updated the open pull request for $REQUEST_BRANCH."
    return
  fi
  gh pr create --base "$target_branch" --head "$REQUEST_BRANCH" --title "$1" --body "$2" || fail "cannot open a pull request for $REQUEST_BRANCH"
}

open_request_with_glab() {
  if request_is_open_on_gitlab; then
    echo "Updated the open merge request for $REQUEST_BRANCH."
    return
  fi
  glab mr create --source-branch "$REQUEST_BRANCH" --target-branch "$target_branch" --title "$1" --description "$2" --yes || fail "cannot open a merge request for $REQUEST_BRANCH"
}

open_request() {
  local checkout=$1 title=$2 body=$3 cli
  cli=$(platform_cli)
  if [ -z "$cli" ]; then
    echo "Open a merge request from $REQUEST_BRANCH into $target_branch."
    return
  fi
  (cd "$checkout" && "open_request_with_$cli" "$title" "$body")
}
