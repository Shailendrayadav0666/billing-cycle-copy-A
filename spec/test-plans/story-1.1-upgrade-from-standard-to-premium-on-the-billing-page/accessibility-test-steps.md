# Accessibility Test Steps — Story 1.1 Upgrade from Standard to Premium on the Billing page

**Purpose**: verify that the UI this story adds (upgrade button, dialog with charge, dynamic plan labels,
success message) is usable with the keyboard, readable by a screen reader and at 200% zoom. Full dialog
semantics and focus trapping are story 1.7's scope and are not tested here.
**Scope**: AC-1, AC-2, AC-3 (REQ-F-10, REQ-F-11, REQ-F-12, REQ-F-14).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.1 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.1"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Frontend dev server `http://localhost:5173` |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-A11Y-01 — The upgrade can be completed with the keyboard only

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2, AC-3 — WCAG 2.1.1 Keyboard, 2.4.7 Focus Visible |
| **Type** | Accessibility |
| **Priority** | P2 |
| **Preconditions** | Fresh backend; signed in as `tpg@example.com` on the Billing page; mouse not used |
| **Test data** | — |

**Steps**
1. Press Tab repeatedly from the top of the page until "Upgrade to Premium" has focus.
2. Press Enter.
3. Tab to "Confirm Upgrade" and press Enter.

**Expected result**
- Step 1: the button is reachable and shows a visible focus indicator.
- Step 2: the dialog opens with the charge text.
- Step 3: the upgrade completes; the page shows `Premium` and the success message.

**Pass/Fail criteria**: PASS if the whole flow works by keyboard with visible focus; FAIL otherwise.
**Cleanup**: restart the backend.

### TC-A11Y-02 — Button, plan badge and charge text are exposed to a screen reader

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 — WCAG 4.1.2 Name, Role, Value; 1.3.1 Info and Relationships |
| **Type** | Accessibility |
| **Priority** | P2 |
| **Preconditions** | Fresh backend; NVDA (Windows) or VoiceOver (macOS) running |
| **Test data** | — |

**Steps**
1. Navigate the Billing page with the screen reader.
2. Move to the upgrade button; open the dialog and read its content.

**Expected result**
- The plan badge is read as `Standard`; the button is announced as a button named "Upgrade to Premium".
- In the dialog, the plans, days remaining and charge sentence are read as text; "Confirm Upgrade" and "Cancel" are announced as buttons.
- Negative check: no control is announced as an unlabeled "button" or "clickable".

**Pass/Fail criteria**: PASS if all names and roles are announced correctly; FAIL otherwise.
**Cleanup**: none.

### TC-A11Y-03 — Content remains usable at 200% zoom and meets contrast

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-3 — WCAG 1.4.4 Resize Text, 1.4.3 Contrast (Minimum) |
| **Type** | Accessibility |
| **Priority** | P3 |
| **Preconditions** | Signed in as `tpg@example.com`; browser zoom 200% |
| **Test data** | — |

**Steps**
1. At 200% zoom, open the dialog and confirm the upgrade.
2. Check text contrast of the button, the dialog text and the success message with a contrast checker (e.g. the browser's DevTools colour picker).

**Expected result**
- Step 1: dialog text and both buttons are fully visible without horizontal scrolling of the dialog; the success message is fully visible.
- Step 2: normal text contrast ≥ 4.5:1.

**Pass/Fail criteria**: PASS if nothing is clipped and contrast meets 4.5:1; FAIL otherwise.
**Cleanup**: reset zoom; restart the backend.
