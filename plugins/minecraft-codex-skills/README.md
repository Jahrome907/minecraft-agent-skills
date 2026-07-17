# minecraft-codex-skills

This plugin packages the same 13 Minecraft skills for Codex and Claude Code.
`minecraft-imagegen` requires a host with image-generation support.

## Install

- Codex: keep this directory beside `.agents/plugins/marketplace.json`, then
  install `minecraft-codex-skills` from the plugins surface.
- Claude Code:

  ```bash
  claude --plugin-dir ./plugins/minecraft-codex-skills
  ```

## Maintain

Edit `.agents/skills/` in the repository root, then run `npm run sync:skills`.
Do not edit this plugin's `skills/` directory directly.
