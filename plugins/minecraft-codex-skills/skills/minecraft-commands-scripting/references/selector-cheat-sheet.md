# Selector Cheat Sheet (1.21.x)

## High-Value Filters

```mcfunction
@a[gamemode=!spectator]
@e[type=minecraft:zombie,distance=..16]
@a[scores={kills=5..}]
@e[tag=arena,sort=nearest,limit=1]
@a[team=red]
@s[nbt={SelectedItem:{id:"minecraft:clock"}}]
```

## Safer Defaults

- Add `type=` when using `@e`
- Add `limit=` whenever you mean one target
- Add `sort=nearest` or `sort=random` instead of relying on arbitrary order
- Prefer score or tag filters over giant NBT filters when you control the system

## Good Combinations

```mcfunction
# nearest tagged mob in range
@e[type=minecraft:zombie,tag=boss,distance=..32,sort=nearest,limit=1]

# active arena players
@a[tag=arena_player,gamemode=!spectator]

# players in a scoreboard phase
@a[scores={phase=2}]
```
