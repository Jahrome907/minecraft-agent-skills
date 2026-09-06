# Legacy Minecraft 1.21.5 Worldgen JSON

These examples target Minecraft 1.21.5. For another 1.21.x release, compare each
registry with that exact release's vanilla data or datagen output before adapting
it. Minecraft 1.21.11 and 26.x change worldgen and environment data; the broad
label "1.21.x" does not establish JSON schema compatibility.

## Biome and feature chain

Biome `features` has 11 arrays, one for each `GenerationStep.Decoration` index.
Ores belong at index 6, `underground_ores`. Each entry is a placed-feature id.

At `data/<namespace>/worldgen/biome/my_biome.json`:

```json
{
  "has_precipitation": true,
  "temperature": 0.7,
  "downfall": 0.8,
  "effects": {
    "sky_color": 7907327,
    "fog_color": 12638463,
    "water_color": 4159204,
    "water_fog_color": 329011
  },
  "spawners": {},
  "spawn_costs": {},
  "carvers": [],
  "features": [
    [], [], [], [], [], [],
    ["<namespace>:my_ore_placed"],
    [], [], [], []
  ]
}
```

At `data/<namespace>/worldgen/configured_feature/my_ore.json`:

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
        "state": { "Name": "minecraft:emerald_ore" }
      }
    ],
    "size": 4,
    "discard_chance_on_air_exposure": 0.0
  }
}
```

At `data/<namespace>/worldgen/placed_feature/my_ore_placed.json`:

```json
{
  "feature": "<namespace>:my_ore",
  "placement": [
    { "type": "minecraft:count", "count": 8 },
    { "type": "minecraft:in_square" },
    {
      "type": "minecraft:height_range",
      "height": {
        "type": "minecraft:trapezoid",
        "min_inclusive": { "above_bottom": 0 },
        "max_inclusive": { "absolute": 64 }
      }
    },
    { "type": "minecraft:biome" }
  ]
}
```

## Dimension and dimension type

At `data/<namespace>/dimension_type/my_type.json`:

```json
{
  "ultrawarm": false,
  "natural": true,
  "coordinate_scale": 1.0,
  "has_skylight": true,
  "has_ceiling": false,
  "ambient_light": 0.0,
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

At `data/<namespace>/dimension/my_dimension.json`:

```json
{
  "type": "<namespace>:my_type",
  "generator": {
    "type": "minecraft:noise",
    "biome_source": { "type": "minecraft:fixed", "biome": "<namespace>:my_biome" },
    "settings": "minecraft:overworld"
  }
}
```

Use `minecraft:multi_noise` only with a complete set of climate parameters from
a known-good 1.21 source. Keep the dimension type, noise settings, and every
referenced biome in the same compatibility lane.

## NeoForge biome modifier

At `data/<namespace>/neoforge/biome_modifier/add_ores.json`:

```json
{
  "type": "neoforge:add_features",
  "biomes": "#minecraft:is_overworld",
  "features": "<namespace>:my_ore_placed",
  "step": "underground_ores"
}
```

For a legacy `remove_features` modifier, `steps` is an array; for
`add_features`, use the singular `step`. Verify the exact minor version's
NeoForge documentation before hand-authoring other modifier types.

## Jigsaw structures

At `data/<namespace>/worldgen/structure/my_structure.json`:

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

At `data/<namespace>/worldgen/template_pool/my_pool/start.json`:

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

At `data/<namespace>/worldgen/structure_set/my_structures.json`:

```json
{
  "structures": [
    { "structure": "<namespace>:my_structure", "weight": 1 }
  ],
  "placement": {
    "type": "minecraft:random_spread",
    "spacing": 32,
    "separation": 8,
    "salt": 12345678
  }
}
```

The pool's `location` needs a matching
`data/<namespace>/structure/my_structure/start.nbt`; use a processor list other
than `minecraft:empty` only when its JSON exists and has been tested.
