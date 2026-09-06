---
name: minecraft-commands-scripting
description: "Write and debug Minecraft Java 26.x and 1.21.x commands, selectors, execute chains, scoreboards, NBT, and RCON scripts. Use for command-only work; use minecraft-datapack for complete datapack structures."
---

# Minecraft Commands & Scripting Skill

Before editing, inspect the exact Minecraft version and execution context
(chat, function, command block, or RCON). Keep the requested scope and use only
the relevant examples. Check current release notes for version-sensitive syntax.

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

## Bundled References And Examples

- Execute cheat sheet: `references/execute-cheat-sheet.md`
- Selector cheat sheet: `references/selector-cheat-sheet.md`
- Example scripts: `scripts/examples/arena-countdown.mcfunction`, `scripts/examples/stopwatch-podium.mcfunction`, `scripts/examples/rcon-backup-warning.sh` (one-time setup commands are called out in comments when needed)

Use the cheat sheets when you need fast command recall without scanning this whole
skill file. The example scripts are meant to be copyable starting points, not toy snippets.

---

## Command reference

Use [references/command-reference.md](references/command-reference.md) for the
relevant command family. It includes version boundaries for item components,
attributes, text events, gamerules, and 26.x world clocks. Do not run example
blocks as a batch; each demonstrates a separate operation.

## RCON Scripting

Connect to a Minecraft server remotely using RCON (enable in `server.properties`):

```properties
# server.properties
enable-rcon=true
rcon.password=your_password
rcon.port=25575
```

RCON is unencrypted. Keep the port bound to a trusted private network, VPN, or
localhost, and inject the password through a protected secret rather than a
command-line argument.

### Bash RCON script (using `mcrcon`)
```bash
#!/usr/bin/env bash
set -euo pipefail

: "${MCRCON_PASS:?inject MCRCON_PASS from a protected secret}"
export MCRCON_HOST="${MCRCON_HOST:-127.0.0.1}"
export MCRCON_PORT="${MCRCON_PORT:-25575}"

restore_saves() {
    mcrcon "save-on" >/dev/null || true
}
trap restore_saves EXIT INT TERM

# Send command
mcrcon "say Server backup starting in 5 minutes"
sleep 300
mcrcon "save-off"
mcrcon "save-all flush"

# Backup world
rsync -av /path/to/server/world/ /backups/world_$(date +%Y%m%d_%H%M%S)/

mcrcon "save-on"
trap - EXIT INT TERM
mcrcon "say Backup complete!"
```

### Python RCON
```python
import os

from mcrcon import MCRcon

with MCRcon("localhost", os.environ["MCRCON_PASS"], port=25575) as mcr:
    response = mcr.command("list")
    print(response)
    # "There are 3 of a max of 20 players online: Steve, Alex, Notch"
    
    players = response.split(": ")[1].split(", ") if ": " in response else []
    print(f"Online players: {players}")
```

---

## Common Scripting Patterns

### First-join setup (load and tick functions)
```mcfunction
# load.mcfunction: create the objective
scoreboard objectives add initialized dummy

# tick.mcfunction: detect players who have not been initialized
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

# on_death.mcfunction (separate file)
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
