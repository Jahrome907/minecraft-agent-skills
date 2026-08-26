# minecraft-agent-skills

This repo is a skills bundle, not a Minecraft project. It ships 13 Minecraft
skills and a dual-target Codex/Claude Code plugin.

## Editing

- Treat `.agents/skills/` as canonical.
- After canonical changes, run `npm run sync:skills` to refresh `.codex/skills/`,
  `.claude/skills/`, and `plugins/minecraft-codex-skills/skills/`.
- Do not hand-edit mirrored skill trees.
- Run `npm run check` before publishing changes.

## Skill standards

- Target current stable Minecraft 26.x and Java 25 for new work. Preserve
  explicit legacy lanes for Minecraft 1.21.x on Java 21 and Forge 1.20.1 on
  Java 17 with ForgeGradle 6.
- Keep platform-specific patterns clear and examples runnable.
- Keep JSON valid and formatted with 2-space indentation.
- Do not create cross-skill dependencies.

## Repository boundaries

- Do not run Minecraft, Gradle, or Paper server commands here.
- Keep helper scripts self-contained inside the skill that uses them.
- Do not add unstable Minecraft features or version guidance.
