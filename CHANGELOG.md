# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- Added a dedicated Forge 1.20.1 / Java 17 lane to `minecraft-modding`, including ForgeGradle 6, `mods.toml`, `FMLJavaModLoadingContext`, `MinecraftForge.EVENT_BUS`, `RegistryObject`, networking, and legacy data-path guidance

### Changed

- Corrected the modding registry cheat sheet to use current 1.21.x NeoForge/Fabric registry constants instead of stale `Registry.*` names
- Replaced an invalid command-scripting `tellraw` translatable-text example with copyable raw JSON text components
- Clarified that bundled worldgen biome and dimension JSON examples are structural guidance for 1.21.10-and-earlier shapes and require exact vanilla-registry verification before use on 1.21.11+ packs
- Updated contributor and mirror documentation to prefer npm script entrypoints for sync/check workflows, and tightened security-reporting fallback wording around GitHub private vulnerability reporting

## [2.5.1] - 2026-06-13

### Added

- Added a README quick-install prompt that users can give to their own agent to download the repository archive and install the Codex or Claude Code skill bundle without manually cloning the repo

### Changed

- Corrected the worldgen dimension example to omit invalid `fixed_time: false`, documented `assets/<namespace>/items/` in the resource-pack layout, and separated one-time scoreboard setup from recurring command example runtime logic
- Hardened the datapack validator against legacy `functions/` and `tags/functions/` paths, and extended the worldgen validator to check jigsaw `start_pool`, template structure template locations, and processor list references
- Tightened Architectury multiloader guidance around same-package `@ExpectPlatform` implementations, required `mod_version` samples, fresher Fabric/Yarn/Loom pins, stricter Fabric dependency metadata, and Kotlin-DSL-safe build-check script output
- Clarified Codex plugin quick-install requirements, aligned CI with the full local check gate, pinned first-party GitHub Actions, and made the dev-tool setup script explicit about Node/npm prerequisites
- Improved Paper plugin and testing validators for `paper-plugin.yml`, server `/reload` misuse, and GameTest metadata/template wiring
- Hardened server-admin backup guidance and marked WorldEdit/EssentialsX chat and console examples as plain text instead of datapack functions
- Bumped package and plugin metadata to version `2.5.1`

## [2.5.0] - 2026-05-29

### Changed

- Refreshed 1.21.x version guidance for Fabric 1.21.11, Architectury multiloader artifacts, MockBukkit 4.x, and Gradle setup actions
- Corrected 1.21.9+ datapack/resource-pack metadata examples and validators to use exact `[major, minor]` pack versions instead of JSON decimals
- Added resource-pack validator coverage for 1.21.4+ `assets/<namespace>/items/*.json` item model definitions
- Updated command examples for 1.21.9 spawn rotation syntax and 1.21.11 namespaced gamerules, and made the bundled stopwatch `.mcfunction` copyable
- Hardened server-admin, WorldEdit, and EssentialsX ops guidance around Velocity forwarding, backup quiescing, WorldEdit history cleanup, sign-shop permissions, and spawn-module checks
- Added local mirror-sync validation to `npm run check` and aligned CI to use the same npm script entrypoints
- Clarified that this bundle remains centered on 1.21.x and that Minecraft 26.1.x requires a separate Java/API/data-format verification pass
- Bumped package and plugin metadata to version `2.5.0`

## [2.4.2] - 2026-05-04

### Changed

- Normalized SKILL.md frontmatter descriptions to single-line quoted format across all 13 skills, per Agent Skills open standard and official Codex/Claude Code documentation best practices (avoids block-scalar whitespace-folding ambiguity during truncation)
- Added explicit "Use when..." routing trigger to `minecraft-ci-release` description, which was the only skill missing one
- Improved `minecraft-datapack`: removed redundant "What Is a Datapack?" intro section and full selector reference (deferred to `minecraft-commands-scripting`); condensed execute subcommands to datapack-specific patterns (chained execute, store result, dimension routing); renamed "NBT and storage" to "Storage NBT (datapack-specific global state)"; added validator step to development workflow before `/reload`
- Improved `minecraft-essentials-ops`: removed redundant "Scope and Positioning" prose section; fixed duplicate `1.` numbered list bug in sign shops runbook; added separate sign shop `[Buy]`/`[Sell]` format examples; added kit `config.yml` YAML example; added troubleshooting hints to mute, jail, and tempban workflows; fixed duplicate `1.` at end of Safe Config Rollout runbook (now correctly numbered 1–6)
- Improved `minecraft-plugin-dev`: refined scheduler inline comments for clarity; reorganized "Build & Run" into numbered "Build, Validate, and Run" steps (build → validate → fix → deploy); merged separate "Validator Script" section into the build steps
- Improved `minecraft-testing`: removed boilerplate `@BeforeEach` empty placeholder; removed generic MockBukkit intro paragraph; added four-step GameTest setup checklist (structure files, run server, check output, fix timeouts) before the Running GameTests section
- Improved `minecraft-world-generation`: merged "Testing Worldgen" and "Validator Script" sections into a unified seven-step "Development Workflow" (edit → validate → fix → in-game biome testing → dimension testing → check logs → reload note with fresh-world/chunk guidance)
- Synced all description and content changes to `.codex/skills/`, `.claude/skills/`, and `plugins/minecraft-codex-skills/skills/` mirrors
- Documented repository independence from Mojang/Microsoft in `README.md` and `TERMS.md`, and set least-privilege `contents: read` permissions on the skills audit workflow

## [2.4.1] - 2026-04-21

### Added

- New `minecraft-imagegen` skill for Minecraft pack art, thumbnails, concept textures, and UI/mockup workflows using Codex's built-in image generation tool
- Public repo-policy docs at `CONTRIBUTING.md`, `SECURITY.md`, `PRIVACY.md`, and `TERMS.md` to make the open-source maintenance/disclosure model explicit
- Bundled support assets for previously thin skills: image-generation prompt/asset references plus a brief scaffold script, and compact rollout/safety references for server-admin, WorldEdit ops, and EssentialsX ops

### Changed

- Updated top-level docs and plugin docs to reflect the 13-skill collection, current Codex skills/plugin terminology, and Codex local plugin cache behavior
- Enriched the Codex plugin manifest with install-surface metadata recommended by current plugin docs, and hardened plugin/community validation around that metadata
- Tightened the repo's skill authoring standard so new multi-workflow skills are expected to ship support assets and end-to-end examples, with structure/docs updated in the same change
- Bumped package and plugin metadata to version `2.4.1` and refreshed the README explainer asset to reflect all 13 skills plus Codex-first image-generation support

## [2.4.0] - 2026-04-04

### Added

- Targeted `scripts/check-version-drift.mjs` guard plus validator fixture coverage for modern `pack.mcmeta` metadata, multiloader version sanity, and testing layout checks
- Bundled support assets for previously thin skills: Architectury reference/checker, testing layout reference/validator, and commands execute/selector cheat sheets with example scripts

### Changed

- Refreshed the repo's 1.21.x guidance around the 1.21.11 line across modding, multiloader, datapack, resource-pack, CI/release, and top-level docs
- Updated datapack and resource-pack docs plus validators to support both legacy `pack_format` metadata and newer `min_format` / `max_format` metadata for 1.21.9+
- Expanded Paper plugin/testing guidance with `paper-plugin.yml`, Folia-safe scheduler patterns, and newer PDC examples

## [2.3.3] - 2026-03-29

### Added (2.3.3)

- Canonical skill index at `.agents/skills/README.md` plus mirrored copies at `.codex/skills/README.md`, `.claude/skills/README.md`, and `plugins/minecraft-codex-skills/skills/README.md`
- New `minecraft-worldedit-ops` skill with practical command workflows for selections, masks, clipboards/schematics, terraforming brushes, and rollback-safe operations
- New `minecraft-essentials-ops` skill with EssentialsX-focused runbooks for economy, kits/warps/homes, permissions, and moderation workflows
- Companion mirror docs at `.codex/README.md` and `.claude/README.md` describing canonical-first edit flow

### Changed (2.3.3)

- Reworked `minecraft-server-admin` into deployment-driven operations guidance with explicit environment routing, server-type decision matrix, and concrete playbooks for performance, plugin operations, proxy/forwarding, backup/recovery, and incident troubleshooting
- Hardened `scripts/sync-skills-layout.sh` and `scripts/audit-skills.mjs` to require a canonical/mirrored skills index and fail fast when index files are missing
- Updated top-level docs and plugin docs for the expanded 12-skill inventory, including README skill tables and `AGENTS.md` selection guidance
- Updated `docs/assets/how-it-works.svg` to display a 12-skill bundle surface
- Bumped package and plugin metadata to version `2.3.3`

## [2.3.1] - 2026-03-27

### Changed (2.3.1)

- Renamed the GitHub repository to `minecraft-agent-skills` and updated public URLs, badges, and metadata while keeping the bundled plugin identifier `minecraft-codex-skills` for install compatibility

## [2.3.0] - 2026-03-27

### Added (2.3.0)

- Dual-target plugin bundle at `plugins/minecraft-codex-skills/` with `.codex-plugin/plugin.json`, `.claude-plugin/plugin.json`, and a synced shared `skills/` tree
- `.agents/plugins/marketplace.json` so Codex can load the local plugin bundle from a repo marketplace entry
- `.gitattributes` to keep Markdown, shell, JSON, and workflow checkouts consistent for contributors across platforms

### Changed (2.3.0)

- Made `scripts/audit-skills.mjs` tolerant of CRLF and BOM-prefixed files so the skill audit behaves consistently across Windows and Linux checkouts
- Extended mirror-sync validation to cover the plugin bundle in addition to `.codex/skills/` and `.claude/skills/`
- Added `scripts/validate-plugin-bundle.mjs` and wired it into `npm run check` plus GitHub Actions so plugin manifests, marketplace metadata, and required plugin README install guidance cannot drift silently
- Removed the remaining mirror-unsafe `.agents/skills/...` references from bundled skill documentation
- Updated README, plugin README, and CONTRIBUTING guidance to document the repo-marketplace Codex install flow, plugin installs, and Windows maintainer prerequisites more accurately

## [2.2.0] - 2026-03-14

### Changed (2.2.0)

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
