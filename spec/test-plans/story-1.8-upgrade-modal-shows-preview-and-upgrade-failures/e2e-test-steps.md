# E2E Test Steps — Story 1.8 Upgrade modal shows preview and upgrade failures

**Purpose**: prove that preview and upgrade failures are shown inside the dialog, that the page data stays
unchanged on failure, and that Confirm cannot send two upgrade requests.
**Scope**: AC-1, AC-2, AC-3 (announcement of errors is in `accessibility-test-steps.md`).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.8 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.8"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000`; frontend dev server `http://localhost:5173` (proxies `/api`) |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard). Restart the backend before each case to reset it to Standard. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

**Black-box failure injection used below**
- *Network error*: DevTools > Network > "Block request URL" for the endpoint, or stop the backend process.
- *400 "Already on Premium plan"*: the same account is upgraded in a second browser window (separate sign-in,
  e.g. a private window) while the first window still shows Standard.
- *Slow response*: DevTools > Network throttling "Slow 3G" (or a custom profile with 3000 ms latency).

---

### TC-E2E-01 — Preview fails with a network error

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-15 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; signed in as `tpg@example.com` on the Billing page |
| **Test data** | Blocked URL pattern `*/api/billing/upgrade/preview` |

**Steps**
1. In DevTools, block the URL pattern `*/api/billing/upgrade/preview`.
2. Click "Upgrade to Premium".

**Expected result**
- The dialog opens and shows "Something went wrong. Please try again."
- "Confirm Upgrade" is disabled.
- The user stays signed in (no redirect to sign-in).

**Pass/Fail criteria**: PASS only if the message is shown, Confirm is disabled and the user is not signed out.
**Cleanup**: Remove the URL block; click "Cancel".

### TC-E2E-02 — Preview refused with 400 "Already on Premium plan"

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-15 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; backend freshly restarted; two browser windows (normal + private) |
| **Test data** | `tpg@example.com` / `password` in both windows |

**Steps**
1. Window A: sign in, stay on the Billing page showing Standard.
2. Window B: sign in with the same account, click "Upgrade to Premium", then "Confirm Upgrade"; wait for Premium to show.
3. Window A (do not reload): click "Upgrade to Premium".

**Expected result**
- Window A's dialog shows "Already on Premium plan".
- "Confirm Upgrade" is disabled.

**Pass/Fail criteria**: PASS if the server's message is shown and Confirm is disabled.
**Cleanup**: Close both windows; restart the backend.

### TC-E2E-03 — Preview fails with a server error (500)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-15 |
| **Type** | E2E |
| **Priority** | P3 |
| **Preconditions** | SUT running; signed in |
| **Test data** | TO CONFIRM: a black-box way to make `GET /api/billing/upgrade/preview` return 500 (none is documented; dev team to advise, or execute via DevTools "Override content"/response override returning status 500 with body `{"detail": "Internal server error"}`) |

**Steps**
1. Arrange for the preview request to return 500 with `{"detail": "Internal server error"}` (see Test data).
2. Click "Upgrade to Premium".

**Expected result**
- The dialog shows "Internal server error"; "Confirm Upgrade" is disabled; the user stays signed in.

**Pass/Fail criteria**: PASS if the message is shown and Confirm disabled.
**Cleanup**: Remove any override; click "Cancel".

### TC-E2E-04 — Upgrade fails with a network error; dialog stays open, page unchanged

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-15 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; backend freshly restarted; signed in on the Billing page |
| **Test data** | Blocked URL pattern `*/api/billing/upgrade` (exact path, not the preview) |

**Steps**
1. Click "Upgrade to Premium" and wait for the charge text.
2. In DevTools, block the URL `http://localhost:5173/api/billing/upgrade` (exact match).
3. Click "Confirm Upgrade".

**Expected result**
- The dialog stays open and shows "Something went wrong. Please try again."
- "Confirm Upgrade" is enabled again.
- Behind the dialog the page still shows "Standard" and `$20/month`.

**Pass/Fail criteria**: PASS only if all three expectations hold.
**Cleanup**: Remove the block; click "Cancel".

### TC-E2E-05 — Retry after a failed upgrade succeeds (recovery)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-15, REQ-F-12 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | State at the end of TC-E2E-04 step 3 (block still active) |
| **Test data** | — |

**Steps**
1. Remove the URL block.
2. Click "Confirm Upgrade" again.

**Expected result**
- The dialog closes; the page shows "Premium", `$40/month`, the unchanged renewal date, and the success message.

**Pass/Fail criteria**: PASS if the second attempt upgrades successfully.
**Cleanup**: Restart the backend.

### TC-E2E-06 — Upgrade refused with 400 "Already on Premium plan"

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-15 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Backend freshly restarted; two browser windows (normal + private) |
| **Test data** | `tpg@example.com` / `password` in both |

**Steps**
1. Window A: sign in, click "Upgrade to Premium", wait for the charge text (do not confirm).
2. Window B: sign in with the same account, upgrade to Premium and confirm.
3. Window A: click "Confirm Upgrade".

**Expected result**
- Window A's dialog stays open showing "Already on Premium plan".
- "Confirm Upgrade" is enabled again.
- Window A's page behind the dialog still shows "Standard" (no reload happened).

**Pass/Fail criteria**: PASS only if all expectations hold.
**Cleanup**: Close windows; restart the backend.

### TC-E2E-07 — Confirm cannot send the upgrade twice

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-12 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Backend freshly restarted; signed in; Network tab open and cleared |
| **Test data** | Network throttling "Slow 3G" |

**Steps**
1. Click "Upgrade to Premium" and wait for the charge text.
2. Enable "Slow 3G" throttling.
3. Click "Confirm Upgrade" twice in quick succession (and press Enter on it once more if it still has focus).
4. While waiting, observe the button. After the response arrives, count `POST /api/billing/upgrade` requests.

**Expected result**
- The button is disabled (not clickable) while the request is in flight.
- Exactly one `POST /api/billing/upgrade` request was sent.
- The upgrade completes once (Premium shown).

**Pass/Fail criteria**: FAIL if more than one upgrade request is sent or the button stays clickable during the request.
**Cleanup**: Disable throttling; restart the backend.

### TC-E2E-08 — Confirm is disabled while the preview is still loading (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-11, REQ-F-12 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | Signed in; Network tab open |
| **Test data** | Network throttling "Slow 3G" |

**Steps**
1. Enable "Slow 3G".
2. Click "Upgrade to Premium" and immediately try to click "Confirm Upgrade" before the charge text appears.

**Expected result**
- "Confirm Upgrade" is disabled until the charge text is shown; no `POST /api/billing/upgrade` is sent by the early click.

**Pass/Fail criteria**: PASS if no upgrade request is sent before the preview has loaded.
**Cleanup**: Disable throttling; click "Cancel".
