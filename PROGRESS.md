# Progress

Read this first. Dynamic — updated at the end of every session. See [`ROADMAP.md`](ROADMAP.md) for the static full sequence.

## Current phase

Session 5.5 (GitHub Actions secrets prep) — complete. Repository secrets/variables added by the user: `DIGITALOCEAN_TOKEN`, `TF_TOKEN_app_terraform_io`, `SSH_DEPLOY_PRIVATE_KEY`, `OPENCLAW_ANTHROPIC_KEY`, and the `TF_VAR_admin_ssh_public_key` variable. `TELEGRAM_BOT_TOKEN` and `TF_VAR_tailscale_authkey` are intentionally not set yet — both are now genuinely optional (see below), not blockers. Next up: Session 6 (`provision.yml`).

## Last session

Continued Session 5.5: the user confirmed which secrets they had real values for and which they didn't (`TELEGRAM_BOT_TOKEN`, `TF_VAR_tailscale_authkey` — no values yet). `tailscale_authkey` was already designed to be optional (cloud-init skips the join gracefully if empty), but `configure.sh` still had a hard `: "${TELEGRAM_BOT_TOKEN:?...}"` guard that would abort if it were unset — a real gap surfaced by the user's actual state, not a hypothetical.

Fixed: relaxed that guard to a warning. This was safe to do because the rendered `openclaw.json` only ever names the env var OpenClaw should read the token from (`channels.telegram.bot_token_env`), never the token value itself — there was nothing that actually needed the value at render time, so requiring it was stricter than necessary. Now, if `TELEGRAM_BOT_TOKEN` is unset, `configure.sh` logs a warning and continues (the daemon just won't be able to authenticate the Telegram channel until a real token is added later).

Verified for real: shellcheck clean, and re-ran the scratch-directory end-to-end test from Session 5 with `TELEGRAM_BOT_TOKEN` deliberately unset — confirmed it warns and completes with exit code 0 rather than aborting.

Also clarified with the user: GitHub Actions secrets added are **repository secrets**, not environment secrets (environment secrets would add a required-reviewer approval gate on top of `workflow_dispatch` — decided against it for now; `workflow_dispatch`'s manual trigger is enough).

## Blockers

None. `TELEGRAM_BOT_TOKEN` and `TF_VAR_tailscale_authkey` remaining unset is expected and handled gracefully, not a blocker.

## Honest gaps (carried forward, still open)

- `openclaw.json.tmpl`'s field names are still an unverified best-effort mapping from the planning docs' prose (see Session 4 notes).
- `install.sh`'s pinned-checksum file for the real installer still doesn't exist.
- Real execution still requires a live droplet — deferred to the user's own later `terraform apply`.
- Telegram channel and Tailscale join are both configured-but-inert until their real values are eventually added as GitHub secrets — expected, not a defect.

## Next session

Session 6: `.github/workflows/provision.yml` — wrap `terraform init/plan/apply` + SSH deploy (using `SSH_DEPLOY_PRIVATE_KEY`) + `install.sh`/`configure.sh` into one workflow, `apply` gated behind manual `workflow_dispatch` only, never on push. Secrets it can now reference by name: `DIGITALOCEAN_TOKEN`, `TF_TOKEN_app_terraform_io`, `SSH_DEPLOY_PRIVATE_KEY`, `OPENCLAW_ANTHROPIC_KEY`, and the `TF_VAR_admin_ssh_public_key` variable. `TELEGRAM_BOT_TOKEN`/`TF_VAR_tailscale_authkey` can be referenced too (will just be empty until added — both degrade gracefully).

## Open decisions (resolved)

- ~~Terraform state backend~~ — resolved: HCP Terraform, org `FlyingThunderWolfDesign`, workspace `molted-magic-openclaw`, execution mode: local.
- ~~SSH key provisioning~~ — resolved: Terraform registers it directly via `digitalocean_ssh_key.admin`, no manual DO upload step.
- ~~GitHub secrets: repo-level vs environment-level~~ — resolved: repository secrets, no environment protection rules for now.
