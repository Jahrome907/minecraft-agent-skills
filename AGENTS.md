# AGENTS.md — minecraft-codex-skills Repository

This repository is a collection of **10 Minecraft development skills** plus a
dual-target plugin bundle for Codex and Claude Code.
It is NOT itself a Minecraft project — it contains skill files and plugin packaging
that get copied into Minecraft mod, plugin, or server-admin projects.

## What this repo contains

```text
.agents/skills/                ← canonical source of truth
├── minecraft-modding/
│   ├── SKILL.md
│   ├── references/
│   │   ├── neoforge-api.md
│   │   ├── fabric-api.md
│   │   └── common-patterns.md
│   └── scripts/
│       └── check-build.sh
├── minecraft-plugin-dev/
│   └── SKILL.md
├── minecraft-datapack/
│   └── SKILL.md
├── minecraft-commands-scripting/
│   └── SKILL.md
├── minecraft-multiloader/
│   └── SKILL.md
├── minecraft-testing/
│   └── SKILL.md
├── minecraft-ci-release/
│   └── SKILL.md
├── minecraft-world-generation/
│   └── SKILL.md
├── minecraft-resource-pack/
│   └── SKILL.md
└── minecraft-server-admin/
    └── SKILL.md
```

Compatibility mirror (kept in sync by script/CI):

```text
.codex/skills/
├── minecraft-modding/            ← NeoForge + Fabric mod development
│   ├── SKILL.md
│   ├── references/
│   │   ├── neoforge-api.md
│   │   ├── fabric-api.md
│   │   └── common-patterns.md
│   └── scripts/
│       └── check-build.sh
├── minecraft-plugin-dev/         ← Paper/Bukkit server plugin development
│   └── SKILL.md
├── minecraft-datapack/           ← Vanilla datapack authoring (no Java)
│   └── SKILL.md
├── minecraft-commands-scripting/ ← Vanilla commands, scoreboards, NBT, RCON
│   └── SKILL.md
├── minecraft-multiloader/        ← Architectury NeoForge + Fabric multiloader
│   └── SKILL.md
├── minecraft-testing/            ← JUnit 5, MockBukkit, GameTests, CI
│   └── SKILL.md
├── minecraft-ci-release/         ← GitHub Actions, Modrinth/CurseForge publishing
│   └── SKILL.md
├── minecraft-world-generation/   ← Custom biomes, dimensions, structures
│   └── SKILL.md
├── minecraft-resource-pack/      ← Textures, models, sounds, shaders
│   └── SKILL.md
└── minecraft-server-admin/       ← Server setup, JVM tuning, Docker, Velocity
    └── SKILL.md
```

Claude Code mirror (kept in sync by script/CI):

```text
.claude/skills/
├── minecraft-modding/            ← NeoForge + Fabric mod development
│   ├── SKILL.md
│   ├── references/
│   │   ├── neoforge-api.md
│   │   ├── fabric-api.md
│   │   └── common-patterns.md
│   └── scripts/
│       └── check-build.sh
├── minecraft-plugin-dev/         ← Paper/Bukkit server plugin development
│   └── SKILL.md
├── minecraft-datapack/           ← Vanilla datapack authoring (no Java)
│   └── SKILL.md
├── minecraft-commands-scripting/ ← Vanilla commands, scoreboards, NBT, RCON
│   └── SKILL.md
├── minecraft-multiloader/        ← Architectury NeoForge + Fabric multiloader
│   └── SKILL.md
├── minecraft-testing/            ← JUnit 5, MockBukkit, GameTests, CI
│   └── SKILL.md
├── minecraft-ci-release/         ← GitHub Actions, Modrinth/CurseForge publishing
│   └── SKILL.md
├── minecraft-world-generation/   ← Custom biomes, dimensions, structures
│   └── SKILL.md
├── minecraft-resource-pack/      ← Textures, models, sounds, shaders
│   └── SKILL.md
└── minecraft-server-admin/       ← Server setup, JVM tuning, Docker, Velocity
    └── SKILL.md
```

Dual-target plugin bundle (kept in sync by script/CI):

```text
plugins/minecraft-codex-skills/
├── .codex-plugin/
│   └── plugin.json
├── .claude-plugin/
│   └── plugin.json
└── skills/
    ├── minecraft-modding/
    ├── minecraft-plugin-dev/
    ├── minecraft-datapack/
    ├── minecraft-commands-scripting/
    ├── minecraft-multiloader/
    ├── minecraft-testing/
    ├── minecraft-ci-release/
    ├── minecraft-world-generation/
    ├── minecraft-resource-pack/
    └── minecraft-server-admin/
```

## Skill Selection Guide

Codex selects skills automatically from the `description` field in each `SKILL.md`.
The table below maps task types to which skill(s) to load:

|Task type|Skill to use|
|---|---|
|NeoForge / Fabric mod (blocks, items, entities, events, datagen)|`minecraft-modding`|
|Paper / Bukkit / Spigot server plugin|`minecraft-plugin-dev`|
|Vanilla datapack (functions, advancements, recipes, loot tables)|`minecraft-datapack`|
|`/execute`, scoreboards, NBT, `tellraw`, RCON scripting|`minecraft-commands-scripting`|
|Single code base targeting both NeoForge and Fabric|`minecraft-multiloader`|
|Unit tests, MockBukkit, NeoForge GameTests, Fabric GameTests|`minecraft-testing`|
|GitHub Actions CI, Modrinth/CurseForge auto-publish, semantic versioning|`minecraft-ci-release`|
|Custom biomes, dimensions, structures (datapack or mod)|`minecraft-world-generation`|
|Texture packs, block/item models, animated textures, shaders|`minecraft-resource-pack`|
|Server launch flags, `server.properties`, Docker, Velocity proxy|`minecraft-server-admin`|

## When working in this repository

- **Do not** run Minecraft, Gradle, or Paper server commands here; there is no game project to build.
- Edit `.agents/skills/` only; sync mirrors and the plugin bundle after canonical changes.
- When editing skill files, keep examples accurate for **Minecraft 1.21.x**.
- Keep Java examples correct for **Java 21** and verify changed examples in their target project context.
- Keep JSON snippets valid and pretty-printed with 2-space indentation.
- Mark platform-specific patterns (NeoForge / Fabric / Paper) clearly.
- Prefer complete, runnable code snippets over pseudo-code.
- Skills are independent — do not create cross-skill dependencies.

## Updating for new Minecraft versions

When Minecraft releases a new version, update the following files:

1. **`minecraft-modding/SKILL.md`** — version table, NeoForge/Fabric versions
2. **`minecraft-modding/references/neoforge-api.md`** — class names, gradle.properties versions
3. **`minecraft-modding/references/fabric-api.md`** — yarn mappings, Fabric API version
4. **`minecraft-modding/references/common-patterns.md`** — changed JSON formats
5. **`minecraft-plugin-dev/SKILL.md`** — `paper-api` version, `api-version` field
6. **`minecraft-datapack/SKILL.md`** — pack format number table
7. **`minecraft-resource-pack/SKILL.md`** — pack format number table
8. **`minecraft-commands-scripting/SKILL.md`** — any syntax changes
9. **`minecraft-world-generation/SKILL.md`** — worldgen JSON schema changes
10. **`minecraft-multiloader/SKILL.md`** — Architectury, Fabric loader, NeoForge versions

## Contributing

This collection is MIT-licensed and open for contributions. When opening a PR:

- Verify all Java examples are correct for the stated MC version
- Verify all JSON is valid (`jq . < file.json`)
- Add a `CHANGELOG.md` entry describing what changed
- Do not add features not yet stable in the stated MC version
