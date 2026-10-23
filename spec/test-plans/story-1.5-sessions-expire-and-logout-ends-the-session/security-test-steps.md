# Security Test Steps — Story 1.5 Sessions expire and logout ends the session

**Purpose**: verify session revocation fails closed and that logout and expiry events are logged without
secrets (Security Baseline SECURITY-03, SECURITY-08, SECURITY-12).
**Scope**: `POST /api/auth/logout`, protected endpoints, the backend console/log output.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.5 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.5"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000` (Swagger UI at `/docs`); frontend dev `http://localhost:5173` (proxies `/api`) |
| Local services that must be up | none |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (user_id 1) |
| Log output | The backend terminal where Uvicorn runs (INFO level) — TO CONFIRM if logs are written anywhere else |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-SEC-01 — Logout is logged at INFO without token, email or password

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-NF-01 (SECURITY-03) |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | Backend running in a visible terminal |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Log in; copy the token S1.
2. `POST /api/auth/logout` with S1.
3. Inspect the backend output produced by steps 1–2 (search for S1, `tpg@example.com` and `password`).

**Expected result**
- An INFO line identifying a `logout` event with `user_id=1` (or equivalent user ID field).
- No log line contains S1, `tpg@example.com` or `password`.

**Pass/Fail criteria**: PASS if the logout event is logged by user ID and no secret/PII appears.
**Cleanup**: none.

### TC-SEC-02 — Expired-session rejection is logged without the token

| Field | Value |
|-------|-------|
| **Traces to** | AC-5, AC-1 / SECURITY-03 |
| **Type** | Security |
| **Priority** | P2 |
| **Preconditions** | Backend started with the shortest supported `SESSION_TTL_HOURS` (see api-test-steps.md) |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Log in; copy S1; wait past the lifetime.
2. `GET /api/billing` with S1.
3. Inspect the backend output.

**Expected result**
- Response 401.
- If an expiry event is logged, it is INFO, identifies the user by ID only, and does not contain S1 or the email. TO CONFIRM (dev): whether an expiry rejection emits a log line (AC-5 says "a logout or an expired-session rejection").

**Pass/Fail criteria**: PASS if no secret/PII appears and, per the confirmed behaviour, the expiry is logged.
**Cleanup**: restart with default settings.

### TC-SEC-03 — A revoked token cannot be reused anywhere (fail closed)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-3 / SECURITY-08, SECURITY-12 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | Backend running; story 1.1 endpoints present |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Log in; note S1; log out with S1.
2. Call each with S1: `GET /api/users/me`, `GET /api/billing`, `GET /api/billing/upgrade/preview`, `POST /api/billing/upgrade`, `POST /api/auth/logout`.
3. `GET /api/billing` for the seeded user via a fresh login.

**Expected result**
- Step 2: every call returns 401 `{"detail": "Not authenticated"}`.
- Step 3: the seeded user is still `Standard` (the rejected upgrade did nothing).

**Pass/Fail criteria**: PASS if no endpoint accepts the revoked token and no state changed.
**Cleanup**: none.

### TC-SEC-04 — Error responses for invalid logout reveal nothing (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / SECURITY-15 |
| **Type** | Security |
| **Priority** | P3 |
| **Preconditions** | Backend running |
| **Test data** | `Authorization: Bearer ' OR 1=1 --`; `Authorization: Bearer <5000 x "a">` |

**Steps**
1. Send `POST /api/auth/logout` with each header.

**Expected result**
- Each response is 401 `{"detail": "Not authenticated"}` with no stack trace, exception text or internal detail; the server keeps running.

**Pass/Fail criteria**: PASS if both are clean 401s.
**Cleanup**: none.
