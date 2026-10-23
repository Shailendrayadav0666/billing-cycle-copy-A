# aire State Tracking

## Project Information
- **Project Type**: Brownfield
- **Start Date**: 2026-10-23T07:53:23Z
- **Current Stage**: PLANNING - User Stories
- **Workflow Type**: epic
- **AIRE Framework Version**: 1.0

## Tracker
- Type: LOCAL
- Parent Epic: HELIX-6852 — Self-Serve Premium Upgrade (Atlas document 6852, sourced via Helix MCP)
- Epic URL: —
- Project Key / Repo / Org: —

## Workspace State
- **Existing Code**: Yes
- **Programming Languages**: Python (FastAPI backend), JavaScript/JSX (React 19 frontend)
- **Build System**: pip (requirements.txt) for backend; npm + Vite 8 for frontend
- **Project Structure**: Monolith (single-file FastAPI backend + React SPA)
- **Reverse Engineering Needed**: No (Atlas deep dive pulled)
- **Reverse Engineering Artifacts**: spec/plans/atlas-deep-dive.md
- **Workspace Root**: C:\Users\shailendra.yadav\Desktop\projects\billing cycle copy-A\billing-cycle-copy

## Code Location Rules
- **Application Code**: src/ (already the code root — no `## Code Root` override needed)
- **Documentation**: spec/ only
- **Structure patterns**: See code-generation.md Critical Rules

## Helix MCP Binding
- **Server**: helix
- **Docs tool(s)**: list_solution_documents_tool, get_solution_document_tool — list and fetch Atlas solution documents (Epic, Story, Deep Dive)
- **Graph/Search tool(s)**: codebase_agent_query, codebase_cypher_query, document_chatbot_query — targeted inline answers about the indexed codebase/docs
- **Estate / workspace id**: solution 951 "Billing-Cycle-Helix-Workshop" (repo Billing-Cycle, main @ 69f67f308492a85648aa25a9ff7d8d574031344a)
- **Resolved**: 2026-10-23T07:54:25Z

## Existing-System Context
- **Workspace type**: brownfield
- **Helix MCP**: connected
- **Source**: atlas
- **Components in scope**: src/backend/main.py, src/frontend/src/pages/Billing.jsx, src/frontend/src/context/AuthContext.jsx, src/frontend/src/App.css
- **Atlas deep dive doc**: spec/plans/atlas-deep-dive.md
- **Recorded**: 2026-10-23T07:54:25Z

## Atlas Artifact Sync
- Enabled: No
- Source: user opt-out

## Context Project
- **Existing Knowledge**: No
- **Existing Knowledge Path(s)**: —
- **New References**: No
- **New Reference Path(s)**: —

## Design References
| Reference | Type | Path | Read? | Read At Stage |
|---|---|---|---|---|
| (none registered) | — | — | — | — |

## Extension Configuration
| Extension | Enabled | Decided At |
|---|---|---|
| Security Baseline | Yes (always enforced) | Workflow start |
| UI/UX Mockups | No | Requirements Analysis |
| Resiliency Baseline | No | Requirements Analysis |
| Property-Based Testing | No | Requirements Analysis |
| Playwright Test Automation | Standalone only (/playwright-implement) | — |

## UI/UX Design
- **Mode**: skip
- **Provided design path(s)**: —
- **Decided At**: Requirements Analysis

## Branching
- Base Branch: main
- Epic Branch: epic/6852-self-serve-premium-upgrade
- Epic PR: (not raised — raised manually at cycle end via pr-generator)

## Stage Progress
- [x] Workspace Detection — state check, tracker selection (LOCAL), Epic + Deep Dive pulled from Atlas, epic branch created
- [x] Workspace Detection — Atlas Artifact Sync opt-in (No), Context opt-in (No/No)
- [-] Reverse Engineering — SKIPPED (Atlas deep dive found and pulled)
- [x] Requirements Analysis — Standard depth; spec/plans/requirements.md v1 approved (16 REQ-F, 7 REQ-NF)
- [ ] User Stories
- [ ] Dependency Graph
- [ ] Workflow Planning
- [ ] Application Design
