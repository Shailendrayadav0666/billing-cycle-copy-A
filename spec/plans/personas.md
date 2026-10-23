# Personas — Epic HELIX-6852 Self-Serve Premium Upgrade

Derived from `spec/plans/epic-brief.md` (Atlas Epic 6852 / Story 6853) and the user model in
`spec/plans/atlas-deep-dive.md` (StreamPlex subscribers on Standard $20/month or Premium $40/month).

---

## P1 — Sam, the Standard Subscriber (primary)

- **Who**: An existing StreamPlex subscriber on the Standard plan ($20/month, Full HD, 2 screens, 2 download devices).
- **Goal**: Get Premium features (4K Ultra HD, 4 screens, 6 download devices, Dolby Vision) right away, mid-cycle, without contacting support.
- **Needs**: To see exactly what they will be charged *before* committing; to see the change take effect immediately; to be able to back out.
- **Frustrations today**: The Billing page is read-only — there is no self-serve way to change plan.
- **Success looks like**: Upgrades in under 60 seconds and trusts the prorated charge shown.
- **Accessibility**: Uses keyboard navigation at times; expects modals that can be closed with Escape.

## P2 — Priya, the Premium Subscriber

- **Who**: A subscriber already on Premium ($40/month) — either upgraded by self-serve or seeded that way.
- **Goal**: View plan details and perks accurately; never be offered or charged for an upgrade they already have.
- **Needs**: The Billing page labels and features reflect Premium; no "Upgrade" prompt.

## P3 — Nina, the New Subscriber

- **Who**: Someone who has just registered; new accounts start on Standard with a renewal date 30 days out.
- **Goal**: Sign up, see a correct Standard billing page, and be able to upgrade like any Standard subscriber.
- **Needs**: Registration and login keep working exactly as before; her session is private to her and ends when she logs out.

---

## Persona → Story map

| Persona | Stories |
|---|---|
| P1 Sam (Standard) | 1.1, 1.3, 1.6, 1.7, 1.8, 1.9, 1.10 |
| P2 Priya (Premium) | 1.2, 1.9 |
| P3 Nina (New) | 1.1 (registration regression), 1.4, 1.5 |
