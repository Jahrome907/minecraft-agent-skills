# minecraft-codex-skills

An open-source collection of **10 AI coding agent skills** covering every major area
of Minecraft development — mods, plugins, datapacks, commands, testing, CI/CD,
world generation, resource packs, and server administration.

Drop the `.agents/` folder (for Codex), `.claude/` folder (for Claude Code),
or `.codex/` folder into any Minecraft project and your AI agent will
automatically select the right skill for every task you assign it.

---

## What is a Codex Skill?

Codex skills live in `.agents/skills/<skill-name>/` within a repository and are
read by [OpenAI Codex](https://openai.com/index/introducing-codex/) whenever you
assign it a task. Each `SKILL.md` file defines the skill's `name`, `description`,
and detailed instructions. Codex selects relevant skills automatically based on
the description field and your task.

This repository also keeps compatibility mirrors at `.codex/skills/` and
`.claude/skills/`. Canonical source of truth is `.agents/skills/`.

---

## Skills in this Collection

|Skill|Directory|What it covers|
|---|---|---|
|**minecraft-modding**|`minecraft-modding/`|NeoForge + Fabric mod development — blocks, items, entities, events, data gen|
|**minecraft-plugin-dev**|`minecraft-plugin-dev/`|Paper/Bukkit server plugins — events, commands, schedulers, PDC, Adventure, Vault|
|**minecraft-datapack**|`minecraft-datapack/`|Vanilla datapacks — functions, advancements, recipes, loot tables, tags|
|**minecraft-commands-scripting**|`minecraft-commands-scripting/`|Vanilla commands, scoreboards, NBT paths, JSON text, RCON scripting|
|**minecraft-multiloader**|`minecraft-multiloader/`|Architectury multiloader — single codebase targeting NeoForge and Fabric|
|**minecraft-testing**|`minecraft-testing/`|JUnit 5, MockBukkit, NeoForge/Fabric GameTests, GitHub Actions CI|
|**minecraft-ci-release**|`minecraft-ci-release/`|GitHub Actions pipelines, Modrinth/CurseForge publishing, semantic versioning|
|**minecraft-world-generation**|`minecraft-world-generation/`|Custom biomes, dimensions, structures (datapacks + mods)|
|**minecraft-resource-pack**|`minecraft-resource-pack/`|Textures, block/item models, sounds, animations, OptiFine CIT, shaders|
|**minecraft-server-admin**|`minecraft-server-admin/`|Server setup, JVM tuning, Docker, Velocity proxy, backups, security|

---

## Installation

### Option A — Clone and copy

```bash
# From your Minecraft project root:
REPO_URL="https://github.com/Jahrome907/minecraft-codex-skills"
git clone "$REPO_URL" /tmp/mc-skills
cp -r /tmp/mc-skills/.agents .
```

### Option B — Git submodule

```bash
REPO_URL="https://github.com/Jahrome907/minecraft-codex-skills"
git submodule add "$REPO_URL" .skills-src
cp -r .skills-src/.agents .
```

### Option C — Manual download

Download the latest release from
`https://github.com/Jahrome907/minecraft-codex-skills/releases/latest`
and extract the `.agents/` folder into your project root.

---

## Project Structure

```text
your-project/
└── .agents/
    └── skills/
        ├── minecraft-modding/
        │   ├── SKILL.md
        │   ├── references/
        │   │   ├── neoforge-api.md
        │   │   ├── fabric-api.md
        │   │   └── common-patterns.md
        │   └── scripts/
        │       └── check-build.sh
        ├── minecraft-plugin-dev/
        │   ├── SKILL.md
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
        └── minecraft-server-admin/
            └── SKILL.md

# Compatibility mirrors (same content, synced by script):
your-project/
├── .codex/
│   └── skills/
│       └── ... (mirrors .agents/skills)
└── .claude/
    └── skills/
        └── ... (mirrors .agents/skills)
```

---

## Maintainers

Repo maintainer tooling requires **Node 20+**. The copied skill directories do not
need the repo-root Node install.

```bash
# One-time: install/check local dev tools
./scripts/setup-dev-tools.sh

# Install pinned Node-based maintainer tooling
npm ci

# Edit canonical skills only
$EDITOR .agents/skills/<skill>/SKILL.md

# Sync compatibility mirrors
./scripts/sync-skills-layout.sh sync

# Run repository skill audit
node ./scripts/audit-skills.mjs

# Validate markdown/JSON/YAML doc snippets
node ./scripts/validate-doc-snippets.mjs

# Run validator fixture tests
./scripts/run-skill-validator-fixtures.sh

# Run repo policy fixtures
./scripts/test-repo-policy-fixtures.sh

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

# Server plugin
codex "Create a Paper plugin that gives players a speed boost for 10 seconds \
      when they eat a golden apple, with a 60-second cooldown tracked in PDC."

# Datapack
codex "Write a datapack function that detects when a player kills 10 zombies \
      and gives them a custom advancement with a diamond reward."

# Server admin
codex "Generate a docker-compose.yml for a Paper 1.21.1 server with Aikar's \
      JVM flags, persistent volumes, and auto-restart on crash."
```

Codex reads the appropriate `SKILL.md` and picks up platform patterns, correct
API versions, JSON schemas, and build commands automatically.

---

## Usage with ChatGPT Codex

1. Open [chatgpt.com/codex](https://chatgpt.com/codex)
2. Connect your GitHub repository
3. Assign a task — Codex reads the skills from your repo automatically

---

## Supported Versions

|Platform|Version|Java|
|---|---|---|
|NeoForge|21.1.x / 21.4.x / 21.5.x|21|
|Fabric|0.114.x+|21|
|Paper/Bukkit|1.21.x (`paper-api:1.21.11-R0.1-SNAPSHOT`)|21|
|Vanilla datapack|1.21–1.21.5 (pack formats 48–71)|—|
|Resource pack|1.21–1.21.5 (pack formats 34–55)|—|

---

## Contributing

PRs are welcome! Before opening one:

1. Verify Java examples you change remain correct for **Java 21** in their target project context
2. Validate all JSON with `jq . < file.json`
3. Test against the stated Minecraft / platform version
4. Add a `CHANGELOG.md` entry describing what changed
5. Keep examples complete and runnable — no pseudo-code

See [AGENTS.md](AGENTS.md) and [docs/skill-authoring-standard.md](docs/skill-authoring-standard.md) for guidance on editing skill files.
See [CONTRIBUTING.md](CONTRIBUTING.md) for PR workflow and quality gates.
Public issues should use the GitHub issue templates, and security reports should follow [SECURITY.md](SECURITY.md).

---

## License

MIT — free to use, modify, and share. See [LICENSE](LICENSE).