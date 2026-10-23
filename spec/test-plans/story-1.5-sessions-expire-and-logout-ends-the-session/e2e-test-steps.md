# E2E Test Steps — Story 1.5 Sessions expire and logout ends the session

**Purpose**: verify the Logout button ends the server session and always signs the user out locally, even
when the logout request fails.
**Scope**: Billing page header Logout button, sign-in page, browser storage.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.5 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.5"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend dev `http://localhost:5173` (proxies `/api` to backend `http://localhost:8000`) |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` |
| Tools | Browser DevTools (Network tab, Application > Local Storage) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-E2E-01 — Logout calls the server, clears local state and shows sign-in

| Field | Value |
|-------|-------|
| **Traces to** | AC-4, AC-2 / REQ-F-03, REQ-F-16 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Signed out; DevTools open on the Network tab |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in at `http://localhost:5173/login`; note the `token` value in Local Storage.
2. On the Billing page click `Logout`.
3. Inspect the Network tab and Local Storage.
4. With an HTTP client, call `GET http://localhost:8000/api/billing` with `Authorization: Bearer <noted token>`.

**Expected result**
- Step 3: a `POST /api/auth/logout` request was sent with `Authorization: Bearer <token>`; the app is on the sign-in page; Local Storage has no `token`.
- Step 4: 401 — the server session really ended.

**Pass/Fail criteria**: PASS if all expectations hold.
**Cleanup**: none.

### TC-E2E-02 — Logout still signs the user out when the logout request fails

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-03 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Signed in on the Billing page |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. In DevTools, block the request URL `*/api/auth/logout` (Network request blocking), or stop the backend process.
2. Click `Logout`.

**Expected result**
- The app shows the sign-in page; Local Storage has no `token`; no error screen.

**Pass/Fail criteria**: PASS if the user is signed out locally despite the failed call.
**Cleanup**: unblock the URL / restart the backend.

### TC-E2E-03 — After logout, browser Back does not show billing data (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4, AC-2 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | Signed in on the Billing page |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Click `Logout`.
2. Press the browser Back button; then navigate directly to `http://localhost:5173/billing`.

**Expected result**
- The user is sent to the sign-in page each time; no billing data is displayed.

**Pass/Fail criteria**: PASS if billing is never shown without signing in again.
**Cleanup**: none.

### TC-E2E-04 — Session expiry during use returns the user to sign-in

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-03 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | Backend started with the shortest supported `SESSION_TTL_HOURS` (see api-test-steps.md); story 1.6 present in the build for the automatic redirect |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in; wait past the session lifetime.
2. Reload the Billing page.

**Expected result**
- The user lands on the sign-in page with no stored token.

**Pass/Fail criteria**: PASS if the expired session is not usable from the UI.
**Cleanup**: restart the backend with defaults.
