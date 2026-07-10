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

## Session 5.5 — GitHub Actions secrets prep (unplanned, inserted before Session 6)

- [x] Simplified Terraform: added `digitalocean_ssh_key.admin` resource so Terraform registers the admin SSH key directly from `var.admin_ssh_public_key` — removed the old `ssh_key_id` variable and the manual "upload to DO, find the ID" step entirely
- [x] Generated a dedicated ed25519 deploy keypair locally at `~/.ssh/molted-magic-deploy` (private key never leaves this machine / never committed)
- [x] Verified with real `terraform validate`/`plan` using the actual generated public key (clean: 4 to add — droplet, firewall, VPC, ssh_key — 0 change/destroy, no apply)
- [x] Updated `.env.example` to the resolved names (HCP Terraform instead of the undecided Spaces-vs-TFC choice, `TF_VAR_admin_ssh_public_key` instead of `TF_VAR_ssh_key_id`, added `SSH_DEPLOY_PRIVATE_KEY`)
- [x] User added the secrets/variable to the GitHub repo as **repository secrets** (decided against environment secrets/required-reviewer gate for now — `workflow_dispatch` is enough): `DIGITALOCEAN_TOKEN`, `TF_TOKEN_app_terraform_io`, `SSH_DEPLOY_PRIVATE_KEY`, `OPENCLAW_ANTHROPIC_KEY`, and variable `TF_VAR_admin_ssh_public_key`. `TELEGRAM_BOT_TOKEN`/`TF_VAR_tailscale_authkey` intentionally left unset.
- [x] Relaxed `configure.sh`'s hard requirement on `TELEGRAM_BOT_TOKEN` to a warning (it never needed the value at render time, only the env var *name* is written into config) — re-verified with shellcheck + a scratch end-to-end run with the token unset

## Session 6 — provision.yml

- [x] Wrapped Terraform init/validate/plan/apply + wait-for-SSH + `install.sh`/`configure.sh`/`healthcheck.sh` into `.github/workflows/provision.yml` (two jobs: `terraform`, then `deploy` gated on `needs: terraform` + apply having actually run)
- [x] `apply` gated behind a `workflow_dispatch` choice input (`terraform_action`, default `plan`) — the entire workflow has no push/pull_request/schedule trigger at all, not just the apply step
- [x] Added sensible non-secret defaults for `region`/`droplet_size` in `variables.tf` (`nyc3` / `s-2vcpu-2gb`) so fewer GH Actions variables are required; `admin_ip_cidrs` deliberately kept with no default (security-sensitive, fails closed if unset)
- [x] Verify: installed `actionlint` locally, ran it for real — clean (one intentional `SC2087` suppressed with a documented disable comment: client-side heredoc expansion of escaped secrets is intentional here, not the usual footgun). Caught and fixed a real bug this way: the workflow referenced `TF_VAR_ADMIN_SSH_PUBLIC_KEY`/`TF_VAR_TAILSCALE_AUTHKEY` in uppercase, but the actual GitHub secret/variable names set up in Session 5.5 are mixed-case (`TF_VAR_admin_ssh_public_key`, `TF_VAR_tailscale_authkey`) — GitHub secret/variable lookups are case-sensitive, so this would have silently resolved to empty strings at runtime. Fixed to match exactly.
- [ ] **New requirement surfaced**: a `TF_VAR_admin_ip_cidrs` repository **variable** (not secret) is now needed — no default exists for it by design, so `terraform plan`/`apply` in CI will fail until the user adds it. Not a blocker for this session's work, but needed before a real CI run.
- [ ] **Not yet verified live**: the `deploy` job (wait-for-SSH, scp, remote install/configure, healthcheck) has no droplet to run against yet, so it's reviewed carefully (quoting, secret handling via `printf %q` + stdin heredoc instead of command-line args) but not exercised end-to-end. Deferred to the user's own later `terraform apply`.

## Session 7 — destroy.yml

- [x] Separate, manually-triggered workflow (`.github/workflows/destroy.yml`), no shared triggers with `provision.yml` — its own `workflow_dispatch` only, nothing else
- [x] Added a second safety gate beyond `workflow_dispatch` itself: a required `confirm` input that must exactly equal `"destroy"`, checked by an explicit guard step that fails loudly (`::error::` + non-zero exit) rather than silently skipping the job if it doesn't match
- [x] Verify: `actionlint` clean; confirmed the `on:` block has no `push`/`pull_request`/`schedule` trigger at all; cross-checked the `env:` block's secret/variable names character-for-character against `provision.yml`'s (already-verified-correct) block to avoid repeating the case-mismatch bug from Session 6

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
