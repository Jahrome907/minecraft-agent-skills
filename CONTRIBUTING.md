# Contributing

Thanks for contributing to `minecraft-codex-skills`.

## Repository Model

- Canonical skills live in `.agents/skills/`.
- `.codex/skills/` and `.claude/skills/` are compatibility mirrors and must stay in sync.

## Development Workflow

1. Edit canonical files in `.agents/skills/`.
2. Ensure local tooling:
   - Node `20+`
   - `./scripts/setup-dev-tools.sh`
   - `npm ci`
3. Sync mirror:
   - `./scripts/sync-skills-layout.sh sync`
4. Run validation:
   - `./scripts/sync-skills-layout.sh check`
   - `node ./scripts/audit-skills.mjs`
   - `node ./scripts/validate-doc-snippets.mjs`
   - `./scripts/run-skill-validator-fixtures.sh`
   - `./scripts/test-repo-policy-fixtures.sh`
   - `node ./scripts/check-workflow-action-pins.mjs`
   - `node ./scripts/check-github-community-files.mjs`
   - `npm run lint:md`
5. Update `CHANGELOG.md`.

## Content Standards

- Keep examples accurate for Minecraft `1.21.x`.
- Keep Java examples compatible with Java `21` in their target project context.
- Use explicit routing boundaries in every `SKILL.md`:
  - `Use when`
  - `Do not use when`
- Keep platform boundaries clear (NeoForge/Fabric/Paper/Vanilla).
- Never commit real credentials, tokens, or private keys.

## Pull Requests

- Keep PRs focused and reviewable.
- Open PRs against `main` from a branch; avoid direct pushes to `main`.
- Include rationale for behavior/structure changes.
- Use the PR template to summarize scope, verification, and rollout impact.
- Update `CHANGELOG.md` for any user-facing or maintainer-facing behavior change.
- If you changed canonical skill content, sync `.codex/skills/` and `.claude/skills/` before review.
- Ensure CI passes before requesting review.

## Issues

- Use the GitHub issue templates for bugs and feature requests so reproduction details are complete.
- Do not open public issues for vulnerabilities; follow `SECURITY.md` instead.

## Maintainer Release Flow

1. Land release-ready changes on a branch.
2. Run the full local verification suite on the exact commit you plan to publish.
3. Open a PR to `main` and wait for the GitHub-hosted audit workflow to pass.
4. Merge the PR, create an annotated `vX.Y.Z` tag from the merge commit on `main`, and publish the GitHub Release from that tag.

## Maintainer GitHub Settings

- Protect `main` on GitHub and require the `validate-skills` and `secret-scan` checks before merge.
- Prefer squash merges for release branches so public history stays linear and reviewable.
- Keep direct pushes to `main` disabled in GitHub settings once the protected-branch policy is enabled.
