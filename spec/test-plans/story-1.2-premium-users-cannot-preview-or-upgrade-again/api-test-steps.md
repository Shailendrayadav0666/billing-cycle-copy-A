# API Test Steps — Story 1.2 Premium users cannot preview or upgrade again

**Purpose**: verify that `GET /api/billing/upgrade/preview` and `POST /api/billing/upgrade` refuse a Premium
subscriber with HTTP 400 `Already on Premium plan` and change nothing.
**Scope**: AC-1, AC-2 (REQ-F-07, REQ-F-08). Contracts: `spec/plans/functional-design.md` Section 4, BR-3.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.2 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.2"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000` (Swagger UI at `/docs`); frontend dev server `http://localhost:5173` |
| Local services that must be up | Backend only for this file |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard, renew_at `Oct 30, 2026`). To get a Premium user: sign in and call `POST /api/billing/upgrade` once (story 1.1). Restart the backend to reset. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

**Common setup ("make tpg Premium")**: `POST /api/auth/login` as `tpg@example.com` / `password` → `$TOKEN`;
`curl -s -X POST http://localhost:8000/api/billing/upgrade -H "Authorization: Bearer $TOKEN"` → expect 200 and
`plan_name` `Premium`.

---

### TC-API-01 — Preview is refused for a Premium subscriber

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-07 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Fresh backend; common setup done (tpg is Premium); `$TOKEN` |
| **Test data** | `$TOKEN` |

**Steps**
1. `curl -s -i http://localhost:8000/api/billing/upgrade/preview -H "Authorization: Bearer $TOKEN"`

**Expected result**
- Status `400`; body exactly `{"detail": "Already on Premium plan"}`; no `prorated_charge` field.

**Pass/Fail criteria**: PASS if status and body match; FAIL otherwise.
**Cleanup**: none (reused by TC-API-03).

### TC-API-02 — Preview still works for the same user while Standard (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-07 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | Fresh backend (tpg is Standard); `$TOKEN` from sign-in |
| **Test data** | `$TOKEN` |

**Steps**
1. Call the preview endpoint (as in TC-API-01) before any upgrade.
2. Upgrade once (common setup).
3. Call the preview endpoint again.

**Expected result**
- Step 1: `200` with `current_plan` `Standard`.
- Step 3: `400` `Already on Premium plan` — the refusal starts exactly when the plan becomes Premium.

**Pass/Fail criteria**: PASS if the response flips from 200 to 400 across the upgrade; FAIL otherwise.
**Cleanup**: restart the backend.

### TC-API-03 — A second upgrade is refused and nothing changes

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-08 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Fresh backend; common setup done; `$TOKEN` |
| **Test data** | `$TOKEN` |

**Steps**
1. Record `GET /api/billing` and `GET /api/users/me` responses (with `$TOKEN`).
2. `curl -s -i -X POST http://localhost:8000/api/billing/upgrade -H "Authorization: Bearer $TOKEN"`
3. Repeat step 2 two more times.
4. Repeat step 1 and compare.

**Expected result**
- Steps 2–3: every call returns `400` with `{"detail": "Already on Premium plan"}`.
- Step 4: billing and user responses are identical to step 1 — `plan_name`/`plan` `Premium`, `price` `$40/month`, `renew_at` `Oct 30, 2026`, Premium usages unchanged.

**Pass/Fail criteria**: PASS if all repeat upgrades are 400 and no field changed; FAIL otherwise.
**Cleanup**: restart the backend.

### TC-API-04 — An unauthenticated second upgrade is refused as unauthenticated, not processed

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-08, REQ-F-02 |
| **Type** | API |
| **Priority** | P3 |
| **Preconditions** | Fresh backend; common setup done |
| **Test data** | No `Authorization` header |

**Steps**
1. `curl -s -i -X POST http://localhost:8000/api/billing/upgrade`
2. `curl -s -i http://localhost:8000/api/billing/upgrade/preview`

**Expected result**
- Both: `401` `{"detail": "Not authenticated"}` (authentication is checked before eligibility; no plan information leaks).

**Pass/Fail criteria**: PASS if both are 401 with that detail; FAIL otherwise.
**Cleanup**: restart the backend.
