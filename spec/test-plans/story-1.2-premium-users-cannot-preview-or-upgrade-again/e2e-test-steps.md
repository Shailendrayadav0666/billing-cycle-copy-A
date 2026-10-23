# E2E Test Steps — Story 1.2 Premium users cannot preview or upgrade again

**Purpose**: verify in the browser that a Premium subscriber is never offered an upgrade, while a Standard
subscriber still is.
**Scope**: AC-3 (REQ-F-10).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.2 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.2"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend dev server `http://localhost:5173`; backend `http://localhost:8000` |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password`; a Premium user is made by upgrading once |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-E2E-01 — A Premium subscriber sees no upgrade button, now or after signing in again

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-10 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Fresh backend; signed out |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in as `tpg@example.com`, upgrade via "Upgrade to Premium" → "Confirm Upgrade".
2. Reload the page.
3. Log out, sign in again, open the Billing page.
4. Search the page (Ctrl+F) for "Upgrade to Premium".

**Expected result**
- Steps 2–3: badge reads `Premium`; heading `What's included with Premium`.
- Step 4: no "Upgrade to Premium" text or button is found (the success message from step 1 may be gone after reload).

**Pass/Fail criteria**: PASS if the button never appears for the Premium user; FAIL otherwise.
**Cleanup**: restart the backend.

### TC-E2E-02 — A Standard subscriber still sees the button (negative control)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-10 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | Fresh backend; another browser (or private window) signed in as a newly registered user `nina@example.com` / `secret123` while `tpg@example.com` is Premium (from TC-E2E-01 without restarting) |
| **Test data** | `nina@example.com` / `secret123` |

**Steps**
1. Open the Billing page as Nina.

**Expected result**
- Badge `Standard`; "Upgrade to Premium" button visible — hiding the button for one Premium user does not hide it for others.

**Pass/Fail criteria**: PASS if Nina sees the button; FAIL otherwise.
**Cleanup**: restart the backend.
