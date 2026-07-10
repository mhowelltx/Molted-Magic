#!/usr/bin/env bash
# Installs Node 22+, then runs the official OpenClaw installer. Idempotent:
# safe to re-run — skips Node/OpenClaw install if already present at a
# sufficient version.
#
# "Review the fetched script before executing" (doc 2) can't mean a human
# reads it on every automated run, so it's operationalized as a pinned
# checksum instead: the installer is fetched, hashed, and compared against
# openclaw-install.sha256 in this directory. If that file doesn't exist yet,
# this script refuses to run the installer and prints instructions for the
# one-time human review + pin step. Any unreviewed upstream change to the
# installer changes the hash and fails loudly rather than running silently.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_MAJOR_MIN=22
INSTALLER_URL="https://openclaw.ai/install.sh"
PINNED_HASH_FILE="$SCRIPT_DIR/openclaw-install.sha256"
FETCHED_INSTALLER="$(mktemp)"
trap 'rm -f "$FETCHED_INSTALLER"' EXIT

log() { echo "[install.sh] $*"; }

# --- Node.js ---
node_ok=false
if command -v node >/dev/null 2>&1; then
  node_major="$(node -e 'console.log(process.versions.node.split(".")[0])')"
  if [ "$node_major" -ge "$NODE_MAJOR_MIN" ]; then
    node_ok=true
  fi
fi

if [ "$node_ok" = true ]; then
  log "Node $(node -v) already installed (>= ${NODE_MAJOR_MIN}), skipping."
else
  log "Installing Node ${NODE_MAJOR_MIN}.x..."
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR_MIN}.x" | sudo -E bash -
  sudo apt-get install -y nodejs
fi

# --- OpenClaw ---
if command -v openclaw >/dev/null 2>&1; then
  log "openclaw CLI already installed ($(openclaw --version 2>/dev/null || echo "version unknown")), skipping installer."
  exit 0
fi

if [ ! -f "$PINNED_HASH_FILE" ]; then
  log "No pinned installer hash found at $PINNED_HASH_FILE."
  log "One-time manual step required before this script can run the installer:"
  log "  1. curl -fsSL $INSTALLER_URL -o /tmp/openclaw-install.sh"
  log "  2. less /tmp/openclaw-install.sh   # actually read it"
  log "  3. sha256sum /tmp/openclaw-install.sh | awk '{print \$1}' > $PINNED_HASH_FILE"
  log "  4. commit $PINNED_HASH_FILE"
  exit 1
fi

log "Fetching OpenClaw installer..."
curl -fsSL "$INSTALLER_URL" -o "$FETCHED_INSTALLER"

expected_hash="$(cat "$PINNED_HASH_FILE")"
actual_hash="$(sha256sum "$FETCHED_INSTALLER" | awk '{print $1}')"

if [ "$actual_hash" != "$expected_hash" ]; then
  log "REFUSING TO RUN: installer hash does not match the pinned value."
  log "  expected: $expected_hash"
  log "  actual:   $actual_hash"
  log "The upstream installer changed since it was last reviewed. Review the"
  log "new version manually (see steps above) before updating the pinned hash."
  exit 1
fi

log "Installer hash matches pinned value. Running it..."
bash "$FETCHED_INSTALLER"

log "install.sh complete."
