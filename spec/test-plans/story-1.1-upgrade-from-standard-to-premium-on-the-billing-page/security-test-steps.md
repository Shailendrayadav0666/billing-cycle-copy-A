# Security Test Steps — Story 1.1 Upgrade from Standard to Premium on the Billing page

**Purpose**: verify the Security Baseline controls this story introduces: opaque CSPRNG session tokens,
server-side token validation, no identity from client-supplied email, restricted CORS, input limits,
no internal details in errors, and no secrets in responses or logs.
**Scope**: AC-3, AC-4, AC-5 (REQ-F-01, REQ-F-02, REQ-NF-01). Security Baseline rules SECURITY-03, -05, -08, -12,
-15, -16.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.1 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.1"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000`; frontend dev server `http://localhost:5173` |
| Local services that must be up | Backend (and frontend for TC-SEC-05) |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-SEC-01 — Session tokens are random and a new one is issued per sign-in

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-01 — SECURITY-12, SECURITY-16 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | Fresh backend |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in three times via `POST /api/auth/login`; record the three `access_token` values.
2. Confirm each of the three tokens works on `GET /api/billing`.

**Expected result**
- The three tokens are all different, each ≥ 43 characters, none contains the email, the user ID or a readable date.
- Each token returns 200 on `/api/billing` (multiple concurrent sessions are allowed).

**Pass/Fail criteria**: PASS if tokens are distinct, opaque and valid; FAIL if any token repeats or embeds user data.
**Cleanup**: restart the backend.

### TC-SEC-02 — A forged token (the user's email) cannot read or upgrade the account

| Field | Value |
|-------|-------|
| **Traces to** | AC-4, AC-3 / REQ-F-02 — SECURITY-08 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | Fresh backend |
| **Test data** | Forged header `Authorization: Bearer tpg@example.com` |

**Steps**
1. `GET /api/billing` with the forged header.
2. `POST /api/billing/upgrade` with the forged header.
3. `POST /api/billing/upgrade` with no header but body `{"email": "tpg@example.com"}`.
4. Sign in properly and read `GET /api/billing`.

**Expected result**
- Steps 1–3: `401` `Not authenticated`.
- Step 4: plan is still `Standard`.

**Pass/Fail criteria**: PASS if no forged request succeeds and nothing changed; FAIL otherwise.
**Cleanup**: none.

### TC-SEC-03 — CORS allows only the local development origins

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-01 — SECURITY-08 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | Backend started with default configuration (no `CORS_ALLOWED_ORIGINS` set) |
| **Test data** | Origins `http://evil.example.com`, `http://localhost:5173`, `http://127.0.0.1:5173` |

**Steps**
1. `curl -s -i -X OPTIONS http://localhost:8000/api/billing -H "Origin: http://evil.example.com" -H "Access-Control-Request-Method: GET" -H "Access-Control-Request-Headers: Authorization"`
2. Repeat with `Origin: http://localhost:5173`.
3. Repeat with `Origin: http://127.0.0.1:5173`.

**Expected result**
- Step 1: no `Access-Control-Allow-Origin` header for `http://evil.example.com` (and never `*`).
- Steps 2–3: `Access-Control-Allow-Origin` equals the requesting origin; `Access-Control-Allow-Credentials` is absent or not `true`.

**Pass/Fail criteria**: PASS if only the allowlisted origins are accepted and `*` never appears; FAIL otherwise.
**Cleanup**: none.

### TC-SEC-04 — Errors reveal no internal details

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-01 — SECURITY-05, SECURITY-15 |
| **Type** | Security |
| **Priority** | P2 |
| **Preconditions** | Fresh backend |
| **Test data** | Invalid JSON `{not json`; 300-character email; header `Authorization: Bearer` (empty token) |

**Steps**
1. `POST /api/auth/login` with body `{not json`.
2. `POST /api/auth/login` with a 300-character email.
3. `GET /api/billing` with `Authorization: Bearer ` (empty).
4. Inspect each response body.

**Expected result**
- Step 1–2: `422`; Step 3: `401`.
- No body contains `Traceback`, `File "`, `.py`, exception class names, or server paths.

**Pass/Fail criteria**: PASS if every error is a clean status with a short `detail`; FAIL if internals leak.
**Cleanup**: none.

### TC-SEC-05 — Tokens never travel in URLs and passwords never appear in responses

| Field | Value |
|-------|-------|
| **Traces to** | AC-4, AC-5 / REQ-F-04, REQ-NF-01 — SECURITY-08, SECURITY-12 |
| **Type** | Security |
| **Priority** | P2 |
| **Preconditions** | Fresh backend and frontend; DevTools > Network with "Preserve log" |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in through the UI, open the upgrade dialog and confirm the upgrade.
2. Search all recorded request URLs for the token value and for `email=`.
3. Search all response bodies for `password`.

**Expected result**
- No URL contains the token or `email=`.
- No response body contains a `password` field or the value `password`.

**Pass/Fail criteria**: PASS if both searches find nothing; FAIL otherwise.
**Cleanup**: restart the backend.

### TC-SEC-06 — The upgrade is logged without tokens, emails or passwords

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-01 — SECURITY-03 |
| **Type** | Security |
| **Priority** | P2 |
| **Preconditions** | Backend started in a terminal where its console log is visible (or redirected to a file) |
| **Test data** | `tpg@example.com` / `password` |

**Steps**
1. Sign in via the API, note the token, and call `POST /api/billing/upgrade`.
2. Search the backend console log for the token value, `tpg@example.com` and `password`.
3. Look for an INFO line about the upgrade.

**Expected result**
- Step 2: none of the three values appears in any log line (the access log line for the request path is fine; it carries no token).
- Step 3: an INFO log line records the upgrade with a user ID (e.g. `upgrade user_id=1 charge=...`). TO CONFIRM: exact log message wording (functional-design BR-4 gives `upgrade user_id=<id> charge=<charge>`).

**Pass/Fail criteria**: PASS if no secret appears and the upgrade event is logged by user ID; FAIL otherwise.
**Cleanup**: restart the backend.
