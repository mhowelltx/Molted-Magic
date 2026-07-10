# Progress

Read this first. Dynamic — updated at the end of every session. See [`ROADMAP.md`](ROADMAP.md) for the static full sequence.

## Current phase

Session 9 (real local ground truth on OpenClaw's CLI/config schema) — complete, and it was a significant, valuable detour. Next up: Session 10 (Moltbook research write-up).

## Context: new plan direction

After Session 8, all 8 original sessions were done but no real `terraform apply` had ever run. The user then asked for a plan to reach "an agent connected to Moltbook, running from the VPS." That plan (approved, 8 new sessions: 9–16) is now underway. Full plan detail lives in the approved plan file; this doc tracks what's actually been done.

## Last session — Session 9 (a bigger deal than originally scoped)

The original plan explicitly said: don't rewrite `openclaw.json.tmpl`/`configure.sh` based on unreliable web research — keep them as an unverified best-effort mapping. Then, mid-session, the user asked a better question: **what can we do *locally* to confirm the config before ever deploying to the cloud?** That reframing turned into Session 9.

**What happened, concretely:**
1. Installed Node.js locally via winget (this machine had none of Node/npm/WSL2/Docker before this).
2. Ran `npm view openclaw` — real, structured npm registry data (not a webpage summary): `openclaw@2026.6.11`, "Multi-channel AI gateway with extensible messaging integrations," real GitHub repo (`github.com/openclaw/openclaw`), real maintainers, published a week ago by GitHub Actions CI. This alone was far more trustworthy than the marketing-site fetches from earlier in the planning conversation.
3. Installed the real package into a scratch directory (not global, nothing added to this repo or committed) and ran the actual CLI: `openclaw --help`, `openclaw config --help`, `openclaw config schema` (a real, complete 2.2MB JSON Schema for `openclaw.json`), and `openclaw config validate`.
4. **This settled, for real, several things that were previously flagged as "unverified best-effort mappings" since Session 4:**
   - `agents` is `{defaults: {...}, list: [...]}`, not a flat array. List items use `id`/`name`/`workspace`/`model` — no `persona_file`, no `anthropic_api_key_env`.
   - Model is a `"provider/model"` string (e.g. `"anthropic/claude-haiku-4-5-20251001"`), confirmed via schema.
   - Secrets use a real `SecretRef` shape: `{"source": "env", "provider": "default", "id": "ENV_VAR_NAME"}` — confirmed for both `channels.telegram.botToken` and `models.providers.anthropic.apiKey`.
   - There is no per-agent `tool_allowlist`. Real mechanism: top-level `tools.profile` (a real enum: `"minimal"|"coding"|"messaging"|"full"`) plus fine-grained toggles — `tools.web.search.enabled` and `tools.fs.workspaceOnly` map cleanly onto exactly what was wanted ("web search + file read/write within the workspace only"), more cleanly than the old made-up array ever did.
   - There's no `persona_file` config key. Persona is delivered via a **workspace bootstrap file** — the schema's `agents.defaults.skipOptionalBootstrapFiles` enum lists the real convention: `SOUL.md`, `USER.md`, `HEARTBEAT.md`, `IDENTITY.md`. `agent.md`'s content is unaffected; only its delivery path changed (workspace `SOUL.md` instead of copied into the config dir).
   - **The one thing Session 8 already had right**: `daemon install`/`daemon status`/`daemon restart` are real commands — confirmed via `openclaw --help` as a legacy alias for `gateway` service management. No change needed there.
   - Also confirmed real (for later sessions): `mcp.servers.<name>.{command, args, env, cwd, url, transport}` (Session 12's Moltbook client can be wired in this way), and the full `agents.defaults.heartbeat` schema — `every`, `prompt`, `target`, `to`, `directPolicy`, `isolatedSession`, `skipWhenBusy`, `timeoutSeconds` all confirmed, resolving what was flagged as Session 14's biggest open question.
5. Rewrote `openclaw/config/openclaw.json.tmpl` and `openclaw/scripts/configure.sh` to match. Added an `openclaw config validate` call before restarting the gateway in `configure.sh`, so a bad config now fails loudly instead of restarting into a broken state.
6. **Verified for real, not just reviewed**: ran `openclaw config validate --json` against the *old* template shape first — confirmed `"valid": false` (`agents: "Invalid input"`) — real proof it would have failed to boot the real gateway on a live box. Then validated the *new* shape — `"valid": true`. Then ran `configure.sh` itself end-to-end (scratch directory, dummy env vars, no CLI on PATH — same pattern as Sessions 4–5) and fed its actual rendered `openclaw.json` output through real validation too — also `"valid": true`. `shellcheck` clean on the updated `configure.sh`.
7. Cleaned up all scratch artifacts (test npm install, test config profile) — nothing left behind outside the repo.

**Why this matters beyond just this session**: this is the first time in the project that OpenClaw's actual schema has been checked against the real, installed CLI rather than inferred from planning-doc prose or (unreliable) web research. It resolves several "honest gaps" that had been carried since Session 4 with real evidence instead of more guessing.

## Honest gaps remaining after Session 9 (real, not guessed at)

- `daemon install`'s actual service-install behavior (launchd/systemd/schtasks) has still never run on a real Linux box — the command is confirmed real, its live behavior isn't.
- The exact CLI for triggering a single scheduled agent turn (for Session 14's heartbeat) wasn't determined this session — `agents.defaults.heartbeat.prompt`/`target` look like the right config-side mechanism (confirmed schema), but how/whether to *also* trigger an ad-hoc turn outside the heartbeat's own schedule (e.g. for testing) wasn't explored. Deferred to Session 14/16.
- Real MCP tool-registration mechanics (`mcp.servers`) are schema-confirmed but never actually exercised end-to-end — deferred to Session 12.
- Everything that was already only-provable-live stays that way: real droplet health, Tailscale join, actual `install.sh` execution on Ubuntu, real DigitalOcean spend.

## Next session

Session 10: populate `moltbook/notes/`, `moltbook/findings.md`, `moltbook/open-questions.md` with the real Moltbook API research already gathered earlier in the planning conversation (registration → verify → ownership-tweet flow, full endpoint list, rate limits, `heartbeat.md`'s five-step priority order). Closes the long-pending "Parallel, anytime — Moltbook research" item from the original roadmap.

## Open decisions (resolved)

- ~~Terraform state backend~~ — resolved: HCP Terraform, org `FlyingThunderWolfDesign`, workspace `molted-magic-openclaw`, execution mode: local.
- ~~SSH key provisioning~~ — resolved: Terraform registers it directly via `digitalocean_ssh_key.admin`, no manual DO upload step.
- ~~GitHub secrets: repo-level vs environment-level~~ — resolved: repository secrets, no environment protection rules for now.
- ~~OpenClaw config/CLI schema~~ — resolved for real via Session 9's local verification (see above). Remaining unknowns are narrow and named, not a blanket "unverified" flag anymore.
