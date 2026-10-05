given_gum_in_a_terminal() {
  export PATH=$TOOL_ROOT/tests/fakes/optional:$PATH
  source "$TOOL_ROOT/lib/output.sh"
  source "$TOOL_ROOT/lib/prompt.sh"
  source "$TOOL_ROOT/lib/prompt_plain.sh"
  source "$TOOL_ROOT/lib/prompt_gum.sh"
  stdin_is_terminal() {
    true
  }
}

gum_calls() {
  cat "$HOME/gum.calls"
}

test_gum_choice_yields_number_of_selected_option() {
  given_gum_in_a_terminal
  FAKE_GUM_ANSWER="paste clone URL" ask_choice "Where?" 1 github.com gitlab.com "paste clone URL"
  assert_eq 3 "$choice"
}

test_gum_choice_preselects_default_option() {
  given_gum_in_a_terminal
  FAKE_GUM_ANSWER=gitlab.com ask_choice "Where?" 2 github.com gitlab.com
  assert_eq "choose --header Where? --selected gitlab.com github.com gitlab.com" "$(gum_calls)"
}

test_gum_text_yields_typed_answer() {
  given_gum_in_a_terminal
  FAKE_GUM_ANSWER=acme/brewfiles ask_text "Repository (owner/name)"
  assert_eq "acme/brewfiles" "$answer"
}

test_gum_text_offers_default_as_initial_value() {
  given_gum_in_a_terminal
  FAKE_GUM_ANSWER=office ask_text "Name for this Mac" macbook
  assert_eq "input --header Name for this Mac --value macbook" "$(gum_calls)"
}

test_gum_text_falls_back_to_default_when_cleared() {
  given_gum_in_a_terminal
  FAKE_GUM_ANSWER="" ask_text "Name for this Mac" macbook
  assert_eq "macbook" "$answer"
}

test_gum_confirm_accepts() {
  given_gum_in_a_terminal
  ask_yes_no "Keep repo?" || fail_test "expected yes"
}

test_gum_confirm_declines() {
  given_gum_in_a_terminal
  FAKE_GUM_EXIT=1 ask_yes_no "Keep repo?" && fail_test "expected no"
  return 0
}

cancelled_prompt() (
  FAKE_GUM_EXIT=130 ask_text "Clone URL"
)

test_cancelled_gum_prompt_stops_setup() {
  given_gum_in_a_terminal
  assert_exit 1 cancelled_prompt
  assert_contains "setup cancelled" "$(last_output)"
}

test_wizard_ignores_gum_without_a_terminal() {
  export PATH=$TOOL_ROOT/tests/fakes/optional:$PATH
  create_remote "$REMOTE"
  answer_with 3 "$REMOTE" ""
  assert_exit 0 init_with_answers
  assert_missing "$HOME/gum.calls"
}
