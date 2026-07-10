# Progress

Read this first. Dynamic — updated at the end of every session. See [`ROADMAP.md`](ROADMAP.md) for the static full sequence.

## Current phase

Session 3 (cloud-init hardening + Tailscale) — complete. Next up: Session 4 (install.sh / configure.sh / healthcheck.sh).

## Last session

Session 3: wrote real content for `openclaw/cloud-init/user-data.yml.tmpl` — non-root admin user (`openclaw-admin` by default) with sudo, root login and password auth disabled, ufw allowing SSH only (deny incoming / allow outgoing by default), unattended-upgrades enabled, Tailscale installed and joined via `tailscale up --authkey` (skipped if the auth key variable is empty rather than run with an empty key).

Resolved the carry-forward item from Session 2: `main.tf`'s `templatefile()` reference to the sibling `../cloud-init/` directory failed under HCP Terraform's default `remote` execution mode (confirmed by testing). Fixed by switching the `molted-magic-openclaw` workspace to **local execution mode** via the HCP Terraform API — state still lives in HCP Terraform (locking, history), but `plan`/`apply` now compute wherever `terraform` is invoked, which has the full repo checked out. This is documented in a comment in `backend.tf` so a future session doesn't flip it back to `remote` without also fixing the directory reference. This also better fits how `provision.yml` (Session 6) will need to chain Terraform outputs straight into an SSH step.

Added two new Terraform variables: `admin_ssh_public_key` (not secret, but templated rather than hardcoded — DigitalOcean's `ssh_keys` droplet attribute only targets root, so the cloud-init-created non-root admin user needs its own explicit key) and `tailscale_authkey` (sensitive, default `""`, sourced via `TF_VAR_tailscale_authkey`).

Verified for real: `terraform validate` passed; `terraform plan` (using a local, gitignored, dummy `terraform.tfvars` — fake SSH key fingerprint and public key, TEST-NET-3 example IP, deleted after the run) came back clean, still 3 to add / 0 change / 0 destroy. Used `terraform console` to render the actual cloud-init output with the template variables substituted and reviewed it line-by-line against doc 2 Phase 1's checklist (non-root user, SSH-key-only, ufw, unattended-upgrades, Tailscale) — all present and correctly rendered. One early bug caught this way: an explanatory comment in the template itself contained literal `${...}` text, which `templatefile()` tried to parse as an expression and errored on — fixed by rewording the comment.

## Blockers

None currently.

## Honest gaps (flagged, not glossed over)

- No `cloud-init schema` validator or Python/PyYAML available locally, so the cloud-init YAML was checked by rendering + manual line-by-line review against the doc 2 checklist, not a formal schema lint.
- Tailscale actually joining the tailnet, and the non-root user actually being reachable over SSH, can't be proven without a live droplet boot — this remains deferred to the user's own later `terraform apply`.

## Next session

Session 4: write `openclaw/scripts/install.sh` (Node 22+, OpenClaw official installer — reviewed, not blind-piped), `configure.sh` (narrow workspace dir, cheap default model, minimal tool allowlist, Telegram/BotFather channel wiring), and `healthcheck.sh` (wraps `openclaw doctor`, exit-code driven). Verify via shellcheck + manual cross-check against doc 2 Phases 2–4; real execution is deferred to a live box.

## Open decisions (resolved)

- ~~Terraform state backend~~ — resolved: HCP Terraform, org `FlyingThunderWolfDesign`, workspace `molted-magic-openclaw`, **execution mode: local** (changed from the HCP default of `remote` in Session 3 — see `backend.tf` comment for why).
