package com.example.mymod;

import net.minecraft.gametest.framework.GameTest;
import net.minecraft.gametest.framework.GameTestHelper;
import net.neoforged.neoforge.gametest.GameTestHolder;

@GameTestHolder("mymod")
public final class LegacyGameTests {
    @GameTest(template = "mymod:empty")
    public static void smoke(GameTestHelper helper) {
        helper.succeed();
    }
}
