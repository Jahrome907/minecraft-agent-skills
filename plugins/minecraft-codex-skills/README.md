# minecraft-codex-skills plugin

This plugin packages the repository's 10 Minecraft development skills for both
Codex and Claude Code.

## Layout

```text
plugins/minecraft-codex-skills/
├── .codex-plugin/plugin.json
├── .claude-plugin/plugin.json
└── skills/
```

## Development model

- Do not edit `skills/` directly in this plugin.
- Edit `.agents/skills/` in the repo root.
- Run `./scripts/sync-skills-layout.sh sync` to refresh `.codex/skills/`,
  `.claude/skills/`, and this plugin bundle.

## Codex local install

1. Keep this plugin under `plugins/minecraft-codex-skills/` in the same repo that
    contains `.agents/plugins/marketplace.json`.
2. Start Codex from the repo root.
3. Open `/plugins` and install `minecraft-codex-skills` from the repo marketplace.
4. Restart Codex after plugin changes so the local cached copy refreshes.

## Claude Code local install

```bash
claude --plugin-dir ./plugins/minecraft-codex-skills
```
