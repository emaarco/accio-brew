ask() {
  local question=$1
  while true; do
    printf '%s' "$question"
    if ! read -r answer && [ -z "$answer" ]; then
      echo
      [ $# -ge 2 ] || fail "missing answer for: $question"
    fi
    [ -n "$answer" ] && return
    if [ $# -ge 2 ]; then
      answer=$2
      return
    fi
  done
}
