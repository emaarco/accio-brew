ask_text_plain() {
  local question=$1 hint=
  [ $# -ge 2 ] && hint=" [$2]"
  while true; do
    printf '%s%s: ' "$question" "$hint"
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

ask_choice_plain() {
  local question=$1 default_choice=$2 number=0 option
  shift 2
  echo "$question"
  for option; do
    number=$((number + 1))
    echo "  $number) $option"
  done
  ask_text_plain Choice "$default_choice"
  choice=$answer
}

ask_yes_no_plain() {
  printf '%s [Y/n]: ' "$1"
  read -r answer || echo
  case $answer in
    n|N) return 1 ;;
  esac
}
