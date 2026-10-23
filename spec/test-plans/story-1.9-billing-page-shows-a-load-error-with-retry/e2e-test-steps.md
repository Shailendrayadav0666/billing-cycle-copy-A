# E2E Test Steps — Story 1.9 Billing page shows a load error with Retry

**Purpose**: prove that a failed billing load shows an error with a Retry action instead of an endless
loading message, and that Retry recovers.
**Scope**: AC-1, AC-2 (announcement is in `accessibility-test-steps.md`).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.9 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.9"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000`; frontend dev server `http://localhost:5173` (proxies `/api`) |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard, renews "Oct 30, 2026") |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

**Black-box failure injection**: DevTools > Network > "Block request URL" for the exact URL
`http://localhost:5173/api/billing` (exact match, so `/api/users/me` and sign-in keep working).

---

### TC-E2E-01 — Network error on billing load shows an error with Retry

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-15 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | SUT running; signed in as `tpg@example.com` |
| **Test data** | Blocked exact URL `http://localhost:5173/api/billing` |

**Steps**
1. Block the exact URL `http://localhost:5173/api/billing`.
2. Reload the Billing page (`http://localhost:5173/billing`).
3. Wait 10 seconds.

**Expected result**
- The page shows "Something went wrong. Please try again." and a "Retry" button.
- The text "Loading billing..." is not shown after the request fails.
- The user is still signed in (header shows the user's name).

**Pass/Fail criteria**: FAIL if "Loading billing..." remains, no Retry button appears, or the user is signed out.
**Cleanup**: Remove the block.

### TC-E2E-02 — Server error on billing load shows the server's message

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-15 |
| **Type** | E2E |
| **Priority** | P3 |
| **Preconditions** | SUT running; signed in |
| **Test data** | TO CONFIRM: a black-box way to make `GET /api/billing` return 500 `{"detail": "Internal server error"}` (none documented; dev team to advise, or use a DevTools response override with status 500) |

**Steps**
1. Arrange for `GET /api/billing` to return 500 with `{"detail": "Internal server error"}`.
2. Reload the Billing page.

**Expected result**
- The page shows "Internal server error" and a "Retry" button; "Loading billing..." is not shown.

**Pass/Fail criteria**: PASS if the server's detail and Retry are shown.
**Cleanup**: Remove any override.

### TC-E2E-03 — Backend stopped: error with Retry, not endless loading

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-15 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | SUT running; signed in on the Billing page |
| **Test data** | — |

**Steps**
1. Stop the backend process (leave the frontend dev server running).
2. Click the "Billing" navigation link (or reload the page).

**Expected result**
- An error message with a "Retry" button is shown instead of "Loading billing...". TO CONFIRM: if session restore (`/api/users/me`) also fails with the backend down, the exact screen may differ — record what is shown.

**Pass/Fail criteria**: FAIL if the page shows "Loading billing..." indefinitely.
**Cleanup**: Start the backend again; sign in again if needed (sessions are in memory).

### TC-E2E-04 — Retry recovers once the server answers

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-15 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | State at the end of TC-E2E-01 step 3 (error and Retry shown, block active) |
| **Test data** | — |

**Steps**
1. Remove the URL block.
2. Click "Retry".

**Expected result**
- The page shows plan "Standard", `$20/month`, renewal "Oct 30, 2026" and the feature cards.
- The error message is no longer shown.
- The browser did not perform a full page reload (Network tab shows only a new `GET /api/billing`, no new document request).

**Pass/Fail criteria**: PASS only if billing renders and the error is gone.
**Cleanup**: None.

### TC-E2E-05 — Retry while the server still fails keeps the error (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-15 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | State at the end of TC-E2E-01 step 3 (block still active) |
| **Test data** | — |

**Steps**
1. Click "Retry" with the block still active.
2. Observe the page and the Network tab.

**Expected result**
- A new `GET /api/billing` request is sent.
- The error message and "Retry" button are shown again; the page does not get stuck on "Loading billing...".

**Pass/Fail criteria**: PASS if a new request is made and the error state returns.
**Cleanup**: Remove the block.
