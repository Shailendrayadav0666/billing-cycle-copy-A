# E2E Test Steps — Story 1.10 Upgrade success message times out and can be dismissed

**Purpose**: prove the post-upgrade success message hides itself after about 5 seconds, can be dismissed
immediately, and leaves no timer running after the user leaves the page.
**Scope**: AC-2, AC-3, AC-4 (announcement and keyboard dismissal are in `accessibility-test-steps.md`).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.10 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.10"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000`; frontend dev server `http://localhost:5173` (proxies `/api`) |
| Local services that must be up | Backend and frontend dev server (dev mode, so React warnings appear in the console) |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard). Restart the backend before each case to reset it to Standard. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

Common setup ("upgrade now"): sign in as `tpg@example.com`, click "Upgrade to Premium", wait for the charge
text, click "Confirm Upgrade". Use a stopwatch for timing.

---

### TC-E2E-01 — Success message disappears after about 5 seconds

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-12 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Backend freshly restarted |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Perform "upgrade now"; start the stopwatch when the message appears.
2. Watch the message without interacting with the page.

**Expected result**
- "You're now on Premium! Your next full cycle bills at $40/month." is visible right after the upgrade.
- It disappears between 4 and 7 seconds after appearing (target 5 s).
- The page still shows "Premium" and `$40/month` after it disappears.

**Pass/Fail criteria**: FAIL if the message disappears before 4 s, is still visible after 7 s, or the plan display changes.
**Cleanup**: Restart the backend.

### TC-E2E-02 — Message is still visible shortly after appearing (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-12 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | Backend freshly restarted |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Perform "upgrade now".
2. At about 2 seconds after the message appears, check whether it is visible.

**Expected result**
- The message is still visible at 2 seconds.

**Pass/Fail criteria**: PASS if visible at 2 s.
**Cleanup**: Restart the backend.

### TC-E2E-03 — Dismiss button hides the message immediately

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-12 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Backend freshly restarted |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Perform "upgrade now".
2. Within 1 second, click the message's "Dismiss" button.

**Expected result**
- The message disappears immediately (well before 5 seconds).
- The page still shows "Premium" and `$40/month`.

**Pass/Fail criteria**: PASS if the message is gone at once and the plan display is unchanged.
**Cleanup**: Restart the backend.

### TC-E2E-04 — Dismissed message does not reappear when the timer would have fired (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-4 / REQ-F-12 |
| **Type** | E2E |
| **Priority** | P3 |
| **Preconditions** | Backend freshly restarted; DevTools Console open |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Perform "upgrade now" and click "Dismiss" immediately.
2. Wait 8 seconds.

**Expected result**
- The message stays hidden; no errors or warnings appear in the Console.

**Pass/Fail criteria**: PASS if the message never reappears and the Console is clean.
**Cleanup**: Restart the backend.

### TC-E2E-05 — Leaving the page before the timeout leaves no timer behind

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-12 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | Backend freshly restarted; frontend running in dev mode; DevTools Console open and cleared |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Perform "upgrade now".
2. Within 2 seconds, click "Logout" (this unmounts the Billing page).
3. Wait 8 seconds on the sign-in page.

**Expected result**
- No React warning (for example about updating state on an unmounted component) and no error appear in the Console.
- The sign-in page is unaffected.

**Pass/Fail criteria**: FAIL on any Console warning or error during the wait.
**Cleanup**: Restart the backend.

### TC-E2E-06 — No success message without an upgrade (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-12 |
| **Type** | E2E |
| **Priority** | P3 |
| **Preconditions** | Backend freshly restarted |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in, open the upgrade dialog, click "Cancel".

**Expected result**
- No success message is shown.

**Pass/Fail criteria**: PASS if no success message appears.
**Cleanup**: None.
