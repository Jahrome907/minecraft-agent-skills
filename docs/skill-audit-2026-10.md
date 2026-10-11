# October 2026 skill review

Reviewed the 13 published skills on October 11, 2026. This update keeps existing
project pins and the Minecraft 1.21.x / Java 21 and Forge 1.20.1 / Java 17 examples.

- **Minecraft:** Mojang's [release manifest](https://piston-meta.mojang.com/mc/game/version_manifest_v2.json)
  identifies 26.3 as stable; its version metadata requires Java 25. Updated pack
  formats, loot/predicate examples, worldgen data, and command version boundaries
  against the [26.3 release notes](https://www.minecraft.net/en-us/article/minecraft-java-edition-26-3)
  and [NeoForge migration primer](https://docs.neoforged.net/primer/docs/26.3/).
- **Modding and multiloader:** corrected current identifier names and singular
  tag paths and datagen routing; kept legacy code explicitly scoped and generator versions tied to
  the target project. Sources: [Fabric](https://docs.fabricmc.net/develop/),
  [NeoForge](https://docs.neoforged.net/docs/gettingstarted/),
  [Architectury generator](https://generate.architectury.dev/).
- **Plugins and testing:** refreshed [Paper setup](https://docs.papermc.io/paper/dev/project-setup/)
  to 26.3. Retained the paired MockBukkit 26.2 example because a 26.3 artifact was
  not found in Maven Central. Checked [Fabric tests](https://docs.fabricmc.net/develop/automatic-testing)
  and [NeoForge tests](https://docs.neoforged.net/docs/misc/gametest/).
- **Operations and releases:** refreshed example versions and
  [Minotaur 2.10.0](https://plugins.gradle.org/plugin/com.modrinth.minotaur); retained Java 25 and
  checked [Velocity](https://docs.papermc.io/velocity/getting-started/),
  [WorldEdit build selection](https://enginehub.org/worldedit), and
  [EssentialsX's narrower support range](https://github.com/EssentialsX/Essentials/releases/tag/2.22.0).
- **Models and images:** checked current [OpenAI models](https://developers.openai.com/api/docs/models),
  [Claude models](https://platform.claude.com/docs/en/models/overview),
  [Codex skills](https://learn.chatgpt.com/docs/build-skills), and
  [Claude Code skills](https://code.claude.com/docs/en/skills). Skills remain
  host-loaded instructions without model IDs or reasoning overrides. Image work
  still requires an image-generation tool supplied by the host.

Validation covers mirrored files, packaging, documentation syntax, links,
version checks, and helper fixtures. Current Paper metadata and worldgen feature
references failed before the fixes and passed afterward. The worldgen helper's
`--feature-registry feature` option selects 26.3; its default retains older packs.

The 26.3 berry feature, placement, recipe, and loot shapes were checked against
Mojang's client JAR with SHA-1 `e877b6a07acd633fb3bb475002175cec036e7b87`.
No Minecraft, Gradle, or server process was run. These checks do not establish
in-game behavior or model performance.
