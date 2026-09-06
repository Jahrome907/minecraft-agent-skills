package com.example.mymod;

import net.minecraft.gametest.framework.GameTest;
import net.minecraft.gametest.framework.GameTestHelper;
import net.neoforged.neoforge.gametest.PrefixGameTestTemplate;

@PrefixGameTestTemplate(false)
public final class MyGameTests {
    @GameTest(templateNamespace = "mymod", template = "empty")
    public static void smoke(GameTestHelper helper) {
        helper.succeed();
    }
}
