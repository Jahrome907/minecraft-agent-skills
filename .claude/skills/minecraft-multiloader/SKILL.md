---
name: minecraft-multiloader
description: "Build and maintain Architectury-based Minecraft 26.x or 1.21.x mods that share one codebase across NeoForge and Fabric. Use only when both loaders are required; use minecraft-modding for a single-loader project."
---

# Minecraft Multiloader Skill (Architectury)

## What Is Architectury?

[Architectury](https://github.com/architectury/architectury-api) is a framework that
lets you write one mod codebase that compiles to both **NeoForge** and **Fabric** JARs.
The common subproject has a shared API; platform subprojects implement
platform-specific behavior behind the `@ExpectPlatform` abstraction.

### Routing Boundaries
- `Use when`: one shared codebase must build and ship both NeoForge and Fabric artifacts.
- `Do not use when`: the project is single-loader only (`minecraft-modding` for NeoForge/Fabric, not both).
- `Do not use when`: the task is Paper/Bukkit plugin development (`minecraft-plugin-dev`).

| Component | Purpose |
|-----------|---------|
| `architectury-loom` | Gradle plugin — extends Fabric Loom for multiloader support |
| `architectury-api` | Runtime library — abstractions over both platforms |
| `@ExpectPlatform` | Annotation marking methods with platform-specific implementations |
| `common/` | Shared code (no loader-specific APIs) |
| `fabric/` | Fabric-specific code + entrypoint |
| `neoforge/` | NeoForge-specific code + entrypoint |

---

## Versions (Retained 1.21.11 Lane)

```properties
# gradle.properties property names used by this skill's static helper.
# Get every tool version from the exact generated or known-working project.
mod_version=1.0.0
minecraft_version=1.21.11
enabled_platforms=fabric,neoforge

architectury_version=<project pin>
fabric_loader_version=<project pin>
fabric_api_version=<project pin ending in +1.21.11>
neoforge_version=<project pin in the 21.11.x family>
loom_version=<project pin>
```

Pin `architectury_version`, the Architectury plugin version, and `loom_version`
from the same generated or known-working project line. This skill deliberately
does not publish a copyable dependency matrix: its static helper cannot resolve
whether a particular set of versions is compatible.

For the current Minecraft 26.2 / Java 25 lane, use the official
[Architectury Template Generator](https://generate.architectury.dev/) only when
its version selector offers the exact target. Generate a **Multiplatform**
project with Fabric and NeoForge, then preserve the generated Gradle layout and
pins as one set. If the generator does not offer the target, begin with an
already working project on that exact line and inspect its resolved build; do
not relabel a 1.21.11 template as 26.2. The published template downloads are
not a substitute for an exact-current scaffold.

Do not mechanically change only `minecraft_version` in the retained example:
26.2 is unobfuscated and its Loom/remapping setup differs from 1.21.11.

## Bundled References And Helpers

- Version alignment reference: `references/architectury-reference.md`
- Sanity checker: `./scripts/check-version-sanity.sh --root <project>`

Run the sanity checker after editing `gradle.properties`. It is a static
syntax-and-version-family preflight: it catches missing keys, snapshot pins,
missing `fabric` / `neoforge` platforms, and obvious version-family drift. It
does not resolve dependencies, prove loader compatibility, or replace the
project's Fabric and NeoForge build and smoke tests.

---

## Root Project Layout

```
my-mod/
├── build.gradle           ← root build (shared config)
├── settings.gradle
├── gradle.properties
├── common/
│   ├── build.gradle
│   └── src/main/java/com/example/mymod/
│       ├── MyMod.java               ← shared init
│       ├── registry/
│       │   └── ModItems.java        ← shared registry declarations
│       └── platform/
│           └── PlatformHelper.java  ← @ExpectPlatform methods
├── fabric/
│   ├── build.gradle
│   └── src/main/
│       ├── java/com/example/mymod/fabric/
│       │   ├── MyModFabric.java          ← Fabric entrypoint
│       ├── java/com/example/mymod/platform/
│       │   └── PlatformHelperImpl.java   ← Fabric @ExpectPlatform implementation
│       └── resources/
│           ├── fabric.mod.json
│           └── assets/...
└── neoforge/
    ├── build.gradle
    └── src/main/
        ├── java/com/example/mymod/neoforge/
        │   ├── MyModNeoForge.java        ← NeoForge @Mod entry
        ├── java/com/example/mymod/platform/
        │   └── PlatformHelperImpl.java   ← NeoForge @ExpectPlatform implementation
        └── resources/
            ├── META-INF/neoforge.mods.toml
            └── assets/...
```

---

## Legacy Build Template

The old fixed Gradle scripts were a 1.21.11 snapshot and are intentionally not
presented as a current scaffold. For either supported lane, read
[`references/legacy-1.21.11-template.md`](references/legacy-1.21.11-template.md)
or [`references/architectury-reference.md`](references/architectury-reference.md)
before changing generated build files. They preserve version anchors and
source-set boundaries without encouraging a partial build script to be copied
into a different Minecraft line.

---

## Shared Common Code

### `common/.../MyMod.java`
```java
package com.example.mymod;

import dev.architectury.registry.registries.DeferredRegister;
import dev.architectury.registry.registries.RegistrySupplier;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.Identifier;
import net.minecraft.resources.ResourceKey;
import net.minecraft.world.item.Item;

public class MyMod {
    public static final String MOD_ID = "mymod";

    // Architectury's DeferredRegister — works on both platforms
    public static final DeferredRegister<Item> ITEMS =
        DeferredRegister.create(MOD_ID, Registries.ITEM);

    public static final RegistrySupplier<Item> MY_ITEM =
        ITEMS.register("my_item", () -> new Item(new Item.Properties().setId(
            ResourceKey.create(Registries.ITEM,
                Identifier.fromNamespaceAndPath(MOD_ID, "my_item"))
        )));

    public static void init() {
        ITEMS.register(); // registers with both platforms
    }
}
```

### `@ExpectPlatform` — platform-specific methods

Define the contract in `common/`:
```java
package com.example.mymod.platform;

import dev.architectury.injectables.annotations.ExpectPlatform;
import net.minecraft.world.level.material.Fluid;

public class PlatformHelper {

    @ExpectPlatform
    public static boolean isModLoaded(String modId) {
        // This body is replaced at compile time by the platform implementation
        throw new AssertionError("ExpectPlatform implementation not found");
    }

    @ExpectPlatform
    public static boolean isClient() {
        throw new AssertionError();
    }
}
```

Keep each platform implementation in the same Java package as the common
`@ExpectPlatform` class. Only the source set changes between `common/`,
`fabric/`, and `neoforge/`.

Implement in `fabric/.../platform/PlatformHelperImpl.java`:
```java
package com.example.mymod.platform;

import net.fabricmc.loader.api.FabricLoader;

// Class name must match: <common class name>Impl
public class PlatformHelperImpl {

    public static boolean isModLoaded(String modId) {
        return FabricLoader.getInstance().isModLoaded(modId);
    }

    public static boolean isClient() {
        return FabricLoader.getInstance().getEnvironmentType() ==
            net.fabricmc.api.EnvType.CLIENT;
    }
}
```

Implement in `neoforge/.../platform/PlatformHelperImpl.java`:
```java
package com.example.mymod.platform;

import net.neoforged.fml.ModList;
import net.neoforged.fml.loading.FMLEnvironment;

public class PlatformHelperImpl {

    public static boolean isModLoaded(String modId) {
        return ModList.get().isLoaded(modId);
    }

    public static boolean isClient() {
        return FMLEnvironment.dist.isClient();
    }
}
```

---

## Fabric Entrypoint

### `fabric/.../MyModFabric.java`
```java
package com.example.mymod.fabric;

import com.example.mymod.MyMod;
import net.fabricmc.api.ModInitializer;

public class MyModFabric implements ModInitializer {
    @Override
    public void onInitialize() {
        MyMod.init();
    }
}
```

### `fabric/.../resources/fabric.mod.json`
This retained-1.21.11 metadata example follows the minimum dependencies in the
[upstream Architectury 1.21.11 branch](https://github.com/architectury/architectury-api/tree/1.21.11).
Keep the generated project's exact ranges when they are stricter.

```json
{
  "schemaVersion": 1,
  "id": "mymod",
  "version": "${version}",
  "name": "My Mod",
  "description": "A multiloader example mod",
  "license": "MIT",
  "environment": "*",
  "entrypoints": {
    "main": ["com.example.mymod.fabric.MyModFabric"]
  },
  "depends": {
    "fabricloader": ">=0.18.2",
    "fabric-api": ">=0.139.4+1.21.11",
    "architectury": ">=19.0",
    "minecraft": "~1.21.11"
  }
}
```

---

## NeoForge Entrypoint

### `neoforge/.../MyModNeoForge.java`
```java
package com.example.mymod.neoforge;

import com.example.mymod.MyMod;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.common.Mod;

@Mod(MyMod.MOD_ID)
public class MyModNeoForge {
    public MyModNeoForge(IEventBus modEventBus) {
        MyMod.init();
    }
}
```

### `neoforge/.../resources/META-INF/neoforge.mods.toml`
```toml
modLoader = "javafml"
loaderVersion = "[1,)"
license = "MIT"

[[mods]]
modId = "mymod"
version = "${file.jarVersion}"
displayName = "My Mod"
description = "A multiloader example mod"

[[dependencies.mymod]]
modId = "neoforge"
type = "required"
versionRange = "[21.11,)"
ordering = "NONE"
side = "BOTH"

[[dependencies.mymod]]
modId = "minecraft"
type = "required"
versionRange = "[1.21.11,1.22)"
ordering = "NONE"
side = "BOTH"
```

---

## Build Commands

```bash
# Build both JARs simultaneously
./gradlew build

# Inspect the project's actual outputs. Generated templates choose their own
# archive base name and version convention:
find fabric/build/libs neoforge/build/libs -maxdepth 1 -type f -name '*.jar' \
  ! -name '*-sources.jar' ! -name '*-dev.jar' ! -name '*-javadoc.jar'

# Run in dev environment
./gradlew :fabric:runClient
./gradlew :neoforge:runClient
./gradlew :neoforge:runServer

# Datagen (if applicable)
./gradlew :neoforge:runData
```

---

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Using `net.neoforged.*` / `net.fabricmc.*` in `common/` | Only use vanilla MC and Architectury APIs in common |
| Direct field access on `DeferredRegister` (NeoForge style) in common | Use Architectury's `DeferredRegister` |
| Constructing a 26.2 item without a registry key | Create its `ResourceKey<Item>` and call `Item.Properties#setId` before `new Item` |
| Forgetting `@ExpectPlatform` throws `AssertionError` at runtime | Both `fabric/` and `neoforge/` must have matching same-package `*Impl` classes |
| Assets duplicated in fabric/ and neoforge/ | Keep assets in `common/src/main/resources/assets/` |
| A common Mixin imports a loader API or targets one loader's side | Put it in that platform subproject; loader-neutral Mixins may be common when both generated platform configurations include them |
| Accessing world/registry on mod init thread | Use `mod bus` events for setup; never access world on init |

---

## References

- Architectury API GitHub: https://github.com/architectury/architectury-api
- Architectury API 26.2 source branch: https://github.com/architectury/architectury-api/tree/26.2
- Architectury API 1.21.11 source branch: https://github.com/architectury/architectury-api/tree/1.21.11
- Architectury Loom: https://github.com/architectury/architectury-loom
- Architectury templates: https://github.com/architectury/architectury-templates
- Architectury Template Generator: https://generate.architectury.dev/
- Architectury docs: https://docs.architectury.dev/
