# E2E Test Steps — Story 1.4 Seed and registration use the single plan catalogue

**Purpose**: confirm through the UI that sign-up and the seeded account still show the correct Standard
billing page, and that a duplicate sign-up is still refused.
**Scope**: Login / Sign-Up page and the Billing page in the browser.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.4 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.4"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend dev `http://localhost:5173` (proxies `/api` to backend `http://localhost:8000`) |
| Local services that must be up | Backend and frontend dev server; no other services |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-E2E-01 — Seeded subscriber sees the unchanged Standard billing page

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-16 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Backend freshly restarted; browser storage cleared for `localhost:5173` |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Open `http://localhost:5173/login` and sign in.
2. Observe the Billing page.

**Expected result**
- Plan `Standard`, `$20/month`, renewal `Oct 30, 2026`.
- Feature cards: `Full HD (1080p)`, `Can watch on 2 devices at once`, `Can download on 2 devices`.
- Plan perks: `Ad-free streaming`, `Spatial audio (select titles)`.

**Pass/Fail criteria**: PASS if every value matches.
**Cleanup**: Log out.

### TC-E2E-02 — New subscriber signs up and sees the Standard plan renewing in 30 days

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-05, REQ-F-16 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Backend running; signed out |
| **Test data** | Name `Nina`, email `nina.e2e@example.com`, password `secret123` |

**Steps**
1. On the login page switch to Sign Up, enter the test data and submit.
2. Observe the Billing page.

**Expected result**
- Lands on the Billing page: plan `Standard`, `$20/month`, renewal date = today + 30 days.
- Same feature cards and perks as TC-E2E-01.

**Pass/Fail criteria**: PASS if the new account shows the Standard data with the correct renewal date.
**Cleanup**: Log out; restart the backend.

### TC-E2E-03 — Signing up with an existing email shows an error

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-16 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | Backend running; signed out |
| **Test data** | Name `Dup`, email `tpg@example.com`, password `secret123` |

**Steps**
1. Switch to Sign Up, enter the test data and submit.

**Expected result**
- The form shows `Account already exists`; the user stays on the login/sign-up page.

**Pass/Fail criteria**: PASS if the error is shown and no navigation to Billing occurs.
**Cleanup**: none.
