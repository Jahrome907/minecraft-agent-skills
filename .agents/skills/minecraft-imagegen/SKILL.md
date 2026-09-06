---
name: minecraft-imagegen
description: "Generate or edit Minecraft raster assets such as pack icons, promo art, concept textures, thumbnails, banners, and UI mockups. Use when the deliverable is a bitmap image rather than JSON, SVG, or code-native assets."
---

# Minecraft Image Generation Skill

Use this skill when a Minecraft project needs new raster art or a visual concept
that will later be refined into a resource pack, release post, store listing, or
server brand asset.

## Scope

### Routing Boundaries
- `Use when`: the task is generating or editing a bitmap image for a Minecraft project, such as `pack.png`, release art, store thumbnails, concept textures, UI mockups, or server/banner art.
- `Do not use when`: the task is deterministic resource-pack implementation work such as `pack.mcmeta`, block/item model JSON, blockstates, fonts, sounds, or shader files (`minecraft-resource-pack`).
- `Do not use when`: the task is vector/code-native UI, an existing SVG/logo system, or non-image code/assets.
- `Do not use when`: the current host does not expose built-in image generation or an equivalent image-editing tool.

### Support Assets

- Read [prompt patterns](references/prompt-patterns.md) for an underspecified request or a generation/edit prompt template.
- Read [asset recipes](references/asset-recipes.md) for a pack icon, release banner, server header, or texture concept sheet.
- Use `scripts/scaffold-asset-brief.sh` only when a saved brief is useful for stakeholder feedback or repeated rounds; a clear image request can proceed directly.
- Invoke the helper by its absolute installed path from the project workspace. Relative `--out` values resolve from that workspace. When running from the installed skill directory, pass an absolute `--out` project path or set `CODEX_WORKSPACE_ROOT`.

---

## Default Execution

- If the current host does not expose built-in image generation or an equivalent image-editing tool, stop and tell the user this skill is unavailable on that host; offer prompt/brief preparation or a host with an available image-generation tool.
- Use the built-in `image_gen` tool by default when the host supports it.
- Match the requested deliverable: complete a requested asset, or produce concepts when the user asks for exploration. Do not require a separate concept approval for a clear generation or edit request.
- The built-in image generation workflow supports fresh generations and edits against existing local/reference images; prefer that over describing a manual paint-over process.
- Save a requested project asset at the intended workspace path when the host exposes the output file; otherwise return the generated image and state that a local save could not be verified.
- Preserve existing assets non-destructively by using versioned filenames unless the user explicitly asked to overwrite.
- If editing a local image, load or attach it first so the image is visible to the agent before requesting an edit.

---

## Good Use Cases

- `pack.png` concepts or replacements for mods, datapacks, or resource packs
- Release-banner art for GitHub, Modrinth, CurseForge, or social posts
- Texture look-dev references that will be cleaned up manually into final pixel art
- Server logos, banners, splash artwork, or rules-screen art
- HUD/menu mockups for plugin or mod UX planning
- Promo sheets that show blocks, mobs, or themed environments in-context

---

## Workflow

1. Use the request to identify the asset type, target dimensions, output path, and whether this is a generation or edit. Inspect the existing image for an edit; gather style references only when needed.
2. Generate the requested asset using the available tool. Describe the subject, composition, Minecraft style, and constraints. For an edit, state the change and what must remain unchanged.
3. Inspect the result at its intended display size. Correct observed defects with focused edits; do not require additional rounds when the result meets the request.
4. Save or return the requested result and verify any saved path. Complete pixel cleanup, tiling, and pack references when integration is in scope. Additional skills are optional.

---

## Asset-Specific Guidance

### Pack Icons

- Design for square cropping and tiny-size readability.
- Keep the silhouette bold and text minimal.
- Check readability at `64x64`; that is a useful preview size, not a required `pack.png` resolution. Use the project's target dimensions and the host's supported image-editing workflow.

### Texture Concepts

- Ask for flat, front-on presentation with even lighting and minimal perspective.
- State whether the texture should feel vanilla-faithful, noisy/gritty, hand-painted, or stylized.
- Assume manual cleanup before shipping. Generated textures are best used as concept or paint-over references, not automatic drop-ins.

### UI Mockups

- Reserve negative space for labels, slots, and status text.
- Keep text large and high-contrast.
- Call out whether the mockup should feel vanilla, modded-tech, fantasy, or admin-panel inspired.

### Promo Art and Thumbnails

- Leave copy-safe negative space for release titles or taglines.
- Avoid tiny text and clutter that will collapse on mobile or store cards.
- Specify whether the output should show gameplay-like framing, hero artwork, or a clean showcase layout.

---

## Review Checklist

- The image reads clearly at the actual target size.
- Any text is spelled correctly and positioned as requested.
- No extra logos, watermarks, or unrelated objects were introduced.
- The style matches the requested Minecraft context.
- For texture concepts, the result looks easy to paint over, simplify, or tile manually.

---
