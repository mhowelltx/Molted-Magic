# Progress

Read this first. Dynamic — updated at the end of every session. See [`ROADMAP.md`](ROADMAP.md) for the static full sequence.

## Current phase

Session 2 (Terraform: VPS + firewall) — complete, with one carry-forward item. Next up: Session 3 (cloud-init hardening + Tailscale).

## Last session

Session 2: wrote `openclaw/terraform/{main,variables,outputs,network,firewall,backend}.tf` for a single DigitalOcean droplet (`ubuntu-24-04-x64`, region/size as variables) + a dedicated VPC + a cloud firewall (SSH/22 inbound only, restricted to `admin_ip_cidrs`; no inbound rule at all for the OpenClaw control-UI port — it's Tailscale-only). Backend is HCP Terraform (org `FlyingThunderWolfDesign`, workspace `molted-magic-openclaw`, both already created by the user).

Installed Terraform CLI locally (via winget) and ran real verification against the actual backend and DigitalOcean provider (auth via `TF_TOKEN_app_terraform_io` and `TF_VAR_do_token` env vars set locally via `setx` — never committed):
- `terraform init` — succeeded against the real HCP Terraform workspace.
- `terraform validate` — passed.
- `terraform plan` (with a local, gitignored, dummy `terraform.tfvars` — fake ssh key fingerprint, TEST-NET-3 example IP — deleted after the run) — clean: 3 to add (droplet, firewall, VPC), 0 to change, 0 to destroy. No `apply` was run.

`.terraform.lock.hcl` was generated and is now committed (standard practice — pins provider versions).

## Blockers

None currently.

## Carried forward to Session 3

`main.tf`'s droplet resource does **not** yet set `user_data`. The original plan was to reference `openclaw/cloud-init/user-data.yml.tmpl` via `templatefile()`, but HCP Terraform's CLI-driven remote runs only upload the `openclaw/terraform` working directory to the remote runner — a relative reference to the sibling `../cloud-init/` directory fails during a remote `plan` even though the same config works fine locally (confirmed by testing: `Invalid value for "path" parameter: no file exists at "./../cloud-init/user-data.yml.tmpl"`). This is a real conflict between doc 1's original sibling-directory layout (`terraform/`, `cloud-init/` as siblings under `openclaw/`) and how HCP Terraform CLI-driven workspaces package configuration for remote execution.

Session 3 needs to decide how to resolve this before wiring `user_data` in — options include nesting `cloud-init/` under `openclaw/terraform/`, or changing the HCP Terraform workspace's execution mode/working directory settings. Doesn't block Session 3's actual cloud-init content work, just the final wiring step back into `main.tf`.

## Next session

Session 3: write real content for `openclaw/cloud-init/user-data.yml.tmpl` (non-root user, SSH-key-only sshd, ufw mirroring the DO firewall, unattended-upgrades, Tailscale join) — and resolve the directory-structure conflict above before wiring it into `main.tf`'s `user_data` argument.

## Open decisions (resolved)

- ~~Terraform state backend~~ — resolved: HCP Terraform, org `FlyingThunderWolfDesign`, workspace `molted-magic-openclaw`.
