---
name: playwright-implement
description: >
  Turns a story's already-Approved manual Test Plan plan into executable Playwright UI
  automation by orchestrating Playwright's OWN official Test Agents (Planner, Generator, Healer --
  installed once per repo via `npx playwright init-agents --loop=claude` as real Claude Code
  subagents backed by the playwright-test MCP server). Never re-implements those agents' own logic.
  Flow: Prerequisite Gate (Playwright + its agents installed, local frontend server up, fixture data
  seeded) -> Seed Test Gate (derive/confirm tests/e2e/seed.spec.ts with the user before the Planner runs)
  -> invoke the real Planner agent, scoped strictly to this story's UI-relevant manual test cases ->
  a mandatory user Approval Gate on the Planner's own plan output (spec/playwright-specs/<story-slug>.md) -> invoke
  the real Generator agent per scenario (writes tests/e2e/<story-slug>/*.spec.ts) -> local execution via
  `npx playwright test tests/e2e/<story-slug>/ --headed` -> invoke the real Healer agent on any failure
  (its own loop, never shortcut; a test.fixme() outcome is a candidate product defect signal, routed
  to raise-defect) -> a confirm-first Push Gate, then commits and pushes directly to the integration
  branch (epic/bug/enhancement) -- no branch of its own, no PR; the Push Gate is this skill's only
  review checkpoint before that branch changes. Standalone, it runs only once the dev's work and the
  story's test plan are both on that branch (and any open /ve-implement rework PR has merged), so its
  Planner/Generator have the real code and the manual test docs to work from. UI/browser only -- Playwright's shipped agents carry no API/request-fixture
  tooling, so backend/API manual test cases stay manual-only, always. Additive only -- never modifies
  /ve-implement's manual, black-box test steps, and never touches Story Tracker or tracker status.
  STANDALONE ONLY: the Playwright Test Automation extension is optional and is never run by
  dev-implement / bug-fix-implement / enhancement-implement — those workflows run no Playwright
  automation. The Verification Engineer types /playwright-implement, post-merge, and everything above
  applies as written (prerequisites gate, Approval Gate, Push Gate). Execution is --headed — it is the
  Verification Engineer's own machine, and headless belongs to CI alone, where a runner has no display.
when_to_use: >
  Trigger when the user says: "/playwright-implement 1.2", "/playwright-implement AT-898",
  "/playwright-implement", "automate this story's tests", "generate playwright scripts for story 1.2",
  "turn the Test Plan plan into automation", "playwright automation for AT-898",
  "run playwright tests for this story", "playwright-implement".
allowed-tools: Read Grep Glob Bash Write Edit Agent
---

# Playwright Implement — orchestrates Playwright's own Planner/Generator/Healer for ONE story

Load and execute the agent instructions from:

```
aire-workflow/agents/playwright-implement-agent.md
```

That file in turn loads and executes:

```
aire-workflow/extensions/testing/playwright-automation/playwright-automation.md
```

Read both completely and follow every step defined in them, in order.

🔴 **Standalone only** (`playwright-implement-agent.md` → **Mode — STANDALONE ONLY**): never skip the
Prerequisite Gate (Step 0), the both-merges gate (Step 2a), the Approval Gate (Step 2/7) or the Push
Gate (Step 12). If invoked with `mode: workflow` or from inside an implement workflow, refuse and
stop — implement workflows run no Playwright automation.
