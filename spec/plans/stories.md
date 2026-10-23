EPIC TICKET: HELIX-6852 — Self-Serve Premium Upgrade (LOCAL tracker; Epic sourced from Atlas document 6852 via Helix MCP, see spec/plans/epic-brief.md)

# User Stories — Epic HELIX-6852 Self-Serve Premium Upgrade

**Approach**: Walking skeleton + increments (user direction: the very first story delivers the working
Standard → Premium upgrade UI). **Story count**: 10. **team_size**: 2. **AC format**: Given/When/Then.
**Requirements**: `spec/plans/requirements.md` v1. **Personas**: `spec/plans/personas.md`.

> **Story 1.1 sizing exception (recorded)**: 1.1 is the thinnest working end-to-end slice and touches
> both the backend and the Billing UI — a deliberate exception to the one-new-layer ceiling, taken at the
> user's direction. It keeps 5 ACs and one scenario class (the Standard subscriber's happy path). It includes
> the minimal Bearer session because the mandatory Security Baseline (SECURITY-08) would otherwise block its
> Code Review. All other stories are within the ceilings.

Test convention for every story (REQ-NF-04): backend tests in `tests/unit/backend/` and API tests in
`tests/api/` (pytest + FastAPI `TestClient`); frontend tests in `tests/unit/frontend/` (vitest + Testing
Library). No new runtime dependencies (REQ-NF-05).

---

## Story 1.1 — Upgrade from Standard to Premium on the Billing page

**Tracker ID**: LOCAL
**Requires**: none
**Persona**: P1 Sam (Standard Subscriber); P3 Nina (regression of sign-up)
**Priority**: High
**Covers**: REQ-F-01, REQ-F-02, REQ-F-04, REQ-F-05, REQ-F-06, REQ-F-07, REQ-F-08, REQ-F-09, REQ-F-10, REQ-F-11, REQ-F-12, REQ-F-14, REQ-F-16, REQ-NF-01, REQ-NF-02, REQ-NF-04, REQ-NF-05, REQ-NF-06

> As a Standard subscriber, I want to upgrade to Premium from the Billing page and see the prorated charge
> before I confirm, so that I get Premium features immediately and only pay for the days left in my cycle.

**Acceptance Criteria**

- **AC-1 — Upgrade button for a Standard user** (REQ-F-10, REQ-F-14)
  **Given** I am signed in on the Standard plan
  **When** I open the Billing page
  **Then** an "Upgrade to Premium" button is shown below the current plan card
  **And** the "Current plan" badge and the "What's included with ..." heading show the plan name from the billing data ("Standard")

- **AC-2 — Modal shows the server-calculated charge before commitment** (REQ-F-06, REQ-F-07, REQ-F-11, REQ-NF-06)
  **Given** I am a Standard user whose renewal date is 15 days away
  **When** I click "Upgrade to Premium"
  **Then** a modal opens that loads `GET /api/billing/upgrade/preview` and shows "Standard ($20/mo)", "Premium ($40/mo)", 15 days remaining and "You'll be charged $10.00 today for the 15 days remaining in your cycle."
  **And** it shows "Confirm Upgrade" (disabled until the preview has loaded) and "Cancel" buttons
  **And** my plan has not changed yet

- **AC-3 — Confirming upgrades the account and updates the page without a reload** (REQ-F-05, REQ-F-08, REQ-F-09, REQ-F-12, REQ-NF-02)
  **Given** the upgrade modal is open with the preview loaded
  **When** I click "Confirm Upgrade"
  **Then** `POST /api/billing/upgrade` sets my user record to Premium / "$40/month", replaces my billing data with the Premium plan data from `epic-brief.md` (4K Ultra HD, 4 devices at once, 6 download devices; ad-free, spatial audio, Dolby Vision perks) and returns it with `prorated_charge` 10.00 and the same `renew_at`
  **And** without a page reload the page shows the Premium badge, "What's included with Premium", $40/month, the Premium feature cards, the unchanged renewal date, no Upgrade button, and the message "You're now on Premium! Your next full cycle bills at $40/month."

- **AC-4 — Requests are tied to my server-side session, not to an email** (REQ-F-01, REQ-F-02, REQ-F-04, REQ-NF-01)
  **Given** the backend issues sessions
  **When** I sign in or register
  **Then** `access_token` is an opaque random token (Python `secrets`, ≥128 bits), not my email, and the frontend sends it as `Authorization: Bearer <token>` to `/api/users/me`, `/api/billing`, the preview and the upgrade endpoints
  **And** those endpoints return 401 `{"detail": "Not authenticated"}` for a missing or unknown token, ignore any `email` query/body value for identity, and CORS allows only `http://localhost:5173` and `http://127.0.0.1:5173`
  **And** every request model has explicit field max lengths (email 254, name 100, password 128) and errors never expose stack traces

- **AC-5 — Existing flows keep working** (REQ-F-16, REQ-NF-04, REQ-NF-05)
  **Given** the upgrade feature is in place
  **When** I sign in as `tpg@example.com`, register a new account, reload the page (session restore), log out, or view a Standard billing page
  **Then** each behaves as before from my point of view, and Standard billing values are unchanged
  **And** backend (`pytest`, `httpx`, `pytest-cov`) and frontend (`vitest`, `@testing-library/react`, `jsdom`) test tooling is added as test-only dependencies, with tests covering AC-1..AC-5

---

## Story 1.2 — Premium users cannot preview or upgrade again

**Tracker ID**: LOCAL
**Requires**: 1.1
**Persona**: P2 Priya (Premium Subscriber)
**Priority**: High
**Covers**: REQ-F-07, REQ-F-08, REQ-F-10, REQ-NF-01

> As a Premium subscriber, I want the app to never offer or apply an upgrade I already have, so that I am
> never charged twice.

**Acceptance Criteria**

- **AC-1 — Preview rejected for Premium** (REQ-F-07)
  **Given** I am signed in on Premium
  **When** `GET /api/billing/upgrade/preview` is called with my session
  **Then** it returns 400 `{"detail": "Already on Premium plan"}`

- **AC-2 — Upgrade rejected for Premium, nothing changes** (REQ-F-08)
  **Given** I am signed in on Premium
  **When** `POST /api/billing/upgrade` is called with my session
  **Then** it returns 400 `{"detail": "Already on Premium plan"}` and my user record and billing data are unchanged

- **AC-3 — No Upgrade button for Premium** (REQ-F-10)
  **Given** I am signed in on Premium
  **When** I open the Billing page
  **Then** the "Upgrade to Premium" button is not rendered

- **AC-4 — An upgrade only ever changes the caller's own account** (REQ-NF-01, SECURITY-08)
  **Given** two Standard users A and B, each with their own session
  **When** A calls `POST /api/billing/upgrade` (with or without B's email anywhere in the request)
  **Then** only A becomes Premium and B's plan and billing data are unchanged

---

## Story 1.3 — Proration boundary and rounding rules

**Tracker ID**: LOCAL
**Requires**: 1.1
**Persona**: P1 Sam (Standard Subscriber)
**Priority**: High
**Covers**: REQ-F-06, REQ-NF-06

> As a Standard subscriber, I want the prorated charge to be correct at the edges of my billing cycle, so
> that I am never over- or under-charged.

**Acceptance Criteria**

- **AC-1 — Renewal date today or in the past** (REQ-F-06)
  **Given** my `renew_at` is today or earlier
  **When** I preview or confirm the upgrade
  **Then** `days_remaining` is 0 and `prorated_charge` is 0.00, and the upgrade still proceeds

- **AC-2 — 30 or more days remaining** (REQ-F-06)
  **Given** my `renew_at` is 30 or 45 days away
  **When** I preview the upgrade
  **Then** `prorated_charge` is 20.00 (the full price difference, never more)

- **AC-3 — Half-up rounding to 2 decimals with `Decimal`** (REQ-F-06, REQ-NF-06)
  **Given** 1, 7 and 29 days remaining
  **When** the charge is calculated
  **Then** it is 0.67, 4.67 and 19.33 respectively, computed with `Decimal` and `ROUND_HALF_UP`, and displayed as `$X.XX`

- **AC-4 — Preview and upgrade agree** (REQ-NF-06)
  **Given** I preview and then confirm on the same day
  **When** both responses are compared
  **Then** the `prorated_charge` values are identical because both come from the same backend function

---

## Story 1.4 — Seed and registration use the single plan catalogue

**Tracker ID**: LOCAL
**Requires**: 1.1
**Persona**: P3 Nina (New Subscriber)
**Priority**: Medium
**Covers**: REQ-F-05, REQ-F-16, REQ-NF-05, REQ-NF-07

> As a new subscriber, I want my Standard plan details to come from the same plan definition the upgrade
> uses, so that plan data can never drift between sign-up and upgrade.

**Acceptance Criteria**

- **AC-1 — Seeded user unchanged** (REQ-F-05, REQ-F-16)
  **Given** the server has just started
  **When** `tpg@example.com` requests `/api/billing`
  **Then** the response is identical to the pre-change Standard billing data (same values, same order)

- **AC-2 — Registered user built from the catalogue** (REQ-F-05)
  **Given** a new user registers
  **When** they request `/api/billing`
  **Then** they get the Standard catalogue entry with `renew_at` 30 days from today, identical in shape and values to the seeded user's Standard data apart from `renew_at`

- **AC-3 — Plan data defined once** (REQ-NF-07)
  **Given** the backend source
  **When** it is reviewed
  **Then** Standard and Premium plan data each exist in exactly one `PLANS` catalogue entry used by seed, register and upgrade, with no duplicated literal billing blocks, and no new runtime dependency is added (REQ-NF-05)

- **AC-4 — Duplicate registration still rejected** (REQ-F-16)
  **Given** an account already exists for an email
  **When** someone registers with that email
  **Then** the response is still 400 `{"detail": "Account already exists"}`

---

## Story 1.5 — Sessions expire and logout ends the session

**Tracker ID**: LOCAL
**Requires**: 1.1
**Persona**: P3 Nina (New Subscriber); P1 Sam
**Priority**: Medium
**Covers**: REQ-F-03, REQ-F-16, REQ-NF-01

> As a subscriber, I want my session to end when I log out or after a while, so that nobody can keep using
> my account from an old token.

**Acceptance Criteria**

- **AC-1 — Expired sessions are rejected** (REQ-F-03)
  **Given** a session older than the server-side lifetime (default 8 hours, configurable)
  **When** it is used on any protected endpoint
  **Then** the response is 401 `{"detail": "Not authenticated"}` and the expired session is removed

- **AC-2 — Logout invalidates the session server-side** (REQ-F-03)
  **Given** I have a valid session
  **When** `POST /api/auth/logout` is called with it
  **Then** it succeeds and the same token returns 401 on every protected endpoint afterwards

- **AC-3 — Logout fails closed for an invalid token** (REQ-F-03, REQ-NF-01)
  **Given** a missing or unknown token
  **When** `POST /api/auth/logout` is called
  **Then** it returns 401 and no other session is affected

- **AC-4 — Frontend logout calls the server** (REQ-F-03, REQ-F-16)
  **Given** I am signed in
  **When** I click logout
  **Then** the frontend calls `POST /api/auth/logout` with my token, then clears local state and goes to `/login` even if that call fails

- **AC-5 — Logout and expiry are logged safely** (REQ-NF-01, SECURITY-03)
  **Given** a logout or an expired-session rejection
  **When** it happens
  **Then** an INFO log line records the event without the token or password

---

## Story 1.6 — Signed out on an invalid or expired session

**Tracker ID**: LOCAL
**Requires**: 1.1
**Persona**: P1 Sam (Standard Subscriber)
**Priority**: Medium
**Covers**: REQ-F-04, REQ-F-15

> As a subscriber, I want to be taken back to sign-in when my session is no longer valid, so that I am never
> stuck on a broken page.

**Acceptance Criteria**

- **AC-1 — Any 401 signs me out** (REQ-F-04, REQ-F-15)
  **Given** I am on the Billing page or the upgrade modal
  **When** `/api/users/me`, `/api/billing`, the preview or the upgrade endpoint returns 401
  **Then** the frontend clears the stored token and user and redirects to `/login`

- **AC-2 — A stale pre-upgrade token is handled** (REQ-F-04)
  **Given** `localStorage` still holds an old email-style token from before Story 1.1
  **When** the app loads
  **Then** session restore gets 401 and I land on `/login` once, with no request loop and no error screen

---

## Story 1.7 — Cancel or dismiss the upgrade modal without upgrading

**Tracker ID**: LOCAL
**Requires**: 1.1
**Persona**: P1 Sam (Standard Subscriber)
**Priority**: Medium
**Covers**: REQ-F-13, REQ-NF-03

> As a Standard subscriber, I want to back out of the upgrade easily with mouse or keyboard, so that I only
> upgrade when I mean to.

**Acceptance Criteria**

- **AC-1 — Every dismiss route leaves the account unchanged** (REQ-F-13)
  **Given** the upgrade modal is open
  **When** I click Cancel, click the close (X) button, press Escape, or click the backdrop
  **Then** the modal closes, no `POST /api/billing/upgrade` request is made, and the page data is unchanged

- **AC-2 — Dialog semantics** (REQ-NF-03)
  **Given** the upgrade modal is open
  **When** a screen reader inspects it
  **Then** it has `role="dialog"`, `aria-modal="true"` and an accessible name

- **AC-3 — Focus management** (REQ-NF-03)
  **Given** I open the modal with the keyboard
  **When** it opens and later closes
  **Then** focus moves into the modal on open, Tab stays within it while open, and focus returns to the "Upgrade to Premium" button on close

- **AC-4 — Reopening shows a fresh preview** (REQ-F-13)
  **Given** I cancelled the modal
  **When** I open it again
  **Then** the preview is requested again and shown

---

## Story 1.8 — Upgrade modal shows preview and upgrade failures

**Tracker ID**: LOCAL
**Requires**: 1.1
**Persona**: P1 Sam (Standard Subscriber)
**Priority**: Medium
**Covers**: REQ-F-12, REQ-F-15, REQ-NF-03

> As a Standard subscriber, I want to see what went wrong if the upgrade cannot be previewed or applied, so
> that I can try again without losing my place.

**Acceptance Criteria**

- **AC-1 — Preview failure** (REQ-F-15)
  **Given** I open the upgrade modal
  **When** the preview request fails with a non-401 error or a network error
  **Then** the modal shows the server's `detail` message (or "Something went wrong. Please try again.") and "Confirm Upgrade" stays disabled

- **AC-2 — Upgrade failure keeps the modal open** (REQ-F-15)
  **Given** the preview has loaded
  **When** `POST /api/billing/upgrade` fails with a non-401 error or a network error
  **Then** the modal stays open, shows the error message, re-enables "Confirm Upgrade", and the page data is unchanged

- **AC-3 — No double submit** (REQ-F-12)
  **Given** I click "Confirm Upgrade"
  **When** I click it again before the response arrives
  **Then** the button is disabled while the request is in flight and exactly one upgrade request is sent

- **AC-4 — Errors are announced** (REQ-NF-03)
  **Given** an error message appears in the modal
  **When** a screen reader is running
  **Then** the message is in a `role="alert"` region

---

## Story 1.9 — Billing page shows a load error with Retry

**Tracker ID**: LOCAL
**Requires**: 1.1
**Persona**: P1 Sam; P2 Priya
**Priority**: Medium
**Covers**: REQ-F-15, REQ-NF-03

> As a subscriber, I want to see an error and a way to retry when my billing details fail to load, so that I
> am not left on an endless loading message.

**Acceptance Criteria**

- **AC-1 — Error instead of endless loading** (REQ-F-15)
  **Given** I open the Billing page
  **When** `GET /api/billing` fails with a non-401 error or a network error
  **Then** an error message with a "Retry" button is shown instead of "Loading billing..."

- **AC-2 — Retry recovers** (REQ-F-15)
  **Given** the load error is shown
  **When** I click "Retry" and the request now succeeds
  **Then** the billing page renders normally

- **AC-3 — Error is announced** (REQ-NF-03)
  **Given** the load error is shown
  **When** a screen reader is running
  **Then** the message is in a `role="alert"` region

---

## Story 1.10 — Upgrade success message times out and can be dismissed

**Tracker ID**: LOCAL
**Requires**: 1.1
**Persona**: P1 Sam (Standard Subscriber)
**Priority**: Low
**Covers**: REQ-F-12, REQ-NF-03

> As a subscriber who just upgraded, I want the confirmation message to get out of my way, so that the
> Billing page stays clean.

**Acceptance Criteria**

- **AC-1 — Message announced** (REQ-F-12, REQ-NF-03)
  **Given** the upgrade has just succeeded
  **When** the success message appears
  **Then** it reads "You're now on Premium! Your next full cycle bills at $40/month." inside an `aria-live="polite"` / `role="status"` region

- **AC-2 — Auto-hide after about 5 seconds** (REQ-F-12)
  **Given** the success message is shown
  **When** 5 seconds pass
  **Then** the message disappears

- **AC-3 — Manual dismiss** (REQ-F-12, REQ-NF-03)
  **Given** the success message is shown
  **When** I activate its dismiss button (mouse or keyboard)
  **Then** it disappears immediately

- **AC-4 — No timer leaks** (REQ-F-12)
  **Given** the success message timer is running
  **When** I navigate away from the Billing page
  **Then** the timer is cleared and no state update happens on the unmounted page

---

## Requirements Coverage Matrix

| REQ-ID | Covering stories | Status |
|---|---|---|
| REQ-F-01 Opaque session tokens | 1.1 (AC-4) | Full |
| REQ-F-02 Server-side session validation | 1.1 (AC-4), 1.2 (AC-4) | Full |
| REQ-F-03 Session expiry and logout | 1.5 (AC-1..AC-4) | Full |
| REQ-F-04 Frontend uses Bearer token | 1.1 (AC-4), 1.6 (AC-1, AC-2) | Full |
| REQ-F-05 Single plan catalogue | 1.1 (AC-3 Premium data), 1.4 (AC-1..AC-3) | Full |
| REQ-F-06 Proration calculation | 1.1 (AC-2, AC-3), 1.3 (AC-1..AC-3) | Full |
| REQ-F-07 Upgrade preview endpoint | 1.1 (AC-2), 1.2 (AC-1) | Full |
| REQ-F-08 Upgrade endpoint | 1.1 (AC-3), 1.2 (AC-2) | Full |
| REQ-F-09 Renewal date unchanged | 1.1 (AC-3) | Full |
| REQ-F-10 CTA for Standard only | 1.1 (AC-1), 1.2 (AC-3) | Full |
| REQ-F-11 Confirmation modal with server preview | 1.1 (AC-2) | Full |
| REQ-F-12 Confirm applies upgrade without reload | 1.1 (AC-3), 1.8 (AC-3), 1.10 (AC-1..AC-4) | Full |
| REQ-F-13 Cancel does nothing | 1.7 (AC-1, AC-4) | Full |
| REQ-F-14 Dynamic plan labels | 1.1 (AC-1, AC-3) | Full |
| REQ-F-15 Error handling | 1.6 (AC-1), 1.8 (AC-1, AC-2), 1.9 (AC-1, AC-2) | Full |
| REQ-F-16 Existing flows unchanged | 1.1 (AC-5), 1.4 (AC-1, AC-4), 1.5 (AC-4) | Full |
| REQ-NF-01 Security Baseline compliance | 1.1 (AC-4), 1.2 (AC-4), 1.5 (AC-3, AC-5) | Full |
| REQ-NF-02 Upgrade under 60 s | 1.1 (AC-3) | Full |
| REQ-NF-03 Modal accessibility | 1.7 (AC-2, AC-3), 1.8 (AC-4), 1.9 (AC-3), 1.10 (AC-1, AC-3) | Full |
| REQ-NF-04 Testability and coverage | 1.1 (AC-5) tooling; tests in every story per the test convention | Full |
| REQ-NF-05 No new runtime deps, no persistence | 1.1 (AC-5), 1.4 (AC-3) | Full |
| REQ-NF-06 Consistent money values | 1.1 (AC-2), 1.3 (AC-3, AC-4) | Full |
| REQ-NF-07 Maintainability | 1.4 (AC-3) | Full |

**Requirements coverage: 23/23 REQ-IDs fully covered by story ACs.**

### Cross-story seams (owned explicitly)
- Sessions (1.1) ↔ 401 handling (1.6): 1.6 AC-1 owns the frontend reaction to every protected endpoint 1.1 introduced.
- Upgrade (1.1) ↔ Premium rejection (1.2): 1.2 AC-1/AC-2 own the 400 path of the endpoints 1.1 introduced.
- Base formula (1.1) ↔ edge/rounding rules (1.3): 1.3 AC-4 owns preview/upgrade agreement.
- Premium data (1.1) ↔ catalogue consolidation (1.4): 1.4 AC-3 owns "defined once" across seed, register and upgrade.
