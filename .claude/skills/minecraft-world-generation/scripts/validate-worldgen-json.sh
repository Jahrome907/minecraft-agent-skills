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
Usage: validate-worldgen-json.sh [--root <path>] [--strict]

Checks worldgen JSON integrity:
- validates JSON under data/**/worldgen and data/**/neoforge/biome_modifier
- validates key directory conventions
- validates local cross-references:
  placed_feature -> configured_feature
  structure_set -> structure
  biome and biome_modifier feature references -> placed_feature
USAGE
      exit 0
      ;;
    *)
      echo "$FAIL unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "$FAIL jq is required"
  exit 1
fi

if [[ ! -d "$ROOT" ]]; then
  echo "$FAIL root path does not exist: $ROOT"
  exit 1
fi

FAILURES=0
WARNINGS=0

pass() { echo "$PASS $*"; }
warn() { echo "$WARN $*"; WARNINGS=$((WARNINGS + 1)); }
fail() { echo "$FAIL $*"; FAILURES=$((FAILURES + 1)); }

declare -A CONFIGURED_FEATURES=()
declare -A PLACED_FEATURES=()
declare -A STRUCTURES=()

to_id() {
  local file="$1"
  local rel ns path noext
  rel="${file#"$ROOT/data/"}"
  ns="${rel%%/*}"
  path="${rel#*/}"
  path="${path#worldgen/}"
  noext="${path%.json}"
  echo "$ns:${noext#*/}"
}

in_local_namespace() {
  local ref="$1"
  [[ "$ref" == *:* ]]
}

split_ref() {
  local default_ns="$1"
  local ref="$2"
  if [[ "$ref" == *:* ]]; then
    echo "$ref"
  else
    echo "$default_ns:$ref"
  fi
}

check_json() {
  local file="$1"
  if jq empty "$file" >/dev/null 2>&1; then
    pass "valid JSON: ${file#$ROOT/}"
  else
    fail "invalid JSON: ${file#$ROOT/}"
  fi
}

echo "=== Worldgen Validator ==="

while IFS= read -r -d '' f; do
  check_json "$f"
  id="$(to_id "$f")"
  CONFIGURED_FEATURES["$id"]=1
done < <(find "$ROOT/data" -type f -path '*/worldgen/configured_feature/*.json' -print0 2>/dev/null)

while IFS= read -r -d '' f; do
  check_json "$f"
  id="$(to_id "$f")"
  PLACED_FEATURES["$id"]=1
done < <(find "$ROOT/data" -type f -path '*/worldgen/placed_feature/*.json' -print0 2>/dev/null)

while IFS= read -r -d '' f; do
  check_json "$f"
  id="$(to_id "$f")"
  STRUCTURES["$id"]=1
done < <(find "$ROOT/data" -type f -path '*/worldgen/structure/*.json' -print0 2>/dev/null)

while IFS= read -r -d '' f; do
  check_json "$f"
done < <(find "$ROOT/data" -type f -path '*/neoforge/biome_modifier/*.json' -print0 2>/dev/null)

while IFS= read -r -d '' f; do
  check_json "$f"
done < <(find "$ROOT/data" -type f -path '*/worldgen/biome/*.json' -print0 2>/dev/null)

if [[ ${#PLACED_FEATURES[@]} -eq 0 ]]; then
  warn "no placed_feature JSON files found"
fi

if [[ ${#CONFIGURED_FEATURES[@]} -eq 0 ]]; then
  warn "no configured_feature JSON files found"
fi

echo "Checking placed_feature -> configured_feature references..."
while IFS= read -r -d '' pf_file; do
  rel="${pf_file#"$ROOT/data/"}"
  ns="${rel%%/*}"
  feature_ref="$(jq -r '.feature? // empty' "$pf_file")"

  if [[ -z "$feature_ref" ]]; then
    fail "placed_feature missing .feature: ${pf_file#$ROOT/}"
    continue
  fi

  if [[ "$feature_ref" == \#* ]]; then
    warn "tag reference not resolved in placed_feature: ${pf_file#$ROOT/} -> $feature_ref"
    continue
  fi

  feature_id="$(split_ref "$ns" "$feature_ref")"
  if [[ -n "${CONFIGURED_FEATURES[$feature_id]:-}" ]]; then
    pass "placed_feature target exists: $feature_id"
  else
    fail "placed_feature references missing configured_feature: $feature_id"
  fi
done < <(find "$ROOT/data" -type f -path '*/worldgen/placed_feature/*.json' -print0 2>/dev/null)

echo "Checking structure_set -> structure references..."
while IFS= read -r -d '' ss_file; do
  rel="${ss_file#"$ROOT/data/"}"
  ns="${rel%%/*}"
  while IFS= read -r sref; do
    [[ -z "$sref" ]] && continue
    sid="$(split_ref "$ns" "$sref")"
    if [[ -n "${STRUCTURES[$sid]:-}" ]]; then
      pass "structure_set target exists: $sid"
    else
      fail "structure_set references missing structure: $sid"
    fi
  done < <(jq -r '.structures[]?.structure? // empty' "$ss_file")
done < <(find "$ROOT/data" -type f -path '*/worldgen/structure_set/*.json' -print0 2>/dev/null)

echo "Checking biome feature references..."
while IFS= read -r -d '' biome_file; do
  rel="${biome_file#"$ROOT/data/"}"
  ns="${rel%%/*}"
  while IFS= read -r fref; do
    [[ -z "$fref" ]] && continue
    if [[ "$fref" == \#* ]]; then
      warn "tag reference not resolved in biome file: ${biome_file#$ROOT/} -> $fref"
      continue
    fi

    fid="$(split_ref "$ns" "$fref")"
    if [[ -n "${PLACED_FEATURES[$fid]:-}" ]]; then
      pass "biome feature target exists: $fid"
    else
      fail "biome references missing placed_feature: $fid"
    fi
  done < <(jq -r '.features[][]? // empty' "$biome_file")
done < <(find "$ROOT/data" -type f -path '*/worldgen/biome/*.json' -print0 2>/dev/null)

echo "Checking biome_modifier feature/structure references..."
while IFS= read -r -d '' mod_file; do
  rel="${mod_file#"$ROOT/data/"}"
  ns="${rel%%/*}"

  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    if [[ "$ref" == \#* ]]; then
      warn "tag reference not resolved in biome_modifier: ${mod_file#$ROOT/} -> $ref"
      continue
    fi

    rid="$(split_ref "$ns" "$ref")"
    if [[ -n "${PLACED_FEATURES[$rid]:-}" ]]; then
      pass "biome_modifier feature target exists: $rid"
    else
      fail "biome_modifier references missing placed_feature: $rid"
    fi
  done < <(jq -r '(.features? // empty), (.features[]? // empty)' "$mod_file")

  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    rid="$(split_ref "$ns" "$ref")"
    if [[ -n "${STRUCTURES[$rid]:-}" ]]; then
      pass "biome_modifier structure target exists: $rid"
    else
      fail "biome_modifier references missing structure: $rid"
    fi
  done < <(jq -r '(.structures? // empty), (.structures[]? // empty)' "$mod_file")
done < <(find "$ROOT/data" -type f -path '*/neoforge/biome_modifier/*.json' -print0 2>/dev/null)

echo ""
if [[ "$FAILURES" -gt 0 ]]; then
  echo "$FAIL worldgen validation failed with $FAILURES error(s) and $WARNINGS warning(s)"
  exit 1
fi

if [[ "$STRICT" -eq 1 && "$WARNINGS" -gt 0 ]]; then
  echo "$FAIL worldgen validation strict mode failed on $WARNINGS warning(s)"
  exit 1
fi

echo "$PASS worldgen validation passed with $WARNINGS warning(s)"
