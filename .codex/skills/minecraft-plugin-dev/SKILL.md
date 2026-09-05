---
name: minecraft-plugin-dev
description: "Create, modify, and debug server plugins for current Paper 26.x on Java 25 or legacy Bukkit-derived 1.21.x servers on Java 21. Use for JavaPlugin APIs, events, commands, schedulers, configuration, PDC, and Adventure, not client mods or vanilla datapacks."
---

# Minecraft Plugin Development Skill

## Platform Overview

| Platform | Base API | Notes |
|----------|----------|-------|
| **Paper** | Bukkit/Spigot + Paper extensions | Recommended; async chunk loading, Adventure native |
| **Spigot** | Bukkit + Spigot extensions | Legacy; fewer APIs, slower |
| **Bukkit** | Base API only | Avoid for new plugins |
| **Folia** | Paper fork | Region-threaded; requires special scheduler APIs |

> Paper is the recommended target. Paper includes all Bukkit and Spigot APIs plus
> significant performance improvements and additional APIs.

### Routing Boundaries
- `Use when`: the target is server-side Paper/Bukkit/Spigot plugin behavior with JavaPlugin APIs.
- `Do not use when`: the task requires client-side installable mods or loader APIs (`minecraft-modding` / `minecraft-multiloader`).
- `Do not use when`: the task is pure vanilla datapack/command content (`minecraft-datapack` / `minecraft-commands-scripting`).

## Bundled References

- Read `references/runtime-patterns.md` when the task touches scheduling, Folia support, PDC, Adventure/MiniMessage, YAML config, Vault, or Paper-specific APIs.
- Read `references/paper-plugin-commands.md` for a Paper-only `paper-plugin.yml` project or Brigadier command registration.

---

## Project Setup

The examples below target current Paper 26.2 and Java 25. For an existing
1.21.x plugin, preserve its `1.21.x-R0.1-SNAPSHOT` dependency, Java 21
toolchain, and matching `api-version` until the project is intentionally ported.

### `settings.gradle.kts`
```kotlin
rootProject.name = "my-plugin"
```

### `build.gradle.kts`
```kotlin
plugins {
    java
}

group = "com.example"
version = "1.0.0-SNAPSHOT"

repositories {
    mavenCentral()
    maven("https://repo.papermc.io/repository/maven-public/")
}

dependencies {
    compileOnly("io.papermc.paper:paper-api:26.2.build.+")
}

java {
    toolchain.languageVersion.set(JavaLanguageVersion.of(25))
}

tasks {
    processResources {
        // Substitutes ${version} in plugin.yml with the Gradle project version
        filesMatching(listOf("plugin.yml", "paper-plugin.yml")) {
            expand("version" to project.version)
        }
    }
}
```

Add Shadow only when the plugin has runtime libraries that must be bundled and
relocated. Paper and optional plugin APIs such as Vault remain `compileOnly` and
must not be shaded into the plugin JAR.

### `gradle/wrapper/gradle-wrapper.properties`
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-9.1.0-bin.zip
```

Gradle 8.8 cannot run on Java 25. Use Gradle 9.1 or newer for a current Java 25
project. Preserve the existing wrapper and Java 21 toolchain for a legacy 1.21.x
project unless its build is intentionally upgraded and verified.

---

## Project Layout
```
my-plugin/
├── build.gradle.kts
├── settings.gradle.kts
├── gradle/
│   └── wrapper/
│       └── gradle-wrapper.properties
└── src/main/
    ├── java/com/example/myplugin/
    │   ├── MyPlugin.java          ← main class (extends JavaPlugin)
    │   ├── listeners/
    │   │   └── PlayerListener.java
    │   ├── commands/
    │   │   └── MyCommand.java
    │   └── managers/
    │       └── DataManager.java
    └── resources/
        ├── plugin.yml            ← Bukkit-compatible descriptor
        ├── paper-plugin.yml      ← active descriptor for a Paper plugin
        └── config.yml
```

---

## Core Files

### `plugin.yml` (Bukkit-compatible default)
```yaml
name: MyPlugin
version: "${version}"
main: com.example.myplugin.MyPlugin
description: An example Paper plugin
author: YourName
website: https://github.com/example/my-plugin
api-version: '26.2'

commands:
  myplugin:
    description: Main plugin command
    usage: /myplugin <subcommand>
    permission: myplugin.use
    aliases: [mp]

permissions:
  myplugin.use:
    description: Allows use of /myplugin
    default: true
  myplugin.admin:
    description: Admin access
    default: op
```

> Match `api-version` to the oldest Paper API the plugin intentionally supports.
> Current Paper examples use `26.2`; legacy `1.21` and positive `1.21.<patch>`
> values remain valid for older servers. A server older than the declared value
> refuses to load the plugin.

### `paper-plugin.yml` (experimental Paper-only format)

Prefer `plugin.yml` for Bukkit-compatible plugins. Use `paper-plugin.yml` only
when the JAR is intentionally Paper-only and needs Paper-plugin behavior such
as bootstrapping, loaders, or classloading isolation. It can be the only
descriptor, but is not a drop-in replacement: Paper plugins do not use a
`commands` field or `getCommand(...)` registration. Read
[`references/paper-plugin-commands.md`](references/paper-plugin-commands.md)
for the paired descriptor, main class, and Brigadier lifecycle registration.

When one JAR ships both descriptors, keep their shared metadata and main class
aligned. Do not combine the Paper-only sample with the Bukkit-compatible
`MyPlugin` sample below.

### Bukkit-compatible main class
```java
package com.example.myplugin;

import com.example.myplugin.commands.MyCommand;
import com.example.myplugin.listeners.PlayerListener;
import org.bukkit.plugin.java.JavaPlugin;

public final class MyPlugin extends JavaPlugin {

    @Override
    public void onEnable() {
        saveDefaultConfig();

        // Register listeners
        getServer().getPluginManager().registerEvents(new PlayerListener(), this);

        // Register commands
        var cmd = getCommand("myplugin");
        if (cmd == null) {
            throw new IllegalStateException("myplugin command is missing from plugin.yml");
        }
        var handler = new MyCommand(this);
        cmd.setExecutor(handler);
        cmd.setTabCompleter(handler);

        getLogger().info("MyPlugin enabled!");
    }

    @Override
    public void onDisable() {
        getLogger().info("MyPlugin disabled.");
    }

}
```

---

## Event Listeners

```java
package com.example.myplugin.listeners;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.NamedTextColor;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.PlayerDeathEvent;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.event.player.PlayerQuitEvent;

public class PlayerListener implements Listener {

    @EventHandler(priority = EventPriority.NORMAL)
    public void onPlayerJoin(PlayerJoinEvent event) {
        event.joinMessage(
            Component.text(event.getPlayer().getName() + " joined!", NamedTextColor.GREEN)
        );
    }

    @EventHandler
    public void onPlayerQuit(PlayerQuitEvent event) {
        event.quitMessage(
            Component.text(event.getPlayer().getName() + " left.", NamedTextColor.YELLOW)
        );
    }

    @EventHandler
    public void onPlayerDeath(PlayerDeathEvent event) {
        // Modify death message using Adventure components
        event.deathMessage(
            Component.text("☠ ", NamedTextColor.RED)
                .append(Component.text(event.getPlayer().getName(), NamedTextColor.WHITE))
                .append(Component.text(" died!", NamedTextColor.RED))
        );
    }
}
```

### EventPriority order
`LOWEST → LOW → NORMAL → HIGH → HIGHEST → MONITOR`  
Use `MONITOR` for logging only (never modify outcome). On events that implement
`Cancellable`, use `ignoreCancelled = true` unless you need cancelled events.

### Cancellable events
```java
@EventHandler
public void onBlockBreak(BlockBreakEvent event) {
    if (event.getPlayer().hasPermission("myplugin.break.deny")) {
        event.setCancelled(true);
        event.getPlayer().sendMessage(Component.text("You cannot break blocks!", NamedTextColor.RED));
    }
}
```

---

## Commands

This section is for the `plugin.yml` path above. Its declared command enables
`getCommand("myplugin")`. For a Paper-only descriptor, use the Brigadier
lifecycle example in [`references/paper-plugin-commands.md`](references/paper-plugin-commands.md).

```java
package com.example.myplugin.commands;

import com.example.myplugin.MyPlugin;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.NamedTextColor;
import org.bukkit.command.Command;
import org.bukkit.command.CommandExecutor;
import org.bukkit.command.CommandSender;
import org.bukkit.command.TabCompleter;
import org.bukkit.entity.Player;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.util.List;
import java.util.Locale;

public class MyCommand implements CommandExecutor, TabCompleter {

    private final MyPlugin plugin;

    public MyCommand(MyPlugin plugin) {
        this.plugin = plugin;
    }

    @Override
    public boolean onCommand(@NotNull CommandSender sender, @NotNull Command command,
                             @NotNull String label, @NotNull String[] args) {
        if (!(sender instanceof Player player)) {
            sender.sendMessage(Component.text("Only players can use this command.", NamedTextColor.RED));
            return true;
        }

        if (!player.hasPermission("myplugin.use")) {
            player.sendMessage(Component.text("No permission.", NamedTextColor.RED));
            return true;
        }

        if (args.length == 0) {
            player.sendMessage(Component.text("Usage: /myplugin <reload|info>", NamedTextColor.YELLOW));
            return true;
        }

        return switch (args[0].toLowerCase(Locale.ROOT)) {
            case "reload" -> {
                plugin.reloadConfig();
                player.sendMessage(Component.text("Config reloaded.", NamedTextColor.GREEN));
                yield true;
            }
            case "info" -> {
                player.sendMessage(Component.text("Version: " + plugin.getDescription().getVersion(), NamedTextColor.AQUA));
                yield true;
            }
            default -> {
                player.sendMessage(Component.text("Unknown subcommand.", NamedTextColor.RED));
                yield true;
            }
        };
    }

    @Override
    public @Nullable List<String> onTabComplete(@NotNull CommandSender sender, @NotNull Command command,
                                                @NotNull String label, @NotNull String[] args) {
        if (args.length == 1) {
            return List.of("reload", "info").stream()
                .filter(s -> s.startsWith(args[0].toLowerCase(Locale.ROOT)))
                .toList();
        }
        return List.of();
    }
}
```

---

## Schedulers

For classic Paper plugins, `BukkitScheduler` is still fine. If you claim Folia support,
route player, entity, region, global, and async work through the matching Folia-aware
scheduler. Keep scheduling behind a small project-local interface when one plugin must
support both Paper and Folia.

See `references/runtime-patterns.md` for copy-ready sync, async, cancelable, and
Folia-safe scheduler examples.

---

## Persistent Data Container (PDC)

PDC stores arbitrary data on any `PersistentDataHolder` (players, entities, items, chunks).
Data is saved with the world and persists across restarts.

Create `NamespacedKey` instances once, keep data types stable after release, and use
PDC for small metadata rather than large datasets. Prefer config files or a database
for large or query-heavy plugin state.

See `references/runtime-patterns.md` for player, item, chunk, and world PDC examples.

---

## Adventure Text Components

Paper uses [Adventure](https://docs.advntr.dev/) natively for all text. No legacy chat colors.
Use `Component` builders for code-owned messages and MiniMessage for config-driven
messages. Avoid legacy `ChatColor` unless the target project already depends on it
for compatibility.

See `references/runtime-patterns.md` for simple messages, hover/click events,
MiniMessage parsing, titles, and action bars.

---

## Configuration (YAML)

### `src/main/resources/config.yml`
```yaml
# Default config
settings:
  max-players: 20
  welcome-message: "<green>Welcome to the server!"
  cooldown-seconds: 30

database:
  host: localhost
  port: 3306
  name: myplugin_db
```

### Accessing config values
Call `saveDefaultConfig()` in `onEnable()`, provide explicit defaults when reading
values, and validate config shape before starting long-running tasks.

### Custom config file
Use custom YAML files only when separating user config from mutable plugin data is
worth the extra file handling. Keep blocking disk writes off hot event paths.

See `references/runtime-patterns.md` for config read/write and custom YAML examples.

---

## Vault Integration (Economy / Permissions)

Declare Vault as `compileOnly`, soft-depend on it in plugin metadata, and disable
economy features cleanly when the service provider is unavailable. Never assume a
Vault-compatible economy plugin is installed just because Vault itself is present.

When Vault support is required, add the JitPack repository and
`compileOnly("com.github.MilkBowl:VaultAPI:1.7")` to the Gradle build.

See `references/runtime-patterns.md` for a minimal economy setup and charge example.

---

## Paper-Specific APIs

Use Paper APIs when they remove main-thread blocking or simplify Adventure-native
behavior. Keep optional plugin integrations behind presence checks and metadata
soft-dependencies.

See `references/runtime-patterns.md` for async chunk loading, custom item meta,
profile lookup, and protection-plugin integration examples.

---

## Common Tasks Checklist

### Creating a new event listener
- [ ] Create class implementing `Listener`
- [ ] Annotate methods with `@EventHandler`
- [ ] Call `getServer().getPluginManager().registerEvents(listener, plugin)` in `onEnable()`
- [ ] On cancellable events, add `ignoreCancelled = true` unless you need cancelled events

### Adding a new command
- [ ] For a Bukkit-compatible plugin, define the command in `plugin.yml`, create a `CommandExecutor`, and register it with `getCommand("name")`
- [ ] For a Paper-only plugin, register the command through `LifecycleEvents.COMMANDS`; do not add a `commands` field

### Saving plugin data
- [ ] For simple values: use `config.yml` via `getConfig()` / `saveConfig()`
- [ ] For per-entity data: use PDC with a `NamespacedKey`
- [ ] For large datasets: use async scheduler + file I/O or a database

### Scheduling a repeating task
- [ ] Determine if task needs main thread (use `runTaskTimer`) or is I/O (use `runTaskTimerAsynchronously`)
- [ ] Store the `BukkitTask` reference so you can cancel in `onDisable()`
- [ ] Cancel all tasks in `onDisable()` or use `getServer().getScheduler().cancelTasks(plugin)`

---

## Build, Validate, and Run

1. Build the plugin JAR:
   ```bash
   ./gradlew build
   # Output: build/libs/my-plugin-1.0.0-SNAPSHOT.jar
   ```
2. Run the bundled validator to catch config and layout errors:
   ```bash
   ./scripts/validate-plugin-layout.sh --root /path/to/plugin-project
   # Strict mode treats warnings as failures:
   ./scripts/validate-plugin-layout.sh --root /path/to/plugin-project --strict
   ```
   The validator requires Node and includes its own YAML parser for descriptor checks.
3. Fix any reported errors and re-run until clean.
4. Deploy: copy the built JAR to `server/plugins/` and restart the Paper server.
   If the real project already applies a Paper dev-server plugin such as `xyz.jpenilla.run-paper`,
   use that project's documented dev task instead of assuming `./gradlew runServer` exists.

The validator checks:
- active `plugin.yml` or `paper-plugin.yml` required keys (`name`, `version`, `main`, `api-version`) and repo-supported current `26.<release>` or legacy `1.21` / positive `1.21.<patch>` values, with warnings for versions newer than the documented examples
- cross-descriptor metadata consistency when both descriptors are present; `paper-plugin.yml` is selected as active
- Active main class path exists and extends `JavaPlugin`
- actual server `/reload` anti-patterns such as `Bukkit.reload()` or dispatching the server reload command

---

## References

- Paper API Javadoc: https://jd.papermc.io/paper/
- Paper plugin descriptor: https://docs.papermc.io/paper/dev/plugin-yml/
- Paper plugins: https://docs.papermc.io/paper/dev/getting-started/paper-plugins/
- Paper Brigadier registration: https://docs.papermc.io/paper/dev/command-api/basics/registration/
- Gradle Java compatibility: https://docs.gradle.org/current/userguide/compatibility.html
- Adventure (text API): https://docs.advntr.dev/
- MiniMessage format: https://docs.advntr.dev/minimessage/format.html
- Vault API: https://github.com/MilkBowl/VaultAPI
- Bukkit API Javadoc: https://javadoc.io/doc/org.bukkit/bukkit/
- run-task Gradle plugin: https://github.com/jpenilla/run-task
