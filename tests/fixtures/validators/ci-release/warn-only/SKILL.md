---
name: minecraft-ci-release
description: Fixture with valid workflow YAML and a warning-only glob pattern.
---

# Warning Fixture

```yaml
name: Warn Only
on:
  workflow_dispatch:
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: echo "ok"
        env:
          OUTPUT_PATH: build/**/**
```
