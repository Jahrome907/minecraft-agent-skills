---
name: minecraft-ci-release
description: >
  Fixture with valid multiline flow collections in workflow YAML.
---

# Multiline Flow Fixture

## Required Secrets

- `MODRINTH_TOKEN`

```yaml
name: Matrix Build
on:
  push:
    branches: ["main"]
jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - { platform: fabric, dir: fabric }
          - { platform: neoforge, dir: neoforge }
    steps:
      - uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803
      - env:
          MODRINTH_TOKEN: ${{ secrets.MODRINTH_TOKEN }}
        run: "./gradlew :${{ matrix.dir }}:build --no-daemon"
```
