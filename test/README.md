# Tests

The suite uses [Bats-core](https://github.com/bats-core/bats-core). On Linux,
with Bash, GNU coreutils, make and Git available:

```sh
git clone --depth 1 --branch v1.14.0 https://github.com/bats-core/bats-core.git .test-tools/bats-core
test "$(git -C .test-tools/bats-core rev-parse HEAD)" = eb7f42f8d608ac693d7a4b67474f6714ea68cfc5
make test BATS="$PWD/.test-tools/bats-core/bin/bats"
```

An existing Bats installation can instead be used with `make test`. No npm
installation or `make install` is needed. The target fails if Bats is missing
or an assertion fails. Bats 1.14.0 is the pinned CI version.

Each test starts the actual `node-reinstall` entry point in a fresh environment.
Its HOME and PREFIX point into the test's temporary directory; its PATH contains
only recording stubs and a small set of real text/listing utilities. The runner
keeps temporary data in `.test-tmp/` and limits each installer process to 10
seconds, with a 15-second Bats test timeout and no retries.

The stubs record sudo/removal requests without executing them, validate their
paths, provide fixed Node/npm responses, and replace all network and manager
commands. The `curl | bash` boundary accepts only an inert marker and never
evaluates shell text. Unknown commands or unrecognized stub arguments fail the
test even when the installer ignores the failing command's exit code. Sentinel
files check that the fixture home, prefix and outside path survive. Guard tests
also exercise rejected deletion, sudo, network and piped-command requests.

The suite covers help/version/error options, version precedence, NVM/Nave
selection, force and interactive confirmation, empty npm module warnings,
populated home warnings, cleanup targets, and missing-test-runner failure.
These are control-flow unit tests with simulated installation dependencies.
They do **not** install Node, download installers, prove a successful reinstall,
or test macOS.

Two existing installer details are outside this basic test setup: the NVM tag
extractor uses `\d` with `grep -E`, and npm's multi-line parseable output is fed
to `xargs basename` in one invocation. The suite retains the real text utilities
instead of replacing their behavior. Its NVM download stub records both the
fixture release URL and the current empty-version URL as inert sequencing
inputs; accepting that input does not mean the URL works. Nonempty global-module
reinstallation and live release resolution are not covered. Production code is
unchanged.

`.travis.yml` supplies the requested Travis setup. GitHub Actions runs the same
suite on Ubuntu after fetching the pinned Bats source. Both CI configurations
run tests in a network namespace with no routes; neither invokes the repository's
install target. Travis must be enabled separately by the repository owner.
The CI guard uses Python 3 and iproute2 to require both route tables to be empty.
Connection probes must return `ENETUNREACH`; IPv6 `EADDRNOTAVAIL` is also accepted
only when the namespace has no IPv6 addresses. Empty and header-only procfs
displays are supported. A timeout or refusal is not proof of isolation.
