# API Test Steps — Story 1.1 Upgrade from Standard to Premium on the Billing page

**Purpose**: verify, from outside the system, the HTTP contracts this story adds or changes: opaque session
tokens at sign-in/registration, Bearer-only identity on `/api/users/me` and `/api/billing`, and the new
`GET /api/billing/upgrade/preview` and `POST /api/billing/upgrade` endpoints.
**Scope**: AC-2, AC-3, AC-4, AC-5 of story 1.1 (REQ-F-01, REQ-F-02, REQ-F-06, REQ-F-07, REQ-F-08, REQ-F-09,
REQ-F-16, REQ-NF-01, REQ-NF-06). Source: `spec/plans/stories.md`, `spec/plans/functional-design.md` Section 4.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.1 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.1"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000` (Swagger UI at `/docs`); frontend dev server `http://localhost:5173` (proxies `/api` to the backend) |
| Local services that must be up | None besides the backend (and the frontend dev server for UI cases) — data is in memory |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard, `$20/month`, renew_at `Oct 30, 2026`). Restart the backend before each run to restore seed data. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

**Computing the expected charge** (functional-design BR-1/BR-2): `days = max(0, Oct 30, 2026 − today's date on the
backend machine)`; `charge = 20.00 × min(days, 30) / 30`, rounded half up to 2 decimals. Example: on Oct 15, 2026 →
15 days → `10.00`; on Oct 23, 2026 → 7 days → `4.67`. Write the expected values for today in each case before
running it.

Shell convention: commands below use `curl` (available on Windows 10+ and macOS/Linux). `$TOKEN` means "paste
the `access_token` value from TC-API-01".

---

### TC-API-01 — Sign-in returns an opaque session token, not the email

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-01 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Backend freshly started |
| **Test data** | `{"email": "tpg@example.com", "password": "password"}` |

**Steps**
1. `curl -s -i -X POST http://localhost:8000/api/auth/login -H "Content-Type: application/json" -d "{\"email\":\"tpg@example.com\",\"password\":\"password\"}"`
2. Note the `access_token` value.

**Expected result**
- Status `200`.
- `access_token` is not `tpg@example.com` and does not contain `tpg@example.com` or `tpg`.
- `access_token` is at least 43 characters long and looks random (URL-safe characters only).
- `user` contains `id`, `name`, `email`, `plan` = `Standard`, `price` = `$20/month`, `renew_at` = `Oct 30, 2026`, and has **no** `password` field.

**Pass/Fail criteria**: PASS if every expectation holds; FAIL otherwise.
**Cleanup**: none (keep the token for the next cases).

### TC-API-02 — `/api/users/me` and `/api/billing` return the caller's data with a Bearer token

| Field | Value |
|-------|-------|
| **Traces to** | AC-4, AC-5 / REQ-F-02, REQ-F-16 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | TC-API-01 done; `$TOKEN` from it |
| **Test data** | `$TOKEN` |

**Steps**
1. `curl -s -i http://localhost:8000/api/users/me -H "Authorization: Bearer $TOKEN"`
2. `curl -s -i http://localhost:8000/api/billing -H "Authorization: Bearer $TOKEN"`

**Expected result**
- Step 1: `200`; body has `email` = `tpg@example.com`, `plan` = `Standard`; no `password` field.
- Step 2: `200`; `plan_name` = `Standard`, `price` = `$20/month`, `renew_at` = `Oct 30, 2026`; usages "Video quality" = `Full HD (1080p)`, "Watch at the same time" = `Can watch on 2 devices at once`, "Download on devices" = `Can download on 2 devices`; perks "Ad-free streaming", "Spatial audio (select titles)".

**Pass/Fail criteria**: PASS if both responses match exactly; FAIL otherwise.
**Cleanup**: none.

### TC-API-03 — Preview returns the server-calculated charge for the session's user

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-06, REQ-F-07, REQ-NF-06 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Fresh backend; `$TOKEN` for `tpg@example.com` (Standard) |
| **Test data** | Expected `days` and `charge` for today computed per the formula above |

**Steps**
1. `curl -s -i http://localhost:8000/api/billing/upgrade/preview -H "Authorization: Bearer $TOKEN"`

**Expected result**
- Status `200`.
- Body: `current_plan` = `Standard`, `current_price` = `$20/month`, `new_plan` = `Premium`, `new_price` = `$40/month`, `days_remaining` = expected days, `days_in_cycle` = `30`, `prorated_charge` = expected charge (number with 2 decimals, e.g. `10.0`/`10.00` for 15 days), `renew_at` = `Oct 30, 2026`.

**Pass/Fail criteria**: PASS if every field matches the expected values computed for today; FAIL otherwise.
**Cleanup**: none.

### TC-API-04 — Preview does not change the plan (no commitment)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-07 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | TC-API-03 done (preview called at least once) |
| **Test data** | `$TOKEN` |

**Steps**
1. Call the preview endpoint two more times (same command as TC-API-03).
2. `curl -s http://localhost:8000/api/billing -H "Authorization: Bearer $TOKEN"`
3. `curl -s http://localhost:8000/api/users/me -H "Authorization: Bearer $TOKEN"`

**Expected result**
- Step 1 responses are identical to TC-API-03.
- Step 2: `plan_name` still `Standard`, `price` still `$20/month`.
- Step 3: `plan` still `Standard`.

**Pass/Fail criteria**: PASS if nothing changed after previews; FAIL if any plan/price field changed.
**Cleanup**: none.

### TC-API-05 — Upgrade applies Premium, returns the charge and keeps the renewal date

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-05, REQ-F-08, REQ-F-09 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Fresh backend; `$TOKEN` for `tpg@example.com` (Standard) |
| **Test data** | Expected charge for today (formula above) |

**Steps**
1. `curl -s -i -X POST http://localhost:8000/api/billing/upgrade -H "Authorization: Bearer $TOKEN"`
2. `curl -s http://localhost:8000/api/users/me -H "Authorization: Bearer $TOKEN"`
3. `curl -s http://localhost:8000/api/billing -H "Authorization: Bearer $TOKEN"`

**Expected result**
- Step 1: `200`; `plan_name` = `Premium`, `price` = `$40/month`, `renew_at` = `Oct 30, 2026`, `prorated_charge` = expected charge; `usages`: "Video quality" = `4K Ultra HD`, "Watch at the same time" = `Can watch on 4 devices at once`, "Download on devices" = `Can download on 6 devices`; `included_usage.items` = "Ad-free streaming", "Spatial audio (select titles)", "Dolby Vision (select titles)" (each `used_percent` 100); `included_usage.help` = `Perks included in your Premium plan.`
- Step 2: `plan` = `Premium`, `price` = `$40/month`, `renew_at` = `Oct 30, 2026`.
- Step 3: same Premium billing as step 1 (without `prorated_charge` is acceptable), `renew_at` = `Oct 30, 2026`.

**Pass/Fail criteria**: PASS if all three responses match; FAIL otherwise.
**Cleanup**: restart the backend to restore the Standard seed user.

### TC-API-06 — Protected endpoints reject missing or unknown tokens

| Field | Value |
|-------|-------|
| **Traces to** | AC-4, AC-3 / REQ-F-02 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Fresh backend |
| **Test data** | Table below |

**Steps** — for each row, send the request and record status and body:

| # | Request | Credential |
|---|---------|-----------|
| a | `GET /api/users/me` | no `Authorization` header |
| b | `GET /api/billing` | `Authorization: Bearer not-a-real-token` |
| c | `GET /api/billing/upgrade/preview` | no `Authorization` header |
| d | `POST /api/billing/upgrade` | `Authorization: Bearer tpg@example.com` |
| e | `POST /api/billing/upgrade` | `Authorization: tpg@example.com` (no `Bearer` prefix) |

Example: `curl -s -i -X POST http://localhost:8000/api/billing/upgrade -H "Authorization: Bearer tpg@example.com"`

**Expected result**
- Every row: status `401`, body `{"detail": "Not authenticated"}`.
- After row d/e, sign in (TC-API-01) and confirm `GET /api/billing` still shows `Standard` (no upgrade happened).

**Pass/Fail criteria**: PASS if all five rows return 401 with that detail and no upgrade occurred; FAIL otherwise.
**Cleanup**: none.

### TC-API-07 — The `email` query parameter no longer grants access

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-02 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Fresh backend |
| **Test data** | `email=tpg@example.com` |

**Steps**
1. `curl -s -i "http://localhost:8000/api/users/me?email=tpg@example.com"`
2. `curl -s -i "http://localhost:8000/api/billing?email=tpg@example.com"`

**Expected result**
- Both: status `401`, `{"detail": "Not authenticated"}`; no user or billing data in the body.

**Pass/Fail criteria**: PASS if both are 401 with no data; FAIL if any data is returned.
**Cleanup**: none.

### TC-API-08 — Registration returns an opaque token and a Standard account

| Field | Value |
|-------|-------|
| **Traces to** | AC-5, AC-4 / REQ-F-01, REQ-F-16 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | Fresh backend |
| **Test data** | `{"name": "Nina", "email": "nina@example.com", "password": "secret123"}` |

**Steps**
1. `curl -s -i -X POST http://localhost:8000/api/auth/register -H "Content-Type: application/json" -d "{\"name\":\"Nina\",\"email\":\"nina@example.com\",\"password\":\"secret123\"}"`
2. With the returned token: `curl -s http://localhost:8000/api/billing -H "Authorization: Bearer <token>"`

**Expected result**
- Step 1: `200`; `access_token` does not contain `nina`; `user.plan` = `Standard`; `user.renew_at` = today + 30 days in `MMM DD, YYYY` format; no `password` field.
- Step 2: `200`; `plan_name` = `Standard`, `price` = `$20/month`, `renew_at` = today + 30 days.

**Pass/Fail criteria**: PASS if both hold; FAIL otherwise.
**Cleanup**: restart the backend.

### TC-API-09 — Wrong credentials and duplicate registration are still rejected

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-16 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | Fresh backend |
| **Test data** | Wrong password `wrong`; duplicate email `tpg@example.com` |

**Steps**
1. `POST /api/auth/login` with `{"email":"tpg@example.com","password":"wrong"}`.
2. `POST /api/auth/register` with `{"name":"Dup","email":"tpg@example.com","password":"secret123"}`.

**Expected result**
- Step 1: `401`, `{"detail": "Invalid credentials"}`, no `access_token`.
- Step 2: `400`, `{"detail": "Account already exists"}`.

**Pass/Fail criteria**: PASS if both statuses and details match; FAIL otherwise.
**Cleanup**: none.

### TC-API-10 — Oversized and malformed input is rejected without internal details

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-01 (SECURITY-05, SECURITY-15) |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | Fresh backend |
| **Test data** | Email of 300 characters (`aaaa…a@example.com`); name of 101 characters; password of 129 characters; email `not-an-email` |

**Steps**
1. `POST /api/auth/login` with the 300-character email and password `password`.
2. `POST /api/auth/register` with a 101-character name (valid email/password).
3. `POST /api/auth/register` with a 129-character password.
4. `POST /api/auth/login` with email `not-an-email`.
5. `POST /api/auth/login` with body `{not json`.

**Expected result**
- Steps 1–5: status `422` (validation error); response contains no stack trace, file paths or Python exception text.
- Max lengths accepted at the boundary: email 254, name 100, password 128 (spot-check one: a 100-character name registers successfully).

**Pass/Fail criteria**: PASS if all oversized/malformed inputs get 422 without internals and the boundary value is accepted; FAIL otherwise.
**Cleanup**: restart the backend.
