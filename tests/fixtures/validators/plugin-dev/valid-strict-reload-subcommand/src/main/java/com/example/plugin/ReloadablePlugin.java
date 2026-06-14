package com.example.plugin;

import org.bukkit.plugin.java.JavaPlugin;

public final class ReloadablePlugin extends JavaPlugin {
    public boolean onSubcommand(String subcommand) {
        return switch (subcommand) {
            case "reload" -> {
                reloadConfig();
                yield true;
            }
            default -> false;
        };
    }
}
