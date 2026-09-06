# Common Minecraft Modding Patterns

Cross-platform patterns for blocks, items, entities, data generation, commands, recipes,
and more. Code examples use NeoForge syntax unless noted; adapt field/method names for Fabric.

This reference retains 1.21.11 examples alongside 26.x replacements. A heading
that names Minecraft 26.x uses the 26.1 API and official Mojang mappings;
verify any later 26.x API change before copying code into a pinned project.
Treat all other examples as the retained 1.21.11 lane unless their exact API is
verified for the project.

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

```java
public class MyDirectionalBlock extends DirectionalBlock {
    public static final DirectionProperty FACING = DirectionalBlock.FACING;

    public MyDirectionalBlock(Properties props) {
        super(props);
        registerDefaultState(stateDefinition.any().setValue(FACING, Direction.NORTH));
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext ctx) {
        return defaultBlockState().setValue(FACING, ctx.getNearestLookingDirection().getOpposite());
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> builder) {
        builder.add(FACING);
    }
}
```

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
    BLOCKS.register("my_slab", () -> new SlabBlock(
        BlockBehaviour.Properties.ofFullCopy(Blocks.STONE_SLAB)));
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
    BLOCKS.register("my_stairs", () -> new StairBlock(
        ModBlocks.MY_BLOCK.get().defaultBlockState(),
        BlockBehaviour.Properties.ofFullCopy(Blocks.STONE_STAIRS)));
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
    ITEMS.registerSimpleItem("my_food", new Item.Properties()
        .food(new FoodProperties.Builder()
            .nutrition(4)
            .saturationModifier(0.3f)
            .effect(new MobEffectInstance(MobEffects.REGENERATION, 200, 1), 0.8f)
            .build()));
```

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

## Commands (Brigadier — works the same in NeoForge and Fabric)

```java
// NeoForge — register on GAME bus
@EventBusSubscriber(modid = MyMod.MOD_ID, bus = Bus.GAME)
public class ModCommands {
    @SubscribeEvent
    public static void onRegisterCommands(RegisterCommandsEvent event) {
        registerCommands(event.getDispatcher());
    }
}

// Shared implementation
private static void registerCommands(CommandDispatcher<CommandSourceStack> dispatcher) {
    dispatcher.register(
        Commands.literal("mymod")
            .then(Commands.literal("give")
                .requires(src -> src.hasPermission(2))  // op level 2
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
```

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
  "ingredient": { "item": "mymod:my_ore" },
  "result": { "id": "mymod:my_ingot" },
  "experience": 0.7,
  "cookingtime": 200
}
```

### Custom Recipe Type (NeoForge / Fabric)

```java
// Implement Recipe<RecipeInput> and register RecipeSerializer + RecipeType
public class MyRecipe implements Recipe<SingleRecipeInput> {
    // ...
}
```

---

## Tags

Tags group blocks/items for use in recipes and game logic.

`data/mymod/tags/block/mineable/pickaxe.json`:
```json
{
  "replace": false,
  "values": ["mymod:my_block"]
}
```

`data/mymod/tags/block/needs_iron_tool.json`:
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

## Data Generation (NeoForge)

### BlockState Provider

```java
public class ModBlockStateProvider extends BlockStateProvider {
    public ModBlockStateProvider(PackOutput output, ExistingFileHelper helper) {
        super(output, MyMod.MOD_ID, helper);
    }

    @Override
    protected void registerStatesAndModels() {
        simpleBlock(ModBlocks.MY_BLOCK.get());
        simpleBlock(ModBlocks.SPECIAL_BLOCK.get(),
            models().cubeAll("special_block", modLoc("block/special_block")));
        // Slab:
        slabBlock((SlabBlock) ModBlocks.MY_SLAB.get(),
            modLoc("block/my_block"), modLoc("block/my_block"));
        // Stairs:
        stairsBlock((StairBlock) ModBlocks.MY_STAIRS.get(), modLoc("block/my_block"));
    }
}
```

### Item Model Provider

```java
public class ModItemModelProvider extends ItemModelProvider {
    public ModItemModelProvider(PackOutput output, ExistingFileHelper helper) {
        super(output, MyMod.MOD_ID, helper);
    }

    @Override
    protected void registerModels() {
        // BlockItem models derived from block models:
        withExistingParent(ModItems.MY_BLOCK_ITEM.getId().getPath(),
            modLoc("block/my_block"));

        // Flat item (generated):
        basicItem(ModItems.MY_ITEM.get());
    }
}
```

### Recipe Provider

```java
public class ModRecipeProvider extends RecipeProvider {
    public ModRecipeProvider(PackOutput output,
            CompletableFuture<HolderLookup.Provider> lookupProvider) {
        super(output, lookupProvider);
    }

    @Override
    protected void buildRecipes(RecipeOutput output) {
        ShapedRecipeBuilder.shaped(RecipeCategory.BUILDING_BLOCKS, ModItems.MY_BLOCK_ITEM.get(), 4)
            .pattern("SS")
            .pattern("SS")
            .define('S', Items.STONE)
            .unlockedBy("has_stone", has(Items.STONE))
            .save(output);

        SimpleCookingRecipeBuilder.smelting(
                Ingredient.of(Tags.Items.ORES_IRON),
                RecipeCategory.MISC,
                ModItems.MY_INGOT.get(),
                0.7f, 200)
            .unlockedBy("has_ore", has(Tags.Items.ORES_IRON))
            .save(output, ResourceLocation.fromNamespaceAndPath(MyMod.MOD_ID, "my_ingot_smelting"));
    }
}
```

### Loot Table Provider

```java
public class ModLootTableProvider extends LootTableProvider {
    public ModLootTableProvider(PackOutput output,
            CompletableFuture<HolderLookup.Provider> lookupProvider) {
        super(output, Set.of(), List.of(
            new SubProviderEntry(ModBlockLootTables::new, LootContextParamSets.BLOCK)
        ), lookupProvider);
    }

    public static class ModBlockLootTables extends BlockLootSubProvider {
        protected ModBlockLootTables(HolderLookup.Provider registries) {
            super(Set.of(), FeatureFlags.REGISTRY.allFlags(), registries);
        }

        @Override
        protected void generate() {
            dropSelf(ModBlocks.MY_BLOCK.get());

            // Drop ore with fortune/silk-touch handling:
            add(ModBlocks.MY_ORE.get(),
                createOreDrop(ModBlocks.MY_ORE.get(), ModItems.MY_GEM.get()));
        }

        @Override
        protected Iterable<Block> getKnownBlocks() {
            return ModBlocks.BLOCKS.getEntries().stream()
                .map(DeferredHolder::get)::iterator;
        }
    }
}
```

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

## GitHub Actions CI Workflow

```yaml
# .github/workflows/build.yml
name: Build

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'microsoft'
      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v4
      - name: Build with Gradle
        run: ./gradlew build
      - name: Run Game Tests
        run: ./gradlew runGameTestServer
        # For Fabric: ./gradlew runGametest
      - name: Upload Build Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: mod-jar
          path: build/libs/*.jar
          if-no-files-found: error
```

---

## Modrinth / CurseForge Publishing

```groovy
// build.gradle — Modrinth via Minotaur plugin
modrinth {
    token = System.getenv("MODRINTH_TOKEN")
    projectId = "your-project-id"
    versionNumber = project.mod_version
    versionType = "release"
    uploadFile = jar
    gameVersions = ["1.21.11"]
    loaders = ["neoforge"]
    changelog = rootProject.file("CHANGELOG.md").text
    syncBodyFrom = rootProject.file("README.md").text
}
```

```groovy
// Alternatively, use the official CurseForge Gradle plugin
curseforge {
    apiKey = System.getenv("CURSEFORGE_TOKEN")
    project {
        id = "000000"
        changelogType = "markdown"
        changelog = file("CHANGELOG.md")
        releaseType = "release"
        addGameVersion "1.21.11"
        addGameVersion "NeoForge"
        mainArtifact jar
    }
}
```
