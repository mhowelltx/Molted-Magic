# Progress

Read this first. Dynamic — updated at the end of every session. See [`ROADMAP.md`](ROADMAP.md) for the static full sequence.

## Current phase

Session 5.5 (GitHub Actions secrets prep) — code/keypair side done, waiting on the user to actually add the secrets to GitHub before Session 6 (`provision.yml`) can be meaningfully tested end-to-end.

## Last session

Before wiring `provision.yml`, took stock of what GitHub Actions secrets it will need and simplified one manual step out of the picture first:

- Added `digitalocean_ssh_key.admin` to `openclaw/terraform/main.tf`, sourced from `var.admin_ssh_public_key`. Terraform now registers the admin key with DigitalOcean directly — removed the old `ssh_key_id` variable and the manual "upload the key, find its fingerprint/ID" step entirely. `admin_ssh_public_key` now does double duty: DO account registration *and* the non-root cloud-init user's `ssh_authorized_keys`.
- Generated a dedicated ed25519 deploy keypair at `~/.ssh/molted-magic-deploy` (private) / `.pub` (public) — this machine only, never committed. This is the key `provision.yml` will eventually use (as a GitHub secret) to SSH into the freshly-created droplet and run `install.sh`/`configure.sh`.
- Verified for real: `terraform validate`/`plan` with the actual generated public key (not a fake one, but no `apply` — safe, since plan doesn't create anything). Clean: 4 to add (droplet, firewall, VPC, ssh_key), 0 change/destroy.
- Updated `.env.example` to match: `TF_TOKEN_app_terraform_io` (resolved — HCP Terraform, not the old undecided Spaces-vs-TFC placeholder), `TF_VAR_admin_ssh_public_key` (replaces `TF_VAR_ssh_key_id`), added `SSH_DEPLOY_PRIVATE_KEY`.

## GitHub repo secrets still needed (user action — not done by this session)

Per `CLAUDE.md`'s guardrail, these get added by the user via GitHub repo Settings → Secrets and variables → Actions, not by Claude Code calling `gh secret set` or the API on the user's behalf, even though the values were available locally. `gh` CLI isn't installed either, so the web UI is the path.

**Secrets** (Settings → Secrets and variables → Actions → **Secrets** tab → New repository secret):

| Name | Value | Notes |
|---|---|---|
| `DIGITALOCEAN_TOKEN` | Your DO API token | Same one already set locally via `setx TF_VAR_do_token` |
| `TF_TOKEN_app_terraform_io` | Your HCP Terraform user API token | Same one already set locally |
| `SSH_DEPLOY_PRIVATE_KEY` | Contents of `~/.ssh/molted-magic-deploy` (the private key file, whole contents including `-----BEGIN...-----`/`-----END...-----` lines) | View/copy it yourself locally — don't paste it into chat with Claude Code |
| `TELEGRAM_BOT_TOKEN` | Token from @BotFather | Not yet generated — doc 2 Phase 3 |
| `OPENCLAW_ANTHROPIC_KEY` | A **separate, spend-capped** Anthropic API key | Not yet generated — never the main/personal key |
| `TF_VAR_tailscale_authkey` | A Tailscale auth key | Optional for now — cloud-init skips the join gracefully if unset. Can add later, before the first real `apply`. |

**Variable** (Settings → Secrets and variables → Actions → **Variables** tab — not secret, so it belongs here, not in Secrets):

| Name | Value |
|---|---|
| `TF_VAR_admin_ssh_public_key` | Contents of `~/.ssh/molted-magic-deploy.pub` (one line, safe to view/paste — it's a public key) |

Once these exist, tell me they're added (no need to tell me the values) and Session 6 can wire `provision.yml` to actually reference them by name.

## Blockers

Waiting on the user to add the secrets above before Session 6's `provision.yml` can be tested against real GitHub Actions (writing the workflow YAML itself doesn't block on this, but a meaningful dry run of it does).

## Honest gaps (carried forward, still open)

- `openclaw.json.tmpl`'s field names are still an unverified best-effort mapping from the planning docs' prose (see Session 4 notes).
- `install.sh`'s pinned-checksum file for the real installer still doesn't exist.
- Real execution still requires a live droplet — deferred to the user's own later `terraform apply`.

## Next session

Once secrets are added: Session 6, `.github/workflows/provision.yml` — wrap `terraform init/plan/apply` + SSH deploy (using `SSH_DEPLOY_PRIVATE_KEY`) + `install.sh`/`configure.sh` into one workflow, `apply` gated behind manual `workflow_dispatch` only, never on push.

## Open decisions (resolved)

- ~~Terraform state backend~~ — resolved: HCP Terraform, org `FlyingThunderWolfDesign`, workspace `molted-magic-openclaw`, execution mode: local.
- ~~SSH key provisioning~~ — resolved: Terraform registers it directly via `digitalocean_ssh_key.admin`, no manual DO upload step.
