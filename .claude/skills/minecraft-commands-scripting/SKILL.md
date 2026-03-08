---
name: minecraft-commands-scripting
description: >
  Write Minecraft vanilla commands, NBT scripts, scoreboards, and complex execute chains
  for use in command blocks, chat, or .mcfunction files. Covers full execute subcommand
  reference (as/at/in/positioned/rotated/facing/anchored/if/unless/store/run), selector
  arguments with all filter options, scoreboard objectives and operations, NBT path syntax
  for entities/blocks/storage, schedule and forceload commands, tellraw/title JSON text
  components, bossbar, team management, item modification commands, attribute commands,
  particle/playsound effects, and RCON scripting. Targets Minecraft 1.21.x Java Edition.
  Use for command-only work; for full function/advancement/recipe systems use the
  minecraft-datapack skill instead.
---

# Minecraft Commands & Scripting Skill

## Command Syntax Conventions

- `<required>` — required argument
- `[optional]` — optional argument
- `(a|b|c)` — choose one
- `...` — repeating / multiple
- Coordinates: `~` = relative offset, `^` = local (look-direction)

### Routing Boundaries
- `Use when`: the task is raw command chains, scoreboards, selector logic, or RCON command scripting.
- `Do not use when`: creating or editing full datapack structures and registries (`minecraft-datapack`).
- `Do not use when`: behavior depends on Java plugin or mod code (`minecraft-plugin-dev`/`minecraft-modding`).

---

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
execute if data entity @s SelectedItem.tag.custom run say Has custom tag
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
scoreboard objectives add kills playerKillCount              # player kill counter (kills BY players)
scoreboard objectives add zombie_kills minecraft.killed:minecraft.zombie  # kills of a specific mob type
scoreboard objectives add deaths deathCount
scoreboard objectives add xp experienceLevel
scoreboard objectives add jumps minecraft.custom:minecraft.jump          # 1.13+ stat format
scoreboard objectives add playtime minecraft.custom:minecraft.play_one_minute  # 1.13+ stat format
scoreboard objectives add points dummy                       # manual control only
scoreboard objectives add health health

# Display
scoreboard objectives setdisplay sidebar points
scoreboard objectives setdisplay list kills
scoreboard objectives setdisplay belowname health
scoreboard objectives setdisplay sidebar.team.red points   # team-specific sidebar

# Remove / rename objective
scoreboard objectives remove points
scoreboard objectives modify points displayname {"text":"Score","color":"gold"}
scoreboard objectives modify points rendertype (integer|hearts)

# Player scores
scoreboard players set @s points 0
scoreboard players add @s points 10
scoreboard players remove @s points 5
scoreboard players reset @s points
scoreboard players reset @s *           # reset all objectives
scoreboard players enable @s ability    # for trigger objectives

# Operations (both sides must have the score set)
scoreboard players operation @s points += @s bonus       # add
scoreboard players operation @s points -= @s penalty     # subtract
scoreboard players operation @s points *= @s multiplier  # multiply
scoreboard players operation @s points /= @s divisor     # integer divide
scoreboard players operation @s points %= @s modulus     # modulo
scoreboard players operation @s points >< @s temp        # swap
scoreboard players operation @s max = @s temp            # set to max of both
scoreboard players operation @s min = @s temp            # set to min of both

# Special fake player names (start with # for hidden players)
scoreboard players set #max points 100
scoreboard players set #config.difficulty points 2
```

---

## NBT Path Syntax

```mcfunction
# Entity root
data get entity @s

# Compound key access
data get entity @s Health
data get entity @s Inventory
data get entity @s Pos[0]           # 1st element of Pos list
data get entity @s Inventory[0]     # 1st inventory slot
data get entity @s Inventory[{id:"minecraft:diamond"}]  # match compound

# Nested path
data get entity @s Brain.memories."minecraft:home".value.pos
data get entity @s ActiveEffects[0].Id

# Block entity
data get block 0 64 0
data get block 0 64 0 Items
data get block 0 64 0 Items[{Slot:0b}].Count

# Storage
data get storage mypack:data config.difficulty
data get storage mypack:data player_list

# Modify operations
data modify entity @s Health set value 20.0f
data modify entity @s CustomName set value '{"text":"Boss"}'
data modify storage mypack:tmp result set from entity @s Health
data modify storage mypack:out names append from entity @e[type=!player] CustomName

# Remove NBT
data remove entity @s ActiveEffects
data remove storage mypack:data temp
```

---

## Item and Inventory Commands

```mcfunction
# Give items
give @s minecraft:diamond 5
give @s minecraft:diamond_sword[minecraft:enchantments={levels:{"minecraft:sharpness":5}}]

# Clear items
clear @s minecraft:dirt
clear @a                            # clear entire inventory
clear @s minecraft:diamond 3        # remove exactly 3 diamonds

# Item (1.17+) — modify items in slots
item replace entity @s weapon.mainhand with minecraft:golden_sword[minecraft:custom_name='{"text":"Divine Blade"}']
item replace block 0 64 0 container.0 with minecraft:diamond 1
item replace entity @s hotbar.0 from entity @s hotbar.1   # copy slot
item modify entity @s weapon.mainhand mypack:add_lore      # apply item modifier

# Slot identifiers for players:
# weapon.mainhand, weapon.offhand
# head, chest, legs, feet
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
bossbar set mypack:boss_hp color (pink|blue|red|green|yellow|purple|white)
bossbar set mypack:boss_hp style (progress|notched_6|notched_10|notched_12|notched_20)
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
team modify redteam color (aqua|black|blue|dark_aqua|dark_blue|dark_gray|dark_green|dark_purple|dark_red|gold|gray|green|light_purple|red|white|yellow)
team modify redteam prefix {"text":"[RED] ","color":"red"}
team modify redteam nametagVisibility (always|hideForOtherTeams|hideForOwnTeam|never)
team modify redteam collisionRule (always|never|pushOtherTeams|pushOwnTeam)
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
tellraw @a {"translate":"death.attack.mob","with":[{"selector":"@p"},{"entity":"@p","selector":"type"}]}

# Clickable / hoverable
tellraw @a {"text":"Click here","color":"aqua","clickEvent":{"action":"run_command","value":"/say hi"},"hoverEvent":{"action":"show_text","contents":"Run /say hi"}}

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
title @a times 10 70 20    # fade-in, stay, fade-out ticks
title @a clear
title @a reset
```

---

## Schedule

```mcfunction
# Schedule a function to run once after N ticks
schedule function mypack:delayed_grant 100t

# Schedule repeating (append = don't cancel existing)
schedule function mypack:repeating 20t replace    # replace existing schedule
schedule function mypack:repeating 20t append     # add alongside existing

# Clear scheduled function
schedule clear mypack:delayed_grant
```

---

## Attribute Commands

```mcfunction
# Get base/current value
attribute @s minecraft:generic.max_health get
attribute @s minecraft:generic.movement_speed get

# Set base value
attribute @s minecraft:generic.max_health base set 30.0
attribute @s minecraft:generic.attack_damage base set 10.0

# Add modifier
attribute @s minecraft:generic.movement_speed modifier add 12345678-1234-1234-1234-123456789abc "speed_boost" 0.1 add_multiplied_total

# Remove modifier
attribute @s minecraft:generic.movement_speed modifier remove 12345678-1234-1234-1234-123456789abc

# Get modifier value
attribute @s minecraft:generic.movement_speed modifier value get 12345678-1234-1234-1234-123456789abc

# Modifier operations: add_value, add_multiplied_base, add_multiplied_total
```

---

## Effects, Particles, Sounds

```mcfunction
# Effects
effect give @s minecraft:speed 60 2 true     # 60 seconds, level III, hide particles
effect give @a minecraft:resistance 9999 4
effect clear @s minecraft:speed
effect clear @s                              # clear all effects

# Particles
particle minecraft:flame 0.0 65.0 0.0 0.5 0.5 0.5 0.01 20
particle minecraft:block minecraft:stone 0.0 65.0 0.0 0 0 0 0 1

# Sounds
playsound minecraft:entity.player.levelup master @s ~ ~ ~ 1.0 1.0
playsound minecraft:block.note_block.bell record @a ~ ~ ~ 1.0 0.5
# playsound <sound> <source> <targets> [x] [y] [z] [volume] [pitch] [minVolume]
# source: (master|music|record|weather|block|hostile|neutral|player|ambient|voice)

stopsound @a * minecraft:music.game
stopsound @s
```

---

## World and Environment Commands

```mcfunction
# Time
time set day
time set noon      # 6000
time set night     # 13000
time set 0
time add 1000
time query daytime

# Weather
weather clear 6000
weather rain 12000
weather thunder 6000

# Gamerules (1.21.x)
gamerule doDaylightCycle false
gamerule doMobSpawning false
gamerule keepInventory true
gamerule spawnRadius 0
gamerule playersSleepingPercentage 0   # one player can skip night
gamerule universalAnger true

# Difficulty
difficulty peaceful
difficulty easy
difficulty normal
difficulty hard

# Setworldspawn
setworldspawn 0 64 0 0.0   # x y z angle

# Spawnpoint per player
spawnpoint @s ~ ~ ~ 0.0

# forceload
forceload add 0 0 31 31     # keep chunks 0,0 to 31,31 loaded
forceload remove 0 0 31 31
forceload query 0 0
```

---

## RCON Scripting

Connect to a Minecraft server remotely using RCON (enable in `server.properties`):

```properties
# server.properties
enable-rcon=true
rcon.password=your_password
rcon.port=25575
```

### Bash RCON script (using `mcrcon`)
```bash
#!/bin/bash
RCON="mcrcon -H localhost -P 25575 -p your_password"

# Send command
$RCON "say Server backup starting in 5 minutes"
sleep 300
$RCON "save-off"
$RCON "save-all"

# Backup world
rsync -av /path/to/server/world/ /backups/world_$(date +%Y%m%d_%H%M%S)/

$RCON "save-on"
$RCON "say Backup complete!"
```

### Python RCON
```python
from mcrcon import MCRcon

with MCRcon("localhost", "your_password", port=25575) as mcr:
    response = mcr.command("list")
    print(response)
    # "There are 3 of a max of 20 players online: Steve, Alex, Notch"
    
    players = response.split(": ")[1].split(", ") if ": " in response else []
    print(f"Online players: {players}")
```

---

## Common Scripting Patterns

### Player join setup (in `load.mcfunction` + tag listeners)
```mcfunction
# Give new players a starter kit tag
scoreboard objectives add initialized dummy
execute as @a unless score @s initialized matches 1 run function mypack:on_first_join

# on_first_join.mcfunction
scoreboard players set @s initialized 1
give @s minecraft:stone_sword
give @s minecraft:bread 16
tellraw @s {"text":"Welcome! Here's a starter kit.","color":"green"}
```

### Death counter + respawn
```mcfunction
# tick.mcfunction — check deaths
execute as @a[scores={deaths=1..}] run function mypack:on_death
function mypack:on_death
scoreboard players reset @s deaths
scoreboard players add @s total_deaths 1
```

### Proximity detection
```mcfunction
# Check if any player is within 5 blocks of a location
execute if entity @a[x=10,y=64,z=10,distance=..5] run function mypack:player_nearby
```

### Math tricks (no fractions in scoreboards)
```mcfunction
# Multiply @s.value by 1.5 using integer math (×3 then /2)
scoreboard players operation @s result = @s value
scoreboard players operation @s result *= #three constants
scoreboard players operation @s result /= #two constants
# Set #two and #three on load:
# scoreboard players set #two constants 2
# scoreboard players set #three constants 3
```

---

## References

- Minecraft Wiki — Commands: https://minecraft.wiki/w/Commands
- Minecraft Wiki — Target selectors: https://minecraft.wiki/w/Target_selectors
- Minecraft Wiki — NBT format: https://minecraft.wiki/w/NBT_format
- Minecraft Wiki — Raw JSON text: https://minecraft.wiki/w/Raw_JSON_text_format
- Minecraft Wiki — Scoreboard: https://minecraft.wiki/w/Scoreboard
- Execute command wiki: https://minecraft.wiki/w/Commands/execute
