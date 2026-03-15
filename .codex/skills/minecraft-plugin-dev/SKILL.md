---
name: minecraft-plugin-dev
description: >
  Develop Minecraft server plugins using the Paper/Bukkit/Spigot API for Minecraft 1.21.x.
  Handles creating Paper plugins with JavaPlugin, event listeners with @EventHandler, 
  commands, schedulers (sync/async), Persistent Data Container (PDC), Adventure text components,
  Vault economy integration, BungeeCord/Velocity messaging, plugin.yml configuration,
  YAML config management, and Paper-specific enhancement APIs. Always targets Paper API
  1.21.x (Java 21) with Gradle (Kotlin DSL). Distinguishes plugin development from mod
  development: plugins run server-side only and do not require client installation.
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

---

## Project Setup

### `settings.gradle.kts`
```kotlin
rootProject.name = "my-plugin"
```

### `build.gradle.kts`
```kotlin
plugins {
    java
    id("com.gradleup.shadow") version "8.3.0"
}

group = "com.example"
version = "1.0.0-SNAPSHOT"

repositories {
    mavenCentral()
    maven("https://repo.papermc.io/repository/maven-public/")
    // For Vault (economy API)
    maven("https://jitpack.io")
}

dependencies {
    compileOnly("io.papermc.paper:paper-api:1.21.11-R0.1-SNAPSHOT")
    // Optional: Vault economy/permission integration
    compileOnly("com.github.MilkBowl:VaultAPI:1.7")
}

java {
    toolchain.languageVersion.set(JavaLanguageVersion.of(21))
}

tasks {
    processResources {
        // Substitutes ${version} in plugin.yml with the Gradle project version
        filesMatching("plugin.yml") {
            expand("version" to project.version)
        }
    }
    shadowJar {
        archiveClassifier.set("")
    }
    build {
        dependsOn(shadowJar)
    }
}
```

### `gradle/wrapper/gradle-wrapper.properties`
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.8-bin.zip
```

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
        ├── plugin.yml
        └── config.yml
```

---

## Core Files

### `plugin.yml` (required)
```yaml
name: MyPlugin
version: "${version}"
main: com.example.myplugin.MyPlugin
description: An example Paper plugin
author: YourName
website: https://github.com/example/my-plugin
api-version: '1.21.11'

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

> Paper 1.20.5+ supports major/minor/patch `api-version` values.
> Use `api-version: '1.21.11'` when you target that Paper patch specifically, or `api-version: '1.21'`
> only when you intentionally support the broader 1.21.x line.

### Main Plugin Class
```java
package com.example.myplugin;

import com.example.myplugin.commands.MyCommand;
import com.example.myplugin.listeners.PlayerListener;
import org.bukkit.plugin.java.JavaPlugin;

public final class MyPlugin extends JavaPlugin {

    private static MyPlugin instance;

    @Override
    public void onEnable() {
        instance = this;
        saveDefaultConfig();

        // Register listeners
        getServer().getPluginManager().registerEvents(new PlayerListener(this), this);

        // Register commands
        var cmd = getCommand("myplugin");
        if (cmd != null) {
            cmd.setExecutor(new MyCommand(this));
            cmd.setTabCompleter(new MyCommand(this));
        }

        getLogger().info("MyPlugin enabled!");
    }

    @Override
    public void onDisable() {
        getLogger().info("MyPlugin disabled.");
    }

    public static MyPlugin getInstance() {
        return instance;
    }
}
```

---

## Event Listeners

```java
package com.example.myplugin.listeners;

import com.example.myplugin.MyPlugin;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.NamedTextColor;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.PlayerDeathEvent;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.event.player.PlayerQuitEvent;

public class PlayerListener implements Listener {

    private final MyPlugin plugin;

    public PlayerListener(MyPlugin plugin) {
        this.plugin = plugin;
    }

    @EventHandler(priority = EventPriority.NORMAL, ignoreCancelled = true)
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

    @EventHandler(ignoreCancelled = true)
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
Use `MONITOR` for logging only (never modify outcome). Use `ignoreCancelled = true` unless
you have a specific reason to handle cancelled events.

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

        return switch (args[0].toLowerCase()) {
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
                yield false;
            }
        };
    }

    @Override
    public @Nullable List<String> onTabComplete(@NotNull CommandSender sender, @NotNull Command command,
                                                @NotNull String label, @NotNull String[] args) {
        if (args.length == 1) {
            return List.of("reload", "info").stream()
                .filter(s -> s.startsWith(args[0].toLowerCase()))
                .toList();
        }
        return List.of();
    }
}
```

---

## Schedulers

### Synchronous (runs on main thread)
```java
// Run once after 20 ticks (1 second)
plugin.getServer().getScheduler().runTaskLater(plugin, () -> {
    // safe to access Bukkit API here
}, 20L);

// Repeating task every 40 ticks (2 seconds), starts after 0 ticks
plugin.getServer().getScheduler().runTaskTimer(plugin, () -> {
    // runs on main thread
}, 0L, 40L);
```

### Asynchronous (for I/O / database work)
```java
// Never touch Bukkit API in async tasks!
plugin.getServer().getScheduler().runTaskAsynchronously(plugin, () -> {
    // safe: file I/O, HTTP requests, DB queries
    String data = fetchFromDatabase();
    // Switch back to main thread to use Bukkit API
    plugin.getServer().getScheduler().runTask(plugin, () -> {
        Bukkit.broadcastMessage(data);
    });
});
```

### BukkitRunnable (cancelable tasks)
```java
new BukkitRunnable() {
    int count = 0;

    @Override
    public void run() {
        count++;
        if (count >= 10) {
            cancel(); // stop after 10 executions
            return;
        }
        // task logic
    }
}.runTaskTimer(plugin, 0L, 20L);
```

---

## Persistent Data Container (PDC)

PDC stores arbitrary data on any `PersistentDataHolder` (players, entities, items, chunks).
Data is saved with the world and persists across restarts.

```java
import org.bukkit.NamespacedKey;
import org.bukkit.persistence.PersistentDataType;

// Define keys (reuse instances — create once in your plugin class)
NamespacedKey killKey = new NamespacedKey(plugin, "kill_count");
NamespacedKey flagKey = new NamespacedKey(plugin, "vip");

// Write
player.getPersistentDataContainer().set(killKey, PersistentDataType.INTEGER, 42);
player.getPersistentDataContainer().set(flagKey, PersistentDataType.BOOLEAN, true);

// Read
int kills = player.getPersistentDataContainer()
    .getOrDefault(killKey, PersistentDataType.INTEGER, 0);

boolean isVip = player.getPersistentDataContainer()
    .getOrDefault(flagKey, PersistentDataType.BOOLEAN, false);

// Check existence
boolean hasData = player.getPersistentDataContainer().has(killKey, PersistentDataType.INTEGER);

// Remove
player.getPersistentDataContainer().remove(killKey);
```

### PDC on ItemStack
```java
ItemStack item = new ItemStack(Material.DIAMOND_SWORD);
ItemMeta meta = item.getItemMeta();
meta.getPersistentDataContainer().set(new NamespacedKey(plugin, "custom_id"),
    PersistentDataType.STRING, "special_sword");
item.setItemMeta(meta);
```

---

## Adventure Text Components

Paper uses [Adventure](https://docs.advntr.dev/) natively for all text. No legacy chat colors.

```java
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.NamedTextColor;
import net.kyori.adventure.text.format.TextDecoration;
import net.kyori.adventure.text.event.ClickEvent;
import net.kyori.adventure.text.event.HoverEvent;

// Simple components
player.sendMessage(Component.text("Hello!", NamedTextColor.GREEN));
player.sendMessage(Component.text("Bold warning", NamedTextColor.RED, TextDecoration.BOLD));

// Compound component
Component message = Component.text()
    .append(Component.text("[Click Me]", NamedTextColor.AQUA)
        .clickEvent(ClickEvent.runCommand("/myplugin info"))
        .hoverEvent(HoverEvent.showText(Component.text("Run /myplugin info"))))
    .append(Component.text(" to see plugin info.", NamedTextColor.WHITE))
    .build();
player.sendMessage(message);

// MiniMessage (recommended for config-driven text)
import net.kyori.adventure.text.minimessage.MiniMessage;
Component parsed = MiniMessage.miniMessage().deserialize(
    "<gradient:red:yellow>Hello World</gradient>"
);

// Titles / action bars
player.showTitle(Title.title(
    Component.text("Welcome!", NamedTextColor.GOLD),
    Component.text("To " + player.getWorld().getName(), NamedTextColor.YELLOW),
    Title.Times.times(Duration.ofMillis(500), Duration.ofSeconds(3), Duration.ofMillis(500))
));
player.sendActionBar(Component.text("Health: " + player.getHealth(), NamedTextColor.RED));
```

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
```java
// In onEnable():
saveDefaultConfig(); // writes config.yml if absent

// Reading values
int maxPlayers = getConfig().getInt("settings.max-players", 20);
String message  = getConfig().getString("settings.welcome-message", "Welcome!");
boolean enabled = getConfig().getBoolean("features.pvp", true);

// Reloading
reloadConfig();

// Writing values
getConfig().set("settings.max-players", 30);
saveConfig();
```

### Custom config file
```java
File customFile = new File(getDataFolder(), "data.yml");
if (!customFile.exists()) {
    saveResource("data.yml", false); // copies from resources/
}
FileConfiguration customConfig = YamlConfiguration.loadConfiguration(customFile);
customConfig.set("some.key", "value");
customConfig.save(customFile);
```

---

## Vault Integration (Economy / Permissions)

```java
import net.milkbowl.vault.economy.Economy;
import org.bukkit.plugin.RegisteredServiceProvider;

public class MyPlugin extends JavaPlugin {
    private Economy economy;

    @Override
    public void onEnable() {
        if (!setupEconomy()) {
            getLogger().severe("Vault not found! Economy features disabled.");
        }
    }

    private boolean setupEconomy() {
        if (getServer().getPluginManager().getPlugin("Vault") == null) return false;
        RegisteredServiceProvider<Economy> rsp =
            getServer().getServicesManager().getRegistration(Economy.class);
        if (rsp == null) return false;
        economy = rsp.getProvider();
        return economy != null;
    }

    // Usage
    public void chargePlayer(Player player, double amount) {
        if (economy != null && economy.has(player, amount)) {
            economy.withdrawPlayer(player, amount);
        }
    }
}
```

---

## Paper-Specific APIs

### Async chunk loading
```java
// Paper: load chunk without blocking main thread
world.getChunkAtAsync(x, z).thenAccept(chunk -> {
    // runs on main thread after chunk loads
    chunk.getBlock(0, 64, 0).setType(Material.GOLD_BLOCK);
});
```

### Custom item meta
```java
// Set custom model data (for resource packs)
ItemStack item = new ItemStack(Material.STICK);
ItemMeta meta = item.getItemMeta();
meta.setCustomModelData(1001);
meta.displayName(Component.text("Magic Wand", NamedTextColor.LIGHT_PURPLE));
item.setItemMeta(meta);
```

### Player profile (async)
```java
// Paper: async profile lookup (no blocking main thread)
Bukkit.createProfile(UUID.fromString("...")).update().thenAccept(profile -> {
    String name = profile.getName();
});
```

### GriefPrevention / WorldGuard bypass
```java
// Check if location is protected (WorldGuard example)
// Always soft-depend on protection plugins
if (getServer().getPluginManager().getPlugin("WorldGuard") != null) {
    // use WorldGuard API
}
```

---

## Common Tasks Checklist

### Creating a new event listener
- [ ] Create class implementing `Listener`
- [ ] Annotate methods with `@EventHandler`
- [ ] Call `getServer().getPluginManager().registerEvents(listener, plugin)` in `onEnable()`
- [ ] Add `ignoreCancelled = true` unless you need cancelled events

### Adding a new command
- [ ] Define command in `plugin.yml` under `commands:`
- [ ] Create executor class implementing `CommandExecutor`
- [ ] (Optional) implement `TabCompleter` for autocomplete
- [ ] Register with `getCommand("name").setExecutor(new MyExecutor())`

### Saving plugin data
- [ ] For simple values: use `config.yml` via `getConfig()` / `saveConfig()`
- [ ] For per-entity data: use PDC with a `NamespacedKey`
- [ ] For large datasets: use async scheduler + file I/O or a database

### Scheduling a repeating task
- [ ] Determine if task needs main thread (use `runTaskTimer`) or is I/O (use `runTaskTimerAsynchronously`)
- [ ] Store the `BukkitTask` reference so you can cancel in `onDisable()`
- [ ] Cancel all tasks in `onDisable()` or use `getServer().getScheduler().cancelTasks(plugin)`

---

## Build & Run

```bash
# Build plugin JAR
./gradlew shadowJar

# Output: build/libs/my-plugin-1.0.0-SNAPSHOT.jar
# Copy to server/plugins/ and restart the server

# Run Paper dev server (with run-task plugin)
./gradlew runServer
```

## Validator Script

Use the bundled validator before publishing a Paper plugin:

```bash
# Run from the installed skill directory (for example `.agents/skills/minecraft-plugin-dev`):
./scripts/validate-plugin-layout.sh --root /path/to/plugin-project

# Strict mode treats warnings as failures:
./scripts/validate-plugin-layout.sh --root /path/to/plugin-project --strict
```

What it checks:
- `plugin.yml` required keys (`name`, `version`, `main`, `api-version`)
- Main class path exists and extends `JavaPlugin`
- `/reload` anti-pattern detection in source snippets

---

## References

- Paper API Javadoc: https://jd.papermc.io/paper/1.21/
- Paper Dev Docs: https://docs.papermc.io/paper/dev/getting-started/
- Adventure (text API): https://docs.advntr.dev/
- MiniMessage format: https://docs.advntr.dev/minimessage/format.html
- Vault API: https://github.com/MilkBowl/VaultAPI
- Bukkit API Javadoc: https://javadoc.io/doc/org.bukkit/bukkit/
- run-task Gradle plugin: https://github.com/jpenilla/run-task
