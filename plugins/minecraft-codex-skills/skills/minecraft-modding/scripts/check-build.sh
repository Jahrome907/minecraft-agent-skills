#!/usr/bin/env bash
# check-build.sh
# Verifies the Minecraft mod build environment and runs a clean build.
# Run from the root of a Minecraft mod project.

set -euo pipefail

PASS="[PASS]"
FAIL="[FAIL]"
WARN="[WARN]"

echo "=== Minecraft Mod Build Environment Check ==="
echo ""

# ── Java 21 ────────────────────────────────────────────────────────────────
echo "Checking Java version..."
if ! command -v java &>/dev/null; then
    echo "$FAIL java not found. Install JDK 21 from https://adoptium.net/"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -1 | sed -n 's/.*version "\([^"]*\)".*/\1/p')
JAVA_MAJOR=$(echo "$JAVA_VERSION" | cut -d. -f1)

if [[ "$JAVA_MAJOR" -ge 21 ]]; then
    echo "$PASS Java $JAVA_VERSION (JDK 21+ required)"
else
    echo "$FAIL Java $JAVA_VERSION — Minecraft 1.20.5+ requires Java 21"
    echo "       Install from: https://adoptium.net/en-GB/temurin/releases/?version=21"
    exit 1
fi

# ── Gradle wrapper ──────────────────────────────────────────────────────────
echo ""
echo "Checking Gradle wrapper..."
if [[ ! -f "gradlew" ]]; then
    echo "$FAIL gradlew not found. Are you in the root of a Minecraft mod project?"
    exit 1
fi
echo "$PASS gradlew found"

# ── Platform detection ──────────────────────────────────────────────────────
echo ""
echo "Detecting mod platform..."

BUILD_FILES=(build.gradle build.gradle.kts settings.gradle settings.gradle.kts gradle.properties)
PLATFORM="unknown"
if grep -qr "architectury" "${BUILD_FILES[@]}" 2>/dev/null; then
    PLATFORM="architectury"
elif grep -qr "net.neoforged" "${BUILD_FILES[@]}" 2>/dev/null; then
    PLATFORM="neoforge"
elif grep -qr "fabric-loom\|fabricmc" "${BUILD_FILES[@]}" 2>/dev/null; then
    PLATFORM="fabric"
fi

echo "$PASS Platform: $PLATFORM"

# ── Key files ───────────────────────────────────────────────────────────────
echo ""
echo "Checking key mod files..."

case "$PLATFORM" in
  neoforge)
    for f in "src/main/resources/META-INF/neoforge.mods.toml" "gradle.properties"; do
        [[ -f "$f" ]] && echo "$PASS $f" || echo "$WARN $f not found"
    done
    [[ -f "build.gradle" || -f "build.gradle.kts" ]] && echo "$PASS build script found" || echo "$WARN build script not found"
    ;;
  fabric)
    for f in "src/main/resources/fabric.mod.json" "gradle.properties"; do
        [[ -f "$f" ]] && echo "$PASS $f" || echo "$WARN $f not found"
    done
    [[ -f "build.gradle" || -f "build.gradle.kts" ]] && echo "$PASS build script found" || echo "$WARN build script not found"
    ;;
  architectury)
    for f in "common/build.gradle" "common/build.gradle.kts" "fabric/build.gradle" "fabric/build.gradle.kts" "neoforge/build.gradle" "neoforge/build.gradle.kts" "gradle.properties"; do
        [[ -f "$f" ]] && echo "$PASS $f" || echo "$WARN $f not found"
    done
    ;;
  *)
    echo "$WARN Unknown platform; skipping file checks"
    ;;
esac

# ── Run Gradle build ────────────────────────────────────────────────────────
echo ""
echo "Running ./gradlew build..."
./gradlew build --console=plain

JAR_COUNT=$(find . -type f -path "*/build/libs/*.jar" ! -name "*-sources.jar" ! -name "*-dev.jar" 2>/dev/null | wc -l)
if [[ "$JAR_COUNT" -gt 0 ]]; then
    echo ""
    echo "$PASS Build succeeded!"
    echo "Output jar(s):"
    find . -type f -path "*/build/libs/*.jar" ! -name "*-sources.jar" ! -name "*-dev.jar" | while read -r jar; do
        echo "  → $jar"
    done
else
    echo ""
    echo "$FAIL Build did not produce a jar. Check Gradle output above."
    exit 1
fi

echo ""
echo "=== Build environment is ready ==="
