#!/usr/bin/env bats

setup() {
  export REPO_ROOT="$BATS_TEST_DIRNAME/.."
  export TEST_TMPDIR="$BATS_TEST_TMPDIR"
}

make_stub_bin() {
  local dir="$1"
  mkdir -p "$dir"

  cat > "$dir/sudo" <<'EOF'
#!/usr/bin/env bash
echo "sudo $*" >> "$NODE_REINSTALL_TEST_LOG"
exit 0
EOF

  cat > "$dir/node" <<'EOF'
#!/usr/bin/env bash
echo "v18.19.0"
EOF

  cat > "$dir/npm" <<'EOF'
#!/usr/bin/env bash
echo "npm $*" >> "$NODE_REINSTALL_TEST_LOG"
if [[ "$*" == "-g list --depth 0 --parseable" ]]; then
  printf "%s\n" "/usr/local/lib/node_modules/npm"
fi
exit 0
EOF

  cat > "$dir/curl" <<'EOF'
#!/usr/bin/env bash
echo "curl $*" >> "$NODE_REINSTALL_TEST_LOG"
if [[ "$*" == *"releases/latest"* ]]; then
  printf '%s\n' '{"tag_name":"v0.39.7"}'
else
  printf '%s\n' '#!/usr/bin/env bash'
  printf '%s\n' 'exit 0'
fi
EOF

  cat > "$dir/nvm" <<'EOF'
#!/usr/bin/env bash
echo "nvm $*" >> "$NODE_REINSTALL_TEST_LOG"
exit 0
EOF

  chmod +x "$dir/sudo" "$dir/node" "$dir/npm" "$dir/curl" "$dir/nvm"
}

@test "--help prints usage" {
  run "$REPO_ROOT/node-reinstall" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"node-reinstall [--nave|--nvm|--nvm-latest]"* ]]
}

@test "--version prints current version" {
  run "$REPO_ROOT/node-reinstall" --version

  [ "$status" -eq 0 ]
  [ "$output" = "0.0.17" ]
}

@test "unknown option fails and prints usage" {
  run bash -c "\"$REPO_ROOT/node-reinstall\" --wat 2>&1"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option"* ]]
  [[ "$output" == *"Usage:"* ]]
}

@test "--force --nvm runs through reinstall flow with command stubs" {
  local fake_home="$TEST_TMPDIR/home"
  local fake_prefix="$TEST_TMPDIR/prefix"
  local fake_bin="$TEST_TMPDIR/bin"
  local log="$TEST_TMPDIR/commands.log"

  mkdir -p "$fake_home/.nvm" "$fake_home/local" "$fake_prefix/bin"
  make_stub_bin "$fake_bin"

  run env \
    HOME="$fake_home" \
    PREFIX="$fake_prefix" \
    PATH="$fake_bin:/usr/bin:/bin" \
    NODE_REINSTALL_TEST_LOG="$log" \
    "$REPO_ROOT/node-reinstall" --force --nvm 20.11.1

  [ "$status" -eq 0 ]
  [[ "$output" == *"Found Node.js version v18.19.0 already installed."* ]]
  [[ "$output" == *"node-reinstall is done."* ]]
  grep -q "sudo -v" "$log"
  grep -q "curl .*api.github.com/repos/nvm-sh/nvm/releases/latest" "$log"
  grep -q "nvm install 20.11.1" "$log"
  grep -q "nvm alias default 20.11.1" "$log"
}
