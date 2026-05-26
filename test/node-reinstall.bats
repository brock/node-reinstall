#!/usr/bin/env bats

setup() {
  TMPROOT="$(mktemp -d)"
  export HOME="$TMPROOT/home"
  export PREFIX="$TMPROOT/prefix"
  export PATH="$TMPROOT/mock-bin:$PATH"
  export LOGDIR="$TMPROOT/logs"

  mkdir -p "$HOME" "$PREFIX/bin" "$TMPROOT/mock-bin" "$LOGDIR"

  cat >"$TMPROOT/mock-bin/sudo" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$TMPROOT/mock-bin/sudo"

  cat >"$TMPROOT/mock-bin/rm" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$TMPROOT/mock-bin/rm"

  cat >"$TMPROOT/mock-bin/node" <<'EOF'
#!/usr/bin/env bash
echo "v18.19.0"
EOF
  chmod +x "$TMPROOT/mock-bin/node"

  cat >"$TMPROOT/mock-bin/which" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "npm" ]]; then
  exit 1
fi
command -v "$1"
EOF
  chmod +x "$TMPROOT/mock-bin/which"

  cat >"$TMPROOT/mock-bin/curl" <<'EOF'
#!/usr/bin/env bash
out=""
for ((i=1; i<=$#; i++)); do
  if [[ "${!i}" == "-o" ]]; then
    j=$((i + 1))
    out="${!j}"
  fi
done

if [[ -n "$out" ]]; then
  cat >"$out" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$out"
  exit 0
fi

echo '{"tag_name":"v0.39.7"}'
EOF
  chmod +x "$TMPROOT/mock-bin/curl"

  cat >"$TMPROOT/mock-bin/nave" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$LOGDIR/nave.log"
exit 0
EOF
  chmod +x "$TMPROOT/mock-bin/nave"
}

teardown() {
  rm -rf "$TMPROOT"
}

@test "help prints usage" {
  run bash ./node-reinstall --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "version prints version" {
  run bash ./node-reinstall --version
  [ "$status" -eq 0 ]
  [ "$output" = "0.0.17" ]
}

@test "force nave path completes with mocked externals" {
  run bash ./node-reinstall --force --nave 18.19.0
  [ "$status" -eq 0 ]
  [[ "$output" == *"node-reinstall is done."* ]]
  [ -f "$LOGDIR/nave.log" ]
  grep -q 'usemain v18.19.0' "$LOGDIR/nave.log"
}
