---
name: minecraft-modding
description: "Full-stack Minecraft mod development skill for NeoForge (1.21+), Fabric (1.21+), and legacy Forge 1.20.1. Scaffolds new mods, adds custom blocks, items, entities, recipes, commands, GUIs, dimensions, and data generation. Knows NeoForge DeferredRegister + event-bus patterns, Forge 1.20.1 MDK/FMLJavaModLoadingContext patterns, and Fabric Registry + ModInitializer patterns. Use when the user asks to create a Minecraft mod, add a feature to an existing mod, fix a mod bug, generate JSON assets/data, support Forge 1.20.1, or migrate between modding platforms. Prefer NeoForge unless the user specifies Fabric, Forge 1.20.1, or Multiloader."
---

# Minecraft Modding Skill

## Overview

This skill guides Codex through developing open-source Minecraft mods.
Target platforms:

| Platform | MC Version | Java | Build System |
|---|---|---|---|
| **NeoForge** | 1.21.x with 1.21.11 examples | Java 21 | Gradle + ModDevGradle |
| **Forge** | 1.20.1 legacy lane | Java 17 | Gradle + ForgeGradle 6 |
| **Fabric** | 1.21.x with 1.21.11 examples | Java 21 | Gradle + Fabric Loom |
| **Architectury** (multiloader) | 1.21.x | Java 21 | Gradle + Architectury Loom |

Always confirm the platform and Minecraft version from `gradle.properties` or `build.gradle`
before writing any mod-specific code.

### Routing Boundaries
- `Use when`: the task is Java/Kotlin mod code, registry/event work, networking, datagen wiring, and loader APIs.
- `Do not use when`: the task is command-only vanilla logic (`minecraft-commands-scripting`) or pure datapacks (`minecraft-datapack`).
- `Do not use when`: the task targets Paper/Bukkit plugins (`minecraft-plugin-dev`).

---

## 1. Identifying the Platform

```bash
# NeoForge project signature
grep -r "net.neoforged" gradle.properties build.gradle settings.gradle 2>/dev/null | head -5

# Forge 1.20.1 project signature
grep -r "net.minecraftforge" gradle.properties build.gradle settings.gradle 2>/dev/null | head -5

# Fabric project signature
grep -r "fabric" gradle.properties build.gradle settings.gradle 2>/dev/null | head -5

# Read mod ID and version
cat gradle.properties
```

Key files per platform:

- **NeoForge**: `src/main/resources/META-INF/neoforge.mods.toml`, annotated `@Mod` main class
- **Forge 1.20.1**: `src/main/resources/META-INF/mods.toml`, `net.minecraftforge:forge` dependency
- **Fabric**: `src/main/resources/fabric.mod.json`, class implementing `ModInitializer`
- **Architectury**: `common/`, `fabric/`, `neoforge/` subprojects

---

## 2. Build & Test Commands

```bash
# Build the mod jar
./gradlew build

# Run the Minecraft client to test
./gradlew runClient

# Run a dedicated server to test
./gradlew runServer

# Run game tests (NeoForge JUnit-style game tests)
./gradlew runGameTestServer

# Run data generation (generates JSON assets automatically)
./gradlew runData

# Clean build cache
./gradlew clean

# Check for dependency updates (optional)
./gradlew dependencyUpdates
```

After `./gradlew build`, the mod jar is at:
`build/libs/<mod_id>-<version>.jar`

---

## 3. Project Layout (NeoForge)

```
src/
  main/
    java/<groupId>/<modid>/
      MyMod.java               ← @Mod entry point
      block/
        ModBlocks.java         ← DeferredRegister<Block>
        MyCustomBlock.java
      item/
        ModItems.java          ← DeferredRegister<Item>
      entity/
        ModEntities.java       ← DeferredRegister<EntityType<?>>
      menu/                    ← custom GUI containers
      recipe/
      worldgen/
      datagen/
        ModDataGen.java        ← GatherDataEvent handler
        providers/
    resources/
      META-INF/
        neoforge.mods.toml     ← mod metadata (renamed from mods.toml in NeoForge 1.20.5+)
      assets/<modid>/
        blockstates/           ← JSON blockstate definitions
        models/
          block/               ← block model JSON
          item/                ← item model JSON
        textures/
          block/               ← 16×16 PNG textures
          item/
        lang/
          en_us.json           ← translation strings
      data/<modid>/
        recipes/               ← crafting recipe JSON
        loot_table/
          blocks/              ← per-block loot table JSON
        tags/
          blocks/
          items/
```

## 4. Project Layout (Forge 1.20.1)

Use this layout only when `minecraft_version=1.20.1` and the project depends on
`net.minecraftforge:forge`. Forge 1.20.1 is not NeoForge: keep `mods.toml`,
`net.minecraftforge.*` imports, Java 17, and ForgeGradle 6 patterns.

```
src/
  main/
    java/<groupId>/<modid>/
      MyMod.java               <- @Mod entry point
      block/
        ModBlocks.java         <- DeferredRegister<Block>
      item/
        ModItems.java          <- DeferredRegister<Item>
      datagen/
        ModDataGen.java        <- GatherDataEvent handler
    resources/
      META-INF/
        mods.toml              <- Forge metadata
      assets/<modid>/          <- client assets
      data/<modid>/            <- server data using 1.20.1 paths
```

See `references/forge-1.20.1-api.md` before editing Forge 1.20.1 projects.

## 5. Project Layout (Fabric)

```
src/
  main/
    java/<groupId>/<modid>/
      MyMod.java               ← implements ModInitializer
      client/
        MyModClient.java       ← implements ClientModInitializer
      block/
      item/
      mixin/                   ← Mixin classes
    resources/
      fabric.mod.json
      assets/<modid>/          ← same as NeoForge
      data/<modid>/            ← same as NeoForge
      <modid>.mixins.json      ← mixin configuration
```

---

## 6. Core Concepts Cheatsheet

### Sides
- **Physical client** – the game client JAR (has rendering code)
- **Physical server** – the dedicated server JAR (no rendering)
- **Logical client** – the client thread (handles rendering, input)
- **Logical server** – the server thread (handles world simulation)
- Code decorated with `@OnlyIn(Dist.CLIENT)` (NeoForge) or `@Environment(EnvType.CLIENT)` (Fabric)
  must NEVER run on the server.

### Registries
Everything in Minecraft lives in a registry. Always register objects; never
construct them at field initializer time outside a registry call. Use the
mapping-appropriate registry constants for the loader you are editing:

| Type | NeoForge / Mojang mappings | Fabric / Yarn mappings |
|------|-----------------------------|-------------------------|
| Blocks | `BuiltInRegistries.BLOCK` | `Registries.BLOCK` |
| Items | `BuiltInRegistries.ITEM` | `Registries.ITEM` |
| Entity types | `BuiltInRegistries.ENTITY_TYPE` | `Registries.ENTITY_TYPE` |
| Block entity types | `BuiltInRegistries.BLOCK_ENTITY_TYPE` | `Registries.BLOCK_ENTITY_TYPE` |
| Menu / screen-handler types | `BuiltInRegistries.MENU` | `Registries.SCREEN_HANDLER` |
| Sound events | `BuiltInRegistries.SOUND_EVENT` | `Registries.SOUND_EVENT` |
| Biomes | `Registries.BIOME` registry keys | `RegistryKeys.BIOME` registry keys |

Do not copy older `Registry.BLOCK` / `Registry.ITEM` constants into 1.21.x code;
those names are stale for the examples in this skill.

### ResourceLocation / Identifier
Every registry entry needs a namespaced ID:
```java
// NeoForge / vanilla Java
ResourceLocation id = ResourceLocation.fromNamespaceAndPath("mymod", "my_block");

// Fabric with Yarn mappings
Identifier id = Identifier.of("mymod", "my_block");
```

---

## 7. NeoForge Quick Patterns

See full patterns in `references/neoforge-api.md`.

```java
// Main mod class
@Mod(MyMod.MOD_ID)
public class MyMod {
    public static final String MOD_ID = "mymod";

    public MyMod(IEventBus modEventBus) {
        ModBlocks.BLOCKS.register(modEventBus);
        ModItems.ITEMS.register(modEventBus);
        modEventBus.addListener(this::commonSetup);
    }

    private void commonSetup(FMLCommonSetupEvent event) {
        // runs after all mods are registered
    }
}
```

```java
// Block registration
public class ModBlocks {
    public static final DeferredRegister<Block> BLOCKS =
        DeferredRegister.create(BuiltInRegistries.BLOCK, MyMod.MOD_ID);

    public static final DeferredBlock<Block> MY_BLOCK =
        BLOCKS.registerSimpleBlock("my_block",
            BlockBehaviour.Properties.of()
                .mapColor(MapColor.STONE)
                .strength(1.5f, 6.0f)
                .sound(SoundType.STONE)
                .requiresCorrectToolForDrops());
}
```

---

## 8. Forge 1.20.1 Quick Patterns

See full patterns in `references/forge-1.20.1-api.md`.

```java
// Main mod class
@Mod(MyMod.MOD_ID)
public class MyMod {
    public static final String MOD_ID = "mymod";

    public MyMod(FMLJavaModLoadingContext context) {
        IEventBus modEventBus = context.getModEventBus();
        ModBlocks.BLOCKS.register(modEventBus);
        ModItems.ITEMS.register(modEventBus);
        modEventBus.addListener(this::commonSetup);
        MinecraftForge.EVENT_BUS.register(this);
    }

    private void commonSetup(FMLCommonSetupEvent event) {
        // runs after registries are prepared
    }
}
```

```java
// Block registration
public class ModBlocks {
    public static final DeferredRegister<Block> BLOCKS =
        DeferredRegister.create(ForgeRegistries.BLOCKS, MyMod.MOD_ID);

    public static final RegistryObject<Block> MY_BLOCK =
        BLOCKS.register("my_block", () -> new Block(
            BlockBehaviour.Properties.of()
                .mapColor(MapColor.STONE)
                .strength(1.5f, 6.0f)
                .sound(SoundType.STONE)
                .requiresCorrectToolForDrops()));
}
```

---
## 9. Fabric Quick Patterns

See full patterns in `references/fabric-api.md`.

```java
// Main mod class
public class MyMod implements ModInitializer {
    public static final String MOD_ID = "mymod";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    @Override
    public void onInitialize() {
        ModBlocks.register();
        ModItems.register();
    }
}
```

```java
// Block registration
public class ModBlocks {
    public static final Block MY_BLOCK = new Block(
        AbstractBlock.Settings.create()
            .mapColor(MapColor.STONE)
            .strength(1.5f, 6.0f)
            .sounds(BlockSoundGroup.STONE)
            .requiresTool()
    );

    public static void register() {
        Registry.register(Registries.BLOCK,
            Identifier.of(MyMod.MOD_ID, "my_block"), MY_BLOCK);
    }
}
```

---

## 10. JSON Asset Templates

Always provide matching JSON assets for every registered block/item.
Codex should generate or update these files alongside Java code.
For Forge 1.20.1, check `references/forge-1.20.1-api.md` for legacy server-data
directory names before creating loot tables or tags.

See `references/common-patterns.md` for full JSON templates for:
- Blockstate JSON
- Block model JSON (cube, slab, stairs, fence, door, trapdoor, etc.)
- Item model JSON
- Loot table JSON
- Recipe JSON (crafting_shaped, crafting_shapeless, smelting, blasting, stonecutting)
- Language file (`en_us.json`) entries
- Tag JSON

---

## 11. Data Generation

Prefer data generation over hand-authored JSON for maintainability.

```java
// NeoForge – register data gen providers in GatherDataEvent
@SubscribeEvent
public static void gatherData(GatherDataEvent event) {
    DataGenerator gen = event.getGenerator();
    PackOutput output = gen.getPackOutput();
    ExistingFileHelper helper = event.getExistingFileHelper();
    CompletableFuture<HolderLookup.Provider> lookupProvider = event.getLookupProvider();

    gen.addProvider(event.includeClient(), new ModBlockStateProvider(output, helper));
    gen.addProvider(event.includeClient(), new ModItemModelProvider(output, helper));
    gen.addProvider(event.includeServer(), new ModRecipeProvider(output, lookupProvider));
    gen.addProvider(event.includeServer(), new ModLootTableProvider(output, lookupProvider));
    gen.addProvider(event.includeServer(), new ModBlockTagsProvider(output, lookupProvider, helper));
}
```

Run data generation with `./gradlew runData`, then commit the generated files.
For Forge 1.20.1, use the mod-event-bus registration, `GatherDataEvent`
signature, provider classes, and legacy output paths from
`references/forge-1.20.1-api.md`.

---

## 12. Common Tasks Checklist

When adding a **new block**:
- [ ] `Block` subclass (or use vanilla Block with properties)
- [ ] Register in `ModBlocks.BLOCKS` / `Registries.BLOCK`
- [ ] Register `BlockItem` in `ModItems.ITEMS` / `Registries.ITEM`
- [ ] Blockstate JSON → `assets/<modid>/blockstates/<name>.json`
- [ ] Block model JSON → `assets/<modid>/models/block/<name>.json`
- [ ] Item model JSON → `assets/<modid>/models/item/<name>.json` (or inherits from block)
- [ ] Texture PNG → `assets/<modid>/textures/block/<name>.png`
- [ ] Loot table JSON -> 1.21.x: `data/<modid>/loot_table/blocks/<name>.json`; Forge 1.20.1: `data/<modid>/loot_tables/blocks/<name>.json`
- [ ] Tags -> 1.21.x: `data/<modid>/tags/block/` and `tags/item/`; Forge 1.20.1: `data/<modid>/tags/blocks/` and `tags/items/`
- [ ] Language entry in `en_us.json`
- [ ] Mine-with-correct-tool tag if hardness > 0
- [ ] Do not mix Forge 1.20.1 plural server-data paths with 1.21.x singular server-data paths

When adding a **new item**:
- [ ] `Item` subclass (or use `new Item(properties)`)
- [ ] Register in `ModItems` / `Registries.ITEM`
- [ ] Item model JSON
- [ ] Texture PNG
- [ ] Language entry
- [ ] Creative tab registration (NeoForge/Forge: `BuildCreativeModeTabContentsEvent`; Fabric: `ItemGroupEvents`)
- [ ] Recipe JSON if craftable

When adding a **new entity**:
- [ ] Entity class (extends appropriate base: `Mob`, `Animal`, `TamableAnimal`, etc.)
- [ ] `EntityType` registration
- [ ] Renderer class (`@OnlyIn(Dist.CLIENT)`)
- [ ] Model class (`@OnlyIn(Dist.CLIENT)`)
- [ ] Register renderer in `EntityRenderersEvent.RegisterRenderers` (NeoForge) or
      `EntityModelLayerRegistry` (Fabric)
- [ ] Spawn egg item (optional)
- [ ] Spawn rules / biome modifier

---

## 13. Open-Source Conventions

- **License**: MIT or LGPL-3.0 — include `LICENSE` file and `SPDX-License-Identifier` header
- **Versioning**: `{mod_version}+{mc_version}` (e.g., `2.0.0+1.21.11`)
- **Changelog**: Keep `CHANGELOG.md` up to date with semver notes
- **Publishing**: Use `gradle-modrinth` or `curseforgegradle` plugins for CurseForge / Modrinth
- **CI**: GitHub Actions with `./gradlew build` and `./gradlew runGameTestServer`
- **PR conventions**: Keep PRs scoped to a single feature; include asset files with Java changes

---

## 14. References

- NeoForge API patterns and event system: `./references/neoforge-api.md`
- Forge 1.20.1 API patterns and MDK workflow: `./references/forge-1.20.1-api.md`
- Fabric API patterns and mixin guide: `./references/fabric-api.md`
- Blocks, items, recipes, commands, GUIs, datagen: `./references/common-patterns.md`
- NeoForge official docs: https://docs.neoforged.net/
- Fabric developer docs: https://docs.fabricmc.net/develop/
- Architectury (multiloader): https://docs.architectury.dev/
- Minecraft Wiki (data formats): https://minecraft.wiki/w/Java_Edition_data_values
