# Loaded by Bats, never by node-reinstall.
setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TEST_ROOT="$BATS_TEST_TMPDIR/sandbox"
  TEST_HOME="$TEST_ROOT/home"
  TEST_PREFIX="$TEST_ROOT/prefix"
  TEST_BIN="$TEST_ROOT/bin"
  TEST_LOG="$TEST_ROOT/calls"
  TEST_VIOLATIONS="$TEST_ROOT/violations"
  mkdir -p "$TEST_HOME" "$TEST_PREFIX" "$TEST_BIN"
  : > "$TEST_LOG"
  : > "$TEST_VIOLATIONS"
  printf 'home sentinel\n' > "$TEST_HOME/sentinel"
  printf 'prefix sentinel\n' > "$TEST_PREFIX/sentinel"
  printf 'outside sentinel\n' > "$TEST_ROOT/outside"

  local command
  for command in sudo rm curl bash node npm nvm nave which xargs; do
    ln -s "$REPO_ROOT/test/stub-command" "$TEST_BIN/$command"
  done
  # These are the only real utilities exposed to the installer. xargs is
  # separately guarded below so it can invoke only the real basename utility.
  for command in grep sed basename ls wc; do
    ln -s "$(command -v "$command")" "$TEST_BIN/$command"
  done
  REAL_XARGS="$(command -v xargs)"
  TEST_NODE_VERSION=
  TEST_HAS_NPM=0
  TEST_NPM_LIST="$TEST_PREFIX/lib"
}

teardown() {
  # The installer does not use set -e. Check this independently of its exit code.
  if [[ -s "$TEST_VIOLATIONS" ]]; then
    cat "$TEST_VIOLATIONS" >&2
    return 1
  fi
  [[ "$(< "$TEST_HOME/sentinel")" == 'home sentinel' ]] || return 1
  [[ "$(< "$TEST_PREFIX/sentinel")" == 'prefix sentinel' ]] || return 1
  [[ "$(< "$TEST_ROOT/outside")" == 'outside sentinel' ]]
}

run_installer() {
  # Do not inherit the caller's HOME, PATH, shell functions or startup files.
  run timeout --kill-after=2s 10s env -i \
    HOME="$TEST_HOME" PREFIX="$TEST_PREFIX" PATH="$TEST_BIN" LC_ALL=C \
    TEST_ROOT="$TEST_ROOT" TEST_HOME="$TEST_HOME" TEST_PREFIX="$TEST_PREFIX" \
    TEST_BIN="$TEST_BIN" TEST_LOG="$TEST_LOG" TEST_VIOLATIONS="$TEST_VIOLATIONS" \
    TEST_NODE_VERSION="$TEST_NODE_VERSION" TEST_HAS_NPM="$TEST_HAS_NPM" \
    TEST_NPM_LIST="$TEST_NPM_LIST" REAL_XARGS="$REAL_XARGS" \
    BASH_ENV="$REPO_ROOT/test/guard-env.bash" \
    /bin/bash "$REPO_ROOT/node-reinstall" "$@"
}

assert_call() {
  local expected
  printf -v expected '%q ' "$@"
  grep -Fqx -- "$expected" "$TEST_LOG"
}

refute_command() {
  ! grep -q -- "^$1 " "$TEST_LOG"
}

assert_simulated_completion() {
  [[ "$status" -eq 0 ]]
  [[ "$output" == *'node-reinstall is done.'* ]]
  [[ "$output" == *'restart your terminal'* ]]
}

run_stub() {
  run env -i PATH="$TEST_BIN" TEST_ROOT="$TEST_ROOT" TEST_HOME="$TEST_HOME" \
    TEST_PREFIX="$TEST_PREFIX" TEST_BIN="$TEST_BIN" TEST_LOG="$TEST_LOG" \
    TEST_VIOLATIONS="$TEST_VIOLATIONS" "$TEST_BIN/$1" "${@:2}"
}

assert_guard_rejection() {
  [[ "$status" -eq 97 ]]
  [[ "$(wc -l < "$TEST_VIOLATIONS")" -eq 1 ]]
  [[ "$output" == *'STUB REJECTED:'* ]]
  # Only these intentional guard tests consume their one expected violation.
  : > "$TEST_VIOLATIONS"
}
