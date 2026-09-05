# September 2026 skill audit

Audit date: 2026-09-05. Release: **v2.5.3**.

The review covers all 13 canonical skills, their local references and helpers,
the three generated skill mirrors, plugin manifests, repository checks, and
release instructions. It addresses GPT-6 Astra and Claude Fable 5.1 through
their documented behavior and host skill contracts. The bundle does not select
models, install tools, or change global configuration.

## Model and host design

Entrypoints keep task routing and version boundaries visible. Larger examples
live in local references and are loaded when relevant. Existing project pins,
explicit scope, and authorization govern the work; example checklists do not
require migrations, extra artifacts, or repeated approval for an authorized edit.
Image requests proceed directly when a suitable tool is available. A model name
alone does not establish image-generation capability.

These choices follow OpenAI's guidance on Astra's literal instruction following,
scope, and tendency to over-test small changes, together with Anthropic's Fable
guidance on completing authorized work, targeted edits, and retrieving changing
facts. Sources: [GPT-6 Astra behavior](https://developers.openai.com/api/docs/guides/latest-model#gpt-6-astra-behavior),
[Claude Fable 5.1 prompting](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1).

The raw skill folders and plugin are alternative installation routes. Installing
both can expose duplicate skills. All entrypoints remain below 500 lines, with
local supporting files and no required cross-skill dependencies. Sources:
[Codex skills](https://developers.openai.com/codex/skills),
[Claude Code skills](https://code.claude.com/docs/en/skills),
[Agent Skills specification](https://agentskills.io/specification).

## Coverage and corrections

| Skill | Reviewed behavior and resulting corrections | Primary evidence |
| --- | --- | --- |
| `minecraft-commands-scripting` | Checked attribute modifiers, text components, enchantments, sound sources, version-specific commands, and RCON credential handling. Preserved version-specific examples and the command-only route. | [Mojang 1.21.5](https://www.minecraft.net/en-us/article/minecraft-java-edition-1-21-5), [Mojang 26.1](https://www.minecraft.net/en-us/article/minecraft-java-edition-26-1) |
| `minecraft-datapack` | Corrected automatic load/tick tags to the `minecraft` namespace. Custom tags remain legal but receive an advisory when named load/tick. Added modern metadata bounds, short-array endpoint handling, range ordering, and legacy compatibility checks. | [Mojang load tag](https://www.minecraft.net/en-us/article/minecraft-snapshot-18w01a), [Mojang pack metadata](https://www.minecraft.net/en-us/article/minecraft-java-edition-1-21-9) |
| `minecraft-resource-pack` | Corrected the 1.21.4 item-definition boundary, string custom-model selectors, modern texture objects, sound event references, and block inspection guidance. Extended metadata validation and corrected misleading valid fixtures. | [Mojang 1.21.4](https://feedback.minecraft.net/hc/en-us/articles/32385811139085-Minecraft-Java-Edition-1-21-4-The-Garden-Awakens), [Mojang 26.1](https://www.minecraft.net/en-us/article/minecraft-java-edition-26-1), [NeoForge sounds](https://docs.neoforged.net/docs/1.21.8/resources/client/sounds/) |
| `minecraft-world-generation` | Corrected `/place feature` to use a configured-feature ID. Narrowed legacy JSON examples to 1.21.5 and corrected the biome carver list. Preserved current random-patch migration guidance and distinction between local references and external registries. | [NeoForge 26.1 primer](https://docs.neoforged.net/primer/docs/26.1/), [NeoForge biome modifiers](https://docs.neoforged.net/docs/worldgen/biomemodifier/), [Mojang 1.21.5 client data](https://piston-data.mojang.com/v1/objects/b88808bbb3da8d9f453694b5d8f74a3396f1a533/client.jar) |
| `minecraft-modding` | Fixed specialized registry types, registry keys before object construction, current tool/armor/entity patterns, and recipe paths/schema. The build helper accurately describes incremental builds and candidate artifacts. | [NeoForge blocks](https://docs.neoforged.net/docs/blocks/), [tools](https://docs.neoforged.net/docs/items/tools/), [armor](https://docs.neoforged.net/docs/items/armor/), [entities](https://docs.neoforged.net/docs/entities/), [Fabric blocks](https://docs.fabricmc.net/develop/blocks/first-block) |
| `minecraft-multiloader` | Corrected shared keyed item registration, removed claims of an unavailable released template, and derives artifact names from the real build. The helper is explicitly a static properties/family check. | [Architectury 1.21.11 source](https://github.com/architectury/architectury-api/tree/1.21.11), [26.2 source](https://github.com/architectury/architectury-api/tree/26.2), [template releases](https://github.com/architectury/architectury-templates/releases), [Loom releases](https://github.com/architectury/architectury-loom/releases) |
| `minecraft-plugin-dev` | Separated Bukkit `plugin.yml` command lookup from a paired Paper-only descriptor/main class using Brigadier lifecycle registration. Reviewed Java, Paper API, PDC, and Folia scheduler boundaries. | [Paper plugins](https://docs.papermc.io/paper/dev/getting-started/paper-plugins/), [command registration](https://docs.papermc.io/paper/dev/command-api/basics/registration/), [Folia support](https://docs.papermc.io/paper/dev/folia-support/) |
| `minecraft-testing` | Fixed paired Fabric metadata, current death-event construction, Jupiter alignment, current NeoForge test-function registration, legacy template naming, and class-specific event registration checks. GameTest-only projects do not require an unrelated JUnit source tree. | [Fabric testing](https://docs.fabricmc.net/develop/automatic-testing), [current NeoForge tests](https://docs.neoforged.net/docs/misc/gametest/), [legacy NeoForge tests](https://docs.neoforged.net/docs/1.21.3/misc/gametest/), [Paper death event](https://jd.papermc.io/paper/26.2/org/bukkit/event/entity/EntityDeathEvent.html) |
| `minecraft-ci-release` | Verified immutable action pins. Release selection requires both loader artifacts with distinct names. Publisher tasks depend on version verification; tag preflight checks worktree, branch, exact push URL, and remote lookup errors. Removed an incorrect cache path and false strict-mode warnings for secretless workflows. | [Gradle setup cache behavior](https://github.com/gradle/actions/blob/main/docs/setup-gradle.md), [GitHub release action](https://github.com/softprops/action-gh-release), [Minotaur](https://github.com/modrinth/minotaur), [CurseForgeGradle](https://github.com/Darkhax/CurseForgeGradle) |
| `minecraft-server-admin` | Clarified Java/runtime lanes, corrected spark monitoring, scoped backup examples, added modded-server recovery inventory, and corrected live-backup consistency requirements and Folia limitations. | [Paper setup](https://docs.papermc.io/paper/getting-started/), [Velocity setup](https://docs.papermc.io/velocity/getting-started/), [spark commands](https://spark.lucko.me/docs/Command-Usage), [backup lifecycle](https://github.com/itzg/docker-mc-backup), [Folia FAQ](https://docs.papermc.io/folia/faq/) |
| `minecraft-worldedit-ops` | Paste checks now preview the destination with `//paste -n` and matching placement flags before inspecting its size. Arena reset examples retain air when needed to remove old blocks. | [WorldEdit clipboard](https://worldedit.enginehub.org/en/latest/usage/clipboard/) |
| `minecraft-essentials-ops` | Added the documented unsupported-platform boundary, corrected jail permissions, and separated core mute handling from optional chat formatting. Exact server/build compatibility remains a prerequisite. | [EssentialsX 2.22.0](https://github.com/EssentialsX/Essentials/discussions/6552), [EssentialsX modules](https://essentialsx.net/wiki/modules) |
| `minecraft-imagegen` | Removed repeated prompt/workflow material and mandatory extra concept rounds. Uses actual host capability, the requested output, and verified save paths. Supporting recipes are conditional. | [OpenAI image generation](https://developers.openai.com/api/docs/guides/image-generation), [Claude vision](https://platform.claude.com/docs/en/build-with-claude/vision) |

New work retains the repository's stable 26.x / Java 25 baseline. Explicit
1.21.x / Java 21 and Forge 1.20.1 / Java 17 projects keep their own pins and
build conventions. Published older dependency pins are not automatically bugs;
an intentional upgrade still requires dependency resolution and project tests.
Sources: [NeoForge 26.1 migration](https://docs.neoforged.net/primer/docs/26.1/),
[Forge 1.20.1 setup](https://docs.minecraftforge.net/en/1.20.1/gettingstarted/).

## Verification and limits

The repository gate is `npm run sync:skills` followed by `npm run check`. It
checks mirror equality, plugin packaging, skill metadata and local links, version
drift, JSON/YAML examples, helper regression fixtures, repository policy, action
pins, and Markdown. These checks do not compile Java or execute Minecraft codecs.

Additional review exercises used the documented release snippets directly:
three artifact cases covered both loaders, a missing loader, and ambiguous
outputs. Six preflight cases covered an absent/existing tag, failed remote
lookup, wrong/multiple push URLs, and an untracked file. Git responses were
mocked; these exercises did not create tags or contact a release destination.

A GPT-6 Astra trial received four ordinary requests and read the relevant skills
without expected answers: two 1.21.11 attribute commands, a minimal dirt-to-diamond
recipe datapack, an image request without an image tool, and release-version
selection. It returned the requested commands, two datapack files with format
94.1, an explicit capability limitation, and v2.5.3. The generated datapack passed
the bundled strict validator. This is a small behavioral spot check, not a
statistical benchmark. An authenticated Fable 5.1 run was unavailable; its
coverage is primary-source instruction and host-contract review.

The 1.21.5 biome correction was independently checked against the installed
official client JAR, whose SHA-1 matched Mojang's download identity
`b88808bbb3da8d9f453694b5d8f74a3396f1a533`. Current NeoForge examples are grounded
in its published 26.1 API documentation; later 26.x changes still require an
exact-project check. No Minecraft, Paper, or Gradle runtime was launched in this
skills repository. Rendering, gameplay, full dependency resolution, and live
server operations remain validation steps in the target Minecraft project.

## Release version

v2.5.3 is the approved patch release after v2.5.2. These corrections retain the
existing skill names and installation contracts. Package metadata, lockfile,
both plugin manifests, Git tag, and GitHub release must agree.
See [Semantic Versioning](https://semver.org/).
