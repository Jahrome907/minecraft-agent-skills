# AGENTS.md — minecraft-agent-skills Repository

This repository is a collection of **13 AI agent skills**: 12 Minecraft
development/operations skills plus one Minecraft image-generation skill, along
with a dual-target plugin bundle for Codex and Claude Code.
It is NOT itself a Minecraft project — it contains skill files and plugin packaging
that get copied into Minecraft mod, plugin, or server-admin projects.

## What this repo contains

Representative layout excerpts follow. They are intentionally not exhaustive;
other skills in this repo also include `references/` and `scripts/` support assets.

```text
.agents/skills/                ← canonical source of truth
├── minecraft-modding/
│   ├── SKILL.md
│   ├── references/
│   │   ├── neoforge-api.md
│   │   ├── forge-1.20.1-api.md
│   │   ├── fabric-api.md
│   │   └── common-patterns.md
│   └── scripts/
│       └── check-build.sh
├── minecraft-plugin-dev/
│   ├── SKILL.md
│   ├── references/
│   │   └── runtime-patterns.md
│   └── scripts/
│       └── validate-plugin-layout.sh
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
├── minecraft-imagegen/
│   ├── SKILL.md
│   ├── references/
│   │   ├── prompt-patterns.md
│   │   └── asset-recipes.md
│   └── scripts/
│       └── scaffold-asset-brief.sh
├── minecraft-server-admin/
│   ├── SKILL.md
│   └── references/
│       └── deployment-checklists.md
├── minecraft-worldedit-ops/
│   ├── SKILL.md
│   └── references/
│       └── safety-checklists.md
└── minecraft-essentials-ops/
    ├── SKILL.md
    └── references/
        └── permissions-and-rollout-checklists.md
```

Compatibility mirror (kept in sync by script/CI):

```text
.codex/skills/
├── minecraft-modding/            ← NeoForge + Fabric + Forge 1.20.1 mod development
│   ├── SKILL.md
│   ├── references/
│   │   ├── neoforge-api.md
│   │   ├── forge-1.20.1-api.md
│   │   ├── fabric-api.md
│   │   └── common-patterns.md
│   └── scripts/
│       └── check-build.sh
├── minecraft-plugin-dev/         ← Paper/Bukkit server plugin development
│   ├── SKILL.md
│   ├── references/
│   │   └── runtime-patterns.md
│   └── scripts/
│       └── validate-plugin-layout.sh
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
├── minecraft-imagegen/           ← Pack art, concept textures, thumbnails, mockups
│   ├── SKILL.md
│   ├── references/
│   │   ├── prompt-patterns.md
│   │   └── asset-recipes.md
│   └── scripts/
│       └── scaffold-asset-brief.sh
├── minecraft-server-admin/       ← Server setup, JVM tuning, Docker, Velocity
│   ├── SKILL.md
│   └── references/
│       └── deployment-checklists.md
├── minecraft-worldedit-ops/      ← WorldEdit operations and safe edit workflows
│   ├── SKILL.md
│   └── references/
│       └── safety-checklists.md
└── minecraft-essentials-ops/     ← EssentialsX operations and moderation/economy policy
    ├── SKILL.md
    └── references/
        └── permissions-and-rollout-checklists.md
```

Claude Code mirror (kept in sync by script/CI):

```text
.claude/skills/
├── minecraft-modding/            ← NeoForge + Fabric + Forge 1.20.1 mod development
│   ├── SKILL.md
│   ├── references/
│   │   ├── neoforge-api.md
│   │   ├── forge-1.20.1-api.md
│   │   ├── fabric-api.md
│   │   └── common-patterns.md
│   └── scripts/
│       └── check-build.sh
├── minecraft-plugin-dev/         ← Paper/Bukkit server plugin development
│   ├── SKILL.md
│   ├── references/
│   │   └── runtime-patterns.md
│   └── scripts/
│       └── validate-plugin-layout.sh
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
├── minecraft-imagegen/           ← Pack art, concept textures, thumbnails, mockups
│   ├── SKILL.md
│   ├── references/
│   │   ├── prompt-patterns.md
│   │   └── asset-recipes.md
│   └── scripts/
│       └── scaffold-asset-brief.sh
├── minecraft-server-admin/       ← Server setup, JVM tuning, Docker, Velocity
│   ├── SKILL.md
│   └── references/
│       └── deployment-checklists.md
├── minecraft-worldedit-ops/      ← WorldEdit operations and safe edit workflows
│   ├── SKILL.md
│   └── references/
│       └── safety-checklists.md
└── minecraft-essentials-ops/     ← EssentialsX operations and moderation/economy policy
    ├── SKILL.md
    └── references/
        └── permissions-and-rollout-checklists.md
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
    ├── minecraft-imagegen/
    ├── minecraft-server-admin/
    ├── minecraft-worldedit-ops/
    └── minecraft-essentials-ops/
```

## Skill Selection Guide

Codex selects skills automatically from the `description` field in each `SKILL.md`.
The table below maps task types to which skill(s) to load:

|Task type|Skill to use|
|---|---|
|NeoForge / Fabric / Forge 1.20.1 mod (blocks, items, entities, events, datagen)|`minecraft-modding`|
|Paper / Bukkit / Spigot server plugin|`minecraft-plugin-dev`|
|Vanilla datapack (functions, advancements, recipes, loot tables)|`minecraft-datapack`|
|`/execute`, scoreboards, NBT, `tellraw`, RCON scripting|`minecraft-commands-scripting`|
|Single code base targeting both NeoForge and Fabric|`minecraft-multiloader`|
|Unit tests, MockBukkit, NeoForge GameTests, Fabric GameTests|`minecraft-testing`|
|GitHub Actions CI, Modrinth/CurseForge auto-publish, semantic versioning|`minecraft-ci-release`|
|Custom biomes, dimensions, structures (datapack or mod)|`minecraft-world-generation`|
|Texture packs, block/item models, animated textures, shaders|`minecraft-resource-pack`|
|Pack art, pack icons, thumbnails, concept textures, and UI mockups|`minecraft-imagegen`|
|Server launch flags, `server.properties`, Docker, Velocity proxy|`minecraft-server-admin`|
|WorldEdit selections, schematics, brushes, safe rollback workflows|`minecraft-worldedit-ops`|
|EssentialsX commands, economy, kits/warps/homes, moderation and permissions|`minecraft-essentials-ops`|

## When working in this repository

- **Do not** run Minecraft, Gradle, or Paper server commands here; there is no game project to build.
- Edit `.agents/skills/` only; sync mirrors and the plugin bundle after canonical changes.
- When editing skill files, keep examples accurate for **Minecraft 1.21.x** unless the file or section is explicitly marked for Forge 1.20.1.
- Keep Java examples correct for **Java 21** by default; Forge 1.20.1 examples must stay correct for **Java 17** and ForgeGradle 6.
- Keep JSON snippets valid and pretty-printed with 2-space indentation.
- Mark platform-specific patterns (NeoForge / Forge 1.20.1 / Fabric / Paper) clearly.
- Prefer complete, runnable code snippets over pseudo-code.
- Skills are independent — do not create cross-skill dependencies.

## Updating for new Minecraft versions

When Minecraft releases a new version, update the following files:

1. **`minecraft-modding/SKILL.md`** — version table, NeoForge/Fabric/Forge 1.20.1 versions
2. **`minecraft-modding/references/neoforge-api.md`** — class names, gradle.properties versions
3. **`minecraft-modding/references/forge-1.20.1-api.md`** — ForgeGradle, Forge version, Java 17, and legacy Forge API patterns
4. **`minecraft-modding/references/fabric-api.md`** — yarn mappings, Fabric API version
5. **`minecraft-modding/references/common-patterns.md`** — changed JSON formats
6. **`minecraft-plugin-dev/SKILL.md`** and **`minecraft-plugin-dev/references/runtime-patterns.md`** — `paper-api` version, `api-version` field, runtime API examples
7. **`minecraft-datapack/SKILL.md`** — pack format number table
8. **`minecraft-resource-pack/SKILL.md`** — pack format number table
9. **`minecraft-commands-scripting/SKILL.md`** — any syntax changes
10. **`minecraft-world-generation/SKILL.md`** — worldgen JSON schema changes
11. **`minecraft-multiloader/SKILL.md`** — Architectury, Fabric loader, NeoForge versions
12. **`minecraft-worldedit-ops/SKILL.md`** — command workflow or safety behavior changes
13. **`minecraft-essentials-ops/SKILL.md`** — EssentialsX command/config/permission behavior changes

## Repo Notes

This collection is MIT-licensed and maintained as a small repo-owned skills bundle.
If repo content is changed:

- Verify all Java examples are correct for the stated MC version
- Verify all JSON is valid (`jq . < file.json`)
- Add a `CHANGELOG.md` entry describing what changed
- Do not add features not yet stable in the stated MC version
