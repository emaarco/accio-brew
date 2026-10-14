list_direct_dependencies() {
  HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1 brew deps --installed --direct --for-each 9>&-
}

list_requested_packages() {
  HOMEBREW_NO_AUTO_UPDATE=1 brew leaves --installed-on-request 9>&- &&
    HOMEBREW_NO_AUTO_UPDATE=1 brew list --cask --full-name 9>&-
}

graph_lines() {
  awk '
    function node_id(name,  id) {
      id = name
      gsub(/[^A-Za-z0-9]/, "_", id)
      return "n_" id
    }
    FILENAME == ARGV[1] { requested[$0] = 1; next }
    {
      package = $1
      sub(/:$/, "", package)
      packages[package] = 1
      for (i = 2; i <= NF; i++) {
        packages[$i] = 1
        print "2   " node_id(package) " --> " node_id($i)
      }
    }
    END {
      for (package in packages) {
        style = (package in requested) ? ":::requested" : ""
        print "1   " node_id(package) "[\"" package "\"]" style
      }
    }
  ' "$1" "$2" | LC_ALL=C sort -u | cut -c3-
}

graph_markdown() {
  printf '# Homebrew dependencies\n\n'
  printf 'Arrows point from a package to its direct dependencies. Highlighted packages were installed on request.\n\n'
  printf '```mermaid\nflowchart LR\n  classDef requested fill:#d4edda,stroke:#28a745\n'
  graph_lines "$1" "$2"
  printf '```\n'
}

write_dependency_graph() {
  local requested dependencies status
  requested=$(mktemp)
  dependencies=$(mktemp)
  list_requested_packages > "$requested" &&
    list_direct_dependencies > "$dependencies" &&
    graph_markdown "$requested" "$dependencies"
  status=$?
  rm -f "$requested" "$dependencies"
  return "$status"
}

command_graph() {
  write_dependency_graph || fail "cannot read the dependencies from brew"
}
