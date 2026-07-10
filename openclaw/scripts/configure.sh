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

# Telegram is optional, not required: the rendered config only ever names the
# env var OpenClaw should read the token from (channels.telegram.bot_token_env
# in openclaw.json.tmpl), never the token value itself, so there's nothing to
# fail render-time validation on. If it's unset, the daemon just won't be able
# to authenticate the Telegram channel until a real token is added later.
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
  log "TELEGRAM_BOT_TOKEN not set — Telegram channel will be configured but unable to connect until a real token is provided (from @BotFather, see openclaw-isolated-setup-plan.md Phase 3)."
fi

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
  # Daemon lifecycle lives here, not install.sh: this is the idempotent
  # script that reruns on every update.yml pass, so "ensure installed, then
  # restart to pick up the just-rendered config" belongs in the same place
  # as the config render itself, not split across two scripts. `daemon
  # status`/`daemon install`/`daemon restart` subcommand names are inferred
  # from doc 2 Phase 5 ("openclaw daemon install") the same way the rest of
  # openclaw.json.tmpl's schema is — unverified against a real CLI reference.
  if ! openclaw daemon status >/dev/null 2>&1; then
    log "OpenClaw daemon not yet installed — installing..."
    openclaw daemon install
  fi
  log "Restarting OpenClaw daemon to pick up the new config..."
  openclaw daemon restart
  openclaw doctor || log "openclaw doctor reported issues — review before proceeding."
else
  log "openclaw CLI not found on PATH — run install.sh first. Config was still written."
fi

log "configure.sh complete."
