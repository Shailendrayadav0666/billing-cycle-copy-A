# UI/UX Mockups — Opt-In

**Extension**: UI/UX Mockups

## Opt-In Prompt

The following question is automatically included in the Requirements Analysis clarifying questions
when this extension is loaded. Include exactly ONE of the two variants below, chosen when the questions
file is written:

- **Variant 1**: no design has been provided yet. `## Context Project` records `New References: No`,
  and `## Design References` has no row of Type `UI prototype` or `mockup or screenshot`.
- **Variant 2**: designs were already provided, at the Context question or anywhere earlier.
  Substitute `[path]` with the recorded path(s).

### Variant 1

```markdown
## Question: UI/UX Mockups
Once the design stages are complete, should HTML mockups of the user interface be produced for your review before development begins?

A) Yes, produce HTML mockups for review

B) No, designs already exist. Place them in spec/context-project/new-references/ and enter the path after [Answer]:

C) No, skip this step

X) Other (please describe after [Answer]: tag below)

[Answer]: 
```

### Variant 2

```markdown
## Question: UI/UX Mockups
The designs provided at [path] will be used as the reference for development. Should HTML mockups also be produced for any screens those designs do not cover?

A) No, use the provided designs only

B) Yes, produce HTML mockups for the screens not covered

X) Other (please describe after [Answer]: tag below)

[Answer]: 
```

## Recording the answer

| Variant | Answer | `## Extension Configuration` | `## UI/UX Design` Mode |
|---|---|---|---|
| 1 | A | `UI/UX Mockups` = Yes | `generate` |
| 1 | B (with a path) | `UI/UX Mockups` = Yes | `provided` |
| 1 | C | `UI/UX Mockups` = No | `skip` |
| 2 | A | `UI/UX Mockups` = Yes | `provided` |
| 2 | B | `UI/UX Mockups` = Yes | `provided+generate` |

- A Variant 1 **B** answer without a path, or with a path that does not exist, is incomplete: say so
  and ask for the path again, as a follow-up in the clarification file.
- A path given in the answer is a design reference. Register it and read it immediately, per
  `common/design-reference-grounding.md` DR-1 and DR-2.
- 🔴 **When no `UI/UX Mockups` row exists** (for example a cycle resumed from before this extension
  existed), treat it as **No**. This extension is never run by default.

Write the section in `runtime-artifacts/aire-state.md`:

```markdown
## UI/UX Design
- **Mode**: [generate | provided | provided+generate | skip]
- **Provided design path(s)**: [exact path(s) — or —]
- **Decided At**: Requirements Analysis
```
