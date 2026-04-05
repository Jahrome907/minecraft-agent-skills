#!/usr/bin/env bash
set -euo pipefail

PASS='[PASS]'
WARN='[WARN]'
FAIL='[FAIL]'

ROOT='.'
STRICT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    --help|-h)
      cat <<'USAGE'
Usage: validate-test-layout.sh [--root <path>] [--strict]

Checks common 1.21.x testing layout expectations:
- build.gradle(.kts) exists
- src/test/java or src/test/kotlin exists
- test task enables JUnit Platform
- MockBukkit tests have the MockBukkit dependency
- GameTests have committed structure fixtures
USAGE
      exit 0
      ;;
    *)
      echo "$FAIL unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "$ROOT" ]]; then
  echo "$FAIL root path does not exist: $ROOT" >&2
  exit 1
fi

FAILURES=0
WARNINGS=0

pass() { echo "$PASS $*"; }
warn() { echo "$WARN $*"; WARNINGS=$((WARNINGS + 1)); }
fail() { echo "$FAIL $*"; FAILURES=$((FAILURES + 1)); }

BUILD_FILE=''
if [[ -f "$ROOT/build.gradle.kts" ]]; then
  BUILD_FILE="$ROOT/build.gradle.kts"
elif [[ -f "$ROOT/build.gradle" ]]; then
  BUILD_FILE="$ROOT/build.gradle"
else
  fail "missing build.gradle or build.gradle.kts"
fi

TEST_ROOT=''
if [[ -d "$ROOT/src/test/java" ]]; then
  TEST_ROOT="$ROOT/src/test/java"
elif [[ -d "$ROOT/src/test/kotlin" ]]; then
  TEST_ROOT="$ROOT/src/test/kotlin"
else
  fail "missing src/test/java or src/test/kotlin"
fi

if [[ -n "$BUILD_FILE" ]]; then
  pass "found build file: ${BUILD_FILE#$ROOT/}"
fi

if [[ -n "$TEST_ROOT" ]]; then
  pass "found test source root: ${TEST_ROOT#$ROOT/}"
fi

if [[ -n "$BUILD_FILE" ]]; then
  if grep -Eq 'useJUnitPlatform' "$BUILD_FILE"; then
    pass "test task enables JUnit Platform"
  else
    fail "test task missing useJUnitPlatform()"
  fi
fi

HAS_MOCKBUKKIT_TESTS=0
if [[ -n "$TEST_ROOT" ]] && grep -R -E -q 'MockBukkit|ServerMock|PlayerMock' "$TEST_ROOT"; then
  HAS_MOCKBUKKIT_TESTS=1
  pass "MockBukkit-style tests detected"
fi

if [[ "$HAS_MOCKBUKKIT_TESTS" -eq 1 && -n "$BUILD_FILE" ]]; then
  if grep -Eq 'MockBukkit' "$BUILD_FILE"; then
    pass "build file declares MockBukkit dependency"
  else
    fail "MockBukkit tests detected but build file is missing MockBukkit dependency"
  fi
fi

HAS_GAMETESTS=0
if [[ -n "$TEST_ROOT" ]] && grep -R -E -q '@GameTest|FabricGameTest|GameTestHelper' "$TEST_ROOT"; then
  HAS_GAMETESTS=1
  pass "GameTest-style tests detected"
fi

if [[ "$HAS_GAMETESTS" -eq 1 ]]; then
  STRUCTURE_ROOTS=()
  if [[ -d "$ROOT/src/test/resources" ]]; then
    STRUCTURE_ROOTS+=("$ROOT/src/test/resources")
  fi
  if [[ -d "$ROOT/src/main/resources" ]]; then
    STRUCTURE_ROOTS+=("$ROOT/src/main/resources")
  fi

  if [[ "${#STRUCTURE_ROOTS[@]}" -gt 0 ]] && find "${STRUCTURE_ROOTS[@]}" -type f -path '*/data/*/structures/*.nbt' 2>/dev/null | grep -q .; then
    pass "GameTest structure fixtures found"
  else
    fail "GameTest tests detected but no committed data/*/structures/*.nbt fixtures were found"
  fi
fi

if [[ "$HAS_MOCKBUKKIT_TESTS" -eq 0 && "$HAS_GAMETESTS" -eq 0 ]]; then
  warn "no MockBukkit or GameTest fixtures detected; layout only covers plain unit tests"
fi

echo ""
if [[ "$FAILURES" -gt 0 ]]; then
  echo "$FAIL testing layout validation failed with $FAILURES error(s) and $WARNINGS warning(s)"
  exit 1
fi

if [[ "$STRICT" -eq 1 && "$WARNINGS" -gt 0 ]]; then
  echo "$FAIL testing layout validation strict mode failed on $WARNINGS warning(s)"
  exit 1
fi

echo "$PASS testing layout validation passed with $WARNINGS warning(s)"