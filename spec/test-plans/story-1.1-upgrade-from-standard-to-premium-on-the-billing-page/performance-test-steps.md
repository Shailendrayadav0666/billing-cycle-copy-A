# Performance Test Steps — Story 1.1 Upgrade from Standard to Premium on the Billing page

**Purpose**: verify the measurable targets in REQ-NF-02: a Standard subscriber completes the upgrade in under
60 seconds, and the preview and upgrade endpoints respond in under 500 ms on a local run.
**Scope**: AC-2, AC-3 (REQ-NF-02). No load/throughput target exists for this POC (single process, in memory).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/6852-self-serve-premium-upgrade` |
| This story's PR | — (not raised yet; execute after the [STORY] PR for story 1.1 merges into the epic branch) |
| Confirm the story is in the build | `git log --oneline \| grep "1.1"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | Backend `http://localhost:8000`; frontend dev server `http://localhost:5173` |
| Local services that must be up | Backend and frontend dev server |
| Test data / accounts to seed | Seed account `tpg@example.com` / `password` |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-PERF-01 — The upgrade journey takes under 60 seconds

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-NF-02 |
| **Type** | Performance |
| **Priority** | P2 |
| **Preconditions** | Fresh backend; signed in as `tpg@example.com` on the Billing page; a stopwatch |
| **Test data** | — |

**Steps**
1. Start the stopwatch with the Billing page fully loaded.
2. Click "Upgrade to Premium", read the charge, click "Confirm Upgrade".
3. Stop the stopwatch when the page shows `Premium` and the success message.
4. Repeat 3 times (restart the backend between runs) and record the times.

**Expected result**
- Every run completes in under 60 seconds (expected: a few seconds).

| Run | Time (s) | Under 60 s? |
|-----|----------|-------------|
| 1 | | |
| 2 | | |
| 3 | | |

**Pass/Fail criteria**: PASS if all runs are under 60 s; FAIL if any run reaches 60 s.
**Cleanup**: restart the backend.

### TC-PERF-02 — Preview and upgrade respond in under 500 ms locally

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-3 / REQ-NF-02 |
| **Type** | Performance |
| **Priority** | P3 |
| **Preconditions** | Fresh backend; `$TOKEN` from `POST /api/auth/login` |
| **Test data** | `$TOKEN` |

**Steps**
1. Run 10 times: `curl -s -o NUL -w "%{time_total}\n" http://localhost:8000/api/billing/upgrade/preview -H "Authorization: Bearer $TOKEN"` (use `-o /dev/null` on macOS/Linux).
2. Run once: `curl -s -o NUL -w "%{time_total}\n" -X POST http://localhost:8000/api/billing/upgrade -H "Authorization: Bearer $TOKEN"`.
3. Record the times; take the highest preview time (boundary check).

**Expected result**
- Every preview time and the upgrade time is below `0.500` seconds.

| Request | Max time (s) | Under 0.5 s? |
|---------|--------------|--------------|
| Preview (10 runs) | | |
| Upgrade | | |

**Pass/Fail criteria**: PASS if all measured times are below 0.5 s; FAIL if any is 0.5 s or more.
**Cleanup**: restart the backend.
