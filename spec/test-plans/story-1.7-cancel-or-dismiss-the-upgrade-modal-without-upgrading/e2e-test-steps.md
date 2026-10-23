# E2E Test Steps — Story 1.7 Cancel or dismiss the upgrade modal without upgrading

**Purpose**: prove that every way of closing the upgrade dialog leaves the account on Standard and sends no
upgrade request, and that reopening shows a fresh preview.
**Scope**: AC-1, AC-4 (dialog semantics and focus are in `accessibility-test-steps.md`).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.7 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.7"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000`; frontend dev server `http://localhost:5173` (proxies `/api`) |
| Local services that must be up | Backend and frontend dev server; no datastore (in-memory) |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard). Restart the backend before each case to reset it to Standard. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-E2E-01 — Cancel button closes the dialog without upgrading

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-13 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; backend freshly restarted; browser DevTools Network tab open with "Preserve log" on |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Open `http://localhost:5173`, sign in as `tpg@example.com` / `password`.
2. On the Billing page, click "Upgrade to Premium" and wait until the charge text is shown.
3. Click "Cancel".
4. Inspect the Network tab.

**Expected result**
- The dialog closes.
- No `POST /api/billing/upgrade` request appears in the Network tab.
- The page still shows the "Standard" badge, `$20/month`, and the "Upgrade to Premium" button.

**Pass/Fail criteria**: PASS only if all three expectations hold.
**Cleanup**: None needed (no state changed).

### TC-E2E-02 — Close (X) button closes the dialog without upgrading

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-13 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | As TC-E2E-01 |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in and open the upgrade dialog as in TC-E2E-01 steps 1–2.
2. Click the close (X) button of the dialog.
3. Inspect the Network tab.

**Expected result**
- The dialog closes; no `POST /api/billing/upgrade` request is sent; page still shows Standard / `$20/month` with the upgrade button.

**Pass/Fail criteria**: PASS only if all expectations hold.
**Cleanup**: None.

### TC-E2E-03 — Escape key closes the dialog without upgrading

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-13 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | As TC-E2E-01 |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in and open the upgrade dialog.
2. Press the Escape key.
3. Inspect the Network tab.

**Expected result**
- The dialog closes; no `POST /api/billing/upgrade`; page still shows Standard / `$20/month` with the upgrade button.

**Pass/Fail criteria**: PASS only if all expectations hold.
**Cleanup**: None.

### TC-E2E-04 — Clicking the backdrop closes the dialog without upgrading

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-13 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | As TC-E2E-01 |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in and open the upgrade dialog.
2. Click on the dimmed area outside the dialog box.
3. Inspect the Network tab.

**Expected result**
- The dialog closes; no `POST /api/billing/upgrade`; page unchanged (Standard / `$20/month`, upgrade button visible).

**Pass/Fail criteria**: PASS only if all expectations hold.
**Cleanup**: None.

### TC-E2E-05 — Clicking inside the dialog does NOT close it (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-13 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | As TC-E2E-01 |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in and open the upgrade dialog.
2. Click on the dialog's body text (not on any button).

**Expected result**
- The dialog stays open with the charge text and both buttons visible.
- No `POST /api/billing/upgrade` request is sent.

**Pass/Fail criteria**: PASS if the dialog remains open and no upgrade request is sent.
**Cleanup**: Click "Cancel".

### TC-E2E-06 — Reopening after cancel requests a fresh preview

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-13 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | As TC-E2E-01; Network tab cleared before step 2 |
| **Test data** | `tpg@example.com` / `password` (renewal date "Oct 30, 2026") |

**Steps**
1. Sign in; clear the Network tab.
2. Click "Upgrade to Premium", wait for the charge text, click "Cancel".
3. Click "Upgrade to Premium" again and wait for the charge text.
4. Count `GET /api/billing/upgrade/preview` requests in the Network tab.

**Expected result**
- Exactly two `GET /api/billing/upgrade/preview` requests were sent (one per opening).
- The reopened dialog shows "You'll be charged $X.XX today for the N days remaining in your cycle." with the same values as the first time (same day).

**Pass/Fail criteria**: PASS if two preview requests are seen and the text is shown again.
**Cleanup**: Click "Cancel".

### TC-E2E-07 — Reopen after cancel never reuses a stale or failed preview (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 |
| **Type** | E2E |
| **Priority** | P3 |
| **Preconditions** | As TC-E2E-01; DevTools request blocking available |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in. In DevTools, block the URL pattern `*/api/billing/upgrade/preview`.
2. Click "Upgrade to Premium"; observe the dialog; click "Cancel".
3. Remove the URL block.
4. Click "Upgrade to Premium" again.

**Expected result**
- On reopening (step 4), the dialog shows the charge text from a new successful preview request, and "Confirm Upgrade" is enabled.
- TO CONFIRM: the message shown in step 2 belongs to story 1.8; here only the recovery on reopen is asserted.

**Pass/Fail criteria**: PASS if the reopened dialog shows a fresh, successful preview.
**Cleanup**: Click "Cancel"; ensure no URL blocks remain.
