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

Checks common Minecraft testing layout expectations:
- build.gradle(.kts) exists
- unit or MockBukkit tests enable JUnit Platform
- MockBukkit tests have the MockBukkit dependency
- GameTests have committed structure fixtures that match referenced templates
- Fabric GameTests include their required registration metadata
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

extract_package_name() {
  local file="$1"
  awk '/^[[:space:]]*package[[:space:]]+/ { gsub(/;/, "", $2); print $2; exit }' "$file"
}

extract_class_name() {
  local file="$1"
  sed -nE 's/.*(^|[[:space:]])(class|object)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\3/p' "$file" | head -n 1
}

extract_fqcn() {
  local file="$1"
  local package_name
  local class_name
  package_name="$(extract_package_name "$file")"
  class_name="$(extract_class_name "$file")"

  if [[ -z "$class_name" ]]; then
    return 1
  fi

  if [[ -n "$package_name" ]]; then
    printf '%s.%s\n' "$package_name" "$class_name"
  else
    printf '%s\n' "$class_name"
  fi
}

template_fixture_exists() {
  local root="$1"
  local namespace="$2"
  local path="$3"
  local structure_roots=()

  if [[ -d "$root/src/test/resources" ]]; then
    structure_roots+=("$root/src/test/resources")
  fi
  if [[ -d "$root/src/main/resources" ]]; then
    structure_roots+=("$root/src/main/resources")
  fi
  if [[ -d "$root/src/gametest/resources" ]]; then
    structure_roots+=("$root/src/gametest/resources")
  fi

  if [[ "${#structure_roots[@]}" -eq 0 ]]; then
    return 1
  fi

  local structure_rel="data/$namespace/structure/$path.nbt"
  local structure_root
  for structure_root in "${structure_roots[@]}"; do
    if [[ -f "$structure_root/$structure_rel" ]]; then
      return 0
    fi
  done

  return 1
}

append_legacy_neoforge_implicit_templates() {
  local source_file="$1"
  local class_name="$2"
  local holder_namespace=''
  local holder_present=0
  local class_prefix_disabled=0
  local line
  local annotation
  local method
  local method_line
  local namespace
  local path
  local template_name
  local method_prefix_disabled
  local index
  local candidate_index
  local lookahead_index
  local -a source_lines=()

  if grep -E -q '@GameTestHolder[[:space:]]*\(' "$source_file"; then
    holder_present=1
  fi
  holder_namespace="$({ grep -oE '@GameTestHolder[[:space:]]*\([[:space:]]*"[^"]+' "$source_file" || true; } | head -n 1 | sed -E 's/.*"//')"
  mapfile -t source_lines < "$source_file"

  for ((index = 0; index < ${#source_lines[@]}; index++)); do
    if [[ "${source_lines[$index]}" =~ @PrefixGameTestTemplate[[:space:]]*\([[:space:]]*false[[:space:]]*\) ]]; then
      for ((lookahead_index = index + 1; lookahead_index < ${#source_lines[@]}; lookahead_index++)); do
        line="${source_lines[$lookahead_index]}"
        if [[ "$line" =~ (^|[[:space:]])(class|object)[[:space:]]+ ]]; then
          class_prefix_disabled=1
          break 2
        fi
        if [[ "$line" =~ @GameTest([[:space:]]|\(|$) ]]; then
          break
        fi
      done
    fi
  done

  for ((index = 0; index < ${#source_lines[@]}; index++)); do
    line="${source_lines[$index]}"
    [[ "$line" =~ @GameTest([[:space:]]|\(|$) ]] || continue

    annotation="$line"
    method=''
    method_prefix_disabled=0
    if (( index > 0 )) && [[ "${source_lines[$((index - 1))]}" =~ @PrefixGameTestTemplate[[:space:]]*\([[:space:]]*false[[:space:]]*\) ]]; then
      method_prefix_disabled=1
    fi

    for ((candidate_index = index; candidate_index < ${#source_lines[@]}; candidate_index++)); do
      method_line="${source_lines[$candidate_index]}"
      if (( candidate_index > index )); then
        annotation+=" $method_line"
      fi
      if [[ "$method_line" =~ (^|[[:space:]])(public|protected|private|internal|static)[[:space:]].*\( || "$method_line" =~ (^|[[:space:]])fun[[:space:]]+ ]]; then
        if [[ "$method_line" =~ ([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\( ]]; then
          method="${BASH_REMATCH[1]}"
        fi
        break
      fi
    done

    [[ -n "$method" ]] || continue

    # Java annotations may appear in either order before the method. The
    # collected annotation block covers both @PrefixGameTestTemplate(false)
    # before and after @GameTest.
    if [[ "$annotation" =~ @PrefixGameTestTemplate[[:space:]]*\([[:space:]]*false[[:space:]]*\) ]]; then
      method_prefix_disabled=1
    fi

    template_name="$(printf '%s' "$method" | tr '[:upper:]' '[:lower:]')"
    if [[ "$annotation" =~ template[[:space:]]*= ]]; then
      if [[ "$annotation" =~ template[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
        template_name="${BASH_REMATCH[1]}"
      else
        warn "legacy NeoForge GameTest has a non-literal template name; fixture path not verified: ${source_file#$ROOT/}"
        continue
      fi
    fi
    if [[ "$template_name" == *:* ]]; then
      warn "legacy NeoForge GameTest template must be an un-namespaced name; configure its namespace with templateNamespace or @GameTestHolder: ${source_file#$ROOT/}"
      continue
    fi

    namespace="$holder_namespace"
    if [[ "$annotation" =~ templateNamespace[[:space:]]*= ]]; then
      if [[ "$annotation" =~ templateNamespace[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
        namespace="${BASH_REMATCH[1]}"
      else
        warn "legacy NeoForge GameTest has a non-literal templateNamespace; fixture path not verified: ${source_file#$ROOT/}"
        continue
      fi
    elif [[ "$holder_present" -eq 1 && -z "$namespace" ]]; then
      warn "legacy NeoForge GameTest has a non-literal @GameTestHolder value; fixture path not verified: ${source_file#$ROOT/}"
      continue
    elif [[ -z "$namespace" ]]; then
      namespace='minecraft'
    fi

    path="$template_name"
    if [[ "$class_prefix_disabled" -eq 0 && "$method_prefix_disabled" -eq 0 ]]; then
      path="$(printf '%s' "$class_name" | tr '[:upper:]' '[:lower:]').$path"
    fi
    GAME_TEST_TEMPLATES+=("$namespace:$path")
  done
}

legacy_neoforge_event_registers_class() {
  local root="$1"
  local class_name="$2"
  local source_file
  local event_variable

  while IFS= read -r -d '' source_file; do
    while IFS= read -r event_variable; do
      if grep -E -q "${event_variable}[[:space:]]*\\.[[:space:]]*register[[:space:]]*\\([[:space:]]*([A-Za-z_][A-Za-z0-9_]*\\.)*${class_name}\\.class[[:space:]]*\\)" "$source_file"; then
        return 0
      fi
    done < <(grep -oE 'RegisterGameTestsEvent[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' "$source_file" | sed -E 's/.*[[:space:]]([A-Za-z_][A-Za-z0-9_]*)$/\1/')
  done < <(find "$root/src/main" "$root/src/test" -type f \( -name '*.java' -o -name '*.kt' \) -print0 2>/dev/null)

  return 1
}

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
fi

if [[ -n "$BUILD_FILE" ]]; then
  pass "found build file: ${BUILD_FILE#$ROOT/}"
fi

if [[ -n "$TEST_ROOT" ]]; then
  pass "found test source root: ${TEST_ROOT#$ROOT/}"
fi

HAS_MOCKBUKKIT_TESTS=0
if [[ -n "$TEST_ROOT" ]] && grep -R -E -q 'MockBukkit|ServerMock|PlayerMock' "$TEST_ROOT"; then
  HAS_MOCKBUKKIT_TESTS=1
  pass "MockBukkit-style tests detected"
fi

if [[ "$HAS_MOCKBUKKIT_TESTS" -eq 1 && -n "$BUILD_FILE" ]]; then
  if grep -R -E -q 'be\.seeseemelk|com\.github\.seeseemelk' "$BUILD_FILE" "$TEST_ROOT"; then
    warn "legacy MockBukkit 3.x coordinate or package detected; prefer org.mockbukkit.mockbukkit 4.x"
  fi

  if grep -Eiq 'MockBukkit|mockbukkit' "$BUILD_FILE"; then
    pass "build file declares MockBukkit dependency"
  else
    fail "MockBukkit tests detected but build file is missing MockBukkit dependency"
  fi
fi

HAS_GAMETESTS=0
declare -a SOURCE_SCAN_ROOTS=()
for candidate_root in \
  "$ROOT/src/main/java" \
  "$ROOT/src/main/kotlin" \
  "$ROOT/src/test/java" \
  "$ROOT/src/test/kotlin" \
  "$ROOT/src/gametest/java" \
  "$ROOT/src/gametest/kotlin"; do
  if [[ -d "$candidate_root" ]]; then
    SOURCE_SCAN_ROOTS+=("$candidate_root")
  fi
done

declare -a GAME_TEST_FILES=()
declare -a GAME_TEST_TEMPLATES=()
declare -a NEOFORGE_GAMETEST_CLASSES=()
declare -a NEOFORGE_EVENT_REGISTERED_CLASSES=()
declare -a FABRIC_GAMETEST_CLASSES=()

if [[ "${#SOURCE_SCAN_ROOTS[@]}" -gt 0 ]]; then
  while IFS= read -r -d '' source_file; do
    if grep -E -q '@GameTest|FabricGameTest|GameTestHelper' "$source_file"; then
      GAME_TEST_FILES+=("$source_file")
      fqcn="$(extract_fqcn "$source_file" || true)"
      if [[ -n "$fqcn" ]]; then
        # Only the 1.21.3 annotation API needs holder or event registration.
        # Current data-driven NeoForge test-function classes also use
        # GameTestHelper, but have no @GameTest annotation to register.
        if grep -E -q '@GameTest([[:space:]]|\(|$)' "$source_file" \
          && { grep -E -q 'net\.neoforged|@GameTestHolder|PrefixGameTestTemplate' "$source_file" \
            || { [[ -f "$ROOT/src/main/resources/META-INF/neoforge.mods.toml" ]] && ! grep -E -q 'FabricGameTest|fabric\.api\.gametest' "$source_file"; }; }; then
          NEOFORGE_GAMETEST_CLASSES+=("$fqcn")
          if ! grep -E -q '@GameTestHolder' "$source_file"; then
            NEOFORGE_EVENT_REGISTERED_CLASSES+=("$fqcn")
          fi
          append_legacy_neoforge_implicit_templates "$source_file" "${fqcn##*.}"
        else
          while IFS= read -r template; do
            [[ -n "$template" ]] && GAME_TEST_TEMPLATES+=("$template")
          done < <(grep -oE '@GameTest\([^)]*template[[:space:]]*=[[:space:]]*"[^"]+"' "$source_file" | sed -E 's/.*template[[:space:]]*=[[:space:]]*"([^"]+)"/\1/')
        fi
        if grep -E -q 'FabricGameTest|fabric\.api\.gametest' "$source_file"; then
          FABRIC_GAMETEST_CLASSES+=("$fqcn")
        fi
      fi
    fi
  done < <(find "${SOURCE_SCAN_ROOTS[@]}" -type f \( -name '*.java' -o -name '*.kt' \) -print0)
fi

declare -a RESOURCE_SCAN_ROOTS=()
for candidate_root in \
  "$ROOT/src/main/resources" \
  "$ROOT/src/test/resources" \
  "$ROOT/src/gametest/resources"; do
  if [[ -d "$candidate_root" ]]; then
    RESOURCE_SCAN_ROOTS+=("$candidate_root")
  fi
done

HAS_CURRENT_NEOFORGE_GAMETESTS=0
if [[ "${#RESOURCE_SCAN_ROOTS[@]}" -gt 0 ]]; then
  while IFS= read -r -d '' instance_file; do
    HAS_CURRENT_NEOFORGE_GAMETESTS=1
    while IFS= read -r template; do
      [[ -n "$template" ]] && GAME_TEST_TEMPLATES+=("$template")
    done < <(grep -oE '"structure"[[:space:]]*:[[:space:]]*"[^"]+"' "$instance_file" | sed -E 's/.*"structure"[[:space:]]*:[[:space:]]*"([^"]+)"/\1/')
  done < <(find "${RESOURCE_SCAN_ROOTS[@]}" -type f -path '*/data/*/test_instance/*.json' -print0)
fi

HAS_JUNIT_STYLE_TESTS=0
if [[ -n "$TEST_ROOT" ]] && grep -R -E -q 'org\.junit|@Test|@ParameterizedTest' "$TEST_ROOT"; then
  HAS_JUNIT_STYLE_TESTS=1
fi

if [[ "$HAS_JUNIT_STYLE_TESTS" -eq 1 || "$HAS_MOCKBUKKIT_TESTS" -eq 1 ]]; then
  if grep -Eq 'useJUnitPlatform' "$BUILD_FILE"; then
    pass "test task enables JUnit Platform"
  else
    fail "unit or MockBukkit tests require useJUnitPlatform()"
  fi
fi

if [[ "${#GAME_TEST_FILES[@]}" -gt 0 || "$HAS_CURRENT_NEOFORGE_GAMETESTS" -eq 1 ]]; then
  HAS_GAMETESTS=1
  pass "GameTest-style tests detected"
fi

if [[ "$HAS_GAMETESTS" -eq 1 ]]; then
  if [[ "${#GAME_TEST_TEMPLATES[@]}" -gt 0 ]]; then
    for template in "${GAME_TEST_TEMPLATES[@]}"; do
      if [[ "$template" =~ ^([a-z0-9_.-]+):([a-z0-9_./-]+)$ ]]; then
        if template_fixture_exists "$ROOT" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"; then
          pass "GameTest template fixture exists: $template"
        else
          fail "GameTest template fixture missing: $template"
        fi
      else
        warn "GameTest template uses a non-literal or unsupported format: $template"
      fi
    done
  else
    pass "no literal GameTest structure reference found; skipping fixture-path validation"
  fi

  if [[ "${#NEOFORGE_GAMETEST_CLASSES[@]}" -gt 0 || "$HAS_CURRENT_NEOFORGE_GAMETESTS" -eq 1 ]]; then
    if [[ -f "$ROOT/src/main/resources/META-INF/neoforge.mods.toml" ]]; then
      pass "NeoForge metadata found for GameTests"
    else
      fail "NeoForge GameTests detected but src/main/resources/META-INF/neoforge.mods.toml is missing"
    fi

    for fqcn in "${NEOFORGE_EVENT_REGISTERED_CLASSES[@]}"; do
      class_name="${fqcn##*.}"
      if legacy_neoforge_event_registers_class "$ROOT" "$class_name"; then
        pass "legacy NeoForge GameTest class has an event registration path: $fqcn"
      else
        fail "legacy NeoForge GameTest class needs @GameTestHolder or RegisterGameTestsEvent registration: $fqcn"
      fi
    done
  fi

  if [[ "${#FABRIC_GAMETEST_CLASSES[@]}" -gt 0 ]]; then
    FABRIC_MOD_JSON=''
    if [[ -f "$ROOT/src/gametest/resources/fabric.mod.json" ]]; then
      FABRIC_MOD_JSON="$ROOT/src/gametest/resources/fabric.mod.json"
    elif [[ -f "$ROOT/src/main/resources/fabric.mod.json" ]]; then
      FABRIC_MOD_JSON="$ROOT/src/main/resources/fabric.mod.json"
    fi
    if [[ -f "$FABRIC_MOD_JSON" ]]; then
      pass "Fabric metadata found for GameTests"
      if grep -Fq '"fabric-gametest"' "$FABRIC_MOD_JSON"; then
        pass "fabric.mod.json declares fabric-gametest entrypoints"
      else
        fail "fabric.mod.json is missing the fabric-gametest entrypoint block"
      fi

      for fqcn in "${FABRIC_GAMETEST_CLASSES[@]}"; do
        if grep -Fq "$fqcn" "$FABRIC_MOD_JSON"; then
          pass "fabric.mod.json registers GameTest entrypoint: $fqcn"
        else
          fail "fabric.mod.json is missing the fabric-gametest entry for $fqcn"
        fi
      done
    else
      if [[ -d "$ROOT/src/gametest" ]]; then
        fail "Fabric GameTests detected but src/gametest/resources/fabric.mod.json is missing"
      else
        fail "Fabric GameTests detected but src/main/resources/fabric.mod.json is missing"
      fi
    fi
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
