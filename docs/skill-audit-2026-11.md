# November 2026 skill review

The November 24 review starts from v2.5.4 and keeps Minecraft Java 26.3 and
Java 25 as the stable baseline. Existing project pins, the 1.21.x examples,
and the Forge 1.20.1 examples still apply to those targets.
[Mojang release manifest](https://piston-meta.mojang.com/mc/game/version_manifest_v2.json),
[Java 26.3 release notes](https://www.minecraft.net/en-us/article/minecraft-java-edition-26-3).

## Agent hosts

Codex, Google Antigravity, and Gemini CLI discover workspace skills in
`.agents/skills`. Claude Code loads project skills from `.claude/skills`.
Codex and Claude Code also have plugin manifests. Use one installation route
per host. Antigravity uses the existing skill folders directly.
[Codex skills](https://developers.openai.com/codex/skills),
[Claude Code skills](https://code.claude.com/docs/en/skills),
[Antigravity skills](https://antigravity.google/docs/skills),
[Gemini CLI skills](https://geminicli.com/docs/cli/skills/).

Model selection belongs to the host. The usage guide covers GPT-6.2 Sol and
Astra, Claude Opus 5.5 and Fable 5.2, and Gemini 4 Neon in Antigravity.
Image generation depends on the tools available in the active session.
[OpenAI model selection](https://developers.openai.com/api/docs/guides/model-selection),
[Claude model overview](https://platform.claude.com/docs/en/models/overview),
[Gemini 4 Neon in Antigravity](https://antigravity.google/blog/gemini-4-neon-in-google-antigravity/).

## Minecraft and release corrections

| Area | Change | Evidence |
| --- | --- | --- |
| Mods and tests | Added the Architectury API 22 setup and accepted the upstream `architectury_api_version` property when Loom is pinned in the build. Paired MockBukkit 4.124.0 with the Paper API build in its manifest, added the API to the test classpath, and clarified direct welcome messages versus the join-event component. | [Architectury setup](https://docs.architectury.dev/api/getting-started/setup/), [MockBukkit artifact](https://repo.maven.apache.org/maven2/org/mockbukkit/mockbukkit/mockbukkit-v26.3/4.124.0/), [Paper build 200](https://fill.papermc.io/v3/projects/paper/versions/26.3/builds/200) |
| Packs and commands | Corrected the visible root advancement, added `execute if slots`, and documented the 26.3 model shading and tint changes. | [Java 26.3 technical changes](https://www.minecraft.net/en-us/article/minecraft-java-edition-26-3) |
| Server operations | Documented the 26.3 allowlist default and changed log automation assumptions. Distinguished EssentialsX 2.22.0 release support from development branch support. | [Java 26.3 server changes](https://www.minecraft.net/en-us/article/minecraft-java-edition-26-3), [EssentialsX 2.22.0](https://github.com/EssentialsX/Essentials/releases/tag/2.22.0), [EssentialsX development branch](https://github.com/EssentialsX/Essentials) |
| CI and publishing | Refreshed action pins in the examples and repository workflow, clarified unique mod versions for game-independent tags, and fixed pin checks for flow-style references, reusable workflows, and Docker images. | [Gradle Actions 6.4.1](https://github.com/gradle/actions/releases/tag/v6.4.1), [setup-java 6.3.0](https://github.com/actions/setup-java/releases/tag/v6.3.0), [upload-artifact 7.0.2](https://github.com/actions/upload-artifact/releases/tag/v7.0.2), [action-gh-release 3.0.4](https://github.com/softprops/action-gh-release/releases/tag/v3.0.4), [setup-node 7.1.0](https://github.com/actions/setup-node/releases/tag/v7.1.0), [GitHub container digests](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#pulling-container-images) |

The modding skill now links the exact 26.3 migration notes for loader APIs.
[NeoForge primer](https://docs.neoforged.net/primer/docs/26.3/),
[Fabric release notes](https://fabricmc.net/2026/09/15/263.html).

## Verification scope

The repository check covers skill structure, generated mirrors, packaging,
examples, validator fixtures, workflow references, and Markdown. The
Architectury preflight and MockBukkit dependency example also received an
independent task walkthrough. Model coverage is based on provider documentation.
Minecraft, Gradle, and Paper runtime checks belong to the target project.

The [October review](skill-audit-2026-10.md) records the earlier version update
and separate worldgen and loader checks.
