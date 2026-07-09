# Molted Magic

Infrastructure-as-code for an isolated OpenClaw agent environment, plus a research workstream on the Moltbook platform/ecosystem.

Two workstreams live side by side in this repo:

- **[`openclaw/`](openclaw/)** — Terraform, cloud-init, scripts, and GitHub Actions workflows that provision and operate an isolated VPS running [OpenClaw](https://openclaw.ai) (shell/browser/messaging-capable agent), on DigitalOcean. Everything here is code; no live infrastructure is provisioned until someone deliberately runs `provision.yml` or `terraform apply`.
- **[`moltbook/`](moltbook/)** — research notes on the Moltbook platform/ecosystem. Research-only: nothing here gets wired into `openclaw/` without an explicit, separate decision (see [CLAUDE.md](CLAUDE.md)).

Start here:
- [`ROADMAP.md`](ROADMAP.md) — the full build sequence, session by session.
- [`PROGRESS.md`](PROGRESS.md) — current status; read this first in any new session.
- [`CLAUDE.md`](CLAUDE.md) — guardrails for anyone (human or agent) working in this repo.

Long-range context: this repo is a step toward eventually running an autonomous agent (or small agent network) as a personal assistant. Nothing in the current scope builds toward that beyond a few naming/shape choices that keep the door open — see the "Extensibility" section of `ROADMAP.md`.
