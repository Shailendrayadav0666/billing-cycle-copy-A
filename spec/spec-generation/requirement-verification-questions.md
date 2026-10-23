# Requirements Clarification Questions — Epic HELIX-6852 Self-Serve Premium Upgrade

Inputs read: `spec/plans/epic-brief.md` (Atlas Epic 6852 + linked Story 6853), `spec/plans/atlas-deep-dive.md`
(Atlas Deep Dive v29), and the current code (`src/backend/main.py`, `src/frontend/src/pages/Billing.jsx`,
`src/frontend/src/context/AuthContext.jsx`).

The Epic and Story are already detailed (7 acceptance criteria), so these questions only cover the gaps,
conflicts and decisions they leave open. Fill in each `[Answer]:` tag with a letter (or text for X).

---

## Question 1 — Security Baseline vs. the Epic's "email as token" pattern (most important)

The Epic says `POST /api/billing/upgrade` takes `{ "email": "<user_email>" }`, following the POC's existing
"the token is the email" model. The **Security Baseline is mandatory and blocking** for every project, and the
automated Code Review checks the new/changed code against it. As written, the new endpoint fails:

- **SECURITY-08 (object-level authorization / IDOR)** — anyone who knows an email can upgrade that account.
- **SECURITY-08 (token validation)** — nothing is validated server-side; the "token" is guessable.
- **SECURITY-08 (CORS)** — `allow_origins=["*"]` with `allow_credentials=True` on an authenticated, state-changing endpoint.

How should the upgrade endpoint authenticate the caller?

A) Introduce opaque server-side session tokens (CSPRNG via Python `secrets`, in-memory store, expiry, invalidated
on logout). Login/register issue them; `/api/users/me`, `/api/billing` and `/api/billing/upgrade` resolve the user
from an `Authorization: Bearer <token>` header and never trust a client-supplied email. Restrict CORS to the
local dev origins. Delivered as its own story so it can run in parallel with the upgrade work. (Recommended —
smallest change that passes the gate; no new dependencies)

B) Same as A, and ALSO fix the other pre-existing auth issues from the deep dive (hash passwords with an adaptive
algorithm, brute-force protection on login, remove the hardcoded demo credentials pre-filled in `Login.jsx`).
Larger scope; password hashing would need a new package (e.g. `bcrypt`/`argon2-cffi`).

C) Keep the Epic exactly as written (email in body). Note: the Code Review gate would then report a blocking
SECURITY-08 finding, and the story could not pass.

X) Other (please describe after [Answer]: tag below)

[Answer]: a

---

## Question 2 — Where is the prorated charge in the modal computed?

The Story says the modal computes `days_remaining` and the charge **in JavaScript** (client), while the backend
computes it again on confirm. Two implementations can disagree (time zones near midnight, rounding: Python's
`round()` rounds halves to even, JavaScript's `toFixed()` does not).

A) Add a read-only `GET /api/billing/upgrade/preview` endpoint. The modal shows the server's numbers, and confirm
uses the same function, so the shown amount and the applied amount are always identical. (Recommended)

B) Follow the Story literally: compute the preview client-side in JS, and accept that it could differ by a cent
or a day from the server.

X) Other (please describe after [Answer]: tag below)

[Answer]: a

---

## Question 3 — Rounding rule for the prorated charge

The formula `round((40 - 20) * (days_remaining / 30), 2)` can land exactly on half a cent for some values. Which
rounding should apply?

A) Round half up to 2 decimal places (standard currency rounding, using `Decimal`). (Recommended)

B) Python's built-in `round()` exactly as written in the Story (round half to even).

X) Other (please describe after [Answer]: tag below)

[Answer]: a

---

## Question 4 — Hardcoded "Standard" labels on the Billing page

`Billing.jsx` currently hardcodes "Current plan: **Standard**" and "What's included with **Standard**" regardless
of the data. After upgrading (AC-5), these would still say Standard.

A) Make them dynamic from `data.plan_name` (with a Premium badge style), as part of the upgrade work. (Recommended)

B) Leave them as they are.

X) Other (please describe after [Answer]: tag below)

[Answer]: a

---

## Question 5 — What happens when the upgrade request fails?

The Story covers success, Cancel, and the backend's 400 "Already on Premium plan", but not what the user sees on a
failure (400, 401 expired session, network error). Today `Billing.jsx` also silently swallows fetch errors
(infinite "Loading billing...").

A) Keep the modal open, show the server's error message inside it, re-enable the Confirm button, and leave the page
data unchanged. On 401, log the user out to the login page. Also show an error state instead of the infinite
"Loading billing..." on the Billing page. (Recommended)

B) Only handle errors in the modal (as in A); leave the existing Billing page loading behaviour untouched.

X) Other (please describe after [Answer]: tag below)

[Answer]: a

---

## Question 6 — Success message and modal behaviour details

A) Success message stays for about 5 seconds and can be dismissed. The modal closes with the Cancel button, the
close (X) button, the Escape key or a click on the backdrop; focus moves into the modal on open and returns to the
Upgrade button on close; the Confirm button is disabled while the request is in flight (prevents double submit).
(Recommended)

B) Minimal: modal with Confirm and Cancel only; success message stays until the page is left.

X) Other (please describe after [Answer]: tag below)

[Answer]: a

---

## Question 7 — Automated tests and test dependencies

The deep dive reports **zero** tests today. AIRE's `dev-implement` generates and runs unit tests to a coverage
threshold, plus API & contract tests for new endpoints. That needs test-only (dev) dependencies. The Epic says no
new runtime dependencies.

A) Add test-only dependencies: backend `pytest` + `httpx` (FastAPI `TestClient`) + `pytest-cov`; frontend
`vitest` + `@testing-library/react` + `jsdom`. No new runtime dependencies. (Recommended)

B) Backend tests only (`pytest`, `httpx`, `pytest-cov`); no frontend test framework.

X) Other (please describe after [Answer]: tag below)

[Answer]: a

---

## Question 8 — Duplicated plan data in `main.py`

The deep dive notes the Standard billing structure is copy-pasted twice (seed data and `register`). The upgrade
adds a third block (Premium).

A) Introduce a small plan catalogue (`PLANS = {"Standard": {...}, "Premium": {...}}`) and build billing data from
it in seed, register and upgrade. Behaviour for existing endpoints stays identical. (Recommended)

B) Add the Premium block inline as the Story shows; leave the existing duplication alone.

X) Other (please describe after [Answer]: tag below)

[Answer]: a

---

## Question: UI/UX Mockups
Once the design stages are complete, should HTML mockups of the user interface be produced for your review before development begins?

A) Yes, produce HTML mockups for review

B) No, designs already exist. Place them in spec/context-project/new-references/ and enter the path after [Answer]:

C) No, skip this step

X) Other (please describe after [Answer]: tag below)

[Answer]: c

---

## Question: Resiliency Extensions
Should the resiliency baseline be applied to this project?

**What this extension is.** Enabling it applies a set of **directional, design-time best practices** for building resilient systems, derived from the **AWS Well-Architected Framework (Reliability Pillar)** and resilience-review guidance. It steers requirements, design, and code toward fault tolerance, high availability, observability, and recoverability — covering 15 practice areas across business goals, change management, observability, high availability, disaster recovery, and continuous improvement.

**What this extension is NOT.** Enabling it does **not** make your workload production-ready, nor does it certify or guarantee any availability, RTO, or RPO target. It is a **starting point** that scaffolds good resiliency decisions early — it is not a substitute for a formal **AWS Well-Architected Review** of the built system.

Treat the output as a well-grounded **first draft of your resiliency posture** to build on and validate — not a finished, production-certified result.

A) Yes — apply the resiliency baseline as directional best practices and design-time guidance (recommended for business-critical workloads, as an informed starting point that you can validate and harden before go-live)

B) No — skip the resiliency baseline (suitable for PoCs, prototypes, and experimental projects where rapid iteration matters more than reliability)

X) Other (please describe after [Answer]: tag below)

[Answer]: b

---

## Question: Property-Based Testing Extension
Should property-based testing (PBT) rules be enforced for this project?

A) Yes — enforce all PBT rules as blocking constraints (recommended for projects with business logic, data transformations, serialization, or stateful components)

B) Partial — enforce PBT rules only for pure functions and serialization round-trips (suitable for projects with limited algorithmic complexity)

C) No — skip all PBT rules (suitable for simple CRUD applications, UI-only projects, or thin integration layers with no significant business logic)

X) Other (please describe after [Answer]: tag below)

[Answer]: c
