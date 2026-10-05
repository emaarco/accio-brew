create_empty_remote() {
  git init -q --bare -b main "$1"
}

target_checkout() {
  printf '%s' "$SANDBOX/target-$(basename "$1")"
}

publish_target() {
  local remote=$1 package=$2 checkout
  checkout=$(target_checkout "$remote")
  [ -d "$checkout" ] || git init -q -b main "$checkout"
  printf 'brew "%s"\n' "$package" > "$checkout/Brewfile"
  git -C "$checkout" add Brewfile
  git -C "$checkout" commit -q -m "chore: set target to $package"
  git -C "$checkout" push -q "$remote" main
}

create_remote() {
  create_empty_remote "$1"
  publish_target "$1" target
}

map_url_to() {
  git config --global "url.$2.insteadOf" "$1"
}

unplug_remote() {
  mv "$REMOTE" "$SANDBOX/unplugged.git"
}

replug_remote() {
  mv "$SANDBOX/unplugged.git" "$REMOTE"
}

remote_file() {
  git -C "$REMOTE" show "$1:Brewfile"
}

remote_commit_count() {
  git -C "$REMOTE" rev-list --count "$1"
}

last_remote_commit() {
  git -C "$REMOTE" log -1 --format="$1" hosts/a
}
