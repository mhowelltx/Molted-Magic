# CLAUDE.md

Guardrails for any Claude Code session working in this repo.

## Session continuity

- Read [`PROGRESS.md`](PROGRESS.md) and [`ROADMAP.md`](ROADMAP.md) before doing anything else.
- Update `PROGRESS.md` at the end of every session — what was done, what's next, any new open questions or blockers. This is not optional bookkeeping; it's how the next session avoids re-deriving context.

## Secrets

- Never write a real credential value into any file in this repo — including `.tfvars`, config templates, or scratch files. Secrets are referenced via `${{ secrets.X }}` in workflows or environment variables locally, never inlined.
- The OpenClaw agent's Anthropic API key must be separate and spend-capped from the user's main key. Never reuse or reference the main key.
- If a script or workflow needs a new secret, stop and ask the user to add it via GitHub repo settings (Settings → Secrets and variables → Actions), rather than proposing to hardcode it "temporarily."

## Tool allowlist / agent capability

- Never widen the OpenClaw tool allowlist (shell, browser, messaging, etc.) without the user explicitly asking, in that session, for that specific widening.
- Default new capability additions to off/narrow. The user opts in per-capability, not by default.

## Infra safety

- `terraform destroy` / `destroy.yml` stays a separate, manually-triggered workflow — never folded into `provision.yml` or `update.yml`, and never scheduled.
- `terraform apply` (in a workflow or run locally) is never run against real infrastructure without the user explicitly triggering that specific run. `terraform plan` is expected and fine as a verification step.
- The OpenClaw control UI port must never be exposed publicly. Firewall/cloud-init rules restrict it to Tailscale/private network only — flag any drift toward a public-facing rule rather than applying it.

## Moltbook boundary

- `moltbook/` is research-only. Nothing in it gets wired into `openclaw/` config, scripts, or workflows (no fetch-and-execute-remote-instructions integration) without an explicit, separate user sign-off — this is a distinct, higher-trust decision from standing up base OpenClaw infra.
- If research surfaces something that looks like it should become code, propose it as a new session/entry in `ROADMAP.md` rather than adding it ad hoc.

## Scope

- Build for DigitalOcean. Don't add parallel Hetzner support unless asked.
- Keep `install.sh`/`configure.sh` idempotent — safe to re-run.
- Don't run a real `terraform apply` against a live billed account as part of routine session work — that remains the user's own deliberate, later action.
