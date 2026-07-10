#!/usr/bin/env bash
# Renders openclaw.json from the template and delivers the persona as a
# workspace bootstrap file. Idempotent: re-running regenerates both
# deterministically from the template + environment rather than accumulating
# edits, so it's safe to re-run on every update.yml pass.
#
# Schema confirmed for real against the installed `openclaw` npm package
# (v2026.6.11) via `openclaw config schema` + `openclaw config validate`
# locally — not guessed. Persona delivery via a workspace bootstrap file
# (SOUL.md) is likewise a confirmed real convention (openclaw config schema's
# agents.defaults.skipOptionalBootstrapFiles enum: SOUL.md, USER.md,
# HEARTBEAT.md, IDENTITY.md) — there is no "persona_file" config key.
#
# Tool allowlist stays at the template's default minimal posture (tools.profile
# "minimal" + web.search enabled + fs.workspaceOnly — no shell, no browser).
# Widening it is a deliberate, explicit, per-capability edit to
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
# explicit config change once the setup is trusted, not a default. Bare
# model id here; the template prefixes it with "anthropic/" per the real
# agents.defaults.model "provider/model" string format.
OPENCLAW_MODEL="${OPENCLAW_MODEL:-claude-haiku-4-5-20251001}"

log() { echo "[configure.sh] $*"; }

: "${OPENCLAW_ANTHROPIC_KEY:?OPENCLAW_ANTHROPIC_KEY must be set — a separate, spend-capped key, never the main Anthropic key. See CLAUDE.md.}"

# Telegram is optional, not required: the rendered config only ever names the
# env var OpenClaw should read the token from (channels.telegram.botToken's
# SecretRef in openclaw.json.tmpl), never the token value itself, so there's
# nothing to fail render-time validation on. If it's unset, the gateway just
# won't be able to authenticate the Telegram channel until a real token is
# added later.
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
  log "TELEGRAM_BOT_TOKEN not set — Telegram channel will be configured but unable to connect until a real token is provided (from @BotFather, see openclaw-isolated-setup-plan.md Phase 3)."
fi

mkdir -p "$WORKSPACE_DIR" "$CONFIG_DIR"

log "Rendering openclaw.json into $CONFIG_DIR ..."
export OPENCLAW_WORKSPACE_DIR="$WORKSPACE_DIR"
export OPENCLAW_MODEL
# shellcheck disable=SC2016 # envsubst wants literal ${VAR} tokens here, not shell expansion
envsubst '${OPENCLAW_WORKSPACE_DIR} ${OPENCLAW_MODEL}' \
  < "$TEMPLATE_PATH" > "$CONFIG_DIR/openclaw.json"
chmod 600 "$CONFIG_DIR/openclaw.json"

log "Delivering persona as a workspace bootstrap file (SOUL.md)..."
cp "$PERSONA_SRC" "$WORKSPACE_DIR/SOUL.md"

log "Config written: model=anthropic/$OPENCLAW_MODEL workspace=$WORKSPACE_DIR"

if command -v openclaw >/dev/null 2>&1; then
  openclaw config validate || { log "openclaw config validate FAILED — not restarting the gateway with a broken config."; exit 1; }
  # `daemon` is a confirmed-real legacy alias for `gateway` service management
  # (openclaw --help), not a guess. Daemon lifecycle lives here, not
  # install.sh: this is the idempotent script that reruns on every update.yml
  # pass, so "ensure installed, then restart to pick up the just-rendered
  # config" belongs in the same place as the config render itself.
  if ! openclaw daemon status >/dev/null 2>&1; then
    log "OpenClaw gateway service not yet installed — installing..."
    openclaw daemon install
  fi
  log "Restarting the OpenClaw gateway service to pick up the new config..."
  openclaw daemon restart
  openclaw doctor || log "openclaw doctor reported issues — review before proceeding."
else
  log "openclaw CLI not found on PATH — run install.sh first. Config was still written."
fi

log "configure.sh complete."
