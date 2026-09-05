---
name: minecraft-ci-release
description: Fixture for a secretless workflow that passes strict validation.
---

# Secretless Workflow Fixture

```yaml
name: Build
on:
  pull_request:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - run: echo ok
```
