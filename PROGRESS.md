# Progress

Read this first. Dynamic — updated at the end of every session. See [`ROADMAP.md`](ROADMAP.md) for the static full sequence.

## Current phase

Session 10 (Moltbook research write-up) — complete. Next up: Session 11 (`CLAUDE.md`/`agent.md` updates authorizing the integration).

## Context: new plan direction

After Session 8, all 8 original sessions were done but no real `terraform apply` had ever run. The user then asked for a plan to reach "an agent connected to Moltbook, running from the VPS." That plan (approved, 8 new sessions: 9–16) is now underway. Full plan detail lives in the approved plan file; this doc tracks what's actually been done.

## Last session — Session 10 (Moltbook research write-up)

Populated `moltbook/notes/registration-flow.md`, `notes/api-endpoints.md`, `notes/heartbeat-and-rate-limits.md`, `findings.md`, and `open-questions.md` with the real Moltbook research gathered during planning (multiple consistent `WebFetch` reads of `moltbook.com/skill.md` and `/heartbeat.md` — internally consistent, unlike the unrelated `openclaw.ai` research that prompted Session 9).

Resolved the one open question flagged during planning: exactly how Moltbook confirms the human-ownership tweet. A closer read of `skill.md` surfaced it — registration returns a `claim_url` for the human (who verifies their email there, then posts the tweet); the agent polls `GET /api/v1/agents/status` for `"pending_claim"` → `"claimed"`. No tweet text/format is documented (presumably shown on the claim page itself) — noted as a smaller remaining open item for `register.js` (Session 12) to handle by directing the human to the claim URL rather than guessing at wording.

Verify: `grep -r moltbook openclaw/` confirmed zero references from `openclaw/` into the top-level research-only `moltbook/`, consistent with `CLAUDE.md`'s boundary (the deployed client will live at `openclaw/moltbook/`, a separate path, in Session 12). Removed `moltbook/notes/.gitkeep` now that real files exist there.

## Prior session — Session 9 (real local ground truth on OpenClaw's CLI/config schema)

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

## Honest gaps remaining (real, not guessed at)

- `daemon install`'s actual service-install behavior (launchd/systemd/schtasks) has still never run on a real Linux box — the command is confirmed real, its live behavior isn't.
- The exact CLI for triggering a single scheduled agent turn (for Session 14's heartbeat) wasn't determined — `agents.defaults.heartbeat.prompt`/`target` look like the right config-side mechanism (confirmed schema), but how/whether to *also* trigger an ad-hoc turn outside the heartbeat's own schedule (e.g. for testing) hasn't been explored. Deferred to Session 14/16.
- Real MCP tool-registration mechanics (`mcp.servers`) are schema-confirmed but never actually exercised end-to-end — deferred to Session 12.
- Exact tweet text/format for Moltbook's ownership verification isn't documented (presumably shown on the claim page) — `register.js` (Session 12) should direct the human there rather than guess.
- Exact upvote/downvote endpoint paths for comments vs. posts aren't fully disambiguated in Moltbook's prose docs — verify with a real authenticated call in Session 12, don't guess further from documentation.
- Everything that was already only-provable-live stays that way: real droplet health, Tailscale join, actual `install.sh` execution on Ubuntu, real DigitalOcean spend.

## Next session

Session 11: rewrite `CLAUDE.md`'s "Moltbook boundary" from research-only to narrowly-scoped authorization, and add a Moltbook section to `openclaw/config/agent.md` naming it as the one specific, named exception to the no-fetch-and-execute rule (full autonomy on Moltbook actions specifically, everything else stays under the existing consent posture).

## Open decisions (resolved)

- ~~Terraform state backend~~ — resolved: HCP Terraform, org `FlyingThunderWolfDesign`, workspace `molted-magic-openclaw`, execution mode: local.
- ~~SSH key provisioning~~ — resolved: Terraform registers it directly via `digitalocean_ssh_key.admin`, no manual DO upload step.
- ~~GitHub secrets: repo-level vs environment-level~~ — resolved: repository secrets, no environment protection rules for now.
- ~~OpenClaw config/CLI schema~~ — resolved for real via Session 9's local verification. Remaining unknowns are narrow and named, not a blanket "unverified" flag anymore.
- ~~How Moltbook confirms human-ownership~~ — resolved via Session 10: `claim_url` + polling `/api/v1/agents/status`.
