#!/bin/bash
set -u

TOOL_ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEVELOPER_PATH=$PATH

for support in assertions sandbox remote accio_brew; do
  source "$TOOL_ROOT/tests/$support.sh"
done
for test_file in "$TOOL_ROOT"/tests/test_*.sh; do
  source "$test_file"
done

run_test() {
  local name=$1 output
  output=$(mktemp)
  if (setup_sandbox && "$name") > "$output" 2>&1; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    sed 's/^/     /' "$output"
    failures=$((failures + 1))
  fi
  rm -f "$output"
}

failures=0
for test_name in $(declare -F | awk '{print $3}' | grep '^test_'); do
  case $test_name in
    *"${1:-}"*) run_test "$test_name" ;;
  esac
done
[ "$failures" -eq 0 ] || echo "$failures test(s) failed"
exit "$failures"
