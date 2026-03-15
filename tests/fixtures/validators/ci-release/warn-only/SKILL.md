---
name: minecraft-ci-release
description: >
  Fixture with valid workflow YAML but a warning-only secrets section.
---

# Warning Fixture

## Secrets

- `MODRINTH_TOKEN`

```yaml
name: Warn Only
on:
  workflow_dispatch:
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: echo "ok"
```
