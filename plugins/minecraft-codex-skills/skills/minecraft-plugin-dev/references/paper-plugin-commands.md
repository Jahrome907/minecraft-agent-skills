# Paper-Only Plugins and Commands

Read this only when the target JAR uses `paper-plugin.yml`. Paper plugins are
experimental and are not a drop-in replacement for Bukkit-compatible
`plugin.yml` plugins.

Paper plugins do not use a `commands` field. Register commands through Paper's
Brigadier lifecycle API; do not call `getCommand(...)` unless the matching
command is declared in `plugin.yml`.

## Paired descriptor and main class

This Paper-only example has one descriptor and one matching main class. It does
not include a Bukkit `plugin.yml`.

### `src/main/resources/paper-plugin.yml`

```yaml
name: PaperOnlyPlugin
version: "${version}"
main: com.example.myplugin.PaperOnlyPlugin
description: An example Paper-only plugin
api-version: '26.2'
```

### `src/main/java/com/example/myplugin/PaperOnlyPlugin.java`

```java
package com.example.myplugin;

import com.mojang.brigadier.Command;
import io.papermc.paper.command.brigadier.Commands;
import io.papermc.paper.plugin.lifecycle.event.types.LifecycleEvents;
import org.bukkit.plugin.java.JavaPlugin;

public final class PaperOnlyPlugin extends JavaPlugin {

    @Override
    public void onEnable() {
        this.getLifecycleManager().registerEventHandler(LifecycleEvents.COMMANDS, event -> {
            event.registrar().register(
                Commands.literal("myplugin")
                    .executes(context -> {
                        context.getSource().getSender().sendRichMessage("<green>MyPlugin is running.");
                        return Command.SINGLE_SUCCESS;
                    })
                    .build(),
                "Main Paper-only plugin command"
            );
        });
    }
}
```

`LifecycleEvents.COMMANDS` re-registers the command when Paper reloads command
resources. Keep registration inside its handler. Use `Commands.literal(...)` and
`Commands.argument(...)` to construct larger command trees, and add `requires`
to the tree when a command needs an access check.

## When both descriptors are needed

Use both descriptors only when the same JAR intentionally supports the two
formats. Keep `name`, `version`, `main`, and `api-version` aligned. The
`plugin.yml` path may use `commands` and `getCommand(...)`; the Paper-plugin
path must instead register its commands through the lifecycle API.

## Sources

- [Paper plugins: descriptor differences and commands](https://docs.papermc.io/paper/dev/getting-started/paper-plugins/)
- [Paper Brigadier registration](https://docs.papermc.io/paper/dev/command-api/basics/registration/)
- [Paper Brigadier arguments and literals](https://docs.papermc.io/paper/dev/command-api/basics/arguments-and-literals/)
