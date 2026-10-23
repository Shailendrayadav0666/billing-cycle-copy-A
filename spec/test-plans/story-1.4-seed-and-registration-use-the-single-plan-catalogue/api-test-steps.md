# API Test Steps — Story 1.4 Seed and registration use the single plan catalogue

**Purpose**: verify, from the HTTP API only, that seeded and newly registered users receive Standard billing
data built from the single plan catalogue, unchanged from before, and that duplicate registration is still
rejected.
**Scope**: `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/billing` (Bearer session).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.4 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.4"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000` (Swagger UI at `/docs`); frontend dev `http://localhost:5173` (proxies `/api`) |
| Local services that must be up | none (in-memory data; restart the backend to reset) |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (present on every start) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

Tools: Swagger UI at `http://localhost:8000/docs`, or any HTTP client (curl, Postman). All protected calls send
`Authorization: Bearer <access_token>` obtained from login/register.

---

### TC-API-01 — Seeded user's billing data is unchanged after a fresh start

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-05, REQ-F-16 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Backend freshly restarted (no prior registrations or upgrades) |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. `POST /api/auth/login` with `{"email": "tpg@example.com", "password": "password"}`; note `access_token`.
2. `GET /api/billing` with `Authorization: Bearer <access_token>`.

**Expected result**
- Status 200; `plan_name` = `Standard`, `price` = `$20/month`, `renew_at` = `Oct 30, 2026`.
- `usages`, in order: `Video quality` = `Full HD (1080p)`; `Watch at the same time` = `Can watch on 2 devices at once`; `Download on devices` = `Can download on 2 devices`; each with type `feature` and its help text.
- `included_usage.title` = `Plan perks`; items in order `Ad-free streaming` (100) and `Spatial audio (select titles)` (100); help = `Perks included in your Standard plan.`

**Pass/Fail criteria**: PASS only if every value and the order match exactly.
**Cleanup**: none.

### TC-API-02 — Newly registered user gets Standard catalogue data renewing in 30 days

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-05 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Backend running; note today's date on the backend host |
| **Test data** | `{"name": "Nina", "email": "nina.t14@example.com", "password": "secret123"}` |

**Steps**
1. `POST /api/auth/register` with the test data; note `access_token`.
2. `GET /api/billing` with that token.
3. Compare the body with TC-API-01's body.

**Expected result**
- Status 200; `plan_name` = `Standard`, `price` = `$20/month`, `renew_at` = today + 30 days in `MMM DD, YYYY` form (for example today `Oct 15, 2026` → `Nov 14, 2026`).
- Apart from `renew_at`, the body is identical (values and order) to the seeded user's body from TC-API-01.

**Pass/Fail criteria**: PASS if renew_at is exactly today + 30 days and every other field matches TC-API-01.
**Cleanup**: restart the backend.

### TC-API-03 — Duplicate registration is still rejected

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-16 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Backend running |
| **Test data** | `{"name": "Dup", "email": "tpg@example.com", "password": "anything1"}` |

**Steps**
1. `POST /api/auth/register` with the test data.
2. `POST /api/auth/login` as `tpg@example.com` / `password`, then `GET /api/billing`.

**Expected result**
- Step 1: status 400, body `{"detail": "Account already exists"}`; no `access_token`.
- Step 2: seeded user's billing unchanged (`Standard`, `$20/month`, `Oct 30, 2026`).

**Pass/Fail criteria**: PASS if 400 with the exact detail and the seeded account is untouched.
**Cleanup**: none.

### TC-API-04 — Registering the same new email twice (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4, AC-2 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | Backend freshly restarted |
| **Test data** | `{"name": "Twice", "email": "twice@example.com", "password": "secret123"}` |

**Steps**
1. `POST /api/auth/register` with the test data.
2. Repeat the same request.

**Expected result**
- Step 1: 200 with an `access_token`.
- Step 2: 400 `{"detail": "Account already exists"}`.

**Pass/Fail criteria**: PASS if only the first registration succeeds.
**Cleanup**: restart the backend.

### TC-API-05 — Billing of a seeded user is not altered by registrations (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | Backend freshly restarted |
| **Test data** | Three new registrations `r1@example.com`, `r2@example.com`, `r3@example.com` (password `secret123`) |

**Steps**
1. Register the three users.
2. Log in as `tpg@example.com` and `GET /api/billing`.

**Expected result**
- The seeded user's billing is still exactly as in TC-API-01.

**Pass/Fail criteria**: PASS if no field changed.
**Cleanup**: restart the backend.
