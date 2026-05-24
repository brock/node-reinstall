#!/usr/bin/env bats

setup() {
  export SCRIPT="$BATS_TEST_DIRNAME/../node-reinstall"
}

make_stub_dir() {
  export STUB_DIR="$BATS_TEST_TMPDIR/bin"
  export STUB_LOG="$BATS_TEST_TMPDIR/commands.log"
  mkdir -p "$STUB_DIR"
  touch "$STUB_LOG"
  export PATH="$STUB_DIR:$PATH"
}

write_stub() {
  local name="$1"
  shift
  printf "%s\n" "$@" > "$STUB_DIR/$name"
  chmod +x "$STUB_DIR/$name"
}

install_reinstall_stubs() {
  make_stub_dir
  export HOME="$BATS_TEST_TMPDIR/home"
  export PREFIX="$BATS_TEST_TMPDIR/prefix"
  mkdir -p "$HOME" "$PREFIX/bin"

  write_stub sudo \
    '#!/usr/bin/env bash' \
    'printf "sudo %s\n" "$*" >> "$STUB_LOG"' \
    'if [ "$1" = "-v" ]; then exit 0; fi' \
    'exec "$@"'

  write_stub node \
    '#!/usr/bin/env bash' \
    'printf "node %s\n" "$*" >> "$STUB_LOG"' \
    'printf "v18.19.0\n"'

  write_stub npm \
    '#!/usr/bin/env bash' \
    'printf "npm %s\n" "$*" >> "$STUB_LOG"' \
    'if [ "$1" = "-g" ] && [ "$2" = "list" ]; then' \
    '  printf "/tmp/prefix/lib\n/tmp/prefix/lib/npm\n/tmp/prefix/lib/prettier\n/tmp/prefix/lib/typescript\n"' \
    'fi'

  write_stub curl \
    '#!/usr/bin/env bash' \
    'printf "curl %s\n" "$*" >> "$STUB_LOG"' \
    'out=""' \
    'prev=""' \
    'for arg in "$@"; do' \
    '  if [ "$prev" = "-o" ]; then out="$arg"; fi' \
    '  prev="$arg"' \
    'done' \
    'if printf "%s\n" "$*" | grep -q "api.github.com/repos/nvm-sh/nvm/releases/latest"; then' \
    '  printf "{\"tag_name\":\"v0.39.7\"}\n"' \
    'elif [ -n "$out" ] && [ "$out" != "-" ]; then' \
    '  printf "#!/usr/bin/env bash\n" > "$out"' \
    'else' \
    '  printf "#!/usr/bin/env bash\nprintf \"fake installer\\n\"\n"' \
    'fi'

  write_stub nvm \
    '#!/usr/bin/env bash' \
    'printf "nvm %s\n" "$*" >> "$STUB_LOG"'

  write_stub nave \
    '#!/usr/bin/env bash' \
    'printf "nave %s\n" "$*" >> "$STUB_LOG"'
}

@test "script has valid bash syntax" {
  run bash -n "$SCRIPT"

  [ "$status" -eq 0 ]
}

@test "--help prints usage and exits before privileged operations" {
  make_stub_dir
  write_stub sudo \
    '#!/usr/bin/env bash' \
    'echo "sudo should not run for help" >&2' \
    'exit 42'

  run "$SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"--nvm-latest"* ]]
  [[ "$output" != *"sudo should not run"* ]]
}

@test "-v prints the package version" {
  run "$SCRIPT" -v

  [ "$status" -eq 0 ]
  [ "$output" = "0.0.17" ]
}

@test "unknown options fail with usage output before privileged operations" {
  make_stub_dir
  write_stub sudo \
    '#!/usr/bin/env bash' \
    'echo "sudo should not run for invalid options" >&2' \
    'exit 42'

  run "$SCRIPT" --not-a-real-option

  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option"* ]]
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" != *"sudo should not run"* ]]
}

@test "--force --nvm runs the reinstall path against safe stubs" {
  install_reinstall_stubs

  run "$SCRIPT" --force --nvm 20

  [ "$status" -eq 0 ]
  [[ "$output" == *"Found Node.js version v18.19.0 already installed."* ]]
  [[ "$output" == *"Reinstalling your global npm modules:"* ]]
  grep -q "sudo -v" "$STUB_LOG"
  grep -q "curl .*api.github.com/repos/nvm-sh/nvm/releases/latest" "$STUB_LOG"
  grep -q "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh" "$STUB_LOG"
  grep -q "nvm install 20" "$STUB_LOG"
  grep -q "nvm alias default 20" "$STUB_LOG"
  grep -q "npm install --global" "$STUB_LOG"
  grep -q "prettier" "$STUB_LOG"
  grep -q "typescript" "$STUB_LOG"
}

@test "--force --nave runs the nave reinstall path against safe stubs" {
  install_reinstall_stubs

  run "$SCRIPT" --force --nave 16

  [ "$status" -eq 0 ]
  grep -q "sudo rm -rf $HOME/.nave" "$STUB_LOG"
  grep -q "curl -sL https://raw.githubusercontent.com/isaacs/nave/master/nave.sh -o $PREFIX/bin/nave" "$STUB_LOG"
  grep -q "nave usemain 16" "$STUB_LOG"
}
