#!/usr/bin/env bash
# Renders openclaw.json from the template and copies the persona file into
# place. Idempotent: re-running regenerates both files deterministically from
# the template + environment rather than accumulating edits, so it's safe to
# re-run on every update.yml pass.
#
# Tool allowlist stays at the template's default minimal set (web search,
# file read/write within the workspace only — no shell, no browser). Widening
# it is a deliberate, explicit, per-capability edit to
# openclaw/config/openclaw.json.tmpl, never something this script does on its
# own. See CLAUDE.md's "Tool allowlist / agent capability" guardrail.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="$SCRIPT_DIR/../config/openclaw.json.tmpl"
PERSONA_SRC="$SCRIPT_DIR/../config/agent.md"

WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/openclaw-workspace}"
CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
# Cheap/fast model by default per doc 2 Phase 2 ("start with a cheaper/faster
# model for testing") — upgrading to a stronger model is a deliberate,
# explicit config change once the setup is trusted, not a default.
OPENCLAW_MODEL="${OPENCLAW_MODEL:-claude-haiku-4-5-20251001}"

log() { echo "[configure.sh] $*"; }

: "${OPENCLAW_ANTHROPIC_KEY:?OPENCLAW_ANTHROPIC_KEY must be set — a separate, spend-capped key, never the main Anthropic key. See CLAUDE.md.}"
: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN must be set (from @BotFather) — see openclaw-isolated-setup-plan.md Phase 3.}"

mkdir -p "$WORKSPACE_DIR" "$CONFIG_DIR"

log "Rendering openclaw.json into $CONFIG_DIR ..."
export OPENCLAW_WORKSPACE_DIR="$WORKSPACE_DIR"
export OPENCLAW_CONFIG_DIR="$CONFIG_DIR"
export OPENCLAW_MODEL
# shellcheck disable=SC2016 # envsubst wants literal ${VAR} tokens here, not shell expansion
envsubst '${OPENCLAW_WORKSPACE_DIR} ${OPENCLAW_CONFIG_DIR} ${OPENCLAW_MODEL}' \
  < "$TEMPLATE_PATH" > "$CONFIG_DIR/openclaw.json"
chmod 600 "$CONFIG_DIR/openclaw.json"

log "Copying persona file into $CONFIG_DIR ..."
cp "$PERSONA_SRC" "$CONFIG_DIR/agent.md"

log "Config written: model=$OPENCLAW_MODEL workspace=$WORKSPACE_DIR"

if command -v openclaw >/dev/null 2>&1; then
  openclaw doctor || log "openclaw doctor reported issues — review before proceeding."
else
  log "openclaw CLI not found on PATH — run install.sh first. Config was still written."
fi

log "configure.sh complete."
