test_graph_is_a_mermaid_flowchart() {
  assert_exit 0 graph
  assert_contains '```mermaid' "$(last_output)"
  assert_contains 'flowchart LR' "$(last_output)"
}

test_graph_points_from_package_to_its_dependency() {
  set_dependencies "git: pcre2" "pcre2:"
  assert_exit 0 graph
  assert_contains 'n_git --> n_pcre2' "$(last_output)"
}

test_graph_shows_package_without_dependencies() {
  set_dependencies "bruno:"
  assert_exit 0 graph
  assert_contains 'n_bruno["bruno"]' "$(last_output)"
}

test_graph_highlights_requested_formulae() {
  set_dependencies "git: pcre2" "pcre2:"
  assert_exit 0 graph
  assert_contains 'n_git["git"]:::requested' "$(last_output)"
  assert_not_contains 'n_pcre2["pcre2"]:::requested' "$(last_output)"
}

test_graph_highlights_casks() {
  set_dependencies "bruno:"
  set_casks bruno
  assert_exit 0 graph
  assert_contains 'n_bruno["bruno"]:::requested' "$(last_output)"
}

test_graph_highlights_casks_of_other_taps() {
  set_dependencies "miragon/tap/modeler:"
  set_casks miragon/tap/modeler
  assert_exit 0 graph
  assert_contains 'n_miragon_tap_modeler["miragon/tap/modeler"]:::requested' "$(last_output)"
}

test_graph_turns_names_into_valid_ids() {
  set_dependencies "emaarco/tap/accio-brew: gum" "python@3.13:" "gum:"
  assert_exit 0 graph
  assert_contains 'n_emaarco_tap_accio_brew["emaarco/tap/accio-brew"]' "$(last_output)"
  assert_contains 'n_python_3_13["python@3.13"]' "$(last_output)"
}

test_graph_does_not_depend_on_order_reported_by_brew() {
  local first_output
  set_dependencies "zsh: pcre2" "git: pcre2" "pcre2:"
  assert_exit 0 graph
  first_output=$(last_output)
  set_dependencies "pcre2:" "git: pcre2" "zsh: pcre2"
  assert_exit 0 graph
  assert_eq "$first_output" "$(last_output)"
}

test_graph_fails_when_brew_cannot_list_dependencies() {
  rm "$FAKE_DEPENDENCIES"
  assert_exit 1 graph
}
