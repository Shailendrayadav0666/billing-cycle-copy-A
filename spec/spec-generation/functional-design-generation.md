# Functional Design Plan — Epic HELIX-6852 Self-Serve Premium Upgrade

**Inputs**: `spec/plans/epic-brief.md`, `spec/plans/requirements.md` v1, `spec/plans/stories.md` (1.1–1.10),
`spec/plans/atlas-deep-dive.md`, current source (`main.py`, `Billing.jsx`, `AuthContext.jsx`).
**Scope**: whole system, single pass. Application Design was skipped, so component structure is decided here.

## Plan

- [x] Analyse system context (Epic, requirements, stories, deep dive, source)
- [x] Collect answers to the questions below
- [x] Domain model: users, billing data, `PLANS` catalogue, sessions (fields, invariants)
- [x] Business rules: proration (inputs, formula, bounds, rounding), upgrade eligibility, session lifecycle (issue, validate, expire, revoke)
- [x] API contracts: login/register (changed), `/api/users/me`, `/api/billing` (changed), preview, upgrade, logout (new) — request, response, error codes
- [x] Validation and error handling rules (backend and frontend)
- [x] Frontend: component hierarchy, state, interaction flows (modal state machine), API integration, accessibility
- [x] Story-to-design trace (which design element each story implements)
- [x] Write `spec/plans/functional-design.md`; present the 2-option completion message (awaiting approval)

Most design points are already fixed by `requirements.md`. These four questions cover the remaining
structural choices. Fill in each `[Answer]:` tag.

---

## Question 1 — Backend code structure

`main.py` is a single 163-line file (the deep dive flags it as a monolith). This epic adds sessions, a plan
catalogue, proration and three endpoints.

A) Split into small modules inside `src/backend/`: `plans.py` (catalogue), `proration.py` (pure function),
`sessions.py` (session store + FastAPI dependency `get_current_user`), and keep routes in `main.py`. Pure
functions become easy to unit-test. (Recommended)

B) Keep everything in `main.py`, as today.

X) Other (please describe after [Answer]: tag below)

[Answer]: a

## Question 2 — Frontend code structure

A) New `src/frontend/src/components/UpgradeModal.jsx` (modal UI + preview/confirm logic) and a small
`src/frontend/src/api.js` helper (`authFetch` that adds the Bearer header and reports 401s to `AuthContext`).
`Billing.jsx` renders the button, the modal and the success message. (Recommended)

B) Put the modal and fetch logic inline in `Billing.jsx`.

X) Other (please describe after [Answer]: tag below)

[Answer]: a

## Question 3 — Configuration of session lifetime and allowed CORS origins

A) Environment variables with safe defaults: `SESSION_TTL_HOURS` (default 8) and `CORS_ALLOWED_ORIGINS`
(comma-separated, default `http://localhost:5173,http://127.0.0.1:5173`). The production mode (FastAPI serving
the built SPA on the same origin) needs no CORS entry. (Recommended)

B) Hardcoded constants in the code.

X) Other (please describe after [Answer]: tag below)

[Answer]: a

## Question 4 — Which "today" does proration use?

A) The server's local date (`date.today()`), the same basis the existing registration code uses for
`renew_at`. The frontend never computes dates; it shows the server's numbers. Tests inject a fixed date.
(Recommended)

B) UTC date on the server.

X) Other (please describe after [Answer]: tag below)

[Answer]: a
