# E2E Test Steps — Story 1.6 Signed out on an invalid or expired session

**Purpose**: verify that any 401 from a protected call — on page load, session restore, opening the upgrade
dialog or confirming the upgrade — clears the stored session and returns the user to sign-in once, without
loops or error screens.
**Scope**: SPA session restore, Billing page, upgrade dialog, sign-in page, browser storage.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.6 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.6"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend dev `http://localhost:5173` (proxies `/api` to backend `http://localhost:8000`) |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard plan) |
| Tools | Browser DevTools (Network tab, Application > Local Storage). A 401 is produced by invalidating the session: restart the backend (sessions are in memory) or log the token out from an HTTP client (`POST /api/auth/logout`, story 1.5) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-E2E-01 — 401 on Billing page load signs the user out

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-04, REQ-F-15 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Signed in as the seed user on the Billing page |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Restart the backend (invalidates the session; keep the browser tab open).
2. Reload `http://localhost:5173/billing`.
3. Inspect Local Storage.

**Expected result**
- The user is on the sign-in page; Local Storage has no `token`; no error screen and no endless "Loading billing...".

**Pass/Fail criteria**: PASS if all expectations hold.
**Cleanup**: none.

### TC-E2E-02 — 401 when opening the upgrade dialog signs the user out

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-04, REQ-F-15 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Signed in as the seed user (Standard) on the Billing page, data loaded |
| **Test data** | Seed user token (copy from Local Storage) |

**Steps**
1. From an HTTP client, `POST http://localhost:8000/api/auth/logout` with `Authorization: Bearer <token>` (or restart the backend).
2. In the browser, without reloading, click `Upgrade to Premium`.

**Expected result**
- The preview request returns 401; the user is taken to the sign-in page; Local Storage has no `token`; the dialog is not left open with an error.

**Pass/Fail criteria**: PASS if the 401 leads straight to sign-in.
**Cleanup**: none.

### TC-E2E-03 — 401 when confirming the upgrade signs the user out and does not upgrade

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-04, REQ-F-15 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Signed in as the seed user (Standard); upgrade dialog open with the charge shown |
| **Test data** | Seed user token |

**Steps**
1. Invalidate the token from an HTTP client (`POST /api/auth/logout`), keeping the dialog open.
2. Click `Confirm Upgrade`.
3. Sign in again as the seed user.

**Expected result**
- Step 2: the user is taken to the sign-in page; no stored token.
- Step 3: the Billing page still shows plan `Standard` and the `Upgrade to Premium` button.

**Pass/Fail criteria**: PASS if the user is signed out and the plan is unchanged.
**Cleanup**: none.

### TC-E2E-04 — 401 during session restore on app load signs the user out

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-04 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Signed in as the seed user; then close the tab |
| **Test data** | — |

**Steps**
1. Restart the backend.
2. Open a new tab at `http://localhost:5173/billing`.

**Expected result**
- `GET /api/users/me` returns 401; the user lands on the sign-in page; Local Storage has no `token`.

**Pass/Fail criteria**: PASS if the stale session never shows billing data.
**Cleanup**: none.

### TC-E2E-05 — Stale email-style token from before the upgrade feature is handled once

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-04 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Signed out; DevTools Network tab open with "Preserve log" on |
| **Test data** | Local Storage key `token` = `tpg@example.com` |

**Steps**
1. In DevTools > Application > Local Storage for `http://localhost:5173`, set `token` to `tpg@example.com`.
2. Load `http://localhost:5173/billing`.
3. Wait 10 seconds; count requests to `/api/users/me` in the Network tab.

**Expected result**
- Exactly one `GET /api/users/me` request (401); the user is on the sign-in page; Local Storage has no `token`; no error screen; no repeated requests or redirect loop.

**Pass/Fail criteria**: PASS only if the request count is exactly 1 and the user ends on sign-in.
**Cleanup**: none.

### TC-E2E-06 — A non-401 error does not sign the user out (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 (boundary: only 401 triggers sign-out) |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | Signed in as the seed user on the Billing page |
| **Test data** | — |

**Steps**
1. In DevTools, block the request URL `*/api/billing/upgrade/preview` (network error, not 401).
2. Click `Upgrade to Premium`.

**Expected result**
- The user stays signed in on the Billing page (the dialog shows an error per story 1.8 if present); Local Storage still has the `token`.

**Pass/Fail criteria**: PASS if no sign-out happens on a non-401 failure.
**Cleanup**: unblock the URL.

### TC-E2E-07 — After a 401 sign-out, signing in again works normally

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | Completed TC-E2E-05 (on the sign-in page) |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in.

**Expected result**
- The Billing page loads normally; Local Storage holds a new opaque token (not the email).

**Pass/Fail criteria**: PASS if sign-in recovers fully.
**Cleanup**: Log out.
