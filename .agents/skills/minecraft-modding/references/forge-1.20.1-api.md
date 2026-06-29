# Forge 1.20.1 API Patterns

Use this reference only for Minecraft `1.20.1` projects using MinecraftForge
`47.4.x` and Java 17. Do not apply these snippets to NeoForge 1.21.x projects.
Forge 1.20.1 and NeoForge 1.21.x share some concepts, but the package names,
metadata file, event bus access, helper classes, and several data paths differ.

## Project Detection

A Forge 1.20.1 project usually has these signatures:

```text
build.gradle: id 'net.minecraftforge.gradle' version '[6.0,6.2)'
gradle.properties: minecraft_version=1.20.1
gradle.properties: forge_version=47.4.20
src/main/resources/META-INF/mods.toml
```

Use Java 17 for Forge 1.20.1. The official MDK template sets:

```gradle
java.toolchain.languageVersion = JavaLanguageVersion.of(17)
```

## Gradle Properties

```properties
org.gradle.jvmargs=-Xmx3G
org.gradle.daemon=false

minecraft_version=1.20.1
minecraft_version_range=[1.20.1,1.21)
forge_version=47.4.20
forge_version_range=[47,)
loader_version_range=[47,)
mapping_channel=official
mapping_version=1.20.1

mod_id=mymod
mod_name=My Mod
mod_license=MIT
mod_version=1.0.0
mod_group_id=com.example.mymod
mod_authors=YourName
mod_description=A Forge 1.20.1 mod.
```

Use the current Forge 1.20.1 `47.4.x` patch from the Forge files page when
scaffolding a new project. Keep `minecraft_version` and the left side of the
Forge artifact coordinate paired as `1.20.1-${forge_version}`.

## build.gradle Essentials

```gradle
plugins {
    id 'eclipse'
    id 'idea'
    id 'maven-publish'
    id 'net.minecraftforge.gradle' version '[6.0,6.2)'
}

version = mod_version
group = mod_group_id

base {
    archivesName = mod_id
}

java.toolchain.languageVersion = JavaLanguageVersion.of(17)

minecraft {
    mappings channel: mapping_channel, version: mapping_version
    copyIdeResources = true

    runs {
        configureEach {
            workingDirectory project.file('run')
            property 'forge.logging.markers', 'REGISTRIES'
            property 'forge.logging.console.level', 'debug'
            mods {
                "${mod_id}" {
                    source sourceSets.main
                }
            }
        }

        client {
            property 'forge.enabledGameTestNamespaces', mod_id
        }

        server {
            property 'forge.enabledGameTestNamespaces', mod_id
            args '--nogui'
        }

        data {
            workingDirectory project.file('run-data')
            args '--mod', mod_id, '--all', '--output', file('src/generated/resources/'),
                '--existing', file('src/main/resources/')
        }
    }
}

sourceSets.main.resources { srcDir 'src/generated/resources' }

dependencies {
    minecraft "net.minecraftforge:forge:${minecraft_version}-${forge_version}"
}
```

## mods.toml

Forge 1.20.1 uses `src/main/resources/META-INF/mods.toml`, not
`neoforge.mods.toml`.

```toml
modLoader="javafml"
loaderVersion="${loader_version_range}"
license="${mod_license}"

[[mods]]
modId="${mod_id}"
version="${mod_version}"
displayName="${mod_name}"
authors="${mod_authors}"
description='''${mod_description}'''

[[dependencies.${mod_id}]]
modId="forge"
mandatory=true
versionRange="${forge_version_range}"
ordering="NONE"
side="BOTH"

[[dependencies.${mod_id}]]
modId="minecraft"
mandatory=true
versionRange="${minecraft_version_range}"
ordering="NONE"
side="BOTH"
```

## Entry Point And Event Buses

Forge 1.20.1 uses `net.minecraftforge.*` imports. The mod event bus comes from
`FMLJavaModLoadingContext`, and gameplay events use `MinecraftForge.EVENT_BUS`.

```java
@Mod(MyMod.MOD_ID)
public class MyMod {
    public static final String MOD_ID = "mymod";
    private static final Logger LOGGER = LogUtils.getLogger();

    public MyMod(FMLJavaModLoadingContext context) {
        IEventBus modEventBus = context.getModEventBus();

        ModBlocks.BLOCKS.register(modEventBus);
        ModItems.ITEMS.register(modEventBus);
        ModCreativeTabs.CREATIVE_MODE_TABS.register(modEventBus);

        modEventBus.addListener(this::commonSetup);
        modEventBus.addListener(this::addCreative);
        MinecraftForge.EVENT_BUS.register(this);
    }

    private void commonSetup(FMLCommonSetupEvent event) {
        LOGGER.info("Common setup for {}", MOD_ID);
    }

    private void addCreative(BuildCreativeModeTabContentsEvent event) {
        if (event.getTabKey() == CreativeModeTabs.BUILDING_BLOCKS) {
            event.accept(ModItems.MY_BLOCK_ITEM);
        }
    }

    @SubscribeEvent
    public void onServerStarting(ServerStartingEvent event) {
        LOGGER.info("Server starting");
    }
}
```

## DeferredRegister

Forge 1.20.1 uses `ForgeRegistries` and `RegistryObject`.

```java
public final class ModBlocks {
    public static final DeferredRegister<Block> BLOCKS =
        DeferredRegister.create(ForgeRegistries.BLOCKS, MyMod.MOD_ID);

    public static final RegistryObject<Block> MY_BLOCK = BLOCKS.register(
        "my_block",
        () -> new Block(BlockBehaviour.Properties.of()
            .mapColor(MapColor.STONE)
            .strength(1.5f, 6.0f)
            .sound(SoundType.STONE)
            .requiresCorrectToolForDrops())
    );

    private ModBlocks() {
    }
}
```

```java
public final class ModItems {
    public static final DeferredRegister<Item> ITEMS =
        DeferredRegister.create(ForgeRegistries.ITEMS, MyMod.MOD_ID);

    public static final RegistryObject<Item> MY_BLOCK_ITEM = ITEMS.register(
        "my_block",
        () -> new BlockItem(ModBlocks.MY_BLOCK.get(), new Item.Properties())
    );

    public static final RegistryObject<Item> MY_ITEM = ITEMS.register(
        "my_item",
        () -> new Item(new Item.Properties())
    );

    private ModItems() {
    }
}
```

For vanilla registries not wrapped by `ForgeRegistries`, use the matching
`net.minecraft.core.registries.Registries` key with `DeferredRegister.create`.
Creative mode tabs in the official MDK use this pattern.

```java
public static final DeferredRegister<CreativeModeTab> CREATIVE_MODE_TABS =
    DeferredRegister.create(Registries.CREATIVE_MODE_TAB, MyMod.MOD_ID);
```

## ResourceLocation

Forge 1.20.1 uses the public constructors available in Minecraft 1.20.1.
Do not use NeoForge 1.21.x helpers such as `ResourceLocation.fromNamespaceAndPath`.

```java
ResourceLocation id = new ResourceLocation(MyMod.MOD_ID, "my_block");
```

## Networking

Forge 1.20.1 uses `SimpleChannel` with `NetworkRegistry.newSimpleChannel`.
Register packets with stable integer discriminators and always mark packets as
handled after scheduling work.

```java
public final class ModNetworking {
    private static final String PROTOCOL_VERSION = "1";

    public static final SimpleChannel CHANNEL = NetworkRegistry.newSimpleChannel(
        new ResourceLocation(MyMod.MOD_ID, "main"),
        () -> PROTOCOL_VERSION,
        PROTOCOL_VERSION::equals,
        PROTOCOL_VERSION::equals
    );

    public static void register() {
        int id = 0;
        CHANNEL.registerMessage(
            id++,
            SyncEnergyPacket.class,
            SyncEnergyPacket::encode,
            SyncEnergyPacket::decode,
            SyncEnergyPacket::handle
        );
    }

    private ModNetworking() {
    }
}
```

```java
public record SyncEnergyPacket(BlockPos pos, int energy) {
    public static void encode(SyncEnergyPacket packet, FriendlyByteBuf buffer) {
        buffer.writeBlockPos(packet.pos());
        buffer.writeInt(packet.energy());
    }

    public static SyncEnergyPacket decode(FriendlyByteBuf buffer) {
        return new SyncEnergyPacket(buffer.readBlockPos(), buffer.readInt());
    }

    public static void handle(SyncEnergyPacket packet, Supplier<NetworkEvent.Context> context) {
        NetworkEvent.Context ctx = context.get();
        ctx.enqueueWork(() -> {
            ServerPlayer sender = ctx.getSender();
            if (sender == null || !sender.level().hasChunkAt(packet.pos())) {
                return;
            }
            // Handle trusted server-side work here.
        });
        ctx.setPacketHandled(true);
    }
}
```

Send packets through the channel and Forge `PacketDistributor` helpers. In Forge
`47.4.x`, `PacketDistributor<T>.with` takes the target object directly; for
`PLAYER`, pass the `ServerPlayer`, not a `Supplier<ServerPlayer>`.

```java
ModNetworking.CHANNEL.send(PacketDistributor.PLAYER.with(serverPlayer), packet);
ModNetworking.CHANNEL.sendToServer(packet);
```

## Data Generation And Paths

Run Forge 1.20.1 data generation with `./gradlew runData`. The generated output
is normally wired from `src/generated/resources` into `sourceSets.main.resources`.
Register data providers on the mod event bus; Forge fires `GatherDataEvent` there
when the data generator starts.

```java
public MyMod(FMLJavaModLoadingContext context) {
    IEventBus modEventBus = context.getModEventBus();
    modEventBus.addListener(ModDataGen::gatherData);
}
```

Use Forge 1.20.1 provider classes and constructors rather than NeoForge 1.21.x
examples. `ExistingFileHelper` comes from the event and validates referenced
assets such as textures and parent models.

```java
public final class ModDataGen {
    public static void gatherData(GatherDataEvent event) {
        DataGenerator generator = event.getGenerator();
        PackOutput output = generator.getPackOutput();
        ExistingFileHelper existingFileHelper = event.getExistingFileHelper();
        CompletableFuture<HolderLookup.Provider> lookupProvider = event.getLookupProvider();

        generator.addProvider(event.includeClient(), new ModBlockStateProvider(output, existingFileHelper));
        generator.addProvider(event.includeClient(), new ModItemModelProvider(output, existingFileHelper));
        generator.addProvider(event.includeServer(), new ModRecipeProvider(output));

        ModBlockTagsProvider blockTags = new ModBlockTagsProvider(output, lookupProvider, existingFileHelper);
        generator.addProvider(event.includeServer(), blockTags);
        generator.addProvider(event.includeServer(), new ModItemTagsProvider(
            output,
            lookupProvider,
            blockTags.contentsGetter(),
            existingFileHelper
        ));
    }

    private ModDataGen() {
    }
}
```

Common Forge 1.20.1 provider constructors look like this:

```java
public final class ModBlockStateProvider extends BlockStateProvider {
    public ModBlockStateProvider(PackOutput output, ExistingFileHelper existingFileHelper) {
        super(output, MyMod.MOD_ID, existingFileHelper);
    }

    @Override
    protected void registerStatesAndModels() {
        // Generate blockstates, block models, and simple block item models here.
    }
}
```

```java
public final class ModItemModelProvider extends ItemModelProvider {
    public ModItemModelProvider(PackOutput output, ExistingFileHelper existingFileHelper) {
        super(output, MyMod.MOD_ID, existingFileHelper);
    }

    @Override
    protected void registerModels() {
        // Generate standalone item models here.
    }
}
```

```java
public final class ModRecipeProvider extends RecipeProvider {
    public ModRecipeProvider(PackOutput output) {
        super(output);
    }

    @Override
    protected void buildRecipes(Consumer<FinishedRecipe> consumer) {
        // Generate recipes here.
    }
}
```

```java
public final class ModBlockTagsProvider extends BlockTagsProvider {
    public ModBlockTagsProvider(
        PackOutput output,
        CompletableFuture<HolderLookup.Provider> lookupProvider,
        ExistingFileHelper existingFileHelper
    ) {
        super(output, lookupProvider, MyMod.MOD_ID, existingFileHelper);
    }

    @Override
    protected void addTags(HolderLookup.Provider provider) {
        // Generate block tags here.
    }
}
```

```java
public final class ModItemTagsProvider extends ItemTagsProvider {
    public ModItemTagsProvider(
        PackOutput output,
        CompletableFuture<HolderLookup.Provider> lookupProvider,
        CompletableFuture<TagsProvider.TagLookup<Block>> blockTags,
        ExistingFileHelper existingFileHelper
    ) {
        super(output, lookupProvider, blockTags, MyMod.MOD_ID, existingFileHelper);
    }

    @Override
    protected void addTags(HolderLookup.Provider provider) {
        // Generate item tags here.
    }
}
```

Minecraft 1.20.1 uses the older server-data path names:

```text
data/<modid>/loot_tables/blocks/<block>.json
data/<modid>/tags/blocks/<tag>.json
data/<modid>/tags/items/<tag>.json
```

Do not rewrite these to the 1.21.x singular path names when editing a Forge
1.20.1 project. Conversely, do not copy these legacy paths into 1.21.x projects.

## Common Porting Mistakes

| Mistake | Forge 1.20.1 fix |
|---|---|
| Using `net.neoforged.*` imports | Use `net.minecraftforge.*` imports |
| Creating `META-INF/neoforge.mods.toml` | Use `META-INF/mods.toml` |
| Injecting `IEventBus` into the mod constructor | Accept `FMLJavaModLoadingContext context` and call `context.getModEventBus()` |
| Using `DeferredBlock` / `DeferredItem` | Use `RegistryObject<T>` |
| Using `BuiltInRegistries.BLOCK` with Forge deferred registers | Use `ForgeRegistries.BLOCKS` |
| Using `ResourceLocation.fromNamespaceAndPath` | Use `new ResourceLocation(namespace, path)` |
| Assuming Java 21 | Use Java 17 for Minecraft 1.20.1 |
