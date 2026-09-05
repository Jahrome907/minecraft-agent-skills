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
Usage: validate-resource-pack.sh [--root <path>] [--strict]

Checks resource pack integrity:
- JSON validity for assets/** and pack.mcmeta
- model/blockstate/item-definition/font/sounds references point to existing files
- every .png.mcmeta has a matching .png
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

resolve_texture() {
  local current_ns="$1"
  local ref="$2"
  local ns path target

  [[ -z "$ref" || "$ref" == \#* ]] && return
  if [[ "$ref" == *:* ]]; then
    ns="${ref%%:*}"
    path="${ref#*:}"
  else
    ns="$current_ns"
    path="$ref"
  fi

  target="$ROOT/assets/$ns/textures/$path.png"
  if [[ -f "$target" ]]; then
    pass "texture exists: $ns:$path"
  elif [[ "$ns" != "$current_ns" ]]; then
    warn "external texture not locally verifiable: $ns:$path"
  else
    fail "missing texture: $ns:$path (expected ${target#$ROOT/})"
  fi
}

resolve_model() {
  local current_ns="$1"
  local ref="$2"
  local ns path target

  [[ -z "$ref" || "$ref" == builtin/* ]] && return
  if [[ "$ref" == *:* ]]; then
    ns="${ref%%:*}"
    path="${ref#*:}"
  else
    ns="$current_ns"
    path="$ref"
  fi

  if [[ "$ns" == "minecraft" ]]; then
    return
  fi

  target="$ROOT/assets/$ns/models/$path.json"
  if [[ -f "$target" ]]; then
    pass "model exists: $ns:$path"
  elif [[ "$ns" != "$current_ns" ]]; then
    warn "external model not locally verifiable: $ns:$path"
  else
    fail "missing model: $ns:$path (expected ${target#$ROOT/})"
  fi
}

resolve_sound() {
  local current_ns="$1"
  local sound_type="$2"
  local ref="$3"
  local ns path target

  [[ -z "$ref" ]] && return
  if [[ "$sound_type" == "event" ]]; then
    pass "sound event reference does not map to an .ogg file: $ref"
    return
  fi
  if [[ "$sound_type" != "file" ]]; then
    fail "unsupported sounds.json entry type '$sound_type' for $ref (expected file or event)"
    return
  fi
  if [[ "$ref" == *:* ]]; then
    ns="${ref%%:*}"
    path="${ref#*:}"
  else
    ns="$current_ns"
    path="$ref"
  fi

  target="$ROOT/assets/$ns/sounds/$path.ogg"
  if [[ -f "$target" ]]; then
    pass "sound exists: $ns:$path"
  elif [[ "$ns" != "$current_ns" ]]; then
    warn "external sound not locally verifiable: $ns:$path"
  else
    fail "missing sound: $ns:$path (expected ${target#$ROOT/})"
  fi
}

echo "=== Resource Pack Validator ==="

if [[ -f "$ROOT/pack.mcmeta" ]]; then
  check_json "$ROOT/pack.mcmeta"
  check_pack_metadata "$ROOT/pack.mcmeta"
else
  fail "missing pack.mcmeta"
fi

if [[ ! -d "$ROOT/assets" ]]; then
  fail "missing assets/ directory"
fi

echo "Checking JSON files under assets/..."
while IFS= read -r -d '' json_file; do
  check_json "$json_file"
done < <(find "$ROOT/assets" -type f -name '*.json' -print0 2>/dev/null)

echo "Checking model and blockstate references..."
while IFS= read -r -d '' model_file; do
  rel="${model_file#"$ROOT/assets/"}"
  ns="${rel%%/*}"

  while IFS= read -r tex; do
    tex="$(strip_cr "$tex")"
    resolve_texture "$ns" "$tex"
  done < <(jq -r '(.textures // {} | to_entries[]?.value // empty)' "$model_file")

  while IFS= read -r parent; do
    parent="$(strip_cr "$parent")"
    resolve_model "$ns" "$parent"
  done < <(jq -r '.parent? // empty' "$model_file")

  while IFS= read -r over_model; do
    over_model="$(strip_cr "$over_model")"
    resolve_model "$ns" "$over_model"
  done < <(jq -r '.overrides[]?.model? // empty' "$model_file")
done < <(find "$ROOT/assets" -type f -path '*/models/*.json' -print0 2>/dev/null)

echo "Checking item definition model references..."
while IFS= read -r -d '' item_file; do
  rel="${item_file#"$ROOT/assets/"}"
  ns="${rel%%/*}"
  while IFS= read -r model_ref; do
    model_ref="$(strip_cr "$model_ref")"
    resolve_model "$ns" "$model_ref"
  done < <(jq -r '.. | objects | select(.type? == "minecraft:model" and (.model? | type) == "string") | .model' "$item_file")
done < <(find "$ROOT/assets" -type f -path '*/items/*.json' -print0 2>/dev/null)

while IFS= read -r -d '' blockstate_file; do
  rel="${blockstate_file#"$ROOT/assets/"}"
  ns="${rel%%/*}"
  while IFS= read -r model_ref; do
    model_ref="$(strip_cr "$model_ref")"
    resolve_model "$ns" "$model_ref"
  done < <(jq -r '(
      .variants? // {} | .. | objects | .model? // empty
    ), (
      .multipart[]?.apply? | if type == "array" then .[]?.model? // empty else .model? // empty end
    )' "$blockstate_file")
done < <(find "$ROOT/assets" -type f -path '*/blockstates/*.json' -print0 2>/dev/null)

echo "Checking sounds.json references..."
while IFS= read -r -d '' sounds_file; do
  rel="${sounds_file#"$ROOT/assets/"}"
  ns="${rel%%/*}"
  while IFS=$'\t' read -r sound_type sound_ref; do
    sound_type="$(strip_cr "$sound_type")"
    sound_ref="$(strip_cr "$sound_ref")"
    resolve_sound "$ns" "$sound_type" "$sound_ref"
  done < <(jq -r '.. | objects | select(has("sounds")) | .sounds[]? | if type == "string" then ["file", .] else [(.type // "file"), (.name // empty)] end | @tsv' "$sounds_file")
done < <(find "$ROOT/assets" -type f -name 'sounds.json' -print0 2>/dev/null)

echo "Checking font provider file references..."
while IFS= read -r -d '' font_file; do
  rel="${font_file#"$ROOT/assets/"}"
  ns="${rel%%/*}"
  while IFS= read -r font_ref; do
    font_ref="$(strip_cr "$font_ref")"
    [[ -z "$font_ref" ]] && continue
    if [[ "$font_ref" == *:* ]]; then
      target_ns="${font_ref%%:*}"
      target_path="${font_ref#*:}"
    else
      target_ns="$ns"
      target_path="$font_ref"
    fi

    target="$ROOT/assets/$target_ns/textures/$target_path"
    if [[ -f "$target" ]]; then
      pass "font texture exists: $target_ns:$target_path"
    elif [[ "$target_ns" != "$ns" ]]; then
      warn "external font texture not locally verifiable: $target_ns:$target_path"
    else
      fail "missing font texture: $target_ns:$target_path (expected ${target#$ROOT/})"
    fi
  done < <(jq -r '.providers[]? | .file? // empty' "$font_file")
done < <(find "$ROOT/assets" -type f -path '*/font/*.json' -print0 2>/dev/null)

echo "Checking .png.mcmeta pairs..."
while IFS= read -r -d '' mcmeta_file; do
  check_json "$mcmeta_file"
  png_file="${mcmeta_file%.mcmeta}"
  if [[ -f "$png_file" ]]; then
    pass "animation pair exists: ${mcmeta_file#$ROOT/}"
  else
    fail "orphan .png.mcmeta: ${mcmeta_file#$ROOT/} (missing ${png_file#$ROOT/})"
  fi
done < <(find "$ROOT/assets" -type f -name '*.png.mcmeta' -print0 2>/dev/null)

echo ""
if [[ "$FAILURES" -gt 0 ]]; then
  echo "$FAIL resource-pack validation failed with $FAILURES error(s) and $WARNINGS warning(s)"
  exit 1
fi

if [[ "$STRICT" -eq 1 && "$WARNINGS" -gt 0 ]]; then
  echo "$FAIL resource-pack validation strict mode failed on $WARNINGS warning(s)"
  exit 1
fi

echo "$PASS resource-pack validation passed with $WARNINGS warning(s)"
