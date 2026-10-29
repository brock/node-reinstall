#!/usr/bin/env bats

load helpers

@test "help aliases exit before privilege, detection or cleanup commands" {
  for option in -h --help; do
    run reinstall "$option"
    [ "$status" -eq 0 ]
    [[ "$output" == *'Usage:'* ]]
    [[ "$output" == *'--nave'* ]]
    [ ! -s "$TRACE" ]
  done
}

@test "version aliases report the package version without side effects" {
  local expected
  expected=$(sed -n 's/.*"version": "\([^"]*\)".*/\1/p' "$BATS_TEST_DIRNAME/../package.json")
  [ -n "$expected" ]
  for option in -v --version; do
    run reinstall "$option"
    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ]
    [ ! -s "$TRACE" ]
  done
}

@test "unknown options return an error and usage before doing any work" {
  run reinstall --not-an-option
  [ "$status" -eq 1 ]
  [[ "$output" == *'Unknown option'* ]]
  [[ "$output" == *'Usage:'* ]]
  [ ! -s "$TRACE" ]
}

@test "first install defaults to Node 5 through nvm" {
  run reinstall --force
  [ "$status" -eq 0 ]
  [[ "$output" == *'Installing Node, npm.'* ]]
  assert_called 'nvm install 5'
  assert_called 'nvm alias default 5'
  assert_not_called '^nave '
}

@test "an existing version is reused when no version is requested" {
  INSTALLED_VERSION=v20.11.1
  run reinstall --force
  [ "$status" -eq 0 ]
  assert_called 'nvm install v20.11.1'
  assert_called 'nvm alias default v20.11.1'
}

@test "a requested version takes precedence over the installed version" {
  INSTALLED_VERSION=v20.11.1
  run reinstall --force 22.1.0
  [ "$status" -eq 0 ]
  assert_called 'nvm install 22.1.0'
  assert_called 'nvm alias default 22.1.0'
  assert_not_called '^nvm install v20'
}

@test "nave uses the requested version and its own cleanup path" {
  run reinstall --force --nave 22.1.0
  [ "$status" -eq 0 ]
  assert_called 'nave usemain 22.1.0'
  assert_called "sudo rm -rf $FIXTURE/home/.nave"
  assert_called "curl -sL https://raw.githubusercontent.com/isaacs/nave/master/nave.sh -o $FIXTURE/prefix/bin/nave"
  assert_not_called '^nvm |^sudo rm .*\.nvm$'
}

@test "the last manager option wins when nvm follows nave" {
  run reinstall --force --nave --nvm
  [ "$status" -eq 0 ]
  assert_called 'nvm install 5'
  assert_called "sudo rm -rf $FIXTURE/home/.nvm"
  assert_not_called '^nave |^sudo rm .*\.nave$'
}

@test "the last manager option wins when nave follows nvm" {
  run reinstall --force --nvm --nave
  [ "$status" -eq 0 ]
  assert_called 'nave usemain 5'
  assert_not_called '^nvm '
}

@test "declining replacement of existing Node stops before cleanup" {
  INSTALLED_VERSION=v20.11.1
  run reinstall <<< '2'
  [ "$status" -eq 0 ]
  [[ "$output" == *'Would you like to continue'* ]]
  assert_called 'sudo -v'
  assert_not_called '^rm |^sudo rm |^curl |^nvm |^nave '
}

@test "accepting replacement proceeds with the existing version" {
  INSTALLED_VERSION=v20.11.1
  run reinstall --nave <<< '1'
  [ "$status" -eq 0 ]
  assert_called 'nave usemain v20.11.1'
}

@test "empty global module listing warns and can be declined before cleanup" {
  NPM_PRESENT=1
  run reinstall <<< '2'
  [ "$status" -eq 0 ]
  [[ "$output" == *'did not find any global node modules'* ]]
  assert_called 'npm -g list --depth 0 --parseable'
  assert_not_called '^rm |^sudo rm |^curl |^nvm |^nave '
}

@test "force skips confirmation and does not reinstall an empty module list" {
  INSTALLED_VERSION=v20.11.1
  NPM_PRESENT=1
  run reinstall -f --nave
  [ "$status" -eq 0 ]
  [[ "$output" != *'Would you like to continue'* ]]
  assert_called 'nave usemain v20.11.1'
  assert_not_called '^npm install '
}

@test "populated home directories warn and allow declining the cleanup" {
  mkdir "$FIXTURE/home/local"
  touch "$FIXTURE/home/local/keep-a" "$FIXTURE/home/local/keep-b"
  run reinstall --nave <<< '2'
  [ "$status" -eq 0 ]
  [[ "$output" == *'has files or directories in it'* ]]
  assert_not_called '^rm |^curl |^nave '
  [ -f "$FIXTURE/home/local/keep-a" ]
  [ -f "$FIXTURE/home/local/keep-b" ]
}

@test "cleanup requests use the disposable prefix and never delete fixtures" {
  touch "$FIXTURE/prefix/bin/node" "$FIXTURE/home/.npmrc"
  run reinstall --force --nave
  [ "$status" -eq 0 ]
  assert_called "sudo rm -rf $FIXTURE/prefix/bin/node $FIXTURE/prefix/bin/npm"
  assert_called "sudo rm -rf $FIXTURE/prefix/share/man/man1/node.1"
  [ -f "$FIXTURE/prefix/bin/node" ]
  [ -f "$FIXTURE/home/.npmrc" ]
  [[ "$output" == *'You must restart your terminal for changes to take effect.'* ]]
}

@test "restores multiple global modules including scoped names without npm itself" {
  NPM_PRESENT=1
  GLOBAL_MODULES_FIXTURE=1
  run reinstall --force --nave
  [ "$status" -eq 0 ]
  assert_called 'npm install --global typescript @scope/tool'
  [[ "$output" != *'extra operand'* ]]
}
