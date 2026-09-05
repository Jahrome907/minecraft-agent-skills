package com.example.mymod;

import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.common.Mod;
import net.neoforged.neoforge.gametest.RegisterGameTestsEvent;

@Mod("mymod")
public final class MyMod {
    public MyMod(IEventBus modEventBus) {
        modEventBus.register(MyGameTests.class);
    }

    public static void unrelated(RegisterGameTestsEvent event) {
    }
}
