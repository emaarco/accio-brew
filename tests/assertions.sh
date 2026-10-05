fail_test() {
  printf 'assertion failed: %s\n' "$*"
  exit 1
}

assert_eq() {
  [ "$1" = "$2" ] || fail_test "expected '$1', got '$2'"
}

assert_contains() {
  case $2 in
    *"$1"*) ;;
    *) fail_test "expected '$1' in '$2'" ;;
  esac
}

assert_not_contains() {
  case $2 in
    *"$1"*) fail_test "did not expect '$1' in '$2'" ;;
  esac
}

assert_exit() {
  local expected=$1 actual
  shift
  "$@" > "$SANDBOX/last.out" 2>&1
  actual=$?
  [ "$actual" = "$expected" ] || fail_test "expected exit $expected, got $actual from: $* ($(last_output))"
}

assert_missing() {
  [ ! -e "$1" ] || fail_test "expected $1 to be missing"
}

assert_exists() {
  [ -e "$1" ] || fail_test "expected $1 to exist"
}

assert_same_file() {
  cmp -s "$1" "$2" || fail_test "$1 and $2 differ"
}

last_output() {
  cat "$SANDBOX/last.out"
}
