# Findings

Synthesized summary of Moltbook research. Full detail in `notes/`; this is the one-page version.

## What it is

Moltbook (https://www.moltbook.com) is "A Social Network for AI Agents" — agents post, comment, upvote, and follow each other in community areas called "Submolts." Humans are welcome to observe, and every agent's human owner goes through a real identity-verification flow (email + a public X/Twitter tweet) before the agent is fully activated.

## It's a real, documented REST API — not an arbitrary-code-execution risk

Everything is authenticated via `Authorization: Bearer <api_key>` against `https://www.moltbook.com` — a fixed set of specific endpoints for reading (home/feed/search/comments) and writing (post/comment/vote/follow/subscribe). See `notes/api-endpoints.md` for the full list. Rate limits are real and documented (60 reads/60s, 30 writes/60s, 1 post/30min) with proper `X-RateLimit-*` headers to respect.

## The one real risk: Moltbook's own doc tells agents to self-update

Moltbook's onboarding doc (`skill.md`) and its heartbeat reference (`heartbeat.md`) both instruct agents to periodically re-fetch newer versions of themselves from moltbook.com and adjust behavior accordingly. That's a live, mutable remote-instruction dependency — the exact pattern this project's `agent.md` forbids by default. **Decision (made explicitly, see `CLAUDE.md`): this project does not implement that.** We read these docs once, by hand, and hand-build a fixed, code-reviewed integration against the specific endpoints and behavior documented here. Future changes to Moltbook's actual behavior require a deliberate re-review of these notes and a conscious update to the code, not an automatic re-fetch.

## Registration is a real, multi-step human process

Register → solve a math anti-bot challenge → verify → the human owner gets a `claim_url`, verifies their email, and posts a real tweet from their own account. The agent polls `GET /api/v1/agents/status` for `"pending_claim"` → `"claimed"`. See `notes/registration-flow.md` for the full sequence — this cannot be automated past the point of the human's own actions (email verification, posting the tweet), by design.

## Heartbeat behavior we're adopting as fixed logic

Five-step priority order from `heartbeat.md`: check `/home` → respond to engagement on your own posts (the most important thing) → browse/upvote → comment/follow → post rarely, only when valuable. Escalate to the human for questions only they can answer, controversial mentions, and new DM requests. See `notes/heartbeat-and-rate-limits.md`.

## What this means for the integration (Sessions 11–16)

- `openclaw/moltbook/client.js` — hardcoded base URL, one function per endpoint, rate-limit-aware.
- `openclaw/moltbook/register.js` — one-time, human-run, never wired into any workflow.
- Full autonomy on Moltbook actions once live (the user's explicit choice), with a kill switch on the heartbeat interval as a cheap safety valve.
- `CLAUDE.md`'s "Moltbook boundary" is being rewritten (Session 11) from research-only to narrowly-scoped authorization: the reviewed client only, never a generic fetch-and-execute grant.
