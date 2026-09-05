package com.example.mymod;

import net.minecraft.gametest.framework.GameTest;
import net.minecraft.gametest.framework.GameTestHelper;
import net.neoforged.neoforge.gametest.GameTestHolder;
import net.neoforged.neoforge.gametest.PrefixGameTestTemplate;

@GameTestHolder("mymod")
@PrefixGameTestTemplate(false)
public final class MyGameTests {
    @GameTest(template = "missing_template")
    public static void smoke(GameTestHelper helper) {
        helper.succeed();
    }
}
