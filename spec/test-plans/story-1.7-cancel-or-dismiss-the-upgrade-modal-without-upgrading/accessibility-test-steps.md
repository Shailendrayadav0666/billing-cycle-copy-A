# Accessibility Test Steps — Story 1.7 Cancel or dismiss the upgrade modal without upgrading

**Purpose**: prove the upgrade dialog is exposed as a modal dialog and that keyboard focus is managed.
**Scope**: AC-2, AC-3 (plus keyboard dismissal from AC-1).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.7 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.7"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000`; frontend dev server `http://localhost:5173` (proxies `/api`) |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard); restart backend before each case |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

Tools: browser DevTools Accessibility tree / Elements panel; a screen reader (NVDA on Windows or VoiceOver on macOS).

---

### TC-A11Y-01 — Dialog role, modality and accessible name

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-NF-03 — WCAG 4.1.2 Name, Role, Value |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | SUT running; signed in as `tpg@example.com` |
| **Test data** | — |

**Steps**
1. On the Billing page click "Upgrade to Premium".
2. In DevTools Elements, select the dialog container; read its attributes and the Accessibility tree entry.

**Expected result**
- `role="dialog"` and `aria-modal="true"` are present.
- The accessible name is "Upgrade to Premium" (via `aria-labelledby` pointing to the visible title).

**Pass/Fail criteria**: PASS only if role, modality and name are all as stated.
**Cleanup**: Close the dialog.

### TC-A11Y-02 — Screen reader announces the dialog on open

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-NF-03 — WCAG 4.1.2, 1.3.1 Info and Relationships |
| **Type** | Accessibility |
| **Priority** | P2 |
| **Preconditions** | Screen reader running; signed in |
| **Test data** | — |

**Steps**
1. Using only the keyboard, Tab to "Upgrade to Premium" and press Enter.
2. Listen to the announcement.

**Expected result**
- The screen reader announces a dialog named "Upgrade to Premium".
- Content behind the dialog is not read when using the virtual cursor (modal behaviour).

**Pass/Fail criteria**: PASS if the dialog and its name are announced and background content is not reachable.
**Cleanup**: Press Escape.

### TC-A11Y-03 — Focus moves into the dialog on open

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-03 — WCAG 2.4.3 Focus Order |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | Signed in; mouse not used |
| **Test data** | — |

**Steps**
1. Tab to "Upgrade to Premium" and press Enter.
2. Note where the visible focus indicator is (or run `document.activeElement` in the DevTools console).

**Expected result**
- Focus is on an element inside the dialog (its first focusable control).
- A visible focus indicator is shown (WCAG 2.4.7 Focus Visible).

**Pass/Fail criteria**: PASS if focus is inside the dialog and visible.
**Cleanup**: Press Escape.

### TC-A11Y-04 — Tab and Shift+Tab never leave the open dialog

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-03 — WCAG 2.4.3 Focus Order, 2.1.2 No Keyboard Trap (trap must be escapable) |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | Dialog open via keyboard |
| **Test data** | — |

**Steps**
1. Press Tab 10 times, noting each focused element.
2. Press Shift+Tab 10 times, noting each focused element.
3. Press Escape.

**Expected result**
- Every focused element in steps 1–2 is inside the dialog (close X, Cancel, Confirm Upgrade); focus wraps around.
- Step 3 closes the dialog (the trap is escapable).

**Pass/Fail criteria**: FAIL if focus ever lands on the page behind the dialog, or Escape does not close it.
**Cleanup**: None.

### TC-A11Y-05 — Focus returns to the Upgrade button on close

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-03 — WCAG 2.4.3 Focus Order |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | Signed in, keyboard only |
| **Test data** | — |

**Steps**
1. Open the dialog with the keyboard, press Escape. Note focus.
2. Open it again, Tab to "Cancel", press Enter. Note focus.
3. Open it again, Tab to the close (X) button, press Enter. Note focus.

**Expected result**
- After each close, focus is on the "Upgrade to Premium" button.

**Pass/Fail criteria**: PASS only if focus returns to the button in all three cases.
**Cleanup**: None.

### TC-A11Y-06 — All dialog controls are operable by keyboard

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-1 / REQ-NF-03 — WCAG 2.1.1 Keyboard |
| **Type** | Accessibility |
| **Priority** | P2 |
| **Preconditions** | Signed in, keyboard only, Network tab open |
| **Test data** | — |

**Steps**
1. Open the dialog with Enter on "Upgrade to Premium".
2. Tab to "Cancel" and press Space.
3. Reopen, Tab to the close (X) button and press Enter.

**Expected result**
- Each control activates with the keyboard and closes the dialog.
- No `POST /api/billing/upgrade` is sent.

**Pass/Fail criteria**: PASS if every control works by keyboard and no upgrade request is sent.
**Cleanup**: None.
