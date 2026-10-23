# Requirements — Epic HELIX-6852: Self-Serve Premium Upgrade

**Version**: 1
**Generated**: 2026-10-23T08:03:50Z
**Depth**: Standard
**Primary inputs**: `spec/plans/epic-brief.md` (Atlas Epic 6852 + linked Story 6853, via Helix MCP),
`spec/plans/atlas-deep-dive.md` (Atlas Deep Dive v29, via Helix MCP),
`spec/spec-generation/requirement-verification-questions.md` (answers received 2026-10-23)
**Context Project artifacts consulted**: none (user answered "no" to both parts)
**New References consulted**: none
**Design references consulted**: none registered

---

## 1. Intent Analysis

| Item | Value |
|---|---|
| **User request** | "using aire and helix mcp fetch the solution document and start implementing the epic requirements" |
| **Request type** | New Feature (enhancement of the existing Billing page) plus a targeted security hardening of the authentication used by the new feature |
| **Scope estimate** | Multiple Components — backend (`src/backend/main.py`) and frontend (`Billing.jsx`, `AuthContext.jsx`, `App.css`) |
| **Complexity estimate** | Moderate |
| **Clarity** | Clear — the Epic and Story carry 7 acceptance criteria; 8 gaps resolved by the clarifying questions |

### 1.1 Decisions taken from the clarifying answers

| Q | Decision | Effect on the Epic as written |
|---|---|---|
| Q1 = A | Opaque server-side session tokens replace "the token is the email"; endpoints resolve the user from `Authorization: Bearer <token>`; CORS restricted to local dev origins | **Amends** the Epic's Technical Context and the Story's AC-4 request shape: the upgrade request carries no email; identity comes from the session token |
| Q2 = A | Read-only `GET /api/billing/upgrade/preview` endpoint feeds the modal | **Amends** the Story's Frontend Changes item 3 (client-side calculation replaced by the server preview) |
| Q3 = A | Round half up to 2 decimals using `Decimal` | Refines AC-3 |
| Q4 = A | "Current plan" badge and "What's included with ..." heading driven by `plan_name` | Adds to AC-5 |
| Q5 = A | Error handling in the modal; 401 logs the user out; Billing page shows an error state instead of infinite loading | New behaviour not covered by the Story |
| Q6 = A | Success message about 5 s, dismissible; accessible modal (Esc, backdrop, focus management); Confirm disabled while in flight | Refines AC-2, AC-5, AC-6 |
| Q7 = A | Test-only dependencies: `pytest`, `httpx`, `pytest-cov`; `vitest`, `@testing-library/react`, `jsdom` | Epic's "no new dependencies" holds for **runtime**; test tooling added as dev-only |
| Q8 = A | Single plan catalogue (`PLANS`) used by seed, register and upgrade | Removes the duplication noted in the deep dive |
| UI/UX Mockups = C | No HTML mockups | Extension disabled |
| Resiliency = B | Resiliency baseline not applied | Extension disabled |
| PBT = C | Property-based testing not enforced | Extension disabled |

> **Epic amendment (security)** — The Epic states the upgrade endpoint follows the "email passed as query
> param / request body" pattern. The mandatory Security Baseline (SECURITY-08: object-level authorization,
> server-side token validation, no wildcard CORS on authenticated endpoints) blocks that design. Per the
> user's answer to Q1, these requirements follow the Security Baseline and amend the Epic. Recorded in
> `runtime-artifacts/audit.md`.

---

## 2. Existing-System Baseline (from Atlas)

From `spec/plans/atlas-deep-dive.md` (read-only truth):
- FastAPI backend in one file; data in in-memory dicts `users` and `billing_data`, keyed by email; reset on restart.
- Endpoints: `POST /api/auth/login`, `POST /api/auth/register`, `GET /api/users/me?email=`, `GET /api/billing?email=`.
- "access_token" returned by login/register is the user's email; the frontend stores it in `localStorage` and sends it as a query parameter.
- CORS: `allow_origins=["*"]` with `allow_credentials=True`.
- Billing data shape: `plan_name`, `price`, `renew_at` (`"%b %d, %Y"` string), `usages[]`, `included_usage{}`.
- `Billing.jsx` is read-only, hardcodes "Standard" labels, and never handles fetch errors.
- No tests exist.

---

## 3. Functional Requirements

### Authentication and session (security hardening required by the new feature)

**REQ-F-01 — Opaque session tokens issued at sign-in**
`POST /api/auth/login` and `POST /api/auth/register` return an `access_token` that is an opaque, random
session token generated with a CSPRNG (Python `secrets`, at least 128 bits of entropy), not the email. The
server keeps an in-memory session store mapping token → email and expiry. The response shape
(`access_token`, `user`) is otherwise unchanged, and the password is never returned.

**REQ-F-02 — Server-side session validation on every protected request**
`GET /api/users/me`, `GET /api/billing`, `GET /api/billing/upgrade/preview` and `POST /api/billing/upgrade`
identify the caller ONLY from an `Authorization: Bearer <token>` header, validated server-side against the
session store (exists, not expired). A missing, unknown or expired token returns HTTP 401
`{"detail": "Not authenticated"}`. The `email` query parameter is no longer accepted as identity; a caller can
only read or change their own data.

**REQ-F-03 — Session expiry and logout**
Sessions expire after a fixed server-side lifetime (default 8 hours). A new `POST /api/auth/logout`
(Bearer token) invalidates the session server-side; the frontend calls it on logout before clearing local
state. After logout the old token returns 401 everywhere.

**REQ-F-04 — Frontend uses the Bearer session token**
`AuthContext.jsx` stores the opaque token, sends it as `Authorization: Bearer <token>` on every protected
call (session restore via `/api/users/me`, billing, preview, upgrade), and logs the user out (redirect to
`/login`) on any 401. Login, registration, session restore and logout keep working exactly as before from the
user's point of view.

### Plan catalogue

**REQ-F-05 — Single plan catalogue**
The backend defines one catalogue of plans — `Standard` ($20/month, monthly price 20.00) and `Premium`
($40/month, monthly price 40.00) — each with its `usages` and `included_usage`. Seed data, registration and
upgrade build billing data from it. Standard data stays byte-for-byte identical to today's; Premium data is
exactly the "Premium Plan Feature Data" block in `epic-brief.md` (4K Ultra HD, 4 devices at once, download on 6
devices; perks: ad-free, spatial audio, Dolby Vision).

### Proration

**REQ-F-06 — Proration calculation**
One backend function computes the upgrade charge:
- `days_remaining = max(0, (renew_date − today).days)`, where `renew_date` is parsed from `renew_at`
  (`"%b %d, %Y"`) and `today` is the server's current date.
- `days_in_cycle = 30` (fixed).
- `prorated_charge = (40.00 − 20.00) × min(days_remaining, 30) / 30`, rounded **half up** to 2 decimal places
  using `Decimal`.
- `days_remaining <= 0` → `0.00` (the upgrade still proceeds). `days_remaining >= 30` → `20.00`.
- Examples: 0 → 0.00; 15 → 10.00; 29 → 19.33; 30 → 20.00; 45 → 20.00; 7 → 4.67.

**REQ-F-07 — Upgrade preview endpoint**
New `GET /api/billing/upgrade/preview` (Bearer token, read-only, no state change) returns
`{"current_plan": "Standard", "current_price": "$20/month", "new_plan": "Premium", "new_price": "$40/month",
"days_remaining": <int>, "days_in_cycle": 30, "prorated_charge": <number, 2 dp>, "renew_at": "<unchanged>"}`
using REQ-F-06. A user already on Premium gets HTTP 400 `{"detail": "Already on Premium plan"}`.

### Upgrade

**REQ-F-08 — Upgrade endpoint applies the plan change**
New `POST /api/billing/upgrade` (Bearer token, no request body fields required; any body is ignored for
identity). For the authenticated Standard user it: computes `prorated_charge` with REQ-F-06; sets
`users[email]["plan"] = "Premium"` and `users[email]["price"] = "$40/month"`; replaces `billing_data[email]`
with the Premium catalogue entry, keeping `renew_at` unchanged; returns HTTP 200 with
`{"plan_name": "Premium", "price": "$40/month", "renew_at": "<unchanged>", "prorated_charge": <number>,
"usages": [...], "included_usage": {...}}`. A user already on Premium gets HTTP 400
`{"detail": "Already on Premium plan"}` and nothing changes. (Story AC-3, AC-4, AC-7.)

**REQ-F-09 — Renewal date unchanged**
After an upgrade, `renew_at` in `users`, in `billing_data` and in the UI is the same value as before the
upgrade. (Story AC-7.)

### Billing page UI

**REQ-F-10 — Upgrade CTA for Standard users only**
`Billing.jsx` renders an "Upgrade to Premium" button below the current plan card only when
`data.plan_name === "Standard"`; it is not rendered for Premium. (Story AC-1.)

**REQ-F-11 — Confirmation modal with server preview**
Clicking "Upgrade to Premium" opens a modal that loads `GET /api/billing/upgrade/preview` and shows: current
plan "Standard ($20/mo)", new plan "Premium ($40/mo)", days remaining, and the text
"You'll be charged $X.XX today for the N days remaining in your cycle." with **Confirm Upgrade** and
**Cancel** buttons. Nothing is upgraded until Confirm is clicked. While the preview loads, Confirm is disabled.
(Story AC-2.)

**REQ-F-12 — Confirm applies the upgrade without a reload**
"Confirm Upgrade" calls `POST /api/billing/upgrade` once (Confirm disabled while the request is in flight), and
on success updates page state from the response without a page reload: plan Premium, price $40/month, renewal
date unchanged, Premium usage cards and perks, no upgrade button. A success message "You're now on Premium!
Your next full cycle bills at $40/month." shows for about 5 seconds and can be dismissed. (Story AC-5.)

**REQ-F-13 — Cancel does nothing**
Cancel, the close (X) button, the Escape key and a click on the backdrop close the modal without calling the
upgrade endpoint; page data is unchanged. (Story AC-6.)

**REQ-F-14 — Dynamic plan labels**
The "Current plan" badge and the "What's included with <plan>" heading show `data.plan_name` (Premium gets
its own badge style), instead of the hardcoded "Standard".

**REQ-F-15 — Error handling**
- In the modal: if preview or upgrade fails (400, network error, other non-2xx), the modal stays open, shows
  the server's `detail` message (or a generic "Something went wrong. Please try again."), re-enables Confirm,
  and page data is unchanged.
- Any 401 logs the user out and redirects to `/login` (REQ-F-04).
- The Billing page shows an error message with a Retry action instead of staying on "Loading billing..."
  forever when `GET /api/billing` fails.

### No regressions

**REQ-F-16 — Existing flows unchanged**
Login (including the seeded `tpg@example.com` user), registration, session restore, logout, and the Standard
billing display behave as before from the user's point of view; Standard billing values are unchanged.

---

## 4. Non-Functional Requirements

**REQ-NF-01 — Security Baseline compliance for new and changed code (blocking)**
All new and changed endpoints meet the Security Baseline rules that apply to them, in particular:
SECURITY-08 (deny by default, object-level authorization via the session, server-side token validation,
CORS restricted to `http://localhost:5173` and `http://127.0.0.1:5173` (configurable), no mass assignment —
request models allowlist fields), SECURITY-05 (Pydantic schemas with max lengths for every request string,
e.g. email 254, name 100, password 128), SECURITY-12 (CSPRNG opaque session IDs, server-side expiry, invalidation
on logout), SECURITY-15 (no stack traces or internal details in error responses; fail closed on any auth error),
SECURITY-03 (upgrade and logout events logged at INFO without tokens or passwords). Pre-existing findings
outside this diff (plaintext passwords, missing brute-force protection, demo credentials pre-filled in
`Login.jsx`) are out of scope per Q1 = A and are recorded as known residual risk.

**REQ-NF-02 — Usability / speed**
A Standard user can complete the upgrade from the Billing page in under 60 seconds (open modal → read charge →
confirm). The preview and upgrade endpoints respond in under 500 ms locally.

**REQ-NF-03 — Accessibility of the modal**
The modal uses `role="dialog"`, `aria-modal="true"` and an accessible name; focus moves into it on open and
returns to the "Upgrade to Premium" button on close; Escape closes it; all controls are keyboard-operable;
error and success messages are announced (`role="alert"` / `aria-live`).

**REQ-NF-04 — Testability and coverage**
Automated tests are added with test-only dependencies (backend: `pytest`, `httpx`, `pytest-cov` in a separate
dev requirements file; frontend: `vitest`, `@testing-library/react`, `jsdom` as devDependencies). Unit tests
cover the proration function (at least 0, 1 → 0.67, 15, 29, 30, 45, and a past date), the session store,
every endpoint (success, 400, 401), and the Billing page behaviours. Line coverage of new/changed code meets
the project `unitTestCoverageMin` threshold.

**REQ-NF-05 — No new runtime dependencies and no persistence**
No new runtime packages in `requirements.txt` or `package.json` `dependencies`; data and sessions stay
in-memory (reset on restart), per the Epic's out-of-scope list.

**REQ-NF-06 — Consistent, deterministic money values**
The charge shown in the modal and the charge returned by the upgrade come from the same backend function, so
for the same day they are identical. Money is rounded half up to 2 decimals and displayed as `$X.XX`.

**REQ-NF-07 — Maintainability**
Plan data is defined once (REQ-F-05). New backend code follows the existing FastAPI/Pydantic style in
`main.py`; new frontend code follows existing React function-component and CSS-class conventions in
`Billing.jsx` / `App.css`.

---

## 5. Out of Scope (confirmed by the Epic and the answers)

- Downgrades; refunds or credits
- Payment verification, decline flows, external payment SDKs (Stripe, etc.)
- Enterprise or additional plans
- Persistent database storage (data and sessions stay in memory)
- Password hashing, brute-force protection, removal of pre-filled demo credentials (Q1 option B not chosen)
- HTML mockups (UI/UX Mockups extension disabled); resiliency baseline; property-based testing

---

## 6. Traceability to the Atlas Story

| Story AC (epic-brief.md) | Requirement(s) |
|---|---|
| AC-1 CTA for Standard only | REQ-F-10 |
| AC-2 Modal shows prorated amount | REQ-F-07, REQ-F-11, REQ-NF-03 |
| AC-3 Proration math | REQ-F-06, REQ-NF-06 |
| AC-4 Backend upgrade endpoint | REQ-F-08 (amended: identity from Bearer session, REQ-F-02) |
| AC-5 Page reflects Premium without reload | REQ-F-12, REQ-F-14 |
| AC-6 Cancel does nothing | REQ-F-13 |
| AC-7 Renewal date unchanged | REQ-F-09 |
| Definition of Done: no regressions | REQ-F-16 |
| Epic success metric: under 60 s | REQ-NF-02 |

---

## 7. Security Baseline Compliance Summary (Requirements stage)

| Rule | Status | Note |
|---|---|---|
| SECURITY-01 Encryption | N/A | No data store; local HTTP dev setup (POC) |
| SECURITY-02 Access logging on intermediaries | N/A | No load balancer / gateway |
| SECURITY-03 Application logging | Compliant (by requirement) | REQ-NF-01 |
| SECURITY-04 HTTP security headers | N/A for this diff | No HTML-serving change; pre-existing |
| SECURITY-05 Input validation | Compliant (by requirement) | REQ-NF-01 |
| SECURITY-06 / 07 Least privilege, network | N/A | No cloud/IaC |
| SECURITY-08 Access control | Compliant (by requirement) | REQ-F-02, REQ-NF-01 |
| SECURITY-09 Hardening | Compliant (by requirement) | REQ-NF-01 (no internal details in errors) |
| SECURITY-10 Supply chain | Compliant (by requirement) | Only test-only dev dependencies, pinned in lock/requirements files |
| SECURITY-11 Secure design | Compliant (by requirement) | Server is the single source of the charge (REQ-NF-06) |
| SECURITY-12 Auth and credentials | Partially in scope | Session requirements in scope (REQ-F-01..03); password hashing / brute force are pre-existing and out of scope per Q1 = A |
| SECURITY-13 Integrity | N/A | No deserialization of untrusted objects / CI artifacts |
| SECURITY-14 Alerting | N/A | No deployed monitoring for the POC |
| SECURITY-15 Exception handling | Compliant (by requirement) | REQ-NF-01, REQ-F-15 |
| SECURITY-16 Cryptography | Compliant (by requirement) | `secrets` CSPRNG for session tokens |

No blocking security findings at this stage.
