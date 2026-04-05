# NeoForge API Patterns (1.21.x)

Reference for NeoForge-specific code patterns. NeoForge is the primary Minecraft modding
platform as of 2025-2026, targeting Minecraft 1.21.x with Java 21.

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

        // Register for in-game events on the GAME event bus (NeoForge 1.20.5+)
        NeoForge.EVENT_BUS.register(this);
        // Prefer @EventBusSubscriber on a separate class over registering `this`
    }

    private void commonSetup(FMLCommonSetupEvent event) {
        event.enqueueWork(() -> {
            // thread-safe registration calls go here, e.g. CompostingChanceRegistry
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
loaderVersion="[21,)"
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
versionRange="[21.1,)"
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
    public static final DeferredRegister<Block> BLOCKS =
        DeferredRegister.create(BuiltInRegistries.BLOCK, MyMod.MOD_ID);

    // Simple full-cube block
    public static final DeferredBlock<Block> MY_BLOCK =
        BLOCKS.registerSimpleBlock("my_block",
            BlockBehaviour.Properties.of()
                .mapColor(MapColor.STONE)
                .instrument(NoteBlockInstrument.BASEDRUM)
                .strength(1.5f, 6.0f)
                .sound(SoundType.STONE)
                .requiresCorrectToolForDrops());

    // Custom block class
    public static final DeferredBlock<MySpecialBlock> SPECIAL_BLOCK =
        BLOCKS.registerBlock("special_block", MySpecialBlock::new,
            BlockBehaviour.Properties.of().strength(2.0f));
}
```

```java
// ModItems.java
public class ModItems {
    public static final DeferredRegister<Item> ITEMS =
        DeferredRegister.create(BuiltInRegistries.ITEM, MyMod.MOD_ID);

    // BlockItem for a block
    public static final DeferredItem<BlockItem> MY_BLOCK_ITEM =
        ITEMS.registerSimpleBlockItem(ModBlocks.MY_BLOCK);

    // Simple item
    public static final DeferredItem<Item> MY_ITEM =
        ITEMS.registerSimpleItem("my_item", new Item.Properties().stacksTo(16));

    // Custom item class
    public static final DeferredItem<MySword> MY_SWORD =
        ITEMS.registerItem("my_sword", props ->
            new MySword(Tiers.IRON, new Item.Properties()
                .attributes(SwordItem.createAttributes(Tiers.IRON, 3, -2.4f))));
}
```

---

## Block Entity (Tile Entity)

```java
// MyBlockEntity.java
public class MyBlockEntity extends BlockEntity {
    private final ItemStackHandler inventory = new ItemStackHandler(9);

    public MyBlockEntity(BlockPos pos, BlockState state) {
        super(ModBlockEntities.MY_BLOCK_ENTITY.get(), pos, state);
    }

    @Override
    protected void saveAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.saveAdditional(tag, registries);
        tag.put("inventory", inventory.serializeNBT(registries));
    }

    @Override
    public void loadAdditional(CompoundTag tag, HolderLookup.Provider registries) {
        super.loadAdditional(tag, registries);
        inventory.deserializeNBT(registries, tag.getCompound("inventory"));
    }
}

// ModBlockEntities.java
public class ModBlockEntities {
    public static final DeferredRegister<BlockEntityType<?>> BLOCK_ENTITIES =
        DeferredRegister.create(BuiltInRegistries.BLOCK_ENTITY_TYPE, MyMod.MOD_ID);

    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<MyBlockEntity>>
        MY_BLOCK_ENTITY = BLOCK_ENTITIES.register("my_block_entity",
            () -> BlockEntityType.Builder
                .of(MyBlockEntity::new, ModBlocks.MY_BLOCK.get())
                .build(null));
}
```

---

## Event Bus System

NeoForge has two event buses:

- **MOD bus** (`IEventBus` injected into constructor): lifecycle events, registration events
- **GAME bus** (`NeoForge.EVENT_BUS`): in-game events  
  Import: `net.neoforged.neoforge.common.NeoForge`  
  (`MinecraftForge.EVENT_BUS` was removed in NeoForge 1.20.5)

```java
// Recommended: separate class with @EventBusSubscriber
@EventBusSubscriber(modid = MyMod.MOD_ID, bus = Bus.MOD)
public class ModEvents {
    @SubscribeEvent
    public static void onRegisterEntityRenderers(EntityRenderersEvent.RegisterRenderers event) {
        event.registerEntityRenderer(ModEntityTypes.MY_ENTITY.get(), MyEntityRenderer::new);
    }

    @SubscribeEvent
    public static void gatherData(GatherDataEvent event) {
        DataGenerator gen = event.getGenerator();
        PackOutput output = gen.getPackOutput();
        ExistingFileHelper helper = event.getExistingFileHelper();
        CompletableFuture<HolderLookup.Provider> lookupProvider = event.getLookupProvider();

        gen.addProvider(event.includeClient(),
            new ModBlockStateProvider(output, helper));
        gen.addProvider(event.includeClient(),
            new ModItemModelProvider(output, helper));
        gen.addProvider(event.includeServer(),
            new ModRecipeProvider(output, lookupProvider));
        gen.addProvider(event.includeServer(),
            new ModLootTableProvider(output, lookupProvider));
        gen.addProvider(event.includeServer(),
            new ModBlockTagsProvider(output, lookupProvider, helper));
    }
}

@EventBusSubscriber(modid = MyMod.MOD_ID, bus = Bus.GAME)
public class GameEvents {
    @SubscribeEvent
    public static void onPlayerTick(PlayerTickEvent.Post event) {
        // runs every tick for every player
    }

    @SubscribeEvent
    public static void onLivingHurt(LivingIncomingDamageEvent event) {
        // fires when an entity is about to take damage; cancellable
    }
}
```

---

## Menu / GUI (Container)

```java
// MyMenu.java (server + client)
public class MyMenu extends AbstractContainerMenu {
    private final ContainerLevelAccess access;

    public MyMenu(int containerId, Inventory playerInventory) {
        this(containerId, playerInventory, ContainerLevelAccess.NULL);
    }

    public MyMenu(int containerId, Inventory playerInventory, ContainerLevelAccess access) {
        super(ModMenuTypes.MY_MENU.get(), containerId);
        this.access = access;
        addPlayerInventory(playerInventory);
        addPlayerHotbar(playerInventory);
    }

    @Override
    public boolean stillValid(Player player) {
        return access.evaluate(
            (level, pos) -> player.distanceToSqr(pos.getX() + 0.5, pos.getY() + 0.5,
                pos.getZ() + 0.5) < 64, true);
    }
}

// MyScreen.java (@OnlyIn(Dist.CLIENT))
@OnlyIn(Dist.CLIENT)
public class MyScreen extends AbstractContainerScreen<MyMenu> {
    private static final ResourceLocation TEXTURE =
        ResourceLocation.fromNamespaceAndPath(MyMod.MOD_ID, "textures/gui/my_gui.png");

    public MyScreen(MyMenu menu, Inventory playerInventory, Component title) {
        super(menu, playerInventory, title);
        this.imageWidth = 176;
        this.imageHeight = 166;
    }

    @Override
    protected void renderBg(GuiGraphics graphics, float partialTick, int mouseX, int mouseY) {
        graphics.blit(TEXTURE, leftPos, topPos, 0, 0, imageWidth, imageHeight);
    }
}

// Register on MOD bus (client-only):
@EventBusSubscriber(modid = MyMod.MOD_ID, bus = Bus.MOD, value = Dist.CLIENT)
public class ClientModEvents {
    @SubscribeEvent
    public static void registerScreens(RegisterMenuScreensEvent event) {
        event.register(ModMenuTypes.MY_MENU.get(), MyScreen::new);
    }
}
```

---

## Capabilities (NeoForge Capability System)

```java
// Attach a capability to a player entity
@EventBusSubscriber(modid = MyMod.MOD_ID, bus = Bus.GAME)
public class CapabilityEvents {
    @SubscribeEvent
    public static void attachCapabilities(AttachCapabilitiesEvent<Entity> event) {
        if (event.getObject() instanceof Player player) {
            // Attach once; NeoForge will retain capability data on the provider.
            event.addCapability(
                ResourceLocation.fromNamespaceAndPath(MyMod.MOD_ID, "my_cap"),
                new MyCapProvider());
        }
    }
}

// Access a capability
entity.getCapability(MyCapProvider.MY_CAP).ifPresent(cap -> {
    cap.doSomething();
});
```

---

## Network Packets (1.21 SimpleChannel)

```java
// Register a payload (packet) type
public record MyPayload(int value) implements CustomPacketPayload {
    public static final Type<MyPayload> TYPE =
        new Type<>(ResourceLocation.fromNamespaceAndPath(MyMod.MOD_ID, "my_payload"));

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

```json
// data/mymod/neoforge/biome_modifier/add_spawn.json
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
|Tool tiers|`Tiers.*` (WOOD, STONE, IRON, DIAMOND, NETHERITE)|
|Rarity|`Rarity.*` (COMMON, UNCOMMON, RARE, EPIC)|
|Block tags|`BlockTags.*`|
|Item tags|`ItemTags.*`|
|Entity categories|`MobCategory.*`|
|Directions|`Direction.*`|
|Block positions|`BlockPos`, `BlockPos.MutableBlockPos`|
|Level access|`Level`, `ServerLevel`|
|Registry access|`BuiltInRegistries.*`, `Registries.*`|
