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
Usage: validate-datapack.sh [--root <path>] [--strict]

Checks datapack structure and JSON validity:
- pack.mcmeta and data/** JSON parse with jq
- 1.21.x path conventions (loot_table, function, tags/block, tags/item, tags/function)
- load/tick function tag references resolve to existing .mcfunction files
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
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  JQ_SHIM="$SCRIPT_DIR/jq-shim.mjs"
  if command -v node >/dev/null 2>&1 && [[ -f "$JQ_SHIM" ]]; then
    jq() {
      node "$JQ_SHIM" "$@"
    }
  else
    echo "$FAIL jq is required"
    exit 1
  fi
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
strip_cr() { printf '%s' "${1%$'\r'}"; }

check_json() {
  local file="$1"
  if jq empty "$file" >/dev/null 2>&1; then
    pass "valid JSON: ${file#$ROOT/}"
  else
    fail "invalid JSON: ${file#$ROOT/}"
  fi
}

check_pack_metadata() {
  local file="$1"
  local has_pack_format=0
  local has_min_format=0
  local has_max_format=0

  if jq -e '.pack.pack_format | type == "number" and . == floor' "$file" >/dev/null 2>&1; then
    pass "pack.mcmeta uses integer pack.pack_format"
    has_pack_format=1
  fi

  if jq -e '.pack.min_format | ((type == "number" and . == floor) or (type == "array" and length == 2 and all(.[]; type == "number" and . == floor)))' "$file" >/dev/null 2>&1; then
    pass "pack.mcmeta uses valid pack.min_format"
    has_min_format=1
  fi

  if jq -e '.pack.max_format | ((type == "number" and . == floor) or (type == "array" and length == 2 and all(.[]; type == "number" and . == floor)))' "$file" >/dev/null 2>&1; then
    pass "pack.mcmeta uses valid pack.max_format"
    has_max_format=1
  fi

  if [[ "$has_pack_format" -eq 1 ]]; then
    return
  fi

  if [[ "$has_min_format" -eq 1 && "$has_max_format" -eq 1 ]]; then
    return
  fi

  fail "pack.mcmeta must define either integer .pack.pack_format or both .pack.min_format and .pack.max_format as integers or [major, minor] integer arrays"
}

echo "=== Datapack Validator ==="

echo "Checking required root files..."
if [[ -f "$ROOT/pack.mcmeta" ]]; then
  check_json "$ROOT/pack.mcmeta"
  check_pack_metadata "$ROOT/pack.mcmeta"
else
  fail "missing pack.mcmeta"
fi

if [[ ! -d "$ROOT/data" ]]; then
  fail "missing data/ directory"
else
  pass "found data/ directory"
fi

echo "Checking JSON files under data/..."
while IFS= read -r -d '' json_file; do
  check_json "$json_file"
done < <(find "$ROOT/data" -type f -name '*.json' -print0 2>/dev/null)

echo "Checking banned legacy paths..."
while IFS= read -r -d '' bad_path; do
  fail "legacy path detected: ${bad_path#$ROOT/}"
done < <(find "$ROOT/data" -type f \( -path '*/loot_tables/*' -o -path '*/functions/*' -o -path '*/tags/blocks/*' -o -path '*/tags/items/*' -o -path '*/tags/functions/*' \) -print0 2>/dev/null)

resolve_function_ref() {
  local tag_file="$1"
  local ref="$2"
  local required="$3"
  local ancestry="$4"
  local target_ns target_path resolved kind

  if [[ "$ref" == *:* ]]; then
    target_ns="${ref%%:*}"
    target_path="${ref#*:}"
  else
    fail "invalid function id (missing namespace): ${tag_file#$ROOT/} -> $ref"
    return
  fi

  if [[ "$ref" == \#* ]]; then
    target_ns="${target_ns#\#}"
    kind="function tag"
    resolved="$ROOT/data/$target_ns/tags/function/$target_path.json"
  else
    kind="function"
    resolved="$ROOT/data/$target_ns/function/$target_path.mcfunction"
  fi

  if [[ ! -d "$ROOT/data/$target_ns" ]]; then
    warn "external $kind reference not verified: ${tag_file#$ROOT/} -> $ref"
    return
  fi

  if [[ -f "$resolved" ]]; then
    pass "$kind target exists: $ref"
    if [[ "$ref" == \#* ]]; then
      if [[ "$ancestry" == *"|$resolved|"* ]]; then
        fail "cyclic function tag reference: ${tag_file#$ROOT/} -> $ref"
        return
      fi
      check_function_tag "$resolved" "$ancestry|$resolved|"
    fi
  elif [[ "$required" == "false" ]]; then
    pass "optional $kind reference is absent: $ref"
  else
    fail "missing $kind for tag reference: $ref (expected ${resolved#$ROOT/})"
  fi
}

check_function_tag() {
  local tag_file="$1"
  local ancestry="$2"
  local required ref

  if ! jq -e '.values | type == "array"' "$tag_file" >/dev/null 2>&1; then
    fail "tag file missing array .values: ${tag_file#$ROOT/}"
    return
  fi

  while IFS=$'\t' read -r required ref; do
    required="$(strip_cr "$required")"
    ref="$(strip_cr "$ref")"
    if [[ "$required" == "invalid" || -z "$ref" ]]; then
      fail "invalid function tag entry: ${tag_file#$ROOT/}"
      continue
    fi
    resolve_function_ref "$tag_file" "$ref" "$required" "$ancestry"
  done < <(jq -r '.values[]? | if type == "string" then "true\t" + . elif type == "object" and (.id | type == "string") and ((.required? // true) | type == "boolean") then ((if .required == false then "false" else "true" end) + "\t" + .id) else "invalid\t" end' "$tag_file")
}

echo "Checking load/tick function tag references..."
while IFS= read -r -d '' tag_file; do
  check_function_tag "$tag_file" "|$tag_file|"
done < <(find "$ROOT/data" -type f \( -path '*/tags/function/load.json' -o -path '*/tags/function/tick.json' \) -print0 2>/dev/null)

echo ""
if [[ "$FAILURES" -gt 0 ]]; then
  echo "$FAIL datapack validation failed with $FAILURES error(s) and $WARNINGS warning(s)"
  exit 1
fi

if [[ "$STRICT" -eq 1 && "$WARNINGS" -gt 0 ]]; then
  echo "$FAIL datapack validation strict mode failed on $WARNINGS warning(s)"
  exit 1
fi

echo "$PASS datapack validation passed with $WARNINGS warning(s)"
