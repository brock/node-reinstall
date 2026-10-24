#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
checker="${BATS:-bats}"
if ! command -v "$checker" >/dev/null 2>&1; then
  printf 'Bats is required. See test/README.md; set BATS=/path/to/bats.\n' >&2
  exit 1
fi
for utility in timeout env grep sed basename ls wc xargs; do
  command -v "$utility" >/dev/null || exit 1
done
# Keep Bats-created temporary files under this checkout, not a caller's home.
mkdir -p .test-tmp
export TMPDIR="$PWD/.test-tmp"
export BATS_TEST_TIMEOUT=15 BATS_TEST_RETRIES=0
exec "$checker" --tap test/node-reinstall.bats
