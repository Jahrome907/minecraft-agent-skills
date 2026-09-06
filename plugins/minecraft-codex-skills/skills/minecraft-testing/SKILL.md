---
name: minecraft-testing
description: "Design and implement automated tests for current Minecraft 26.x or legacy 1.21.x mods and plugins using JUnit, MockBukkit, NeoForge Game Tests, or Fabric Game Tests. Use for test code and test execution, not release publishing or gameplay implementation."
---

# Minecraft Testing Skill

## Testing Strategies Overview

| Approach | Best For | Requires Game? |
|----------|---------|----------------|
| **JUnit 5** (pure unit tests) | Logic, data structures, NBT serialization | No |
| **MockBukkit** | Bukkit/Paper plugin events, commands, inventory | No (mocked server) |
| **NeoForge GameTests** | In-game block/entity/world interaction | Yes (test environment) |
| **Fabric GameTests** | In-game block/entity/world interaction | Yes (test environment) |
| **Integration server** | Full plugin/mod lifecycle | Yes (dedicated test server) |

Use Java 25 for current 26.x projects. Keep legacy 1.21.x examples on Java 21
and Forge 1.20.1 on Java 17. Do not combine source layouts or APIs across lanes.

### Routing Boundaries
- `Use when`: the task is designing or implementing automated tests (unit, mock, gametest, CI test jobs) for Minecraft projects.
- `Do not use when`: the task is implementing gameplay features rather than testing them (`minecraft-modding`, `minecraft-plugin-dev`, `minecraft-datapack`).
- `Do not use when`: the task is release automation or publishing pipelines (`minecraft-ci-release`).

## Bundled References And Helpers

- Layout guide: `references/test-layouts.md`
- Fixture/layout validator: `./scripts/validate-test-layout.sh --root <project>`

Use the validator before copying a test layout into a real project. It checks
visible static dependencies, metadata, and literal structure references. It does
not compile the project or prove a Game Test can run.

---

## Unit Testing (JUnit 5 — No Minecraft)

### JUnit Platform task
```kotlin
tasks.test {
    useJUnitPlatform()
    testLogging {
        events("passed", "skipped", "failed")
    }
}
```

For Fabric code that needs loader setup, use Fabric Loader JUnit rather than
assuming ordinary JUnit initialized Minecraft:

```groovy
dependencies {
    testImplementation "net.fabricmc:fabric-loader-junit:${project.loader_version}"
}

test {
    useJUnitPlatform()
}
```

When a unit test reaches registry-dependent Minecraft classes, initialize only
the required bootstrap in test setup. The current Fabric guide uses
`SharedConstants.tryDetectVersion()` and `Bootstrap.bootStrap()` for that case.

### Example pure unit test
```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class CooldownManagerTest {

    @Test
    void cooldown_tracksPlayersIndependently() {
        var manager = new CooldownManager(500L); // 500ms cooldown
        manager.startCooldown("steve");
        assertTrue(manager.isOnCooldown("steve"));
        assertFalse(manager.isOnCooldown("notExisting"));
    }

    @Test
    void cooldown_throwsIllegalArgument_onNegativeDuration() {
        assertThrows(IllegalArgumentException.class,
            () -> new CooldownManager(-1L));
    }
}
```

---

## MockBukkit (Paper/Bukkit Plugin Tests)

### `build.gradle.kts`
```kotlin
repositories {
    maven("https://repo.papermc.io/repository/maven-public/")
    mavenCentral()
}

dependencies {
    compileOnly("io.papermc.paper:paper-api:26.2.build.+")
    testImplementation("org.junit.jupiter:junit-jupiter:6.1.3")
    testImplementation("org.mockbukkit.mockbukkit:mockbukkit-v26.2:4.116.1")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.test {
    useJUnitPlatform()
}
```

### Setup / teardown pattern
```java
import org.mockbukkit.mockbukkit.MockBukkit;
import org.mockbukkit.mockbukkit.ServerMock;
import org.mockbukkit.mockbukkit.entity.PlayerMock;
import org.junit.jupiter.api.*;

class MyPluginTest {

    private static ServerMock server;
    private static MyPlugin plugin;

    @BeforeAll
    static void setUp() {
        // Start mock Bukkit server and load your plugin
        server = MockBukkit.mock();
        plugin = MockBukkit.load(MyPlugin.class);
    }

    @AfterAll
    static void tearDown() {
        MockBukkit.unmock();
    }
}
```

### Testing events
```java
@Test
void playerJoin_getsWelcomeMessage() {
    PlayerMock player = server.addPlayer("Steve");
    player.simulateJoin(); // fires PlayerJoinEvent

    // Assert the player received the expected message component
    player.assertSaid("Welcome, Steve!");
    // Or for Adventure components:
    assertTrue(player.nextMessage().contains("Welcome"));
}

@Test
void onBlockBreak_cancelledForNonOp() {
    PlayerMock player = server.addPlayer();
    player.setOp(false);

    Block block = player.getWorld().getBlockAt(0, 64, 0);
    block.setType(Material.STONE);
    BlockBreakEvent event = new BlockBreakEvent(block, player);
    server.getPluginManager().callEvent(event);

    assertTrue(event.isCancelled(), "Non-op should not be able to break blocks");
}
```

### Testing commands
```java
@Test
void mypluginInfo_returnsVersion() {
    PlayerMock player = server.addPlayer("Admin");
    player.setOp(true);

    boolean result = server.dispatchCommand(player, "myplugin info");

    assertTrue(result);
    player.assertSaid("Version: " + plugin.getDescription().getVersion());
}

@Test
void mypluginReload_requiresOp() {
    PlayerMock player = server.addPlayer("NonOp");
    player.setOp(false);

    server.dispatchCommand(player, "myplugin reload");

    player.assertSaid("No permission.");
}
```

### Testing inventory / items
```java
@Test
void giveKitCommand_givesPlayerItems() {
    PlayerMock player = server.addPlayer();
    
    server.dispatchCommand(player, "kit starter");
    
    // Check inventory
    assertTrue(player.getInventory().contains(Material.STONE_SWORD));
    assertTrue(player.getInventory().contains(Material.BREAD, 16));
}
```

### Testing scheduler tasks
```java
@Test
void repeatingTask_firesAfterDelay() {
    PlayerMock player = server.addPlayer();
    
    // Execute 40 ticks worth of scheduled tasks
    server.getScheduler().performTicks(40L);
    
    // Assert expected side effect happened
    assertEquals(2, plugin.getTaskCount());
}
```

### Testing Folia-safe scheduler abstractions

MockBukkit does not emulate Folia's region-threaded runtime. The safe pattern is to
wrap scheduling behind your own interface and unit test the abstraction boundary.

```java
interface SchedulerFacade {
    void runPlayerTask(Player player, Runnable task);
    void runAsync(Runnable task);
}

@Test
void playerTask_delegatesThroughFacade() {
    List<String> calls = new ArrayList<>();
    SchedulerFacade facade = new SchedulerFacade() {
        @Override
        public void runPlayerTask(Player player, Runnable task) {
            calls.add("player");
            task.run();
        }

        @Override
        public void runAsync(Runnable task) {
            calls.add("async");
            task.run();
        }
    };

    facade.runPlayerTask(server.addPlayer(), () -> calls.add("ran"));
    assertEquals(List.of("player", "ran"), calls);
}
```

### Testing PDC
```java
import java.util.ArrayList;
import org.bukkit.damage.DamageSource;
import org.bukkit.damage.DamageType;
import org.bukkit.entity.LivingEntity;

@Test
void pdcKillCount_incrementsOnKill() {
    PlayerMock player = server.addPlayer();
    NamespacedKey key = new NamespacedKey(plugin, "kills");

    // EntityDeathEvent requires a living victim and an explicit damage source.
    LivingEntity victim = (LivingEntity) server.addMockEntity(EntityType.ZOMBIE);
    DamageSource damageSource = DamageSource.builder(DamageType.GENERIC)
        .withCausingEntity(player)
        .withDirectEntity(player)
        .build();
    EntityDeathEvent deathEvent = new EntityDeathEvent(
        victim, damageSource, new ArrayList<>(), 0
    );
    server.getPluginManager().callEvent(deathEvent);

    int kills = player.getPersistentDataContainer()
        .getOrDefault(key, PersistentDataType.INTEGER, 0);
    assertEquals(1, kills);
}
```

This dispatches a synthetic death event. For player attribution, the listener
under test should read `event.getDamageSource().getCausingEntity()`; test actual
combat attribution separately on a real server.

### Testing item or chunk PDC writes
```java
@Test
void itemPdc_roundTripsCustomId() {
    NamespacedKey key = new NamespacedKey(plugin, "custom_id");
    ItemStack item = new ItemStack(Material.STICK);

    item.editMeta(meta -> meta.getPersistentDataContainer().set(
        key, PersistentDataType.STRING, "wand"
    ));

    String value = item.getItemMeta().getPersistentDataContainer()
        .get(key, PersistentDataType.STRING);
    assertEquals("wand", value);
}
```

---

## Current NeoForge Game Tests (26.x)

NeoForge 1.21.5 and later uses data-driven test environments and test instances,
not the old `@GameTestHolder` method-registration API. Store resources under
`data/<namespace>/test_environment/` and `data/<namespace>/test_instance/`.
A `test_instance` selects its environment, structure, timing, and either a
registered function or a block-based test.

```json
{
  "environment": "minecraft:default",
  "structure": "examplemod:example_structure",
  "max_ticks": 200,
  "setup_ticks": 0,
  "required": true,
  "type": "minecraft:function",
  "function": "examplemod:example_function"
}
```

Register the `Consumer<GameTestHelper>` with a `DeferredRegister` for the
current `BuiltInRegistries.TEST_FUNCTION` registry, then attach that register to
the mod event bus. The function below makes the JSON reference above usable.
Use `RegisterGameTestsEvent` only when registering environments and test
instances in code instead of data files. Keep the referenced structure in
`data/<namespace>/structure/<path>.nbt` and mark success explicitly.

```java
import java.util.function.Consumer;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.gametest.framework.GameTestHelper;
import net.minecraft.world.level.block.Blocks;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.common.Mod;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredRegister;

@Mod(ExampleGameTests.MOD_ID)
public final class ExampleGameTests {
    public static final String MOD_ID = "examplemod";
    private static final DeferredRegister<Consumer<GameTestHelper>> TEST_FUNCTIONS =
        DeferredRegister.create(BuiltInRegistries.TEST_FUNCTION, MOD_ID);
    public static final DeferredHolder<Consumer<GameTestHelper>, Consumer<GameTestHelper>>
        EXAMPLE_FUNCTION = TEST_FUNCTIONS.register(
            "example_function", () -> ExampleGameTests::exampleTest
        );

    public ExampleGameTests(IEventBus modBus) {
        TEST_FUNCTIONS.register(modBus);
    }

    public static void exampleTest(GameTestHelper helper) {
        helper.assertBlockPresent(Blocks.AIR, 0, 0, 0);
        helper.succeed();
    }
}
```

Run `./gradlew runGameTestServer`; the server exits with the count of required
failed tests. This command is for a real project, not this skills repository.

---

## Current Fabric Game Tests (26.x)

Use Fabric Loom's dedicated Game Test source set. Configure it in the existing
`fabricApi` block and keep its metadata and code under `src/gametest`, separate
from ordinary unit tests.

```groovy
fabricApi {
    configureTests {
        createSourceSet = true
        modId = "example-mod-test-${project.name}"
        enableGameTests = true
        enableClientGameTests = true
        eula = true
    }
}
```

Place `fabric.mod.json` in `src/gametest/resources/` and register server tests
under `fabric-gametest`; use `fabric-client-gametest` for client tests. Implement
server methods with Fabric's `net.fabricmc.fabric.api.gametest.v1.GameTest` and,
when setup is needed before a method runs, `CustomTestMethodInvoker`.

```java
package com.example.mymod;

import java.lang.reflect.Method;
import net.fabricmc.fabric.api.gametest.v1.CustomTestMethodInvoker;
import net.fabricmc.fabric.api.gametest.v1.GameTest;
import net.minecraft.gametest.framework.GameTestHelper;
import net.minecraft.world.level.block.Blocks;

public final class ExampleGameTest implements CustomTestMethodInvoker {
    @GameTest
    public void testBlock(GameTestHelper context) {
        context.assertBlockPresent(Blocks.AIR, 0, 0, 0);
        context.succeed();
    }

    @Override
    public void invokeTestMethod(GameTestHelper context, Method method)
            throws ReflectiveOperationException {
        method.invoke(this, context);
    }
}
```

### `src/gametest/resources/fabric.mod.json`
```json
{
  "entrypoints": {
    "fabric-gametest": [
      "com.example.mymod.ExampleGameTest"
    ]
  }
}
```

Keep the `fabric-gametest` entrypoint in sync with the concrete Game Test class.
Fabric's server Game Tests run with `build`; use `runClientGameTest` for client
tests. Follow the current Fabric documentation for project-specific Loom options
and headless client CI.

---

## Legacy NeoForge Game Tests (1.21.3 only)

Keep annotation-based tests isolated to an explicit 1.21.3 lane. The class can
be registered by either `@GameTestHolder(MOD_ID)` or a
`RegisterGameTestsEvent` listener. Do not register a `@GameTestHolder` class
again with `modEventBus.register(MyGameTests.class)`.

```java
import net.minecraft.gametest.framework.GameTest;
import net.minecraft.gametest.framework.GameTestHelper;
import net.neoforged.neoforge.gametest.GameTestHolder;
import net.neoforged.neoforge.gametest.PrefixGameTestTemplate;

@GameTestHolder("examplemod")
@PrefixGameTestTemplate(false)
public final class ExampleGameTests {
    @GameTest(template = "example_structure")
    public static void smoke(GameTestHelper helper) {
        helper.succeed();
    }
}
```

For `RegisterGameTestsEvent`, register the class on the mod event bus and set
`templateNamespace = MOD_ID` on each `@GameTest`. Legacy templates are `.nbt`
files under `data/<namespace>/structure/`; `@PrefixGameTestTemplate(false)`
controls whether the class name is added to the template path. When `template`
is omitted, the path uses the lowercase method name and, unless that prefix is
disabled, the lowercase simple class name followed by a dot. `template` is the
path name only; configure its namespace through `templateNamespace` or
`@GameTestHolder`.

---

## CI

Keep fast unit/mock tests separate from a loader's Game Test task, and select
the Java version by lane: 25 for 26.x, 21 for 1.21.x, and 17 for Forge 1.20.1.
Upload test reports when a runtime-facing job fails. Do not assume a task name
from another loader: Fabric server Game Tests run with `build`, while NeoForge
uses `runGameTestServer`. MockBukkit does not prove Folia thread safety or real
server bootstrap.

---

## References

- MockBukkit GitHub: https://github.com/MockBukkit/MockBukkit
- MockBukkit docs: https://docs.mockbukkit.org/
- Fabric automated testing: https://docs.fabricmc.net/develop/automatic-testing
- NeoForge 26.x Game Tests: https://docs.neoforged.net/docs/misc/gametest/
- NeoForge 1.21.3 Game Tests: https://docs.neoforged.net/docs/1.21.3/misc/gametest/
- JUnit 5 user guide: https://junit.org/junit5/docs/current/user-guide/
