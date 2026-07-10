# Progress

Read this first. Dynamic — updated at the end of every session. See [`ROADMAP.md`](ROADMAP.md) for the static full sequence.

## Current phase

Session 7 (`destroy.yml`) — complete. Next up: Session 8 (`update.yml` + `healthcheck.yml`) — the last session in the current roadmap before the repo is feature-complete for this plan.

## Last session

Wrote `.github/workflows/destroy.yml`:

- `workflow_dispatch` only, with a required `confirm` input. The description tells the user to type exactly `"destroy"`.
- A guard step (`Verify confirmation phrase`) runs first and fails loudly with `::error::` if `inputs.confirm != 'destroy'` — deliberately a **failed step with a clear message**, not a job-level `if:` that would silently show as "skipped." Every later step is unconditional, relying on GitHub Actions' default behavior of stopping a job after a failed step.
- Then: checkout, `hashicorp/setup-terraform`, `terraform init`, `terraform destroy -auto-approve`, and a `$GITHUB_STEP_SUMMARY` write-up noting that HCP Terraform state persists so a later `provision.yml` run starts clean.

This is the second gate beyond `workflow_dispatch` alone — matches `provision.yml`'s `terraform_action` choice-input pattern from Session 6, applied here as a typed phrase instead of a dropdown since there's only one destructive action this workflow does.

**Verified for real**: `actionlint` clean. Confirmed the `on:` block has no `push`/`pull_request`/`schedule` trigger — manual-only, matching `CLAUDE.md`'s "destroy.yml stays separate and manually-triggered" guardrail. Learned from Session 6's case-mismatch bug: explicitly diffed this workflow's `env:` block secret/variable references against `provision.yml`'s (already-verified-correct) block character-for-character before committing, rather than re-typing them from memory and risking the same class of bug again.

## Blockers

None.

## Honest gaps (carried forward, still open)

- Neither `provision.yml`'s `deploy` job nor `destroy.yml` has run against real infrastructure yet — both reviewed carefully but unverified end-to-end, deferred to the user's own later, deliberate triggers.
- `openclaw.json.tmpl`'s field names are still an unverified best-effort mapping from the planning docs' prose.
- `install.sh`'s pinned-checksum file for the real installer still doesn't exist.
- `TF_VAR_admin_ip_cidrs` repository variable still needs to be added before any real `plan`/`apply`/`destroy` run in CI (flagged in Session 6, still open).

## Next session

Session 8 (last in the current roadmap): `update.yml` (SSH in, `git pull`, re-run `configure.sh`, restart the daemon) and `healthcheck.yml` (scheduled `healthcheck.sh` run, read-only). After that, the repo is feature-complete for this plan — the Moltbook research workstream remains open-ended/parallel, and the first real `terraform apply` stays the user's own later action.

## Open decisions (resolved)

- ~~Terraform state backend~~ — resolved: HCP Terraform, org `FlyingThunderWolfDesign`, workspace `molted-magic-openclaw`, execution mode: local.
- ~~SSH key provisioning~~ — resolved: Terraform registers it directly via `digitalocean_ssh_key.admin`, no manual DO upload step.
- ~~GitHub secrets: repo-level vs environment-level~~ — resolved: repository secrets, no environment protection rules for now.
