#!/usr/bin/env bash
set -euo pipefail

export MCRCON_HOST="${MCRCON_HOST:-127.0.0.1}"
export MCRCON_PORT="${MCRCON_PORT:-25575}"
: "${MCRCON_PASS:?inject MCRCON_PASS from a protected secret}"

mcrcon 'tellraw @a {"text":"[Server] Backup starts in 60 seconds.","color":"yellow"}'
sleep 60
mcrcon 'save-all flush'
