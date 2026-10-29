setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../node-reinstall"
  FIXTURE="$BATS_TEST_TMPDIR/fixture"
  mkdir -p "$FIXTURE/bin" "$FIXTURE/home" "$FIXTURE/prefix/bin"
  TRACE="$FIXTURE/trace"
  : > "$TRACE"

  # Only these read-only utilities and the recording stubs are on the child PATH.
  # The Bats process keeps its original environment and can clean up normally.
  local command
  for command in bash basename grep ls sed wc xargs; do
    ln -s "$(command -v "$command")" "$FIXTURE/bin/$command"
  done
  for command in sudo rm curl node npm nvm nave which; do
    ln -s "$BATS_TEST_DIRNAME/stub" "$FIXTURE/bin/$command"
  done
  INSTALLED_VERSION=
  NPM_PRESENT=0
  GLOBAL_MODULES_FIXTURE=0
}

teardown() {
  # The installer does not use set -e: catch rejected stub calls even if it
  # continued and ultimately returned success.
  if [ -s "$TRACE.rejected" ]; then
    cat "$TRACE.rejected" >&2
    return 1
  fi
}

reinstall() {
  # Do not inherit exported shell functions, BASH_ENV, NVM_DIR or user settings.
  env -i HOME="$FIXTURE/home" PREFIX="$FIXTURE/prefix" \
    PATH="$FIXTURE/bin" TRACE="$TRACE" \
    INSTALLED_VERSION="$INSTALLED_VERSION" NPM_PRESENT="$NPM_PRESENT" GLOBAL_MODULES_FIXTURE="$GLOBAL_MODULES_FIXTURE" \
    /bin/bash "$SCRIPT" "$@"
}

assert_called() {
  grep -Fx -- "$*" "$TRACE"
}

assert_not_called() {
  ! grep -E -- "$1" "$TRACE"
}
