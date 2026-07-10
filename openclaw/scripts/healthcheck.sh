#!/usr/bin/env bash
# Wraps `openclaw doctor`, exit-code driven so it can be used both by
# healthcheck.yml (Session 8) and manual/cron checks. Read-only: never takes
# corrective action itself, only reports status.
set -euo pipefail

log() { echo "[healthcheck.sh] $*"; }

if ! command -v openclaw >/dev/null 2>&1; then
  log "openclaw CLI not found on PATH."
  exit 1
fi

if openclaw doctor; then
  log "openclaw doctor: OK"
  exit 0
fi

status=$?
log "openclaw doctor failed (exit $status)"
exit "$status"
