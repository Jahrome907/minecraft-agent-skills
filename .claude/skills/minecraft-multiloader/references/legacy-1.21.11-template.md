# Architectury 1.21.11 Template Notes

Use this reference only for a project that has already selected the retained
Minecraft 1.21.11 and Java 21 lane. It is not a 26.x migration recipe.

## Source of Truth

Use the official [Architectury Template Generator](https://generate.architectury.dev/)
when it offers Minecraft 1.21.11 with a Multiplatform project that includes
Fabric and NeoForge. Keep its generated Gradle layout, plugin versions, and
loader wiring together. If that target is unavailable, start from a known-working
1.21.11 project and verify its resolved build before changing pins. Do not treat
an older template download as an unverified current scaffold. The root
`gradle.properties` must identify both platforms:

```properties
# These are property names and family constraints, not a released pin matrix.
# Copy values only from the generated or known-working 1.21.11 project.
mod_version=1.0.0
minecraft_version=1.21.11
enabled_platforms=fabric,neoforge

architectury_version=<project pin>
fabric_loader_version=<project pin>
fabric_api_version=<project pin ending in +1.21.11>
neoforge_version=<project pin in the 21.11.x family>
loom_version=<project pin>
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
properties, then build both artifacts. The helper checks static properties only;
it does not prove dependency compatibility. For exact project code, consult the
generated or known-working project rather than trying to repair a copied,
partial Gradle example.
