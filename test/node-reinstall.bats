#!/usr/bin/env bats

setup() {
  export SCRIPT="$BATS_TEST_DIRNAME/../node-reinstall"
  export TEST_ROOT="$BATS_TEST_TMPDIR/node-reinstall"
  export HOME="$TEST_ROOT/home"
  export PREFIX="$TEST_ROOT/prefix"
  export STUB_BIN="$TEST_ROOT/bin"
  export STUB_LOG="$TEST_ROOT/commands.log"

  mkdir -p "$HOME" "$PREFIX/bin" "$STUB_BIN"
  export PATH="$STUB_BIN:/usr/bin:/bin:$PREFIX/bin"
}

make_stub() {
  local name="$1"
  local body="$2"

  printf '#!/usr/bin/env bash\n%s\n' "$body" > "$STUB_BIN/$name"
  chmod +x "$STUB_BIN/$name"
}

stub_sudo() {
  make_stub sudo 'echo "sudo $*" >> "$STUB_LOG"; exit 0'
}

stub_curl_for_nvm() {
  make_stub curl '
echo "curl $*" >> "$STUB_LOG"
for arg in "$@"; do
  if [[ "$arg" == "-o" ]]; then
    write_next=1
    continue
  fi
  if [[ -n "${write_next:-}" ]]; then
    printf "%s\n" "#!/usr/bin/env bash" "echo \"nave \$*\" >> \"\$STUB_LOG\"" > "$arg"
    chmod +x "$arg"
    exit 0
  fi
done
case "$*" in
  *releases/latest*) printf "%s\n" "{\"tag_name\":\"v0.40.3\"}" ;;
  *) printf "%s\n" "# nvm install script stub" ;;
esac
'
}

stub_nvm() {
  make_stub nvm 'echo "nvm $*" >> "$STUB_LOG"; exit 0'
}

stub_absent_node() {
  make_stub node 'exit 127'
}

stub_installed_node() {
  make_stub node 'printf "%s\n" "v16.20.2"'
}

stub_npm_with_globals() {
  make_stub npm '
echo "npm $*" >> "$STUB_LOG"
if [[ "$*" == "-g list --depth 0 --parseable" ]]; then
  printf "%s\n" "/usr/local/lib" "/usr/local/lib/npm" "/usr/local/lib/eslint" "/usr/local/lib/prettier"
  exit 0
fi
exit 0
'
}

@test "script has valid bash syntax" {
  run bash -n "$SCRIPT"

  [ "$status" -eq 0 ]
}

@test "--help prints usage and exits before privileged operations" {
  run "$SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"--nvm-latest"* ]]
  [[ "$output" != *"sudo"* ]]
}

@test "-v prints the package version" {
  run "$SCRIPT" -v

  [ "$status" -eq 0 ]
  [ "$output" = "0.0.17" ]
}

@test "unknown options fail with usage output" {
  run "$SCRIPT" --not-a-real-option

  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option"* ]]
  [[ "$output" == *"Usage:"* ]]
}

@test "--force --nvm installs the default version when node and npm are absent" {
  stub_sudo
  stub_curl_for_nvm
  stub_nvm
  stub_absent_node

  run "$SCRIPT" --force --nvm

  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing Node, npm."* ]]
  [[ "$output" == *"node-reinstall is done."* ]]
  grep -q "sudo -v" "$STUB_LOG"
  grep -q "nvm install 5" "$STUB_LOG"
  grep -q "nvm alias default 5" "$STUB_LOG"
}

@test "--force --nave uses the requested node version without prompting" {
  stub_sudo
  stub_curl_for_nvm
  stub_installed_node
  stub_npm_with_globals

  run "$SCRIPT" --force --nave 18.20.4

  [ "$status" -eq 0 ]
  [[ "$output" == *"Found Node.js version v16.20.2 already installed."* ]]
  [[ "$output" == *"Completely reinstalling Node, npm."* ]]
  [[ "$output" == *"Reinstalling your global npm modules:"* ]]
  grep -q "sudo -v" "$STUB_LOG"
  grep -q "curl .*nave.sh.* -o $PREFIX/bin/nave" "$STUB_LOG"
  grep -q "nave usemain 18.20.4" "$STUB_LOG"
  grep -q "npm install --global eslint prettier" "$STUB_LOG"
}
