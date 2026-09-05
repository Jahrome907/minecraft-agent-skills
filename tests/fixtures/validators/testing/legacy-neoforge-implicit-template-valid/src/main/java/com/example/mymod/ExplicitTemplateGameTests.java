package com.example.mymod;

import net.minecraft.gametest.framework.GameTest;
import net.minecraft.gametest.framework.GameTestHelper;
import net.neoforged.neoforge.gametest.GameTestHolder;
import net.neoforged.neoforge.gametest.PrefixGameTestTemplate;

@GameTestHolder("mymod")
public final class ExplicitTemplateGameTests {
    @GameTest(template = "example_structure")
    @PrefixGameTestTemplate(false)
    public static void smoke(GameTestHelper helper) {
        helper.succeed();
    }
}
