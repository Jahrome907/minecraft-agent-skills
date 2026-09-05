# Architectury 1.21.11 Template Notes

Use this reference only for a project that has already selected the retained
Minecraft 1.21.11 and Java 21 lane. It is not a 26.x migration recipe.

## Source of Truth

Start from a released [Architectury template](https://github.com/architectury/architectury-templates)
that explicitly supports the project Minecraft version. Keep its generated Gradle
layout, plugin versions, and loader wiring together. The root `gradle.properties`
must identify both platforms:

```properties
mod_version=1.0.0
minecraft_version=1.21.11
enabled_platforms=fabric,neoforge

architectury_version=19.0.1
fabric_loader_version=0.19.3
fabric_api_version=0.141.4+1.21.11
neoforge_version=21.11.42
loom_version=1.17.11
```

The generated layout should keep `common/`, `fabric/`, and `neoforge/` as
separate source sets. Put shared resources in `common/src/main/resources`; keep
each loader's metadata in its platform project.

## Shared And Loader-Specific Code

The common source set may use vanilla and Architectury APIs. `@ExpectPlatform`
is appropriate for a small loader boundary, with same-package `*Impl` classes in
both platform source sets. Keep loader APIs and entrypoints in the matching
platform source set.

A loader-neutral Mixin may live in common only when its configuration and
resources are included for both Fabric and NeoForge by the generated template.
Keep a Mixin in its platform source set when it imports a loader API, uses a
platform-only target or side, or needs platform-specific configuration.

## Metadata Anchors

The Fabric metadata must use the template's loader, Fabric API, and Minecraft
version ranges. The NeoForge metadata belongs at
`neoforge/src/main/resources/META-INF/neoforge.mods.toml` and its Minecraft and
NeoForge dependency ranges must match the same 1.21.11 lane. Do not copy these
1.21.11 values into a 26.x project.

## Verification

Run `./scripts/check-version-sanity.sh --root <project>` after changing version
properties, then build both artifacts. For exact current template code, consult
the generated template rather than trying to repair a copied, partial Gradle
example.
