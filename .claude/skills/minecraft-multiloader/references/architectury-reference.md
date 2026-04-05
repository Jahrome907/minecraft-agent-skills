# Architectury Version And Layout Reference

Use this file together with `SKILL.md` when you need the quick alignment rules.

## Shared Code Boundaries

- `common/` may use vanilla Minecraft classes and Architectury APIs only
- `fabric/` owns Fabric loader APIs, Fabric entrypoints, Fabric-only hooks, and Mixins
- `neoforge/` owns NeoForge loader APIs, `@Mod` entrypoints, NeoForge events, and datagen runs

## Version Alignment Rules

- Keep `minecraft_version` on one explicit 1.21.x patch line across the whole repo
- Keep `neoforge_version` on the matching `21.<patch>.x` family for that same patch
- Keep `enabled_platforms=fabric,neoforge`
- Avoid snapshot-only toolchain pins in shared examples unless you are intentionally documenting a prerelease workflow
- Keep Fabric API on the stable 1.21.x branch, which still uses the `+1.21.1` suffix for current 1.21.11-compatible releases

## Sanity Check Workflow

```bash
./scripts/check-version-sanity.sh --root .
./scripts/check-version-sanity.sh --root . --strict
```

The checker validates:

- required keys exist in `gradle.properties`
- `enabled_platforms` contains both `fabric` and `neoforge`
- snapshot versions are flagged
- NeoForge version family matches the Minecraft patch line

## Release Checklist

- build both jars with `./gradlew build`
- smoke test both `:fabric:runClient` and `:neoforge:runClient`
- verify published artifact names include the same `+<minecraft_version>` suffix
- keep one changelog entry for shared logic and call out loader-specific fixes only when behavior differs
