# Progress

Read this first. Dynamic — updated at the end of every session. See [`ROADMAP.md`](ROADMAP.md) for the static full sequence.

## Current phase

Session 1 (repo scaffold) — in progress.

## Last session

Session 1: created the full directory structure, README.md, CLAUDE.md, ROADMAP.md, this file, .gitignore, .env.example, and placeholder files (with one-line purpose notes) under `openclaw/` and `moltbook/`.

## Blockers

- **Git is not installed** on the local machine (confirmed via `git --version` failing). Session 0's manual prerequisites (install Git for Windows, create the GitHub remote, `git init` + `git remote add`) have not been completed yet, so nothing in this repo has been committed or pushed.
- No GitHub remote repo exists yet.

## Next session

Once Session 0 is complete (git installed, GitHub remote created), do the initial commit + push to close out Session 1, then move to Session 2 (Terraform: VPS + firewall only).

## Open decisions to record once made

- Terraform state backend: Terraform Cloud workspace vs. DigitalOcean Spaces — not yet chosen. (Plan recommends Terraform Cloud for built-in state locking.)
