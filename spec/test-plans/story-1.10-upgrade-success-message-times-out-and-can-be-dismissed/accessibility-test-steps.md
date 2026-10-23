# Accessibility Test Steps — Story 1.10 Upgrade success message times out and can be dismissed

**Purpose**: prove the success message is announced politely and can be dismissed by keyboard.
**Scope**: AC-1, AC-3 (keyboard).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.10 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.10"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000`; frontend dev server `http://localhost:5173` (proxies `/api`) |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard); restart backend before each case |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-A11Y-01 — Success message has status semantics and exact text

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-12, REQ-NF-03 — WCAG 4.1.3 Status Messages |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | Backend freshly restarted; signed in |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Upgrade (Upgrade to Premium → Confirm Upgrade).
2. Within 3 seconds, inspect the message element in DevTools.

**Expected result**
- Text is exactly "You're now on Premium! Your next full cycle bills at $40/month."
- The element (or an ancestor) has `role="status"` and `aria-live="polite"`.

**Pass/Fail criteria**: PASS only if text and both attributes match.
**Cleanup**: Restart the backend.

### TC-A11Y-02 — Screen reader announces the success message politely

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-NF-03 — WCAG 4.1.3 Status Messages |
| **Type** | Accessibility |
| **Priority** | P2 |
| **Preconditions** | Screen reader running; backend freshly restarted; signed in |
| **Test data** | — |

**Steps**
1. Using the keyboard only, open the upgrade dialog and activate "Confirm Upgrade".
2. Listen.

**Expected result**
- The success message is announced after the current speech finishes (polite), without the user navigating to it.

**Pass/Fail criteria**: PASS if announced automatically.
**Cleanup**: Restart the backend.

### TC-A11Y-03 — Dismiss button is keyboard operable (Enter)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-03 — WCAG 2.1.1 Keyboard, 4.1.2 Name, Role, Value |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | Backend freshly restarted; signed in |
| **Test data** | — |

**Steps**
1. Upgrade using the keyboard.
2. Within 4 seconds, Tab to the message's dismiss control; note its announced name and role.
3. Press Enter.

**Expected result**
- The control is a button with an accessible name containing "Dismiss" and a visible focus indicator (WCAG 2.4.7).
- Pressing Enter hides the message immediately.
- TO CONFIRM: where focus goes after dismissal (expected: a sensible element on the page, not lost to the document body).

**Pass/Fail criteria**: PASS if the button is reachable, named, and Enter hides the message.
**Cleanup**: Restart the backend.

### TC-A11Y-04 — Message stays long enough to be read (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-NF-03 — WCAG 2.2.1 Timing Adjustable (informational message; dismiss is optional) |
| **Type** | Accessibility |
| **Priority** | P3 |
| **Preconditions** | Screen reader running |
| **Test data** | — |

**Steps**
1. Upgrade and let the screen reader announce the message.
2. Confirm the full sentence is announced before the message disappears.

**Expected result**
- The complete message is announced even though it auto-hides after about 5 seconds.

**Pass/Fail criteria**: FAIL if the announcement is cut off because the message disappears.
**Cleanup**: Restart the backend.
