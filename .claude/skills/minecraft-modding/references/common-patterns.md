# Common Minecraft Modding Patterns

Cross-platform patterns for blocks, items, entities, data generation, commands, recipes,
and more. Code examples use NeoForge syntax unless noted; adapt field/method names for Fabric.

This reference retains 1.21.11 examples alongside 26.x replacements. A heading
that names Minecraft 26.x uses the 26.1 API and official Mojang mappings;
verify any later 26.x API change before copying code into a pinned project.
Treat all other examples as 1.21.11 examples unless their exact API is
verified for the project. For 26.3 loot data, use entry `condition` / `modifier`
and predicate/function `type`; the older loot JSON below needs migration.
See the [26.3 migration primer](https://docs.neoforged.net/primer/docs/26.3/).

---

## Blocks

### Simple Full-Cube Block

Files needed:

1. Java class (if custom behavior) or `registerSimpleBlock()` call
2. `assets/<modid>/blockstates/<name>.json`
3. `assets/<modid>/models/block/<name>.json`
4. `assets/<modid>/items/<name>.json` (1.21.x item definition)
5. `assets/<modid>/models/item/<name>.json`
6. `assets/<modid>/textures/block/<name>.png`
7. `data/<modid>/loot_table/blocks/<name>.json`
8. `en_us.json` entry

`assets/mymod/blockstates/my_block.json`:
```json
{
  "variants": {
    "": { "model": "mymod:block/my_block" }
  }
}
```

`assets/mymod/models/block/my_block.json`:
```json
{
  "parent": "minecraft:block/cube_all",
  "textures": {
    "all": "mymod:block/my_block"
  }
}
```

`assets/mymod/items/my_block.json`:
```json
{
  "model": {
    "type": "minecraft:model",
    "model": "mymod:block/my_block"
  }
}
```

`assets/mymod/models/item/my_block.json` is only needed when the block item needs
a model distinct from the block model. For that case:
```json
{
  "parent": "mymod:block/my_block"
}
```

`data/mymod/loot_table/blocks/my_block.json`:
```json
{
  "type": "minecraft:block",
  "pools": [{
    "rolls": 1,
    "entries": [{
      "type": "minecraft:item",
      "name": "mymod:my_block"
    }],
    "conditions": [{
      "condition": "minecraft:survives_explosion"
    }]
  }]
}
```

---

### Directional Block (faces a direction when placed)

Extend `DirectionalBlock`, define its codec, initialize the default `FACING`,
and set facing in `getStateForPlacement`. Register it through `registerBlock`
so its properties receive the block key. Use the
[1.21.11 block guide](https://docs.neoforged.net/docs/1.21.11/blocks/) for the
codec and registration signatures.

`assets/mymod/blockstates/my_directional_block.json`:
```json
{
  "variants": {
    "facing=north": { "model": "mymod:block/my_directional_block" },
    "facing=south": { "model": "mymod:block/my_directional_block", "y": 180 },
    "facing=west":  { "model": "mymod:block/my_directional_block", "y": 270 },
    "facing=east":  { "model": "mymod:block/my_directional_block", "y": 90 },
    "facing=up":    { "model": "mymod:block/my_directional_block", "x": -90 },
    "facing=down":  { "model": "mymod:block/my_directional_block", "x": 90 }
  }
}
```

---

### Slab Block

```java
public static final DeferredBlock<SlabBlock> MY_SLAB =
    BLOCKS.registerBlock("my_slab", SlabBlock::new,
        () -> BlockBehaviour.Properties.ofFullCopy(Blocks.STONE_SLAB));
```

`assets/mymod/models/block/my_slab.json`:
```json
{
  "parent": "minecraft:block/slab",
  "textures": {
    "bottom": "mymod:block/my_block",
    "top": "mymod:block/my_block",
    "side": "mymod:block/my_block"
  }
}
```

`assets/mymod/models/block/my_slab_top.json`:
```json
{
  "parent": "minecraft:block/slab_top",
  "textures": {
    "bottom": "mymod:block/my_block",
    "top": "mymod:block/my_block",
    "side": "mymod:block/my_block"
  }
}
```

`assets/mymod/blockstates/my_slab.json`:
```json
{
  "variants": {
    "type=bottom": { "model": "mymod:block/my_slab" },
    "type=top":    { "model": "mymod:block/my_slab_top" },
    "type=double": { "model": "mymod:block/my_block" }
  }
}
```

---

### Stairs Block

```java
public static final DeferredBlock<StairBlock> MY_STAIRS =
    BLOCKS.registerBlock("my_stairs",
        props -> new StairBlock(ModBlocks.MY_BLOCK.get().defaultBlockState(), props),
        () -> BlockBehaviour.Properties.ofFullCopy(Blocks.STONE_STAIRS));
```

`assets/mymod/models/block/my_stairs.json`:
```json
{
  "parent": "minecraft:block/stairs",
  "textures": {
    "bottom": "mymod:block/my_block",
    "top": "mymod:block/my_block",
    "side": "mymod:block/my_block"
  }
}
```

Also create `my_stairs_inner.json` and `my_stairs_outer.json`, inheriting from
`minecraft:block/inner_stairs` and `minecraft:block/outer_stairs` respectively.

---

## Items

### Food Item

```java
// NeoForge
public static final DeferredItem<Item> MY_FOOD =
    ITEMS.registerSimpleItem("my_food", props -> props
        .food(new FoodProperties.Builder()
            .nutrition(4)
            .saturationModifier(0.3f)
            .build(),
            Consumable.builder()
                .onConsume(new ApplyStatusEffectsConsumeEffect(
                    new MobEffectInstance(MobEffects.REGENERATION, 200, 1), 0.8f))
                .build()));
```

Food effects belong to the consumable component, not `FoodProperties.Builder`.
See the [1.21.11 consumable API](https://docs.neoforged.net/docs/1.21.11/items/consumables/).

`assets/mymod/items/my_food.json`:
```json
{
  "model": {
    "type": "minecraft:model",
    "model": "mymod:item/my_food"
  }
}
```

`assets/mymod/models/item/my_food.json`:
```json
{
  "parent": "minecraft:item/generated",
  "textures": {
    "layer0": "mymod:item/my_food"
  }
}
```

### Tool Item (NeoForge 26.x)

`Tier` and `SwordItem.createAttributes` are obsolete here. Define a
`ToolMaterial`, then use the `Item.Properties` tool delegate during item
registration.

```java
public static final ToolMaterial MY_TOOL_MATERIAL = new ToolMaterial(
    ModBlockTags.INCORRECT_FOR_MY_TOOL,
    455, 5.0f, 1.5f, 22,
    ModItemTags.REPAIRS_MY_TOOL
);

public static final DeferredItem<Item> MY_SWORD =
    ITEMS.registerItem("my_sword", props ->
        new Item(props.sword(MY_TOOL_MATERIAL, 3, -2.4f)));
```

### Armor Set (NeoForge 26.x)

`ArmorMaterial` is not a registry entry. Its equipment asset key identifies
the corresponding equipment definition, while `humanoidArmor` applies the
material to a normal `Item`.

```java
public static final ResourceKey<EquipmentAsset> MY_ARMOR_ASSET =
    ResourceKey.create(EquipmentAssets.ROOT_ID,
        Identifier.fromNamespaceAndPath(MyMod.MOD_ID, "my_material"));

public static final ArmorMaterial MY_ARMOR_MATERIAL = new ArmorMaterial(
    15,
    Map.of(
        ArmorType.HELMET, 3,
        ArmorType.CHESTPLATE, 8,
        ArmorType.LEGGINGS, 6,
        ArmorType.BOOTS, 3
    ),
    5, SoundEvents.ARMOR_EQUIP_IRON, 0.0f, 0.0f,
    ModItemTags.REPAIRS_MY_ARMOR, MY_ARMOR_ASSET
);

public static final DeferredItem<Item> MY_HELMET =
    ITEMS.registerItem("my_helmet", props ->
        new Item(props.humanoidArmor(MY_ARMOR_MATERIAL, ArmorType.HELMET)));
```

---

## Entity Types

```java
// ModEntityTypes.java (NeoForge 26.x)
public class ModEntityTypes {
    public static final DeferredRegister.Entities ENTITY_TYPES =
        DeferredRegister.createEntities(MyMod.MOD_ID);

    public static final Supplier<EntityType<MyEntity>> MY_ENTITY =
        ENTITY_TYPES.registerEntityType(
            "my_entity", MyEntity::new, MobCategory.CREATURE,
            builder -> builder
                .sized(0.9f, 1.3f)
                .clientTrackingRange(8)
                .updateInterval(3)
        );
}
```

For a concrete entity subclass, attributes, spawning, or renderer wiring, use
the current NeoForge entity guide for the project's exact version. Do not copy
the removed `EntityType.Builder#build(String)` overload into 26.x code.

---

## Commands (NeoForge 1.21.11, Mojang mappings)

```java
// NeoForge — register on GAME bus
@EventBusSubscriber(modid = MyMod.MOD_ID)
public class ModCommands {
    @SubscribeEvent
    public static void onRegisterCommands(RegisterCommandsEvent event) {
        registerCommands(event.getDispatcher());
    }

    private static void registerCommands(CommandDispatcher<CommandSourceStack> dispatcher) {
        dispatcher.register(
            Commands.literal("mymod")
                .then(Commands.literal("give")
                    .requires(Commands.hasPermission(Commands.LEVEL_GAMEMASTERS))
                    .then(Commands.argument("player", EntityArgument.player())
                        .then(Commands.argument("count", IntegerArgumentType.integer(1, 64))
                            .executes(ctx -> executeGive(ctx,
                                EntityArgument.getPlayer(ctx, "player"),
                                IntegerArgumentType.getInteger(ctx, "count"))))))
        );
    }

    private static int executeGive(CommandContext<CommandSourceStack> ctx,
            ServerPlayer player, int count) throws CommandSyntaxException {
        ItemStack stack = new ItemStack(ModItems.MY_ITEM.get(), count);
        player.getInventory().add(stack);
        ctx.getSource().sendSuccess(
            () -> Component.translatable("commands.mymod.give.success",
                count, player.getDisplayName()),
            true);
        return count;
    }
}
```

Minecraft 1.21.11 replaced numeric permission calls with permission checks.
Keep Fabric's registration callback and mapping names separate. See the
[1.21.11 migration primer](https://docs.neoforged.net/primer/docs/1.21.11/).

---

## Recipes (Minecraft 26.x JSON)

### Shaped Crafting Recipe

`data/mymod/recipe/my_item.json`:
```json
{
  "type": "minecraft:crafting_shaped",
  "pattern": [
    "SSS",
    " I ",
    " I "
  ],
  "key": {
    "S": "minecraft:stone",
    "I": "minecraft:iron_ingot"
  },
  "result": {
    "id": "mymod:my_item",
    "count": 1
  }
}
```

### Shapeless Recipe

```json
{
  "type": "minecraft:crafting_shapeless",
  "ingredients": [
    "minecraft:diamond",
    "minecraft:emerald"
  ],
  "result": {
    "id": "mymod:my_item",
    "count": 2
  }
}
```

### Smelting / Blasting / Smoking / Campfire

```json
{
  "type": "minecraft:smelting",
  "ingredient": "mymod:my_ore",
  "result": { "id": "mymod:my_ingot" },
  "experience": 0.7,
  "cookingtime": 200
}
```

### Custom Recipe Type (NeoForge / Fabric)

Implement the target version's `Recipe<SingleRecipeInput>` contract, its
serializer, and recipe-type registration together. Follow the
[versioned recipe guide](https://docs.neoforged.net/docs/1.21.11/resources/server/recipes/)
for codecs, recipe input, and recipe-book display requirements.

---

## Tags

Tags group blocks/items for use in recipes and game logic.
Extend the `minecraft` namespace's mining tags for vanilla tool behavior;
`mymod:mineable/pickaxe` would be a separate tag that vanilla does not consult.

`data/minecraft/tags/block/mineable/pickaxe.json`:
```json
{
  "replace": false,
  "values": ["mymod:my_block"]
}
```

`data/minecraft/tags/block/needs_iron_tool.json`:
```json
{
  "replace": false,
  "values": ["mymod:my_block"]
}
```

`data/mymod/tags/item/my_material.json`:
```json
{
  "replace": false,
  "values": ["mymod:my_ingot", "mymod:my_nugget"]
}
```

---

## Data Generation (NeoForge 1.21.11 and 26.x)

Use the target version of the [resource guide](https://docs.neoforged.net/docs/1.21.11/resources/)
and the project's generated provider classes. `GatherDataEvent.Client` can
register both client and server providers; the current MDK uses `runClientData`.
A split setup uses `.Client` and `.Server` with their matching tasks.

- Use `ModelProvider` for blockstates, block models, and client item definitions.
- Register recipe generation through `RecipeProvider.Runner` and keep its
  registry lookup and `RecipeOutput` wiring together.
- Use `event.createProvider(...)` and the project's registry provider setup.
  Do not copy old `ExistingFileHelper` or `GatherDataEvent#includeClient` code.
- Inspect generated resource paths and schemas before packaging. Older provider
  constructors and a successful static JSON check do not prove compatibility.

---

## Language File (en_us.json)

```json
{
  "block.mymod.my_block": "My Block",
  "item.mymod.my_item": "My Item",
  "item.mymod.my_food": "My Food",
  "entity.mymod.my_entity": "My Entity",
  "container.mymod.my_container": "My Container",
  "itemGroup.mymod.main_tab": "My Mod",
  "commands.mymod.give.success": "Gave %s x%s My Item"
}
```

---

## Build and publishing

Keep the project's configured build tasks and publication destinations.
Fabric server Game Tests use the configured `build` integration; NeoForge uses
`runGameTestServer`. Run only tasks present in that project. Inspect each
loader's actual distributable before publishing; older Fabric projects may
require `remapJar`, while 26.x uses the non-remapping build.
