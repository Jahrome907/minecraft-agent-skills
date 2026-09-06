# EssentialsX Permissions and Rollout Checklists

Load this file when the task is a permissions review, economy rollout, or a
moderation-policy change that needs a compact checklist.

## Permissions Review

- Map each command family to a role: admin, staff, player, donor, event host, etc.
- Remove wildcard grants from non-admin groups unless absolutely necessary.
- Test with representative accounts, not only operator status.
- Verify homes, warps, nicknames, economy, and moderation commands separately.

## Economy Rollout

- Confirm Vault provider chain before enabling economy-dependent plugins.
- Set starter balances, sinks, and restricted admin commands intentionally.
- Test pay, shop, sell, and reward flows with non-op accounts.
- Watch for dupe paths or unintended zero-cost item loops after launch.

## Moderation Rollout

- Define mute, jail, tempban, and permanent-ban thresholds in writing.
- Ensure staff can supply reasons and durations consistently.
- Grant `essentials.setjail` only to authorized roles; use
  `essentials.togglejail` for staff who jail and unjail players.
- Verify logs or moderation records are retained as expected.
- Keep rollback or appeal procedures documented for staff.

## Config Change Smoke Test

- Join with a normal player account.
- Confirm `/spawn`, `/home`, `/warp`, `/msg`, and `/pay` behavior.
- Confirm staff moderation commands work without exposing economy admin commands.
- Keep the previous Essentials config bundle available for rollback.
