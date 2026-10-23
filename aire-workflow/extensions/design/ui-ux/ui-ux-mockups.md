# UI/UX Mockups

## Overview

An optional stage that gives the user a reviewed picture of the user interface before any code is
written. Depending on the opt-in answer, it either produces HTML mockups, reviews them with the user
until they are approved, or takes the designs the user already has. Either way it registers them as
design references, so every later design and code step is grounded in them through
`common/design-reference-grounding.md` (DR-5).

**When it runs**: at the STOP CHECKPOINT, after every design stage, `architecture.md`, the rubrics and
the CI pipeline (when enabled), and **before** the behaviour specs and test plans. It is invoked from
`implementation/specs-and-test-plans.md` Section 0, so it covers all three cycles:

| Cycle | Invoked from | Scope |
|---|---|---|
| Epic | `CLAUDE.md` MANDATORY STOP Step 1.7, then `specs-and-test-plans.md` Section 0 | every story with a user interface |
| Bug | `workflows/bug-fix.md` Step 8.5 Item 4.5, then Section 0 | the single ticket, if it touches the user interface |
| Enhancement | `workflows/enhancement-implement.md` Step 8.5 Item 4.5, then Section 0 | the single ticket, if it touches the user interface |

Running it here means the mockups are built from the approved stories, the functional design and the
NFR targets, and the `.feature` files and test plans written right after can use the same screen
names and labels.

**Enabled check**: run only when `## Extension Configuration` records `UI/UX Mockups` = Yes. A
missing row means **No**: skip silently and log the skip. This overrides the default-to-enforced rule
in `common/extensions-loading.md` Section 5.

### Modes

| Mode (`## UI/UX Design`) | What this stage does |
|---|---|
| `generate` | Steps 1 to 6: build the mockups, open them for review, iterate until approved, register them |
| `provided` | Step 7 only: read the provided designs and report what they do not cover. No mockups are built and no approval is requested. |
| `provided+generate` | Step 7, then Steps 1 to 6 for the work units the provided designs do not cover |
| `skip` | Nothing. Not loaded. |

---

## Step 1: Determine the UI scope

A work unit is in scope when it adds or changes something a user sees or operates in the interface:
its acceptance criteria describe a screen, form, message, navigation or visible state;
`spec/plans/functional-design.md` lists frontend components for it; or, in a bug or enhancement cycle,
`spec/plans/impact-analysis.md` names frontend files.

- In `provided+generate` mode, remove the units already covered by a provided design (Step 7).
- **No unit in scope**: record `UI/UX Mockups: N/A — no work unit changes the user interface` in
  `## UI/UX Design` and `runtime-artifacts/audit.md`, announce it in one line, and return to
  `specs-and-test-plans.md` Part A.

## Step 2: Gather the inputs

Read, for the units in scope:
- the acceptance criteria in `spec/plans/stories.md` (or the single story of a bug or enhancement
  cycle) and the `Covers` REQ-IDs in `spec/plans/requirements.md`
- `spec/plans/functional-design.md`: component structure, interaction flows, states, validation rules
- `spec/plans/nfr.md`: accessibility and usability targets, when present
- `spec/plans/personas.md`, when present
- **brownfield**: the existing interface's styling, so the mockups look like the real application.
  Read the theme or token files, global CSS variables, and the component library in use under the code
  root. Do not invent a new visual language for an existing product.

Then load `common/ui-ux-design-standards.md`. It holds the accessibility, responsive
and design rules every screen must meet.
- **Design questions**: if the inputs above leave visual basis, screen sizes, accessibility level,
  density, navigation, feedback style, loading style or brand colour undecided, write the questions
  file in its Section 1, containing only the open questions. Wait for the answers before Step 3. If
  everything is already determinable, skip the file.

## Step 3: Build the mockups

Write everything to `spec/plans/ui-ux/`:

```text
spec/plans/ui-ux/
├── index.html                  # entry page: every screen, linked, grouped by work unit
├── SCR-01-<screen-slug>.html   # one file per screen
└── SCR-02-<screen-slug>.html

spec/plans/ui-ux-design.md      # the screen inventory (below)
```

Rules for every screen file:
- **Self-contained**: inline CSS, no external stylesheets, fonts, CDNs, images from the web, or build
  step. It must render correctly when opened straight from disk.
- **No application logic.** Plain HTML and CSS. A few lines of vanilla JavaScript are allowed only to
  switch between states or link screens. These files are design artifacts; `src/` never imports them.
- **Real content**: labels, button text, messages and sample data come from the acceptance criteria
  and functional design. No placeholder text.
- **Every state the ACs imply**: default, empty, loading, validation error, failure and success,
  shown as sections or a state switcher on the same page.
- **One token block**: the same `:root` design-token block in every screen
  (`common/ui-ux-design-standards.md` Section 2), so all screens share one palette, type scale and spacing.
- **Accessible**: meets `ui-ux-design-standards.md` Section 3 at the agreed level, with WCAG 2.2 AA as
  the minimum.
- **Responsive** across every supported screen size, per `ui-ux-design-standards.md` Section 4.
- **UX patterns** per `ui-ux-design-standards.md` Section 5, unless an answer or the existing product
  sets them differently.
- **A header comment** naming what the screen covers:

```html
<!--
  Screen: SCR-02 Sign-in
  Work units: story-1.2 (PROJ-102)
  Acceptance criteria: AC-1, AC-2, AC-4
  States: default, validation error, locked account
-->
```

**Scope rule**: the mockups show what the approved acceptance criteria describe and nothing more. A
control or flow beyond them is left out. If it would clearly be needed, list it in
`ui-ux-design.md` under **Out of scope** so the user sees it at review.

Write `spec/plans/ui-ux-design.md`:

```markdown
# UI/UX Design

| Screen | File | Work units | Acceptance criteria | States |
|---|---|---|---|---|
| SCR-01 Dashboard | ui-ux/SCR-01-dashboard.html | story-1.1 | AC-1, AC-3 | default, empty, loading |

## Design system
- Visual basis: [existing application / brand guidelines / Material / framework defaults / neutral]
- Supported screen sizes: [desktop / desktop and tablet / desktop, tablet and mobile]
- Accessibility level: [WCAG 2.2 AA / AAA where achievable]
- Density, navigation, feedback style, loading style: [answers or derived values]
- Tokens: [colour roles with hex values, spacing scale, type scale, radius, elevation, icon set]
- Breakpoints: [values in use]

## Standards check
[Result of the ui-ux-design-standards.md Section 7 self-check: passed, or each item fixed]

## Design decisions
- [visual and layout decisions, with the reason for each]

## Out of scope
- [anything seen as needed but not covered by the approved acceptance criteria — not built]

## Review history
| Round | Requested change | Applied |
|---|---|---|
```

## Step 4: Open the mockups for review

1. Before presenting, run the `ui-ux-design-standards.md` Section 7 self-check on every screen file.
   Also confirm that every label and message matches the acceptance criteria, every link in
   `index.html` resolves, and the markup is well formed. Fix every failure first, and record the
   result under **Standards check** in `ui-ux-design.md`.
2. Open `spec/plans/ui-ux/index.html` in the user's default browser. Use `start "" <path>` on Windows,
   `open <path>` on macOS, or `xdg-open <path>` on Linux. No server or extra tooling is needed. If the
   browser cannot be opened from the session, give the user the full file path to open themselves.

## Step 5: Review and approve

Present the standardized 2-option message, then **WAIT**. Do not invent a third option, and do not
proceed on silence.

```markdown
# UI/UX Mockups Complete

[S] screen(s) for [U] work unit(s) — opened in your browser from `spec/plans/ui-ux/index.html`
[One line per screen: SCR-ID — name — work units — states shown]
Out of scope (not built): [items, or "none"]

> **<u>REVIEW REQUIRED:</u>**
> Mockups: `spec/plans/ui-ux/index.html`
> Screen inventory: `spec/plans/ui-ux-design.md`

> ** <u>**WHAT'S NEXT?**</u>**
>
> **You may:**
>
> **Request Changes** - Describe the changes to any screen, state or layout
> **Continue to Next Stage** - Approve the mockups and proceed to the behaviour specs and test plans

---
```

- **Request Changes**: apply the changes to the named screen files, add a row to the Review history,
  re-run the standards self-check on the changed screens, reopen `index.html`, and present the
  message again. Repeat until the user approves. This loop is driven by the user, so the self-healing
  attempt cap does not apply to it. A requested change never lowers the accessibility floor in
  `common/ui-ux-design-standards.md` Section 3; if one would, say so and offer the nearest compliant
  alternative.
  - A requested change that goes beyond the approved acceptance criteria is not built. Add it to
    **Out of scope** and say in one line that it needs an acceptance-criteria change: through
    `epic-change-request` in an epic cycle, or a new ticket in a bug or enhancement cycle. Then
    continue.
- **Continue to Next Stage**: go to Step 6.
- Log the prompt before presenting it and the user's complete raw response after receiving it, per
  `common/audit-logging.md`.

## Step 6: Register and hand over

1. Add one row per screen file to `## Design References` in `runtime-artifacts/aire-state.md`:

   | # | Path / Location | Type | Governs | Read? | Read At Stage |
   |---|---|---|---|---|---|
   | n | spec/plans/ui-ux/SCR-02-sign-in.html | UI prototype (AIRE-generated) | story-1.2 | ✓ | UI/UX Mockups |

2. Record each Out of scope item as a `Reconciled` row (decision: EXCLUDED — not in the approved
   acceptance criteria), per DR-8, so no later stage builds it from the mockup.
3. Update `## UI/UX Design` with `Screens`, `Work units covered`, `Review rounds` and `Approved`
   (ISO 8601 timestamp).
4. Return to `specs-and-test-plans.md` Part A. The files are committed with the design commit at
   the end of the STOP CHECKPOINT. This stage makes no commit of its own.

## Step 7: Provided designs

Used in `provided` and `provided+generate` modes.

1. Every provided path is already registered in `## Design References` (DR-1). Confirm each exists
   and **read its content** (DR-2, DR-3). Images and PDFs are read visually, HTML and CSS as text, and
   Office documents by unzipping them.
2. If a provided item cannot be read (a design-tool file or a link that needs a sign-in), say which
   item and ask the user for an export (PNG, JPG, PDF or HTML) placed in
   `spec/context-project/new-references/`. If none is supplied, record the item as `not readable — not
   used` in the registry, say so, and continue.
3. Write `spec/plans/ui-ux-design.md` with the screen inventory mapped to the provided files, and a
   **Not covered** list: every in-scope work unit that no provided design shows.
4. Report the coverage in one short block. In `provided` mode this needs no approval, because the
   designs are the user's own. Return to `specs-and-test-plans.md` Part A. In `provided+generate`
   mode, continue with Step 1 for the Not covered units only.

---

## How later steps use the mockups

- **Behaviour specs and test plans** (`specs-and-test-plans.md` Parts A and B, immediately after this
  stage): scenario steps and manual test steps use the screen names, labels and messages shown in the
  approved mockups.
- **Code generation** (`dev-implement`, `bug-fix-implement`, `enhancement-implement`): the
  registered rows bring DR-5 into force. Every component in the code-generation plan carries
  `Design reference: spec/plans/ui-ux/<file> — grounded (…)`, or `none covers this component`.
  `code-generation.md` Step 1.6 then applies `common/ui-ux-design-standards.md` to the real frontend
  code, using the agreed tokens, accessibility level, screen sizes and UX patterns recorded in
  `ui-ux-design.md`.
- **Precedence** for AIRE-generated mockups: the approved acceptance criteria decide behaviour and
  scope, and the mockup decides layout, wording and visual detail the criteria leave open. Recorded
  reconciliations win over both (DR-8). User-provided designs follow DR-8 as written.
- **Cycle close**: `archive-epic` archives `spec/` in full, so the mockups are kept with the cycle.
- **Atlas**: when Atlas Artifact Sync is enabled, the screen files and `index.html` are uploaded to the
  cycle's Atlas folder like every other spec artifact (`common/atlas-artifact-sync.md` Section 5).

## Rules (for the stage compliance summary)

| Rule | Requirement |
|---|---|
| UX-01 | Every in-scope work unit has an approved mockup or a readable provided design, or is listed as Not covered in `provided` mode |
| UX-02 | Generated mockups show nothing beyond the approved acceptance criteria; extra items are listed as Out of scope and reconciled |
| UX-03 | Mockups are approved before the behaviour specs and test plans are written |
| UX-04 | Every approved mockup and every readable provided design is registered in `## Design References` |
| UX-05 | Screen files are self-contained and never imported by application code |
| UX-06 | Every generated screen passes the `ui-ux-design-standards.md` Section 7 self-check (accessibility at WCAG 2.2 AA minimum, responsive across every supported size, shared tokens) |

Before the STOP CHECKPOINT every rule is N/A. After this stage completes, UX-01 to UX-06 apply
(UX-06 is N/A in `provided` mode).

## State and audit

Record in `runtime-artifacts/aire-state.md`:

```markdown
## UI/UX Design
- **Mode**: generate
- **Provided design path(s)**: —
- **Decided At**: Requirements Analysis
- **Screens**: [S] in spec/plans/ui-ux/
- **Work units covered**: [U]
- **Review rounds**: [R]
- **Approved**: [ISO 8601 timestamp]
```

Log in `runtime-artifacts/audit.md`, per `common/audit-logging.md`: the stage start, the scope
decision, each review round (the user's complete raw request and what changed), the approval prompt
and the user's complete raw response.
