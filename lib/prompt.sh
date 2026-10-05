stdin_is_terminal() {
  [ -t 0 ]
}

uses_gum() {
  stdin_is_terminal && command -v gum >/dev/null
}

prompt_style() {
  if uses_gum; then
    echo gum
  else
    echo plain
  fi
}

ask_text() {
  "ask_text_$(prompt_style)" "$@"
}

ask_choice() {
  "ask_choice_$(prompt_style)" "$@"
}

ask_yes_no() {
  "ask_yes_no_$(prompt_style)" "$@"
}
