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

### Minecraft 1.21.x

- Keep `minecraft_version` on one explicit 1.21.x patch line across the whole repo
- Keep `neoforge_version` on the matching `21.<patch>.x` family for that same patch
- Keep Fabric API on the exact Minecraft patch suffix you target, for example `+1.21.11` for `minecraft_version=1.21.11`

### Minecraft 26.x

- Use the [Architectury 26.3 setup guide](https://docs.architectury.dev/api/getting-started/setup/)
  for the API 22 toolchain and `dev.architectury.loom-no-remap`. The guide uses
  `architectury_api_version` in `gradle.properties` and declares Loom in the
  Gradle build. Keep the pins from the same target version and scaffold.

For both versions, keep `enabled_platforms=fabric,neoforge` and use the split
Architectury artifacts (`architectury`, `architectury-fabric`, and
`architectury-neoforge`). Check the upstream guide and the resolved project
build before replacing an existing toolchain pin.

## Sanity Check Workflow

```bash
./scripts/check-version-sanity.sh --root .
./scripts/check-version-sanity.sh --root . --strict
```

The checker performs a static preflight and validates:

- required keys exist in `gradle.properties`, including `architectury_api_version`
  or the older `architectury_version`
- `enabled_platforms` contains both `fabric` and `neoforge`
- snapshot pins in inspected properties are flagged
- NeoForge version families and Fabric API suffixes match the Minecraft target

When Loom is declared in the Gradle build or version catalog, check that pin
there. The helper reads `loom_version` only from `gradle.properties`.

It does not download or resolve dependencies, compile the project, or establish
that a specific Architectury, Fabric API, NeoForge, and Loom combination is
compatible. Use the project build and both loader smoke tests for that evidence.

## Release Checklist

- build both jars with `./gradlew build`
- smoke test both `:fabric:runClient` and `:neoforge:runClient`
- inspect the actual Fabric and NeoForge JAR names under each `build/libs/`
  directory; archive-name conventions come from the selected project template
- keep one changelog entry for shared logic and call out loader-specific fixes only when behavior differs
