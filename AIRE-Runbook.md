# HELIX AIRE EXAMPLE RUNBOOK

**Prepared by:** Helix AIRE v1 Team
**Date:** 2026-10-07


---

## Why This Document Exists

Here's the question this document answers:

> *"A pod is handed an intent and a codebase. What should they actually do with AIRE v1 ?"*

This playbook shows you exactly what to do. It maps out who runs each step, what to type, which
questions you will be asked, which documents you approve, and what you have at the end, taking you
from a product intent to a reviewed, merged Epic and a complete archive of the cycle.

## Three Ways to Run AIRE

The **same AIRE framework** (same stages, same approval checkpoints, same artifacts) can be run in **three
ways**.

| | **Way 1 (Local)** | **Way 2 (Helix MCP)** | **Way 3 ( Helix Enterprise Studio Build)** |
|---|---|---|---|
| **You work in** | Claude Code (terminal, desktop app or IDE) inside your repository | Claude Code in your repository, with the **Helix MCP** connected | *(TBD)* |
| **Where the Epic comes from** | You create it (`/intent-intake`, `/intent-refinement`) or point to one in Jira, Azure DevOps or GitHub | **Fetched from your Helix ATLAS solution** when it exists there otherwise created with `/intent-intake` and `/intent-refinement` | *(TBD)* |
| **Existing-system description** | Reverse engineering runs locally (when no deep dive is in the repository) | **Deep dive fetched from ATLAS** when it exists there otherwise reverse engineering generates it | *(TBD)* |
| **Where it runs** | Your machine | Your machine | *(TBD)* |
| **Read** | **Way 1** (Phases 0–2, Steps 1–15) | **Way 2** (Steps 1–8) | *(TBD)* |


The cycle runs in three phases:

```
PHASE 0: Prepare          PHASE 1: Planning           PHASE 2: Implementation
--------------------      ----------------------      ------------------------------------------
Setup + Intent        --> Using AIRE              --> System design stages
(intent-intake,           Reverse engineering         architecture.md + rubrics + CI pipeline
 intent-refinement)       (when needed)(Local)        UI/UX mockups (optional)
                          Requirements                Gerkhin Scenarios + test plans
                          Stories                     dev-implement per story, PR review + merge
                          Dependency graph            Verification Engineer sign-off
                          Workflow planning           archive-epic
                          Application design          stitch-delta
```

### Who's Who

| Role | What they do in AIRE |
|---|---|
| **Intent Architect** | Shapes the Epic/Bug/Enhancemnet, starts the workflow, answers the planning questions, approves requirements and the stories, closes the cycle |
| **Architect** | Answers the design questions and approves each design document and the behaviour specs |
| **Developer** | Builds one story at a time with `dev-implement`, reviews and merges story pull requests with Verification Engineer |
| **Verification Engineer** | Owns and approves the test plans, tests each merged story and signs it off with `ve-list-work` |

The framework never merges a story, bug, enhancement or Epic pull request on anyone's behalf, every merge is a human decision.

---

# WAY 1 — Local (Claude Code in Your Repository)

---

## Phase 0 — Prepare

### What This Section Covers
What has to be in place before the first `Using AIRE`, and how to turn a raw idea into an Epic the
framework can build from.

---

### Step 1 — One-Time Setup

1. **Get the framework into your repository.** Ask an HELIX AIRE maintainer to add your repository to the
   subscriber registry. An installation pull request arrives carrying `CLAUDE.md`, `aire-workflow/`,
   `.claude/skills/`, the AIRE section of `.gitattributes` and `.aire-version`. **Review and merge it.**
   Later framework versions arrive the same way, as update pull requests.
2. **Install the prerequisites** (full instructions in the README's Prerequisites section of the HELIX AIRE repo):

   | Tool | 
   |---|
   | Claude Code (CLI, desktop app or IDE extension)  | 
   | GitHub CLI `gh` | 
   | Atlassian MCP server |  
   | Azure CLI + `azure-devops` extension | 
   | Podman | 
   | Playwright + its official test agents | 

3. **Turn off Claude Code's built-in `code-review` skill.** AIRE has its own `code-review` workflow and the
   built-in one would intercept it. Add this to `~/.claude/settings.json` and restart Claude Code:

   ```json
   "skillOverrides": {
       "code-review": "off"
   }
   ```

4. **Install Playwright from the workspace root** (the folder that holds
   `spec/`), then restart the session:

   ```bash
   npm i -D @playwright/test
   npx playwright install
   npx playwright init-agents --loop=claude
   ```

---

### Step 2 — Capture the Idea (Optional)

**Who:** Intent Architect · **Type:** `/intent-intake`

Skip Steps 2 and 3 if your Epic already exists in your tracker.

1. **Type** `/intent-intake`. The skill asks whether you have a document to work from (a PRD, research
   notes, a Confluence page) or would rather explain in plain English.
2. **Answer the six baseline fields:** the outcome, how success is measured, the success signal, what is
   out of scope, the known constraints, and your confidence with the open unknowns.
3. **Confirm the draft.** The skill creates an Epic in Jira, Azure DevOps or GitHub, labelled
   `intent-intake`.

**What you get:** a baseline Epic 

---

### Step 3 — Refine the Epic (Optional)

**Who:** Intent Architect (with engineers) · **Type:** `/intent-refinement`

1. **Type** `/intent-refinement` and give the Epic created using `/intent-intake`.
2. The skill fetches the Epic, shows what is present and missing, and works through focused question
   batches: measurable success criteria with thresholds, scope and exclusions, constraints, the domain
   model, quality expectations and risks.
3. **Confirm.** The same Epic is updated and labelled `intake-refined`, and the skill tells you how to
   start AIRE.

**What you get:** an Epic that is detailed and verifiable — the primary input to everything that follows.

---

## Phase 1 — Planning

### What This Section Covers
The **WHAT and WHY**: how the framework starts, what it asks you, and how an Epic becomes approved
requirements, an approved story set in your tracker, a dependency graph, a workflow plan and when new
components are needed.

---

### Step 4 — Start the Workflow

**Who:** Intent Architect · **Type:** `Using AIRE, <epic reference>`

1. **Open Claude Code in the repository** and check out the base branch the Epic should eventually merge into
   (usually `main`). This becomes the recorded **base branch**.
2. **Type one of:** to provide the Intent

   ```
   Using AIRE, https://yoursite.atlassian.net/browse/PROJ-42                  # Jira
   Using AIRE, https://dev.azure.com/myorg/MyProject/_workitems/edit/4821     # Azure DevOps
   Using AIRE, https://github.com/my-org/my-repo/issues/42                    # GitHub
   Using AIRE, <a plain description of what to build>                         # Local only
   ```
   

3. **Work through Workspace Detection.** It always runs in this order:
   - **Welcome message**, stamped with the framework version.
   - **Resume check:** If `runtime-artifacts/aire-state.md` already exists, the workflow resumes where it
     stopped instead of starting over.
   - **Tracker question:** JIRA, ADO, GITHUB or LOCAL. Asked once per Cycle.
   - **Epic capture:** The Epic is recorded as the Parent Epic and copied into `spec/plans/epic-brief.md`.
   - **Project Type Detection:** New (greenfield) or existing (brownfield) codebase.
   - **Deep dive check** (for existing codebases).
   - **Epic branch:** `epic/<EPIC-ID>-<title>` is cut from the base branch. All cycle work happens here.
   - **Context question:** Answer each part with a path or `no`:

     ```
     1) Existing knowledge: notes on how the current system works.
        Place under spec/context-project/existing-knowledge/      (existing codebases only)
     2) New references: what to build (wireframes, mockups, API specs, diagrams).
        Place under spec/context-project/new-references/
     ```

   **The deep dive check:**

   | What the framework finds | What happens |
   |---|---|
   | `spec/plans/atlas-deep-dive.md` already in the repository | Reused as it is. Reverse engineering is skipped. |
   | No deep dive in the repository | Reverse engineering runs locally by the framework. |


#### Understanding the Three Kinds of Interaction

Every AIRE interaction is one of three kinds. Here's how to handle each:

**Question files** — Every planning and design questions are written to a file under
`spec/spec-generation/` (for example `requirement-verification-questions.md`). Each question has lettered
options with an "Other" choice. Write your answer after the `[Answer]:` tag, save the file, and reply
`done` in the chat. If an answer is ambiguous, the framework asks a follow-up rather than guessing.

```
## Question 3
Where should session data live?

A) In-memory store
B) Relational database
C) Distributed cache
D) Other (please describe after [Answer]: tag below)

[Answer]: B
```

**Approval checkpoints** — every document that shapes the build waits for an explicit decision:

| Checkpoints | Your choices |
|---|---|
| Requirements, story set, Application Design | **Request Changes** or **Approve & Continue** |
| Functional, NFR, Infrastructure Design, UI/UX mockups, behaviour specs and test plans | **Request Changes** or **Continue to Next Stage** |

Choose **Request Changes** and say what to change in the chat. The framework revises the document and
presents the checkpoint again. It never moves on without your explicit approval.

**Chat-only questions** — three questions are always asked in the chat, never in a file: the tracker,
the context folders, and whether to set up the CI pipeline. The manual CI setup instructions are showed in full
and you answer with `proceed` or `skip`.


> **Sessions are disposable.** Every answer, approval and stage is recorded in
> `runtime-artifacts/aire-state.md` and `runtime-artifacts/audit.md`. Close the session, switch machines or
> hand over to a colleague, the next session picks up exactly where the last one stopped.

---

### Step 5 — Reverse Engineering (Existing Codebases Only, When Needed)

**Runs:** automatically, only when the deep dive check finds no deep dive
and no earlier reverse-engineering documents exist anywhere in the repository

1. The framework analyses the code and writes the business overview, architecture, code
   structure, APIs, component inventory, interaction diagrams, technology stack and dependencies
   in `spec/plans/`.
2. **Review and approve the result.** The workflow does not continue until you do.

**What you get:** a detailed description of the current system that every later stage builds the change against.


---

### Step 6 — Requirements Analysis

**Who:** Intent Architect · **Checkpoint:** Request Changes / Approve & Continue

1. The framework reads `epic-brief.md` (plus the existing-system documents on brownfield work) and picks a
   depth: **minimal** for a clear, simple request, **standard** for normal work, **comprehensive** for
   complex or high-risk work.
2. **Answer the questions** in `spec/spec-generation/requirement-verification-questions.md` and reply
   `done`. The file also asks whether to turn on the optional extensions (resiliency, property-based
   testing and UI/UX mockups). The Security Baseline and Playwright automation are always on and are
   never asked.

   **The UI/UX mockups question** decides whether the design handoff (Step 10) includes a mockup
   review:

   | Your answer | What happens at Step 10 |
   |---|---|
   | **A) Yes, produce HTML mockups for review** | The framework builds HTML mockups of every screen the stories touch and reviews them with you |
   | **B) No, designs already exist** | Place your designs in `spec/context-project/new-references/` and enter the path after `[Answer]:`. The framework uses them instead of producing mockups |
   | **C) No, skip this step** | No mockup stage. Choose this when the work has no user interface |

   If you already gave designs at the context question (Step 4), the question asks only whether to
   produce mockups for the screens your designs do not cover.
3. **Review `spec/plans/requirements.md`.** Every requirement has a permanent identifier such as `REQ-F-03`.
4. **Approve.** The planning documents are committed and pushed on the Epic branch. No pull request is
   raised.

**What you get:** the agreed definition of *what* to build — every story, test and review later traces
back to these identifiers.

> **This is the right place to freeze the right a misunderstanding.** A wrong requirement caught here costs one
> edit. Caught after stories are built, it costs an `epic-change-request` (Step 14).

---

### Step 7 — User Stories and the Dependency Graph

**Who:** Intent Architect · **Checkpoint:** Request Changes / Approve & Continue

1. **Answer the story plan questions** in `spec/spec-generation/story-generation.md` and reply `done`.
   The framework never asks for team size (it is fixed at two)
2. **Review the story set.** `spec/plans/stories.md` and `spec/plans/personas.md` are written in one pass.
   Every story lists its acceptance criteria and the requirements it covers, and every requirement must
   be covered by at least one story.
3. **Approve the story set.** On **Approve & Continue**:
   - Each story is created in your tracker, set to **Ready for Development**, labelled with the AIRE
     version, linked to the Parent Epic, and its tracker ID is written back. For Local, nothing leaves the
     repository.
   - **Dependency Graph (automatic):** the framework works out which stories need which others first,
     writes `spec/plans/dependency-graph.yml`, and shows which stories can start now. Stories, personas
     and graph are committed and pushed together.
   - **Workflow Planning (automatic):** the framework decides which design stages this Epic needs and
     records why in `spec/plans/executions.md`.

**What you get:** an approved story set in your tracker and a graph that tells every developer which
stories they can pick up in parallel.


---

### Step 8 — Application Design (When Needed)

**Who:** Architect · **Checkpoint:** Request Changes / Approve & Continue

This stage runs only when Workflow Planning finds that new components or services are needed. Otherwise
it is skipped, and the skip is recorded.

1. **Answer the questions** in `spec/spec-generation/application-design-generation.md` and reply `done`.
2. **Review `spec/plans/application-design.md`:** the components, their methods, the services and how they
   depend on each other.
3. **Approve.** On **Approve & Continue** the workflow moves into the Implementation phase.

**What you get:** the component boundaries every later design stage and story builds within.

---

### End of Planning Checkpoint

At this point the Epic branch should hold:
- `spec/plans/epic-brief.md`, `requirements.md`, `stories.md`, `personas.md`, `dependency-graph.yml`,
  `executions.md`, and `application-design.md` if that stage ran
- `atlas-deep-dive.md` (or the local reverse-engineering documents) on existing codebases

Your tracker should hold every story at **Ready for Development**, linked to the Parent Epic.

---

## Phase 2 — Implementation

### What This Section Covers
The **HOW**, in three parts:
- **Design (Steps 9–10):** the system-level design, the architecture document the code will be judged
  against, every story's behaviour contract and test plan.
- **Build (Steps 11–14):** how developers build stories one at a time, how pull requests are reviewed and
  fixed, how the Verification Engineer signs each story off, and what to do when a change arrives mid-Epic.
- **Close (Step 15):** how to raise the Epic pull request and archive the cycle.

---

### Step 9 — System-Level Design Stages

**Who:** Architect · **Checkpoint:** one per stage

These stages run once for the whole system, and only the ones Workflow Planning selected. Each asks its
own questions in a file, writes its document, and waits for your decision. No code is written here.

| Stage | Runs when | Document | Checkpoint |
|---|---|---|---|
| Functional Design | New data models or complex business rules | `functional-design.md` | Request Changes / Continue to Next Stage |
| NFR Requirements | Performance, security or scalability targets, or a stack choice | `nfr.md` | Request Changes / Continue to Next Stage |
| NFR Design | NFR Requirements ran | `nfr.md` | Request Changes / Continue to Next Stage |
| Infrastructure Design | Environments, hosting or cloud resources change | `infrastructure-design.md` | Request Changes / Continue to Next Stage |

On existing codebases, the existing-system architecture is the starting point and each document records the change
from it.

---

### Step 10 — The Design Handoff Checkpoint

**Who:** Architect  · **Checkpoint:** Approval for all specs and test plans

This step runs once for the whole Epic, in this order:

1. **CI question (in the chat):** `Set up the CI/CD eval pipeline for this project? (yes/no)`.
2. **`spec/behavior.feature`** — the Gerkhin scenarios for the whole Epic, run on the last story only.
3. **`spec/plans/architecture.md`** — assembled from the approved design documents and the existing-system documents. It always contains a System Context and a Component Architecture diagram.
4. **Rubrics and thresholds** in `tests/.evals/`: `architecture-rubric.json` derived from
   `architecture.md`, `security-rubric.json` from the OWASP Top 10 2025 (the J2 judge), and
   `config.json`, which holds every threshold.
5. **CI pipeline** (only on `yes`): `.github/workflows/agentic-eval-pipeline.yml` is generated from your
   repository's real build files and the `config.json` thresholds. The framework then prints the
   SonarQube and secrets manual setup instructions and waits for the user. Do the steps, then type `proceed` — or
   `skip` to leave SonarQube off.

   | Secret | Without it |
   |---|---|
   | `CLAUDE_CODE_OAUTH_TOKEN` (from `claude setup-token`) | Judge scoring and CI self-repair are skipped |
   | `SONAR_TOKEN` + `SONAR_HOST_URL` | SonarQube is skipped |

6. **UI/UX mockups** (Optional). See
   [The UI/UX Mockups Stage](#the-uiux-mockups-stage) below.
7. **Behaviour specs and test plans for every story**, before any code exists:
   - `spec/behavior/story-N.M.feature` — one `@AC-<n>` scenario per acceptance criterion, failure paths
     included.
   - `spec/test-plans/<TICKET-ID>-<title>/` — the test plan, written by the `ve-implement` skill.
   - A coverage check: every acceptance criterion has at least one scenario and one test case.
   - When mockups were approved, the scenarios and test steps use the same screen names, labels and
     messages.

   **Review the whole set with Verification Engineer** and choose Request Changes or Continue to Next Stage.
8. **Commit and push** everything on the Epic branch.
9. **CI smoke test** (only on `yes`): a zero-change draft pull request is raised to check the CI environment works. On
   success it is merged into the Epic branch and its branch deleted.
10. **Development Handoff.** The framework reports how many stories exist, which can start now and which
    design stages ran.

#### The UI/UX Mockups Stage

**Who:** The Intent Architect · **Checkpoint:** Request Changes / Continue to Next Stage

This stage runs only if you opted in at Requirements Analysis. It skips itself, when no
story changes the user interface.

1. **Answer the design questions,** if any. The framework reads the requirements, the stories, the
   design documents and, on existing codebases, the current interface first. It then writes
   `spec/spec-generation/ui-ux-design-questions.md` with only the points still open. These can include:
   visual basis, supported screen sizes, accessibility level, information density, navigation, feedback
   style, loading style, and brand colour and tone. Answer them and reply `done`. If nothing is open, no
   file is written.
2. **The framework builds the mockups** in `spec/plans/ui-ux/`: an `index.html` that links every
   screen, and one self-contained HTML file per screen covering its default, empty, loading, error and
   success states.
3. **Review the mockups.** The framework opens `index.html` in your browser and summarises the screens in
   `spec/plans/ui-ux-design.md`.
   - **Request Changes:** describe what to change in the chat. The framework updates the screens, opens
     them again and presents the checkpoint again. Repeat as often as needed.
   - **Continue to Next Stage:** the mockups are approved and recorded as the design reference for
     every story they cover.

**What you get:** an approved picture of every screen before any code is written. `dev-implement`
builds each story's interface from it and applies the same accessibility, responsive and token
standards to the real code.

---

### End of Design Checkpoint

At this point the Epic branch should also hold:
- The design documents that ran, and `architecture.md`
- `spec/behavior.feature`, one `spec/behavior/story-N.M.feature` per story, one test plan folder per story
- `tests/.evals/config.json` and `tests/.evals/rubrics/`
- The CI pipeline, if you said yes
- `spec/plans/ui-ux-design.md` and the approved mockups in `spec/plans/ui-ux/`, if you opted in to
  UI/UX mockups

---

### Step 11 — Build a Story with `dev-implement`

**Who:** Developer · **Type:** `dev-implement`

1. **Developer manually gets the latest Epic branch:**

   ```
   git fetch origin
   git checkout epic/PROJ-42-checkout
   git pull --ff-only
   ```

2. **Type** `dev-implement` exactly as shown, then name the story — its tracker key (`PROJ-102`) or its
   number (`1.2`).
3. **The run proceeds on its own:**

   | Stage | What happens |
   |---|---|
   | Doability check | Every prerequisite story must be merged or Ready for Testing. If not, the run stops and names what is outstanding — merge it, then type `dev-implement` again |
   | Tracker | The story moves to In Development on both trackers and is assigned to you. The first story also moves the Epic |
   | Story branch | `story/N.M-<title>` is cut from the Epic branch, the commit hook is installed |
   | Baselines | The full test suite, the seven static evals and the existing Playwright suite run *before* any code, so old problems are never blamed on this story |
   | Plan | Written to `spec/spec-generation/story-N.M-code-generation.md`.|
   | Code | Application code into `src/` (or the Code Root), tests into `tests/` |
   | Evaluation | Unit tests and changed-line coverage (90 percent by default) → behaviour tests B1/B2 (and B3 on the last story) in Podman → API and contract tests → test placement → full regression → static evals D1–D7 → Playwright |
   | Code review | Acceptance criteria, the 16-rule Security Baseline on the changed code, and the J1 and J2 judge scores (0.85 minimum by default). Findings are fixed and re-reviewed automatically |
   | Evidence and commit | `eval.json` and `eval-summary.md` are written, the commit carries an `AIRE-Version` trailer |
   | Pull request | A `[STORY]` pull request into the Epic branch with the scorecard in its description, CI (when on), then an automatic PR review |


#### When dev-implement Stops: the Three-Attempt Limit

Every automatic repair loop has three attempts. If a Evaluation criteria is still failing after that, the run stops at
that Eval and tells you what is failing, why it stopped, what it tried (left in your working tree), how to
reproduce and fix it.

1. **Fix the problem yourself.**
2. **Type the same keyword again** (`dev-implement`). The framework finds the stopped work, looks at what
   you changed, never undoes your edits, gives the loop a fresh three attempts, and carries on to the pull
   request.

> **Parallel development.** Two developers can each run `dev-implement` on different stories at the same
> time by refering the dependency graph.

---

### Step 12 — Review and Merge the Story Pull Request

**Who:** Developer and Verification Engineer

1. **Read the pull request:** the scorecard in the description, the automatic PR review comment, and the CI
   result when CI is on.
2. **If changes are needed,** leave review comments, then the developer types `pr-fix <PR-NUMBER>`:
   - It reads every unresolved comment and sorts each into issue.
   - It merges the latest Epic branch into the story branch, makes the fix,
     re-runs every `dev-implement` eval, pushes to the **same** pull request and replies to each comment.
   - It asks a question only when a comment would change an approved acceptance criterion or two
     reviewers disagree.
3. **Merge the pull request manually.** A story that depends on this one can start only after this merge.

---

### Step 13 — The Verification Engineer Track

**Who:** Verification Engineer · **Works on:** the Epic branch

**After each story pull request merges — test and sign off:**
1. Type `/ve-list-work` and choose **A** to list which story has merged and is still In Development.
2. **Build the Epic branch locally** and execute the story's test plan.
3. Type `/ve-list-work` and choose **B**, with one decision per story, for example `1.1 approve, PROJ-103 reject`.
   - **Approve:** `ve-approved` label, story moves to **Ready for Testing** on the tracker.
   - **Reject:** `ve-rejected` label, story stays **In Development**. Log the problem with
     `/raise-defect`.
4. Use **C** to add or adjust a manual test case. It edits the files only — commit and push them yourself.

When every story is approved, `ve-list-work` offers to move the Parent Epic to Ready for Testing.

---

### Step 14 — Handle Changes While the Epic Is Open

**Who:** Developer or Intent Architect

Changes that arrive mid Epic are delivered inside the Epic, on the Epic branch, never as a separate cycle.
Pick the workflow by what changed:

| Situation | Type | What you approve |
|---|---|---|
| Eg: "Make button yellow" - small enhancement | `epic-enhance <TICKET-ID or description>` | One document, `spec/plans/change-story-N.M.md` |
| "X is broken" — a defect in work this Epic built | `epic-bugfix <TICKET-ID or description>` | One document, `spec/plans/bugfix-story-N.M.md` |
| "We agreed X, now we agree Y" — the requirement itself changed | `epic-change-request <TICKET-ID, description, or <path> to a prd>` | One staged change request files |

- `epic-enhance` and `epic-bugfix` build the change and raise a `[STORY]` pull request.
- `epic-change-request` writes no code: it versions the requirement (`REQ-F-03@v2`), amends the affected
  specs and test plans, and creates new stories if required.

---

### End of Build Checkpoint

Before closing the cycle, confirm:
- Every story pull request is **merged** into the Epic branch.
- Every story is **Ready for Testing**, signed off by the Verification Engineer.

---

### Step 15 — Raise the Epic Pull Request and Archive

**Who:** Intent Architect · **Type:** `/pr-generator` (on the Epic branch)

1. **Type** `/pr-generator` on the Epic branch. It targets the recorded base branch and **asks you to
   confirm** before opening PR.
2. It raises (or updates) the `[EPIC]` pull request into the base branch, then **`archive-epic` runs
   automatically**:
   - Writes the cycle's delta to `spec/plans/delta/<EPIC-ID>-<name>/`.
   - Copies `spec/`, `reports/`, `runtime-artifacts/` and `tests/.evals/rubrics/` into
     `aire-archives/epics/<EPIC-ID>-<name>/` and verifies the copy.
   - Removes the live `spec/`, `reports/`, `runtime-artifacts/` and `tests/.evals/rubrics/`.
   - Commits and pushes, so all of this lands in the open Epic pull request.
3. **Review and merge the Epic pull request manually.**

**What you get:** the Epic in the base branch, and a complete, self-contained record of the cycle in
`aire-archives/`.

---

### End of Cycle Checkpoint

- The `[EPIC]` pull request is merged.
- `aire-archives/epics/<EPIC-ID>-<name>/` holds the cycle record.

---

# WAY 2 — MCP (Helix MCP)

You drive AIRE in **Claude Code**, exactly as in Way 1, but with the **Helix MCP connected**. Claude Code
can then reach your **Helix ATLAS solution** and fetch what already exists there: the **Epic** (the
intent) and the project **deep dive** document. Each one is fetched **only if it exists**.

### What Is Different from Way 1

| | **Way 1 — Local** | **Way 2 — MCP** |
|---|---|---|
| **Epic** | Created with `/intent-intake` and `/intent-refinement`, or read from a tracker link | **Fetched from ATLAS** when it exists there. If it does not, create it with `/intent-intake` and `/intent-refinement` |
| **Existing-system deep dive** | Never fetched. Reverse engineering writes it locally (Step 5) | **Fetched from ATLAS** when it exists there. If it does not, reverse engineering generates it locally |
| **Everything after that** | Steps 6–15 | **Identical: Steps 6–15 of Way 1** |
| **Closing the cycle** | Step 15 | Step 15, then Step 16 (**refresh ATLAS**) |

### The Three Situations

What the run does depends on what your ATLAS solution already holds. The framework checks the **Epic** and
the **deep dive** independently.

| | **Epic on ATLAS** | **Deep dive on ATLAS** | Intent Intake and Refinement | Reverse Engineering |
|---|---|---|---|---|
| **Situation A** | Yes | Yes | **Skipped** (Epic is fetched) | **Skipped** (deep dive is fetched) |
| **Situation B** | **No** | Yes, or No | **Run them** (Steps 2–3 of Way 1) to create the Epic | **Skipped** if the deep dive is fetched, **runs** if it is not |
| **Situation C** | Yes | **No** | **Skipped** (Epic is fetched) | **Runs** and generates the deep dive |

---

### Step 1 — One-Time Setup

**Who:** The whole Pod

1. **Complete the Way 1 setup (Step 1)**: the framework in your repository, Claude Code, `gh`, Playwright
   and the other prerequisites.
2. **Connect the Helix MCP in Claude Code:** Claude Code must be able to reach Helix. If it is not
   connected, nothing can be fetched and the run stops at the Helix checkpoint (Step 3).

---

### Step 2 — Create the Epic When It Is Not on ATLAS (Situation B Only)

**Who:** Intent Architect · **Type:** `/intent-intake`, then `/intent-refinement`

**Skip this step** when the Epic already exists on ATLAS (Situations A and C).

1. **Run `/intent-intake`** and then **`/intent-refinement`**, exactly as in Way 1 (Steps 2 and 3). They create
   and refine the Epic in your tracker.
2. **Keep the Epic reference** (for example its Jira link). You use it to start the workflow in Step 3.

---

### Step 3 — Start the Workflow

**Who:** Intent Architect · **Open Claude Code in the repository** and check out the base branch the Epic
should eventually merge into (usually `main`), as in Step 4.

**Type the keyword that matches your situation:**

```
Using AIRE, implement the epic from Helix                       # Situations A and C: the Epic is on ATLAS
Using AIRE, https://yoursite.atlassian.net/browse/PROJ-42       # Situation B: the Epic you created in Step 2
```

**Work through Workspace Detection.** The order is the same as Step 4, with these differences:
- **Tracker question:** JIRA, ADO, GITHUB or LOCAL, asked once, as in Way 1.
- **Epic capture:** in Situations A and C the Epic comes **from ATLAS through the Helix MCP**, not from a
  tracker fetch. It is copied verbatim into `spec/plans/epic-brief.md`, with its source recorded. In
  Situation B it is read from the tracker link, as in Way 1.
- **Project Type Detection:** existing codebase (brownfield), so the existing-system check follows.
- **Helix gate (below):** the deep dive is looked up on ATLAS in every situation, and the Epic as well in
  Situations A and C.
- **Epic branch and context question:** as in Step 4.

#### The Helix Checkpoint

**Runs:** automatically during Workspace Detection

| What the framework finds | What happens |
|---|---|
| `spec/plans/atlas-deep-dive.md` already in the repository | Reused as it is. ATLAS is not asked for the deep dive again. Reverse engineering is skipped |
| The deep dive is on ATLAS | Fetched **verbatim** into `spec/plans/atlas-deep-dive.md`. Reverse engineering is skipped |
| The Epic is on ATLAS (Situations A and C) | Fetched **verbatim** into `spec/plans/epic-brief.md`. Intent Intake and Refinement are not used |
| The deep dive is **not** on ATLAS, or Helix MCP is not connected | The workflow **stops** at a checkpoint with options **A** and **B**. **A)** connect Helix MCP, or create the deep dive on ATLAS, and run again. **B)** continue without it: the framework generates the existing-system documents locally, marked *"Existing-system context derived locally"*. This is **Reverse Engineering (Step 4)** |
| The Epic is **not** on ATLAS, and you started with `implement the epic from Helix` | The Epic cannot be fetched. Create it first with `/intent-intake` and `/intent-refinement`, then start again with its reference |


---

### Step 4 — Reverse Engineering (Only When the Deep Dive Is Not on ATLAS)

**Runs:** automatically

The framework analyses the code, writes the business overview, architecture, code
structure, APIs, component inventory, technology stack and dependencies into `spec/plans/`, and waits for
your approval. The generated documents are the deep dive for this cycle. When the deep dive **was** fetched
from ATLAS, this step is skipped and the skip is logged.

---

### Step 5 — The Normal AIRE Flow Continues

From here **the AIRE framework works exactly as in Way 1**, whichever situation you were in. Nothing about
the stages, questions or gates changes.

| Stage | Follow |
|---|---|
| Requirements Analysis, using `epic-brief.md` and the deep dive | Way 1, **Step 6** |
| User Stories and the Dependency Graph | Way 1, **Step 7** |
| Application Design (when needed) | Way 1, **Step 8** |
| System-level design stages | Way 1, **Step 9** |
| Design handoff checkpoint (UI/UX mockups when opted in, specs, test plans, rubrics, CI) | Way 1, **Step 10** |
| Build each story with `dev-implement` | Way 1, **Step 11** |
| Review and merge story pull requests | Way 1, **Step 12** |
| Verification Engineer sign-off | Way 1, **Step 13** |
| Changes while the Epic is open | Way 1, **Step 14** |
| Raise the Epic pull request and archive | Way 1, **Step 15** |

On the design documents, the deep dive (fetched or generated) is the starting point and each document
records the change from it.

---

### Step 6 — Push the Specs Back to ATLAS (Optional)

**Who:** Intent Architect · **You answer:** `yes` or `no`

The fetch works in both directions. During the cycle the framework **asks whether you want to push the
specs to ATLAS**, *"Do you want to push the specs to ATLAS?"*, and it never pushes without your
answer.

| Your answer | What happens |
|---|---|
| **Yes** | The framework pushes the specs to your Helix ATLAS solution **through the Helix MCP**. They are then available on ATLAS along with other solution documents |
| **No** | Nothing is sent. The specs stay in the repository only, and the cycle continues unchanged |

- The push goes through the same **Helix MCP** you connected in Step 1. If it is not connected, the push
  cannot happen.
- Answering **no** never blocks the cycle. You can still refresh the ATLAS deep dive at the end with
  `/stitch-delta` (Step 8).
- Every question and your answer are recorded in `runtime-artifacts/audit.md`, like every other decision.

---

### Step 7 — Check the Epic Branch Before Moving On

At the end of planning, the Epic branch should hold the Way 1 planning files, plus:

| File | Situation A | Situation B | Situation C |
|---|---|---|---|
| `spec/plans/epic-brief.md` | As **fetched from ATLAS** | From the Epic you created in Step 2 | As **fetched from ATLAS**, with its provenance block |
| `spec/plans/atlas-deep-dive.md` | As **fetched from ATLAS** | Fetched from ATLAS if it exists, otherwise the locally generated reverse-engineering documents | The locally generated reverse-engineering documents |

---

### Step 8 — Refresh ATLAS with `stitch-delta`

**Who:** Intent Architect · **Type:** `/stitch-delta` (on the base branch, after the merge)

1. **Pull the base branch** after the Epic pull request has merged.
2. **Type** `/stitch-delta`. It finds every archived delta not yet stitched, refreshes **the whole**
   ATLAS deep dive against the merged code.
3. It appends one row to `aire-archives/stitch-ledger.md` and raises a `[STITCH]` pull request. **Merge it manually.**

**What you get:** ATLAS deep dive document describes the system as it is after this cycle. The next cycle reads its
existing-system truth from there. In Situation C this is also how the deep dive first reaches ATLAS.

> **Don't skip this.** Without it, the next cycle starts from an out-of-date description of the system.

---

### End of Cycle Checkpoint

- The `[EPIC]` and `[STITCH]` pull requests are merged.
- `aire-archives/epics/<EPIC-ID>-<name>/` holds the cycle record.
- The ATLAS deep dive describes the system as it is after this cycle.

---

# WAY 3 — Web (Helix Enterprise Studio Build) 

> **TBD.** 

---

# Common Questions (All Three Ways)

## Common Questions

**Q: Do I have to follow this exact order?**
A: Yes for the phases the framework enforces it. Code cannot start before the design handoff, a story
cannot start before its prerequisites merge, and a cycle cannot close before its archive.

**Q: Can the framework merge a pull request for me?**
A: No. Story, bug, enhancement, Epic and stitch pull requests are always merged by a person. The only
pull request the framework merges itself is the zero change CI smoke test.

**Q: We don't use Jira, Azure DevOps or GitHub Issues. Can we still use AIRE?**
A: Yes. Choose **LOCAL** at the tracker question. The Story Tracker in `runtime-artifacts/aire-state.md`
becomes the record and nothing is sent to an external tracker. Pull requests still go through GitHub.

**Q: Is it mandatory to always set up the CI?**
A: No. Answering `no` skips every CI file; every local eval still runs in full. With CI
on, CI re-checks the local results in a clean environment.

**Q: Do we have to produce UI mockups?**
A: No. The UI/UX mockups stage is optional and is offered at Requirements Analysis. If you already have
wireframes or designs, place them in `spec/context-project/new-references/` and the framework builds
from them.

**Q: A story keeps failing the same eval. What do I do?**
A: After three attempts the run stops with a report of what failed and how to fix it. Fix it by hand and
type the same keyword again. If a tool cannot be installed on your machine, the report tells you how to
install it yourself.

**Q: An approved acceptance criterion turns out to be wrong. Can I just edit the `.feature` file?**
A: No — `dev-implement` treats it as a contract. Use `epic-change-request` if the requirement changed, or
`epic-enhance` if it's a small enhancement. Both amend the specs and test plans properly and keep the history.

---
