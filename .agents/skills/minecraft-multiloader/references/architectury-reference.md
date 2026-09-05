# Architectury Version And Layout Reference

Use this file together with `SKILL.md` when you need the quick alignment rules.

## Shared Code Boundaries

- `common/` may use vanilla Minecraft classes and Architectury APIs only
- `fabric/` owns Fabric loader APIs, Fabric entrypoints, and Fabric-only hooks
- `neoforge/` owns NeoForge loader APIs, `@Mod` entrypoints, NeoForge events, and datagen runs
- A loader-neutral Mixin may be packaged from `common/` when both generated
  platform resource/configuration paths include it. Keep Mixins with loader API
  imports, platform-only targets, or platform-only side rules in that platform.

## Version Alignment Rules

### Retained 1.21.x lane

- Keep `minecraft_version` on one explicit 1.21.x patch line across the whole repo
- Keep `neoforge_version` on the matching `21.<patch>.x` family for that same patch
- Keep Fabric API on the exact Minecraft patch suffix you target, for example `+1.21.11` for `minecraft_version=1.21.11`

### Current 26.2 lane

- Use the official [Architectury Template Generator](https://generate.architectury.dev/)
  only when it offers the exact 26.2 target with Fabric and NeoForge. Preserve
  its Minecraft, Java 25, Loom, Fabric API, NeoForge, and Architectury pins as
  one set.
- If the generator lacks that target, use a known-working project on the exact
  line as the starting point. Inspect its Gradle files and resolve its build
  before changing pins; do not manufacture a current matrix from a 1.21.11
  example or an older template download.

For both lanes, keep `enabled_platforms=fabric,neoforge`, avoid snapshot-only
pins unless intentionally testing a prerelease, and use the split Architectury
artifacts (`architectury`, `architectury-fabric`, and `architectury-neoforge`).

## Sanity Check Workflow

```bash
./scripts/check-version-sanity.sh --root .
./scripts/check-version-sanity.sh --root . --strict
```

The checker performs a static preflight and validates:

- required keys exist in `gradle.properties`
- `enabled_platforms` contains both `fabric` and `neoforge`
- snapshot versions are flagged
- NeoForge version family matches the Minecraft patch line for the retained 1.21.x lane

It does not download or resolve dependencies, compile the project, or establish
that a specific Architectury, Fabric API, NeoForge, and Loom combination is
compatible. Use the project build and both loader smoke tests for that evidence.

## Release Checklist

- build both jars with `./gradlew build`
- smoke test both `:fabric:runClient` and `:neoforge:runClient`
- inspect the actual Fabric and NeoForge JAR names under each `build/libs/`
  directory; archive-name conventions come from the selected project template
- keep one changelog entry for shared logic and call out loader-specific fixes only when behavior differs
