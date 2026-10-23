# Security Test Steps — Story 1.2 Premium users cannot preview or upgrade again

**Purpose**: verify object-level authorization on the upgrade: a request can only ever change the caller's
own account, whatever email it carries (IDOR prevention).
**Scope**: AC-4 (REQ-NF-01, REQ-F-02) — Security Baseline SECURITY-08.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.2 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.2"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000` |
| Local services that must be up | Backend only |
| Test data / accounts to seed | Register two Standard users: A = `a@example.com` / `secret123`, B = `b@example.com` / `secret123` via `POST /api/auth/register`; keep tokens `$SA` and `$SB` |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-SEC-01 — A's upgrade naming B in the body changes only A

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-01 — SECURITY-08 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | Fresh backend; A and B registered; `$SA`, `$SB` |
| **Test data** | Body `{"email": "b@example.com"}` |

**Steps**
1. `curl -s -i -X POST http://localhost:8000/api/billing/upgrade -H "Authorization: Bearer $SA" -H "Content-Type: application/json" -d "{\"email\":\"b@example.com\"}"`
2. `GET /api/billing` with `$SA`.
3. `GET /api/billing` with `$SB`.

**Expected result**
- Step 1: `200`, `plan_name` `Premium`.
- Step 2: A is `Premium`.
- Step 3: B is still `Standard`, `$20/month`, `Full HD (1080p)`.

**Pass/Fail criteria**: PASS if only A changed; FAIL if B changed in any way.
**Cleanup**: restart the backend.

### TC-SEC-02 — Query-string and header tampering cannot target another account

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-01, REQ-F-02 — SECURITY-08 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | Fresh backend; A and B registered (both Standard); `$SA`, `$SB` |
| **Test data** | `?email=b@example.com`; header `Authorization: Bearer b@example.com` |

**Steps**
1. `curl -s -i -X POST "http://localhost:8000/api/billing/upgrade?email=b@example.com" -H "Authorization: Bearer $SA"`
2. `curl -s -i "http://localhost:8000/api/billing/upgrade/preview?email=b@example.com" -H "Authorization: Bearer $SB"` (B previews; must describe B only)
3. `curl -s -i -X POST http://localhost:8000/api/billing/upgrade -H "Authorization: Bearer b@example.com"`
4. `GET /api/billing` with `$SB`.

**Expected result**
- Step 1: `200`; only A becomes Premium.
- Step 2: `200`; `current_plan` `Standard` — B's own data, computed from B's renew_at.
- Step 3: `401` `Not authenticated`.
- Step 4: B is still `Standard`.

**Pass/Fail criteria**: PASS if B is never changed and the forged header is rejected; FAIL otherwise.
**Cleanup**: restart the backend.
