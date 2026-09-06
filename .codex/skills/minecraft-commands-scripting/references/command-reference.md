# Command reference

Read only the section needed for the target Minecraft version. Examples are
independent commands, not a script to execute from top to bottom. Preserve the
existing project version and verify changed syntax against its release notes.

Contents: selectors, execute, scoreboards, NBT and items, bossbars and teams,
text components, scheduling, attributes, particles and sounds, time and gamerules.

## Target Selectors

### Base selectors
| Selector | Targets |
|----------|---------|
| `@a` | All online players |
| `@e` | All loaded entities |
| `@p` | Nearest player to executor |
| `@r` | Random online player |
| `@s` | Executing entity |
| `@n` | Nearest entity of any type (1.21+) |

### Selector arguments (full reference)
```
@e[
  type=minecraft:zombie,         # entity type (prefix ! to negate)
  type=!minecraft:player,

  name=Herobrine,                # custom name (exact)
  name=!Bob,                     # not named Bob

  distance=..10,                 # max 10 blocks away
  distance=5..10,                # 5-10 blocks away

  x=0,y=64,z=0,                  # origin for AABB
  dx=15,dy=5,dz=15,              # AABB dimensions (x/dx/dy/dz required together)

  scores={kills=1..,deaths=..5}, # score conditions (..N = max, N.. = min)

  tag=vip,                       # has scoreboard tag
  tag=!banned,                   # does NOT have tag

  team=red,                      # on team "red"
  team=!blue,                    # not on team "blue"
  team=,                         # no team

  gamemode=survival,             # (survival|creative|adventure|spectator)
  gamemode=!spectator,

  level=30..,                    # XP level range
  x_rotation=-90..-45,          # pitch range (looking up = -90)
  y_rotation=-45..45,            # yaw range (facing south = 0)

  nbt={Inventory:[{id:"minecraft:diamond"}]},  # NBT match

  predicate=mypack:my_predicate, # predicate match

  sort=(nearest|furthest|random|arbitrary),
  limit=1,
]
```

---

## The `execute` Command

Full subcommand chain syntax — subcommands must come before `run`:

```
execute
  [as <entity>]
  [at <entity>]
  [in <dimension>]
  [positioned (<xyz> | as <entity> | over <heightmap>)]
  [rotated (<yaw> <pitch> | as <entity>)]
  [facing (<xyz> | entity <entity> (eyes|feet))]
  [anchored (eyes|feet)]
  [if|unless (block|blocks|biome|data|dimension|entity|loaded|predicate|score|items)]
  [store (result|success) (score|storage|entity|block|bossbar) ...]
  run <command>
```

### Context modifiers
```mcfunction
# Change executor
execute as @a run say I am @s

# Change position and rotation to entity
execute at @e[type=minecraft:zombie] run particle minecraft:flame ~ ~ ~ 0.5 0.5 0.5 0.1 5

# Change both executor and position
execute as @a at @s run particle minecraft:heart ~ ~1 ~ 0.3 0.3 0.3 0.01 3

# Change dimension
execute in minecraft:the_end run say Running in The End

# Absolute position
execute positioned 0.0 100.0 0.0 run setblock ~ ~ ~ minecraft:beacon

# Relative to entity
execute as @a at @s positioned ~ ~2 ~ run setblock ~ ~ ~ minecraft:glass

# Local coords (^ = forward/up/right relative to rotation)
execute as @a at @s anchored eyes run particle minecraft:end_rod ^ ^ ^1 0 0 0 0 1
```

### Conditional execution
```mcfunction
# if block
execute if block 0 64 0 minecraft:diamond_block run say Found diamond block

# if blocks — compare two regions
execute if blocks 0 0 0 9 9 9 100 0 100 all run say Regions match

# if entity (existence check)
execute if entity @a[tag=boss] run say Boss is online
execute unless entity @a[gamemode=creative] run say No creative players

# if score
execute if score @s kills matches 10.. run say Ten or more kills
execute if score PlayerA points > PlayerB points run say A beats B
execute if score @s points = @s max_points run say Max score!

# if data (NBT path existence/value)
execute if data entity @s SelectedItem.components."minecraft:custom_data".custom run say Has custom data
execute if data storage mypack:config active run say Config is active
execute if data block 0 64 0 Items run say Chest has items

# if predicate
execute if predicate mypack:is_raining run say It is raining

# if loaded (chunk loaded check)
execute if loaded 0 64 0 run say Chunk is loaded

# if biome
execute if biome ~ ~ ~ minecraft:jungle run say You're in a jungle

# if dimension
execute if dimension minecraft:overworld run say In overworld

# if items (1.21+)
execute if items entity @s weapon.mainhand minecraft:diamond_sword run say Holding diamond sword
execute if items block 0 64 0 container.0 minecraft:diamond run say Diamond in container slot 0
```

### Storing results
```mcfunction
# Store arithmetic result into score
execute store result score @s my_score run data get entity @s Health

# Store success (1 if command succeeded, 0 if not)
execute store success score @s result_flag run kill @e[type=minecraft:bat,limit=1]

# Store into block entity NBT (example: command block SuccessCount)
execute store result block 0 64 0 SuccessCount int 1 run data get entity @a 1

# Store into storage
execute store result storage mypack:data player_count int 1 run execute if entity @a

# Store into entity NBT
execute store result entity @s Air short 1 run data get entity @s Air

# Store into bossbar
execute store result bossbar minecraft:health value run data get entity @s Health
```

---

## Scoreboards

```mcfunction
# Create objectives
# player kill counter (kills BY players)
scoreboard objectives add kills playerKillCount
# kills of a specific mob type
scoreboard objectives add zombie_kills minecraft.killed:minecraft.zombie
scoreboard objectives add deaths deathCount
scoreboard objectives add xp level
# 1.13+ stat format
scoreboard objectives add jumps minecraft.custom:minecraft.jump
# 1.13+ stat format
scoreboard objectives add playtime minecraft.custom:minecraft.play_time
# manual control only
scoreboard objectives add points dummy
scoreboard objectives add health health

# Display
scoreboard objectives setdisplay sidebar points
scoreboard objectives setdisplay list kills
scoreboard objectives setdisplay belowname health
# team-specific sidebar
scoreboard objectives setdisplay sidebar.team.red points

# Remove / rename objective
scoreboard objectives remove points
scoreboard objectives modify points displayname {"text":"Score","color":"gold"}
scoreboard objectives modify points rendertype integer

# Player scores
scoreboard players set @s points 0
scoreboard players add @s points 10
scoreboard players remove @s points 5
scoreboard players reset @s points
# reset all objectives
scoreboard players reset @s *
# for trigger objectives
scoreboard players enable @s ability

# Operations (both sides must have the score set)
# add
scoreboard players operation @s points += @s bonus
# subtract
scoreboard players operation @s points -= @s penalty
# multiply
scoreboard players operation @s points *= @s multiplier
# integer divide
scoreboard players operation @s points /= @s divisor
# modulo
scoreboard players operation @s points %= @s modulus
# swap
scoreboard players operation @s points >< @s temp
# set to max of both
scoreboard players operation @s max > @s temp
# set to min of both
scoreboard players operation @s min < @s temp

# Special fake player names (start with # for hidden players)
scoreboard players set #max points 100
scoreboard players set #config.difficulty points 2
```

---

## NBT Path Syntax

These item/effect paths target 1.21.x and later; the `CustomName` compound form
targets 1.21.5+. Entity writes require a non-player target. Use `/item`, `/effect`,
or the appropriate command for player state instead of editing player NBT.

```mcfunction
# Entity root
data get entity @s

# Compound key access
data get entity @s Health
data get entity @s Inventory
# 1st element of Pos list
data get entity @s Pos[0]
# 1st inventory slot
data get entity @s Inventory[0]
# match compound
data get entity @s Inventory[{id:"minecraft:diamond"}]

# Nested path
data get entity @s Brain.memories."minecraft:home".value.pos
data get entity @s active_effects[0].id

# Block entity
data get block 0 64 0
data get block 0 64 0 Items
data get block 0 64 0 Items[{Slot:0b}].count

# Storage
data get storage mypack:data config.difficulty
data get storage mypack:data player_list

# Modify operations
data modify entity @s Health set value 20.0f
data modify entity @s CustomName set value {text:"Boss"}
data modify storage mypack:tmp result set from entity @s Health
data modify storage mypack:out names append from entity @e[type=!player,limit=1,sort=nearest] CustomName

# Remove NBT
data remove entity @s active_effects
data remove storage mypack:data temp
```

---

## Item and Inventory Commands

Component values below target 1.21.5+ and 26.x. Earlier 1.21 releases use a
`levels` wrapper for enchantments and JSON-encoded strings for text components.

```mcfunction
# Give items
give @s minecraft:diamond 5
give @s minecraft:diamond_sword[minecraft:enchantments={"minecraft:sharpness":5}]

# Clear items
clear @s minecraft:dirt
# clear entire inventory
clear @a
# remove exactly 3 diamonds
clear @s minecraft:diamond 3

# Item (1.17+) — modify items in slots
item replace entity @s weapon.mainhand with minecraft:golden_sword[minecraft:custom_name={text:"Divine Blade"}]
item replace block 0 64 0 container.0 with minecraft:diamond 1
# copy slot
item replace entity @s hotbar.0 from entity @s hotbar.1
# apply item modifier
item modify entity @s weapon.mainhand mypack:add_lore

# Slot identifiers for players:
# weapon.mainhand, weapon.offhand
# armor.head, armor.chest, armor.legs, armor.feet
# hotbar.0 .. hotbar.8
# inventory.0 .. inventory.26
# container.0 .. container.N  (for block entities)
```

---

## Bossbar

```mcfunction
bossbar add mypack:boss_hp {"text":"Dragon HP","color":"dark_purple"}
bossbar set mypack:boss_hp max 200
bossbar set mypack:boss_hp value 150
bossbar set mypack:boss_hp color purple
bossbar set mypack:boss_hp style progress
bossbar set mypack:boss_hp players @a
bossbar set mypack:boss_hp visible true
bossbar get mypack:boss_hp value
bossbar remove mypack:boss_hp
```

---

## Teams

```mcfunction
team add redteam {"text":"Red Team","color":"red"}
team join redteam Steve
team leave @a
team modify redteam friendlyFire false
team modify redteam color red
team modify redteam prefix {"text":"[RED] ","color":"red"}
team modify redteam nametagVisibility hideForOtherTeams
team modify redteam collisionRule pushOwnTeam
team list
team remove redteam
```

---

## Text Components (tellraw / title / books)

### `tellraw` JSON text
```mcfunction
# Plain text
tellraw @a {"text":"Hello World","color":"green"}

# Multiple components (array)
tellraw @a [{"text":"Hello ","color":"white"},{"selector":"@s","color":"gold"},{"text":"!","color":"white"}]

# Translatable text
tellraw @a {"translate":"block.minecraft.diamond_block","color":"aqua"}
tellraw @a {"translate":"commands.give.success.single","with":[{"text":"1"},{"translate":"item.minecraft.diamond"},{"selector":"@p"}]}

# Clickable / hoverable (1.21.5+ and 26.x)
tellraw @a {text:"Click here",color:"aqua",click_event:{action:"run_command",command:"/say hi"},hover_event:{action:"show_text",value:"Run /say hi"}}

# Keybind display
tellraw @a {"text":"Press ","extra":[{"keybind":"key.jump","color":"yellow"},{"text":" to jump."}]}

# NBT display
tellraw @a {"nbt":"Health","entity":"@s","interpret":false}

# Score display
tellraw @a {"score":{"name":"@s","objective":"points"}}
```

### Formatting codes (text component)
| Field | Values |
|-------|--------|
| `color` | `black`, `dark_blue`, `dark_green`, `dark_aqua`, `dark_red`, `dark_purple`, `gold`, `gray`, `dark_gray`, `blue`, `green`, `aqua`, `red`, `light_purple`, `yellow`, `white`, `#RRGGBB` |
| `bold` | `true`/`false` |
| `italic` | `true`/`false` |
| `underlined` | `true`/`false` |
| `strikethrough` | `true`/`false` |
| `obfuscated` | `true`/`false` |
| `font` | resource location (e.g., `minecraft:default`) |

### Title commands
```mcfunction
title @a title {"text":"ROUND START","color":"gold","bold":true}
title @a subtitle {"text":"Fight!","color":"red"}
title @a actionbar {"text":"Time: 60s","color":"yellow"}
# fade-in, stay, fade-out ticks
title @a times 10 70 20
title @a clear
title @a reset
```

---

## Schedule

```mcfunction
# Schedule a function to run once after N ticks
schedule function mypack:delayed_grant 100t

# Schedule repeating (append = don't cancel existing)
# replace existing schedule
schedule function mypack:repeating 20t replace
# add alongside existing
schedule function mypack:repeating 20t append

# Clear scheduled function
schedule clear mypack:delayed_grant
```

---

## Attribute Commands

These names target 1.21.2+ and 26.x. Minecraft 1.21/1.21.1 still uses the
`generic.` attribute prefix; namespaced modifier IDs apply throughout 1.21+.

```mcfunction
# Get base/current value
attribute @s minecraft:max_health get
attribute @s minecraft:movement_speed get

# Set base value
attribute @s minecraft:max_health base set 30.0
attribute @s minecraft:attack_damage base set 10.0

# Add modifier
attribute @s minecraft:movement_speed modifier add mypack:speed_boost 0.1 add_multiplied_total

# Remove modifier
attribute @s minecraft:movement_speed modifier remove mypack:speed_boost

# Get modifier value
attribute @s minecraft:movement_speed modifier value get mypack:speed_boost

# Modifier operations: add_value, add_multiplied_base, add_multiplied_total
```

---

## Effects, Particles, Sounds

```mcfunction
# Effects
# 60 seconds, level III, hide particles
effect give @s minecraft:speed 60 2 true
effect give @a minecraft:resistance 9999 4
effect clear @s minecraft:speed
# clear all effects
effect clear @s

# Particles
particle minecraft:flame 0.0 65.0 0.0 0.5 0.5 0.5 0.01 20
particle minecraft:block{block_state:"minecraft:stone"} 0.0 65.0 0.0 0 0 0 0 1

# Sounds
playsound minecraft:entity.player.levelup master @s ~ ~ ~ 1.0 1.0
playsound minecraft:block.note_block.bell record @a ~ ~ ~ 1.0 0.5
# playsound <sound> <source> <targets> [x] [y] [z] [volume] [pitch] [minVolume]
# source: master, music, record, weather, block, hostile, neutral, player, ambient, voice
# Minecraft 1.21.6+ also supports ui

stopsound @a * minecraft:music.game
stopsound @s
```

---

## World and Environment Commands

For 26.x, `/time` operates on a world clock. Select it explicitly when the
execution dimension is not enough; `set` and `add` return total clock ticks.

```mcfunction
time of minecraft:overworld set noon
time of minecraft:overworld add 1000
time of minecraft:overworld query time
time query gametime
```

See the [26.1 release notes](https://www.minecraft.net/en-us/article/minecraft-java-edition-26-1)
for clock/timeline query semantics. The following time examples are for 1.21.x:

```mcfunction
# Time (legacy 1.21.x)
time set day
# 6000
time set noon
# 13000
time set night
time set 0
time add 1000
time query daytime

# Weather
weather clear 6000
weather rain 12000
weather thunder 6000

# Gamerules (1.21.10 and earlier camelCase names)
gamerule doDaylightCycle false
gamerule doMobSpawning false
gamerule keepInventory true
gamerule spawnRadius 0
# one player can skip night
gamerule playersSleepingPercentage 0
gamerule universalAnger true

# Gamerules (1.21.11+ registry IDs)
gamerule minecraft:advance_time false
gamerule minecraft:spawn_mobs false
gamerule minecraft:keep_inventory true
gamerule minecraft:respawn_radius 0
gamerule minecraft:players_sleeping_percentage 0
gamerule minecraft:universal_anger true

# Difficulty
difficulty peaceful
difficulty easy
difficulty normal
difficulty hard

# Setworldspawn
# 1.21.8 and earlier: x y z angle
setworldspawn 0 64 0 0.0
# 1.21.9+: x y z yaw pitch
setworldspawn 0 64 0 0.0 0.0

# Spawnpoint per player
# 1.21.8 and earlier: x y z angle
spawnpoint @s ~ ~ ~ 0.0
# 1.21.9+: x y z yaw pitch
spawnpoint @s ~ ~ ~ 0.0 0.0

# forceload
# keep chunks 0,0 to 31,31 loaded
forceload add 0 0 31 31
forceload remove 0 0 31 31
forceload query 0 0
```

---
