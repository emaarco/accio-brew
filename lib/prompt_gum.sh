ask_text_gum() {
  local question=$1
  while true; do
    answer=$(gum input --header "$question" --value "${2-}") || fail "setup cancelled"
    [ -n "$answer" ] && return
    if [ $# -ge 2 ]; then
      answer=$2
      return
    fi
  done
}

ask_choice_gum() {
  local question=$1 default_choice=$2 selected option
  shift 2
  selected=$(gum choose --header "$question" --selected "${!default_choice}" "$@") || fail "setup cancelled"
  choice=0
  for option; do
    choice=$((choice + 1))
    [ "$option" = "$selected" ] && return
  done
}

ask_yes_no_gum() {
  gum confirm "$1"
}
