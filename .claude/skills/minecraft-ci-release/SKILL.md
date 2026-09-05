---
name: minecraft-ci-release
description: "Set up and review CI, artifact publishing, versioning, and release governance for Minecraft 26.x or legacy 1.21.x mods and Paper plugins. Use for pipelines and releases, not gameplay implementation or server operations."
---

# Minecraft CI / Release Skill

## Routing Boundaries
- `Use when`: the task is CI/CD pipelines, artifact publishing, versioning, or release governance.
- `Do not use when`: the task is gameplay or plugin implementation (`minecraft-modding`, `minecraft-plugin-dev`, or `minecraft-datapack`).
- `Do not use when`: the task is server runtime operations or infrastructure tuning (`minecraft-server-admin`).

---

## Release Shape

Keep each repository's existing release destinations and approval policy. A tag can
build an artifact and create a GitHub Release without publishing to Modrinth or
CurseForge. Add a publisher only when the project already uses it or the user asks
for it. Never add tokens to committed files.

For the current Minecraft 26.x lane, use Java 25 and state that in workflow labels
and examples. Legacy Minecraft 1.21.x projects stay on Java 21; retain their own
loader and Gradle conventions instead of mechanically changing their version.

Use an immutable GitHub Action revision in a protected workflow. The following refs
were verified from the upstream tags on 2026-09-04; refresh them from the upstream
tag before intentionally upgrading an action:

```text
actions/checkout@v7.0.1             3d3c42e5aac5ba805825da76410c181273ba90b1
actions/setup-java@v6.0.0           dd06d9cba3e5552c54d9f8ea23572deb30010f7c
gradle/actions/setup-gradle@v6.3.0  9c971963bec38e04b3d30dcc455b5382be2fdbfb
actions/upload-artifact@v7.0.1      043fb46d1a93c77aae656e7c1c64a875d1fc6a0a
softprops/action-gh-release@v3.0.3  efb35369e0ad2afab669f228072c1b0d510eae64
```

## Version and Tag Convention

Minecraft mod versions follow: `{mod_version}+{mc_version}`

```
1.0.0+26.2  ← mod 1.0.0 for MC 26.2
1.2.3+26.2
2.0.0+26.2
```

Use a release version without the game suffix for the Git tag, and retain the
Minecraft version in the artifact version when the project uses that convention:

```text
mod_version: 1.2.3
project/artifact version: 1.2.3+26.2
tag: v1.2.3
```

The release workflow must verify that `v1.2.3` matches `mod_version=1.2.3` before
building. Do not override `mod_version` from the tag, because that hides a mismatch.
The Gradle task and safe changelog extraction are in
[the publishing reference](references/publishing-gradle.md).

---

## Core CI Workflow (NeoForge + Fabric)

This is a Minecraft 26.x / Java 25 example. Its displayed check names are
`Build / Build (fabric)`, `Build / Build (neoforge)`, and `Build / Test` after
the test job below is added. After the first successful pull request, copy the
exact names GitHub displays into branch protection; workflow or job renames
change the required-check context.

### `.github/workflows/build.yml`
```yaml
name: Build

on:
  push:
    branches: ["main", "develop"]
  pull_request:
    branches: ["main"]

permissions:
  contents: read

jobs:
  build:
    name: Build (${{ matrix.platform }})
    runs-on: ubuntu-latest
    strategy:
      matrix:
        platform: [neoforge, fabric]
      fail-fast: false

    steps:
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1

      - name: Set up Java 25
        uses: actions/setup-java@dd06d9cba3e5552c54d9f8ea23572deb30010f7c
        with:
          java-version: "25"
          distribution: "temurin"

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@9c971963bec38e04b3d30dcc455b5382be2fdbfb
        with:
          cache-read-only: ${{ github.event_name == 'pull_request' }}

      - name: Grant execute permission for gradlew
        run: chmod +x gradlew

      - name: Build (${{ matrix.platform }})
        run: ./gradlew :${{ matrix.platform }}:build --no-daemon

      - name: Upload artifacts
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a
        with:
          name: mod-${{ matrix.platform }}-${{ github.sha }}
          path: ${{ matrix.platform }}/build/libs/*.jar
          if-no-files-found: error

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - name: Set up Java 25
        uses: actions/setup-java@dd06d9cba3e5552c54d9f8ea23572deb30010f7c
        with:
          distribution: temurin
          java-version: "25"
      - name: Set up Gradle
        uses: gradle/actions/setup-gradle@9c971963bec38e04b3d30dcc455b5382be2fdbfb
      - name: Run tests
        run: ./gradlew test --no-daemon
```

---

## Tagged GitHub Release

### `.github/workflows/release.yml`
```yaml
name: Release

on:
  push:
    tags:
      - "v*"

permissions:
  contents: write      # for creating GitHub releases

jobs:
  release:
    name: Release
    runs-on: ubuntu-latest

    steps:
      - name: Checkout tagged source
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1

      - name: Set up Java 25
        uses: actions/setup-java@dd06d9cba3e5552c54d9f8ea23572deb30010f7c
        with:
          java-version: "25"
          distribution: "temurin"

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@9c971963bec38e04b3d30dcc455b5382be2fdbfb

      - name: Grant execute permission for gradlew
        run: chmod +x gradlew

      - name: Validate tag and build
        env:
          MOD_VERSION: ${{ github.ref_name }}
        run: |
          MOD_VERSION="${MOD_VERSION#v}"
          ./gradlew verifyReleaseVersion build --no-daemon \
            -PreleaseModVersion="$MOD_VERSION"

      - name: Select release artifacts
        run: |
          mkdir -p release-artifacts
          find fabric/build/libs neoforge/build/libs -maxdepth 1 -type f -name '*.jar' \
            ! -name '*-sources.jar' ! -name '*-dev.jar' -exec cp {} release-artifacts/ \;
          test -n "$(find release-artifacts -maxdepth 1 -type f -name '*.jar' -print -quit)" \
            || { echo 'No release JAR was selected.' >&2; exit 1; }

      - name: Create GitHub Release
        uses: softprops/action-gh-release@efb35369e0ad2afab669f228072c1b0d510eae64
        with:
          files: release-artifacts/*.jar
          fail_on_unmatched_files: true
          generate_release_notes: true
          prerelease: ${{ contains(github.ref_name, '-alpha') || contains(github.ref_name, '-beta') || contains(github.ref_name, '-rc') }}
```

This workflow creates a GitHub Release only. Add a project-specific publisher after
the version validation only when that destination is in scope. Update the selected
artifact directories and exclusions to match the build, but keep both the non-empty
check and `fail_on_unmatched_files: true` so an empty glob cannot create a release.

---

## Paper Plugin CI

### `.github/workflows/build.yml` (plugin)
```yaml
name: Build

on:
  push:
    branches: ["main"]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - uses: actions/setup-java@dd06d9cba3e5552c54d9f8ea23572deb30010f7c
        with:
          java-version: "25"
          distribution: "temurin"
      - uses: gradle/actions/setup-gradle@9c971963bec38e04b3d30dcc455b5382be2fdbfb
      - run: chmod +x gradlew
      - run: ./gradlew build --no-daemon
      - uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a
        with:
          name: plugin-${{ github.sha }}
          path: build/libs/*.jar
          if-no-files-found: error

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - uses: actions/setup-java@dd06d9cba3e5552c54d9f8ea23572deb30010f7c
        with:
          java-version: "25"
          distribution: "temurin"
      - uses: gradle/actions/setup-gradle@9c971963bec38e04b3d30dcc455b5382be2fdbfb
      - run: ./gradlew test --no-daemon
```

---

## Publishing and Changelog Details

Read [the publishing reference](references/publishing-gradle.md) only when the
project publishes to Modrinth or CurseForge. It includes current plugin versions,
26.x `jar` selection, explicit legacy Loom `remapJar` guidance, version verification,
and a parser that fails when the expected changelog heading is missing.

---

## `gradle.properties` Secrets Pattern

Never hardcode tokens. Read them from environment:

```properties
# gradle.properties (committed)
mod_id=mymod
mod_version=1.0.0
minecraft_version=26.2
modrinth_project_id=AABBCCDD
curseforge_project_id=123456

# DO NOT commit tokens
# Set these as GitHub repo secrets:
# MODRINTH_TOKEN, CURSEFORGE_TOKEN
```

---

## Semantic Versioning for Mods

| Change | Version bump |
|--------|-------------|
| New features, no breaking changes | Minor: `1.1.0` |
| Bug fixes only | Patch: `1.0.1` |
| API/config breaking changes | Major: `2.0.0` |
| Minecraft version update | Keep mod version, change the `+26.2` suffix |
| Pre-release | `1.0.0-beta.1`, `1.0.0-rc.1` |

---

## CHANGELOG.md Convention

```markdown
# Changelog

## [1.1.0] — 2025-06-01
### Added
- New `/kit` command
- PDC-based kill tracker

### Fixed
- Death message not appearing on Paper 26.2

## [1.0.0] — 2025-05-01
### Added
- Initial release
```

The publishing reference extracts this section by `mod_version` and fails clearly
when the expected heading is missing.

---

## Dependabot Configuration

### `.github/dependabot.yml`
```yaml
version: 2
updates:
  - package-ecosystem: "gradle"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      gradle-plugins:
        patterns:
          - "com.gradleup.shadow"
          - "dev.architectury.loom"
          - "com.modrinth.minotaur"
          - "net.darkhax.curseforgegradle"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

---

## Build Caching Best Practices

```yaml
# In all workflow jobs:
- name: Setup Gradle
  uses: gradle/actions/setup-gradle@9c971963bec38e04b3d30dcc455b5382be2fdbfb
  with:
    # Read-only cache on PRs, read-write on main
    cache-read-only: ${{ github.event_name == 'pull_request' }}
    # Cache Minecraft assets (speeds up loom tasks by minutes)
    gradle-home-cache-includes: |
      caches
      notifications
      .gradle/loom-cache
```

---

## Branch Protection + Required Checks

Recommended GitHub branch protection for `main`:
- Require the observed checks: `Build / Build (fabric)`, `Build / Build (neoforge)`, and `Build / Test`
- Require linear history (squash/rebase merges)
- Require signed commits (optional but recommended for release workflows)

---

## Tag and Release Script

```bash
#!/usr/bin/env bash
# scripts/release.sh <mod-version>
set -euo pipefail

VERSION="${1:?Usage: release.sh <mod-version>}"
git diff --check
git diff --exit-code
git tag --annotate "v${VERSION}" --message "Release v${VERSION}"
git push origin HEAD
git push origin "refs/tags/v${VERSION}"
```

Update and verify version/changelog files before this script, then tag that release
commit. Do not force-push or retag a published release without explicit authorization.

## Workflow Snippet Validator

Run the bundled validator from an installed `minecraft-ci-release` skill directory:

```bash
# Run from the installed skill directory:
./scripts/validate-workflow-snippets.sh --root .

# Strict mode treats warnings as failures:
./scripts/validate-workflow-snippets.sh --root . --strict
```

The validator is bundled and self-contained. Run it from a copied `.agents/`,
`.codex/`, or `.claude/` `minecraft-ci-release` skill directory without relying
on repo-root `node_modules`.

It validates workflow-shaped YAML, unresolved placeholders, documented secrets, and
remote `uses:` references pinned to full commit SHAs. Local actions (`./...`) and
Docker actions (`docker://...`) are intentionally excluded from the SHA requirement.

---

## References

- [GitHub Actions security hardening](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-your-deployments)
- [GitHub branch protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [Minotaur](https://github.com/modrinth/minotaur)
- [CurseForgeGradle](https://github.com/Darkhax/CurseForgeGradle)
