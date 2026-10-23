# Accessibility Test Steps — Story 1.9 Billing page shows a load error with Retry

**Purpose**: prove the billing load error is announced and the Retry action is keyboard operable.
**Scope**: AC-3 (and the accessible side of AC-1/AC-2).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.9 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.9"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000`; frontend dev server `http://localhost:5173` (proxies `/api`) |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-A11Y-01 — Load error is in a role="alert" region

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-03 — WCAG 4.1.3 Status Messages |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | Signed in |
| **Test data** | Blocked exact URL `http://localhost:5173/api/billing` |

**Steps**
1. Block the exact URL and reload the Billing page.
2. Inspect the element containing "Something went wrong. Please try again."

**Expected result**
- The message element (or an ancestor) has `role="alert"`.

**Pass/Fail criteria**: PASS if the message is inside a `role="alert"` region.
**Cleanup**: Remove the block.

### TC-A11Y-02 — Screen reader announces the load error

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-03 — WCAG 4.1.3 Status Messages |
| **Type** | Accessibility |
| **Priority** | P2 |
| **Preconditions** | Screen reader running; signed in |
| **Test data** | Blocked exact URL `http://localhost:5173/api/billing` |

**Steps**
1. Block the URL and navigate to the Billing page with the keyboard (Billing nav link).
2. Listen.

**Expected result**
- The screen reader announces "Something went wrong. Please try again." without the user navigating to it.

**Pass/Fail criteria**: PASS if announced automatically.
**Cleanup**: Remove the block.

### TC-A11Y-03 — Retry is reachable and operable by keyboard

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-3 / REQ-NF-03 — WCAG 2.1.1 Keyboard, 4.1.2 Name, Role, Value |
| **Type** | Accessibility |
| **Priority** | P2 |
| **Preconditions** | Error shown as in TC-A11Y-01 |
| **Test data** | — |

**Steps**
1. Using Tab only, move focus to "Retry"; confirm it is announced as a button named "Retry".
2. Remove the URL block, then press Enter.

**Expected result**
- "Retry" is a focusable button with the accessible name "Retry" and a visible focus indicator (WCAG 2.4.7).
- Pressing Enter reloads billing data and the plan details are shown.

**Pass/Fail criteria**: PASS if Retry is keyboard operable and recovers the page.
**Cleanup**: None.

### TC-A11Y-04 — No alert is present when billing loads normally (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-03 — WCAG 4.1.3 Status Messages |
| **Type** | Accessibility |
| **Priority** | P3 |
| **Preconditions** | Signed in; no URL blocks |
| **Test data** | — |

**Steps**
1. Reload the Billing page normally.
2. Search the DOM for `role="alert"` elements with text.

**Expected result**
- No error alert is present or announced.

**Pass/Fail criteria**: PASS if no error alert appears on a successful load.
**Cleanup**: None.
