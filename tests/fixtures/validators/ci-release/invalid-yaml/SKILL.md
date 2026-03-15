---
name: minecraft-ci-release
description: >
  Fixture with malformed workflow YAML.
---

# Invalid YAML Fixture

## Secrets

- `GITHUB_TOKEN`

```yaml
name: Broken Workflow
on:
  push:
jobs:
  build:
    runs-on ubuntu-latest
    steps:
      - run: echo "broken"
```
