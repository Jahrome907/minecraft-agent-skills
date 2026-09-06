# Datapack data examples

Read the section for the requested registry: advancements, recipes, loot
tables, predicates, or tags. Match its JSON schema to the exact Minecraft
version; copying pack metadata alone does not port older data.

## Advancements

### `data/<namespace>/advancement/my_advancement.json`
```json
{
  "display": {
    "icon": {
      "id": "minecraft:diamond"
    },
    "title": {"text": "Diamond Hunter"},
    "description": {"text": "Obtain your first diamond"},
    "frame": "task",
    "show_toast": true,
    "announce_to_chat": true,
    "hidden": false
  },
  "criteria": {
    "obtained_diamond": {
      "trigger": "minecraft:inventory_changed",
      "conditions": {
        "items": [
          {"items": "minecraft:diamond"}
        ]
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
| `minecraft:thrown_item_picked_up_by_player` | Player picks up a thrown item |
| `minecraft:placed_block` | Player places a block |
| `minecraft:inventory_changed` | Player inventory changes |
| `minecraft:changed_dimension` | Player changes dimension |
| `minecraft:consume_item` | Player consumes an item |
| `minecraft:location` | Player at a specific location |
| `minecraft:recipe_unlocked` | Player unlocks a recipe |

---

## Custom Recipes

These ingredients use the string/tag/list format introduced in 1.21.2 and
retained in 26.x. Preserve the older ingredient-object schema for 1.21/1.21.1.

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
    "D": "minecraft:diamond"
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
    "minecraft:wheat",
    "minecraft:wheat",
    "minecraft:wheat"
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
  "ingredient": "minecraft:beef",
  "result": { "id": "minecraft:cooked_beef" },
  "experience": 0.35,
  "cookingtime": 200
}
```

### Disable a vanilla recipe

An empty `{}` is not a valid recipe and produces a decode error. To hide a
specific lower-priority recipe, merge a top-level `filter` into the existing
`pack.mcmeta`, alongside its `pack` section. For example, this filter blocks
the vanilla piston recipe:

```json
{
  "filter": {
    "block": [
      {
        "namespace": "minecraft",
        "path": "recipe/piston\\.json"
      }
    ]
  }
}
```

Check the exact path in the target version's vanilla data. Filters only affect
packs below the filtering pack; they do not remove a replacement recipe in the
same pack. See [Mojang's pack-filter format](https://www.minecraft.net/en-us/article/minecraft-snapshot-22w11a).

### Smithing transform
```json
{
  "type": "minecraft:smithing_transform",
  "template": "minecraft:netherite_upgrade_smithing_template",
  "base": "minecraft:diamond_sword",
  "addition": "minecraft:netherite_ingot",
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
