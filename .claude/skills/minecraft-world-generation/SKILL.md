---
name: minecraft-world-generation
description: >
  Create custom world generation content for Minecraft 1.21.x including custom biomes,
  dimensions, noise settings, surface rules, placed/configured features, carvers,
  structure sets, and biome modifiers. Covers both the datapack-only approach (JSON
  worldgen files) and the mod-code approach (NeoForge BiomeModifiers, Fabric BiomeModification
  API, code-driven worldgen registration with DeferredRegister). Includes the full JSON
  schema for biome files, noise_settings overrides, placed_feature, configured_feature,
  structure, structure_set, and processor_list files. Targets Minecraft 1.21.x with
  official Mojang mappings.
---

# Minecraft World Generation Skill

## Two Approaches to Custom Worldgen

| Approach | Best When | Platform |
|----------|-----------|----------|
| **Datapack JSON** | Overriding/extending vanilla worldgen | Vanilla, any server |
| **Mod + Datagen** | Registering new biomes/dimensions, code-driven | NeoForge / Fabric |
| **Biome Modifier (NeoForge)** | Adding features/spawns to existing biomes | NeoForge |
| **BiomeModification API (Fabric)** | Adding features/spawns to existing biomes | Fabric |

### Routing Boundaries
- `Use when`: the task is biome/dimension/feature/structure worldgen design or registration.
- `Do not use when`: the task is general non-worldgen datapack work (recipes, advancements, predicates, function orchestration) (`minecraft-datapack`).
- `Do not use when`: the task is non-worldgen mod systems (items, entities, GUI, gameplay logic) (`minecraft-modding`).

---

## Directory Layout (Datapack / Mod Resources)

```
data/<namespace>/
├── worldgen/
│   ├── biome/
│   │   └── my_biome.json
│   ├── configured_feature/
│   │   └── my_ore.json
│   ├── placed_feature/
│   │   └── my_ore_placed.json
│   ├── noise_settings/
│   │   └── my_dimension_noise.json
│   ├── density_function/
│   │   └── my_density.json    (advanced)
│   ├── structure/
│   │   └── my_structure.json
│   ├── structure_set/
│   │   └── my_structures.json
│   ├── processor_list/
│   │   └── my_processors.json
│   ├── template_pool/
│   │   └── my_pool.json
│   └── carver/
│       └── my_carver.json
├── dimension/
│   └── my_dimension.json
├── dimension_type/
│   └── my_type.json
├── tags/
│   └── worldgen/
│       └── biome/
│           └── is_forest.json
└── neoforge/
    └── biome_modifier/      (NeoForge mod only)
        └── add_ores.json
```

---

## Custom Biome JSON

### `data/<namespace>/worldgen/biome/my_biome.json`
```json
{
  "has_precipitation": true,
  "temperature": 0.7,
  "temperature_modifier": "none",
  "downfall": 0.8,
  "effects": {
    "sky_color": 7907327,
    "fog_color": 12638463,
    "water_color": 4159204,
    "water_fog_color": 329011,
    "grass_color_modifier": "none",
    "ambient_sound": "minecraft:ambient.cave",
    "mood_sound": {
      "sound": "minecraft:ambient.cave",
      "tick_delay": 6000,
      "block_search_extent": 8,
      "offset": 2.0
    }
  },
  "spawners": {
    "monster": [
      { "type": "minecraft:zombie", "weight": 95, "minCount": 4, "maxCount": 4 },
      { "type": "minecraft:skeleton", "weight": 100, "minCount": 4, "maxCount": 4 }
    ],
    "creature": [
      { "type": "minecraft:sheep", "weight": 12, "minCount": 4, "maxCount": 4 }
    ],
    "ambient": [],
    "axolotls": [],
    "underground_water_creature": [],
    "water_creature": [],
    "water_ambient": [],
    "misc": []
  },
  "spawn_costs": {},
  "carvers": {
    "air": ["minecraft:cave", "minecraft:cave_extra_underground", "minecraft:canyon"]
  },
  "features": [
    [],
    [],
    ["minecraft:lake_lava_underground", "minecraft:lake_lava_surface"],
    ["minecraft:amethyst_geode", "minecraft:monster_room"],
    [],
    [],
    [
      "minecraft:ore_dirt", "minecraft:ore_gravel", "minecraft:ore_granite_upper",
      "minecraft:ore_coal_upper", "minecraft:ore_coal_lower",
      "<namespace>:my_ore_placed"
    ],
    [],
    ["minecraft:spring_lava"],
    [],
    ["minecraft:freeze_top_layer"]
  ]
}
```

> The `features` array has exactly 11 slots (indices 0–10), one per `GenerationStep.Decoration`:
>
> | Index | Step | Put here |
> |-------|------|---------|
> | 0 | `RAW_GENERATION` | (rarely used) |
> | 1 | `LAKES` | Surface water/lava lakes |
> | 2 | `LOCAL_MODIFICATIONS` | Underground lava lakes, geodes |
> | 3 | `UNDERGROUND_STRUCTURES` | Amethyst geodes, dungeons |
> | 4 | `SURFACE_STRUCTURES` | Glaciers, blue ice patches |
> | 5 | `STRONGHOLDS` | (unused in biome JSON) |
> | 6 | `UNDERGROUND_ORES` | **All ores go here** |
> | 7 | `UNDERGROUND_DECORATION` | Fossils, infested stone |
> | 8 | `FLUID_SPRINGS` | `spring_water`, `spring_lava` |
> | 9 | `VEGETAL_DECORATION` | Trees, grass, flowers |
> | 10 | `TOP_LAYER_MODIFICATION` | `freeze_top_layer` |
>
> Custom ores added via placed features must be placed at index **6**.

---

## Configured Feature

### `data/<namespace>/worldgen/configured_feature/my_ore.json`
```json
{
  "type": "minecraft:ore",
  "config": {
    "targets": [
      {
        "target": {
          "predicate_type": "minecraft:tag_match",
          "tag": "minecraft:stone_ore_replaceables"
        },
        "state": {
          "Name": "minecraft:emerald_ore"
        }
      }
    ],
    "size": 4,
    "discard_chance_on_air_exposure": 0.0
  }
}
```

### Other feature types
| Type | Use |
|------|-----|
| `minecraft:ore` | Ore veins |
| `minecraft:tree` | Tree placement |
| `minecraft:random_patch` | Grass, flowers, mushrooms |
| `minecraft:block_pile` | Hay bales, pumpkins |
| `minecraft:lake` | Water/lava lakes |
| `minecraft:disk` | Sand/gravel/clay disks |
| `minecraft:no_bonemeal_flower` | Wither roses, etc. |
| `minecraft:simple_block` | Single block placement |
| `minecraft:fill_layer` | Fill an entire layer |
| `minecraft:geode` | Amethyst geodes |
| `minecraft:decorated` | Wraps another feature with placement |

---

## Placed Feature

### `data/<namespace>/worldgen/placed_feature/my_ore_placed.json`
```json
{
  "feature": "<namespace>:my_ore",
  "placement": [
    {
      "type": "minecraft:count",
      "count": 8
    },
    {
      "type": "minecraft:in_square"
    },
    {
      "type": "minecraft:height_range",
      "height": {
        "type": "minecraft:trapezoid",
        "min_inclusive": { "above_bottom": 0 },
        "max_inclusive": { "absolute": 64 }
      }
    },
    {
      "type": "minecraft:biome"
    }
  ]
}
```

### Common placement modifiers
| Type | Effect |
|------|--------|
| `minecraft:count` | Number of attempts |
| `minecraft:count_on_every_layer` | Per layer |
| `minecraft:in_square` | Randomize X/Z within chunk |
| `minecraft:biome` | Only place if biome has this feature |
| `minecraft:height_range` | Y-level range |
| `minecraft:surface_relative_threshold_filter` | Filter by surface depth |
| `minecraft:noise_based_count` | Count varies with noise |
| `minecraft:rarity_filter` | 1-in-N chance |
| `minecraft:environment_scan` | Scans up/down for a condition |

---

## Dimension Type

### `data/<namespace>/dimension_type/my_type.json`
```json
{
  "ultrawarm": false,
  "natural": true,
  "coordinate_scale": 1.0,
  "has_skylight": true,
  "has_ceiling": false,
  "ambient_light": 0.0,
  "fixed_time": false,
  "monster_spawn_light_level": {
    "type": "minecraft:uniform",
    "min_inclusive": 0,
    "max_inclusive": 7
  },
  "monster_spawn_block_light_limit": 0,
  "piglin_safe": false,
  "bed_works": true,
  "respawn_anchor_works": false,
  "has_raids": true,
  "logical_height": 384,
  "height": 384,
  "min_y": -64,
  "infiniburn": "#minecraft:infiniburn_overworld",
  "effects": "minecraft:overworld"
}
```

---

## Custom Dimension

### `data/<namespace>/dimension/my_dimension.json`
```json
{
  "type": "<namespace>:my_type",
  "generator": {
    "type": "minecraft:noise",
    "biome_source": {
      "type": "minecraft:fixed",
      "biome": "<namespace>:my_biome"
    },
    "settings": "minecraft:overworld"
  }
}
```

### Multi-biome dimension with `minecraft:multi_noise` source
```json
{
  "type": "<namespace>:my_type",
  "generator": {
    "type": "minecraft:noise",
    "biome_source": {
      "type": "minecraft:multi_noise",
      "biomes": [
        {
          "parameters": {
            "temperature": [ -1.0, -0.45 ],
            "humidity":    [ -1.0, -0.35 ],
            "continentalness": [ -1.2, -1.05 ],
            "erosion":     [ -0.78, 0.0 ],
            "weirdness":   [ 0.0, 0.0 ],
            "depth":       [ 0.0, 0.0 ],
            "offset":      0.0
          },
          "biome": "<namespace>:my_biome"
        }
      ]
    },
    "settings": "minecraft:overworld"
  }
}
```

---

## NeoForge: Biome Modifier

Biome Modifiers let you add features, spawns, or carvers to existing biomes without
replacing the biome JSON.

### JSON biome modifier (`data/<namespace>/neoforge/biome_modifier/add_ores.json`)
```json
{
  "type": "neoforge:add_features",
  "biomes": "#minecraft:is_overworld",
  "features": "<namespace>:my_ore_placed",
  "step": "underground_ores"
}
```

### Other NeoForge biome modifier types
```json
{ "type": "neoforge:add_spawns", "biomes": "#minecraft:is_forest",
  "spawners": [{ "type": "minecraft:wolf", "weight": 5, "minCount": 2, "maxCount": 4 }] }

{ "type": "neoforge:remove_features", "biomes": "#minecraft:is_plains",
  "features": "minecraft:ore_coal_upper", "steps": ["underground_ores"] }

{ "type": "neoforge:remove_spawns", "biomes": "#minecraft:is_ocean",
  "entity_types": "#minecraft:skeletons" }
```

---

## Fabric: BiomeModification API (Code)

```java
import net.fabricmc.fabric.api.biome.v1.BiomeModifications;
import net.fabricmc.fabric.api.biome.v1.BiomeSelectors;
import net.minecraft.world.level.levelgen.GenerationStep;

public class MyModWorldgen {
    public static void init() {
        // Add a placed feature to all overworld biomes
        BiomeModifications.addFeature(
            BiomeSelectors.foundInOverworld(),
            GenerationStep.Decoration.UNDERGROUND_ORES,
            ResourceKey.create(
                Registries.PLACED_FEATURE,
                ResourceLocation.fromNamespaceAndPath(MyMod.MOD_ID, "my_ore_placed")
            )
        );

        // Add mob spawns
        BiomeModifications.addSpawn(
            BiomeSelectors.tag(BiomeTags.IS_FOREST),
            MobCategory.CREATURE,
            EntityType.WOLF,
            5, 2, 4
        );
    }
}
```

---

## Mod-Registered Worldgen (NeoForge + Fabric via Datagen)

### Register worldgen keys in code
```java
// In a dedicated worldgen registry class
public class ModWorldgen {
    public static final ResourceKey<Biome> MY_BIOME = ResourceKey.create(
        Registries.BIOME,
        ResourceLocation.fromNamespaceAndPath(MyMod.MOD_ID, "my_biome")
    );

    public static final ResourceKey<PlacedFeature> MY_ORE_PLACED = ResourceKey.create(
        Registries.PLACED_FEATURE,
        ResourceLocation.fromNamespaceAndPath(MyMod.MOD_ID, "my_ore_placed")
    );
}
```

### Datagen: NeoForge (`DatapackBuiltinEntriesProvider`)

```java
public class ModWorldgenProvider extends DatapackBuiltinEntriesProvider {

    private static final RegistrySetBuilder BUILDER = new RegistrySetBuilder()
        .add(Registries.CONFIGURED_FEATURE, ModWorldgenProvider::bootstrapConfigured)
        .add(Registries.PLACED_FEATURE, ModWorldgenProvider::bootstrapPlaced);

    public ModWorldgenProvider(PackOutput output, CompletableFuture<HolderLookup.Provider> registries) {
        super(output, registries, BUILDER, Set.of(MyMod.MOD_ID));
    }

    private static void bootstrapConfigured(BootstrapContext<ConfiguredFeature<?, ?>> ctx) {
        ctx.register(
            ModWorldgen.MY_ORE_CONFIGURED,
            new ConfiguredFeature<>(Feature.ORE, new OreConfiguration(
                OreConfiguration.target(
                    new TagMatchTest(BlockTags.STONE_ORE_REPLACEABLES),
                    ModBlocks.MY_ORE.get().defaultBlockState()
                ),
                9  // vein size
            ))
        );
    }

    private static void bootstrapPlaced(BootstrapContext<PlacedFeature> ctx) {
        HolderGetter<ConfiguredFeature<?, ?>> configured =
            ctx.lookup(Registries.CONFIGURED_FEATURE);
        ctx.register(
            ModWorldgen.MY_ORE_PLACED,
            new PlacedFeature(
                configured.getOrThrow(ModWorldgen.MY_ORE_CONFIGURED),
                List.of(
                    HeightRangePlacement.triangle(
                        VerticalAnchor.absolute(-64),
                        VerticalAnchor.absolute(32)
                    ),
                    CountPlacement.of(8),
                    InSquarePlacement.spread(),
                    BiomeFilter.biome()
                )
            )
        );
    }
}
```

Register in your `GatherDataEvent` handler:
```java
@SubscribeEvent
public static void onGatherData(GatherDataEvent event) {
    DataGenerator gen = event.getGenerator();
    PackOutput output = gen.getPackOutput();
    gen.addProvider(event.includeServer(),
        new ModWorldgenProvider(output, event.getLookupProvider()));
}
```

### Datagen: Fabric (`FabricDynamicRegistryProvider`)

```java
public class ModWorldgenProvider extends FabricDynamicRegistryProvider {

    public ModWorldgenProvider(FabricDataOutput output, CompletableFuture<HolderLookup.Provider> registries) {
        super(output, registries);
    }

    @Override
    protected void configure(HolderLookup.Provider registries, Entries entries) {
        entries.addAll(registries.lookupOrThrow(Registries.CONFIGURED_FEATURE));
        entries.addAll(registries.lookupOrThrow(Registries.PLACED_FEATURE));
    }

    @Override
    public String getName() {
        return "Worldgen";
    }
}
```

---

## Custom Structure

### `data/<namespace>/worldgen/structure/my_structure.json`
```json
{
  "type": "minecraft:jigsaw",
  "biomes": "#<namespace>:my_biome_tag",
  "step": "surface_structures",
  "terrain_adaptation": "beard_thin",
  "start_pool": "<namespace>:my_pool/start",
  "size": 6,
  "max_distance_from_center": 80,
  "use_expansion_hack": false,
  "spawn_overrides": {}
}
```

### Template pool for jigsaw structures
```json
{
  "fallback": "minecraft:empty",
  "elements": [
    {
      "weight": 1,
      "element": {
        "element_type": "minecraft:single_pool_element",
        "location": "<namespace>:my_structure/start",
        "projection": "rigid",
        "processors": "minecraft:empty"
      }
    }
  ]
}
```

---

## Structure Set

### `data/<namespace>/worldgen/structure_set/my_structures.json`
```json
{
  "structures": [
    {
      "structure": "<namespace>:my_structure",
      "weight": 1
    }
  ],
  "placement": {
    "type": "minecraft:random_spread",
    "spacing": 32,
    "separation": 8,
    "salt": 12345678
  }
}
```

---

## Testing Worldgen

```bash
# Create a new world with datapack loaded
# In-game with a mod:
/locate structure <namespace>:my_structure
/locate biome <namespace>:my_biome
/placefeature <namespace>:my_ore_placed

# Reload worldgen data (does not affect already-generated chunks)
/reload

# For dimension testing — must use /execute in <namespace>:my_dimension
execute in <namespace>:my_dimension run tp @s 0 100 0
```

## Validator Script

Use the bundled validator before shipping worldgen JSON changes:

```bash
# Run from the installed skill directory (for example `.agents/skills/minecraft-world-generation`):
./scripts/validate-worldgen-json.sh --root /path/to/datapack-or-mod-resources

# Strict mode treats warnings as failures:
./scripts/validate-worldgen-json.sh --root /path/to/datapack-or-mod-resources --strict
```

What it checks:
- JSON validity for `worldgen/**` and `neoforge/biome_modifier/**`
- Cross-reference integrity for `placed_feature -> configured_feature`
- Cross-reference integrity for `structure_set -> structure` and biome/biome_modifier feature targets

---

## References

- Minecraft Wiki — World generation: https://minecraft.wiki/w/Custom_world_generation
- Minecraft Wiki — Biome: https://minecraft.wiki/w/Biome/JSON_format
- Minecraft Wiki — Features: https://minecraft.wiki/w/World_generation/Configured_feature
- NeoForge Biome Modifiers: https://docs.neoforged.net/docs/worldgen/biomemodifier/
- Fabric BiomeModifications: https://wiki.fabricmc.net/tutorial:biomemodification
- misode's data pack generator (worldgen UI): https://misode.github.io/worldgen/
