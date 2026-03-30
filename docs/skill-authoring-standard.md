# Skill Authoring Standard

This repository uses `.agents/skills/` as canonical. `.codex/skills/` is a generated compatibility mirror.

## Required Per Skill

- Directory: `.agents/skills/<skill-name>/`
- File: `SKILL.md`
- Frontmatter:
  - `name: <skill-name>`
  - `description: >` concise trigger description
- Routing boundaries section with:
  - Use when
  - Do not use when

## Quality Rules

- Examples in runnable code blocks must not contain unresolved placeholders such as `{player}` or `run ...`.
- Keep Minecraft 1.21.x data path conventions consistent across all skills.
- Prefer short top-level guidance and move deep examples into `references/`.
  This is a migration target and not a CI-hard requirement for legacy skills yet.
- All Java snippets target Java 21.
- Keep platform boundaries explicit (NeoForge/Fabric/Paper/Vanilla).

## Mirror and Audit Workflow

1. Edit only in `.agents/skills/`.
2. Run `./scripts/sync-skills-layout.sh sync`.
3. Run `node ./scripts/audit-skills.mjs`.
4. Run `node ./scripts/validate-doc-snippets.mjs`.
5. Commit both canonical and mirror changes.

## Versioning Policy

- Use `{mod_version}+{mc_version}` for mod release examples.
- Keep validator commands mirror-safe by using `./scripts/...` from the installed skill directory.
- Bundled skill validators must ship any parser/runtime code they need inside the skill directory.
- Do not make bundled validators depend on repo-root `node_modules`; that is only acceptable for repo-only development scripts.
