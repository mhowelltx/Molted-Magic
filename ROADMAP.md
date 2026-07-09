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
- [ ] **Carried to Session 3**: `main.tf`'s droplet resource does not yet wire `user_data` to the cloud-init template. HCP Terraform's CLI-driven remote runs only upload the `openclaw/terraform` working directory, so a `templatefile()` reference to the sibling `../cloud-init/` path fails remotely (confirmed by testing). Session 3 needs to resolve this — likely nesting cloud-init under `openclaw/terraform/` or otherwise restructuring — before wiring `user_data` in.

## Session 3 — Cloud-init hardening + Tailscale

- [ ] `user-data.yml.tmpl`: non-root user, SSH-key-only sshd, ufw mirroring the DO firewall, unattended-upgrades, Tailscale join
- [ ] Verify: YAML/cloud-init lint + manual checklist against doc 2 Phase 1 (Tailscale join itself can't be proven without a live box)

## Session 4 — install.sh / configure.sh / healthcheck.sh

- [ ] `install.sh`: Node 22+, OpenClaw official installer (reviewed, not blind-piped)
- [ ] `configure.sh`: narrow workspace dir, cheap default model, minimal tool allowlist, Telegram/BotFather channel wiring
- [ ] `healthcheck.sh`: wraps `openclaw doctor`, exit-code driven
- [ ] Verify: shellcheck + manual cross-check against doc 2 Phases 2–4 (real execution deferred to a live box)

## Session 5 — openclaw.json.tmpl + agent.md

- [ ] Config template (model, allowlist shape, workspace path placeholders)
- [ ] Persona/system-prompt file
- [ ] Verify: template renders with example values substituted, matches "cheap model / minimal allowlist / capped separate key" guardrails

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
