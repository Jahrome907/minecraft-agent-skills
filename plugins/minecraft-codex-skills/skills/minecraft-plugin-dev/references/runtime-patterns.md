# Runtime Patterns for Paper Plugins

Use these examples when implementing runtime behavior for Paper/Bukkit plugins.
All snippets target Java 21 and Paper API 1.21.x unless noted.

## Schedulers

Classic Paper plugins can use `BukkitScheduler`. Never run blocking I/O on the
main thread, and switch back to the main thread before touching Bukkit state.

```java
// Run once after 20 ticks (1 second)
plugin.getServer().getScheduler().runTaskLater(plugin, () -> {
    // Bukkit API access is safe here.
}, 20L);

// Repeating: starts after 0 ticks, runs every 40 ticks.
plugin.getServer().getScheduler().runTaskTimer(plugin, () -> {
    // Main-thread task logic.
}, 0L, 40L);

// Async I/O, then return to the main thread for Bukkit API work.
plugin.getServer().getScheduler().runTaskAsynchronously(plugin, () -> {
    String data = fetchFromDatabase();
    plugin.getServer().getScheduler().runTask(plugin, () -> {
        Bukkit.broadcastMessage(data);
    });
});
```

Use `BukkitRunnable` when task-local cancellation state is useful.

```java
new BukkitRunnable() {
    int count = 0;

    @Override
    public void run() {
        count++;
        if (count >= 10) {
            cancel();
            return;
        }
        // Repeating task logic.
    }
}.runTaskTimer(plugin, 0L, 20L);
```

For Folia support, choose a scheduler based on the ownership of the work.

```java
// Player-bound work: stays with the player's owning region.
player.getScheduler().run(plugin, task -> {
    player.sendActionBar(Component.text("Checkpoint reached"));
}, null);

// Location / chunk-bound work.
plugin.getServer().getRegionScheduler().run(plugin, location, task -> {
    location.getBlock().setType(Material.GOLD_BLOCK);
});

// Global coordination not tied to one region.
plugin.getServer().getGlobalRegionScheduler().run(plugin, task -> {
    plugin.getServer().broadcast(Component.text("Maintenance starts in five minutes."));
});

// Blocking I/O stays async.
plugin.getServer().getAsyncScheduler().runNow(plugin, task -> {
    writeAuditLog();
});
```

Folia [disables `save-all`](https://docs.papermc.io/folia/faq/); use a clean stop
or a verified platform snapshot for backups.

## Persistent Data Container

Create `NamespacedKey` instances once and keep each key's type stable after
release. PDC is appropriate for small metadata on players, entities, items,
chunks, and worlds.

```java
import org.bukkit.NamespacedKey;
import org.bukkit.persistence.PersistentDataType;

NamespacedKey killKey = new NamespacedKey(plugin, "kill_count");
NamespacedKey flagKey = new NamespacedKey(plugin, "vip");

player.getPersistentDataContainer().set(killKey, PersistentDataType.INTEGER, 42);
player.getPersistentDataContainer().set(flagKey, PersistentDataType.BOOLEAN, true);

int kills = player.getPersistentDataContainer()
    .getOrDefault(killKey, PersistentDataType.INTEGER, 0);

boolean isVip = player.getPersistentDataContainer()
    .getOrDefault(flagKey, PersistentDataType.BOOLEAN, false);

player.getPersistentDataContainer().remove(killKey);
```

```java
ItemStack item = new ItemStack(Material.DIAMOND_SWORD);
item.editMeta(meta -> meta.getPersistentDataContainer().set(
    new NamespacedKey(plugin, "custom_id"),
    PersistentDataType.STRING,
    "special_sword"
));
```

```java
NamespacedKey arenaKey = new NamespacedKey(plugin, "arena_id");

chunk.getPersistentDataContainer().set(arenaKey, PersistentDataType.STRING, "spawn");

String arenaId = chunk.getPersistentDataContainer()
    .getOrDefault(arenaKey, PersistentDataType.STRING, "unknown");
```

## Adventure And MiniMessage

Paper uses Adventure natively. Use `Component` builders for code-owned messages
and MiniMessage for config-owned rich text.

```java
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.event.ClickEvent;
import net.kyori.adventure.text.event.HoverEvent;
import net.kyori.adventure.text.format.NamedTextColor;
import net.kyori.adventure.text.format.TextDecoration;

player.sendMessage(Component.text("Hello!", NamedTextColor.GREEN));
player.sendMessage(Component.text("Bold warning", NamedTextColor.RED, TextDecoration.BOLD));

Component message = Component.text()
    .append(Component.text("[Info]", NamedTextColor.AQUA)
        .clickEvent(ClickEvent.runCommand("/myplugin info"))
        .hoverEvent(HoverEvent.showText(Component.text("Run /myplugin info"))))
    .append(Component.text(" for plugin details.", NamedTextColor.WHITE))
    .build();
player.sendMessage(message);
```

```java
import net.kyori.adventure.text.minimessage.MiniMessage;

Component parsed = MiniMessage.miniMessage().deserialize(
    "<gradient:red:yellow>Hello World</gradient>"
);
```

```java
player.showTitle(Title.title(
    Component.text("Welcome!", NamedTextColor.GOLD),
    Component.text("To " + player.getWorld().getName(), NamedTextColor.YELLOW),
    Title.Times.times(Duration.ofMillis(500), Duration.ofSeconds(3), Duration.ofMillis(500))
));

player.sendActionBar(Component.text("Health: " + player.getHealth(), NamedTextColor.RED));
```

## YAML Config

Call `saveDefaultConfig()` in `onEnable()` and always provide explicit defaults
when reading values.

```java
saveDefaultConfig();

int maxPlayers = getConfig().getInt("settings.max-players", 20);
String message = getConfig().getString("settings.welcome-message", "Welcome!");
boolean enabled = getConfig().getBoolean("features.pvp", true);

reloadConfig();

getConfig().set("settings.max-players", 30);
saveConfig();
```

Use a custom file when mutable data should be separated from user-editable config.

```java
File customFile = new File(getDataFolder(), "data.yml");
if (!customFile.exists()) {
    saveResource("data.yml", false);
}

FileConfiguration customConfig = YamlConfiguration.loadConfiguration(customFile);
customConfig.set("some.key", "value");
customConfig.save(customFile);
```

## Vault

Vault is an optional bridge. Check for both the Vault plugin and the requested
service provider before enabling economy behavior.

```java
import net.milkbowl.vault.economy.Economy;
import org.bukkit.plugin.RegisteredServiceProvider;

public class MyPlugin extends JavaPlugin {
    private Economy economy;

    @Override
    public void onEnable() {
        if (!setupEconomy()) {
            getLogger().warning("Vault economy provider unavailable; economy features disabled.");
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

    public boolean chargePlayer(Player player, double amount) {
        if (economy == null || !economy.has(player, amount)) return false;
        return economy.withdrawPlayer(player, amount).transactionSuccess();
    }
}
```

## Paper-Specific APIs

Use async Paper APIs to avoid avoidable main-thread blocking.

```java
world.getChunkAtAsync(x, z).thenAccept(chunk -> {
    chunk.getBlock(0, 64, 0).setType(Material.GOLD_BLOCK);
});
```

```java
ItemStack item = new ItemStack(Material.STICK);
ItemMeta meta = item.getItemMeta();
meta.setCustomModelData(1001);
meta.displayName(Component.text("Magic Wand", NamedTextColor.LIGHT_PURPLE));
item.setItemMeta(meta);
```

```java
Bukkit.createProfile(UUID.fromString("00000000-0000-0000-0000-000000000000"))
    .update()
    .thenAccept(profile -> {
        String name = profile.getName();
    });
```

Optional protection plugins should be soft dependencies and presence-checked
before calling their APIs.

```java
if (getServer().getPluginManager().getPlugin("WorldGuard") != null) {
    // Use WorldGuard API from a project-specific adapter class.
}
```
