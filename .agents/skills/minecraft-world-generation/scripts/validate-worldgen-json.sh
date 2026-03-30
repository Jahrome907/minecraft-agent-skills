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
- validates JSON under data/**/worldgen, data/**/dimension, data/**/dimension_type, data/**/tags/worldgen, and data/**/neoforge/biome_modifier
- validates key directory conventions
- validates local cross-references:
  dimension -> dimension_type + noise_settings
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

TOTAL_SUPPORTED_FILES=0

declare -A VALIDATED_JSON_FILES=()
declare -A INVALID_JSON_FILES=()
declare -A CONFIGURED_FEATURES=()
declare -A PLACED_FEATURES=()
declare -A STRUCTURES=()
declare -A DIMENSION_TYPES=()
declare -A NOISE_SETTINGS=()
declare -A VANILLA_DIMENSION_TYPES=(
  ["minecraft:overworld"]=1
  ["minecraft:overworld_caves"]=1
  ["minecraft:the_nether"]=1
  ["minecraft:the_end"]=1
)
declare -A VANILLA_NOISE_SETTINGS=(
  ["minecraft:overworld"]=1
  ["minecraft:large_biomes"]=1
  ["minecraft:amplified"]=1
  ["minecraft:nether"]=1
  ["minecraft:end"]=1
  ["minecraft:caves"]=1
  ["minecraft:floating_islands"]=1
)

DATA_ROOT="$ROOT/data"

BIOME_FILES=0
BIOME_MODIFIER_FILES=0

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
    unset 'INVALID_JSON_FILES[$file]'
    pass "valid JSON: ${file#$ROOT/}"
  else
    INVALID_JSON_FILES["$file"]=1
    fail "invalid JSON: ${file#$ROOT/}"
  fi
}

check_json_once() {
  local file="$1"
  if [[ -n "${VALIDATED_JSON_FILES["$file"]+x}" ]]; then
    return
  fi

  VALIDATED_JSON_FILES["$file"]=1
  check_json "$file"
  TOTAL_SUPPORTED_FILES=$((TOTAL_SUPPORTED_FILES + 1))
}

should_validate_dimension_type_ref() {
  local source_ns="$1"
  local id="$2"
  local target_ns="${id%%:*}"

  if [[ "$target_ns" == "$source_ns" ]]; then
    return 0
  fi

  if [[ "$target_ns" == "minecraft" && -n "${VANILLA_DIMENSION_TYPES[$id]:-}" ]]; then
    return 1
  fi

  [[ -d "$DATA_ROOT/$target_ns/dimension_type" ]]
}

should_validate_noise_settings_ref() {
  local source_ns="$1"
  local id="$2"
  local target_ns="${id%%:*}"

  if [[ "$target_ns" == "$source_ns" ]]; then
    return 0
  fi

  if [[ "$target_ns" == "minecraft" && -n "${VANILLA_NOISE_SETTINGS[$id]:-}" ]]; then
    return 1
  fi

  [[ -d "$DATA_ROOT/$target_ns/worldgen/noise_settings" ]]
}

find_worldgen_jsons() {
  local category="${1:-}"
  while IFS= read -r -d '' worldgen_dir; do
    if [[ -n "$category" ]]; then
      [[ -d "$worldgen_dir/$category" ]] || continue
      find "$worldgen_dir/$category" -mindepth 1 -type f -name '*.json' -print0 2>/dev/null
    else
      find "$worldgen_dir" -mindepth 2 -type f -name '*.json' -print0 2>/dev/null
    fi
  done < <(find "$DATA_ROOT" -mindepth 2 -maxdepth 2 -type d -name worldgen -print0 2>/dev/null)
}

find_namespace_jsons() {
  local dir_name="$1"
  while IFS= read -r -d '' dir; do
    find "$dir" -mindepth 1 -type f -name '*.json' -print0 2>/dev/null
  done < <(find "$DATA_ROOT" -mindepth 2 -maxdepth 2 -type d -name "$dir_name" -print0 2>/dev/null)
}

find_neoforge_jsons() {
  local dir_name="$1"
  while IFS= read -r -d '' dir; do
    find "$dir" -mindepth 1 -type f -name '*.json' -print0 2>/dev/null
  done < <(find "$DATA_ROOT" -mindepth 3 -maxdepth 3 -type d -path "$DATA_ROOT/*/neoforge/$dir_name" -print0 2>/dev/null)
}

find_tags_worldgen_jsons() {
  while IFS= read -r -d '' dir; do
    find "$dir" -mindepth 2 -type f -name '*.json' -print0 2>/dev/null
  done < <(find "$DATA_ROOT" -mindepth 3 -maxdepth 3 -type d -path "$DATA_ROOT/*/tags/worldgen" -print0 2>/dev/null)
}

find_invalid_tags_worldgen_jsons() {
  while IFS= read -r -d '' dir; do
    find "$dir" -mindepth 1 -maxdepth 1 -type f -name '*.json' -print0 2>/dev/null
  done < <(find "$DATA_ROOT" -mindepth 3 -maxdepth 3 -type d -path "$DATA_ROOT/*/tags/worldgen" -print0 2>/dev/null)
}

echo "=== Worldgen Validator ==="

if [[ ! -d "$DATA_ROOT" ]]; then
  fail "missing data/ directory"
fi

echo "Checking for legacy paths..."
while IFS= read -r -d '' legacy_path; do
  fail "legacy path detected: ${legacy_path#$ROOT/}"
done < <(find_neoforge_jsons 'biome_modifiers')

while IFS= read -r -d '' invalid_tag_path; do
  fail "invalid worldgen tag path: ${invalid_tag_path#$ROOT/} (expected tags/worldgen/<registry>/...)"
done < <(find_invalid_tags_worldgen_jsons)

while IFS= read -r -d '' f; do
  check_json_once "$f"
done < <(
  {
    find_worldgen_jsons
    find_namespace_jsons 'dimension'
    find_namespace_jsons 'dimension_type'
    find_tags_worldgen_jsons
    find_neoforge_jsons 'biome_modifier'
  }
)

while IFS= read -r -d '' f; do
  id="$(to_id "$f")"
  CONFIGURED_FEATURES["$id"]=1
done < <(find_worldgen_jsons 'configured_feature')

while IFS= read -r -d '' f; do
  id="$(to_id "$f")"
  PLACED_FEATURES["$id"]=1
done < <(find_worldgen_jsons 'placed_feature')

while IFS= read -r -d '' f; do
  id="$(to_id "$f")"
  STRUCTURES["$id"]=1
done < <(find_worldgen_jsons 'structure')

while IFS= read -r -d '' f; do
  id="$(to_id "$f")"
  DIMENSION_TYPES["$id"]=1
done < <(find_namespace_jsons 'dimension_type')

while IFS= read -r -d '' f; do
  id="$(to_id "$f")"
  NOISE_SETTINGS["$id"]=1
done < <(find_worldgen_jsons 'noise_settings')

while IFS= read -r -d '' _; do
  BIOME_FILES=$((BIOME_FILES + 1))
done < <(find_worldgen_jsons 'biome')

while IFS= read -r -d '' _; do
  BIOME_MODIFIER_FILES=$((BIOME_MODIFIER_FILES + 1))
done < <(find_neoforge_jsons 'biome_modifier')

if [[ "$TOTAL_SUPPORTED_FILES" -eq 0 ]]; then
  fail "no supported worldgen JSON files found under data/**/worldgen, data/**/dimension, data/**/dimension_type, data/**/tags/worldgen, or data/**/neoforge/biome_modifier"
fi

if (( ${#PLACED_FEATURES[@]} == 0 && (BIOME_FILES > 0 || BIOME_MODIFIER_FILES > 0) )); then
  warn "no placed_feature JSON files found"
fi

if (( ${#CONFIGURED_FEATURES[@]} == 0 && ${#PLACED_FEATURES[@]} > 0 )); then
  warn "no configured_feature JSON files found"
fi

echo "Checking dimension references..."
while IFS= read -r -d '' dimension_file; do
  if [[ -n "${INVALID_JSON_FILES["$dimension_file"]:-}" ]]; then
    continue
  fi

  rel="${dimension_file#"$ROOT/data/"}"
  ns="${rel%%/*}"
  type_ref="$(jq -r '.type? // empty' "$dimension_file")"

  if [[ -z "$type_ref" ]]; then
    fail "dimension missing .type: ${dimension_file#$ROOT/}"
  else
    type_id="$(split_ref "$ns" "$type_ref")"
    if should_validate_dimension_type_ref "$ns" "$type_id"; then
      if [[ -n "${DIMENSION_TYPES[$type_id]:-}" ]]; then
        pass "dimension type target exists: $type_id"
      else
        fail "dimension references missing dimension_type: $type_id"
      fi
    fi
  fi

  settings_ref="$(jq -r 'if (.generator?.type? // empty) == "minecraft:noise" and (.generator?.settings? | type) == "string" then .generator.settings else empty end' "$dimension_file")"
  if [[ -z "$settings_ref" ]]; then
    continue
  fi

  settings_id="$(split_ref "$ns" "$settings_ref")"
  if ! should_validate_noise_settings_ref "$ns" "$settings_id"; then
    continue
  fi

  if [[ -n "${NOISE_SETTINGS[$settings_id]:-}" ]]; then
    pass "dimension noise settings target exists: $settings_id"
  else
    fail "dimension references missing noise_settings: $settings_id"
  fi
done < <(find_namespace_jsons 'dimension')

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
done < <(find_worldgen_jsons 'placed_feature')

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
done < <(find_worldgen_jsons 'structure_set')

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
done < <(find_worldgen_jsons 'biome')

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
done < <(find_neoforge_jsons 'biome_modifier')

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
