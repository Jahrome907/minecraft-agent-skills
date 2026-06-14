#!/usr/bin/env bash
set -euo pipefail

PASS='[PASS]'
WARN='[WARN]'
FAIL='[FAIL]'

echo "=== Setup Dev Tools ==="

OS="$(uname -s)"

need_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1
}

install_with_apt() {
  sudo apt-get update
  sudo apt-get install -y jq rsync
}

install_with_brew() {
  brew install jq rsync
}

if ! need_cmd node || ! need_cmd npm; then
  echo "$FAIL Node 20+ and npm are required but were not found on PATH."
  echo "$WARN Install Node 20+ with nvm, fnm, Volta, Homebrew, or NodeSource, then rerun."
  exit 1
fi

if need_cmd jq && need_cmd rsync; then
  echo "$PASS Required support tools already installed: jq, rsync"
else
  echo "[INFO] Installing missing support tools..."
  case "$OS" in
    Linux)
      if need_cmd apt-get; then
        install_with_apt
      else
        echo "$FAIL Unsupported Linux package manager. Install manually: jq rsync"
        exit 1
      fi
      ;;
    Darwin)
      if need_cmd brew; then
        install_with_brew
      else
        echo "$FAIL Homebrew is required on macOS. Install brew, then rerun."
        exit 1
      fi
      ;;
    *)
      echo "$FAIL Unsupported OS: $OS"
      echo "$WARN Install manually: jq, rsync, node, npm"
      exit 1
      ;;
  esac
fi

for cmd in jq rsync node npm; do
  if need_cmd "$cmd"; then
    ver="$($cmd --version 2>/dev/null | head -n 1 || true)"
    echo "$PASS $cmd ${ver}"
  else
    echo "$FAIL Missing required command after setup: $cmd"
    exit 1
  fi
done

if need_cmd rsync; then
  ver="$(rsync --version 2>/dev/null | head -n 1 || true)"
  echo "$PASS rsync ${ver}"
else
  echo "$WARN rsync not found; mirror sync will use the Node fallback"
fi

node_major="$(node --version | sed -E 's/^v([0-9]+).*/\1/')"
if [[ -z "$node_major" || "$node_major" -lt 20 ]]; then
  echo "$FAIL Node 20+ is required, but found $(node --version 2>/dev/null || echo missing)"
  echo "$WARN Install Node 20+ with nvm, fnm, Volta, Homebrew, or NodeSource, then rerun."
  exit 1
fi

echo ""
echo "$PASS Dev tools are ready"
