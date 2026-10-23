> **Source**: Atlas via Helix MCP
> **Server / tool**: helix · get_solution_document_tool (document_id 6852, "Epic: Self-Serve Premium Upgrade.md", artifact_type epic, v1; linked story document_id 6853, artifact_type story, v1)
> **Estate**: solution 951 "Billing-Cycle-Helix-Workshop" — repo Billing-Cycle (main, last ingested 69f67f308492a85648aa25a9ff7d8d574031344a)
> **Scope pulled**: the Epic document plus the one Story document Atlas holds under it (both verbatim)
> **Fetched**: 2026-10-23T07:54:25Z
> **Freshness**: Epic updated_at 2026-10-15T09:08:15Z; Story updated_at 2026-10-15T09:09:03Z

# Epic: Self-Serve Premium Upgrade

**Created:** 2026-10-15
**For:** Shailendra
**System:** Billing-Cycle (StreamPlex)
**Status:** Draft
**Priority:** High

---

## Goal

Enable Standard plan subscribers to upgrade themselves to Premium directly from the Billing page, without leaving the app or contacting support. The upgrade must show a prorated charge for the remainder of the current billing cycle and apply the plan change immediately in the UI.

---

## Problem Statement

The Billing page is currently read-only. Users can view their plan details but have no way to change their subscription. This creates friction and potential churn for users who want to access Premium features (4K, more streams, Dolby Vision) — they have no self-serve path.

---

## Success Metrics

- A Standard user can complete an upgrade to Premium in under 60 seconds from the Billing page
- The prorated charge is clearly shown before any commitment
- The plan change is reflected in the UI immediately after confirmation (no page reload)
- No regressions to existing login, registration, or billing display flows

---

## Scope

**In Scope:**
- Standard → Premium upgrade flow with proration UI
- New `POST /api/billing/upgrade` backend endpoint with proration calculation
- Billing page CTA, confirmation modal, and state update

**Out of Scope (confirmed):**
- Downgrades
- Refunds or credits
- Payment verification, decline flows, or external payment SDKs (Stripe, etc.)
- Enterprise or additional plans
- Persistent database storage

---

## Stories

| Story | Priority | Estimate | Status |
|-------|----------|----------|--------|
| Mid-Cycle Upgrade Flow (Standard → Premium) | High | M (3–5 days) | Draft |

---

## Technical Context

The system is a POC with an in-memory Python dict store and an email-as-token auth model. The upgrade flow follows the existing auth pattern (email passed as query param / request body) for consistency. No external billing SDK is required; proration is a simple formula computed server-side.

---

## Referenced Paths

The following files and paths were analyzed to create this document:

### High Relevance
- `Billing-Cycle/src/backend/main.py` - In-memory data store structure, existing billing data shape, and endpoint patterns that the upgrade endpoint will extend
- `Billing-Cycle/src/frontend/src/pages/Billing.jsx` - Read-only billing page that this epic will extend with upgrade CTA and modal

### Medium Relevance
- `Billing-Cycle/src/frontend/src/context/AuthContext.jsx` - Auth token (email) consumed by the upgrade flow

### Low Relevance
- `Billing-Cycle/src/frontend/package.json` - No new dependencies expected for this epic
- `Billing-Cycle/src/backend/requirements.txt` - No new Python packages required

---
---

# Linked Atlas Story (verbatim, document_id 6853)

# Story: Mid-Cycle Upgrade Flow (Standard → Premium)

**Created:** 2026-10-15
**For:** Shailendra
**Epic:** Self-Serve Premium Upgrade
**System:** Billing-Cycle (StreamPlex)
**Status:** Draft
**Priority:** High
**Estimate:** M (3–5 days)

---

## User Story

> **As a Standard plan subscriber ($20/mo),**
> **I want to upgrade to Premium ($40/mo) from the Billing page mid-month,**
> **so that I get advanced features immediately and only pay a prorated charge for the days remaining in my cycle.**

---

## Context

The Billing page (`src/frontend/src/pages/Billing.jsx`) currently renders plan details and usage cards fetched from `GET /api/billing`, but is entirely read-only — there is no way for the user to change their plan. The backend (`src/backend/main.py`) stores billing data in an in-memory dict (`billing_data`) keyed by email, and plan data in a parallel `users` dict. Both need to be updated on upgrade.

The "token" in the current system is the user's email (stored in `localStorage` and passed as a query param). The upgrade endpoint will follow the same pattern for consistency with the existing POC auth model.

---

## Acceptance Criteria

### AC-1: Upgrade CTA is visible to Standard plan users only

**Given** a user is logged in with a Standard plan
**When** they view the Billing page
**Then** an "Upgrade to Premium" button is visible in the plan section (below the current plan card)

**Given** a user is logged in with a Premium plan
**When** they view the Billing page
**Then** the "Upgrade to Premium" button is NOT rendered (plan is already Premium)

---

### AC-2: Confirmation modal shows prorated amount before commitment

**Given** a Standard user clicks "Upgrade to Premium"
**When** the upgrade modal opens
**Then** the modal displays:
- Current plan: Standard ($20/mo)
- New plan: Premium ($40/mo)
- Days remaining in cycle (calculated from `renew_at` date and today's date)
- **Prorated charge:** `($40 − $20) × (days_remaining / days_in_cycle)` rounded to 2 decimal places
- Example display: *"You'll be charged $10.00 today for the 15 days remaining in your cycle."*
- A **Confirm Upgrade** button and a **Cancel** button

**And** the user has NOT been charged or upgraded yet at this point

---

### AC-3: Proration math is correct

**Given** the following inputs to the proration formula:
- Premium price: $40.00
- Standard price: $20.00
- Days remaining in cycle: derived from `renew_at` (stored as `"MMM DD, YYYY"` string) minus today's date
- Days in cycle: 30 (fixed)

**Then** the backend computes:
```
prorated_charge = round((40 - 20) * (days_remaining / 30), 2)
```

**Edge cases:**
- If `days_remaining <= 0` (renewal date is today or past): prorated charge = $0.00; upgrade still proceeds
- If `days_remaining >= 30`: prorated charge = $20.00 (full price difference)

---

### AC-4: Backend upgrade endpoint applies the plan change

**Given** a `POST /api/billing/upgrade` request with `{ "email": "<user_email>" }`
**When** the user is found and is on the Standard plan
**Then** the backend:
1. Calculates `days_remaining` from the stored `renew_at` date
2. Computes `prorated_charge`
3. Updates `users[email]["plan"]` to `"Premium"` and `users[email]["price"]` to `"$40/month"`
4. Updates `billing_data[email]` with the Premium plan features (see Premium feature set below)
5. Returns `{ "plan_name": "Premium", "price": "$40/month", "renew_at": "<unchanged>", "prorated_charge": <float>, "usages": [...], "included_usage": {...} }`

**Given** the user is already on Premium
**When** `POST /api/billing/upgrade` is called
**Then** the backend returns HTTP 400 with `{ "detail": "Already on Premium plan" }`

---

### AC-5: Billing page reflects Premium plan immediately after confirmation

**Given** the user clicks "Confirm Upgrade" in the modal
**When** the backend responds successfully
**Then** the Billing page updates **without a full page reload** to show:
- Plan name: **Premium**
- Price: **$40/month**
- Renewal date: **unchanged** (same `renew_at` as before)
- Updated usage cards reflecting Premium quotas (4K quality, 4 streams, 6 downloads)
- The "Upgrade to Premium" button is no longer rendered

**And** a success message is briefly shown: *"You're now on Premium! Your next full cycle bills at $40/month."*

---

### AC-6: Cancel does nothing

**Given** the upgrade modal is open
**When** the user clicks "Cancel" or closes the modal
**Then** no API call is made and the Billing page remains unchanged

---

### AC-7: Renewal date is unchanged

**Given** a user upgrades mid-cycle
**Then** the `renew_at` date in both the UI and the backend remains the same value it was before the upgrade — the Premium price takes effect at the next cycle, not from a new start date

---

## Premium Plan Feature Data

The backend must define and return the following for Premium users:

```python
"usages": [
    {
        "id": "video-quality",
        "label": "Video quality",
        "type": "feature",
        "value": "4K Ultra HD",
        "help": "The best video resolution available on the Premium plan.",
    },
    {
        "id": "screens",
        "label": "Watch at the same time",
        "type": "feature",
        "value": "Can watch on 4 devices at once",
        "help": "Number of supported devices that can stream simultaneously.",
    },
    {
        "id": "downloads",
        "label": "Download on devices",
        "type": "feature",
        "value": "Can download on 6 devices",
        "help": "Number of devices for offline viewing.",
    },
],
"included_usage": {
    "title": "Plan perks",
    "items": [
        {"id": "ad-free", "label": "Ad-free streaming", "used_percent": 100},
        {"id": "spatial-audio", "label": "Spatial audio (select titles)", "used_percent": 100},
        {"id": "dolby-vision", "label": "Dolby Vision (select titles)", "used_percent": 100},
    ],
    "help": "Perks included in your Premium plan.",
}
```

---

## Backend Changes

**New endpoint:** `POST /api/billing/upgrade`

```python
class UpgradeRequest(BaseModel):
    email: str

@app.post("/api/billing/upgrade")
def upgrade_plan(payload: UpgradeRequest):
    # 1. Validate user exists and is on Standard
    # 2. Calculate days_remaining from renew_at
    # 3. Compute prorated_charge = round((40 - 20) * (days_remaining / 30), 2)
    # 4. Update users[email] plan fields
    # 5. Update billing_data[email] with Premium feature set
    # 6. Return updated billing data + prorated_charge
```

**Proration helper:**
```python
from datetime import datetime

def calculate_days_remaining(renew_at: str) -> int:
    renew_date = datetime.strptime(renew_at, "%b %d, %Y").date()
    today = datetime.today().date()
    return max(0, (renew_date - today).days)
```

---

## Frontend Changes

**`src/frontend/src/pages/Billing.jsx`**

1. Conditionally render an **"Upgrade to Premium"** button when `data.plan_name === "Standard"`
2. Manage modal open/close state with `useState`
3. On modal open: compute `days_remaining` in JS from the `renew_at` string and display the prorated amount client-side
4. On "Confirm Upgrade": `POST /api/billing/upgrade` with `{ email: token }`, then call `setData(response)` to update the page state
5. Show a transient success message on confirmation
6. Remove the upgrade button once plan is Premium

---

## Out of Scope (Confirmed)

- Downgrades
- Refunds or credits
- Payment verification or decline flows
- External payment SDKs (Stripe, etc.)
- Enterprise or additional plans
- Persistent database storage

---

## Definition of Done

- [ ] `POST /api/billing/upgrade` endpoint implemented in `src/backend/main.py`
- [ ] Proration formula tested manually with at least 3 day-remaining values (e.g., 0, 15, 29)
- [ ] "Upgrade to Premium" CTA visible on Billing page for Standard users only
- [ ] Confirmation modal renders with correct prorated charge before commitment
- [ ] On confirmation, Billing page data updates without page reload to show Premium plan
- [ ] Success message displayed after upgrade
- [ ] Cancel/close modal does not trigger upgrade
- [ ] `renew_at` date unchanged after upgrade
- [ ] Upgrade button absent for Premium users
- [ ] No regressions: login, registration, Standard billing display all work as before
- [ ] Code reviewed and merged

---

## Referenced Paths

The following files and paths were analyzed to create this document:

### High Relevance
- `Billing-Cycle/src/backend/main.py` - New `UpgradeRequest` model, `POST /api/billing/upgrade` endpoint, proration logic, Premium billing data structure, and `users` dict mutation all implemented here
- `Billing-Cycle/src/frontend/src/pages/Billing.jsx` - Upgrade CTA button, confirmation modal, `POST` fetch call, and state update (`setData`) all implemented here

### Medium Relevance
- `Billing-Cycle/src/frontend/src/context/AuthContext.jsx` - Provides `token` (email) consumed by `Billing.jsx` to identify the user in the upgrade request
- `Billing-Cycle/src/frontend/src/App.css` - Styles for the upgrade button, modal overlay, confirmation text, and success message

### Low Relevance
- `Billing-Cycle/src/frontend/package.json` - No new dependencies expected; confirmed in scope constraints
- `Billing-Cycle/src/backend/requirements.txt` - No new Python packages required for this story
