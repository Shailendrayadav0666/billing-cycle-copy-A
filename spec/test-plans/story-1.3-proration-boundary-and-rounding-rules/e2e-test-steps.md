# E2E Test Steps — Story 1.3 Proration boundary and rounding rules

**Purpose**: verify that the upgrade dialog shows the boundary and rounded charges exactly as `$X.XX` with the
matching number of days, and that the upgrade still completes at a zero charge.
**Scope**: AC-1, AC-2, AC-3 (REQ-F-06, REQ-NF-06).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.3 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.3"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend dev server `http://localhost:5173`; backend `http://localhost:8000` |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (renew_at `Oct 30, 2026`) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

Controlling "today": set the date of the machine running the **backend**, then restart the backend (see the
table in `api-test-steps.md`). The dialog must show the server's values regardless of the browser machine's
date. TO CONFIRM (dev): supported way to fix the server date (OS clock or test hook).

---

### TC-E2E-01 — The dialog shows a rounded charge with the matching days

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-06, REQ-NF-06 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Backend date Oct 23, 2026; backend restarted |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in and click "Upgrade to Premium".
2. Read the charge sentence.
3. Repeat with backend date Oct 29, 2026 (restart, sign in, open dialog).

**Expected result**
- Step 2: `You'll be charged $4.67 today for the 7 days remaining in your cycle.`
- Step 3: `You'll be charged $0.67 today for the 1 days remaining in your cycle.` TO CONFIRM (BA): whether "1 days" should read "1 day" (the AC text uses the plural template).
- The amount always shows exactly two decimals.

**Pass/Fail criteria**: PASS if both sentences match exactly (amount and days); FAIL otherwise.
**Cleanup**: restart the backend; restore the machine date.

### TC-E2E-02 — A past renewal date shows $0.00 and the upgrade still completes

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-06 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Backend date Nov 05, 2026; backend restarted |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in, click "Upgrade to Premium".
2. Read the charge sentence; click "Confirm Upgrade".

**Expected result**
- Step 2 dialog: `You'll be charged $0.00 today for the 0 days remaining in your cycle.` (never a negative amount or negative days).
- After confirm: badge `Premium`, `$40/month`, renewal date still `Oct 30, 2026`.

**Pass/Fail criteria**: PASS if the dialog shows $0.00 / 0 days and the upgrade completes; FAIL otherwise.
**Cleanup**: restart the backend; restore the machine date.

### TC-E2E-03 — A new subscriber with 30 days left is shown the full $20.00 difference

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-06 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | Backend on the real current date; freshly restarted |
| **Test data** | Register `sam@example.com` / `secret123` |

**Steps**
1. Register Sam through the sign-up form.
2. Click "Upgrade to Premium".

**Expected result**
- `You'll be charged $20.00 today for the 30 days remaining in your cycle.` (never more than $20.00).

**Pass/Fail criteria**: PASS if the sentence matches exactly; FAIL otherwise.
**Cleanup**: restart the backend.
