#!/usr/bin/env bash
set -euo pipefail

CANONICAL_DIR=".agents/skills"
MIRROR_DIRS=(".codex/skills" ".claude/skills")
MODE="${1:-sync}"

if [[ ! -d "$CANONICAL_DIR" ]]; then
  echo "[FAIL] Missing canonical directory: $CANONICAL_DIR" >&2
  exit 1
fi

FAILED=0

case "$MODE" in
  sync)
    for MIRROR_DIR in "${MIRROR_DIRS[@]}"; do
      mkdir -p "$MIRROR_DIR"
      rsync -a --delete "$CANONICAL_DIR/" "$MIRROR_DIR/"
      echo "[PASS] Synced $CANONICAL_DIR -> $MIRROR_DIR"
    done
    ;;
  check)
    for MIRROR_DIR in "${MIRROR_DIRS[@]}"; do
      if [[ ! -d "$MIRROR_DIR" ]]; then
        echo "[FAIL] Mirror directory missing: $MIRROR_DIR" >&2
        FAILED=1
        continue
      fi
      DIFF_OUTPUT="$(rsync -ani --delete "$CANONICAL_DIR/" "$MIRROR_DIR/")"
      if [[ -n "$DIFF_OUTPUT" ]]; then
        echo "[FAIL] Mirror drift detected between $CANONICAL_DIR and $MIRROR_DIR" >&2
        echo "$DIFF_OUTPUT" >&2
        FAILED=1
      else
        echo "[PASS] $CANONICAL_DIR and $MIRROR_DIR are in sync"
      fi
    done
    if [[ "$FAILED" -ne 0 ]]; then
      exit 1
    fi
    echo "[PASS] Canonical and all mirror trees are in sync"
    ;;
  *)
    echo "Usage: $0 [sync|check]" >&2
    exit 1
    ;;
esac
