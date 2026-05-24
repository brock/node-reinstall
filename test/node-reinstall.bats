#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO_ROOT/node-reinstall"
}

@test "help flag prints usage without running reinstall steps" {
  run "$SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"--nvm-latest"* ]]
}

@test "version flag prints the script version" {
  expected="$(grep '^VERSION=' "$SCRIPT" | sed -E 's/VERSION="([^"]+)"/\1/')"

  run "$SCRIPT" --version

  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}

@test "unknown flags fail before destructive reinstall steps" {
  run "$SCRIPT" --does-not-exist

  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option"* ]]
}
