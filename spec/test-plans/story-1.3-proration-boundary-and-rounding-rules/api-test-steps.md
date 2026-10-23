# API Test Steps — Story 1.3 Proration boundary and rounding rules

**Purpose**: verify the prorated charge at the edges of the billing cycle and its rounding, through the preview
and upgrade endpoints.
**Scope**: AC-1, AC-2, AC-3, AC-4 (REQ-F-06, REQ-NF-06). Rules: `spec/plans/functional-design.md` BR-1, BR-2:
`days_remaining = max(0, renew_at − today)`; `charge = 20.00 × min(days, 30) / 30`, rounded half up to 2 decimals;
"today" is the backend machine's local date.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.3 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.3"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000` (Swagger UI at `/docs`) |
| Local services that must be up | Backend only |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard, renew_at `Oct 30, 2026`); fresh registrations get renew_at = today + 30 |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

## Controlling "today" (needed for most cases)

The seed user's renew_at is fixed at `Oct 30, 2026`, so days remaining is controlled by the **date of the machine
running the backend**. For each case: set that machine's date (OS date/time settings, automatic time sync off),
**restart the backend** (fresh seed data), then run the steps. Restore automatic time afterwards.
TO CONFIRM (dev): whether a supported test hook exists to fix the server date instead of changing the OS clock.

| Backend date | Seed user days_remaining | Expected prorated_charge |
|--------------|--------------------------|--------------------------|
| Nov 05, 2026 | 0 (renewal in the past) | 0.00 |
| Oct 30, 2026 | 0 (renewal today) | 0.00 |
| Oct 29, 2026 | 1 | 0.67 |
| Oct 23, 2026 | 7 | 4.67 |
| Oct 15, 2026 | 15 | 10.00 |
| Oct 01, 2026 | 29 | 19.33 |
| Sep 30, 2026 | 30 | 20.00 |
| Sep 15, 2026 | 45 | 20.00 |

Shell: `$TOKEN` = `access_token` from `POST /api/auth/login` as `tpg@example.com` / `password`.
Preview: `curl -s http://localhost:8000/api/billing/upgrade/preview -H "Authorization: Bearer $TOKEN"`.
Upgrade: `curl -s -X POST http://localhost:8000/api/billing/upgrade -H "Authorization: Bearer $TOKEN"`.

---

### TC-API-01 — Renewal date today: no charge, upgrade still proceeds

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-06 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Backend date Oct 30, 2026; backend restarted; `$TOKEN` |
| **Test data** | Seed user (renew_at `Oct 30, 2026`) |

**Steps**
1. Call the preview.
2. Call the upgrade.

**Expected result**
- Step 1: `200`; `days_remaining` `0`; `prorated_charge` `0.00` (JSON `0` / `0.0` accepted as the number zero).
- Step 2: `200`; `plan_name` `Premium`; `prorated_charge` `0.00`; `renew_at` `Oct 30, 2026`.

**Pass/Fail criteria**: PASS if both match; FAIL if the charge is non-zero or the upgrade is refused.
**Cleanup**: restart the backend.

### TC-API-02 — Renewal date in the past: no charge, never negative

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-06 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Backend date Nov 05, 2026; backend restarted; `$TOKEN` |
| **Test data** | Seed user |

**Steps**
1. Call the preview.
2. Call the upgrade.

**Expected result**
- Step 1: `200`; `days_remaining` `0` (not negative); `prorated_charge` `0.00` (not negative).
- Step 2: `200`; `plan_name` `Premium`; `prorated_charge` `0.00`.

**Pass/Fail criteria**: PASS if values are exactly zero and the upgrade succeeds; FAIL on any negative value or refusal.
**Cleanup**: restart the backend; restore the machine date.

### TC-API-03 — 30 days remaining charges the full difference (no clock change needed)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-06 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Backend on the real current date; freshly restarted |
| **Test data** | New user `sam@example.com` / `secret123` |

**Steps**
1. `POST /api/auth/register` with `{"name":"Sam","email":"sam@example.com","password":"secret123"}`; use its token.
2. Call the preview with Sam's token.

**Expected result**
- `200`; `renew_at` = today + 30 days; `days_remaining` `30`; `prorated_charge` `20.00`.

**Pass/Fail criteria**: PASS if exactly 30 days and 20.00; FAIL otherwise.
**Cleanup**: restart the backend.

### TC-API-04 — More than 30 days remaining is capped at the full difference

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-06 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | Backend date Sep 15, 2026 (then Sep 30, 2026); backend restarted each time; `$TOKEN` |
| **Test data** | Seed user |

**Steps**
1. With backend date Sep 15, 2026: call the preview.
2. With backend date Sep 30, 2026: restart, sign in, call the preview.

**Expected result**
- Step 1: `days_remaining` `45`; `prorated_charge` `20.00` (never more than 20.00).
- Step 2: `days_remaining` `30`; `prorated_charge` `20.00`.

**Pass/Fail criteria**: PASS if both charges are exactly 20.00; FAIL if any exceeds 20.00.
**Cleanup**: restart the backend; restore the machine date.

### TC-API-05 — Rounding is half up to two decimals

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-06, REQ-NF-06 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | One run per row below: set the backend date, restart, sign in, call the preview |
| **Test data** | Seed user |

**Steps** — for each row, record `days_remaining` and `prorated_charge`:

| Backend date | Expected days | Raw value | Expected charge | Actual |
|--------------|---------------|-----------|-----------------|--------|
| Oct 29, 2026 | 1 | 0.6666… | 0.67 (rounds up) | |
| Oct 23, 2026 | 7 | 4.6666… | 4.67 (rounds up) | |
| Oct 15, 2026 | 15 | 10.0 | 10.00 | |
| Oct 01, 2026 | 29 | 19.3333… | 19.33 (rounds down) | |

**Expected result**
- Every row matches its expected charge exactly, with at most 2 decimal places in the JSON number.

**Pass/Fail criteria**: PASS if all four rows match; FAIL on any mismatch (e.g. 0.66 or 4.66 means truncation instead of rounding).
**Cleanup**: restart the backend; restore the machine date.

### TC-API-06 — The charge is always a number between 0.00 and 20.00 with at most 2 decimals

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-06 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | Results from TC-API-01..05 |
| **Test data** | All recorded preview and upgrade responses |

**Steps**
1. For every recorded response, check the JSON type and range of `prorated_charge`.

**Expected result**
- `prorated_charge` is a JSON number (not a string), `0 ≤ value ≤ 20`, and has no more than 2 decimal places (no values like `4.666666`).

**Pass/Fail criteria**: PASS if every recorded value satisfies all three; FAIL otherwise.
**Cleanup**: none.

### TC-API-07 — Preview and upgrade on the same day return the identical charge

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-06 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Backend date Oct 23, 2026; restarted; `$TOKEN` |
| **Test data** | Seed user |

**Steps**
1. Call the preview; note `prorated_charge`.
2. Call the upgrade; note `prorated_charge`.

**Expected result**
- Both are `4.67`.

**Pass/Fail criteria**: PASS if identical; FAIL otherwise.
**Cleanup**: restart the backend; restore the machine date.

### TC-API-08 — The applied charge is recalculated by the server on the day of the upgrade

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-06 |
| **Type** | API |
| **Priority** | P3 |
| **Preconditions** | Backend date Oct 22, 2026; restarted; `$TOKEN` |
| **Test data** | Seed user |

**Steps**
1. Call the preview (expect 8 days, `5.33`).
2. Without restarting the backend, change the machine date to Oct 23, 2026.
3. Call the upgrade.

**Expected result**
- Step 3: `prorated_charge` `4.67` — the server recomputes from its own date at upgrade time; no client-supplied amount is used.

**Pass/Fail criteria**: PASS if the upgrade returns 4.67; FAIL if it returns the stale 5.33 or any other value.
**Cleanup**: restart the backend; restore the machine date.
TO CONFIRM (dev): whether changing the OS date without restarting is picked up by the running backend on this platform.
