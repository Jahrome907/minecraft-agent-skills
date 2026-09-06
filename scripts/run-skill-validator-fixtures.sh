#!/usr/bin/env bash
set -euo pipefail

PASS='[PASS]'
FAIL='[FAIL]'

expect_path() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "$FAIL missing fixture path: $path" >&2
    exit 1
  fi
}

run_and_capture() {
  local output_file
  output_file="$(mktemp)"
  if "$@" >"$output_file" 2>&1; then
    cat "$output_file"
    rm -f "$output_file"
    return 0
  else
    local status=$?
    cat "$output_file"
    rm -f "$output_file"
    return "$status"
  fi
}

expect_pass() {
  local name="$1"
  shift
  if run_and_capture "$@"; then
    echo "$PASS $name"
  else
    echo "$FAIL $name (expected pass)" >&2
    exit 1
  fi
}

expect_pass_contains() {
  local name="$1"
  local pattern="$2"
  shift
  shift

  local output_file
  output_file="$(mktemp)"
  if "$@" >"$output_file" 2>&1; then
    if grep -Fq "$pattern" "$output_file"; then
      cat "$output_file"
      rm -f "$output_file"
      echo "$PASS $name"
    else
      cat "$output_file"
      rm -f "$output_file"
      echo "$FAIL $name (missing expected output: $pattern)" >&2
      exit 1
    fi
  else
    cat "$output_file"
    rm -f "$output_file"
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

expect_temp_skill_pass() {
  local name="$1"
  local skill_dir="$2"
  local temp_dir

  temp_dir="$(mktemp -d)"
  cp -R "$skill_dir"/. "$temp_dir"

  if (cd "$temp_dir" && ./scripts/validate-workflow-snippets.sh --root .); then
    rm -rf "$temp_dir"
    echo "$PASS $name"
  else
    local status=$?
    rm -rf "$temp_dir"
    echo "$FAIL $name (expected pass)" >&2
    exit "$status"
  fi
}

echo "=== Running Skill Validator Fixtures ==="

expect_path "tests/fixtures/validators/datapack/valid"
expect_path "tests/fixtures/validators/datapack/legacy-pack-metadata"
expect_path "tests/fixtures/validators/datapack/legacy-function-paths"
expect_path "tests/fixtures/validators/datapack/invalid"
expect_path "tests/fixtures/validators/datapack/invalid-pack-version"
expect_pass "datapack valid" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/valid
expect_pass "datapack modern single-element format" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/modern-single-format --strict
expect_pass "datapack legacy-compatible format range" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/legacy-compatible-format-range --strict
expect_fail_contains "datapack legacy invalid supported formats" "pack.mcmeta pack.supported_formats must be an integer, two-integer array, or object with integer min_inclusive and max_inclusive" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/legacy-invalid-supported-formats
expect_fail_contains "datapack reversed format range" "pack.min_format must not be greater" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/modern-reversed-format-range
expect_fail_contains "datapack missing format bound" "must define both .pack.min_format and .pack.max_format together" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/modern-missing-format-bound
expect_fail_contains "datapack modern pack format only" "modern data pack formats 82 and newer require both .pack.min_format and .pack.max_format" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/modern-pack-format-only
expect_fail_contains "datapack modern supported_formats" "must not define pack.supported_formats for modern-only" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/modern-supported-formats
expect_pass_contains "datapack custom load tag advisory" "custom namespace load/tick tag has no automatic engine behavior" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/custom-load-tick-tag
expect_pass "datapack nested function tags strict" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/nested-function-tag-refs --strict
expect_fail_contains "datapack missing required function reference" "missing function for tag reference" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/missing-required-function-tag-ref
expect_fail_contains "datapack invalid function tag entry" "invalid function tag entry" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/invalid-function-tag-entry
expect_pass_contains "datapack external function reference" "external function tag reference not verified" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/external-function-tag-ref
expect_fail_contains "datapack external reference strict" "strict mode failed" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/external-function-tag-ref --strict
expect_pass "datapack legacy pack metadata" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/legacy-pack-metadata
expect_fail_contains "datapack legacy function paths" "legacy path detected" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/legacy-function-paths
expect_fail_contains "datapack invalid" "legacy path detected" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/invalid
expect_fail_contains "datapack invalid pack version" "pack.mcmeta pack.min_format must be an integer or a one/two-integer array" \
  ./.agents/skills/minecraft-datapack/scripts/validate-datapack.sh \
  --root tests/fixtures/validators/datapack/invalid-pack-version

expect_path "tests/fixtures/validators/resource-pack/valid"
expect_path "tests/fixtures/validators/resource-pack/legacy-pack-metadata"
expect_path "tests/fixtures/validators/resource-pack/invalid"
expect_path "tests/fixtures/validators/resource-pack/invalid-pack-version"
expect_path "tests/fixtures/validators/resource-pack/invalid-item-model"
expect_pass "resource-pack valid" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/valid
expect_pass "resource-pack legacy-only metadata strict" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/legacy-only-pack-format --strict
expect_pass "resource-pack modern format shapes strict" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/valid-modern-format-shapes --strict
expect_fail_contains "resource-pack modern pack format only" "modern resource pack formats 65 and newer require" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/modern-pack-format-only
expect_fail_contains "resource-pack reversed format range" "pack.min_format must not be greater" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/modern-reversed-format-range
expect_fail_contains "resource-pack invalid custom model selector" "select cases must use a string" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/invalid-custom-model-data
expect_fail_contains "resource-pack invalid texture object" "invalid texture entry" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/invalid-texture-object
expect_fail_contains "resource-pack missing sound alias" "missing sound event alias target" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/invalid-sound-event-alias
expect_pass_contains "resource-pack external textures warn" "external texture not locally verifiable" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/external-textures
expect_pass_contains "resource-pack external sounds warn" "external sound not locally verifiable" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/external-textures
expect_fail_contains "resource-pack external assets strict" "strict mode failed" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/external-textures --strict
expect_fail_contains "resource-pack invalid png mcmeta" "invalid JSON: assets/mypack/textures/block/animated.png.mcmeta" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/invalid-png-mcmeta
expect_pass "resource-pack legacy pack metadata" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/legacy-pack-metadata
expect_fail_contains "resource-pack invalid" "missing texture" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/invalid
expect_fail_contains "resource-pack invalid sound type" "unsupported sounds.json entry type 'sound'" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/invalid
expect_fail_contains "resource-pack invalid pack version" "pack.mcmeta pack.min_format must be an integer or a one/two-integer array" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/invalid-pack-version
expect_fail_contains "resource-pack invalid item model" "missing model" \
  ./.agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh \
  --root tests/fixtures/validators/resource-pack/invalid-item-model

expect_path "tests/fixtures/validators/ci-release/valid/SKILL.md"
expect_path "tests/fixtures/validators/ci-release/invalid/SKILL.md"
expect_path "tests/fixtures/validators/ci-release/invalid-yaml/SKILL.md"
expect_path "tests/fixtures/validators/ci-release/indented-workflow/SKILL.md"
expect_path "tests/fixtures/validators/ci-release/multiline-flow/SKILL.md"
expect_path "tests/fixtures/validators/ci-release/non-workflow-yaml/SKILL.md"
expect_path "tests/fixtures/validators/ci-release/warn-only/SKILL.md"
expect_pass "ci-release valid" \
  ./.agents/skills/minecraft-ci-release/scripts/validate-workflow-snippets.sh \
  --root tests/fixtures/validators/ci-release/valid
expect_pass "ci-release secretless strict" \
  ./.agents/skills/minecraft-ci-release/scripts/validate-workflow-snippets.sh \
  --root tests/fixtures/validators/ci-release/secretless-strict --strict
expect_fail_contains "ci-release mutable action" "action must be pinned to a full commit SHA" \
  ./.agents/skills/minecraft-ci-release/scripts/validate-workflow-snippets.sh \
  --root tests/fixtures/validators/ci-release/mutable-action
expect_pass "ci-release multiline flow yaml" \
  ./.agents/skills/minecraft-ci-release/scripts/validate-workflow-snippets.sh \
  --root tests/fixtures/validators/ci-release/multiline-flow
expect_fail_contains "ci-release invalid" 'missing top-level `jobs:`' \
  ./.agents/skills/minecraft-ci-release/scripts/validate-workflow-snippets.sh \
  --root tests/fixtures/validators/ci-release/invalid
expect_fail_contains "ci-release invalid yaml" "is not valid YAML" \
  ./.agents/skills/minecraft-ci-release/scripts/validate-workflow-snippets.sh \
  --root tests/fixtures/validators/ci-release/invalid-yaml
expect_fail_contains "ci-release indented workflow" 'missing top-level `jobs:`' \
  ./.agents/skills/minecraft-ci-release/scripts/validate-workflow-snippets.sh \
  --root tests/fixtures/validators/ci-release/indented-workflow
expect_pass "ci-release non-workflow yaml" \
  ./.agents/skills/minecraft-ci-release/scripts/validate-workflow-snippets.sh \
  --root tests/fixtures/validators/ci-release/non-workflow-yaml
expect_fail_contains "ci-release strict warnings" "strict mode failed" \
  ./.agents/skills/minecraft-ci-release/scripts/validate-workflow-snippets.sh \
  --root tests/fixtures/validators/ci-release/warn-only \
  --strict
expect_temp_skill_pass "ci-release standalone installed mirror" \
  ./.codex/skills/minecraft-ci-release

expect_path "tests/fixtures/validators/plugin-dev/valid"
expect_path "tests/fixtures/validators/plugin-dev/valid-paper-plugin"
expect_path "tests/fixtures/validators/plugin-dev/valid-strict-reload-subcommand"
expect_path "tests/fixtures/validators/plugin-dev/valid-newer-api-version"
expect_path "tests/fixtures/validators/plugin-dev/invalid"
expect_path "tests/fixtures/validators/plugin-dev/invalid-yaml"
expect_path "tests/fixtures/validators/plugin-dev/invalid-api-version"
expect_path "tests/fixtures/validators/plugin-dev/invalid-api-version-zero-patch"
expect_path "tests/fixtures/validators/plugin-dev/invalid-paper-plugin"
expect_path "tests/fixtures/validators/plugin-dev/invalid-reload-misuse"
expect_pass "plugin-dev valid" \
  ./.agents/skills/minecraft-plugin-dev/scripts/validate-plugin-layout.sh \
  --root tests/fixtures/validators/plugin-dev/valid
expect_pass_contains "plugin-dev valid paper-plugin.yml only" "using paper-plugin.yml as the active descriptor" \
  ./.agents/skills/minecraft-plugin-dev/scripts/validate-plugin-layout.sh \
  --root tests/fixtures/validators/plugin-dev/valid-paper-plugin-only --strict
expect_pass "plugin-dev valid paper-plugin.yml" \
  ./.agents/skills/minecraft-plugin-dev/scripts/validate-plugin-layout.sh \
  --root tests/fixtures/validators/plugin-dev/valid-paper-plugin
expect_pass "plugin-dev valid strict reload subcommand" \
  ./.agents/skills/minecraft-plugin-dev/scripts/validate-plugin-layout.sh \
  --root tests/fixtures/validators/plugin-dev/valid-strict-reload-subcommand \
  --strict
expect_pass_contains "plugin-dev valid newer api-version warns" "newer than the last documented 1.21.x patch" \
  ./.agents/skills/minecraft-plugin-dev/scripts/validate-plugin-layout.sh \
  --root tests/fixtures/validators/plugin-dev/valid-newer-api-version
expect_fail_contains "plugin-dev invalid" "api-version has invalid format" \
  ./.agents/skills/minecraft-plugin-dev/scripts/validate-plugin-layout.sh \
  --root tests/fixtures/validators/plugin-dev/invalid
expect_fail_contains "plugin-dev invalid yaml" "plugin.yml is not valid YAML" \
  ./.agents/skills/minecraft-plugin-dev/scripts/validate-plugin-layout.sh \
  --root tests/fixtures/validators/plugin-dev/invalid-yaml
expect_fail_contains "plugin-dev invalid api-version range" "api-version is outside the documented 26.x / 1.21.x skill scope" \
  ./.agents/skills/minecraft-plugin-dev/scripts/validate-plugin-layout.sh \
  --root tests/fixtures/validators/plugin-dev/invalid-api-version
expect_fail_contains "plugin-dev invalid api-version zero patch" "release must be a positive integer without leading zeroes" \
  ./.agents/skills/minecraft-plugin-dev/scripts/validate-plugin-layout.sh \
  --root tests/fixtures/validators/plugin-dev/invalid-api-version-zero-patch
expect_fail_contains "plugin-dev invalid paper-plugin.yml" "paper-plugin.yml missing key: api-version" \
  ./.agents/skills/minecraft-plugin-dev/scripts/validate-plugin-layout.sh \
  --root tests/fixtures/validators/plugin-dev/invalid-paper-plugin
expect_fail_contains "plugin-dev invalid reload misuse strict" "strict mode failed" \
  ./.agents/skills/minecraft-plugin-dev/scripts/validate-plugin-layout.sh \
  --root tests/fixtures/validators/plugin-dev/invalid-reload-misuse \
  --strict

imagegen_workspace="$(mktemp -d)"
imagegen_install_root="$(mktemp -d)"
imagegen_skill_dir="$imagegen_install_root/local/skills/minecraft-imagegen"
mkdir -p "$imagegen_skill_dir"
cp -R ./.agents/skills/minecraft-imagegen/. "$imagegen_skill_dir"
if (
  cd "$imagegen_skill_dir"
  OLDPWD="$imagegen_workspace" bash ./scripts/scaffold-asset-brief.sh --type pack-icon --name smoke-test
); then
  if [[ -f "$imagegen_workspace/smoke-test-asset-brief.md" ]]; then
    echo "$PASS imagegen scaffold workspace inference"
  else
    echo "$FAIL imagegen scaffold workspace inference (brief missing from inferred workspace)" >&2
    rm -rf "$imagegen_workspace" "$imagegen_install_root"
    exit 1
  fi
else
  rm -rf "$imagegen_workspace" "$imagegen_install_root"
  echo "$FAIL imagegen scaffold workspace inference (expected pass)" >&2
  exit 1
fi
rm -rf "$imagegen_workspace" "$imagegen_install_root"

imagegen_workspace="$(mktemp -d)"
imagegen_install_root="$(mktemp -d)"
imagegen_skill_dir="$imagegen_install_root/local/skills/minecraft-imagegen"
mkdir -p "$imagegen_skill_dir"
cp -R ./.agents/skills/minecraft-imagegen/. "$imagegen_skill_dir"
if (
  cd "$imagegen_skill_dir"
  OLDPWD="$imagegen_workspace" bash ./scripts/scaffold-asset-brief.sh --type release-banner --name relative-out --out docs/briefs
); then
  if [[ -f "$imagegen_workspace/docs/briefs/relative-out-asset-brief.md" ]]; then
    if [[ -f "$imagegen_skill_dir/docs/briefs/relative-out-asset-brief.md" ]]; then
      echo "$FAIL imagegen scaffold relative --out resolution (brief was written into installed skill dir)" >&2
      rm -rf "$imagegen_workspace" "$imagegen_install_root"
      exit 1
    fi
    echo "$PASS imagegen scaffold relative --out resolution"
  else
    echo "$FAIL imagegen scaffold relative --out resolution (brief missing from workspace-relative output dir)" >&2
    rm -rf "$imagegen_workspace" "$imagegen_install_root"
    exit 1
  fi
else
  rm -rf "$imagegen_workspace" "$imagegen_install_root"
  echo "$FAIL imagegen scaffold relative --out resolution (expected pass)" >&2
  exit 1
fi
rm -rf "$imagegen_workspace" "$imagegen_install_root"

for surface in .agents .codex .claude; do
  imagegen_home="$(mktemp -d)"
  imagegen_skill_dir="$imagegen_home/$surface/skills/minecraft-imagegen"
  mkdir -p "$imagegen_skill_dir"
  cp -R ./.agents/skills/minecraft-imagegen/. "$imagegen_skill_dir"
  imagegen_output="$(mktemp)"
  if (
    cd "$imagegen_skill_dir"
    unset OLDPWD CODEX_WORKSPACE_ROOT
    HOME="$imagegen_home" bash ./scripts/scaffold-asset-brief.sh --type pack-icon --name raw-install
  ) >"$imagegen_output" 2>&1; then
    cat "$imagegen_output"
    rm -f "$imagegen_output"
    rm -rf "$imagegen_home"
    echo "$FAIL imagegen scaffold raw ~/$surface install requires explicit workspace (expected failure)" >&2
    exit 1
  elif grep -Fq "Could not infer a project workspace for the asset brief." "$imagegen_output"; then
    if [[ -e "$imagegen_home/raw-install-asset-brief.md" ]]; then
      echo "$FAIL imagegen scaffold wrote an asset into the user home" >&2
      exit 1
    fi
    rm -f "$imagegen_output"
    rm -rf "$imagegen_home"
    echo "$PASS imagegen scaffold raw ~/$surface install requires explicit workspace"
  else
    cat "$imagegen_output"
    rm -f "$imagegen_output"
    rm -rf "$imagegen_home"
    echo "$FAIL imagegen scaffold raw ~/$surface install requires explicit workspace (missing expected output)" >&2
    exit 1
  fi
done

expect_path "tests/fixtures/validators/testing/valid"
expect_path "tests/fixtures/validators/testing/invalid"
expect_path "tests/fixtures/validators/testing/neoforge-valid"
expect_path "tests/fixtures/validators/testing/neoforge-missing-template"
expect_path "tests/fixtures/validators/testing/neoforge-missing-registration"
expect_path "tests/fixtures/validators/testing/fabric-valid"
expect_path "tests/fixtures/validators/testing/fabric-missing-entrypoint"
expect_pass "testing valid" \
  ./.agents/skills/minecraft-testing/scripts/validate-test-layout.sh \
  --root tests/fixtures/validators/testing/valid
for fixture in current-neoforge-gametest-only current-fabric-gametest-only legacy-neoforge-gametest-only; do
  expect_pass "testing $fixture strict" \
    ./.agents/skills/minecraft-testing/scripts/validate-test-layout.sh \
    --root "tests/fixtures/validators/testing/$fixture" --strict
done
expect_pass "testing legacy NeoForge implicit template strict" \
  ./.agents/skills/minecraft-testing/scripts/validate-test-layout.sh \
  --root tests/fixtures/validators/testing/legacy-neoforge-implicit-template-valid --strict
expect_fail_contains "testing legacy NeoForge implicit template missing" "GameTest template fixture missing: mymod:missingimplicit" \
  ./.agents/skills/minecraft-testing/scripts/validate-test-layout.sh \
  --root tests/fixtures/validators/testing/legacy-neoforge-implicit-template-missing --strict
expect_fail_contains "testing invalid" "MockBukkit tests detected but build file is missing MockBukkit dependency" \
  ./.agents/skills/minecraft-testing/scripts/validate-test-layout.sh \
  --root tests/fixtures/validators/testing/invalid
expect_pass "testing neoforge valid" \
  ./.agents/skills/minecraft-testing/scripts/validate-test-layout.sh \
  --root tests/fixtures/validators/testing/neoforge-valid
expect_fail_contains "testing neoforge missing template" "GameTest template fixture missing: mymod:missing_template" \
  ./.agents/skills/minecraft-testing/scripts/validate-test-layout.sh \
  --root tests/fixtures/validators/testing/neoforge-missing-template
expect_fail_contains "testing neoforge missing registration" "legacy NeoForge GameTest class needs @GameTestHolder or RegisterGameTestsEvent registration" \
  ./.agents/skills/minecraft-testing/scripts/validate-test-layout.sh \
  --root tests/fixtures/validators/testing/neoforge-missing-registration
expect_pass "testing fabric valid" \
  ./.agents/skills/minecraft-testing/scripts/validate-test-layout.sh \
  --root tests/fixtures/validators/testing/fabric-valid
expect_fail_contains "testing fabric missing entrypoint" "fabric.mod.json is missing the fabric-gametest entry for com.example.mymod.fabric.MyFabricGameTests" \
  ./.agents/skills/minecraft-testing/scripts/validate-test-layout.sh \
  --root tests/fixtures/validators/testing/fabric-missing-entrypoint

expect_path "tests/fixtures/validators/multiloader/valid"
expect_path "tests/fixtures/validators/multiloader/valid-26.2"
expect_path "tests/fixtures/validators/multiloader/invalid"
expect_path "tests/fixtures/validators/multiloader/invalid-missing-mod-version"
expect_pass "multiloader valid" \
  ./.agents/skills/minecraft-multiloader/scripts/check-version-sanity.sh \
  --root tests/fixtures/validators/multiloader/valid
expect_pass "multiloader valid properties separators" \
  ./.agents/skills/minecraft-multiloader/scripts/check-version-sanity.sh \
  --root tests/fixtures/validators/multiloader/valid-properties-format --strict
expect_pass "multiloader valid 26.2" \
  ./.agents/skills/minecraft-multiloader/scripts/check-version-sanity.sh \
  --root tests/fixtures/validators/multiloader/valid-26.2
expect_fail_contains "multiloader invalid" "enabled_platforms must include fabric and neoforge" \
  ./.agents/skills/minecraft-multiloader/scripts/check-version-sanity.sh \
  --root tests/fixtures/validators/multiloader/invalid
expect_fail_contains "multiloader invalid missing mod_version" "gradle.properties missing key: mod_version" \
  ./.agents/skills/minecraft-multiloader/scripts/check-version-sanity.sh \
  --root tests/fixtures/validators/multiloader/invalid-missing-mod-version

expect_path "tests/fixtures/validators/worldgen/valid"
expect_path "tests/fixtures/validators/worldgen/invalid"
expect_path "tests/fixtures/validators/worldgen/dimensions-only"
expect_path "tests/fixtures/validators/worldgen/empty"
expect_path "tests/fixtures/validators/worldgen/external-dimension-refs-with-tags"
expect_path "tests/fixtures/validators/worldgen/external-dimension-settings"
expect_path "tests/fixtures/validators/worldgen/invalid-dimension-json"
expect_path "tests/fixtures/validators/worldgen/invalid-dimension-refs"
expect_path "tests/fixtures/validators/worldgen/invalid-external-local-dimension-refs"
expect_path "tests/fixtures/validators/worldgen/invalid-tag-layout"
expect_path "tests/fixtures/validators/worldgen/legacy"
expect_path "tests/fixtures/validators/worldgen/nested-paths"
expect_path "tests/fixtures/validators/worldgen/invalid-tags"
expect_path "tests/fixtures/validators/worldgen/tags-only"
expect_path "tests/fixtures/validators/worldgen/invalid-jigsaw-refs"
expect_pass "worldgen valid" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/valid
expect_pass "worldgen external references strict" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/external-worldgen-refs --strict
expect_fail_contains "worldgen missing supplied namespace reference" "placed_feature references missing configured_feature: minecraft:missing_configured" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/invalid-external-local-worldgen-refs
expect_fail_contains "worldgen invalid" "placed_feature references missing configured_feature" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/invalid
expect_pass "worldgen dimensions only" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/dimensions-only
expect_pass "worldgen dimensions only strict" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/dimensions-only \
  --strict
expect_pass "worldgen external dimension settings strict" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/external-dimension-settings \
  --strict
expect_pass "worldgen external dimension refs with tags strict" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/external-dimension-refs-with-tags \
  --strict
expect_fail_contains "worldgen invalid dimension refs type" "dimension references missing dimension_type" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/invalid-dimension-refs
expect_fail_contains "worldgen invalid dimension refs noise" "dimension references missing noise_settings" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/invalid-dimension-refs
expect_fail_contains "worldgen invalid external local dimension refs type" "dimension references missing dimension_type: minecraft:custom_missing" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/invalid-external-local-dimension-refs
expect_fail_contains "worldgen invalid external local dimension refs noise" "dimension references missing noise_settings: minecraft:custom_missing_noise" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/invalid-external-local-dimension-refs
expect_fail_contains "worldgen invalid dimension json summary" "worldgen validation failed" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/invalid-dimension-json
expect_pass "worldgen nested paths" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/nested-paths
expect_fail_contains "worldgen invalid jigsaw start_pool" "jigsaw structure references missing template_pool" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/invalid-jigsaw-refs
expect_fail_contains "worldgen invalid jigsaw structure template" "template_pool element references missing structure template" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/invalid-jigsaw-refs
expect_fail_contains "worldgen invalid jigsaw processors" "template_pool element references missing processor_list" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/invalid-jigsaw-refs
expect_fail_contains "worldgen invalid tags" "invalid JSON" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/invalid-tags
expect_fail_contains "worldgen invalid tag layout" "invalid worldgen tag path" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/invalid-tag-layout
expect_fail_contains "worldgen empty" "no supported worldgen JSON files found" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/empty
expect_pass "worldgen tags only" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/tags-only
expect_pass "worldgen tags only strict" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/tags-only \
  --strict
expect_fail_contains "worldgen legacy path" "legacy path detected" \
  ./.agents/skills/minecraft-world-generation/scripts/validate-worldgen-json.sh \
  --root tests/fixtures/validators/worldgen/legacy

echo "$PASS all validator fixture checks completed"
