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
Usage: check-version-sanity.sh [--root <path>] [--strict]

Checks common Architectury multiloader version-alignment rules:
- gradle.properties exists with required keys
- enabled_platforms includes fabric and neoforge
- no snapshot-only toolchain pins unless you accept warnings
- NeoForge version family matches the Minecraft patch line
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

PROPS="$ROOT/gradle.properties"
if [[ ! -f "$PROPS" ]]; then
  echo "$FAIL missing gradle.properties" >&2
  exit 1
fi

FAILURES=0
WARNINGS=0

pass() { echo "$PASS $*"; }
warn() { echo "$WARN $*"; WARNINGS=$((WARNINGS + 1)); }
fail() { echo "$FAIL $*"; FAILURES=$((FAILURES + 1)); }

read_prop() {
  local key="$1"
  local value
  value="$(sed -n -E "s/^${key}=//p" "$PROPS" | head -n 1)"
  printf '%s' "$value"
}

MINECRAFT_VERSION="$(read_prop minecraft_version)"
ENABLED_PLATFORMS="$(read_prop enabled_platforms)"
ARCHITECTURY_VERSION="$(read_prop architectury_version)"
FABRIC_LOADER_VERSION="$(read_prop fabric_loader_version)"
FABRIC_API_VERSION="$(read_prop fabric_api_version)"
NEOFORGE_VERSION="$(read_prop neoforge_version)"
LOOM_VERSION="$(read_prop loom_version)"

for key in minecraft_version enabled_platforms architectury_version fabric_loader_version fabric_api_version neoforge_version loom_version; do
  value="$(read_prop "$key")"
  if [[ -n "$value" ]]; then
    pass "gradle.properties has $key"
  else
    fail "gradle.properties missing key: $key"
  fi
done

if [[ ",${ENABLED_PLATFORMS}," == *,fabric,* && ",${ENABLED_PLATFORMS}," == *,neoforge,* ]]; then
  pass "enabled_platforms includes fabric and neoforge"
else
  fail "enabled_platforms must include fabric and neoforge"
fi

for version_name in ARCHITECTURY_VERSION FABRIC_LOADER_VERSION NEOFORGE_VERSION LOOM_VERSION; do
  value="${!version_name:-}"
  if [[ "$value" == *SNAPSHOT* ]]; then
    warn "snapshot version detected: ${version_name,,}=$value"
  fi
done

if [[ "$MINECRAFT_VERSION" =~ ^1\.21(\.([0-9]+))?$ ]]; then
  patch="${BASH_REMATCH[2]:-1}"
  expected_prefix="21.${patch}."
  if [[ "$NEOFORGE_VERSION" == "$expected_prefix"* ]]; then
    pass "neoforge_version matches Minecraft patch line ($expected_prefix*)"
  else
    fail "neoforge_version should start with $expected_prefix for minecraft_version=$MINECRAFT_VERSION"
  fi
else
  warn "minecraft_version is outside the documented 1.21.x scope: $MINECRAFT_VERSION"
fi

if [[ -n "$FABRIC_API_VERSION" && "$FABRIC_API_VERSION" == *+1.21.1 ]]; then
  pass "fabric_api_version is on the stable 1.21.x branch"
else
  warn "fabric_api_version is not on the expected 1.21.x branch suffix (+1.21.1)"
fi

echo ""
if [[ "$FAILURES" -gt 0 ]]; then
  echo "$FAIL multiloader version sanity failed with $FAILURES error(s) and $WARNINGS warning(s)"
  exit 1
fi

if [[ "$STRICT" -eq 1 && "$WARNINGS" -gt 0 ]]; then
  echo "$FAIL multiloader version sanity strict mode failed on $WARNINGS warning(s)"
  exit 1
fi

echo "$PASS multiloader version sanity passed with $WARNINGS warning(s)"