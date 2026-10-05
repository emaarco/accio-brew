ZSHRC=${ZDOTDIR:-$HOME}/.zshrc
WRAPPER_BLOCK_START='# >>> accio-brew >>>'
WRAPPER_BLOCK_END='# <<< accio-brew <<<'

remove_wrapper() {
  local remaining
  grep -qxF "$WRAPPER_BLOCK_START" "$ZSHRC" 2>/dev/null || return 0
  grep -qxF "$WRAPPER_BLOCK_END" "$ZSHRC" || fail "incomplete accio-brew block in $ZSHRC, remove it by hand"
  remaining=$(mktemp)
  sed "/^$WRAPPER_BLOCK_START\$/,/^$WRAPPER_BLOCK_END\$/d" "$ZSHRC" > "$remaining"
  cat "$remaining" > "$ZSHRC"
  rm -f "$remaining"
}

end_zshrc_with_newline() {
  [ -s "$ZSHRC" ] && [ -n "$(tail -c 1 "$ZSHRC")" ] && echo >> "$ZSHRC"
}

install_wrapper() {
  end_zshrc_with_newline
  {
    printf '%s\n' "$WRAPPER_BLOCK_START"
    printf 'source %q\n' "$TOOL_ROOT/modules/wrapper.zsh"
    printf '%s\n' "$WRAPPER_BLOCK_END"
  } >> "$ZSHRC"
  echo "Wrapper installed. Open a new terminal to activate it."
}
