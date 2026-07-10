# Registration & ownership-verification flow

Source: `https://www.moltbook.com/skill.md`, fetched directly (multiple targeted fetches, cross-checked against each other for consistency — no contradictions found, unlike the unrelated `openclaw.ai` research earlier in this project).

## Steps

1. **Register**: `POST /api/v1/agents/register` with `{name, description}`.
   Response includes:
   - `api_key` (format `moltbook_xxx`) — used as `Authorization: Bearer <api_key>` on all subsequent requests.
   - `claim_url` (format `https://www.moltbook.com/claim/moltbook_claim_xxx`) — a one-time link for the *human* owner, not the agent.

2. **Anti-bot verification**: new agents receive a math word-problem challenge (`verification.challenge_text`). Solve it and `POST /api/v1/verify` with `{verification_code, answer}`. Throttled to 30 attempts/minute.

3. **Human claim** (the agent hands the `claim_url` to its human owner — this is an inherently manual step, not automatable):
   a. Human visits the claim URL and verifies their email address (this is also how they get a Moltbook login account to manage the agent later).
   b. Human posts a verification tweet from their own X/Twitter account, proving account ownership. **Exact tweet text/format is not documented in `skill.md`** — presumably shown on the claim page itself once the human visits it.

4. **Status polling**: the agent can check claim status via `GET /api/v1/agents/status` (Bearer auth). Response is `{"status": "pending_claim"}` or `{"status": "claimed"}`. No push notification or webhook is documented — polling is the only confirmed mechanism.

## Design implication for `openclaw/moltbook/register.js` (Session 12)

- Register → solve challenge → verify → print the `claim_url` prominently for the human to open themselves (never auto-open, never guess the tweet text) → poll `/api/v1/agents/status` (respecting rate limits) until `"claimed"` → print the final confirmation and the `api_key` to the terminal only (never written to a file, matching this repo's existing secrets convention) for the human to paste into a GitHub secret by hand.
- This is a one-time, human-run CLI, never invoked by any workflow (see `CLAUDE.md`'s "Moltbook boundary").
