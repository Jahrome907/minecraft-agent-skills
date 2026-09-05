# Conditional Resource-Pack Assets

Read this reference only when the requested pack uses current or legacy item
models, sounds, fonts, OptiFine, or shaders. Keep each feature within the target
client's supported format.

## Current and legacy item models

For **1.21.4 and later**, place item definitions in
`assets/<namespace>/items/<item>.json`. The `minecraft:custom_model_data`
string property reads the component's `strings` list. A `when` value can be one
string or a non-empty list of strings; numeric values such as `1001` are not
valid for this selector.

```json
{
  "model": {
    "type": "minecraft:select",
    "property": "minecraft:custom_model_data",
    "fallback": {
      "type": "minecraft:model",
      "model": "minecraft:item/stick"
    },
    "cases": [
      {
        "when": ["magic_wand"],
        "model": {
          "type": "minecraft:model",
          "model": "mypack:item/magic_wand"
        }
      }
    ]
  }
}
```

Give the matching item component with a string value:

```mcfunction
/give @s minecraft:stick[custom_model_data={strings:["magic_wand"]}]
```

For **1.21.3 and earlier**, use a model's legacy `overrides` array and numeric
`predicate.custom_model_data` values. Do not mix the legacy override format into
the current `items/` definition.

```json
{
  "parent": "minecraft:item/handheld",
  "textures": { "layer0": "minecraft:item/stick" },
  "overrides": [
    {
      "predicate": { "custom_model_data": 1001 },
      "model": "mypack:item/magic_wand"
    }
  ]
}
```

## Sounds

The namespace of an event is the namespace containing its `sounds.json`. The
namespace in a sound entry's `name` identifies the sound-file namespace. Put a
custom event in `assets/mypack/sounds.json` and its file at
`assets/mypack/sounds/ui/click.ogg`.

```json
{
  "ui.click": {
    "sounds": [
      { "name": "mypack:ui/click", "volume": 1.0 }
    ]
  },
  "ui.click_alias": {
    "sounds": [
      { "name": "mypack:ui.click", "type": "event" }
    ]
  }
}
```

An omitted `type` is a sound-file entry and resolves to an `.ogg` file. An
`event` entry references another sound event and must never be treated as a file
path. `sounds.json` maps events to sound objects; it does not choose the sound
source. A command chooses its source, for example
`/playsound mypack:ui.click ui @s` (the `ui` source is available from 1.21.6),
and mod code supplies the relevant `SoundSource`. Use `replace: true` only when
intentionally replacing an event inherited from a lower-priority pack.

## Fonts

Place font definitions at `assets/<namespace>/font/<name>.json`. A bitmap
provider's `file` is a texture resource location including `.png`.

```json
{
  "providers": [
    {
      "type": "bitmap",
      "file": "mypack:font/icons.png",
      "ascent": 8,
      "height": 9,
      "chars": ["\uE000", "\uE001"]
    }
  ]
}
```

Use private-use characters deliberately and keep each bitmap cell consistent
with its declared height.

## Client-mod and shader boundaries

OptiFine CIT files under `assets/minecraft/optifine/` are OptiFine-specific and
do not work in vanilla or Iris. Do not present them as a portable item system.

Iris shader packs are separate ZIPs with a top-level `shaders/` directory. They
are selected through Iris, not loaded as `assets/iris/shaders` inside a resource
pack. Vanilla resource packs do not provide a supported way to override core
render shaders. Keep shader packs separate from a vanilla resource-pack
deliverable, and test them with the exact Iris version named by the user.

## Sources

- [Mojang: Java Edition 1.21.4 item models](https://www.minecraft.net/en-us/article/minecraft-java-edition-1-21-4)
- [NeoForge 1.21.8 sounds](https://docs.neoforged.net/docs/1.21.8/resources/client/sounds/)
- [Iris documentation](https://irisshaders.dev/)
