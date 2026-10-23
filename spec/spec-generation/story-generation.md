# Story Generation Plan — Epic HELIX-6852 Self-Serve Premium Upgrade

**Inputs**: `spec/plans/requirements.md` v1 (REQ-F-01..16, REQ-NF-01..07), `spec/plans/epic-brief.md`
(Atlas Epic 6852 + Story 6853), `spec/plans/atlas-deep-dive.md` (component boundaries)
**team_size**: 2 (fixed framework default — not asked)
**story_creation_mode**: all-at-once (fixed framework default — not asked)

---

## 1. Story slicing — Story 1 is a working end-to-end upgrade (user direction)

**User direction (2026-10-23)**: "could you design the stories in a way that the very first story creates the
working UI to show -standard to premium upgrade". Story 1 is therefore the **thinnest working vertical slice**
of the whole journey (button → modal with charge → confirm → page shows Premium), built against the real
backend. Every later story adds a rule, path or hardening step on top of it (SPIDR applied to what remains).

**Why Story 1 also carries the minimal session**: the Security Baseline is mandatory and blocking. An upgrade
endpoint that trusts a client-supplied email fails SECURITY-08 at Story 1's own Code Review, so Story 1 must
include the opaque Bearer session (REQ-F-01, REQ-F-02) and restricted CORS. Session *expiry/logout* and
*401 handling* are split out to later stories.

**Deliberate exception to the sizing ceilings**: Story 1 touches more than one new layer (backend endpoints +
Billing UI). This is the "thinnest useful end-to-end slice" allowance in the slicing rules, chosen at the
user's direction. It keeps to 5 ACs and one scenario class (the Standard user's happy path). Every other story
stays within the ceilings.

**Parallelism trade-off**: every later story builds on Story 1, so Story 1 runs alone; after it merges, up to
6 stories can run in parallel (2 developers never idle).

| # | Story | REQ-IDs | SPIDR axis | Layer |
|---|---|---|---|---|
| 1 | Upgrade from Standard to Premium on the Billing page (working end-to-end slice, incl. minimal Bearer session) | F-01, F-02, F-04 (send token), F-05 (Premium data), F-06 (base formula), F-07, F-08, F-09, F-10, F-11, F-12, F-14, F-16, NF-01, NF-02, NF-06 | thin vertical slice | backend + frontend |
| 2 | Premium users cannot preview or upgrade again | F-07/F-08 (400 path), F-10 (hidden for Premium) | **P** (already-Premium path) | backend + one UI condition |
| 3 | Proration boundary and rounding rules | F-06 (past date, ≥30 days, half-up `Decimal`), NF-06 | **R** (rule) | backend |
| 4 | Seed and registration use the single plan catalogue | F-05 (remove duplication), NF-07 | **D** (data) | backend |
| 5 | Sessions expire and logout ends the session | F-03 | **R** (expiry) + **I** (logout endpoint) | backend + logout call |
| 6 | Signed-out on an invalid or expired session | F-04 (401 → logout), F-15 (401 part) | **P** (401 path) | frontend |
| 7 | Cancel or dismiss the upgrade modal without upgrading | F-13, NF-03 | **P** (cancel path) | frontend |
| 8 | Upgrade modal shows preview/upgrade errors | F-15 (modal part) | **P** (error path) | frontend |
| 9 | Billing page shows a load error with Retry | F-15 (page part) | **P** (error path) | frontend |
| 10 | Upgrade success message times out and can be dismissed | F-12 (5 s / dismiss detail), NF-03 (live region) | **P** (post-success state) | frontend |

Non-functional requirements ride as ACs on the stories they constrain: NF-01 on 1, 2, 5; NF-02 on 1; NF-03 on
7 and 10; NF-04 (tests) on every story — Story 1 adds both the backend (`pytest`) and frontend (`vitest`)
test tooling; NF-05/NF-07 are constraints on all stories.

## 2. Breakdown approaches considered

- **Walking skeleton + increments** (chosen, per user direction): Story 1 delivers the working journey end to
  end; later stories add rules, alternate paths and hardening, each one bounded.
- **Feature-based**: stories grouped by capability (sessions, upgrade API, Billing UI). Smaller diffs and more
  early parallelism, but nothing visible works until several stories merge — rejected per user direction.
- **User-journey-based**: one story per step of "open Billing → upgrade", each spanning backend and frontend.
- **Persona-based**: Standard vs. Premium subscriber. Too coarse — almost every story serves the Standard
  subscriber.
- **Domain-based / Epic-based**: one domain (billing) and one Epic — adds no structure here.

## 3. Execution checklist

### Part 1 — Planning
- [x] Record `team_size: 2` and `story_creation_mode: all-at-once` in state (no question)
- [x] Apply SPIDR slicing (Section 1) and log the axes used
- [x] Write this plan with embedded questions
- [x] Collect answers and analyse them for ambiguity

### Part 2 — Generation
- [x] Generate `spec/plans/personas.md`
- [x] Generate `spec/plans/stories.md` (EPIC TICKET header first; every story with `**Covers**:`, persona, Given/When/Then ACs)
- [x] Populate `## Story Tracker` in `runtime-artifacts/aire-state.md` (Requires = TBD, Tracker ID = —, Status = Ready for Development)
- [x] Requirements full-coverage check; append `## Requirements Coverage Matrix`
- [x] Granularity check against the sizing ceilings (≤5 ACs, one new layer, no title conjunction, one scenario class)
- [ ] Present GATE 1 — Story Set Approval

### Part 3 — Push to tracker (after GATE 1)
- [ ] Tracker Type is LOCAL — announce only; Tracker ID = LOCAL for every story

---

## 4. Questions

## Question 1 — Number of stories

 How many user stories should I create for this work?

    Recommended: 10 stories  (suggested range: 9–12)

   Why 10:
   - Story 1 is the working end-to-end upgrade you asked for; the remaining 15 functional requirements collapse into 9 increments sliced by rule (proration edges), path (already Premium, cancel, modal errors, page error, 401, success message), data (catalogue) and interface (logout)
   - after Story 1 merges, up to 6 stories run in parallel, so both developers stay busy
   - every story after Story 1 stays within the sizing ceilings (≤5 ACs, one new layer, one scenario class)

   Reply with a number to override, or "ok"/"use recommended" to accept 10.

[Answer]: ok

## Question 2 — Story breakdown approach

A) Walking skeleton + increments, as in Section 1 (Story 1 = working end-to-end upgrade). (Recommended — matches
your direction)

B) Feature-based (sessions / upgrade API / Billing UI) — the working UI would only appear after several stories

X) Other (please describe after [Answer]: tag below)

[Answer]: a

## Question 3 — Story 1 includes the minimal session hardening

To pass the mandatory Security Baseline at Story 1's own Code Review, Story 1 includes opaque Bearer session
tokens at login/register, Bearer validation on `/api/users/me`, `/api/billing` and the new endpoints, and CORS
restricted to the local dev origins (REQ-F-01, REQ-F-02). Users see no difference in login or registration.

A) Yes — include it in Story 1 as described. (Recommended)

B) No — put session hardening in a separate first story; Story 1 (the working UI) becomes Story 2.

X) Other (please describe after [Answer]: tag below)

[Answer]: a

## Question 4 — Acceptance criteria format

A) Given/When/Then for every AC, numbered AC-1..AC-n per story (maps one-to-one onto the Gherkin
`.feature` scenarios written later). (Recommended)

B) Plain checklist ACs

X) Other (please describe after [Answer]: tag below)

[Answer]: a
