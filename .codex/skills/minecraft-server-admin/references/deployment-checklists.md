# Minecraft Server Admin Checklists

Load this file when the task needs a compact operational checklist rather than a
full prose playbook.

## New Server Bring-Up

- Confirm target platform: Paper, Purpur, Folia, Velocity network, Fabric, or NeoForge.
- Record Minecraft version, Java version, and plugin/mod compatibility constraints.
- Create initial backups path and retention policy before first public launch.
- Lock down firewall rules so only intended ports are exposed.
- Verify startup, join flow, world save path, and log location.
- Run a baseline performance capture before adding more plugins or mods.

## Proxy Change Window

- Confirm forwarding mode and shared secret on both Velocity and backend.
- Block direct public access to backend servers.
- Test staff login, normal player login, permissions, and skin/profile forwarding.
- Keep previous proxy config and backend config available for immediate rollback.

## Performance Investigation

- Capture current MSPT/TPS and player count before changing configs.
- Run Spark or equivalent profiling before tuning view distance or entity rules.
- Change one tuning area at a time: chunks, entities, plugins, or JVM.
- Re-measure after every change under similar load.

## Backup and Recovery Drill

- Verify latest full backup and latest incremental backup exist.
- Restore to a staging path first, not over production.
- Confirm world folders, plugin configs, and player data load correctly.
- For Fabric/NeoForge, confirm the restore includes `mods/` plus the recorded
  loader, Java, launch arguments, and deployment manifests.
- For a live RCON backup, confirm its tested sequence is `save-off`,
  `save-all`, copy, then guaranteed `save-on` cleanup. Use a clean stop or
  verified platform snapshot for Folia because it disables `save-all`.
- Measure actual restore time and compare it to the target `RTO`.

## Security Hardening Quick Pass

- Disable unused admin surfaces such as RCON unless deliberately required.
- Keep secrets off public repos and shared screenshots.
- Review operator permissions, LuckPerms groups, and panel access.
- Confirm scheduled backups, update windows, and incident contacts are documented.
