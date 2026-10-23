# Security Test Steps — Story 1.6 Signed out on an invalid or expired session

**Purpose**: verify the frontend fails closed on an invalid session — no protected data shown, no stale
credential kept, and no forged email-style token accepted (SECURITY-08, SECURITY-12, SECURITY-15).
**Scope**: SPA session handling and browser storage.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.6 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.6"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend dev `http://localhost:5173` (proxies `/api` to backend `http://localhost:8000`) |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password`; second account `nina@example.com` / `secret123` |
| Tools | Browser DevTools (Network, Application > Local Storage) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-SEC-01 — A forged email-style token shows no account data

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-04 (SECURITY-08) |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | Register `nina@example.com`; sign out |
| **Test data** | Local Storage `token` = `nina@example.com` |

**Steps**
1. Set Local Storage `token` to `nina@example.com`.
2. Load `http://localhost:5173/billing`; watch the screen while it loads.

**Expected result**
- Nina's name, plan or billing data are never displayed; the user ends on the sign-in page; the token is removed.

**Pass/Fail criteria**: PASS if no data for that email appears at any point.
**Cleanup**: none.

### TC-SEC-02 — The invalid token is removed from storage after a 401

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / SECURITY-12 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | Signed in as the seed user |
| **Test data** | — |

**Steps**
1. Restart the backend; reload the Billing page.
2. Inspect Local Storage and Session Storage for any value containing the old token or the email.

**Expected result**
- No `token` key and no copy of the old token remains in browser storage.

**Pass/Fail criteria**: PASS if nothing session-related is left behind.
**Cleanup**: none.

### TC-SEC-03 — Sign-out after 401 shows no internal error details

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / SECURITY-15 |
| **Type** | Security |
| **Priority** | P3 |
| **Preconditions** | Signed in as the seed user |
| **Test data** | Local Storage `token` = `garbage-value-123` |

**Steps**
1. Set the token to the test data and reload.
2. Check the page and the browser console.

**Expected result**
- The sign-in page is shown without stack traces, raw JSON or error dialogs; the console shows at most the failed 401 network request (no unhandled exception).

**Pass/Fail criteria**: PASS if no internal detail is shown to the user and no unhandled error is thrown. TO CONFIRM (dev): whether a logged 401 network line in the console is acceptable (browsers log it by default).
**Cleanup**: none.
