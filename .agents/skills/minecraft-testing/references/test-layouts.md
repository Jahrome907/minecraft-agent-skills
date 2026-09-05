# Minecraft Testing Layouts

Choose one explicit platform and version lane. `src/test` is for JUnit or
MockBukkit; it is optional for a Game Test-only project.

## Unit + MockBukkit plugin

```text
src/
  main/
    java/com/example/myplugin/
    resources/
      plugin.yml
  test/
    java/com/example/myplugin/
      MyPluginTest.java
      CommandExecutorTest.java
```

Checklist:

- `build.gradle(.kts)` declares compatible JUnit Jupiter and MockBukkit versions
- `tasks.test { useJUnitPlatform() }` is enabled

## Current Fabric 26.x

Fabric Loom's recommended Game Test layout uses a separate source set.

```text
src/
  main/
    java/com/example/mymod/
    resources/
      fabric.mod.json
  gametest/
    java/com/example/mymod/
      ExampleGameTest.java
    resources/
      fabric.mod.json
      data/mymod/structure/
        example_structure.nbt
  test/                         # only when JUnit tests exist
    java/com/example/mymod/
      SerializerTest.java
```

Configure `fabricApi.configureTests { createSourceSet = true }`. Register server
tests in `src/gametest/resources/fabric.mod.json` under `fabric-gametest`, and
client tests under `fabric-client-gametest`. The current Fabric API annotation
is `net.fabricmc.fabric.api.gametest.v1.GameTest`.

## Current NeoForge 26.x

```text
src/
  main/
    java/com/example/mymod/
      GameTestFunctions.java
    resources/
      META-INF/neoforge.mods.toml
      data/mymod/structure/
        empty.nbt
      data/mymod/test_instance/
        example_test.json
  test/                         # only when JUnit tests exist
    java/com/example/mymod/
      CooldownManagerTest.java
```

Checklist:

NeoForge 1.21.5+ models Game Tests as registered test environments, functions,
and test instances. A `test_instance` must reference an existing structure. Add
a `test_environment` resource when `minecraft:default` is not sufficient.
Register custom test functions with a `DeferredRegister` for
`BuiltInRegistries.TEST_FUNCTION` and attach it to the mod event bus. Use
`RegisterGameTestsEvent` to register environments and instances in code.

## Legacy NeoForge 1.21.3

Only use the annotation route for a clearly labelled 1.21.3 project.

```text
src/
  main/
    java/com/example/mymod/
      LegacyGameTests.java
    resources/
      META-INF/neoforge.mods.toml
      data/mymod/structure/
        example_structure.nbt
```

`@GameTestHolder(MOD_ID)` registers the methods in the annotated type. The
alternative is an event-bus `RegisterGameTestsEvent` listener that calls
`event.register(LegacyGameTests.class)`; then each test provides its
`templateNamespace`. Do not require both mechanisms.

## Validator Usage

```bash
./scripts/validate-test-layout.sh --root .
./scripts/validate-test-layout.sh --root . --strict
```

What it checks:

- build file exists
- JUnit Platform is enabled when unit or MockBukkit tests are present
- MockBukkit tests have the dependency
- GameTests have committed structure fixtures that match referenced templates
- Fabric GameTests include their metadata and entrypoints
