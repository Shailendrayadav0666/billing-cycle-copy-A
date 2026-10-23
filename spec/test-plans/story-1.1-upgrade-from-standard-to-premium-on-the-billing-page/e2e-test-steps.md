# E2E Test Steps — Story 1.1 Upgrade from Standard to Premium on the Billing page

**Purpose**: verify the complete user journeys in the browser: a Standard subscriber sees the upgrade button,
reviews the prorated charge, confirms, and sees Premium without a reload; existing sign-in, registration,
session restore and logout keep working.
**Scope**: AC-1, AC-2, AC-3, AC-5 (REQ-F-10, REQ-F-11, REQ-F-12, REQ-F-14, REQ-F-16, REQ-NF-02).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.1 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.1"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend dev server `http://localhost:5173` (proxies `/api` to the backend); backend `http://localhost:8000` |
| Local services that must be up | Backend and frontend dev server; nothing else |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard, renew_at `Oct 30, 2026`). Restart the backend before each case to restore seed data. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

Expected charge for today: `days = max(0, Oct 30, 2026 − today)`, `charge = 20.00 × min(days, 30) / 30` rounded half
up to 2 decimals (e.g. Oct 15 → 15 days → `$10.00`; Oct 23 → 7 days → `$4.67`).

---

### TC-E2E-01 — A Standard subscriber upgrades to Premium end to end

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2, AC-3 / REQ-F-10, REQ-F-11, REQ-F-12, REQ-F-14 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Fresh backend; browser with DevTools available; no one signed in |
| **Test data** | `tpg@example.com` / `password`; expected days and charge for today |

**Steps**
1. Open `http://localhost:5173/login`, sign in as `tpg@example.com` / `password`.
2. On the Billing page, read the "Current plan" badge and the "What's included with ..." heading.
3. Locate the "Upgrade to Premium" button and note where it sits.
4. Open DevTools > Network, then click "Upgrade to Premium".
5. Read the dialog content.
6. Click "Confirm Upgrade".
7. Watch the page and the Network tab.

**Expected result**
- Step 2: badge reads `Standard`; heading reads `What's included with Standard`.
- Step 3: "Upgrade to Premium" button is shown below the current plan card.
- Step 5: dialog shows `Standard ($20/mo)` and `Premium ($40/mo)`, `<days> days remaining in your cycle`, and `You'll be charged $<charge> today for the <days> days remaining in your cycle.`, with "Confirm Upgrade" and "Cancel" buttons; Network shows one `GET /api/billing/upgrade/preview` returning 200.
- Step 7: one `POST /api/billing/upgrade` returning 200; **no full page reload** (no document request in Network, scroll position kept); badge reads `Premium`; heading `What's included with Premium`; price `$40/month`; renewal date still `Oct 30, 2026`; feature cards `4K Ultra HD`, `Can watch on 4 devices at once`, `Can download on 6 devices`; perks include `Dolby Vision (select titles)`; no "Upgrade to Premium" button; message `You're now on Premium! Your next full cycle bills at $40/month.` is shown.

**Pass/Fail criteria**: PASS if every expectation holds; FAIL otherwise.
**Cleanup**: restart the backend.

### TC-E2E-02 — Opening the dialog commits nothing; Cancel leaves the page unchanged

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-11 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Fresh backend; signed in as `tpg@example.com` |
| **Test data** | — |

**Steps**
1. On the Billing page, open DevTools > Network and click "Upgrade to Premium".
2. Check that "Confirm Upgrade" is disabled until the charge text has appeared (throttle the network to "Slow 3G" in DevTools to observe it).
3. Click "Cancel".
4. Reload the page.

**Expected result**
- Step 2: "Confirm Upgrade" is disabled while the preview is loading, enabled once the charge is shown.
- Step 3: dialog closes; no `POST /api/billing/upgrade` request appears in Network.
- Step 4: page still shows `Standard`, `$20/month`, and the "Upgrade to Premium" button.

**Pass/Fail criteria**: PASS if no upgrade request was sent and the plan is still Standard; FAIL otherwise.
**Cleanup**: none.

### TC-E2E-03 — Plan labels and button follow the data for a newly registered user

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-10, REQ-F-14 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | Fresh backend; signed out |
| **Test data** | Register Nina / `nina@example.com` / `secret123` |

**Steps**
1. On the sign-in page, switch to sign-up and register Nina.
2. On the Billing page, read the badge, heading, renewal date and look for the button.
3. Upgrade via the dialog (Confirm).
4. Reload the page.

**Expected result**
- Step 2: badge `Standard`, heading `What's included with Standard`, renewal date = today + 30 days, "Upgrade to Premium" button shown.
- Step 3: the dialog shows `30 days remaining in your cycle` and `$20.00`; after confirm the badge reads `Premium`.
- Step 4 (negative): after reload the badge still reads `Premium`, heading `What's included with Premium`, and **no** "Upgrade to Premium" button is rendered.

**Pass/Fail criteria**: PASS if labels always match the plan and the button is absent once Premium; FAIL otherwise.
**Cleanup**: restart the backend.

### TC-E2E-04 — Existing sign-in, session restore, logout and registration still work

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-16 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Fresh backend; signed out |
| **Test data** | `tpg@example.com` / `password`; new user `nina2@example.com` / `secret123` |

**Steps**
1. Sign in as `tpg@example.com` / `password`.
2. Confirm the Billing page shows `Standard`, `$20/month`, renews `Oct 30, 2026`.
3. Reload the browser tab (F5).
4. Click "Logout".
5. Register a new account `nina2@example.com`.

**Expected result**
- Step 1–2: lands on `/billing` with the values shown.
- Step 3: still signed in on the Billing page (session restored, no sign-in form).
- Step 4: lands on the sign-in page.
- Step 5: lands on the Billing page showing `Standard`, `$20/month`, renewal = today + 30 days.

**Pass/Fail criteria**: PASS if every step behaves as before the change; FAIL otherwise.
**Cleanup**: restart the backend.

### TC-E2E-05 — Wrong credentials still show an error and do not sign in

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-16 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | Fresh backend; signed out |
| **Test data** | `tpg@example.com` / `wrong` |

**Steps**
1. Sign in with `tpg@example.com` / `wrong`.
2. Try to open `http://localhost:5173/billing` directly.

**Expected result**
- Step 1: the sign-in page shows an error (`Invalid credentials`) and stays on `/login`.
- Step 2: redirected to `/login`.

**Pass/Fail criteria**: PASS if no access is granted and the error is shown; FAIL otherwise.
**Cleanup**: none.
