---
name: minecraft-ci-release
description: Fixture with a mutable remote action reference.
---

# Mutable Action Fixture

```yaml
name: Build
on:
  pull_request:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - run: echo ok
```
