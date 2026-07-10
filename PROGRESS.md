# Progress

Read this first. Dynamic — updated at the end of every session. See [`ROADMAP.md`](ROADMAP.md) for the static full sequence.

## Current phase

Session 6 (`provision.yml`) — complete. One new GitHub Actions variable is needed before this can run for real in CI (see below). Next up: Session 7 (`destroy.yml`).

## Last session

Wrote `.github/workflows/provision.yml`:

- **`terraform` job**: checkout, `hashicorp/setup-terraform`, `init`/`validate`/`plan -out=tfplan`, then `apply` — but only `if: inputs.terraform_action == 'apply'`. The `workflow_dispatch` input defaults to `plan`, so a run triggered without deliberately changing that choice never touches real infrastructure. The workflow has no `push`/`pull_request`/`schedule` trigger at all — the whole thing is manual-only, not just the apply step.
- **`deploy` job**: `needs: terraform`, same `if: apply` gate. Writes the deploy private key from `SSH_DEPLOY_PRIVATE_KEY`, polls for SSH (30 attempts, 10s apart), `scp`s `openclaw/scripts` and `openclaw/config` to the droplet, then runs `install.sh` and `configure.sh` remotely — with `OPENCLAW_ANTHROPIC_KEY`/`TELEGRAM_BOT_TOKEN` shell-escaped via `printf %q` and piped over an SSH stdin heredoc rather than passed as command-line arguments (avoids either end's `ps aux` exposing them). Finishes with a read-only `healthcheck.sh` call and a `$GITHUB_STEP_SUMMARY` write-up.
- Added non-secret defaults to `openclaw/terraform/variables.tf`: `region = "nyc3"`, `droplet_size = "s-2vcpu-2gb"`. Deliberately did **not** default `admin_ip_cidrs` — it's security-sensitive (controls SSH ingress) and should fail loudly if unset rather than silently default to something open.

**Verified for real**: installed `actionlint` (via winget) and ran it against the workflow — clean, with one intentional `SC2087` (shellcheck-via-actionlint) suppressed via a documented disable comment, since client-side expansion of the escaped secrets into the heredoc is the actual intended behavior there, not the usual mistake that rule warns about.

**Caught a real bug this way, not hypothetically**: the workflow referenced `TF_VAR_ADMIN_SSH_PUBLIC_KEY` and `TF_VAR_TAILSCALE_AUTHKEY` in all-caps, but the actual GitHub secret/variable names set up in Session 5.5 are mixed-case — `TF_VAR_admin_ssh_public_key` (variable) and `TF_VAR_tailscale_authkey` (secret). GitHub's `secrets.X`/`vars.X` lookups are case-sensitive, so this mismatch would have silently resolved to empty strings at runtime instead of erroring — actionlint can't catch this class of bug since it has no visibility into the actual repo's configured secrets, so it was caught by manually cross-checking against what was actually asked of the user in the Session 5.5 conversation. Fixed to match exactly.

## New GitHub repo variable needed (user action)

| Name | Where | Value |
|---|---|---|
| `TF_VAR_admin_ip_cidrs` | Settings → Secrets and variables → Actions → **Variables** tab | Your admin IP(s) in CIDR form, e.g. `["203.0.113.5/32"]` — or a Tailscale-assigned range once Tailscale is set up. No default exists on purpose (security-sensitive — should fail loudly if forgotten, not silently allow SSH from everywhere). |

Not urgent — nothing runs it for real until you trigger `provision.yml` yourself.

## Blockers

None for continuing to Session 7. The variable above only blocks an actual `terraform plan`/`apply` run of `provision.yml` in CI, not further scaffolding work.

## Honest gaps (flagged, not glossed over)

- **The `deploy` job has never run against a real droplet.** Careful review went into the SSH retry loop, `scp` paths, and secret-escaping approach, but none of it has been exercised end-to-end — that requires an actual `apply`, still deferred to the user's own later, deliberate trigger.
- Carried forward: `openclaw.json.tmpl`'s field names are still an unverified best-effort mapping from the planning docs' prose; `install.sh`'s pinned-checksum file for the real installer still doesn't exist.

## Next session

Session 7: `.github/workflows/destroy.yml` — `terraform destroy`, manually-triggered only (`workflow_dispatch`, no shared triggers with `provision.yml`), and should probably require typing a confirmation phrase as a `workflow_dispatch` input (similar spirit to `provision.yml`'s `terraform_action` choice) given how destructive this one is.

## Open decisions (resolved)

- ~~Terraform state backend~~ — resolved: HCP Terraform, org `FlyingThunderWolfDesign`, workspace `molted-magic-openclaw`, execution mode: local.
- ~~SSH key provisioning~~ — resolved: Terraform registers it directly via `digitalocean_ssh_key.admin`, no manual DO upload step.
- ~~GitHub secrets: repo-level vs environment-level~~ — resolved: repository secrets, no environment protection rules for now.
