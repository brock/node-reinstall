#!/usr/bin/env bats

setup() {
  TEST_ROOT="${BATS_TEST_TMPDIR:-${BATS_TMPDIR}/node-reinstall-${BATS_TEST_NUMBER}}"
  export HOME="${TEST_ROOT}/home"
  export PREFIX="${TEST_ROOT}/prefix"
  export MOCK_BIN="${TEST_ROOT}/bin"
  export COMMAND_LOG="${TEST_ROOT}/commands.log"

  mkdir -p "$HOME" "$PREFIX/bin" "$MOCK_BIN"
  : > "$COMMAND_LOG"

  create_mock_commands
  export PATH="${MOCK_BIN}:${PATH}"
}

create_mock_commands() {
  cat > "${MOCK_BIN}/sudo" <<'SH'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "$COMMAND_LOG"
exit 0
SH

  cat > "${MOCK_BIN}/rm" <<'SH'
#!/usr/bin/env bash
printf 'rm %s\n' "$*" >> "$COMMAND_LOG"
exit 0
SH

  cat > "${MOCK_BIN}/which" <<'SH'
#!/usr/bin/env bash
case "$1" in
  npm)
    if [ "${MOCK_NPM_PRESENT:-1}" = "1" ]; then
      printf '%s/npm\n' "$MOCK_BIN"
      exit 0
    fi
    exit 1
    ;;
  *)
    command -v "$1"
    ;;
esac
SH

  cat > "${MOCK_BIN}/node" <<'SH'
#!/usr/bin/env bash
if [ "$1" = "--version" ] && [ -n "${MOCK_NODE_VERSION:-}" ]; then
  printf '%s\n' "$MOCK_NODE_VERSION"
  exit 0
fi
exit 1
SH

  cat > "${MOCK_BIN}/npm" <<'SH'
#!/usr/bin/env bash
printf 'npm %s\n' "$*" >> "$COMMAND_LOG"
if [ "$*" = "-g list --depth 0 --parseable" ]; then
  if [ -n "${MOCK_GLOBAL_MODULES:-}" ]; then
    printf '%s\n' "$MOCK_GLOBAL_MODULES"
  fi
  exit 0
fi
exit 0
SH

  cat > "${MOCK_BIN}/curl" <<'SH'
#!/usr/bin/env bash
printf 'curl %s\n' "$*" >> "$COMMAND_LOG"
case "$*" in
  *api.github.com/repos/nvm-sh/nvm/releases/latest*)
    printf '%s\n' '{"tag_name":"v0.39.7"}'
    ;;
  *raw.githubusercontent.com/nvm-sh/nvm/*/install.sh*)
    printf '%s\n' 'echo "mock nvm installer"'
    ;;
  *raw.githubusercontent.com/isaacs/nave/master/nave.sh*)
    printf '%s\n' '# mock nave installer'
    ;;
esac
SH

  cat > "${MOCK_BIN}/nvm" <<'SH'
#!/usr/bin/env bash
printf 'nvm %s\n' "$*" >> "$COMMAND_LOG"
exit 0
SH

  cat > "${MOCK_BIN}/nave" <<'SH'
#!/usr/bin/env bash
printf 'nave %s\n' "$*" >> "$COMMAND_LOG"
exit 0
SH

  chmod +x "${MOCK_BIN}/"*
}

assert_output_contains() {
  case "$output" in
    *"$1"*) return 0 ;;
    *)
      printf 'Expected output to contain: %s\nActual output:\n%s\n' "$1" "$output"
      return 1
      ;;
  esac
}

assert_log_contains() {
  grep -F -- "$1" "$COMMAND_LOG"
}

assert_log_not_contains() {
  ! grep -F -- "$1" "$COMMAND_LOG"
}

@test "--help prints usage without asking for sudo" {
  run ./node-reinstall --help

  [ "$status" -eq 0 ]
  assert_output_contains "Usage:"
  assert_output_contains "node-reinstall [--nave|--nvm|--nvm-latest]"
  assert_log_not_contains "sudo"
}

@test "--version prints the script version without asking for sudo" {
  run ./node-reinstall --version

  [ "$status" -eq 0 ]
  [ "$output" = "0.0.17" ]
  assert_log_not_contains "sudo"
}

@test "unknown options fail before destructive commands run" {
  run ./node-reinstall --wat

  [ "$status" -eq 1 ]
  assert_output_contains "error: Unknown option"
  assert_output_contains "Usage:"
  assert_log_not_contains "sudo"
  assert_log_not_contains "rm "
}

@test "first-time install uses the requested Node version with nvm" {
  export MOCK_NPM_PRESENT=0

  run ./node-reinstall --force 20

  [ "$status" -eq 0 ]
  assert_output_contains "Installing Node, npm."
  assert_output_contains "node-reinstall is done."
  assert_log_contains "sudo -v"
  assert_log_contains "sudo rm -rf ${HOME}/.nvm"
  assert_log_contains "rm -rf ${HOME}/local ${HOME}/lib ${HOME}/include ${HOME}/node* ${HOME}/npm ${HOME}/.npm* ${HOME}/.node-gyp"
  assert_log_contains "curl -H Accept: application/vnd.github.v3+json https://api.github.com/repos/nvm-sh/nvm/releases/latest"
  assert_log_contains "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh"
  assert_log_contains "nvm install 20"
  assert_log_contains "nvm alias default 20"
}

@test "installed Node version is reused when no version is requested" {
  export MOCK_NODE_VERSION="v18.19.0"
  export MOCK_NPM_PRESENT=0

  run ./node-reinstall --force

  [ "$status" -eq 0 ]
  assert_output_contains "Found Node.js version v18.19.0 already installed."
  assert_log_contains "nvm install v18.19.0"
  assert_log_contains "nvm alias default v18.19.0"
}

@test "--nave switches installer and version manager paths" {
  export MOCK_NPM_PRESENT=0

  run ./node-reinstall --force --nave 18.17.1

  [ "$status" -eq 0 ]
  assert_log_contains "sudo rm -rf ${HOME}/.nave"
  assert_log_contains "curl -sL https://raw.githubusercontent.com/isaacs/nave/master/nave.sh -o ${PREFIX}/bin/nave"
  assert_log_contains "nave usemain 18.17.1"
  assert_log_not_contains "nvm install"
}

@test "global npm modules are captured and reinstalled in force mode" {
  export MOCK_NODE_VERSION="v16.13.0"
  export MOCK_NPM_PRESENT=1
  export MOCK_GLOBAL_MODULES="/usr/local/lib/node_modules/http-server"

  run ./node-reinstall --force

  [ "$status" -eq 0 ]
  assert_output_contains "Will reinstall these global npm modules:"
  assert_output_contains "http-server"
  assert_log_contains "npm -g list --depth 0 --parseable"
  assert_log_contains "npm install --global http-server"
}
