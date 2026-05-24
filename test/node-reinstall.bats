#!/usr/bin/env bats

setup() {
  export SCRIPT="$BATS_TEST_DIRNAME/../node-reinstall"
}

make_stub_dir() {
  export MOCK_BIN="$BATS_TEST_TMPDIR/bin"
  export COMMAND_LOG="$BATS_TEST_TMPDIR/commands.log"
  mkdir -p "$MOCK_BIN"
  : > "$COMMAND_LOG"
  export PATH="$MOCK_BIN:$PATH"
}

write_stub() {
  local name="$1"
  shift

  printf "%s\n" "$@" > "$MOCK_BIN/$name"
  chmod +x "$MOCK_BIN/$name"
}

install_safe_stubs() {
  make_stub_dir
  export HOME="$BATS_TEST_TMPDIR/home"
  export PREFIX="$BATS_TEST_TMPDIR/prefix"
  mkdir -p "$HOME" "$PREFIX/bin"

  write_stub sudo \
    '#!/usr/bin/env bash' \
    'printf "sudo %s\n" "$*" >> "$COMMAND_LOG"' \
    'exit 0'

  write_stub rm \
    '#!/usr/bin/env bash' \
    'printf "rm %s\n" "$*" >> "$COMMAND_LOG"' \
    'exit 0'

  write_stub which \
    '#!/usr/bin/env bash' \
    'case "$1" in' \
    '  npm)' \
    '    if [ "${MOCK_NPM_PRESENT:-1}" = "1" ]; then' \
    '      printf "%s/npm\n" "$MOCK_BIN"' \
    '      exit 0' \
    '    fi' \
    '    exit 1' \
    '    ;;' \
    '  *) command -v "$1" ;;' \
    'esac'

  write_stub node \
    '#!/usr/bin/env bash' \
    'printf "node %s\n" "$*" >> "$COMMAND_LOG"' \
    'if [ "$1" = "--version" ] && [ -n "${MOCK_NODE_VERSION:-}" ]; then' \
    '  printf "%s\n" "$MOCK_NODE_VERSION"' \
    '  exit 0' \
    'fi' \
    'exit 1'

  write_stub npm \
    '#!/usr/bin/env bash' \
    'printf "npm %s\n" "$*" >> "$COMMAND_LOG"' \
    'if [ "$*" = "-g list --depth 0 --parseable" ]; then' \
    '  if [ -n "${MOCK_GLOBAL_MODULES:-}" ]; then' \
    '    printf "%s\n" "$MOCK_GLOBAL_MODULES"' \
    '  fi' \
    'fi' \
    'exit 0'

  write_stub curl \
    '#!/usr/bin/env bash' \
    'printf "curl %s\n" "$*" >> "$COMMAND_LOG"' \
    'case "$*" in' \
    '  *api.github.com/repos/nvm-sh/nvm/releases/latest*)' \
    '    printf "%s\n" "{\"tag_name\":\"v0.39.7\"}"' \
    '    ;;' \
    '  *raw.githubusercontent.com/nvm-sh/nvm/*/install.sh*)' \
    '    printf "%s\n" "#!/usr/bin/env bash" "exit 0"' \
    '    ;;' \
    '  *raw.githubusercontent.com/isaacs/nave/master/nave.sh*)' \
    '    printf "%s\n" "#!/usr/bin/env bash" "exit 0"' \
    '    ;;' \
    'esac' \
    'exit 0'

  write_stub nvm \
    '#!/usr/bin/env bash' \
    'printf "nvm %s\n" "$*" >> "$COMMAND_LOG"' \
    'exit 0'

  write_stub nave \
    '#!/usr/bin/env bash' \
    'printf "nave %s\n" "$*" >> "$COMMAND_LOG"' \
    'exit 0'
}

assert_output_contains() {
  case "$output" in
    *"$1"*) return 0 ;;
    *)
      printf "Expected output to contain: %s\nActual output:\n%s\n" "$1" "$output"
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

@test "script has valid bash syntax" {
  run bash -n "$SCRIPT"

  [ "$status" -eq 0 ]
}

@test "--help prints usage before privileged operations" {
  make_stub_dir
  write_stub sudo \
    '#!/usr/bin/env bash' \
    'echo "sudo should not run for help" >&2' \
    'exit 42'

  run "$SCRIPT" --help

  [ "$status" -eq 0 ]
  assert_output_contains "Usage:"
  assert_output_contains "node-reinstall [--nave|--nvm|--nvm-latest]"
  assert_output_contains "--force"
  assert_log_not_contains "sudo"
}

@test "--version prints the script version before privileged operations" {
  make_stub_dir
  write_stub sudo \
    '#!/usr/bin/env bash' \
    'echo "sudo should not run for version" >&2' \
    'exit 42'

  run "$SCRIPT" --version

  [ "$status" -eq 0 ]
  [ "$output" = "0.0.17" ]
  assert_log_not_contains "sudo"
}

@test "unknown options fail before destructive commands run" {
  make_stub_dir
  write_stub sudo \
    '#!/usr/bin/env bash' \
    'echo "sudo should not run for invalid options" >&2' \
    'exit 42'

  run "$SCRIPT" --not-a-real-option

  [ "$status" -eq 1 ]
  assert_output_contains "Unknown option"
  assert_output_contains "Usage:"
  assert_log_not_contains "sudo"
}

@test "first-time nvm install uses the requested Node version" {
  install_safe_stubs
  export MOCK_NPM_PRESENT=0

  run "$SCRIPT" --force --nvm 20

  [ "$status" -eq 0 ]
  assert_output_contains "Installing Node, npm."
  assert_output_contains "node-reinstall is done."
  assert_log_contains "sudo -v"
  assert_log_contains "sudo rm -rf $HOME/.nvm"
  assert_log_contains "rm -rf $HOME/local $HOME/lib $HOME/include $HOME/node* $HOME/npm $HOME/.npm* $HOME/.node-gyp"
  assert_log_contains "curl -H Accept: application/vnd.github.v3+json https://api.github.com/repos/nvm-sh/nvm/releases/latest"
  assert_log_contains "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh"
  assert_log_contains "nvm install 20"
  assert_log_contains "nvm alias default 20"
}

@test "existing Node version is reused when no version is requested" {
  install_safe_stubs
  export MOCK_NPM_PRESENT=0
  export MOCK_NODE_VERSION="v18.19.0"

  run "$SCRIPT" --force --nvm

  [ "$status" -eq 0 ]
  assert_output_contains "Found Node.js version v18.19.0 already installed."
  assert_log_contains "nvm install v18.19.0"
  assert_log_contains "nvm alias default v18.19.0"
}

@test "--nave switches to nave cleanup and install commands" {
  install_safe_stubs
  export MOCK_NPM_PRESENT=0

  run "$SCRIPT" --force --nave 18.17.1

  [ "$status" -eq 0 ]
  assert_log_contains "sudo rm -rf $HOME/.nave"
  assert_log_contains "curl -sL https://raw.githubusercontent.com/isaacs/nave/master/nave.sh -o $PREFIX/bin/nave"
  assert_log_contains "nave usemain 18.17.1"
  assert_log_not_contains "nvm install"
}

@test "--nvm-latest installs from master without querying latest release" {
  install_safe_stubs
  export MOCK_NPM_PRESENT=0

  run "$SCRIPT" --force --nvm-latest 20

  [ "$status" -eq 0 ]
  assert_log_contains "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh"
  assert_log_not_contains "api.github.com/repos/nvm-sh/nvm/releases/latest"
  assert_log_contains "nvm install 20"
  assert_log_contains "nvm alias default 20"
}

@test "global npm modules are captured and reinstalled in force mode" {
  install_safe_stubs
  export MOCK_NPM_PRESENT=1
  export MOCK_NODE_VERSION="v16.13.0"
  export MOCK_GLOBAL_MODULES="/usr/local/lib
/usr/local/lib/node_modules/npm
/usr/local/lib/node_modules/http-server
/usr/local/lib/node_modules/pm2"

  run "$SCRIPT" --force --nvm

  [ "$status" -eq 0 ]
  assert_output_contains "Will reinstall these global npm modules:"
  assert_output_contains "http-server"
  assert_output_contains "pm2"
  assert_log_contains "npm -g list --depth 0 --parseable"
  assert_log_contains "npm install --global http-server pm2"
}
