# Sourced only in the env -i installer child. No command may fall back to the
# developer's PATH. Record missing commands even if the installer masks failure.
command_not_found_handle() {
  printf 'unknown command: %q\n' "$1" >> "$TEST_VIOLATIONS"
  printf 'Unexpected installer command: %s\n' "$1" >&2
  return 97
}
