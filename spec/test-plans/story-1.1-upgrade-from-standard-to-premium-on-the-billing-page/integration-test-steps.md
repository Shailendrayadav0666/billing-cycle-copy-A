# Integration Test Steps — Story 1.1 Upgrade from Standard to Premium on the Billing page

**Purpose**: verify the boundaries this story crosses, observed from outside: SPA ↔ API (the Bearer token on
every protected call), API ↔ in-memory session store (sessions survive reloads, die with the process), and
API ↔ in-memory user/billing stores (an upgrade is visible consistently through every endpoint).
**Scope**: AC-3, AC-4, AC-5 (REQ-F-02, REQ-F-04, REQ-F-08, REQ-F-09, REQ-F-16). Boundaries taken from
`spec/plans/architecture.md` Section 2 and 5.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.1 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.1"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend dev server `http://localhost:5173`; backend `http://localhost:8000` |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard, renew_at `Oct 30, 2026`) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-INT-01 — The SPA sends the session token as a Bearer header on every protected call

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-04 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | Fresh backend; browser DevTools > Network open with "Preserve log" on |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in at `http://localhost:5173/login`.
2. On the Billing page, click "Upgrade to Premium", then "Confirm Upgrade".
3. Inspect the requests `GET /api/users/me` (if any), `GET /api/billing`, `GET /api/billing/upgrade/preview`, `POST /api/billing/upgrade`.

**Expected result**
- Each request carries `Authorization: Bearer <token>` where `<token>` equals the `access_token` from the login response.
- No request URL contains `email=` or the token.
- DevTools > Application > Local Storage `token` holds the opaque token (not the email).

**Pass/Fail criteria**: PASS if every protected request uses the Bearer header and no URL carries identity; FAIL otherwise.
**Cleanup**: restart the backend.

### TC-INT-02 — An upgrade is visible consistently through every endpoint and the UI

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-08, REQ-F-09 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | Fresh backend |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in through the UI and upgrade via the dialog.
2. In a terminal, sign in via `POST /api/auth/login` (second session) and call `GET /api/users/me` and `GET /api/billing` with that new token.
3. In a second browser (or private window), sign in as the same user and open the Billing page.

**Expected result**
- Step 2: `/me` returns `plan` `Premium`, `price` `$40/month`, `renew_at` `Oct 30, 2026`; `/billing` returns `plan_name` `Premium`, `renew_at` `Oct 30, 2026`.
- Step 3: the second browser shows `Premium`, `$40/month`, renewal `Oct 30, 2026`, no upgrade button.

**Pass/Fail criteria**: PASS if user record, billing record and UI agree from any session; FAIL on any mismatch.
**Cleanup**: restart the backend.

### TC-INT-03 — Session restore after reload uses the stored token

| Field | Value |
|-------|-------|
| **Traces to** | AC-5, AC-4 / REQ-F-04, REQ-F-16 |
| **Type** | Integration |
| **Priority** | P2 |
| **Preconditions** | Fresh backend; signed in through the UI |
| **Test data** | — |

**Steps**
1. Reload the Billing page with DevTools > Network open.
2. Inspect the `GET /api/users/me` request.

**Expected result**
- `GET /api/users/me` is sent with `Authorization: Bearer <stored token>` and returns 200; the page stays on `/billing` with the user's name in the header.

**Pass/Fail criteria**: PASS if the session is restored via the Bearer token; FAIL otherwise.
**Cleanup**: none.

### TC-INT-04 — Sessions live in server memory: a backend restart invalidates old tokens

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-02 (in-memory store, REQ-NF-05) |
| **Type** | Integration |
| **Priority** | P3 |
| **Preconditions** | Signed in via `POST /api/auth/login`; `$TOKEN` noted |
| **Test data** | `$TOKEN` |

**Steps**
1. `curl -s -i http://localhost:8000/api/billing -H "Authorization: Bearer $TOKEN"` — expect 200.
2. Stop and restart the backend.
3. Repeat step 1 with the same `$TOKEN`.

**Expected result**
- Step 3: `401`, `{"detail": "Not authenticated"}` (sessions are not persisted).

**Pass/Fail criteria**: PASS if the old token is rejected after restart; FAIL if it still works.
**Cleanup**: none.
