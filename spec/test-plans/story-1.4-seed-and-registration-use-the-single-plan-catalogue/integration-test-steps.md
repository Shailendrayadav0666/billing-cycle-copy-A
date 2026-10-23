# Integration Test Steps — Story 1.4 Seed and registration use the single plan catalogue

**Purpose**: verify across the boundary between registration, the upgrade flow and the shared plan catalogue
that plan data stays consistent and that one user's upgrade never changes the catalogue or another user.
**Scope**: `POST /api/auth/register`, `POST /api/billing/upgrade`, `GET /api/billing`.

> Note on AC-3 ("plan data defined once"): whether Standard/Premium data exists in exactly one catalogue
> entry, with no duplicated literal blocks and no new runtime dependency, is a **code-level property checked
> in Code Review** (architecture constraint ARCH-03). The cases below are the observable black-box proxy.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.4 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.4"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000` (Swagger UI at `/docs`); frontend dev `http://localhost:5173` (proxies `/api`) |
| Local services that must be up | none (in-memory data; restart the backend to reset) |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-INT-01 — Upgrading one registered user does not change the catalogue for later registrations

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-05, REQ-NF-07 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | Backend freshly restarted; story 1.1 (upgrade) present in the build |
| **Test data** | `nina@example.com` / `secret123`; later `late@example.com` / `secret123` |

**Steps**
1. Register `nina@example.com`; `POST /api/billing/upgrade` with Nina's token.
2. `GET /api/billing` with Nina's token.
3. Register `late@example.com`; `GET /api/billing` with Late's token.
4. Log in as `tpg@example.com`; `GET /api/billing`.

**Expected result**
- Step 2: Nina is `Premium`, `$40/month`, video quality `4K Ultra HD`, perks include `Dolby Vision (select titles)`.
- Step 3: Late is `Standard`, `$20/month`, video quality `Full HD (1080p)`, exactly two perks (`Ad-free streaming`, `Spatial audio (select titles)`).
- Step 4: seeded user still `Standard` with `Full HD (1080p)`.

**Pass/Fail criteria**: PASS only if Nina's upgrade leaks into neither the later registration nor the seeded user.
**Cleanup**: restart the backend.

### TC-INT-02 — Seeded, registered and upgraded data use the same plan definitions

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-2 / REQ-F-05 |
| **Type** | Integration |
| **Priority** | P2 |
| **Preconditions** | Backend freshly restarted |
| **Test data** | `a@example.com`, `b@example.com` (password `secret123`) |

**Steps**
1. Register A and B; `GET /api/billing` for both and for `tpg@example.com`.
2. Upgrade A and the seeded user (`POST /api/billing/upgrade` with each token).
3. `GET /api/billing` for A and for `tpg@example.com`.

**Expected result**
- Step 1: the three Standard bodies are identical except `renew_at` (seeded `Oct 30, 2026`; A and B today + 30 days).
- Step 3: the two Premium bodies are identical except `renew_at`, and each `renew_at` equals its pre-upgrade value.
- Premium usages: `4K Ultra HD`, `Can watch on 4 devices at once`, `Can download on 6 devices`; perks `Ad-free streaming`, `Spatial audio (select titles)`, `Dolby Vision (select titles)`; help `Perks included in your Premium plan.`

**Pass/Fail criteria**: PASS if every Standard body matches every other Standard body and every Premium body matches every other Premium body (ignoring `renew_at`).
**Cleanup**: restart the backend.

### TC-INT-03 — B remains Standard after A and the seeded user upgrade (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 |
| **Type** | Integration |
| **Priority** | P2 |
| **Preconditions** | Continue from TC-INT-02 step 3 (before cleanup) |
| **Test data** | B's token |

**Steps**
1. `GET /api/billing` with B's token.

**Expected result**
- B is `Standard`, `$20/month`, `Full HD (1080p)`, two perks.

**Pass/Fail criteria**: PASS if B is unchanged.
**Cleanup**: restart the backend.
