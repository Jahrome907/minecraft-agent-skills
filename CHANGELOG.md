# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Changed

- Made the `plugin-dev` validator's valid Java fixture self-contained by adding a minimal `org.bukkit.plugin.java.JavaPlugin` stub, preventing editor diagnostics in the repo without changing validator behavior
- Hardened bundled validators and fixture coverage for malformed workflow YAML, missing workflow action refs, PR gitleaks token wiring, empty worldgen roots, legacy `biome_modifiers` paths, worldgen dimension reference checks across local namespaces, invalid dimension JSON handling, invalid `tags/worldgen` layouts, and strict-mode tag-only / dimension-only packs
- Replaced mirror-unsafe `.agents/...` validator command examples with mirror-safe `./scripts/...` usage
- Standardized public versioning guidance on `{mod_version}+{mc_version}` and aligned bundled Fabric / NeoForge version snippets
- Clarified Paper `api-version` guidance and fixed missing imports in the main plugin example
- Added pinned Node maintainer tooling, CI doc-snippet validation, and a dedicated secret-scan workflow
- Improved CONTRIBUTING / SECURITY guidance for both compatibility mirrors and private vulnerability reporting
- Added GitHub community health files (`CODEOWNERS`, PR template, issue forms) plus CI-enforced validation that those public repo files remain present and structured
- Documented the intended protected-branch policy for `main` so GitHub settings match the repo's local release and audit workflow

## [2.1.0] - 2026-03-07

### Added (2.1.0)

- Canonical skills tree at `.agents/skills/` with compatibility mirror policy for `.codex/skills/`
- `scripts/sync-skills-layout.sh` to sync/check canonical and mirror skill trees
- `scripts/audit-skills.mjs` to validate skill frontmatter, path consistency, placeholder safety, and mirror drift
- `scripts/run-skill-validator-fixtures.sh` fixture harness to regression-test bundled skill validators
- `scripts/setup-dev-tools.sh` to install/check local maintainer prerequisites (`jq`, `rsync`, `node`, `npm`)
- `.github/workflows/skills-audit.yml` CI workflow to enforce sync and audit checks on push/PR
- `docs/skill-authoring-standard.md` contributor standard for skill structure and quality rules
- New bundled validators:
  - `minecraft-datapack/scripts/validate-datapack.sh`
  - `minecraft-resource-pack/scripts/validate-resource-pack.sh`
  - `minecraft-ci-release/scripts/validate-workflow-snippets.sh`
  - `minecraft-plugin-dev/scripts/validate-plugin-layout.sh`
  - `minecraft-world-generation/scripts/validate-worldgen-json.sh`

### Changed (2.1.0)

- Normalized Minecraft 1.21.x resource path conventions across skills/references (`loot_table`, `tags/block`, `tags/item`, `biome_modifier`)
- Fixed invalid/non-runnable snippets in NeoForge capability, Fabric GameTest, and command scripting examples
- Corrected CI artifact glob examples and plugin packaging upload patterns in `minecraft-ci-release`
- Removed `/reload` recommendation from plugin deployment guidance
- Corrected server property key in security checklist (`max-players`)
- Updated documentation to use `.agents/skills/` as canonical with `.codex/skills/` compatibility mirror
- Updated `check-build.sh` to avoid GNU-only `grep -P` usage
- Added explicit routing boundaries (`Use when` / `Do not use when`) to all 10 skills
- Enforced routing-boundary structure checks in `scripts/audit-skills.mjs`
- Hardened `check-build.sh` for Gradle Kotlin DSL files and Architectury multiloader outputs
- Reworked README install commands to avoid hardcoded `yourname` URLs
- Added validator script usage sections in affected skills and wired fixture tests into CI

## [2.0.0] - 2026-03-07

### Added (2.0.0)

- `minecraft-plugin-dev/SKILL.md` — Paper/Bukkit server plugin development:
  build.gradle.kts, plugin.yml reference, event listeners, commands, schedulers,
  PDC, Adventure/MiniMessage, config.yml, Vault integration, Paper-specific async APIs
- `minecraft-datapack/SKILL.md` — Vanilla datapack authoring: pack format numbers
  for all 1.21.x versions, function tags, execute reference, macro functions,
  advancements, recipe types, loot tables, predicates, worldgen overrides
- `minecraft-commands-scripting/SKILL.md` — Vanilla commands and RCON scripting:
  full selector reference, execute subcommands, scoreboards, NBT path syntax,
  tellraw JSON text schema, teams, bossbars, RCON bash/Python patterns
- `minecraft-multiloader/SKILL.md` — Architectury NeoForge + Fabric multiloader:
  full 3-subproject layout, settings.gradle, build.gradle files, DeferredRegister
  in common, @ExpectPlatform annotation, Fabric/NeoForge entrypoints
- `minecraft-testing/SKILL.md` — Automated testing: JUnit 5, MockBukkit
  (events, commands, inventory, scheduler, PDC), NeoForge GameTests,
  Fabric GameTests, GitHub Actions CI matrix
- `minecraft-ci-release/SKILL.md` — CI/CD and publishing: GitHub Actions build
  and release workflows, Modrinth minotaur plugin, CurseForge gradle plugin,
  semantic versioning, Dependabot, CHANGELOG format, release script
- `minecraft-world-generation/SKILL.md` — Custom worldgen: biome JSON (full schema),
  configured/placed features, dimension JSON, NeoForge BiomeModifier,
  Fabric BiomeModifications API, structures (jigsaw), structure sets
- `minecraft-resource-pack/SKILL.md` — Resource pack creation: pack format numbers,
  block/item model schemas, blockstate definitions, animated textures, sounds.json,
  language files, OptiFine CIT, Iris shaders, new 1.21.4 item model format
- `minecraft-server-admin/SKILL.md` — Server administration: Aikar's JVM flags,
  Paper config tuning, Spark monitoring, Docker/docker-compose, Velocity proxy,
  backup scripts, security checklist
- `AGENTS.md` — Updated to cover full 10-skill collection with skill selection table
- `README.md` — Rewritten as collection overview with all 10 skills and examples

## [1.0.0] - 2025-07-27

### Added (1.0.0)

- Initial release of the Minecraft Codex Skill
- `SKILL.md` — NeoForge + Fabric platform detection, build commands, project layouts,
  core concepts, NeoForge/Fabric quick patterns, JSON asset templates, datagen guide,
  common tasks checklist, open-source conventions
- `references/neoforge-api.md` — complete NeoForge 1.21.x API patterns:
  mod entry point, mods.toml, DeferredRegister, BlockEntity, event bus,
  Menu/GUI, capabilities, networking, biome modifiers, gradle.properties template
- `references/fabric-api.md` — complete Fabric 1.21.x API patterns:
  ModInitializer, fabric.mod.json, block/item registration, BlockEntity, Mixins,
  Fabric events, networking, commands, custom GUI, gradle.properties template
- `references/common-patterns.md` — cross-platform patterns: directional blocks,
  slabs, stairs, food/tool/armor items, entity types, Brigadier commands,
  all recipe types, tags, data gen providers (blockstate, item model, recipe,
  loot table), language files, GitHub Actions CI, Modrinth/CurseForge publishing
- `scripts/check-build.sh` — environment check script (Java 21, gradlew, platform detection, build)
- `AGENTS.md` — guidance for Codex when working in the skill repository itself
- `README.md` — installation guide, usage examples, feature table
- `LICENSE` — MIT license
