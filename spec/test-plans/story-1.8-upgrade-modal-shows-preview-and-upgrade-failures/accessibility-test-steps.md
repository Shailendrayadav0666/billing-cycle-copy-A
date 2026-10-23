# Accessibility Test Steps — Story 1.8 Upgrade modal shows preview and upgrade failures

**Purpose**: prove error messages in the upgrade dialog are announced to assistive technology and that the
disabled state of Confirm is perceivable.
**Scope**: AC-4 (and the accessible side of AC-1/AC-3).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.8 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.8"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000`; frontend dev server `http://localhost:5173` (proxies `/api`) |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` (Standard) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-A11Y-01 — Preview error is in a role="alert" region

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-03 — WCAG 4.1.3 Status Messages |
| **Type** | Accessibility |
| **Priority** | P1 |
| **Preconditions** | Signed in on the Billing page |
| **Test data** | Blocked URL pattern `*/api/billing/upgrade/preview` |

**Steps**
1. Block the preview URL in DevTools.
2. Click "Upgrade to Premium".
3. In DevTools Elements, inspect the element containing "Something went wrong. Please try again."

**Expected result**
- The message element (or an ancestor) has `role="alert"`.

**Pass/Fail criteria**: PASS if the message is inside a `role="alert"` region.
**Cleanup**: Remove the block; close the dialog.

### TC-A11Y-02 — Screen reader announces the upgrade error without moving focus

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-03 — WCAG 4.1.3 Status Messages |
| **Type** | Accessibility |
| **Priority** | P2 |
| **Preconditions** | Screen reader running; backend freshly restarted; signed in |
| **Test data** | Blocked exact URL `http://localhost:5173/api/billing/upgrade` |

**Steps**
1. Open the dialog with the keyboard and wait for the charge text.
2. Block the upgrade URL.
3. Tab to "Confirm Upgrade" and press Enter.

**Expected result**
- The screen reader announces "Something went wrong. Please try again." automatically.
- Focus remains inside the dialog (on or near "Confirm Upgrade").

**Pass/Fail criteria**: PASS if the error is announced without the user navigating to it and focus stays in the dialog.
**Cleanup**: Remove the block; press Escape.

### TC-A11Y-03 — Disabled Confirm is exposed as disabled (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-NF-03 — WCAG 4.1.2 Name, Role, Value |
| **Type** | Accessibility |
| **Priority** | P2 |
| **Preconditions** | Signed in |
| **Test data** | Blocked URL pattern `*/api/billing/upgrade/preview` |

**Steps**
1. Block the preview URL and open the dialog.
2. Inspect "Confirm Upgrade" in the Accessibility tree; with the screen reader, Tab to it.

**Expected result**
- The button is exposed as disabled (`disabled` attribute or `aria-disabled="true"`) and the screen reader reads it as unavailable/dimmed.
- Pressing Enter or Space on it sends no `POST /api/billing/upgrade`.

**Pass/Fail criteria**: PASS if disabled state is exposed and activation sends no request.
**Cleanup**: Remove the block; close the dialog.

### TC-A11Y-04 — Error text has sufficient contrast

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-03 — WCAG 1.4.3 Contrast (Minimum) |
| **Type** | Accessibility |
| **Priority** | P3 |
| **Preconditions** | Error shown as in TC-A11Y-01 |
| **Test data** | — |

**Steps**
1. With the error message shown, use the DevTools color picker contrast ratio on the message text.

**Expected result**
- Contrast ratio is at least 4.5:1 against its background.

**Pass/Fail criteria**: PASS if ratio ≥ 4.5:1.
**Cleanup**: Remove the block; close the dialog.
