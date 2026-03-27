---
name: minecraft-datapack
description: >
  Create, edit, and debug Minecraft vanilla datapacks for 1.21.x. Covers the full
  datapack format: pack.mcmeta, function files (.mcfunction), advancements, predicates,
  loot tables, item modifiers, recipe overrides, tags, damage types, dimension types,
  worldgen overrides, and structure sets. Handles function syntax, execute command chains,
  macro functions (1.20.2+), storage NBT, scoreboard operations, advancement triggers,
  pack format numbers, and /reload workflow. No Java or mod loader required — pure
  vanilla JSON and .mcfunction files.
---

# Minecraft Datapack Skill

## What Is a Datapack?

A datapack is a folder (or `.zip`) placed in a world's `datapacks/` directory that
extends or overrides vanilla Minecraft behavior using JSON files and `.mcfunction`
scripts. No Java, no mods. Requires only a running Minecraft server or singleplayer world.

Datapacks can:
- Add custom **advancements**, **recipes**, **loot tables**, and **tags**
- Override vanilla **worldgen** (biomes, structures, noise settings)
- Add **functions** executed by command blocks, other functions, or triggers
- Add **predicates** for conditional logic
- Add **item modifiers** (rename, enchant, etc. via loot table mechanics)

### Routing Boundaries
- `Use when`: the deliverable is datapack files (`pack.mcmeta`, `data/...`) and `.mcfunction`/JSON content.
- `Do not use when`: the request is command-only snippets not tied to a datapack file tree (`minecraft-commands-scripting`).
- `Do not use when`: the request requires loader APIs, Java code, or runtime mod behavior (`minecraft-modding`).

---

## Pack Format Numbers (1.21.x)

| Minecraft Version | `pack_format` |
|-------------------|--------------|
| 1.21 / 1.21.1     | 48           |
| 1.21.2 / 1.21.3   | 57           |
| 1.21.4            | 61           |
| 1.21.5            | 71           |

Always use the exact format for your target version.
Use `supported_formats` to declare a range:
```json
"supported_formats": { "min_inclusive": 48, "max_inclusive": 71 }
```

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

```json
{
  "pack": {
    "pack_format": 71,
    "supported_formats": { "min_inclusive": 48, "max_inclusive": 71 },
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

### Execute subcommands
```mcfunction
# as: change execution entity
execute as @a run say Hi from each player

# at: change execution position to entity's location
execute as @a at @s run particle flame ~ ~ ~ 0 0 0 0 1

# positioned: change position without changing executor
execute positioned 0 64 0 run setblock ~ ~ ~ stone

# if/unless conditions
execute if block ~ ~-1 ~ minecraft:grass_block run say Standing on grass
execute unless entity @a[tag=vip] run say No VIPs online

# store result into score
execute store result score @s mypack.health run data get entity @s Health

# Chained
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ #minecraft:logs run give @s minecraft:apple

# in: change dimension
execute in minecraft:the_nether run say This runs in the Nether
```

### Scoreboard
```mcfunction
# Create objectives
scoreboard objectives add kills playerKillCount
scoreboard objectives add points dummy
scoreboard objectives setdisplay sidebar points

# Modify scores
scoreboard players set @s points 0
scoreboard players add @s points 10
scoreboard players remove @s points 5
scoreboard players operation @s points += @s kills

# Test scores
execute if score @s points matches 100.. run say Reached 100 points!
execute if score @s points matches ..0 run say Score is zero or negative
execute if score PlayerA points < PlayerB points run say A has fewer points than B
```

### NBT and storage
```mcfunction
# Read entity NBT
data get entity @s Health
data get entity @s Inventory[0]

# Modify entity NBT
data modify entity @s Health set value 20.0f
data modify entity @s CustomName set value '{"text":"Boss","color":"red"}'

# Storage (global key-value store)
data modify storage mypack:data config.difficulty set value "hard"
data get storage mypack:data config.difficulty

# Copy from entity to storage
data modify storage mypack:log last_player_pos set from entity @s Pos
```

### Selectors
```mcfunction
@a                          # all players
@p                          # nearest player
@r                          # random player
@e                          # all entities
@s                          # executing entity
@n                          # nearest entity (1.21+)

# Selector arguments
@a[gamemode=survival]
@a[gamemode=!spectator]
@e[type=minecraft:zombie,distance=..10]
@e[type=minecraft:player,tag=vip]
@a[scores={kills=1..10}]
@a[nbt={playerGameType:0}]
@e[sort=nearest,limit=1,type=!minecraft:player]
@a[x=0,y=64,z=0,dx=10,dy=10,dz=10]   # AABB selection
@a[team=red]
@a[level=30..]
@a[name=Steve]
```

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
2. Run `/reload` in-game (or `/minecraft:reload` if a mod intercepts it)
3. Test with target command
4. Check `latest.log` for syntax errors

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Unknown or invalid command` | Syntax error in function | Check whitespace, selector, trailing space |
| `Datapack did not load` | Invalid JSON in any file | Validate with `jq . < file.json` |
| `pack_format mismatch` | Wrong `pack_format` number | Update `pack.mcmeta` |
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
- Legacy pluralized path mistakes for loot tables and block/item tags
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
