---
name: minecraft-datapack
description: "Create, edit, and debug Minecraft vanilla datapacks for 1.21.x. Covers the full datapack format: pack.mcmeta, function files (.mcfunction), advancements, predicates, loot tables, item modifiers, recipe overrides, tags, damage types, dimension types, worldgen overrides, and structure sets. Handles function syntax, execute command chains, macro functions (1.20.2+), storage NBT, scoreboard operations, advancement triggers, pack format numbers, and /reload workflow. No Java or mod loader required — pure vanilla JSON and .mcfunction files. Use when creating or editing Minecraft datapacks, writing .mcfunction files, configuring loot tables or advancements, or any vanilla datapack development that does not need mod loaders."
---

# Minecraft Datapack Skill

## Skill Scope

### Routing Boundaries
- `Use when`: the deliverable is datapack files (`pack.mcmeta`, `data/...`) and `.mcfunction`/JSON content.
- `Do not use when`: the request is command-only snippets not tied to a datapack file tree (`minecraft-commands-scripting`).
- `Do not use when`: the request requires loader APIs, Java code, or runtime mod behavior (`minecraft-modding`).

---

## Pack Metadata (1.21.x)

| Minecraft Version | Preferred `pack` metadata |
|-------------------|---------------------------|
| 1.21 / 1.21.1     | `pack_format: 48` |
| 1.21.2 / 1.21.3   | `pack_format: 57` |
| 1.21.4            | `pack_format: 61` |
| 1.21.5            | `pack_format: 71` |
| 1.21.6            | `pack_format: 80` |
| 1.21.7 / 1.21.8   | `pack_format: 81` |
| 1.21.9 / 1.21.10  | `min_format: [88, 0]`, `max_format: [88, 0]` |
| 1.21.11           | `min_format: [94, 1]`, `max_format: [94, 1]` |

Use `pack_format` through 1.21.8. Starting in 1.21.9, Mojang replaced that
single field with explicit `min_format` / `max_format` values.
For exact patch targeting, use `[major, minor]` arrays for both `min_format` and
`max_format`, including `.0` versions such as `[88, 0]`. A single integer is
equivalent to `[major, 0]` for `min_format`, while a single integer in
`max_format` allows any minor version on that major line. Do not write decimal
JSON numbers such as `94.1`.

Keep `pack.mcmeta` exact for the patch you target instead of trying to span the
entire 1.21.x line with one metadata block.

---

## Directory Layout

```
my-datapack/
├── pack.mcmeta
└── data/
    └── <namespace>/           ← use your pack's name (e.g., mypack)
        ├── function/
        │   ├── main.mcfunction
        │   └── tick.mcfunction
        ├── advancement/
        │   └── custom_advancement.json
        ├── recipe/
        │   └── custom_recipe.json
        ├── loot_table/
        │   └── custom_loot.json
        ├── predicate/
        │   └── is_night.json
        ├── item_modifier/
        │   └── add_name.json
        └── tags/
            ├── block/
            │   └── climbable.json
            ├── entity_type/
            │   └── bosses.json
            └── function/
                ├── load.json     ← runs on /reload
                └── tick.json     ← runs every game tick
```

---

## `pack.mcmeta`

### 1.21.8 and earlier

```json
{
  "pack": {
    "pack_format": 81,
    "description": "My Custom Datapack v1.0"
  }
}
```

### 1.21.9 / 1.21.10

```json
{
  "pack": {
    "min_format": [88, 0],
    "max_format": [88, 0],
    "description": "My Custom Datapack v1.0"
  }
}
```

### 1.21.11

```json
{
  "pack": {
    "min_format": [94, 1],
    "max_format": [94, 1],
    "description": "My Custom Datapack v1.0"
  }
}
```

---

## Function Tags (load / tick)

### `data/<namespace>/tags/function/load.json`
```json
{
  "values": [
    "<namespace>:setup"
  ]
}
```

### `data/<namespace>/tags/function/tick.json`
```json
{
  "values": [
    "<namespace>:tick"
  ]
}
```

### `data/<namespace>/function/setup.mcfunction`
```mcfunction
# Runs once on /reload
scoreboard objectives add deaths deathCount
scoreboard objectives add kills playerKillCount
tellraw @a {"text":"[MyPack] Loaded!","color":"green"}
```

### `data/<namespace>/function/tick.mcfunction`
```mcfunction
# Runs every tick — KEEP THIS SHORT
# Only put fast, targeted operations here
execute as @a[scores={deaths=1..}] run function mypack:on_death_check
```

---

## Commands and Function Syntax

### Execute subcommands (datapack-specific patterns)
```mcfunction
# Chained execute — common datapack pattern for conditional per-player logic
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ #minecraft:logs run give @s minecraft:apple

# store result into score (bridge between NBT world and scoreboard state)
execute store result score @s mypack.health run data get entity @s Health

# in: run logic in another dimension
execute in minecraft:the_nether run say This runs in the Nether
```

### Storage NBT (datapack-specific global state)
```mcfunction
# Storage is the datapack-native key-value store — persists across /reload
data modify storage mypack:data config.difficulty set value "hard"
data get storage mypack:data config.difficulty

# Copy live entity data into storage for macro use or cross-function state
data modify storage mypack:log last_player_pos set from entity @s Pos
```

For full command syntax, selectors, and scoreboard operations see the
[Minecraft Wiki — Commands](https://minecraft.wiki/w/Commands) reference.
The `minecraft-commands-scripting` skill covers command-only work in depth.

---

## Macros (1.20.2+)

Macro functions let you pass dynamic arguments to a function.

### Define a macro function (`data/mypack/function/greet.mcfunction`)
```mcfunction
# Macro argument: $(name)
$tellraw @a {"text":"Welcome $(name)!","color":"gold"}
$scoreboard players set $(name) points 0
```

### Call with `run function` + `with`
```mcfunction
# Pass values from storage
data modify storage mypack:tmp input set value {name:"Steve"}
function mypack:greet with storage mypack:tmp input

# Pass values from entity NBT
function mypack:greet with entity @p {}

# Pass value from block NBT
function mypack:greet with block 0 64 0 {}
```

---

## Advancements

### `data/<namespace>/advancement/my_advancement.json`
```json
{
  "display": {
    "icon": {
      "id": "minecraft:diamond"
    },
    "title": {"text": "Diamond Hunter"},
    "description": {"text": "Mine your first diamond"},
    "frame": "task",
    "show_toast": true,
    "announce_to_chat": true,
    "hidden": false
  },
  "criteria": {
    "mined_diamond": {
      "trigger": "minecraft:item_picked_up",
      "conditions": {
        "item": {
          "items": ["minecraft:diamond"]
        }
      }
    }
  },
  "rewards": {
    "function": "mypack:on_diamond_obtained",
    "experience": 10
  }
}
```

### Common advancement triggers
| Trigger | When it fires |
|---------|--------------|
| `minecraft:impossible` | Never (use for manual grants) |
| `minecraft:tick` | Every tick while player is online |
| `minecraft:player_killed_entity` | Player kills an entity |
| `minecraft:entity_killed_player` | Entity kills a player |
| `minecraft:item_picked_up` | Player picks up an item |
| `minecraft:placed_block` | Player places a block |
| `minecraft:inventory_changed` | Player inventory changes |
| `minecraft:changed_dimension` | Player changes dimension |
| `minecraft:consume_item` | Player consumes an item |
| `minecraft:location` | Player at a specific location |
| `minecraft:recipe_unlocked` | Player unlocks a recipe |

---

## Custom Recipes

### Shaped crafting (`data/<namespace>/recipe/shaped.json`)
```json
{
  "type": "minecraft:crafting_shaped",
  "pattern": [
    "DDD",
    "D D",
    "DDD"
  ],
  "key": {
    "D": { "item": "minecraft:diamond" }
  },
  "result": {
    "id": "minecraft:diamond_block",
    "count": 1
  }
}
```

### Shapeless crafting
```json
{
  "type": "minecraft:crafting_shapeless",
  "ingredients": [
    { "item": "minecraft:wheat" },
    { "item": "minecraft:wheat" },
    { "item": "minecraft:wheat" }
  ],
  "result": {
    "id": "minecraft:bread",
    "count": 2
  }
}
```

### Smelting / blasting / smoking / campfire
```json
{
  "type": "minecraft:smelting",
  "ingredient": { "item": "minecraft:beef" },
  "result": { "id": "minecraft:cooked_beef" },
  "experience": 0.35,
  "cookingtime": 200
}
```

### Disable a vanilla recipe (override with empty file)
To remove a vanilla recipe, create a file at the **same path** under `data/minecraft/recipe/`
in your datapack with just `{}` as the content:

```json
{}
```

For example, to disable the piston recipe, create:  
`data/minecraft/recipe/piston.json` containing only `{}`.

> Get the exact filename from the vanilla jar:  
> `jar xf minecraft.jar data/minecraft/recipe/`

### Smithing transform
```json
{
  "type": "minecraft:smithing_transform",
  "template": { "item": "minecraft:netherite_upgrade_smithing_template" },
  "base": { "item": "minecraft:diamond_sword" },
  "addition": { "item": "minecraft:netherite_ingot" },
  "result": { "id": "minecraft:netherite_sword" }
}
```

---

## Loot Tables

### `data/<namespace>/loot_table/custom_chest.json`
```json
{
  "type": "minecraft:chest",
  "pools": [
    {
      "rolls": { "type": "minecraft:uniform", "min": 3, "max": 8 },
      "entries": [
        {
          "type": "minecraft:item",
          "name": "minecraft:diamond",
          "weight": 5,
          "functions": [
            {
              "function": "minecraft:set_count",
              "count": { "type": "minecraft:uniform", "min": 1, "max": 3 }
            }
          ]
        },
        {
          "type": "minecraft:item",
          "name": "minecraft:gold_ingot",
          "weight": 20
        },
        {
          "type": "minecraft:empty",
          "weight": 30
        }
      ]
    }
  ]
}
```

---

## Predicates

### `data/<namespace>/predicate/is_daytime.json`
```json
{
  "condition": "minecraft:time_check",
  "value": { "min": 0, "max": 12000 }
}
```

### `data/<namespace>/predicate/player_has_diamond.json`
```json
{
  "condition": "minecraft:entity_properties",
  "entity": "this",
  "predicate": {
    "inventory": {
      "items": [
        { "items": ["minecraft:diamond"] }
      ]
    }
  }
}
```

### Using predicates in functions
```mcfunction
execute if predicate mypack:is_daytime run say It is daytime!
execute unless predicate mypack:player_has_diamond run tell @s You need a diamond!
```

---

## Tags

### Block tag (`data/minecraft/tags/block/climbable.json` — override vanilla)
```json
{
  "replace": false,
  "values": [
    "minecraft:ladder",
    "minecraft:vine",
    "#minecraft:wool"
  ]
}
```

### Item tag (`data/<namespace>/tags/item/my_fuel.json`)
```json
{
  "replace": false,
  "values": [
    "minecraft:coal",
    "minecraft:charcoal",
    "minecraft:blaze_rod"
  ]
}
```

Use `"replace": false` to append to existing tags. Use `"replace": true` to completely
override (use with care for vanilla tags).

---

## Worldgen Overrides

### Override biome noise (`data/minecraft/worldgen/noise_settings/overworld.json`)
Edit inside an existing copy — do NOT create from scratch without the full JSON.
Get the vanilla version from the Minecraft jar: `jar xf minecraft.jar data/`.

### Override a biome's spawn costs
```json
{
  "spawn_costs": {
    "minecraft:zombie": {
      "energy_budget": 0.12,
      "charge": 0.7
    }
  }
}
```

---

## Installation & Testing

```bash
# Place datapack in world folder
/datapacks/my-datapack/

# Or as a zip
/datapacks/my-datapack.zip

# In-game commands
/datapack list               # see all datapacks
/datapack enable "file/my-datapack"
/datapack disable "file/my-datapack"
/reload                      # hot-reload all datapacks without restart
```

### Development workflow
1. Edit `.mcfunction` or `.json` files
2. Run the bundled validator to catch JSON and path errors before loading:
   ```bash
   ./scripts/validate-datapack.sh --root /path/to/datapack
   ```
3. If errors, fix and re-validate until clean
4. Run `/reload` in-game (or `/minecraft:reload` if a mod intercepts it)
5. Test with target command (e.g., `/function mypack:setup`, trigger an advancement)
6. Check `latest.log` for runtime errors (missing references, bad selectors)

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Unknown or invalid command` | Syntax error in function | Check whitespace, selector, trailing space |
| `Datapack did not load` | Invalid JSON in any file | Validate with `jq . < file.json` |
| `pack metadata mismatch` | Wrong `pack_format` or `min_format` / `max_format` values | Update `pack.mcmeta` for the exact 1.21.x patch |
| Function not running on tick | Missing tick tag or wrong namespace | Check `tags/function/tick.json` path |
| Macro error | `$` line but no `with` | Provide `with storage/entity/block` |

## Validator Script

Use the bundled validator script before shipping a datapack update:

```bash
# Run from the installed skill directory (for example `.codex/skills/minecraft-datapack`):
./scripts/validate-datapack.sh --root /path/to/datapack

# Strict mode treats warnings as failures:
./scripts/validate-datapack.sh --root /path/to/datapack --strict
```

What it checks:
- JSON validity for `pack.mcmeta` and `data/**/*.json`
- Legacy pluralized path mistakes for loot tables, functions, and block/item/function tags
- `tags/function/load.json` and `tags/function/tick.json` references resolve to real `.mcfunction` files

---

## References

- Minecraft Wiki — Data Pack: https://minecraft.wiki/w/Data_pack
- Minecraft Wiki — Function: https://minecraft.wiki/w/Function_(Java_Edition)
- Minecraft Wiki — Commands: https://minecraft.wiki/w/Commands
- Pack format history: https://minecraft.wiki/w/Pack_format
- NBT format: https://minecraft.wiki/w/NBT_format
- Predicate conditions: https://minecraft.wiki/w/Predicate
- Loot table format: https://minecraft.wiki/w/Loot_table
