---
name: minecraft-worldedit-ops
description: >
  Operate WorldEdit safely and efficiently for Minecraft 1.21.x server build/admin workflows.
  Covers selection mechanics, region operations, masks and patterns, clipboards and schematics,
  brushes and terraforming, undo/history safety, and practical runbooks for spawn edits, arena
  resets, block cleanup, and path shaping. Use for command-driven world operations, not plugin
  development.
---

# Minecraft WorldEdit Operations Skill

## Scope and Positioning

This skill is for **operating** WorldEdit on live or staging servers.  
It is not for writing plugin code that integrates with WorldEdit APIs.

### Routing Boundaries
- `Use when`: the task is command-driven in-world editing with WorldEdit (selections, transforms, schematics, terrain shaping, rollback-safe workflows).
- `Do not use when`: the task is Java plugin implementation (`minecraft-plugin-dev`).
- `Do not use when`: the task is broad server deployment/tuning/proxy/backup strategy (`minecraft-server-admin`).
- `Do not use when`: the task is EssentialsX command/economy/moderation workflows (`minecraft-essentials-ops`).

---

## Platform and Setup Notes

WorldEdit is commonly used on:
- Paper/Purpur/Folia servers via WorldEdit plugin
- Fabric/NeoForge via mod variants

Operational best practice:
1. Apply large edits on staging or during maintenance windows.
2. Keep automatic backups before major region operations.
3. Use conservative selection + mask constraints before destructive commands.

---

## Core Selection Workflow

### Selection modes

Most common cuboid flow:

```mcfunction
//wand
//pos1
//pos2
//size
```

Fast alternatives:

```mcfunction
//hpos1
//hpos2
//chunk
//expand 20 up
//expand 20 down
```

Selection safety checks:
- always run `//size` before `//set`, `//replace`, or `//paste`
- use `//distr` to preview block composition before replacement

---

## Region Operations

### High-frequency operations

```mcfunction
//set stone
//replace stone andesite
//replace water air
//walls stone_bricks
//overlay grass_block
//smooth 3
```

### Masks and filtered replacements

Use masks to constrain scope:

```mcfunction
//gmask #natural
//replace grass_block dirt
//gmask
```

Single-command mask approach:

```mcfunction
//replace #stone !air
//replace !#leaves air
```

Pattern examples:

```mcfunction
//set 70%stone,20%andesite,10%cobblestone
//replace dirt 60%coarse_dirt,40%podzol
```

---

## Clipboard and Schematic Workflows

### Clipboard basics

```mcfunction
//copy
//rotate 90
//flip east
//paste -a
```

Use `-a` when you want to skip air blocks during paste.

### Schematic workflow

```mcfunction
//schem save spawn-hub-v3
//schem list
//schem load spawn-hub-v3
//paste -a
```

Operational guidance:
- use versioned names (`arena-mid-2026-03-27`)
- keep read-only archive copies for rollback
- pair each major paste with an immediate backup checkpoint

---

## Brushes and Terraforming

### Practical brush setup

```mcfunction
//brush sphere stone 4
//brush smooth 3
//brush raise 2
//brush lower 2
//mask #natural
```

Reset brush:

```mcfunction
//none
```

Terraforming safety:
- start with small radius (3-5) and iterate
- keep masks active to avoid damaging structures
- run periodic `//undo` checkpoints during long sessions

---

## Undo, History, and Safety

### History commands

```mcfunction
//undo
//undo 5
//redo
//clearhistory
```

Safety policy for production operations:
1. Create backup checkpoint.
2. Perform one logical batch of edits.
3. Validate with visual walkthrough.
4. Continue or `//undo` immediately.

Do not chain many destructive edits without intermediate verification.

---

## Practical Runbooks

## Runbook: Spawn Editing Refresh

- Select spawn zone and run `//size`.
- Snapshot:

```mcfunction
//copy
//schem save spawn-before-refresh
```

- Apply constrained replacements and overlays.
- Smooth terrain edges:

```mcfunction
//smooth 2
```

- Validate spawn safety (voids, lighting, navigation).
- Save final state:

```mcfunction
//schem save spawn-after-refresh
```

## Runbook: Arena Reset Between Matches

- Keep a pristine arena schematic.
- After each match:

```mcfunction
//schem load arena-pristine
//paste -a
```

- Rebuild only arena boundary if needed.
- Validate command blocks/signals associated with arena logic.

## Runbook: Block Cleanup (Lag and Visual Noise)

Typical cleanup targets:
- dropped scaffolding builds
- accidental fluid spread
- excessive leaf/log leftovers

Example cleanup sequence:

```mcfunction
//replace lava air
//replace water air
//replace #leaves air
```

Always scope with selection/mask first to avoid map-wide accidental edits.

## Runbook: Path Shaping and Terrain Blend

- Select corridor/path footprint.
- Build mixed surface:

```mcfunction
//set 50%dirt_path,30%coarse_dirt,20%gravel
```

- Blend edges with low-radius smooth brush.
- Add retaining borders (`stone_bricks`, `andesite`) where elevation changes.

---

## Operational Guardrails

- Never run broad replacements from global/world scope.
- Confirm selection size before every destructive command.
- Keep a restoration schematic for each major build zone.
- Coordinate edits with other staff to avoid overlapping operations.
- Validate WorldEdit limits/permissions by role to prevent accidental mass edits.

---

## References

- https://worldedit.enginehub.org/en/latest/
- https://worldedit.enginehub.org/en/latest/usage/
- https://worldedit.enginehub.org/en/latest/usage/regions/selections/
- https://worldedit.enginehub.org/en/latest/usage/general/masks/
- https://worldedit.enginehub.org/en/latest/usage/clipboard/
- https://worldedit.enginehub.org/en/latest/usage/tools/brushes/
