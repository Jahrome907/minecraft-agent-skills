# Fabric API Patterns (1.21.x)

Reference for Fabric-specific code patterns. Fabric is a lightweight, stable
modding platform focused on clean hooks and fast updates. Targets Minecraft 1.21.x with Java 21.

---

## Mod Entry Point

```java
// MyMod.java — registered as "main" entrypoint in fabric.mod.json
public class MyMod implements ModInitializer {
    public static final String MOD_ID = "mymod";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    @Override
    public void onInitialize() {
        // Runs on both client and server after mod loading
        ModBlocks.register();
        ModItems.register();
        ModBlockEntities.register();
    }
}

// MyModClient.java — registered as "client" entrypoint
@Environment(EnvType.CLIENT)
public class MyModClient implements ClientModInitializer {
    @Override
    public void onInitializeClient() {
        // Client-only setup: renderers, screens, keybinds
        BlockEntityRendererFactories.register(ModBlockEntities.MY_BLOCK_ENTITY,
            MyBlockEntityRenderer::new);
        HandledScreens.register(ModMenuTypes.MY_MENU, MyScreen::new);
    }
}
```

---

## fabric.mod.json

```json
{
  "schemaVersion": 1,
  "id": "mymod",
  "version": "${version}",
  "name": "My Mod",
  "description": "A cool Minecraft mod.",
  "authors": ["YourName"],
  "contact": {
    "sources": "https://github.com/yourname/mymod",
    "issues": "https://github.com/yourname/mymod/issues"
  },
  "license": "MIT",
  "icon": "assets/mymod/icon.png",
  "environment": "*",
  "entrypoints": {
    "main": ["com.example.mymod.MyMod"],
    "client": ["com.example.mymod.client.MyModClient"]
  },
  "mixins": ["mymod.mixins.json"],
  "depends": {
    "fabricloader": ">=0.15.0",
    "fabric-api": "*",
    "minecraft": "~1.21"
  }
}
```

---

## Block & Item Registration

```java
// ModBlocks.java
public class ModBlocks {
    public static final Block MY_BLOCK = new Block(
        AbstractBlock.Settings.create()
            .mapColor(MapColor.STONE)
            .strength(1.5f, 6.0f)
            .sounds(BlockSoundGroup.STONE)
            .requiresTool()
    );

    public static final Block MY_LOG = new PillarBlock(
        AbstractBlock.Settings.copyOf(Blocks.OAK_LOG).mapColor(MapColor.RED)
    );

    public static void register() {
        Registry.register(Registries.BLOCK,
            Identifier.of(MyMod.MOD_ID, "my_block"), MY_BLOCK);
        Registry.register(Registries.BLOCK,
            Identifier.of(MyMod.MOD_ID, "my_log"), MY_LOG);
    }
}

// ModItems.java
public class ModItems {
    public static final Item MY_ITEM = new Item(
        new Item.Settings().maxCount(16)
    );

    // BlockItem for a block
    public static final Item MY_BLOCK_ITEM = new BlockItem(
        ModBlocks.MY_BLOCK, new Item.Settings()
    );

    public static void register() {
        Registry.register(Registries.ITEM,
            Identifier.of(MyMod.MOD_ID, "my_item"), MY_ITEM);
        Registry.register(Registries.ITEM,
            Identifier.of(MyMod.MOD_ID, "my_block"), MY_BLOCK_ITEM);

        // Add to creative tab
        ItemGroupEvents.modifyEntriesEvent(ItemGroups.BUILDING_BLOCKS)
            .register(content -> content.add(MY_BLOCK_ITEM));
    }
}
```

---

## Block Entity

```java
// MyBlockEntity.java
public class MyBlockEntity extends BlockEntity {
    private final DefaultedList<ItemStack> inventory =
        DefaultedList.ofSize(9, ItemStack.EMPTY);

    public MyBlockEntity(BlockPos pos, BlockState state) {
        super(ModBlockEntities.MY_BLOCK_ENTITY, pos, state);
    }

    @Override
    protected void writeNbt(NbtCompound nbt, RegistryWrapper.WrapperLookup registries) {
        super.writeNbt(nbt, registries);
        Inventories.writeNbt(nbt, inventory, registries);
    }

    @Override
    public void readNbt(NbtCompound nbt, RegistryWrapper.WrapperLookup registries) {
        super.readNbt(nbt, registries);
        Inventories.readNbt(nbt, inventory, registries);
    }
}

// ModBlockEntities.java
public class ModBlockEntities {
    public static final BlockEntityType<MyBlockEntity> MY_BLOCK_ENTITY =
        BlockEntityType.Builder.create(MyBlockEntity::new, ModBlocks.MY_BLOCK).build();

    public static void register() {
        Registry.register(Registries.BLOCK_ENTITY_TYPE,
            Identifier.of(MyMod.MOD_ID, "my_block_entity"), MY_BLOCK_ENTITY);
    }
}
```

---

## Mixins

Mixins patch Minecraft classes without modifying them. Use sparingly — prefer Fabric API hooks.

```java
// mixin/MixinServerPlayer.java
@Mixin(ServerPlayerEntity.class)
public abstract class MixinServerPlayer {

    // @Inject — add code at a specific point
    @Inject(method = "tick", at = @At("HEAD"))
    private void onTickHead(CallbackInfo ci) {
        ServerPlayerEntity self = (ServerPlayerEntity)(Object) this;
        // runs at the beginning of ServerPlayerEntity.tick()
    }

    // @Overwrite — replace a method entirely (avoid if possible; breaks compat)
    // @ModifyVariable — modify a local variable
    // @Redirect — redirect a method call within a method

    // @Shadow — access a field or method from the target class
    @Shadow public abstract ServerWorld getServerWorld();
}
```

Mixin config file (`mymod.mixins.json`):

```json
{
  "required": true,
  "minVersion": "0.8",
  "package": "com.example.mymod.mixin",
  "compatibilityLevel": "JAVA_21",
  "mixins": [],
  "client": ["MixinServerPlayer"],
  "server": [],
  "injectors": {
    "defaultRequire": 1
  }
}
```

---

## Fabric Events

Fabric API provides stable event hooks. Prefer these over Mixins.

```java
// Register event callbacks in onInitialize()
ServerTickEvents.END_SERVER_TICK.register(server -> {
    // runs at end of every server tick
});

ServerLifecycleEvents.SERVER_STARTED.register(server -> {
    MyMod.LOGGER.info("Server started!");
});

UseBlockCallback.EVENT.register((player, world, hand, hitResult) -> {
    // return ActionResult.PASS to not consume the event
    return ActionResult.PASS;
});

AttackEntityCallback.EVENT.register((player, world, hand, entity, hitResult) -> {
    return ActionResult.PASS;
});

// Item use callback
UseItemCallback.EVENT.register((player, world, hand) -> {
    ItemStack stack = player.getStackInHand(hand);
    return TypedActionResult.pass(stack);
});
```

---

## Networking (Fabric 1.21 — ServerPlayNetworking)

```java
// Define a payload record
public record MyPayload(int data) implements CustomPayload {
    public static final CustomPayload.Id<MyPayload> ID =
        new CustomPayload.Id<>(Identifier.of(MyMod.MOD_ID, "my_payload"));
    public static final PacketCodec<PacketByteBuf, MyPayload> CODEC =
        PacketCodec.tuple(PacketCodecs.INTEGER, MyPayload::data, MyPayload::new);

    @Override
    public CustomPayload.Id<? extends CustomPayload> getId() { return ID; }
}

// Server-side: register receiver
ServerPlayNetworking.registerGlobalReceiver(MyPayload.ID,
    (payload, context) -> {
        context.server().execute(() -> {
            ServerPlayerEntity player = context.player();
            // handle payload
        });
    });

// Send from server to client
ServerPlayNetworking.send(serverPlayerEntity, new MyPayload(42));

// Client-side: register receiver
ClientPlayNetworking.registerGlobalReceiver(MyPayload.ID,
    (payload, context) -> {
        context.client().execute(() -> {
            // handle on client
        });
    });

// Send from client to server
ClientPlayNetworking.send(new MyPayload(42));
```

---

## Commands (Fabric)

```java
// Register commands via CommandRegistrationCallback
CommandRegistrationCallback.EVENT.register((dispatcher, registryAccess, environment) -> {
    dispatcher.register(
        CommandManager.literal("mycommand")
            .requires(source -> source.hasPermissionLevel(2))
            .then(CommandManager.argument("target", EntityArgumentType.player())
                .executes(ctx -> {
                    ServerPlayerEntity player = EntityArgumentType.getPlayer(ctx, "target");
                    ctx.getSource().sendFeedback(
                        () -> Text.literal("Hello, " + player.getName().getString()), false);
                    return 1;
                }))
    );
});
```

---

## Custom Screen / GUI

```java
// MyScreenHandler.java (server + client logic)
public class MyScreenHandler extends ScreenHandler {
    public MyScreenHandler(int syncId, PlayerInventory playerInventory) {
        super(ModMenuTypes.MY_MENU, syncId);
        addPlayerInventory(playerInventory);
        addPlayerHotbar(playerInventory);
    }

    @Override
    public boolean canUse(PlayerEntity player) { return true; }

    private void addPlayerInventory(PlayerInventory playerInventory) {
        for (int row = 0; row < 3; row++)
            for (int col = 0; col < 9; col++)
                addSlot(new Slot(playerInventory, col + row * 9 + 9, 8 + col * 18, 84 + row * 18));
    }

    private void addPlayerHotbar(PlayerInventory playerInventory) {
        for (int col = 0; col < 9; col++)
            addSlot(new Slot(playerInventory, col, 8 + col * 18, 142));
    }
}

// MyScreen.java (@Environment(EnvType.CLIENT))
@Environment(EnvType.CLIENT)
public class MyScreen extends HandledScreen<MyScreenHandler> {
    private static final Identifier TEXTURE =
        Identifier.of(MyMod.MOD_ID, "textures/gui/my_gui.png");

    public MyScreen(MyScreenHandler handler, PlayerInventory inventory, Text title) {
        super(handler, inventory, title);
        backgroundWidth = 176;
        backgroundHeight = 166;
    }

    @Override
    protected void drawBackground(DrawContext context, float delta, int mouseX, int mouseY) {
        context.drawTexture(TEXTURE, x, y, 0, 0, backgroundWidth, backgroundHeight);
    }
}
```

---

## gradle.properties (Fabric Loom template)

```properties
org.gradle.jvmargs=-Xmx2G

minecraft_version=1.21.11
loader_version=0.17.3
fabric_version=0.116.10+1.21.1

# Prefer loom.officialMojangMappings() in shared examples.
# If you want Yarn, resolve the exact 1.21.11 build from https://fabricmc.net/develop/.

mod_version=1.0.0
maven_group=com.example
archives_base_name=mymod
```

---

## Useful Fabric Classes (1.21.x Quick Reference)

|Need|Class|
|---|---|
|Block settings|`AbstractBlock.Settings`|
|Item settings|`Item.Settings`|
|Identifier|`Identifier.of("mymod", "thing")`|
|Map colours|`MapColor.*`|
|Block sounds|`BlockSoundGroup.*`|
|Tool materials|`ToolMaterials.*`|
|Text/chat|`Text.literal("...")`, `Text.translatable("key")`|
|NBT|`NbtCompound`, `NbtList`|
|Inventories util|`Inventories.readNbt`, `Inventories.writeNbt`|
|Registries|`Registries.*`|
|Data pack registry|`RegistryKey.of(RegistryKeys.BIOME, id)`|
|Fabric events|`ServerTickEvents`, `UseBlockCallback`, etc.|
|Item group events|`ItemGroupEvents.modifyEntriesEvent(ItemGroups.*)`|
