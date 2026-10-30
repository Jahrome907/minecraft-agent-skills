# October 2026 skill review

Rechecked the 13 published skills on October 29, following the October 11 review.
This update keeps existing project pins and the Minecraft 1.21.x / Java 21 and
Forge 1.20.1 / Java 17 examples.

- **Minecraft:** Mojang's [release manifest](https://piston-meta.mojang.com/mc/game/version_manifest_v2.json)
  identifies 26.3 as stable; its version metadata requires Java 25. Updated pack
  formats, loot/predicate examples, worldgen data, and command version boundaries
  against the [26.3 release notes](https://www.minecraft.net/en-us/article/minecraft-java-edition-26-3)
  and [NeoForge migration primer](https://docs.neoforged.net/primer/docs/26.3/).
- **Modding and multiloader:** corrected registry keys, food effects, recipe
  ingredients, payload registration, and 1.21.11 permissions. Replaced obsolete
  datagen and partial GUI classes with versioned guidance. Fixed Architectury's
  [platform package suffixes](https://docs.architectury.dev/plugin/custom_platform_exp/).
  Sources: [Fabric](https://docs.fabricmc.net/1.21.11/develop/networking),
  [NeoForge](https://docs.neoforged.net/docs/1.21.11/resources/).
- **Plugins and testing:** refreshed [Paper setup](https://docs.papermc.io/paper/dev/project-setup/)
  to 26.3. Kept the paired MockBukkit 26.2 example explicitly scoped; corrected
  its join simulation and test isolation. Added the missing admin check to the
  plugin reload example. Checked [Fabric tests](https://docs.fabricmc.net/develop/automatic-testing)
  and [NeoForge tests](https://docs.neoforged.net/docs/misc/gametest/).
- **Operations and releases:** fixed brush mask/unbinding commands, required
  resource-pack settings, scoreboard examples, and the race-time guard. Repaired
  moved source links and kept action SHAs pinned to verified upstream commits.
  Checked [WorldEdit commands](https://worldedit.enginehub.org/en/latest/commands/),
  [Minotaur 2.10.0](https://plugins.gradle.org/plugin/com.modrinth.minotaur); retained Java 25 and
  checked [Velocity](https://docs.papermc.io/velocity/getting-started/),
  [WorldEdit build selection](https://enginehub.org/worldedit), and
  [EssentialsX's narrower support range](https://github.com/EssentialsX/Essentials/releases/tag/2.22.0).
- **Images:** kept the existing host-tool requirement and focused asset examples.
  Skills do not set model IDs or reasoning settings.

Validation covers mirrored files, packaging, documentation syntax, links,
version checks, and helper fixtures. The October 11 review fixed failing Paper
metadata and worldgen feature fixtures. The worldgen helper's
`--feature-registry feature` option selects 26.3; its default retains older packs.

The October 11 review checked the 26.3 berry feature, placement, recipe, and loot
shapes against Mojang's client JAR with SHA-1 `e877b6a07acd633fb3bb475002175cec036e7b87`.
No Minecraft, Gradle, or server process was run. These checks do not establish
in-game behavior or model performance.
