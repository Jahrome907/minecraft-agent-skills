#!/usr/bin/env bash
set -euo pipefail

PASS='[PASS]'
WARN='[WARN]'
FAIL='[FAIL]'

ROOT='.'
STRICT=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YAML_MODULE="$SCRIPT_DIR/vendor/js-yaml.min.cjs"

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
Usage: validate-plugin-layout.sh [--root <path>] [--strict]

Checks Paper/Bukkit plugin layout:
- required plugin.yml keys (name, version, main, api-version)
- optional paper-plugin.yml keys (name, version, api-version, and matching main when declared)
- descriptor YAML syntax before key extraction
- main class path exists and extends JavaPlugin
- warns on actual server /reload anti-pattern usage
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
  echo "$FAIL root path does not exist: $ROOT"
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "$FAIL node is required to parse plugin YAML descriptors"
  exit 1
fi

if [[ ! -f "$YAML_MODULE" ]]; then
  echo "$FAIL missing bundled YAML parser: $YAML_MODULE"
  exit 1
fi

FAILURES=0
WARNINGS=0
CURRENT_LEGACY_API_PATCH=11
CURRENT_API_RELEASE=2

pass() { echo "$PASS $*"; }
warn() { echo "$WARN $*"; WARNINGS=$((WARNINGS + 1)); }
fail() { echo "$FAIL $*"; FAILURES=$((FAILURES + 1)); }

validate_api_version() {
  local value="$1"

  if [[ "$value" =~ ^1\.21$ ]]; then
    return 0
  fi

  if [[ "$value" =~ ^1\.21\.([1-9][0-9]*)$ ]]; then
    return 0
  fi

  if [[ "$value" =~ ^26\.([1-9][0-9]*)$ ]]; then
    return 0
  fi

  return 1
}

warn_if_newer_than_documented_api_version() {
  local value="$1"
  local label="$2"

  if [[ "$value" =~ ^1\.21\.([1-9][0-9]*)$ ]] && (( BASH_REMATCH[1] > CURRENT_LEGACY_API_PATCH )); then
    warn "$label api-version is newer than the last documented 1.21.x patch (1.21.${CURRENT_LEGACY_API_PATCH}); verify it against Paper's supported versions"
  elif [[ "$value" =~ ^26\.([1-9][0-9]*)$ ]] && (( BASH_REMATCH[1] > CURRENT_API_RELEASE )); then
    warn "$label api-version is newer than the repo's current Paper example (26.${CURRENT_API_RELEASE}); verify it against the current Paper release line"
  fi
}

trim() {
  local s="$1"
  s="${s//$'\r'/}"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  s="${s#\"}"
  s="${s%\"}"
  s="${s#\'}"
  s="${s%\'}"
  echo "$s"
}

validate_yaml_descriptor() {
  local file="$1"
  local label="$2"
  local output=""

  if output="$(node - "$file" "$label" "$YAML_MODULE" <<'NODE'
const fs = require('node:fs');

const file = process.argv[2];
const label = process.argv[3];
const yamlModule = process.argv[4];

let yaml;
try {
  yaml = require(yamlModule);
} catch (error) {
  console.log(`missing bundled YAML parser at ${yamlModule}: ${String(error.message || error)}`);
  process.exit(2);
}

try {
  const parsed = yaml.load(fs.readFileSync(file, 'utf8'));
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    console.log(`${label} top-level document must be a mapping`);
    process.exit(2);
  }
} catch (error) {
  console.log(String(error.message || error).split('\n')[0]);
  process.exit(2);
}
NODE
)"; then
    pass "$label is valid YAML"
    return 0
  fi

  fail "$label is not valid YAML: $output"
  return 1
}

extract_yaml_key() {
  local file="$1"
  local key="$2"

  node - "$file" "$key" "$YAML_MODULE" <<'NODE'
const fs = require('node:fs');

const file = process.argv[2];
const key = process.argv[3];
const yamlModule = process.argv[4];
const yaml = require(yamlModule);
const parsed = yaml.load(fs.readFileSync(file, 'utf8'));
const value = parsed?.[key];

if (value === undefined || value === null) process.exit(0);
if (typeof value === 'object') process.exit(0);
process.stdout.write(String(value));
NODE
}

warn_on_reload_misuse() {
  local root="$1"
  local misuse_detected=0

  if grep -R -n -E --include='*.java' --include='*.kt' '\b(Bukkit|getServer\(\)|server)\.reload[[:space:]]*\(' "$root/src" >/dev/null 2>&1; then
    misuse_detected=1
  fi

  if grep -R -n -E -i --include='*.java' --include='*.kt' "(dispatchCommand|performCommand|chat)\\([^)]*[\"']/?(minecraft:)?reload([[:space:]]|[\"'])" "$root/src" >/dev/null 2>&1; then
    misuse_detected=1
  fi

  if [[ "$misuse_detected" -eq 1 ]]; then
    warn "detected actual server reload usage in source (avoid Bukkit.reload() and dispatching /reload)"
  else
    pass "no obvious server /reload anti-pattern detected"
  fi
}

echo "=== Plugin Layout Validator ==="

name_val=""
version_val=""
main_val=""
api_val=""

PLUGIN_YML=""
if [[ -f "$ROOT/src/main/resources/plugin.yml" ]]; then
  PLUGIN_YML="$ROOT/src/main/resources/plugin.yml"
elif [[ -f "$ROOT/plugin.yml" ]]; then
  PLUGIN_YML="$ROOT/plugin.yml"
else
  fail "missing plugin.yml (expected src/main/resources/plugin.yml)"
fi

if [[ -n "$PLUGIN_YML" ]]; then
  pass "found plugin.yml: ${PLUGIN_YML#$ROOT/}"

  if validate_yaml_descriptor "$PLUGIN_YML" "plugin.yml"; then
    name_val="$(trim "$(extract_yaml_key "$PLUGIN_YML" "name")")"
    version_val="$(trim "$(extract_yaml_key "$PLUGIN_YML" "version")")"
    main_val="$(trim "$(extract_yaml_key "$PLUGIN_YML" "main")")"
    api_val="$(trim "$(extract_yaml_key "$PLUGIN_YML" "api-version")")"

    [[ -n "$name_val" ]] && pass "plugin.yml has name" || fail "plugin.yml missing key: name"
    [[ -n "$version_val" ]] && pass "plugin.yml has version" || fail "plugin.yml missing key: version"
    [[ -n "$main_val" ]] && pass "plugin.yml has main" || fail "plugin.yml missing key: main"

    if [[ -z "$api_val" ]]; then
      fail "plugin.yml missing key: api-version"
    elif validate_api_version "$api_val"; then
      pass "plugin.yml api-version is within the documented 26.x / 1.21.x skill scope: $api_val"
      warn_if_newer_than_documented_api_version "$api_val" "plugin.yml"
    elif [[ "$api_val" =~ ^(1\.21\.|26\.)0[0-9]*$ ]]; then
      fail "plugin.yml api-version release must be a positive integer without leading zeroes: $api_val"
    elif [[ "$api_val" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
      fail "plugin.yml api-version is outside the documented 26.x / 1.21.x skill scope: $api_val"
    else
      fail "plugin.yml api-version has invalid format: $api_val"
    fi

    if [[ -n "$main_val" ]]; then
      class_path="${main_val//./\/}"
      java_file="$ROOT/src/main/java/$class_path.java"
      kotlin_file="$ROOT/src/main/kotlin/$class_path.kt"

      if [[ -f "$java_file" ]]; then
        pass "main class file exists: ${java_file#$ROOT/}"
        if grep -qE 'extends[[:space:]]+JavaPlugin' "$java_file"; then
          pass "main class extends JavaPlugin"
        else
          fail "main class does not extend JavaPlugin: ${java_file#$ROOT/}"
        fi
      elif [[ -f "$kotlin_file" ]]; then
        pass "main class file exists: ${kotlin_file#$ROOT/}"
        if grep -qE ':[[:space:]]*JavaPlugin\(\)' "$kotlin_file"; then
          pass "main Kotlin class extends JavaPlugin"
        else
          fail "main Kotlin class does not extend JavaPlugin: ${kotlin_file#$ROOT/}"
        fi
      else
        fail "main class file not found for '$main_val'"
      fi
    fi
  fi
fi

PAPER_PLUGIN_YML=""
if [[ -f "$ROOT/src/main/resources/paper-plugin.yml" ]]; then
  PAPER_PLUGIN_YML="$ROOT/src/main/resources/paper-plugin.yml"
elif [[ -f "$ROOT/paper-plugin.yml" ]]; then
  PAPER_PLUGIN_YML="$ROOT/paper-plugin.yml"
fi

if [[ -n "$PAPER_PLUGIN_YML" ]]; then
  pass "found paper-plugin.yml: ${PAPER_PLUGIN_YML#$ROOT/}"

  if validate_yaml_descriptor "$PAPER_PLUGIN_YML" "paper-plugin.yml"; then
    paper_name_val="$(trim "$(extract_yaml_key "$PAPER_PLUGIN_YML" "name")")"
    paper_version_val="$(trim "$(extract_yaml_key "$PAPER_PLUGIN_YML" "version")")"
    paper_main_val="$(trim "$(extract_yaml_key "$PAPER_PLUGIN_YML" "main")")"
    paper_api_val="$(trim "$(extract_yaml_key "$PAPER_PLUGIN_YML" "api-version")")"

    [[ -n "$paper_name_val" ]] && pass "paper-plugin.yml has name" || fail "paper-plugin.yml missing key: name"
    [[ -n "$paper_version_val" ]] && pass "paper-plugin.yml has version" || fail "paper-plugin.yml missing key: version"

    if [[ -z "$paper_api_val" ]]; then
      fail "paper-plugin.yml missing key: api-version"
    elif validate_api_version "$paper_api_val"; then
      pass "paper-plugin.yml api-version is within the documented 26.x / 1.21.x skill scope: $paper_api_val"
      warn_if_newer_than_documented_api_version "$paper_api_val" "paper-plugin.yml"
    elif [[ "$paper_api_val" =~ ^(1\.21\.|26\.)0[0-9]*$ ]]; then
      fail "paper-plugin.yml api-version release must be a positive integer without leading zeroes: $paper_api_val"
    elif [[ "$paper_api_val" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
      fail "paper-plugin.yml api-version is outside the documented 26.x / 1.21.x skill scope: $paper_api_val"
    else
      fail "paper-plugin.yml api-version has invalid format: $paper_api_val"
    fi

    if [[ -n "$PLUGIN_YML" && -n "$name_val" ]]; then
      [[ -n "$paper_name_val" && "$paper_name_val" == "$name_val" ]] && pass "paper-plugin.yml name matches plugin.yml" || fail "paper-plugin.yml name must match plugin.yml"
      [[ -n "$paper_version_val" && "$paper_version_val" == "$version_val" ]] && pass "paper-plugin.yml version matches plugin.yml" || fail "paper-plugin.yml version must match plugin.yml"
      [[ -n "$paper_api_val" && "$paper_api_val" == "$api_val" ]] && pass "paper-plugin.yml api-version matches plugin.yml" || fail "paper-plugin.yml api-version must match plugin.yml"

      if [[ -n "$paper_main_val" ]]; then
        [[ "$paper_main_val" == "$main_val" ]] && pass "paper-plugin.yml main matches plugin.yml" || fail "paper-plugin.yml main must match plugin.yml when declared"
      else
        warn "paper-plugin.yml omits main; verify the descriptor is intentional for your Paper plugin bootstrap flow"
      fi
    fi
  fi
fi

echo "Checking /reload anti-pattern..."
if [[ -d "$ROOT/src" ]]; then
  warn_on_reload_misuse "$ROOT"
else
  warn "src/ directory not found; skipped reload scan"
fi

echo ""
if [[ "$FAILURES" -gt 0 ]]; then
  echo "$FAIL plugin layout validation failed with $FAILURES error(s) and $WARNINGS warning(s)"
  exit 1
fi

if [[ "$STRICT" -eq 1 && "$WARNINGS" -gt 0 ]]; then
  echo "$FAIL plugin layout strict mode failed on $WARNINGS warning(s)"
  exit 1
fi

echo "$PASS plugin layout validation passed with $WARNINGS warning(s)"
