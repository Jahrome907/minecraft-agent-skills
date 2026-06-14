package com.example.mymod.fabric;

import net.fabricmc.fabric.api.gametest.v1.FabricGameTest;
import net.minecraft.gametest.framework.GameTest;
import net.minecraft.gametest.framework.GameTestHelper;

public final class MyFabricGameTests implements FabricGameTest {
    @GameTest(template = "mymod:empty")
    public void smoke(GameTestHelper helper) {
        helper.succeed();
    }
}
