# API Test Steps — Story 1.5 Sessions expire and logout ends the session

**Purpose**: verify session expiry and the new `POST /api/auth/logout` endpoint from the HTTP API.
**Scope**: `POST /api/auth/login`, `POST /api/auth/logout`, `GET /api/billing`, `GET /api/users/me`.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.5 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.5"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000` (Swagger UI at `/docs`); frontend dev `http://localhost:5173` (proxies `/api`) |
| Local services that must be up | none (in-memory sessions; restart the backend to reset) |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password`; `nina@example.com` / `secret123` registered during the test |
| Session lifetime | Env `SESSION_TTL_HOURS` (default 8). For expiry cases start the backend with a short lifetime — TO CONFIRM whether fractional hours (for example `SESSION_TTL_HOURS=0.01`, about 36 s) are accepted; the design says values below 1 fall back to 8, in which case expiry must be tested with `SESSION_TTL_HOURS=1` and a one-hour wait |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-API-01 — Expired session is rejected on protected endpoints

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-03 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Backend started with the shortest supported `SESSION_TTL_HOURS` (see System Under Test) |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. `POST /api/auth/login`; note `access_token` (S1) and the time.
2. Wait until the configured lifetime has passed (plus a few seconds).
3. `GET /api/billing` with `Authorization: Bearer S1`.
4. `GET /api/users/me` with S1.

**Expected result**
- Steps 3 and 4: status 401, body `{"detail": "Not authenticated"}`.

**Pass/Fail criteria**: PASS only if both calls return 401 with the exact detail.
**Cleanup**: restart the backend with default settings.

### TC-API-02 — Session within its lifetime is accepted (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-03 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Same short-lifetime backend as TC-API-01 |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Log in; note S1.
2. Before the lifetime has passed, `GET /api/billing` with S1.

**Expected result**
- Status 200 with the user's billing body.

**Pass/Fail criteria**: PASS if 200 before expiry.
**Cleanup**: none.

### TC-API-03 — Expired session cannot be revived (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | Continue from TC-API-01 (S1 already rejected once) |
| **Test data** | S1 |

**Steps**
1. Call `GET /api/billing` with S1 again.
2. Log in again; call `GET /api/billing` with the new token.

**Expected result**
- Step 1: still 401.
- Step 2: 200; the new token differs from S1.

**Pass/Fail criteria**: PASS if S1 stays dead and a fresh login works.
**Cleanup**: restart the backend.

### TC-API-04 — Logout invalidates the session on the server

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-03 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Backend running with default settings |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Log in; note S1. Confirm `GET /api/billing` with S1 returns 200.
2. `POST /api/auth/logout` with `Authorization: Bearer S1`.
3. `GET /api/billing` with S1; `GET /api/users/me` with S1.

**Expected result**
- Step 2: status 200, body `{"detail": "Logged out"}`.
- Step 3: both 401 `{"detail": "Not authenticated"}`.

**Pass/Fail criteria**: PASS if logout succeeds and the token is rejected everywhere afterwards.
**Cleanup**: none.

### TC-API-05 — Logging out twice with the same token (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-3 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | Continue from TC-API-04 |
| **Test data** | S1 (already logged out) |

**Steps**
1. `POST /api/auth/logout` with S1 again.

**Expected result**
- Status 401 `{"detail": "Not authenticated"}`.

**Pass/Fail criteria**: PASS if the second logout is refused.
**Cleanup**: none.

### TC-API-06 — Logout without a token, or with an unknown token, is refused and affects no one else

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-03, REQ-NF-01 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Backend running; register `nina@example.com` / `secret123` and keep her token S2 |
| **Test data** | No header; `Authorization: Bearer unknown-token`; `Authorization: tpg@example.com` (no Bearer) |

**Steps**
1. `POST /api/auth/logout` with no Authorization header.
2. `POST /api/auth/logout` with `Bearer unknown-token`.
3. `POST /api/auth/logout` with the malformed header.
4. `GET /api/billing` with S2.

**Expected result**
- Steps 1–3: each 401 `{"detail": "Not authenticated"}`.
- Step 4: 200 (Nina's session unaffected).

**Pass/Fail criteria**: PASS if every invalid logout is 401 and S2 still works.
**Cleanup**: restart the backend.

### TC-API-07 — Logout ends only the presented session (multiple sessions per user)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 |
| **Type** | API |
| **Priority** | P3 |
| **Preconditions** | Backend running |
| **Test data** | `tpg@example.com` / `password` logged in twice → SA and SB |

**Steps**
1. Log in twice; note SA and SB.
2. `POST /api/auth/logout` with SA.
3. `GET /api/billing` with SA and with SB.

**Expected result**
- SA → 401; SB → 200.

**Pass/Fail criteria**: PASS if only SA is revoked.
**Cleanup**: none.
