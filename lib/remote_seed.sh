seed_empty_remote() {
  local seed
  [ -z "$remote_refs" ] || return 0
  seed=$(mktemp -d)
  git init -q -b main "$seed"
  mkdir -p "$(dirname "$seed/$BREWFILE")"
  : > "$seed/$BREWFILE"
  git -C "$seed" add -- "$BREWFILE"
  git_as_tool -C "$seed" commit -q -m "chore: add empty target Brewfile"
  git -C "$seed" push -q "$REPO_URL" HEAD:refs/heads/main || fail "cannot push the initial Brewfile to $REPO_URL"
  rm -rf "$seed"
  echo "The repo was empty. Created main with an empty target Brewfile."
}
