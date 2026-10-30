# NeoForge API Patterns (1.21.11)

Legacy NeoForge-specific code patterns for Minecraft 1.21.11 with Java 21.
Use the exact project's versioned documentation for current 26.x / Java 25 work.

---

## Mod Entry Point

```java
// MyMod.java
@Mod(MyMod.MOD_ID)
public class MyMod {
    public static final String MOD_ID = "mymod";
    public static final Logger LOGGER = LogUtils.getLogger();

    public MyMod(IEventBus modEventBus) {
        // Register deferred registers with the mod event bus
        ModBlocks.BLOCKS.register(modEventBus);
        ModItems.ITEMS.register(modEventBus);
        ModBlockEntities.BLOCK_ENTITIES.register(modEventBus);
        ModMenuTypes.MENUS.register(modEventBus);
        ModEntityTypes.ENTITY_TYPES.register(modEventBus);
        ModSounds.SOUNDS.register(modEventBus);

        // Register mod event listeners
        modEventBus.addListener(this::commonSetup);
        modEventBus.addListener(this::addCreativeTabItems);
    }

    private void commonSetup(FMLCommonSetupEvent event) {
        event.enqueueWork(() -> {
            // Main-thread setup that cannot run in parallel goes here.
        });
    }

    private void addCreativeTabItems(BuildCreativeModeTabContentsEvent event) {
        if (event.getTabKey() == CreativeModeTabs.BUILDING_BLOCKS) {
            event.accept(ModItems.MY_ITEM);
        }
    }
}
```

---

## neoforge.mods.toml (META-INF/neoforge.mods.toml)

> File renamed from `mods.toml` to `neoforge.mods.toml` in NeoForge 1.20.5+.
> Always use `neoforge.mods.toml` for 1.21.x projects.

```toml
modLoader="javafml"
loaderVersion="[1,)"
license="MIT"

[[mods]]
modId="mymod"
version="${file.jarVersion}"
displayName="My Mod"
description='''
A brief description of what my mod does.
'''
logoFile="mymod.png"

[[dependencies.mymod]]
modId="neoforge"
type="required"
versionRange="[21.11,)"
ordering="NONE"
side="BOTH"

[[dependencies.mymod]]
modId="minecraft"
type="required"
versionRange="[1.21.11,1.22)"
ordering="NONE"
side="BOTH"
```

---

## DeferredRegister Patterns

```java
// ModBlocks.java
public class ModBlocks {
    public static final DeferredRegister.Blocks BLOCKS =
        DeferredRegister.createBlocks(MyMod.MOD_ID);

    // Simple full-cube block
    public static final DeferredBlock<Block> MY_BLOCK =
        BLOCKS.registerSimpleBlock("my_block", () ->
            BlockBehaviour.Properties.of()
                .mapColor(MapColor.STONE)
                .instrument(NoteBlockInstrument.BASEDRUM)
                .strength(1.5f, 6.0f)
                .sound(SoundType.STONE)
                .requiresCorrectToolForDrops());

    // Custom block class
    public static final DeferredBlock<MySpecialBlock> SPECIAL_BLOCK =
        BLOCKS.registerBlock("special_block", MySpecialBlock::new,
            () -> BlockBehaviour.Properties.of().strength(2.0f));
}
```

```java
// ModItems.java
public class ModItems {
    public static final DeferredRegister.Items ITEMS =
        DeferredRegister.createItems(MyMod.MOD_ID);

    // BlockItem for a block
    public static final DeferredItem<BlockItem> MY_BLOCK_ITEM =
        ITEMS.registerSimpleBlockItem(ModBlocks.MY_BLOCK);

    // Simple item
    public static final DeferredItem<Item> MY_ITEM =
        ITEMS.registerSimpleItem("my_item", props -> props.stacksTo(16));

    // Custom item class
    public static final DeferredItem<MyCustomItem> MY_CUSTOM_ITEM =
        ITEMS.registerItem("my_custom_item", MyCustomItem::new);
}
```

For 26.x tool and armor APIs, use the explicitly versioned patterns in
`common-patterns.md`; this reference otherwise retains 1.21.x examples.

---

## Block Entity

```java
// MyBlockEntity.java
public class MyBlockEntity extends BlockEntity {
    private int processingTicks;

    public MyBlockEntity(BlockPos pos, BlockState state) {
        super(ModBlockEntities.MY_BLOCK_ENTITY.get(), pos, state);
    }

    @Override
    protected void saveAdditional(ValueOutput output) {
        super.saveAdditional(output);
        output.putInt("processing_ticks", processingTicks);
    }

    @Override
    public void loadAdditional(ValueInput input) {
        super.loadAdditional(input);
        processingTicks = input.getIntOr("processing_ticks", 0);
    }
}

// ModBlockEntities.java
public class ModBlockEntities {
    public static final DeferredRegister<BlockEntityType<?>> BLOCK_ENTITIES =
        DeferredRegister.create(BuiltInRegistries.BLOCK_ENTITY_TYPE, MyMod.MOD_ID);

    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<MyBlockEntity>>
        MY_BLOCK_ENTITY = BLOCK_ENTITIES.register("my_block_entity",
            () -> new BlockEntityType<>(
                MyBlockEntity::new, false, ModBlocks.MY_BLOCK.get()));
}
```

---

## Event buses and data generation (1.21.11)

The injected mod bus handles registration and lifecycle events; the game bus
is `NeoForge.EVENT_BUS`. Use `addListener` on the appropriate bus or
`@EventBusSubscriber`, which selects the bus from the event type in 1.21.11.
The old `bus = Bus.MOD` / `Bus.GAME` annotation argument is obsolete here.
Client renderer handlers need `value = Dist.CLIENT` and a separate client
class so dedicated servers do not load rendering classes. See the
[versioned event guide](https://docs.neoforged.net/docs/1.21.11/concepts/events/).

For datagen, use `GatherDataEvent.Client` or `.Server` and
`event.createProvider(...)`. The current MDK registers both kinds of providers
from `.Client` and runs `runClientData`. Keep the registry lookup, model
provider, and recipe runner wiring from the
[1.21.11 resource guide](https://docs.neoforged.net/docs/1.21.11/resources/);
older `ExistingFileHelper` constructors and `includeClient()` flags do not
belong in this version.

## Menus and screens

Build from the target version's
[menu guide](https://docs.neoforged.net/docs/1.21.11/inventories/menus/). Keep server
slots, client slots, synchronized data, and `quickMoveStack` index ranges
consistent. A block menu's `stillValid` must check the block and player range.
Register its client screen separately; preserve the current rendering API
instead of copying an older `GuiGraphics.blit` overload.

---

## Capabilities (NeoForge 1.21.11)

NeoForge registers providers for concrete block entities, blocks, entity types, or
items on the mod event bus. Its capability lookup returns the implementation or
`null`. Do not use Forge's `AttachCapabilitiesEvent`, `ICapabilityProvider`, or
`LazyOptional` patterns in a NeoForge 1.21.11 project.

```java
@EventBusSubscriber(modid = MyMod.MOD_ID)
public final class ModCapabilities {
    @SubscribeEvent
    public static void registerCapabilities(RegisterCapabilitiesEvent event) {
        event.registerBlockEntity(
            Capabilities.Item.BLOCK,
            ModBlockEntities.MY_BLOCK_ENTITY.get(),
            (blockEntity, side) -> blockEntity.getItemHandler(side)
        );
    }
}

// Query from a level. A null result means this side has no item handler.
ResourceHandler<ItemResource> handler =
    level.getCapability(Capabilities.Item.BLOCK, pos, Direction.NORTH);
if (handler != null) {
    // Use handler.
}
```

For a custom capability, create a static `BlockCapability`, `EntityCapability`,
or `ItemCapability` and register its provider with the same event. See the
[NeoForge 1.21.11 capability guide](https://docs.neoforged.net/docs/1.21.11/inventories/capabilities/).

---

## Network payloads (1.21.11)

```java
// Register a payload (packet) type
public record MyPayload(int value) implements CustomPacketPayload {
    public static final Type<MyPayload> TYPE =
        new Type<>(Identifier.fromNamespaceAndPath(MyMod.MOD_ID, "my_payload"));

    public static final StreamCodec<ByteBuf, MyPayload> STREAM_CODEC =
        StreamCodec.composite(ByteBufCodecs.INT, MyPayload::value, MyPayload::new);

    @Override
    public Type<? extends CustomPacketPayload> type() { return TYPE; }
}

// Register on MOD bus
@SubscribeEvent
public static void registerPayloads(RegisterPayloadHandlersEvent event) {
    PayloadRegistrar registrar = event.registrar("1");
    registrar.playToClient(MyPayload.TYPE, MyPayload.STREAM_CODEC,
        (payload, ctx) -> {
            // handle on client — ctx.enqueueWork() for thread safety
            ctx.enqueueWork(() -> handleOnClient(payload));
        });
    registrar.playToServer(MyPayload.TYPE, MyPayload.STREAM_CODEC,
        (payload, ctx) -> ctx.enqueueWork(() -> handleOnServer(payload, ctx.player())));
}

// Send from server to client
PacketDistributor.sendToPlayer(serverPlayer, new MyPayload(42));

// Send from client to server
PacketDistributor.sendToServer(new MyPayload(42));
```

---

## Biome Modifier (World Gen Integration)

`data/mymod/neoforge/biome_modifier/add_spawn.json`:
```json
{
  "type": "neoforge:add_spawns",
  "biomes": "#minecraft:is_overworld",
  "spawners": [
    {
      "type": "mymod:my_entity",
      "weight": 10,
      "minCount": 2,
      "maxCount": 4
    }
  ]
}
```

---

## gradle.properties (NeoForge MDK template)

```properties
org.gradle.jvmargs=-Xmx3G
org.gradle.daemon=false

minecraft_version=1.21.11
minecraft_version_range=[1.21.11,1.22)
neo_version=21.11.42
neo_version_range=[21.11,)
loader_version_range=[1,)

mod_id=mymod
mod_name=My Mod
mod_license=MIT
mod_version=1.0.0
mod_group_id=com.example.mymod
mod_authors=YourName
mod_description=A cool Minecraft mod.

## Dependencies (optional)
# patchouli_version=...
```

---

## Useful NeoForge Classes (1.21.x Quick Reference)

|Need|Class|
|---|---|
|Block properties|`BlockBehaviour.Properties`|
|Item properties|`Item.Properties`|
|Map colours|`MapColor.*`|
|Block sounds|`SoundType.*`|
|Tool materials|`ToolMaterial.*`|
|Rarity|`Rarity.*` (COMMON, UNCOMMON, RARE, EPIC)|
|Block tags|`BlockTags.*`|
|Item tags|`ItemTags.*`|
|Entity categories|`MobCategory.*`|
|Directions|`Direction.*`|
|Block positions|`BlockPos`, `BlockPos.MutableBlockPos`|
|Level access|`Level`, `ServerLevel`|
|Registry access|`BuiltInRegistries.*`, `Registries.*`|
