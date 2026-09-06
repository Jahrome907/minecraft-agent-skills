package com.example.mymod;

import net.minecraft.gametest.framework.GameTest;
import net.minecraft.gametest.framework.GameTestHelper;
import net.neoforged.neoforge.gametest.GameTestHolder;
import net.neoforged.neoforge.gametest.PrefixGameTestTemplate;

@GameTestHolder("mymod")
@PrefixGameTestTemplate(false)
public final class LegacyGameTests {
    @GameTest(template = "empty")
    public static void smoke(GameTestHelper helper) {
        helper.succeed();
    }
}
