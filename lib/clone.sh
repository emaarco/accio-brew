DATA_DIR=$HOME/.local/share/accio-brew
CLONE=$DATA_DIR/repo

git_in_clone() {
  git -C "$CLONE" "$@" 9>&-
}

clone_matches_repo() {
  [ "$(git_in_clone config --get remote.origin.url 2>/dev/null)" = "$REPO_URL" ]
}

ensure_clone() {
  if [ ! -d "$CLONE/.git" ]; then
    mkdir -p "$DATA_DIR"
    git clone --quiet --no-checkout "$REPO_URL" "$CLONE" 2>/dev/null || return 1
  fi
  clone_matches_repo || fail "local clone belongs to another repo, run accio-brew init"
}

drop_foreign_clone() {
  [ -d "$CLONE" ] || return 0
  clone_matches_repo || rm -rf "$CLONE"
}
