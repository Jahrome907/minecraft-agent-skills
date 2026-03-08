---
name: minecraft-server-admin
description: >
  Set up, configure, and optimize a Minecraft Java Edition server for 1.21.x. Covers
  Paper server installation and startup (Aikar's JVM flags), server.properties reference,
  paper-global.yml and paper-world-defaults.yml configuration for performance, spigot.yml
  and bukkit.yml tuning, chunk loading/unloading optimization, player count and TPS
  monitoring, plugin management best practices, world management (pre-generation with
  Chunky), backup strategies, Docker/Pterodactyl deployment, Velocity proxy setup for
  multi-server networks, Geyser for Bedrock crossplay, and performance profiling with
  Spark. Use for server operations and infrastructure — not for plugin or mod development.
---

# Minecraft Server Administration Skill

## Server Software Comparison

| Software | Base | Use Case |
|----------|------|---------|
| **Paper** | Spigot | Recommended for most servers; best performance + plugin compatibility |
| **Purpur** | Paper | Additional gameplay config options |
| **Velocity** | Proxy | Multi-server network proxy (modern replacement for BungeeCord) |
| **Folia** | Paper | Region-threaded; for very high player-count servers |
| **Fabric** / **NeoForge** | Vanilla | Mod servers (no Bukkit plugin support) |

### Routing Boundaries
- `Use when`: the task is server operations, deployment, performance tuning, networking/proxy setup, backups, or security hardening.
- `Do not use when`: the task is writing plugin/mod/gameplay code (`minecraft-plugin-dev`, `minecraft-modding`, `minecraft-multiloader`).
- `Do not use when`: the task is authoring datapack/resource-pack content (`minecraft-datapack`, `minecraft-resource-pack`).

---

## Initial Server Setup

```bash
# Download Paper
curl -O "https://api.papermc.io/v2/projects/paper/versions/1.21.1/builds/latest/downloads/paper-1.21.1-latest.jar"
# Or check https://papermc.io/downloads/paper for latest build

mkdir minecraft-server && mv paper-*.jar minecraft-server/server.jar
cd minecraft-server

# Accept EULA
echo "eula=true" > eula.txt

# Start script (see JVM flags below)
```

---

## Aikar's JVM Flags (Recommended)

For servers with **≥12 GB RAM** (adjust `-Xms` / `-Xmx` to your available RAM):

```bash
java -Xms10G -Xmx10G \
  -XX:+UseG1GC \
  -XX:+ParallelRefProcEnabled \
  -XX:MaxGCPauseMillis=200 \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC \
  -XX:+AlwaysPreTouch \
  -XX:G1NewSizePercent=30 \
  -XX:G1MaxNewSizePercent=40 \
  -XX:G1HeapRegionSize=8M \
  -XX:G1ReservePercent=20 \
  -XX:G1HeapWastePercent=5 \
  -XX:G1MixedGCCountTarget=4 \
  -XX:InitiatingHeapOccupancyPercent=15 \
  -XX:G1MixedGCLiveThresholdPercent=90 \
  -XX:G1RSetUpdatingPauseTimePercent=5 \
  -XX:SurvivorRatio=32 \
  -XX:+PerfDisableSharedMem \
  -XX:MaxTenuringThreshold=1 \
  -Dusing.aikars.flags=https://aikar.co/2018/07/02/aikars-new-server-startup-script/ \
  -Dfile.encoding=UTF-8 \
  -jar server.jar --nogui
```

For servers with **<12 GB RAM**, use `-XX:G1HeapRegionSize=4M` and `-XX:G1NewSizePercent=20`.

### Startup script `start.sh`
```bash
#!/usr/bin/env bash
MEMORY="10G"
JAR="server.jar"

exec java \
  -Xms${MEMORY} -Xmx${MEMORY} \
  -XX:+UseG1GC \
  -XX:+ParallelRefProcEnabled \
  -XX:MaxGCPauseMillis=200 \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC \
  -XX:+AlwaysPreTouch \
  -XX:G1NewSizePercent=30 \
  -XX:G1MaxNewSizePercent=40 \
  -XX:G1HeapRegionSize=8M \
  -XX:G1ReservePercent=20 \
  -XX:G1HeapWastePercent=5 \
  -XX:G1MixedGCCountTarget=4 \
  -XX:InitiatingHeapOccupancyPercent=15 \
  -XX:G1MixedGCLiveThresholdPercent=90 \
  -XX:G1RSetUpdatingPauseTimePercent=5 \
  -XX:SurvivorRatio=32 \
  -XX:+PerfDisableSharedMem \
  -XX:MaxTenuringThreshold=1 \
  -Dfile.encoding=UTF-8 \
  -jar "${JAR}" --nogui
```

---

## `server.properties` Key Settings

```properties
# Network
server-port=25565
online-mode=true              # false for Velocity/BungeeCord with offline-mode forwarding
server-ip=                    # blank = bind all interfaces

# World
level-name=world
gamemode=survival
difficulty=normal
max-players=100
view-distance=10              # lower = better performance (8-12 is normal)
simulation-distance=10        # how far entities simulate (6-8 for perf)
spawn-protection=16
allow-nether=true
allow-end=true

# Performance
max-tick-time=60000           # milliseconds before watchdog kills (increase if needed)
sync-chunk-writes=true

# Resource pack
resource-pack=https://example.com/pack.zip
resource-pack-sha1=

# RCON (for remote management)
enable-rcon=false
rcon.port=25575
rcon.password=CHANGE_THIS

# Query
enable-query=false
query.port=25565
```

---

## Paper Configuration (`config/paper-global.yml`)

Key settings — these are the most impactful for performance:

```yaml
# config/paper-global.yml

chunk-system:
  io-threads: 4               # increase for SSD servers

misc:
  # Reduce log spam
  chat-thread-check-interval: -1

packet-limiter:
  all-packets:
    action: KICK
    max-packet-rate: 500.0

timings:
  enabled: false              # disable for production (use Spark instead)

watchdog:
  early-warning-every: 5000
  early-warning-delay: 10000
```

---

## Paper World Config (`config/paper-world-defaults.yml`)

```yaml
# config/paper-world-defaults.yml

chunks:
  auto-save-interval: default    # or set in ticks (6000 = 5 min)
  delay-chunk-unloads-by: 10s
  entity-per-chunk-save-limit:
    arrow: 16
    dragon_fireball: 3
    fireworks_rocket: 8
    snowball: 8
    falling_block: 8
    painting: 16
  fixed-chunk-inhabited-time: -1
  max-auto-save-chunks-per-tick: 24
  prevent-moving-into-unloaded-chunks: false

entities:
  spawning:
    all-chunks-are-slime-chunks: false
    count-all-mobs-for-spawning: false
    creative-arrow-despawn-rate: -1
    despawn-ranges:             # reduce for fewer loaded entities
      ambient:
        hard: 128
        soft: 32
      axolotls:
        hard: 128
        soft: 32
      creature:
        hard: 128
        soft: 32
      misc:
        hard: 128
        soft: 32
      monster:
        hard: 128
        soft: 32
      underground_water_creature:
        hard: 64
        soft: 32
      water_ambient:
        hard: 64
        soft: 32
      water_creature:
        hard: 128
        soft: 32
    duplicate-uuid:
      delete-invalid: true
      mode: SAFE_REGEN
    mob-spawner-tick-rate: 2
    non-player-arrow-despawn-rate: -1
    per-player-mob-spawns: true  # important — prevents mob spawn farms from breaking
    spawn-limits:
      ambient: -1
      axolotls: -1
      creature: -1
      monster: -1
      underground_water_creature: -1
      water_ambient: -1
      water_creature: -1

environment:
  disable-thunder: false
  disable-ice-and-snow: false
  frosted-ice:
    delay:
      max: 40
      min: 20
    enabled: true

misc:
  max-loads-per-projectile: 10
  redstone-implementation: VANILLA   # ALTERNATE_CURRENT for Alternate Current algorithm
  shield-blocking-delay: 5
```

---

## `bukkit.yml` Key Settings

```yaml
spawn-limits:
  monsters: 70               # max monsters per world (lower = better TPS)
  animals: 10
  water-animals: 5
  water-ambient: 20
  water-underground-creature: 5
  axolotls: 5
  ambient: 15

ticks-per:
  animal-spawns: 400           # how often animals try to spawn (higher = less frequent)
  monster-spawns: 1
  water-spawns: 1
  water-ambient-spawns: 1
  water-underground-creature-spawns: 1
  axolotl-spawns: 1
  ambient-spawns: 1
  autosave: 6000               # ticks between autosaves (6000 = 5 min)

chunk-gc:
  period-in-ticks: 600        # how often to unload unused chunks
```

---

## `spigot.yml` Key Settings

```yaml
world-settings:
  default:
    mob-spawn-range: 6         # radius for mob spawning (reduce for perf)
    entity-activation-range:
      animals: 32
      monsters: 32
      misc: 16
      water: 16
      flying-monsters: 32
      traders: 48
      villagers: 32
      wake-up-inactive:
        animals-every: 1200
        animals-for: 100
        animals-max-per-tick: 4
        monsters-every: 400
        monsters-for: 100
        monsters-max-per-tick: 8
        villagers-every: 600
        villagers-for: 100
        villagers-max-per-tick: 4
        flying-monsters-every: 200
        flying-monsters-for: 100
        flying-monsters-max-per-tick: 8
    merge-radius:
      exp: 3.0
      item: 2.5
    ticks-per:
      animal-spawns: 400       # how often animals try to spawn (higher = less frequent)
      monster-spawns: 1
      autosave: 6000

settings:
  save-user-cache-on-stop-only: false
  restart-on-crash: true
  restart-script: ./start.sh
  netty-threads: 4
```

---

## TPS and Performance Monitoring

```bash
# In-game
/tps                        # shows TPS (20 = perfect)
/mspt                       # milliseconds per tick

# Spark profiler (highly recommended plugin)
/spark tps
/spark profiler start
/spark profiler stop         # generates report URL
/spark heapdump              # heap dump for memory analysis
/spark health               # quick server health overview
```

Target metrics:
- **TPS**: aim for 19.5+ (20 is perfect)
- **MSPT**: aim for <50ms (50ms = minimum for 20 TPS)
- **Memory**: keep GC pauses below 200ms

---

## Pre-generating the World (Chunky)

Pre-generating chunks prevents TPS drops as players explore new areas.

```bash
# Install Chunky plugin (https://hangar.papermc.io/pop4959/Chunky)
# In-game:
/chunky world world
/chunky center 0 0
/chunky radius 5000          # generates 5000-block radius
/chunky start

/chunky status               # check progress
/chunky pause
/chunky continue
/chunky cancel
```

---

## Backup Strategy

### Simple file backup script
```bash
#!/usr/bin/env bash
# backup.sh — run via cron
set -euo pipefail

SERVER_DIR="/opt/minecraft"
BACKUP_DIR="/backups/minecraft"
DATE=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=7

mkdir -p "$BACKUP_DIR"

# Announce and disable saving
mcrcon -H localhost -P 25575 -p "$RCON_PASSWORD" "say Server backup starting..."
mcrcon -H localhost -P 25575 -p "$RCON_PASSWORD" "save-off"
mcrcon -H localhost -P 25575 -p "$RCON_PASSWORD" "save-all flush"

# Backup worlds
tar -czf "$BACKUP_DIR/world_${DATE}.tar.gz" -C "$SERVER_DIR" world world_nether world_the_end

# Re-enable saving
mcrcon -H localhost -P 25575 -p "$RCON_PASSWORD" "save-on"
mcrcon -H localhost -P 25575 -p "$RCON_PASSWORD" "say Backup complete!"

# Delete old backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +${KEEP_DAYS} -delete

echo "Backup complete: world_${DATE}.tar.gz"
```

```bash
# Add to crontab (runs every 6 hours)
0 */6 * * * /opt/minecraft/backup.sh >> /var/log/mc-backup.log 2>&1
```

---

## Docker Deployment

### `docker-compose.yml`
```yaml
services:
  minecraft:
    image: itzg/minecraft-server:latest
    container_name: minecraft
    environment:
      EULA: "TRUE"
      TYPE: "PAPER"
      VERSION: "1.21.1"
      MEMORY: "8G"
      JVM_XX_OPTS: >-
        -XX:+UseG1GC
        -XX:+ParallelRefProcEnabled
        -XX:MaxGCPauseMillis=200
        -XX:+UnlockExperimentalVMOptions
        -XX:+DisableExplicitGC
        -XX:+AlwaysPreTouch
        -XX:G1NewSizePercent=30
        -XX:G1MaxNewSizePercent=40
        -XX:G1HeapRegionSize=8M
        -XX:G1ReservePercent=20
        -XX:G1HeapWastePercent=5
        -XX:G1MixedGCCountTarget=4
        -XX:InitiatingHeapOccupancyPercent=15
        -XX:G1MixedGCLiveThresholdPercent=90
        -XX:G1RSetUpdatingPauseTimePercent=5
        -XX:SurvivorRatio=32
        -XX:+PerfDisableSharedMem
        -XX:MaxTenuringThreshold=1
        -Dfile.encoding=UTF-8
    ports:
      - "25565:25565"
    volumes:
      - ./data:/data
    restart: unless-stopped
    tty: true
    stdin_open: true
```

```bash
docker compose up -d

# Send commands
docker exec minecraft rcon-cli "list"

# View logs
docker compose logs -f minecraft
```

---

## Velocity Proxy (Multi-Server Network)

Velocity is a high-performance proxy for connecting multiple backend servers.

### `velocity.toml` (key settings)
```toml
bind = "0.0.0.0:25577"
motd = "<aqua>My Network"
show-max-players = 100
online-mode = true
player-info-forwarding-mode = "MODERN"   # "LEGACY" for BungeeCord compat
forwarding-secret-file = "forwarding.secret"  # auto-generated; share with backends

[servers]
lobby   = "127.0.0.1:25565"
survival = "127.0.0.1:25566"
minigames = "127.0.0.1:25567"

try = ["lobby"]   # servers to try on initial join

[forced-hosts]
"survival.example.com" = ["survival"]

[advanced]
compression-threshold = 256
connection-timeout = 5000
read-timeout = 30000
```

### Backend server config for Velocity
In `config/paper-global.yml` on each backend:
```yaml
proxies:
  velocity:
    enabled: true
    online-mode: true
    secret: "your-velocity-forwarding-secret"   # must match velocity.toml forwarding-secret
```

And in `server.properties`:
```properties
online-mode=false   # Velocity handles auth
```

---

## Geyser (Bedrock Crossplay)

Geyser allows Bedrock Edition players to join Java Edition servers.

```bash
# Download Geyser-Spigot plugin
# https://geysermc.org/download
# Place in plugins/ folder and restart
```

### `plugins/Geyser-Spigot/config.yml` (key settings)
```yaml
bedrock:
  port: 19132              # Bedrock default port
  clone-remote-port: false
  motd1: "My Server"
  motd2: "Bedrock Welcome"

remote:
  address: auto            # auto-detect for same-server
  port: 25565
  auth-type: online        # online = require MS auth; floodgate = no Java account needed

# For auth-type: floodgate, also install Floodgate plugin
# https://geysermc.org/download#floodgate
```

### Firewall for Geyser
```bash
# Expose Bedrock port (UDP)
sudo ufw allow 19132/udp
```

> **Tip**: Install Floodgate alongside Geyser so Bedrock players don't need a Java account. Bedrock players get a `*` prefix by default.

---

## Pterodactyl Deployment

Pterodactyl is a web-based game server management panel.

### Install with Docker (Pterodactyl Wings)
```bash
# Wings is the daemon that runs on game server nodes.
# Install Docker first, then:
curl -L -o /usr/local/bin/wings \
  "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
chmod u+x /usr/local/bin/wings
```

### Key Setup Steps
1. **Panel**: Deploy the Pterodactyl Panel (web UI) on a separate host or the same machine.
2. **Node**: Add a node in the Panel pointing to the Wings daemon.
3. **Egg**: Use the built-in "Paper" egg (or import a custom egg for Purpur/Fabric).
4. **Allocation**: Assign ports (25565 for MC, 19132/udp for Geyser if needed).
5. **Server**: Create a server from the Panel UI — it auto-downloads Paper and sets JVM flags.

### Custom Startup Command (in Egg config)
```
java -Xms{{SERVER_MEMORY}}M -Xmx{{SERVER_MEMORY}}M -XX:+UseG1GC \
  -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 \
  -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC \
  -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 \
  -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M \
  -Dterminal.jline=false -Dterminal.ansi=true \
  -jar {{SERVER_JARFILE}} --nogui
```

> Pterodactyl docs: https://pterodactyl.io/project/introduction.html

---

## Plugin Management Best Practices

- **Source plugins from trusted sites only**: Modrinth, Hangar (PaperMC), SpigotMC, or GitHub releases.
- **Keep plugins updated**: Use `/version <plugin>` to check versions; subscribe to update notifications.
- **Minimize plugin count**: Each plugin adds tick overhead. Remove unused plugins rather than disabling them.
- **Test updates in staging**: Copy your server to a test environment before updating plugins on production.
- **Use a plugin manager** (optional): [Spark](https://spark.lucko.me/) can identify which plugins consume the most tick time.
- **Check compatibility**: After a Minecraft version upgrade, verify each plugin supports the new version before updating the server JAR.
- **Back up before changes**: Always take a full backup before adding, removing, or updating plugins.
- **Avoid `/reload`**: Use `/restart` or stop/start the server. `/reload` causes memory leaks and unpredictable plugin behavior.

---

## Security Checklist

- [ ] Set a strong `rcon.password` or disable RCON if not needed
- [ ] Use `online-mode=true` (or Velocity with modern forwarding — not offline-mode without a proxy)
- [ ] Firewall: expose only port 25565 (and 25577 for Velocity) to the internet
- [ ] Run the server as a non-root user
- [ ] Set `max-players` appropriate to your hardware
- [ ] Use Paper's `packet-limiter` to prevent packet flood abuse
- [ ] Keep Paper and plugins updated (use `/version` to check)
- [ ] Store `rcon.password` in environment variables, not in committed config files

---

## References

- Aikar's flags: https://aikar.co/2018/07/02/aikars-new-server-startup-script/
- Paper docs: https://docs.papermc.io/paper/
- Velocity docs: https://docs.papermc.io/velocity/
- Spark profiler: https://spark.lucko.me/
- itzg/minecraft-server Docker: https://github.com/itzg/docker-minecraft-server
- Chunky: https://github.com/pop4959/Chunky
- YouHaveTrouble server optimization guide: https://github.com/YouHaveTrouble/minecraft-optimization
