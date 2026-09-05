# Gradle Publishing Reference

Use these snippets only for a project that has chosen the relevant publisher. Keep
its existing project IDs, artifact tasks, loader metadata, and release approval flow.
The examples target Minecraft 26.x on Java 25.

## Release Version and Changelog

Keep the mod version distinct from the computed project/artifact version. This makes
`v1.2.3` a reliable tag for an artifact such as `1.2.3+26.2`.

```kotlin
val modVersion = providers.gradleProperty("mod_version").orNull
    ?: throw GradleException("mod_version is required")
val minecraftVersion = providers.gradleProperty("minecraft_version").orNull
    ?: throw GradleException("minecraft_version is required")

version = "${modVersion}+${minecraftVersion}"

fun changelogFor(releaseVersion: String): String {
    val changelog = rootProject.file("CHANGELOG.md").readText()
    val heading = "## [$releaseVersion]"
    val start = changelog.indexOf(heading)
    check(start >= 0) { "CHANGELOG.md is missing heading: $heading" }

    return changelog.substring(start + heading.length)
        .substringBefore("\n## [")
        .trim()
        .also { check(it.isNotBlank()) { "CHANGELOG.md section is empty: $heading" } }
}

tasks.register("verifyReleaseVersion") {
    group = "verification"
    doLast {
        val tagVersion = providers.gradleProperty("releaseModVersion").orNull
            ?: error("Pass -PreleaseModVersion=<version from v<version> tag>")
        check(tagVersion == modVersion) {
            "Tag version $tagVersion does not match mod_version=$modVersion"
        }
        changelogFor(tagVersion)
    }
}
```

Use a changelog heading such as `## [1.2.3] — 2026-09-04`. Do not look up a heading
from `project.version`, because it includes `+26.2`; `substringAfter` also must not
be used without an explicit missing-heading check because it can return the entire
file.

## Modrinth with Minotaur

The current Gradle Plugin Portal release is `com.modrinth.minotaur` `2.9.0`. For a
Minecraft 26.x Fabric project, upload the primary `jar` task. Current Minecraft is
unobfuscated, so a new 26.x Fabric build should not assume `remapJar` exists.

```kotlin
import org.gradle.api.tasks.bundling.Jar

plugins {
    id("com.modrinth.minotaur") version "2.9.0"
}

modrinth {
    token.set(providers.environmentVariable("MODRINTH_TOKEN"))
    projectId.set(providers.gradleProperty("modrinth_project_id"))
    versionNumber.set(version.toString())
    versionType.set("release")
    uploadFile.set(tasks.named<Jar>("jar"))
    gameVersions.add(minecraftVersion)
    loaders.add("fabric")
    changelog.set(changelogFor(modVersion))
}
```

For a retained legacy Fabric Loom project that produces the distributable
`remapJar`, select that task explicitly instead:

```kotlin
uploadFile.set(tasks.named("remapJar"))
```

Confirm the task name and the produced file in that legacy project before changing
the selection. NeoForge and multi-loader builds can have different platform tasks;
configure each output independently.

## CurseForge with CurseForgeGradle

The current Gradle Plugin Portal release is
`net.darkhax.curseforgegradle` `1.3.33`. Only add this task for a project that
publishes to CurseForge.

```kotlin
import org.gradle.api.tasks.bundling.Jar

plugins {
    id("net.darkhax.curseforgegradle") version "1.3.33"
}

tasks.register<net.darkhax.curseforgegradle.TaskPublishCurseForge>("curseforge") {
    apiToken = providers.environmentVariable("CURSEFORGE_TOKEN").orNull ?: ""

    val mainFile = upload(
        providers.gradleProperty("curseforge_project_id").get(),
        tasks.named<Jar>("jar")
    )
    mainFile.changelogType = "markdown"
    mainFile.changelog = changelogFor(modVersion)
    mainFile.releaseType = "release"
    mainFile.addGameVersion(minecraftVersion)
    mainFile.addModLoader("Fabric")
    mainFile.addJavaVersion("Java 25")
    mainFile.addEnvironment("Client", "Server")
}
```

Set the actual loader and supported environments for the artifact. CurseForgeGradle
can infer loader, game, and Java metadata when the relevant project configuration is
present; explicit metadata is useful only when it matches the released JAR.

## Optional Combined Task

Only create a combined task when both publishers and all named platform tasks are
already configured in the project:

```kotlin
tasks.register("publishSelectedDestinations") {
    group = "publishing"
    dependsOn("modrinth", "curseforge")
}
```

Do not add missing publisher plugins, task dependencies, project IDs, or secrets just
to make this aggregation example apply.
