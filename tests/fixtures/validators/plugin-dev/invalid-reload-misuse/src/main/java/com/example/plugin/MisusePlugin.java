package com.example.plugin;

import org.bukkit.Bukkit;
import org.bukkit.plugin.java.JavaPlugin;

public final class MisusePlugin extends JavaPlugin {
    public void hotReload() {
        Bukkit.reload();
    }
}
