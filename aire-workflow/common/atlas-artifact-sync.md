# Atlas Artifact Sync — Mirror a Cycle's Artifacts to Atlas (opt-in)

**Purpose**: when the user opts in, every artifact the framework writes under `spec/`,
`runtime-artifacts/` and `reports/` is mirrored to Atlas through the Helix MCP, into one team-visible
folder per cycle that keeps the local folder structure. Application code and tests are never synced.
With the opt-out (the default when nothing is recorded), the framework behaves exactly as it does
without this file.

**Who loads it**: CLAUDE.md "Atlas Artifact Sync". Loaded right after the cycle branch is created
(Section 2), and on any later session start, resume or keyword run where `## Atlas Artifact Sync`
records `Enabled: Yes`.

---

## 1. Scope — what is synced, and what never is

| Synced | Never synced |
|---|---|
| Every text file staged under `spec/` (plans, spec-generation, behavior, test-plans, playwright-specs, `behavior.feature`), including the UI/UX mockup HTML in `spec/plans/ui-ux/` | `spec/context-project/**`: human-authored inputs, not framework artifacts |
| Every text file staged under `runtime-artifacts/` (`audit.md`, `aire-state.md`, `stories/<unit-key>/*`) | `src/`, the Code Root, `tests/**`, `tests/.evals/**`, `.github/**`, `aire-archives/**` |
| Every text file staged under `reports/` (all evidence, reviews, security reviews, ticket summaries, PR feedback) | Binary and non-text files (see Section 5) |

🔴 **Mirror, never delete.** A file deleted or renamed locally keeps its Atlas copy. In particular, the
`archive-epic` removal of the live trees never touches Atlas. The Atlas folder is the cycle's record.

🔴 **This is a separate write path from the deep-dive stitch.** It only creates and replaces documents
inside this cycle's own Atlas folder. It never edits the Atlas deep dive or any document outside the
cycle folder. A mirrored copy of `spec/plans/atlas-deep-dive.md` is a new document in the cycle folder,
never the source deep dive (`common/helix-atlas-integration.md` Section 5.3).

---

## 2. The opt-in question (CHAT-ONLY, asked once per cycle, right after the cycle branch is created)

**Where it runs**: immediately after the cycle branch is recorded in `## Branching`:
- epic: `planning/workspace-detection.md` Step 4.5
- bug: `workflows/bug-fix.md` Step 2
- enhancement: `workflows/enhancement-implement.md` Step 2

The mid-epic workflows (`epic-enhance`, `epic-bugfix`, `epic-change-request`) and every work unit
inherit the epic's answer. They never ask.

**Skip** if `runtime-artifacts/aire-state.md` already has `## Atlas Artifact Sync` (resumed cycle). Reuse
it and never re-ask.

Ask exactly this, in chat, as plain text. Never put it in a question file or turn it into a lettered menu:

```
Push the artifacts this cycle creates (spec/, runtime-artifacts/, reports/ — never code) to Atlas
through the Helix MCP? (yes/no)
```

- **no** (or anything that is not yes): record `Enabled: No`, `Source: user opt-out`. Nothing else in
  this file applies.
- **yes**: resolve the provider (Section 3), create the cycle folder (Section 4), then record
  `Enabled: Yes`.

Log the question and the complete raw answer in `runtime-artifacts/audit.md`.

---

## 3. Resolve the Helix provider

Reuse `## Helix MCP Binding` when it exists. Otherwise run `common/helix-atlas-integration.md`
Section 3 discovery now. Greenfield cycles skip the Helix gate, so the binding may not exist yet.

The sync needs a **docs-write** capability, which must be confirmed from the tool descriptions, never
from assumed names:
1. create a document with a title, a Markdown body, a parent document and team visibility;
2. fully replace an existing document's body by its id.

Record it as one extra line in `## Helix MCP Binding`:

```markdown
- **Docs write tool(s)**: <tool name(s)> — create (parent + team visibility) / replace by id
```

**No provider, or no docs-write capability**:
- Record `Enabled: No`, `Source: Helix MCP not connected — <what was missing>`.
- Tell the user in one line that the artifacts will stay local for this cycle.
- Continue.

This never halts the cycle. Sync is an addition, never a dependency.

---

## 4. The cycle folder in Atlas

Atlas has no folders. A **folder is a document whose children are nested under it** through the
parent-document field. Every folder and file document is created with **team visibility**. After each
create, read the returned visibility. If it came back private, report it once and carry on.

**Root name**: the cycle branch name without its prefix, which is unique per cycle:
- `epic/PROJ-42-checkout-revamp` → `PROJ-42-checkout-revamp`
- `bug/PROJ-123-login-timeout` → `PROJ-123-login-timeout`

**Created once, at opt-in.** The fixed skeleton is created up front, so parallel work units never race to
create the same shared folder:

```
<cycle-root>/
  spec/
    plans/   spec-generation/   behavior/   test-plans/   playwright-specs/
  runtime-artifacts/
    stories/
  reports/
    unit-test-evidence/   behavior-test-evidence/   api-contract-test-evidence/
    playwright-test-evidence/   eval-evidence/   reviews/   code-security-reviews/
    ticket-summary/   pr-feedback/
```

Any deeper folder (`reports/eval-evidence/story-1.2/`, `.../static/baseline/`, `spec/test-plans/<ID>-<title>/`,
`runtime-artifacts/stories/story-1.2/`) is created **when its first file is synced**. That folder
belongs to one work unit, so only one writer ever creates it.

**Folder document body** (the Atlas Markdown save contract requires `## Referenced Paths` as the last
section):

```markdown
# <folder-name>

AIRE artifact folder — mirrors `<local/path/>` for cycle <cycle-root>.

## Referenced Paths
- High: `<local/path/>`
```

**State** — written to `runtime-artifacts/aire-state.md`:

```markdown
## Atlas Artifact Sync
- Enabled: Yes
- Source: user opt-in
- Cycle Folder: PROJ-42-checkout-revamp (doc 4812)
- Decided At: <ISO 8601 timestamp>

### Synced Files
| Path | Doc ID | Synced At |
|------|--------|-----------|
| spec/ | 4813 | <ts> |
| spec/plans/ | 4814 | <ts> |

### Pending
| Path | Reason |
|------|--------|
```

Folders are rows ending in `/`. **Work-unit writers** (`common/parallel-work-state.md`) never write the
shared file. They keep their own `### Synced Files` and `### Pending` rows under `## Atlas Artifact Sync`
in their fragment `runtime-artifacts/stories/<unit-key>/state.md`. Readers use the resolved view: the
union of the shared rows and every fragment's rows.

---

## 5. The sync pass (runs before every commit while `Enabled: Yes`)

**Trigger**: CLAUDE.md "Atlas Artifact Sync". Any workflow, agent or skill that is about to `git commit`
runs this pass first, after it has staged its files.

1. **File set**. Use one command, with no extra scans:
   ```bash
   git diff --cached --name-status -- spec runtime-artifacts reports
   ```
   Keep the `A`, `M` and `R` (new-path) entries, plus every row still in `### Pending`. Drop `D`
   entries, which are never deleted in Atlas (Section 1). Drop `spec/context-project/**`.
2. **Text only**. Sync these extensions: `.md .feature .json .yml .yaml .log .txt .xml .csv`, plus
   `.html` under `spec/plans/ui-ux/` only (the UI/UX mockups; HTML anywhere else, such as coverage
   reports under `reports/`, is not synced). Anything else is skipped and named once in the pass's
   audit entry. It is not retried.
3. **Order**. Sync every other file first. Sync the state file (`aire-state.md`, or the fragment
   `state.md`) and the audit file last, so they carry this pass's map and log entry.
4. **Per file**:
   1. Resolve the parent folder from the Synced Files map (resolved view). If a deeper folder is
      missing, create it (Section 4) and record it.
   2. Build the body:
      - **`.md`**: the file content as-is. Append `## Referenced Paths` with
        ``- High: `<path>` `` unless the file already ends with that section.
      - **Any other text file**: one fenced code block holding the content, tagged with the extension's
        language (`gherkin`, `json`, `yaml`, `text`, `xml`, `csv`, `html`), then the same `## Referenced Paths`
        section.
      - The title is the **file name**, so the folder chain carries the path, exactly as on disk.
   3. **Path in the map**: replace that document's body by its id.
      **Path not in the map**: create it under the parent, with team visibility and artifact type
      `report` for `reports/**` and `documentation` for everything else.
   4. Record or refresh the map row with the real clock (`common/audit-logging.md`).
5. **Failure**: a refused or failed call puts the path in `### Pending` with the reason. The pass
   continues, and the commit proceeds. Pending rows are retried at the next pass.
   🔴 A sync failure never blocks a gate, a commit, a push or a PR.
6. **Stage the state update into the same commit**. Stage the state file the pass changed (the shared
   `aire-state.md` for integration-branch writers, the fragment for work-unit writers) with the files
   being committed.
   - The doc-id map therefore always travels with the artifacts. A later writer on any branch replaces
     the same documents instead of duplicating them.
   - A newly created state document records its own id only from the next pass. This is expected.
7. **Audit**. Add one entry `## Atlas Artifact Sync — <writer> pass` with these fields:
   - synced (created / replaced) counts
   - skipped names
   - pending names
   - the Cycle Folder

---

## 6. Cycle close (`archive-epic`)

`archive-epic` Step 4 rewrites the live `aire-state.md` and `audit.md` (the fold-back) after the last
commit, and Step 6 removes the live trees. So the agent runs **one final pass at Step 4.7**, with this
file set instead of the staged one:

```bash
git diff --name-status HEAD -- spec runtime-artifacts reports
```

That pass sends the folded state and audit, so the Atlas folder ends with the cycle's final record. Its
map update lands in the shared `aire-state.md` before the Step 5 copy, so it is archived with
everything else.

The Atlas cycle folder is never removed or archived by the framework.
