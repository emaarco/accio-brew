clone_target() {
  local checkout=$1
  git clone -q --depth 1 "$REPO_URL" "$checkout" 2>/dev/null || return 1
  git -C "$checkout" rev-parse -q --verify HEAD >/dev/null || return 1
  target_branch=$(git -C "$checkout" symbolic-ref --short -q HEAD)
}

target_has_packages() {
  [ -s "$1/$BREWFILE" ]
}

packages_missing_in() {
  local target=$1/$BREWFILE
  mkdir -p "$(dirname "$target")"
  touch "$target"
  grep -vxFf "$target" "$CLONE/$HOST_FILE"
}

push_proposal() {
  local checkout=$1 quiet=
  [ -z "$(platform_cli)" ] || quiet=-q
  git -C "$checkout" switch -q -c "$REQUEST_BRANCH"
  git -C "$checkout" add -- "$BREWFILE"
  git_as_tool -C "$checkout" commit -q -m "feat: add packages from $HOST_ID"
  git -C "$checkout" push $quiet --force origin "$REQUEST_BRANCH" || fail "cannot push $REQUEST_BRANCH to $REPO_URL"
}

propose_missing_packages() {
  local checkout=$1 missing
  REQUEST_BRANCH=propose/$HOST_ID
  missing=$(packages_missing_in "$checkout")
  if [ -z "$missing" ]; then
    echo "Nothing to propose."
    return
  fi
  printf '%s\n' "$missing" >> "$checkout/$BREWFILE"
  push_proposal "$checkout"
  open_request "$checkout" "feat: add packages from $HOST_ID" "$missing"
}

propose_first_target() {
  local checkout
  checkout=$(mktemp -d)
  if clone_target "$checkout" && ! target_has_packages "$checkout"; then
    echo "The target Brewfile on $target_branch is empty. Proposing this Mac's packages."
    propose_missing_packages "$checkout"
  fi
  rm -rf "$checkout"
}

command_propose() {
  local checkout
  command_sync
  checkout=$(mktemp -d)
  clone_target "$checkout" || fail "cannot determine the default branch of $REPO_URL"
  propose_missing_packages "$checkout"
  rm -rf "$checkout"
}
