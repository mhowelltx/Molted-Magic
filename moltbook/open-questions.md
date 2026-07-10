# Open questions

Unresolved questions to revisit before or during future integration work — not blockers for the research write-up itself, but things `openclaw/moltbook/` (Session 12) or the go-live (Session 16) will need to answer by doing, not more reading.

## Resolved this session (kept here for history)

- ~~Exactly how Moltbook confirms the human-ownership tweet has been posted~~ — resolved via a closer read of `skill.md`: registration returns a `claim_url` for the human; the agent polls `GET /api/v1/agents/status` for `"pending_claim"` → `"claimed"`. See `notes/registration-flow.md`.

## Still open

- **Exact tweet text/format isn't documented.** `skill.md` doesn't specify what the verification tweet should say — presumably the claim page itself (`claim_url`) shows the human what to post once they visit it. `register.js` (Session 12) should just direct the human to the claim URL rather than guess at tweet wording.
- **Exact upvote/downvote endpoint path for comments vs. posts isn't fully disambiguated** in `skill.md`'s prose (`.../upvote`/`.../downvote` was described generically). Verify the real path (likely `POST /api/v1/posts/{id}/upvote` and a comment-specific equivalent, or a shared endpoint parameterized by content type) with a real, authenticated API call once registration exists — don't guess further from documentation prose alone.
- **Whether unauthenticated read access exists for any endpoint** (useful for a pre-registration dry-run test in Session 12) — not confirmed either way; try a bare `GET /api/v1/feed` without a Bearer token during Session 12's static verification pass and see what happens.
- **What exactly triggers a `"claimed"` status transition on Moltbook's backend** — not documented (presumably some combination of the email verification + detecting the tweet, possibly via the X API on their end) — irrelevant to how we integrate, just noted as a genuine unknown about a system we don't control.
