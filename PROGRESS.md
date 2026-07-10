# Progress

Read this first. Dynamic — updated at the end of every session. See [`ROADMAP.md`](ROADMAP.md) for the static full sequence.

## Current phase

Session 8 (`update.yml` + `healthcheck.yml`) — complete. **All 8 sessions in the current roadmap are now done.** The repo is feature-complete for the plan approved at the start of this project. What's left is either open-ended (Moltbook research) or the user's own deliberate action (the first real `terraform apply`).

## Last session

Before writing `update.yml`, caught and fixed a real gap: doc 1 says `update.yml` should "restart the daemon," and doc 2 Phase 5 says to register OpenClaw as a persistent daemon (`openclaw daemon install`) — but neither `install.sh` nor `configure.sh` ever actually did that. "Restart the daemon" had nothing to act on. Fixed by adding daemon lifecycle logic to `configure.sh` itself (not `install.sh`): checks `openclaw daemon status`, runs `openclaw daemon install` only if not already installed, then always runs `openclaw daemon restart` to pick up the freshly-rendered config. This lives in `configure.sh` because that's the idempotent script that reruns on every `update.yml` pass — putting daemon lifecycle there means `update.yml` doesn't need any separate "restart" step of its own. Re-verified with shellcheck (clean) and the scratch end-to-end test from Sessions 4–5 (still passes — the no-CLI branch is unaffected).

Wrote `.github/workflows/update.yml`: weekly schedule (`0 6 * * 1`) + `workflow_dispatch`. Doc 1 originally described this as "git pull on the box," but no git-clone-on-box mechanism was ever built — `provision.yml` syncs files by `scp`ing them from the runner's checkout instead, so `update.yml` reuses that same approach rather than introducing a second, different sync mechanism. Reads the droplet's current IP from HCP Terraform state via `terraform output` (there's no `apply` step here to chain outputs from directly).

Wrote `.github/workflows/healthcheck.yml`: every 6 hours + `workflow_dispatch`. Runs the already-deployed `healthcheck.sh` remotely — read-only, no re-sync of scripts.

**Real design decision, not just implementation**: both new workflows gracefully no-op (succeed, green) when Terraform state has no droplet yet, rather than failing loudly. Reasoning: no real infrastructure exists yet — that's the actual, expected current state of this project, not a failure condition. Enabling `healthcheck.yml`'s every-6-hours schedule with a "fail if unreachable" design as originally described in doc 1 would have started spamming failure notifications immediately upon merge, long before any real droplet exists. Both workflows still fail loudly once infrastructure genuinely exists and is unreachable or unhealthy — the graceful skip only covers the "nothing provisioned yet" case.

**Verified for real**: `actionlint` clean on both new workflows. After the Session 6 case-mismatch bug, added a habit rather than just a one-off fix: diffed the `env:` block of all four workflows (`provision.yml`, `destroy.yml`, `update.yml`, `healthcheck.yml`) against each other and confirmed all four reference character-for-character identical secret/variable names.

## Where things stand overall

All 8 roadmap sessions are complete:
1. Repo scaffold
2. Terraform (droplet + firewall + VPC + SSH key registration)
3. Cloud-init (hardening + Tailscale)
4. install.sh / configure.sh / healthcheck.sh
5. openclaw.json.tmpl + agent.md
5.5. GitHub Actions secrets
6. provision.yml
7. destroy.yml
8. update.yml + healthcheck.yml

## Honest gaps (the real remaining risk, all previously flagged, none resolved by writing more code)

These are the things that only get resolved by an actual `terraform apply` against a live DigitalOcean account — which stays the user's own deliberate action, not something to do as routine session work:

- `openclaw.json.tmpl`'s field names (`tool_allowlist`, `anthropic_api_key_env`, `persona_file`, `consent_mode`, `channels.telegram.bot_token_env`) and the daemon subcommands added this session (`daemon status`/`daemon install`/`daemon restart`) are all inferred from the two planning docs' prose, never verified against a real OpenClaw CLI/config reference.
- `install.sh`'s pinned-checksum file for the real installer still doesn't exist — one-time human step whenever this first runs for real.
- `provision.yml`'s `deploy` job and `destroy.yml` have never run against real infrastructure.
- `TF_VAR_admin_ip_cidrs` repository variable still isn't set (flagged since Session 6) — blocks any real `plan`/`apply`/`destroy`/`update`/`healthcheck` run in CI until added.
- `TELEGRAM_BOT_TOKEN` and `TF_VAR_tailscale_authkey` still have no real values — both degrade gracefully, not blockers.

## Next session

No forced next step from the roadmap — the IaC side is feature-complete for this plan. Reasonable options, in no particular order: (a) start the Moltbook research workstream (`moltbook/notes/`, `findings.md`, `open-questions.md` — pure reading/writing, no infra risk, can run any time), (b) add the `TF_VAR_admin_ip_cidrs` variable and do a real `plan`-only `workflow_dispatch` run of `provision.yml` from the GitHub UI to see it actually execute in CI, or (c) work toward the user's own first real `terraform apply` when ready. Whichever comes next, re-read this file and `ROADMAP.md` first.

## Open decisions (resolved)

- ~~Terraform state backend~~ — resolved: HCP Terraform, org `FlyingThunderWolfDesign`, workspace `molted-magic-openclaw`, execution mode: local.
- ~~SSH key provisioning~~ — resolved: Terraform registers it directly via `digitalocean_ssh_key.admin`, no manual DO upload step.
- ~~GitHub secrets: repo-level vs environment-level~~ — resolved: repository secrets, no environment protection rules for now.
- ~~update.yml sync mechanism~~ — resolved: scp from the runner (matching provision.yml), not git-pull-on-box.
