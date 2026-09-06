package com.example.mymod;

import net.minecraft.gametest.framework.GameTest;
import net.minecraft.gametest.framework.GameTestHelper;

public final class EventRegisteredGameTests {
    @GameTest(templateNamespace = "mymod")
    public static void smoke(GameTestHelper helper) {
        helper.succeed();
    }
}
