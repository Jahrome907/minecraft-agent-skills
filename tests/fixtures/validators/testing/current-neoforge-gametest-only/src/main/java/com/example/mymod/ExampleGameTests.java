package com.example.mymod;

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
    public static final String MOD_ID = "mymod";
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
