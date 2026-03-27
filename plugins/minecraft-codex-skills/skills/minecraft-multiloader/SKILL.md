---
name: minecraft-multiloader
description: >
  Build Minecraft mods targeting both NeoForge and Fabric simultaneously using the
  Architectury framework for Minecraft 1.21.x. Covers Architectury project structure
  (common/neoforge/fabric subprojects), ExpectPlatform annotation for platform-specific
  implementations, shared registry via Architectury's registration API, platform-specific
  entrypoints, architectury-loom Gradle plugin configuration, gradle.properties for both
  loaders, multi-jar publishing to Modrinth and CurseForge, and avoiding common pitfalls
  when sharing code. Use this skill when building a mod that must run on both NeoForge
  and Fabric with a single shared codebase.
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

## Versions (1.21.x)

```properties
# gradle.properties (root)
minecraft_version=1.21.1
enabled_platforms=fabric,neoforge

architectury_version=13.0.8
fabric_loader_version=0.16.9
fabric_api_version=0.114.0+1.21.1
neoforge_version=21.1.172

loom_version=1.9-SNAPSHOT
```

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
│       │   └── platform/
│       │       └── PlatformHelperImpl.java  ← Fabric implementation
│       └── resources/
│           ├── fabric.mod.json
│           └── assets/...
└── neoforge/
    ├── build.gradle
    └── src/main/
        ├── java/com/example/mymod/neoforge/
        │   ├── MyModNeoForge.java        ← NeoForge @Mod entry
        │   └── platform/
        │       └── PlatformHelperImpl.java  ← NeoForge implementation
        └── resources/
            ├── META-INF/neoforge.mods.toml
            └── assets/...
```

---

## Root `settings.gradle`

```groovy
pluginManagement {
    repositories {
        maven { url "https://maven.architectury.dev/" }
        maven { url "https://maven.fabricmc.net/" }
        maven { url "https://maven.neoforged.net/releases" }
        gradlePluginPortal()
    }
}

include "common"
include "fabric"
include "neoforge"
```

---

## Root `build.gradle`

```groovy
plugins {
    id "architectury-plugin" version "3.4-SNAPSHOT" apply false
    id "dev.architectury.loom" version "${loom_version}" apply false
    id "com.github.johnrengelman.shadow" version "8.1.1" apply false
}

architectury {
    minecraft = rootProject.minecraft_version
}

subprojects {
    apply plugin: "java"
    apply plugin: "architectury-plugin"

    group = "com.example.mymod"
    version = "${mod_version}+${minecraft_version}"
    archivesBaseName = "my-mod-${project.name}"

    repositories {
        maven { url "https://maven.architectury.dev/" }
        maven { url "https://mod-buildtools.pkg.github.com/TerraformersMC/" }
    }

    java {
        withSourcesJar()
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }
}
```

---

## `common/build.gradle`

```groovy
plugins {
    id "dev.architectury.loom" apply true
}

architectury {
    common(rootProject.enabled_platforms.split(","))
}

loom {
    // common project uses mappings only
}

dependencies {
    minecraft "com.mojang:minecraft:${rootProject.minecraft_version}"
    mappings loom.officialMojangMappings()

    modImplementation "dev.architectury:architectury-api:${rootProject.architectury_version}"
}
```

---

## `fabric/build.gradle`

```groovy
plugins {
    id "com.github.johnrengelman.shadow"
    id "dev.architectury.loom" apply true
}

architectury {
    platformSetupLoomIde()
    fabric()
}

loom {
    accessWidenerPath = project(":common").loom.accessWidenerPath
}

configurations {
    common
    shadowCommon
    compileClasspath.extendsFrom common
    runtimeClasspath.extendsFrom common
    developmentFabric.extendsFrom common
}

dependencies {
    minecraft "com.mojang:minecraft:${rootProject.minecraft_version}"
    mappings loom.officialMojangMappings()

    modImplementation "net.fabricmc:fabric-loader:${rootProject.fabric_loader_version}"
    modApi "net.fabricmc.fabric-api:fabric-api:${rootProject.fabric_api_version}"
    modApi "dev.architectury:architectury-api:${rootProject.architectury_version}:fabric"

    common(project(path: ":common", configuration: "namedElements")) { transitive false }
    shadowCommon(project(path: ":common", configuration: "transformProductionFabric")) { transitive false }
}

shadowJar {
    exclude "architectury.common.json"
    configurations = [project.configurations.shadowCommon]
    archiveClassifier = "dev-shadow"
}

remapJar {
    injectAccessWidener = true
    input.fileValue shadowJar.archiveFile.get().asFile
    dependsOn shadowJar
    archiveClassifier = ""
}

jar { archiveClassifier = "dev" }
sourcesJar { archiveClassifier = "dev-sources" }
components.java.withVariantsFromConfiguration(configurations.shadowRuntimeElements) { skip() }
```

---

## `neoforge/build.gradle`

```groovy
plugins {
    id "com.github.johnrengelman.shadow"
    id "dev.architectury.loom" apply true
}

architectury {
    platformSetupLoomIde()
    neoForge()
}

loom {
    accessWidenerPath = project(":common").loom.accessWidenerPath
}

configurations {
    common
    shadowCommon
    compileClasspath.extendsFrom common
    runtimeClasspath.extendsFrom common
    developmentNeoForge.extendsFrom common
}

dependencies {
    minecraft "com.mojang:minecraft:${rootProject.minecraft_version}"
    mappings loom.officialMojangMappings()

    neoForge "net.neoforged:neoforge:${rootProject.neoforge_version}"
    modApi "dev.architectury:architectury-api:${rootProject.architectury_version}:neoforge"

    common(project(path: ":common", configuration: "namedElements")) { transitive false }
    shadowCommon(project(path: ":common", configuration: "transformProductionNeoForge")) { transitive false }
}

shadowJar {
    exclude "architectury.common.json"
    configurations = [project.configurations.shadowCommon]
    archiveClassifier = "dev-shadow"
}

remapJar {
    input.fileValue shadowJar.archiveFile.get().asFile
    dependsOn shadowJar
    archiveClassifier = ""
}

jar { archiveClassifier = "dev" }
```

---

## Shared Common Code

### `common/.../MyMod.java`
```java
package com.example.mymod;

import dev.architectury.registry.registries.DeferredRegister;
import dev.architectury.registry.registries.RegistrySupplier;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.Item;

public class MyMod {
    public static final String MOD_ID = "mymod";

    // Architectury's DeferredRegister — works on both platforms
    public static final DeferredRegister<Item> ITEMS =
        DeferredRegister.create(MOD_ID, BuiltInRegistries.ITEM);

    public static final RegistrySupplier<Item> MY_ITEM =
        ITEMS.register("my_item", () -> new Item(new Item.Properties()));

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
    "fabricloader": ">=0.16.0",
    "fabric-api": "*",
    "architectury": ">=13.0.0",
    "minecraft": "~1.21"
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
loaderVersion = "[4,)"
license = "MIT"

[[mods]]
modId = "mymod"
version = "${file.jarVersion}"
displayName = "My Mod"
description = "A multiloader example mod"

[[dependencies.mymod]]
modId = "neoforge"
type = "required"
versionRange = "[21.1,)"
ordering = "NONE"
side = "BOTH"

[[dependencies.mymod]]
modId = "minecraft"
type = "required"
versionRange = "[1.21.1,)"
ordering = "NONE"
side = "BOTH"
```

---

## Build Commands

```bash
# Build both JARs simultaneously
./gradlew build

# Outputs:
#   fabric/build/libs/my-mod-fabric-1.0.0+1.21.1.jar
#   neoforge/build/libs/my-mod-neoforge-1.0.0+1.21.1.jar

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
| Forgetting `@ExpectPlatform` throws `AssertionError` at runtime | Both `fabric/` and `neoforge/` must have matching `*Impl` classes |
| Assets duplicated in fabric/ and neoforge/ | Keep assets in `common/src/main/resources/assets/` |
| Mixins in common — not supported on NeoForge | Put Mixins in the platform subprojects only |
| Accessing world/registry on mod init thread | Use `mod bus` events for setup; never access world on init |

---

## References

- Architectury API GitHub: https://github.com/architectury/architectury-api
- Architectury Loom: https://github.com/architectury/architectury-loom
- Architectury templates: https://github.com/architectury/architectury-templates
- Architectury docs: https://docs.architectury.dev/
