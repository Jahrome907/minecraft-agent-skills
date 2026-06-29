#!/usr/bin/env bash
# check-build.sh
# Verifies the Minecraft mod build environment and runs a clean build.
# Run from the root of a Minecraft mod project.

set -euo pipefail

PASS="[PASS]"
FAIL="[FAIL]"
WARN="[WARN]"

check_one_of() {
    local label="$1"
    shift

    for f in "$@"; do
        if [[ -f "$f" ]]; then
            echo "$PASS $f"
            return 0
        fi
    done

    echo "$WARN $label not found"
}

read_gradle_property() {
    local key="$1"
    if [[ -f "gradle.properties" ]]; then
        sed -n "s/^${key}=//p" gradle.properties | head -1
    fi
}

parse_java_major() {
    local version="$1"
    if [[ "$version" =~ ^1\.([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "$version" =~ ^([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

version_at_least() {
    local found="$1"
    local required="$2"
    [[ "$found" =~ ^[0-9]+$ ]] || return 1
    [[ "$found" -ge "$required" ]]
}

echo "=== Minecraft Mod Build Environment Check ==="
echo ""

BUILD_FILES=(build.gradle build.gradle.kts settings.gradle settings.gradle.kts gradle.properties)
MINECRAFT_VERSION=$(read_gradle_property "minecraft_version")

# Platform detection is needed before the Java check because Forge 1.20.1 targets Java 17.
echo "Detecting mod platform..."
PLATFORM="unknown"
if grep -qr "architectury" "${BUILD_FILES[@]}" 2>/dev/null; then
    PLATFORM="architectury"
elif grep -qr "net.neoforged" "${BUILD_FILES[@]}" 2>/dev/null; then
    PLATFORM="neoforge"
elif grep -qr "net.minecraftforge" "${BUILD_FILES[@]}" 2>/dev/null; then
    PLATFORM="forge"
elif grep -qr "fabric-loom\|fabricmc" "${BUILD_FILES[@]}" 2>/dev/null; then
    PLATFORM="fabric"
fi

if [[ -n "$MINECRAFT_VERSION" ]]; then
    echo "$PASS Platform: $PLATFORM (Minecraft $MINECRAFT_VERSION)"
else
    echo "$PASS Platform: $PLATFORM"
fi

REQUIRED_JAVA=21
JAVA_REASON="Minecraft 1.20.5+ / 1.21.x requires Java 21"
if [[ "$PLATFORM" == "forge" && "$MINECRAFT_VERSION" == "1.20.1" ]]; then
    REQUIRED_JAVA=17
    JAVA_REASON="Forge 1.20.1 requires Java 17+ and should target Java 17"
fi

# Java version

echo ""
echo "Checking Java version..."
if ! command -v java &>/dev/null; then
    echo "$FAIL java not found. Install JDK $REQUIRED_JAVA from https://adoptium.net/"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -1 | sed -n 's/.*version "\([^"]*\)".*/\1/p')
JAVA_MAJOR=$(parse_java_major "$JAVA_VERSION" || true)

if [[ -z "$JAVA_MAJOR" ]]; then
    echo "$FAIL Could not parse Java version from: $JAVA_VERSION"
    exit 1
fi

if version_at_least "$JAVA_MAJOR" "$REQUIRED_JAVA"; then
    echo "$PASS Java $JAVA_VERSION (JDK $REQUIRED_JAVA+ available)"
    if [[ "$PLATFORM" == "forge" && "$MINECRAFT_VERSION" == "1.20.1" && "$JAVA_MAJOR" -gt 17 ]]; then
        echo "$WARN Forge 1.20.1 projects should still compile with a Java 17 toolchain target"
    fi
else
    echo "$FAIL Java $JAVA_VERSION - $JAVA_REASON"
    echo "       Install from: https://adoptium.net/temurin/releases/?version=$REQUIRED_JAVA"
    exit 1
fi

# Gradle wrapper

echo ""
echo "Checking Gradle wrapper..."
if [[ ! -f "gradlew" ]]; then
    echo "$FAIL gradlew not found. Are you in the root of a Minecraft mod project?"
    exit 1
fi
echo "$PASS gradlew found"

# Key files

echo ""
echo "Checking key mod files..."

case "$PLATFORM" in
  neoforge)
    for f in "src/main/resources/META-INF/neoforge.mods.toml" "gradle.properties"; do
        [[ -f "$f" ]] && echo "$PASS $f" || echo "$WARN $f not found"
    done
    [[ -f "build.gradle" || -f "build.gradle.kts" ]] && echo "$PASS build script found" || echo "$WARN build script not found"
    ;;
  forge)
    for f in "src/main/resources/META-INF/mods.toml" "gradle.properties"; do
        [[ -f "$f" ]] && echo "$PASS $f" || echo "$WARN $f not found"
    done
    if [[ "$MINECRAFT_VERSION" != "1.20.1" ]]; then
        echo "$WARN Forge support in this skill is documented for Minecraft 1.20.1; verify other Forge versions upstream"
    fi
    [[ -f "build.gradle" || -f "build.gradle.kts" ]] && echo "$PASS build script found" || echo "$WARN build script not found"
    ;;
  fabric)
    for f in "src/main/resources/fabric.mod.json" "gradle.properties"; do
        [[ -f "$f" ]] && echo "$PASS $f" || echo "$WARN $f not found"
    done
    [[ -f "build.gradle" || -f "build.gradle.kts" ]] && echo "$PASS build script found" || echo "$WARN build script not found"
    ;;
  architectury)
    check_one_of "common build script" "common/build.gradle" "common/build.gradle.kts"
    check_one_of "fabric build script" "fabric/build.gradle" "fabric/build.gradle.kts"
    check_one_of "neoforge build script" "neoforge/build.gradle" "neoforge/build.gradle.kts"
    [[ -f "gradle.properties" ]] && echo "$PASS gradle.properties" || echo "$WARN gradle.properties not found"
    ;;
  *)
    echo "$WARN Unknown platform; skipping file checks"
    ;;
esac

# Run Gradle build

echo ""
echo "Running ./gradlew build..."
./gradlew build --console=plain

JAR_COUNT=$(find . -type f -path "*/build/libs/*.jar" ! -name "*-sources.jar" ! -name "*-dev.jar" 2>/dev/null | wc -l)
if [[ "$JAR_COUNT" -gt 0 ]]; then
    echo ""
    echo "$PASS Build succeeded!"
    echo "Output jar(s):"
    find . -type f -path "*/build/libs/*.jar" ! -name "*-sources.jar" ! -name "*-dev.jar" | while read -r jar; do
        echo "  -> $jar"
    done
else
    echo ""
    echo "$FAIL Build did not produce a jar. Check Gradle output above."
    exit 1
fi

echo ""
echo "=== Build environment is ready ==="
