---
name: minecraft-essentials-ops
description: >
  Operate EssentialsX on Minecraft 1.21.x servers with safe, practical admin workflows.
  Covers module scope, install and version-alignment checks, Vault economy integration,
  kits/warps/homes/spawn operations, permissions patterns, moderation workflows (mute, jail,
  tempban), and common config pitfalls. Use for EssentialsX operations, not plugin development.
---

# Minecraft EssentialsX Operations Skill

## Scope and Positioning

This skill focuses on **operating EssentialsX** on running servers.
It is not a general economics theory guide and not a plugin coding guide.

### Routing Boundaries
- `Use when`: the task is EssentialsX command, config, permissions, economy, or moderation operations.
- `Do not use when`: the task is generic server deployment/proxy/performance architecture (`minecraft-server-admin`).
- `Do not use when`: the task is writing Java plugin code (`minecraft-plugin-dev`).
- `Do not use when`: the task is WorldEdit selection/build workflows (`minecraft-worldedit-ops`).

---

## Module Overview and Install Notes

Common EssentialsX modules in production:
- `EssentialsX` (core commands and user tools)
- `EssentialsXChat`
- `EssentialsXSpawn`
- `EssentialsXProtect`

Operational install checklist:
1. Match EssentialsX build to your Paper/Spigot API generation.
2. Install `Vault` if using economy providers or permission/chat bridges.
3. Start server once and inspect logs for dependency warnings.
4. Keep plugin jar versions documented for rollback.

Version-alignment rule:
- update EssentialsX and companion plugins as a tested batch in staging first.

---

## Vault and Economy Basics

### Economy stack model

- EssentialsX can provide economy commands and balances.
- Vault provides a shared bridge so other plugins (shops, jobs, ranks) can read/write balances.

Verify provider chain:
1. Server starts without Vault hook errors.
2. Economy commands respond without permission errors.
3. Third-party plugin transactions affect balances consistently.

### Core economy commands

```mcfunction
/bal
/baltop
/pay Alex 250
/eco give Alex 1000
/eco take Alex 100
/eco reset Alex
```

Use admin economy commands through staff roles only.

---

## Shop Pricing and Sign Shops

If using EssentialsX signs and economy interactions:

1. Define pricing policy:
- starter-tier prices
- anti-inflation sinks
- admin-only item exceptions

1. Restrict sign creation permissions to trusted groups.
1. Validate buy/sell math after config changes.

Operational guardrails:
- never enable broad player access to unrestricted admin shop signs
- monitor rapid balance spikes for dupes/exploit patterns

---

## Kits, Warps, Homes, Nicknames, Spawn

### Kits operations

Typical kit lifecycle:
1. create/edit kit definition
2. set cooldown and permission
3. test with player-rank account

Common commands:

```mcfunction
/kit
/kit starter
/createkit starter
```

### Warps and homes

```mcfunction
/setwarp spawn
/setwarp market
/warp spawn
/sethome
/home
/delhome
```

Control limits through permissions and Essentials config values.

### Nicknames and spawn management

```mcfunction
/nick BuilderOne
/realname BuilderOne
/setspawn
/spawn
```

Keep nickname policy explicit for moderation and impersonation prevention.

---

## Permissions Patterns

Use a permission manager (for example LuckPerms) to model role tiers.

Suggested role intent:
- `admin`: full EssentialsX admin + moderation + economy controls
- `staff`: moderation and support commands, limited economy tools
- `player`: basic homes/warps/msg/pay with guardrails

Example permission outline:

```yaml
groups:
  admin:
    permissions:
      - essentials.*
  staff:
    permissions:
      - essentials.kick
      - essentials.mute
      - essentials.tempban
      - essentials.jail
      - essentials.warp
      - essentials.msg
  player:
    permissions:
      - essentials.home
      - essentials.sethome
      - essentials.delhome
      - essentials.spawn
      - essentials.warp
      - essentials.msg
      - essentials.pay
```

Avoid wildcard permissions outside trusted admin roles.

---

## Moderation Workflows

## Workflow: Mute

```mcfunction
/mute Alex 30m Chat abuse after warning
/unmute Alex
```

Practice:
- include reason and duration
- log escalation path for repeat behavior

## Workflow: Jail

```mcfunction
/setjail intake
/jail Alex intake 20m Griefing spawn edge
/unjail Alex
```

Practice:
- define clear jail reasons
- pair with rollback/repair actions when relevant

## Workflow: Temporary Ban

```mcfunction
/tempban Alex 7d Repeated harassment
/banip Alex Severe evasion case
/unban Alex
```

Practice:
- align durations with policy tiers
- document evidence and staff actor

---

## Config Pitfalls and Hardening Notes

Common pitfalls:
- mismatched EssentialsX/Vault/provider versions after partial plugin updates
- permissive wildcard grants that expose admin economy commands
- high home/warp limits causing navigation abuse or command spam
- inconsistent chat/nickname rules across staff shifts

Hardening checklist:
- keep a tested baseline config backup before edits
- change one policy area at a time (economy, homes, moderation, chat)
- run staff and player smoke tests after every config rollout
- maintain written policy mapping to command permissions

---

## Operations Runbook: Safe Config Rollout

1. Backup current Essentials config files.
2. Apply targeted config edits.
3. Reload only if plugin docs explicitly support live reload for changed sections.
4. Prefer maintenance restart for sensitive changes.
5. Validate:
- login flow
- homes/warps
- economy transactions
- moderation commands
1. Keep rollback bundle ready for immediate restore.

---

## References

- https://essentialsx.net/wiki/Home.html
- https://essentialsx.net/commands
- https://essentialsx.net/permissions
- https://essentialsx.net/wiki/Module-breakdown.html
- https://essentialsx.net/wiki/Configuration-file.html
- https://essentialsx.net/wiki/Sign-Tutorial.html
- https://www.spigotmc.org/resources/vault.34315/
