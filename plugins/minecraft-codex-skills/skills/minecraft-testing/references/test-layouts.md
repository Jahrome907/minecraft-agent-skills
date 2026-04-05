# Minecraft Testing Layouts (1.21.x)

Use these layouts as the default shape for testable projects.

## 1. Pure Unit + MockBukkit Plugin Layout

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
    resources/
      data/testplugin/structures/
        empty.nbt
```

Checklist:

- `build.gradle(.kts)` declares JUnit 5 and MockBukkit
- `tasks.test { useJUnitPlatform() }` is enabled
- Any committed GameTest structures live under `src/test/resources/data/<modid>/structures/`

## 2. NeoForge GameTest Layout

```text
src/
  main/
    java/com/example/mymod/
      MyMod.java
      MyGameTests.java
    resources/
      META-INF/neoforge.mods.toml
      data/mymod/structures/
        empty.nbt
  test/
    java/com/example/mymod/
      CooldownManagerTest.java
```

Checklist:

- Keep pure unit tests in `src/test/java`
- Keep GameTest structure fixtures under committed `data/<modid>/structures/`
- Make the test namespace match the `@GameTest(template = "<namespace>:...")` usage

## 3. Fabric GameTest Layout

```text
src/
  main/
    java/com/example/mymod/
      MyMod.java
      MyFabricGameTests.java
    resources/
      fabric.mod.json
      data/mymod/structures/
        empty.nbt
  test/
    java/com/example/mymod/
      SerializerTest.java
```

Checklist:

- Keep `fabric-gametest` entrypoints in `fabric.mod.json`
- Commit the `.nbt` templates used by your tests
- Keep game-facing tests small; move parsing and business logic back into plain JUnit

## Validator Usage

```bash
./scripts/validate-test-layout.sh --root .
./scripts/validate-test-layout.sh --root . --strict
```

What it checks:

- build file exists
- test source roots exist
- JUnit Platform is enabled
- MockBukkit tests have the dependency
- GameTests have committed structure fixtures
