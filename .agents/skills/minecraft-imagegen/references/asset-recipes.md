# Minecraft Image Asset Recipes

Load this file when the user names a specific asset type and you need a sharper
handoff recipe, naming convention, or review target.

## Quick Map

| Asset type | Bias | Review target | Notes |
|---|---|---|---|
| `pack.png` icon | Strong silhouette, simple square composition | Reads cleanly at `64x64` | Save a high-res source plus the final icon |
| Release banner | Hero scene plus copy-safe negative space | Works on desktop and mobile crop | Prefer art-only version plus composed version |
| Thumbnail/store card | Central focal point, high contrast | Still legible in feed or marketplace grids | Keep text minimal |
| Texture concept | Flat material study | Easy to repaint into `16x16`, `32x32`, or `64x64` | Treat as concept, not final asset |
| Server banner/header | Branding plus environmental cue | Still reads when cropped wide | Avoid dense scene clutter |
| UI mockup | Clear panel hierarchy | Space remains for real UI elements | Keep typography flexible |

## `pack.png`

Recommended filenames:

- `pack-icon-concept-a.png`
- `pack-icon-concept-b.png`
- `pack.png` for the approved final

Recipe:

1. Generate one square asset with a strong subject, or multiple concepts when alternatives were requested.
2. Down-select based on tiny-size readability, not only full-size detail.
3. Keep decorative text out unless the brand absolutely requires it.
4. Save the approved version into the pack root as `pack.png`.

## Release Banner

Recommended filenames:

- `release-banner-art.png`
- `release-banner-composed.png`

Recipe:

1. Ask for a wide composition with explicit negative space for title text.
2. Prefer one clear hero subject or scene instead of several equal focal points.
3. If final text is still unsettled, save art-only and overlay text later.

## Thumbnail or Store Card

Recipe:

1. Optimize for quick scanning at small size.
2. Use one dominant color story and one dominant subject.
3. Avoid dense paragraphs or interface text inside the generated image.

## Texture Concept

Recommended filenames:

- `ore-texture-concept-v1.png`
- `machine-casing-lookdev.png`

Recipe:

1. Keep the image flat, front-on, and lighting-neutral.
2. Ask for material qualities, not scene storytelling.
3. When pack integration is in scope, complete the pixel cleanup, tiling, and file references; otherwise deliver the concept as requested.

## Server Banner or Header

Recipe:

1. Call out the server tone explicitly: cozy SMP, competitive PvP, fantasy RPG, tech network, etc.
2. Reserve one side for logo or server name.
3. Ask for a composition that survives wide crop and partial mobile crop.

## UI Mockup

Recipe:

1. Identify whether the deliverable is background art, a full mockup, or a visual direction sample.
2. Leave generous blank regions for slots, labels, and action buttons.
3. If the design may become code later, keep layout logic simple and repeatable.
