# Progress

Read this first. Dynamic — updated at the end of every session. See [`ROADMAP.md`](ROADMAP.md) for the static full sequence.

## Current phase

Session 4 (install.sh / configure.sh / healthcheck.sh) — complete, and pulled the config-template part of Session 5 forward with it. Remaining Session 5 work is just `agent.md`. Next up: write `agent.md`, then Session 6 (`provision.yml`).

## Last session

Session 4: wrote all three scripts in `openclaw/scripts/`.

- **`install.sh`**: idempotent Node 22+ install (skips if already >= 22), then the OpenClaw official installer. Doc 2 says "review the fetched script before executing" — that instruction is a one-time human action and can't literally happen on every automated run, so it's operationalized as a **pinned SHA-256 checksum gate**: the script refuses to run the installer at all until a `openclaw-install.sha256` file exists next to it (created by a human who fetched, read, and hashed the real installer once), and refuses again if a re-fetch's hash ever stops matching the pinned value. That file does not exist yet — creating it is a manual step for whenever this is first run for real against openclaw.ai's actual installer.
- **`configure.sh`**: renders `openclaw/config/openclaw.json.tmpl` into `~/.openclaw/openclaw.json` and copies `agent.md` alongside it. Idempotent (regenerates deterministically from template + env every run, no accumulation). Requires `OPENCLAW_ANTHROPIC_KEY` and `TELEGRAM_BOT_TOKEN` env vars (fails loudly if unset). Defaults: workspace `~/openclaw-workspace`, model `claude-haiku-4-5-20251001` (cheap/fast per doc 2 Phase 2), tool allowlist stays at the template's minimal set — widening it is explicitly a manual template edit, never something this script does.
- **`healthcheck.sh`**: thin, read-only wrapper around `openclaw doctor`, exit-code driven for use by both `healthcheck.yml` (Session 8) and manual/cron checks.

Fleshed out `openclaw/config/openclaw.json.tmpl` with real content (workspace path, `agents` list with one entry per the Extensibility notes, model, `tool_allowlist: [web_search, file_read, file_write]`, `consent_mode: true`, Telegram channel block) instead of leaving it as a Session 5 placeholder — same lesson as Sessions 2–3: writing a consumer script (`configure.sh`) against an empty placeholder template would just mean redoing the wiring in Session 5. `agent.md` (the persona file) is untouched and remains the Session 1 placeholder; nothing depended on its actual content this session.

Installed shellcheck locally (via winget) and ran it against all three scripts: clean except one intentional `SC2016` (single-quoted `${VAR}` tokens passed to `envsubst`'s variable-list argument, which must stay unexpanded) — suppressed with a documented `# shellcheck disable=SC2016` comment rather than silently ignored. Cross-checked all three scripts against doc 2 Phases 2–4 line by line — no gaps found.

## Blockers

None currently.

## Honest gaps (flagged, not glossed over)

- **The `openclaw.json.tmpl` field names/schema are a best-effort mapping, not verified against real OpenClaw product docs.** `tool_allowlist`, `anthropic_api_key_env`, `persona_file`, `consent_mode`, `channels.telegram.bot_token_env` are inferred from what `openclaw-iac-automation-plan.md` and `openclaw-isolated-setup-plan.md` describe in prose, not from an actual OpenClaw CLI/config reference (none was available to check against). Before this is ever run against a real OpenClaw install, these field names need checking against whatever `openclaw onboard` / the real config schema actually expects, and adjusted if they don't match.
- `install.sh`'s checksum-pinning step has never been exercised against the real `https://openclaw.ai/install.sh` (no live box, and this session had no way to fetch and review it) — the *mechanism* is verified (shellcheck, logic review), the *pin* itself doesn't exist yet.
- As before: real execution of any of these three scripts requires a live droplet — still deferred to the user's own later `terraform apply`.

## Next session

Write `openclaw/config/agent.md` (the OpenClaw persona/system-prompt file) — the one remaining piece of Session 5. Then Session 6: wrap Terraform init/plan/apply + cloud-init + scripts into `provision.yml`, with `apply` gated behind manual `workflow_dispatch` only.

## Open decisions (resolved)

- ~~Terraform state backend~~ — resolved: HCP Terraform, org `FlyingThunderWolfDesign`, workspace `molted-magic-openclaw`, execution mode: local.
