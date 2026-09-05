# Minecraft Agent Skills

Thirteen reusable skills for current Minecraft 26.x development and operations,
with explicit Minecraft 1.21.x and Forge 1.20.1 legacy lanes. Use raw skills in
a project or install the bundled Codex and Claude Code plugin.

## Install

Install one copy of each skill for the host you use. Preserve unrelated local
skills when a target already exists. Copy only the selected skill folders if
you do not need the whole bundle; do not copy this repository's `AGENTS.md`
into a Minecraft project.

| Host | Copy or install |
| --- | --- |
| Codex | `.agents/skills/` into the project's `.agents/skills/` |
| Older Codex hosts | `.codex/skills/` only if that host uses the legacy location |
| Claude Code | `.claude/skills/` into the project's `.claude/skills/` |
| Plugin | `.agents/plugins/marketplace.json` and `plugins/minecraft-codex-skills/` |

For a Codex plugin install, keep the marketplace file and plugin directory under
the same project root, open the plugins surface, and install
`minecraft-codex-skills`. For Claude Code, run:

```bash
claude --plugin-dir ./plugins/minecraft-codex-skills
```

The raw folders and plugin are alternative installation methods. Loading both
can expose duplicate skills. `minecraft-imagegen` needs an image-generation
tool supplied by the host or an already connected integration; installing this
bundle or selecting a model does not add that tool.

<!-- markdownlint-disable MD033 -->
<p align="center">
  <img src="docs/assets/how-it-works.svg" alt="How the Minecraft Agent Skills bundle is installed and routed" width="100%" />
</p>
<!-- markdownlint-enable MD033 -->

## Skills

| Skill | Use it for |
| --- | --- |
| `minecraft-modding` | NeoForge, Fabric, and Forge 1.20.1 mods |
| `minecraft-plugin-dev` | Paper, Bukkit, and Spigot plugins |
| `minecraft-datapack` | Vanilla datapacks, functions, loot, and advancements |
| `minecraft-commands-scripting` | Commands, scoreboards, NBT, and RCON scripting |
| `minecraft-multiloader` | Architectury projects targeting NeoForge and Fabric |
| `minecraft-testing` | JUnit, MockBukkit, and GameTests |
| `minecraft-ci-release` | GitHub Actions and Modrinth/CurseForge releases |
| `minecraft-world-generation` | Biomes, dimensions, structures, and features |
| `minecraft-resource-pack` | Textures, models, sounds, fonts, and shaders |
| `minecraft-imagegen` | Pack art, concepts, thumbnails, and UI mockups |
| `minecraft-server-admin` | Hosting, tuning, backups, proxies, and operations |
| `minecraft-worldedit-ops` | Safe WorldEdit selections, schematics, and brushes |
| `minecraft-essentials-ops` | EssentialsX configuration, moderation, and economy |

## Using GPT-6 Astra and Claude Fable 5.1

These are host-loaded skills, not model-specific API integrations. Select the
model in Codex or Claude Code. The bundle does not set model IDs, effort,
permissions, or global configuration.

Describe the outcome and target version, for example:

- "Fix this Paper 1.21.11 command without upgrading the server."
- "Add a 26.2 datapack recipe and verify its files."
- "Audit this Velocity configuration; prepare any changes locally."

The agent should inspect the existing project first, load only relevant
references, and finish authorized work with focused edits and proportionate
checks. Existing version pins and explicit user choices take precedence over
example defaults. A layout validator checks selected static rules; it does
not establish compilation, in-game behavior, or production readiness.

The September 2026 review follows the official guidance for
[GPT-6 Astra](https://developers.openai.com/api/docs/guides/latest-model#gpt-6-astra-behavior),
[Claude Fable 5.1](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1),
[Codex skills](https://developers.openai.com/codex/skills), and
[Claude Code skills](https://code.claude.com/docs/en/skills).
This is a content and packaging review, not a benchmark of both models or
an in-game certification of every example.
See the [September 2026 audit](docs/skill-audit-2026-09.md) for all 13 skills,
primary sources, corrections, and verification limits.

## Maintaining the bundle

Use Node 22 or newer and Bash (Git Bash works on Windows). Edit
`.agents/skills/`, then run:

```bash
npm run sync:skills
npm run check
```

The sync command refreshes `.codex/skills/`, `.claude/skills/`, and the plugin
bundle. The copied skill directories do not need the repository's Node tooling.

## License

[MIT](LICENSE)
