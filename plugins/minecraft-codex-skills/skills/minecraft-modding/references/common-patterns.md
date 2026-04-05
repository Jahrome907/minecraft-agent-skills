# Common Minecraft Modding Patterns

Cross-platform patterns for blocks, items, entities, data generation, commands, recipes,
and more. Code examples use NeoForge syntax unless noted; adapt field/method names for Fabric.

---

## Blocks

### Simple Full-Cube Block

Files needed:

1. Java class (if custom behavior) or `registerSimpleBlock()` call
2. `assets/<modid>/blockstates/<name>.json`
3. `assets/<modid>/models/block/<name>.json`
4. `assets/<modid>/models/item/<name>.json`
5. `assets/<modid>/textures/block/<name>.png`
6. `data/<modid>/loot_table/blocks/<name>.json`
7. `en_us.json` entry

```json
// blockstates/my_block.json
{
  "variants": {
    "": { "model": "mymod:block/my_block" }
  }
}

// models/block/my_block.json
{
  "parent": "minecraft:block/cube_all",
  "textures": {
    "all": "mymod:block/my_block"
  }
}

// models/item/my_block.json
{
  "parent": "mymod:block/my_block"
}

// loot_table/blocks/my_block.json  (drops itself)
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

```json
// blockstates/my_directional_block.json
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

```json
// models/block/my_slab.json
{
  "parent": "minecraft:block/slab",
  "textures": {
    "bottom": "mymod:block/my_block",
    "top": "mymod:block/my_block",
    "side": "mymod:block/my_block"
  }
}

// models/block/my_slab_top.json
{
  "parent": "minecraft:block/slab_top",
  "textures": {
    "bottom": "mymod:block/my_block",
    "top": "mymod:block/my_block",
    "side": "mymod:block/my_block"
  }
}

// blockstates/my_slab.json
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

```json
// models/block/my_stairs.json
{
  "parent": "minecraft:block/stairs",
  "textures": {
    "bottom": "mymod:block/my_block",
    "top": "mymod:block/my_block",
    "side": "mymod:block/my_block"
  }
}
// Also create: my_stairs_inner.json, my_stairs_outer.json (inherit from minecraft:block/inner_stairs / outer_stairs)
```

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

```json
// models/item/my_food.json
{
  "parent": "minecraft:item/generated",
  "textures": {
    "layer0": "mymod:item/my_food"
  }
}
```

### Tool Item

```java
// Custom sword  (NeoForge)
public static final DeferredItem<SwordItem> MY_SWORD =
    ITEMS.register("my_sword", () -> new SwordItem(
        Tiers.DIAMOND,
        new Item.Properties()
            .attributes(SwordItem.createAttributes(Tiers.DIAMOND, 3, -2.4f))
    ));
```

### Armor Set

```java
// Define armor material as a static constant (NeoForge 1.21):
public static final ResourceKey<ArmorMaterial> MY_MATERIAL_KEY =
    ResourceKey.create(Registries.ARMOR_MATERIAL,
        ResourceLocation.fromNamespaceAndPath(MyMod.MOD_ID, "my_material"));

// Register items
public static final DeferredItem<ArmorItem> MY_HELMET =
    ITEMS.register("my_helmet", () -> new ArmorItem(
        MY_MATERIAL_KEY, ArmorType.HELMET, new Item.Properties()));
```

---

## Entity Types

```java
// ModEntityTypes.java  (NeoForge)
public class ModEntityTypes {
    public static final DeferredRegister<EntityType<?>> ENTITY_TYPES =
        DeferredRegister.create(BuiltInRegistries.ENTITY_TYPE, MyMod.MOD_ID);

    public static final DeferredHolder<EntityType<?>, EntityType<MyEntity>> MY_ENTITY =
        ENTITY_TYPES.register("my_entity",
            () -> EntityType.Builder.<MyEntity>of(MyEntity::new, MobCategory.CREATURE)
                .sized(0.9f, 1.3f)          // hitbox width, height
                .clientTrackingRange(8)
                .updateInterval(3)
                .build("my_entity"));
}

// MyEntity.java
public class MyEntity extends Animal {
    public MyEntity(EntityType<? extends MyEntity> type, Level level) {
        super(type, level);
    }

    public static AttributeSupplier.Builder createAttributes() {
        return Animal.createMobAttributes()
            .add(Attributes.MAX_HEALTH, 20.0)
            .add(Attributes.MOVEMENT_SPEED, 0.25)
            .add(Attributes.ATTACK_DAMAGE, 4.0);
    }

    @Override
    public @Nullable AgeableMob getBreedOffspring(ServerLevel level, AgeableMob mate) {
        return ModEntityTypes.MY_ENTITY.get().create(level);
    }
}

// Register attributes on MOD bus:
@SubscribeEvent
public static void registerEntityAttributes(EntityAttributeCreationEvent event) {
    event.put(ModEntityTypes.MY_ENTITY.get(), MyEntity.createAttributes().build());
}
```

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

## Recipes (JSON)

### Shaped Crafting Recipe

```json
// data/mymod/recipes/my_item.json
{
  "type": "minecraft:crafting_shaped",
  "pattern": [
    "SSS",
    " I ",
    " I "
  ],
  "key": {
    "S": { "item": "minecraft:stone" },
    "I": { "item": "minecraft:iron_ingot" }
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
    { "item": "minecraft:diamond" },
    { "item": "minecraft:emerald" }
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

```json
// data/mymod/tags/block/mineable/pickaxe.json  — mark my_block as pickaxe-mineable
{
  "replace": false,
  "values": ["mymod:my_block"]
}

// data/mymod/tags/block/needs_iron_tool.json  — require iron tier
{
  "replace": false,
  "values": ["mymod:my_block"]
}

// data/mymod/tags/item/my_material.json  — custom item tag
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
        uses: gradle/actions/setup-gradle@v3
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
