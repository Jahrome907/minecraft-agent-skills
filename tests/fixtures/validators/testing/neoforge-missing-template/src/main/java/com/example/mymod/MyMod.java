package com.example.mymod;

import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.common.Mod;

@Mod("mymod")
public final class MyMod {
    public MyMod(IEventBus modEventBus) {
        modEventBus.register(MyGameTests.class);
    }
}
