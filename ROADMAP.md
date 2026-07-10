# Roadmap

Static build sequence. Check items off as sessions complete; log the details of what actually happened in [`PROGRESS.md`](PROGRESS.md), not here.

## Session 0 — Manual prerequisites (not a Claude Code session)

- [x] Install Git for Windows, confirm `git --version` in a new shell
- [x] `git config --global user.name`, `user.email`, `init.defaultBranch main`
- [x] Create private GitHub remote `Molted-Magic` at github.com/new (no auto-init)
- [x] `git init` + `git remote add origin ...` locally
- [ ] (Optional) install GitHub CLI (`gh`) for `gh secret set` / `gh run watch`

## Session 1 — Repo scaffold

- [x] Full directory structure, placeholder files with one-line purpose notes
- [x] README.md, CLAUDE.md, ROADMAP.md, PROGRESS.md, .gitignore, .env.example
- [x] Initial commit + push

## Session 2 — Terraform: VPS + firewall only

- [x] `main.tf` / `variables.tf` / `outputs.tf` / `network.tf` / `firewall.tf` for a single DO droplet + cloud firewall (SSH-only inbound, no public control-UI port)
- [x] Remote state backend wired in `backend.tf` (HCP Terraform / Terraform Cloud, org `FlyingThunderWolfDesign`, workspace `molted-magic-openclaw`)
- [x] Verify: `terraform init` / `validate` / `plan` clean (3 to add: droplet, firewall, VPC — 0 change, 0 destroy), no apply
- [x] **Carried to Session 3, now resolved**: `main.tf`'s droplet resource now wires `user_data` to the cloud-init template. Fixed by switching the HCP Terraform workspace's execution mode from `remote` to `local` rather than restructuring directories.

## Session 3 — Cloud-init hardening + Tailscale

- [x] `user-data.yml.tmpl`: non-root user, SSH-key-only sshd, ufw mirroring the DO firewall, unattended-upgrades, Tailscale join (skipped if `tailscale_authkey` is empty)
- [x] `user_data` wired into `main.tf`'s droplet resource
- [x] Verify: `terraform validate`/`plan` clean with cloud-init wired in (still 3 to add, 0 change/destroy); rendered actual output via `terraform console` and checked line-by-line against doc 2 Phase 1. No `cloud-init schema` tool or Python available locally for a formal lint — noted as a gap. Tailscale join itself still can't be proven without a live box.

## Session 4 — install.sh / configure.sh / healthcheck.sh

- [x] `install.sh`: Node 22+ (idempotent version check), OpenClaw official installer gated by a pinned SHA-256 checksum (not blind-piped — see PROGRESS.md for why "review before piping" had to become a checksum gate rather than a per-run manual step)
- [x] `configure.sh`: narrow workspace dir, cheap default model (`claude-haiku-4-5-20251001`), minimal tool allowlist, Telegram/BotFather channel wiring, consent mode — all rendered via `openclaw/config/openclaw.json.tmpl` (fleshed out ahead of Session 5, same coupling lesson as Sessions 2–3)
- [x] `healthcheck.sh`: wraps `openclaw doctor`, exit-code driven, read-only
- [x] Verify: shellcheck clean on all three (one intentional SC2016 suppressed with a documented disable comment); manual cross-check against doc 2 Phases 2–4 line by line. Real execution deferred to a live box.

## Session 5 — openclaw.json.tmpl + agent.md

- [x] Config template (model, allowlist shape, workspace path placeholders) — done in Session 4, ahead of schedule, because `configure.sh` needed real content to render meaningfully
- [x] Persona/system-prompt file (`agent.md`) — written as actual operating instructions to the agent (narrow current scope, consent mode, no fetch-and-execute-remote-instructions, long-range vision explicitly marked out of current scope)
- [x] Verify: ran `configure.sh` for real (not just reviewed) against a scratch directory with dummy env vars — `openclaw.json` rendered, parsed as valid JSON, `agent.md` copied byte-for-byte identical to the source, `openclaw` CLI absence handled gracefully. Matches the "cheap model / minimal allowlist / capped separate key" guardrails.

## Session 6 — provision.yml

- [ ] Wrap Terraform init/plan/apply + cloud-init + scripts into one workflow
- [ ] `apply` gated behind manual `workflow_dispatch`, never on push
- [ ] Verify: workflow syntax accepted, `apply` step confirmed unreachable via push/PR

## Session 7 — destroy.yml

- [ ] Separate, manually-triggered workflow, no shared triggers with provision.yml
- [ ] Verify: syntax check, confirm zero automatic triggers

## Session 8 — update.yml + healthcheck.yml

- [ ] `update.yml`: SSH in, `git pull`, re-run `configure.sh`, restart daemon
- [ ] `healthcheck.yml`: scheduled `healthcheck.sh` run
- [ ] Verify: syntax checks, healthcheck reviewed as read-only

## Parallel, anytime — Moltbook research

- [ ] Populate `moltbook/notes/`, `moltbook/findings.md`, `moltbook/open-questions.md`
- [ ] Verify: findings reflect what was actually researched, and `openclaw/` has zero references into `moltbook/`

---

After Session 8, the repo is feature-complete for the current plan. The first real `terraform apply` against a live billed account is the user's own later action, not part of this roadmap.

This sequence merges the build order from the original `openclaw-iac-automation-plan.md` and `openclaw-isolated-setup-plan.md` planning docs. See [`CLAUDE.md`](CLAUDE.md) for the guardrails that apply throughout.
