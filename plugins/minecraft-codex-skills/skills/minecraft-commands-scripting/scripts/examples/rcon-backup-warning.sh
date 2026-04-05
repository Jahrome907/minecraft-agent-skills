#!/usr/bin/env bash
set -euo pipefail

RCON_HOST="${RCON_HOST:-127.0.0.1}"
RCON_PORT="${RCON_PORT:-25575}"
RCON_PASSWORD="${RCON_PASSWORD:?set RCON_PASSWORD}"

mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" \
  'tellraw @a {"text":"[Server] Backup starts in 60 seconds.","color":"yellow"}'
mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$RCON_PASSWORD" 'save-all flush'