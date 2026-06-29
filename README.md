# minecraft-agent-skills

[![Skills Audit](https://github.com/Jahrome907/minecraft-agent-skills/actions/workflows/skills-audit.yml/badge.svg)](https://github.com/Jahrome907/minecraft-agent-skills/actions/workflows/skills-audit.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/Jahrome907/minecraft-agent-skills)](https://github.com/Jahrome907/minecraft-agent-skills/releases/latest)
[![Minecraft](https://img.shields.io/badge/Minecraft-1.21.x%20%2B%20Forge%201.20.1-brightgreen)](https://www.minecraft.net/)

A public skills bundle of **13 AI agent skills** covering every major area
of Minecraft development — mods, plugins, datapacks, commands, testing, CI/CD,
world generation, resource packs, server administration, WorldEdit operations,
EssentialsX operations, and image generation for pack art, texture concepts,
thumbnails, and promo assets.

Use it either as raw skill folders for Codex or Claude Code, or as a dual-target
plugin bundle under `plugins/minecraft-codex-skills/` for plugin-based installs.
The `minecraft-imagegen` skill requires a host that exposes image generation;
Codex supports that directly, while other hosts should treat that skill as conditional.

The repository is branded as `minecraft-agent-skills`; the bundled plugin/package
identifier remains `minecraft-codex-skills` for marketplace and install compatibility.

This is an independent, community-maintained skills bundle. It is not affiliated
with, endorsed by, sponsored by, or approved by Mojang Studios, Microsoft, or the
official Minecraft project.

<!-- markdownlint-disable MD033 -->
<p align="center">
      <img src="docs/assets/how-it-works.svg" alt="How It Works — choose raw skills or plugin install, load the 13-skill bundle into your agent, assign a task, and let the right skill activate; image generation is Codex-first" width="100%"/>
</p>
<!-- markdownlint-enable MD033 -->

Use the raw-skill path if you want to copy `.agents/` for Codex or `.claude/`
for Claude Code directly into a project. The `.codex/skills/` tree is kept as a
compatibility mirror, not the recommended authoring or raw-install path. Use the
plugin path if you want to keep the repository layout intact and load
`plugins/minecraft-codex-skills/` through Codex's local marketplace flow or
Claude Code's `--plugin-dir` support.

---

## What is a Codex Skill?

Codex skills live in `.agents/skills/<skill-name>/` within a repository. Per the
official [Codex skills docs](https://developers.openai.com/codex/skills), skills
are the authoring format for reusable workflows, while plugins are the installable
distribution unit for reusable skills and app integrations. Each `SKILL.md` file
defines the skill's `name`, `description`, and detailed instructions. Codex selects
relevant skills automatically based on the description field and your task.

This repository keeps `.agents/skills/` as the canonical source of truth and
syncs exact mirrors to `.codex/skills/`, `.claude/skills/`, and the shared plugin
bundle at `plugins/minecraft-codex-skills/skills/`.
The routing index lives at `.agents/skills/README.md`.

---

## Skills in this Collection

|Skill|Directory|What it covers|
|---|---|---|
|**minecraft-modding**|`minecraft-modding/`|NeoForge + Fabric + Forge 1.20.1 mod development — blocks, items, entities, events, data gen|
|**minecraft-plugin-dev**|`minecraft-plugin-dev/`|Paper/Bukkit server plugins — events, commands, schedulers, PDC, Adventure, Vault|
|**minecraft-datapack**|`minecraft-datapack/`|Vanilla datapacks — functions, advancements, recipes, loot tables, tags|
|**minecraft-commands-scripting**|`minecraft-commands-scripting/`|Vanilla commands, scoreboards, NBT paths, JSON text, RCON scripting|
|**minecraft-multiloader**|`minecraft-multiloader/`|Architectury multiloader — single codebase targeting NeoForge and Fabric|
|**minecraft-testing**|`minecraft-testing/`|JUnit 5, MockBukkit, NeoForge/Fabric GameTests, GitHub Actions CI|
|**minecraft-ci-release**|`minecraft-ci-release/`|GitHub Actions pipelines, Modrinth/CurseForge publishing, semantic versioning|
|**minecraft-world-generation**|`minecraft-world-generation/`|Custom biomes, dimensions, structures (datapacks + mods)|
|**minecraft-resource-pack**|`minecraft-resource-pack/`|Textures, block/item models, sounds, animations, OptiFine CIT, shaders|
|**minecraft-imagegen**|`minecraft-imagegen/`|Pack icons, promo art, concept textures, thumbnails, server banners, UI mockups|
|**minecraft-server-admin**|`minecraft-server-admin/`|Server setup, JVM tuning, Docker, Velocity proxy, backups, security|
|**minecraft-worldedit-ops**|`minecraft-worldedit-ops/`|WorldEdit ops playbooks: selections, masks, schematics, brushes, safe rollback|
|**minecraft-essentials-ops**|`minecraft-essentials-ops/`|EssentialsX ops: kits/warps/homes, economy, permissions, moderation workflows|

---

## Asset Workflow Example

For image-heavy Minecraft tasks, the bundle now treats `minecraft-imagegen` as a
first-class skill instead of a thin add-on. It ships prompt-pattern references,
asset-specific recipes, and a small brief scaffold script so generated art can be
reviewed and handed off cleanly to `minecraft-resource-pack` when the final asset
needs pack wiring.

Example Codex prompt:

```bash
codex "Create two square pack icon concepts for a vanilla-faithful archaeology pack, save the preferred concept into the workspace, then outline the follow-up resource-pack steps."
```

---

## Installation

### Quick install — agent prompt

If you want another agent to install the skills for you without manually cloning
this repository, paste the prompt below from the target project root:

```text
Install the Minecraft agent skills into this project without using git clone.

Repository archive:
https://github.com/Jahrome907/minecraft-agent-skills/archive/refs/heads/main.zip

Work from the current project root. Download the repository archive to a
temporary directory, extract it, and install the skills for the agent host I am
using:

- For Codex, merge the extracted `.agents/` directory into this project.
- For Claude Code, merge the extracted `.claude/` directory into this project.
- If I ask for a Codex plugin install instead of raw skills, keep or copy both
  `.agents/plugins/marketplace.json` and `plugins/minecraft-codex-skills/`
  under this project root so Codex can discover the local marketplace entry.
- If I ask for a Claude Code plugin install instead of raw skills, copy
  `plugins/minecraft-codex-skills/` into this project and explain the next
  `claude --plugin-dir` step.

Preserve existing local agent files. If `.agents/skills/` or `.claude/skills/`
already exists, replace only this bundle's `minecraft-*` skill directories and
the bundled skills `README.md`; do not delete unrelated local skills or custom
agent config.

After copying, verify that all 13 Minecraft skill directories are present:
`minecraft-modding`, `minecraft-plugin-dev`, `minecraft-datapack`,
`minecraft-commands-scripting`, `minecraft-multiloader`, `minecraft-testing`,
`minecraft-ci-release`, `minecraft-world-generation`,
`minecraft-resource-pack`, `minecraft-imagegen`, `minecraft-server-admin`,
`minecraft-worldedit-ops`, and `minecraft-essentials-ops`.

Report the installed target path, which files or directories were changed, and
any existing bundle files that were overwritten. Do not run Minecraft, Gradle,
Paper, or a server from this repository.
```

### Option A — Raw skills for Codex

```bash
REPO_URL="https://github.com/Jahrome907/minecraft-agent-skills"
git clone "$REPO_URL" /tmp/mc-skills
cp -r /tmp/mc-skills/.agents .
```

Codex can read the canonical `.agents/skills/` tree directly. The `.codex/skills/`
mirror is kept byte-for-byte identical for hosts or older setups that still
expect that layout.

### Option B — Raw skills for Claude Code

```bash
REPO_URL="https://github.com/Jahrome907/minecraft-agent-skills"
git clone "$REPO_URL" /tmp/mc-skills
cp -r /tmp/mc-skills/.claude .
```

### Option C — Dual-target plugin bundle

The repository now ships a plugin bundle that both Codex and Claude Code can load.
`minecraft-imagegen` remains conditional on the host exposing an image-generation
tool, so treat that skill as Codex-first unless the current host documents support:

```text
plugins/minecraft-codex-skills/
├── .codex-plugin/plugin.json
├── .claude-plugin/plugin.json
└── skills/
```

For Codex local marketplace installs:

1. Keep the repository layout intact so `.agents/plugins/marketplace.json` and `plugins/minecraft-codex-skills/` stay under the same repo root.
2. Start Codex from that repo root.
3. Open the plugins surface with `/plugins`.
4. Install `minecraft-codex-skills` from the repo marketplace discovered at `.agents/plugins/marketplace.json`.
5. If a local plugin change does not appear immediately, reinstall or restart Codex. Local marketplace installs are loaded from `~/.codex/plugins/cache/<marketplace>/<plugin>/local/`, not directly from the marketplace path.

For Claude Code local plugin testing:

```bash
claude --plugin-dir ./plugins/minecraft-codex-skills
```

### Option D — Git submodule

```bash
REPO_URL="https://github.com/Jahrome907/minecraft-agent-skills"
git submodule add "$REPO_URL" .skills-src
cp -r .skills-src/.agents .
```

### Option E — Manual download

Download the latest release from
`https://github.com/Jahrome907/minecraft-agent-skills/releases/latest`.

- Use `.agents/` for Codex raw-skill installs.
- Use `.codex/skills/` only when your host explicitly expects the compatibility mirror.
- Use `.claude/` for Claude Code raw-skill installs.
- Use `plugins/minecraft-codex-skills/` for Claude Code plugin installs.
- For Codex plugin installs, keep the full release layout intact so `.agents/plugins/marketplace.json` and `plugins/minecraft-codex-skills/` remain together under the same repo root.

---

## Project Structure

Representative excerpt only: several other skills also ship `references/` or
`scripts/` support assets, but the tree below highlights the main install layout.

```text
your-project/
└── .agents/
    └── skills/
        ├── README.md
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
        │   ├── SKILL.md
        │   └── scripts/
        │       └── validate-datapack.sh
        ├── minecraft-commands-scripting/
        │   └── SKILL.md
        ├── minecraft-multiloader/
        │   └── SKILL.md
        ├── minecraft-testing/
        │   └── SKILL.md
        ├── minecraft-ci-release/
        │   ├── SKILL.md
        │   └── scripts/
        │       └── validate-workflow-snippets.sh
        ├── minecraft-world-generation/
        │   ├── SKILL.md
        │   └── scripts/
        │       └── validate-worldgen-json.sh
        ├── minecraft-resource-pack/
        │   ├── SKILL.md
        │   └── scripts/
        │       └── validate-resource-pack.sh
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

# Compatibility mirrors (same content, synced by script):
your-project/
├── .codex/
│   └── skills/
│       └── ... (mirrors .agents/skills)
└── .claude/
    └── skills/
        └── ... (mirrors .agents/skills)

# Dual-target plugin bundle (same skills, plugin manifests for both platforms):
your-project/
└── plugins/
      └── minecraft-codex-skills/
            ├── .codex-plugin/
            │   └── plugin.json
            ├── .claude-plugin/
            │   └── plugin.json
            └── skills/
                  └── ... (mirrors .agents/skills)
```

---

## Working On This Repo

Repo development tooling requires **Node 20+**. The copied skill directories do not
need the repo-root Node install.

The shell-based fixture scripts require **bash** and **jq**. `rsync` is used when
available for mirror sync, with a Node fallback for Windows/Git Bash environments.
On Windows, run repo checks from WSL or Git Bash with those tools available on
`PATH`.

```bash
# One-time: with Node 20+ and npm already installed, install/check support tools
bash ./scripts/setup-dev-tools.sh

# Install pinned repo tooling
npm ci

# Edit canonical skills only
$EDITOR .agents/skills/<skill>/SKILL.md

# Sync compatibility mirrors and plugin bundle
npm run sync:skills

# Check mirror sync from the same npm path used by CI
npm run check:sync

# Validate plugin manifests and marketplace metadata
node ./scripts/validate-plugin-bundle.mjs

# Run repository skill audit
node ./scripts/audit-skills.mjs

# Validate markdown/JSON/YAML doc snippets
node ./scripts/validate-doc-snippets.mjs

# Run validator fixture tests
bash ./scripts/run-skill-validator-fixtures.sh

# Run repo policy fixtures
bash ./scripts/test-repo-policy-fixtures.sh

# Validate GitHub community files
node ./scripts/check-github-community-files.mjs

# Run markdown lint from the pinned local dependency
npm run lint:md
```

---

## Usage with Codex CLI

```bash
# Install Codex CLI
npm install -g @openai/codex

# Mod development
codex "Add a custom ore block called Starstone that spawns in the deepslate layer \
      and gives 2-5 StarstoneGems when mined with iron pickaxe or better. NeoForge."

codex "Add a Forge 1.20.1 block item to this mod, keeping Java 17, mods.toml, \
      FMLJavaModLoadingContext, and net.minecraftforge imports intact."

# Server plugin
codex "Create a Paper plugin that gives players a speed boost for 10 seconds \
      when they eat a golden apple, with a 60-second cooldown tracked in PDC."

# Datapack
codex "Write a datapack function that detects when a player kills 10 zombies \
      and gives them a custom advancement with a diamond reward."

# Server admin
codex "Generate a docker-compose.yml for a Paper 1.21.11 server with Aikar's \
      JVM flags, persistent volumes, and auto-restart on crash."
```

The official Codex CLI docs still use npm for install and upgrade. Current Windows
support is experimental, so use a WSL2 workspace for the best Windows experience.

Codex reads the appropriate `SKILL.md` and picks up platform patterns, correct
API-version guidance, JSON patterns, validators, and build-command examples from
the skill bundle. Forge 1.20.1 projects route through the dedicated Forge reference
inside `minecraft-modding`; still verify against the target project's exact
Minecraft, loader, and server runtime before release.

If you prefer plugin installs in Codex, start Codex from the repository root,
open `/plugins`, and install `minecraft-codex-skills` from the repo marketplace
defined in `.agents/plugins/marketplace.json`.

---

## Usage with Claude Code Plugins

Use the bundled plugin for local testing or team distribution:

```bash
claude --plugin-dir ./plugins/minecraft-codex-skills
```

The plugin mirrors the same 13 skill folders under the `minecraft-codex-skills`
plugin namespace while keeping the shared `skills/` content synchronized with
the raw skill trees. `minecraft-imagegen` remains host-conditional and should be
treated as Codex-first unless the current host documents equivalent image-generation
support.

---

## Usage with Codex

1. Open [Codex](https://chatgpt.com/codex)
2. Connect your GitHub repository
3. Assign a task — Codex reads the skills from your repo automatically

---

## Supported Versions

This release is intentionally centered on the Minecraft 1.21.x line, with a
specific Forge 1.20.1 / Java 17 lane in `minecraft-modding` for legacy Forge
projects. Minecraft 26.1.x is now a separate porting surface: Java 25, Paper
26.x API coordinates, and newer Fabric/vanilla data changes should be verified
against upstream docs before applying 1.21.x snippets unchanged.

|Platform|Version|Java|
|---|---|---|
|NeoForge|1.21.x examples centered on 21.11.x|21|
|Forge|1.20.1 legacy lane (`forge_version=47.4.x`, ForgeGradle 6)|17|
|Fabric|1.21.11 line (`fabric-loader:0.19.3`, `fabric-api:0.141.4+1.21.11`, Loom 1.17.11)|21|
|Paper/Bukkit|1.21.x (`paper-api:1.21.11-R0.1-SNAPSHOT`)|21|
|Vanilla datapack|1.21-1.21.11 (`pack_format` 48-81 through 1.21.8; exact 1.21.11 metadata uses `[94, 1]` full-version arrays)|-|
|Resource pack|1.21-1.21.11 (`pack_format` 34-64 through 1.21.8; exact 1.21.11 metadata uses `[75, 0]` full-version arrays)|-|

---

## Repo Notes

This repository is a small, owner-managed skills bundle rather than a broader contributor project.

If you need to inspect or update repo structure:

1. Edit canonical skill content in `.agents/skills/`
2. Keep `.codex/skills/`, `.claude/skills/`, and `plugins/minecraft-codex-skills/skills/` synchronized
3. Run `npm run check` before publishing repo-level changes

See [AGENTS.md](AGENTS.md), [CONTRIBUTING.md](CONTRIBUTING.md),
[SECURITY.md](SECURITY.md), [PRIVACY.md](PRIVACY.md),
[TERMS.md](TERMS.md), and
[docs/skill-authoring-standard.md](docs/skill-authoring-standard.md) for the
repo-specific editing model.

---

## License

MIT — free to use, modify, and share. See [LICENSE](LICENSE).
