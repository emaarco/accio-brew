whole_program() {
  cat "$TOOL_ROOT"/lib/*.sh "$TOOL_ROOT/bin/accio-brew"
}

whole_test_suite() {
  local tests=$TOOL_ROOT/tests
  cat "$tests/assertions.sh" "$tests/sandbox.sh" "$tests/remote.sh" "$tests/accio_brew.sh" "$tests"/test_*.sh "$tests/run.sh"
}

test_launchd_template_is_valid_plist() {
  assert_exit 0 plutil -lint "$TOOL_ROOT/modules/launchd.plist"
}

test_no_file_exceeds_150_lines() {
  local longest
  longest=$(wc -l "$TOOL_ROOT"/bin/* "$TOOL_ROOT"/lib/* "$TOOL_ROOT"/modules/* "$TOOL_ROOT"/tests/*.sh | grep -v ' total$' | sort -n | tail -1)
  [ "${longest% *}" -le 150 ] || fail_test "too long: $longest"
}

test_tool_passes_shellcheck() {
  PATH=$DEVELOPER_PATH
  command -v shellcheck >/dev/null || return 0
  whole_program | assert_exit 0 shellcheck --shell=bash --exclude=SC1090 -
}

test_fakes_pass_shellcheck() {
  PATH=$DEVELOPER_PATH
  command -v shellcheck >/dev/null || return 0
  assert_exit 0 shellcheck "$TOOL_ROOT"/tests/fakes/brew "$TOOL_ROOT"/tests/fakes/scutil "$TOOL_ROOT"/tests/fakes/launchctl "$TOOL_ROOT"/tests/fakes/ssh "$TOOL_ROOT"/tests/fakes/recording-ssh "$TOOL_ROOT"/tests/fakes/optional/gum "$TOOL_ROOT"/tests/fakes/optional/gh "$TOOL_ROOT"/tests/fakes/optional/glab
}

test_test_suite_passes_shellcheck() {
  PATH=$DEVELOPER_PATH
  command -v shellcheck >/dev/null || return 0
  whole_test_suite | assert_exit 0 shellcheck --shell=bash --exclude=SC1090,SC1091,SC2154,SC2329 -
}
