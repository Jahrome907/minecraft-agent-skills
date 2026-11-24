# CI Release Fixture

## Required Secrets

- `MODRINTH_TOKEN`
- `CURSEFORGE_TOKEN`

```yaml
name: Build
on:
  push:
    branches: ["main"]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803
      - uses: ./.github/actions/example
      - uses: $/.github/actions/example
      - uses: docker://alpine@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
      - run: echo ok
      - env:
          MODRINTH_TOKEN: ${{ secrets.MODRINTH_TOKEN }}
          CURSEFORGE_TOKEN: ${{ secrets.CURSEFORGE_TOKEN }}
        run: echo release
```
