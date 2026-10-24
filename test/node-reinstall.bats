#!/usr/bin/env bats
load helper

@test "both help flags exit before any system command" {
  for option in -h --help; do
    run_installer "$option"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *'Usage:'* && "$output" == *'--nave'* ]]
    [[ ! -s "$TEST_LOG" ]]
  done
}

@test "both version flags report the script version without installer calls" {
  for option in -v --version; do
    run_installer "$option"
    [[ "$status" -eq 0 && "$output" == 0.0.17 ]]
    [[ ! -s "$TEST_LOG" ]]
  done
}

@test "unknown option reports failure and usage without side effects" {
  run_installer --not-an-option
  [[ "$status" -eq 1 && "$output" == *'Unknown option'* && "$output" == *'Usage:'* ]]
  [[ ! -s "$TEST_LOG" ]]
}

@test "first installation defaults to Node 5 and NVM sequencing" {
  run_installer --force
  assert_simulated_completion
  assert_call sudo -v
  assert_call nvm install 5
  assert_call nvm alias default 5
  assert_call bash 'consumed inert marker; no execution'
  refute_command nave
  refute_command npm
}

@test "Nave retains an installed Node version with force" {
  TEST_NODE_VERSION=v20.19.0
  run_installer --nave --force
  assert_simulated_completion
  assert_call nave usemain v20.19.0
  [[ "$output" != *'Would you like to continue'* ]]
  refute_command nvm
}

@test "explicit version overrides the installed version" {
  TEST_NODE_VERSION=v18.20.0
  run_installer --nave -f 22.14.0
  assert_simulated_completion
  assert_call nave usemain 22.14.0
  [[ "$output" == *'replace it with Node.js version 22.14.0'* ]]
}

@test "last explicit version wins" {
  run_installer --nave -f 18 20
  assert_simulated_completion
  assert_call nave usemain 20
}

@test "last manager option selects Nave" {
  run_installer --nvm --nave -f 20
  assert_simulated_completion
  assert_call sudo rm -rf "$TEST_HOME/.nave"
  assert_call curl -sL https://raw.githubusercontent.com/isaacs/nave/master/nave.sh -o "$TEST_PREFIX/bin/nave"
  assert_call nave usemain 20
  refute_command nvm
}

@test "last manager option selects NVM" {
  run_installer --nave --nvm -f 20
  assert_simulated_completion
  assert_call sudo rm -rf "$TEST_HOME/.nvm"
  assert_call nvm install 20
  assert_call nvm alias default 20
  refute_command nave
}

@test "declining replacement stops before deletion and download requests" {
  TEST_NODE_VERSION=v20.19.0
  run_installer --nave <<< '2'
  [[ "$status" -eq 0 && "$output" == *'Would you like to continue'* ]]
  assert_call sudo -v
  refute_command rm
  refute_command curl
  refute_command which
  [[ "$(wc -l < "$TEST_LOG")" -eq 2 ]]
}

@test "accepting replacement allows the requested simulated installation" {
  TEST_NODE_VERSION=v20.19.0
  run_installer --nave 22 <<< '1'
  assert_simulated_completion
  assert_call nave usemain 22
}

@test "empty global module list warns and can be declined before deletion" {
  TEST_HAS_NPM=1
  run_installer --nave <<< '2'
  [[ "$status" -eq 0 && "$output" == *'did not find any global node modules'* ]]
  assert_call npm -g list --depth 0 --parseable
  refute_command rm
  refute_command curl
  [[ "$(grep -c '^sudo ' "$TEST_LOG")" -eq 1 ]]
}

@test "force bypasses the empty module confirmation without npm install" {
  TEST_HAS_NPM=1
  run_installer --nave --force
  assert_simulated_completion
  [[ "$output" == *'did not find any global node modules'* ]]
  [[ "$output" != *'Would you like to continue'* ]]
  [[ "$(grep -c '^npm ' "$TEST_LOG")" -eq 1 ]]
}

@test "populated home directory prompts before home cleanup and can be declined" {
  mkdir -p "$TEST_HOME/local"
  printf one > "$TEST_HOME/local/one"
  printf two > "$TEST_HOME/local/two"
  run_installer --nave <<< '2'
  [[ "$status" -eq 0 && "$output" == *'has files or directories in it'* ]]
  refute_command rm
  refute_command curl
  [[ -f "$TEST_HOME/local/one" && -f "$TEST_HOME/local/two" ]]
}

@test "cleanup targets are recorded under disposable home and prefix only" {
  run_installer --nave -f
  assert_simulated_completion
  assert_call rm -rf "$TEST_HOME/local" "$TEST_HOME/lib" "$TEST_HOME/include" "$TEST_HOME/node*" "$TEST_HOME/npm" "$TEST_HOME/.npm*" "$TEST_HOME/.node-gyp"
  assert_call sudo rm -rf "$TEST_PREFIX/lib/node*"
  assert_call sudo rm -rf "$TEST_PREFIX/include/node*"
  assert_call sudo rm -rf "$TEST_PREFIX/bin/node" "$TEST_PREFIX/bin/npm"
  assert_call sudo rm -rf "$TEST_PREFIX/share/doc/node"
  assert_call sudo rm -rf "$TEST_PREFIX/share/man/man1/node.1"
  assert_call sudo rm -rf "$TEST_PREFIX/share/systemtap/tapset/node.stp"
  assert_call sudo rm -rf "$TEST_PREFIX/lib/dtrace/node.d"
}

@test "removal guard rejects an outside path without deleting it" {
  run_stub rm -rf "$TEST_ROOT/outside"
  assert_guard_rejection
  [[ -f "$TEST_ROOT/outside" && ! -s "$TEST_LOG" ]]
}

@test "sudo guard cannot execute arbitrary commands" {
  run_stub sudo sh -c 'printf unexpected'
  assert_guard_rejection
  [[ ! -s "$TEST_LOG" ]]
}

@test "network guard rejects an unlisted URL" {
  run_stub curl https://example.invalid/unexpected
  assert_guard_rejection
}

@test "pipeline guard rejects executable text without evaluating it" {
  run_stub bash <<< "printf bad > '$TEST_ROOT/payload-ran'"
  assert_guard_rejection
  [[ ! -e "$TEST_ROOT/payload-ran" && ! -s "$TEST_LOG" ]]
}

@test "make test fails clearly when Bats is unavailable" {
  run make -C "$REPO_ROOT" test BATS="$TEST_ROOT/missing-bats"
  [[ "$status" -ne 0 && "$output" == *'Bats is required'* ]]
  [[ ! -s "$TEST_LOG" ]]
}
