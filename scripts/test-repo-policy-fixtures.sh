#!/usr/bin/env bash
set -euo pipefail

PASS='[PASS]'
FAIL='[FAIL]'

expect_pass() {
  local name="$1"
  shift
  if "$@"; then
    echo "$PASS $name"
  else
    echo "$FAIL $name (expected pass)" >&2
    exit 1
  fi
}

expect_fail_contains() {
  local name="$1"
  local pattern="$2"
  shift
  shift

  local output_file
  output_file="$(mktemp)"
  if "$@" >"$output_file" 2>&1; then
    cat "$output_file"
    rm -f "$output_file"
    echo "$FAIL $name (expected failure)" >&2
    exit 1
  elif grep -Fq "$pattern" "$output_file"; then
    cat "$output_file"
    rm -f "$output_file"
    echo "$PASS $name"
  else
    cat "$output_file"
    rm -f "$output_file"
    echo "$FAIL $name (missing expected output: $pattern)" >&2
    exit 1
  fi
}

echo "=== Running Repo Policy Fixtures ==="

expect_pass "workflow pins valid" \
  node ./scripts/check-workflow-action-pins.mjs \
  --root tests/fixtures/workflow-pins/valid
expect_fail_contains "workflow pins invalid missing ref" "action reference is missing a ref: actions/checkout" \
  node ./scripts/check-workflow-action-pins.mjs \
  --root tests/fixtures/workflow-pins/invalid
expect_fail_contains "workflow pins invalid" "third-party action must be pinned to a full commit SHA" \
  node ./scripts/check-workflow-action-pins.mjs \
  --root tests/fixtures/workflow-pins/invalid

echo "$PASS repo policy fixture checks completed"
