---
id: PF-PRO-021
type: Document
category: General
version: 1.0
created: 2026-04-12
updated: 2026-04-12
---

# Structure Change Proposal Template

## Overview
Merge task-trigger-output-traceability into process-framework-task-registry, add Mermaid trigger chain diagrams, slim task-transition-guide by removing duplicated workflow sequences

**Structure Change ID:** SC-PENDING
**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-04-12
**Target Implementation Date:** 2026-04-12

## Current Structure

Three separate infrastructure/guide documents with overlapping content:

1. **Task Trigger & Output Traceability** (`process-framework/infrastructure/task-trigger-output-traceability.md`, PF-INF-002) — 189 lines. Maps every task to trigger status and output status. Contains Trigger Chain Table, State File Trigger Index, and Framework Gaps sections.

2. **Process Framework Task Registry** (`process-framework/infrastructure/process-framework-task-registry.md`, PF-INF-001) — ~1300 lines. Per-task automation catalog with scripts, file operations, key impacts. Contains 50 "Enables next steps" lines that duplicate traceability data.

3. **Task Transition Guide** (`process-framework/infrastructure/task-transition-registry.md`, PF-GDE-018) — 2450 lines. Workflow sequencing, information ownership, transition checklists, cross-reference standards. ~800 lines duplicate workflow sequences from ai-tasks.md and traceability doc.

**Problem**: "Which task runs next and why?" is answered in 4 places (these 3 + ai-tasks.md Common Workflows), each incomplete, creating maintenance burden and drift risk. Every new task requires updating all 3 documents.

## Proposed Structure

Two documents + Mermaid diagrams:

1. **Process Framework Task Registry** (enhanced) — absorbs traceability content:
   - Each task entry gains 3 new fields: Self-Doc, Trigger (state file + status), Output Status
   - New section: "State File Trigger Index" (moved verbatim from traceability)
   - New section: "Framework Gaps" (moved verbatim from traceability)
   - New section: "Trigger Chain Diagrams" (Mermaid diagrams from draft)
   - Remove 50 "Enables next steps" prose lines (replaced by structured Output Status fields)

2. **Task Transition Guide** (slimmed from 2450 → ~1700 lines):
   - **KEEP**: Information Flow and Separation of Concerns (lines 29-507)
   - **KEEP**: Detailed Transition Procedures (lines 1130-2170)
   - **KEEP**: Troubleshooting (lines 2370-2450)
   - **REMOVE**: Core Transition Patterns workflow diagrams (lines 508-1130) — after relocating 3 items
   - **REMOVE**: Quick Reference Scenarios (lines 2186-2370) — derivative of ai-tasks.md

3. **Traceability doc** → tombstone redirect to Registry

**Relocations before trimming** (3 items from removed section → kept sections):

| Content | From | To |
|---|---|---|
| Optional Task Guidelines (✅/❌ for Arch Review, API, DB, UI) | Lines 575-588 | "Transitioning FROM Feature Tier Assessment" (line 1295) |
| When to Use Decomposed Mode guidance | Lines 605-619 | "Transitioning FROM TDD Creation" (line 1357) |
| Test Audit 4-outcome decision tree | Lines 834-841 | "Transitioning FROM Test Audit" (line 1628) |

## Rationale

### Benefits
- One fewer document to maintain when creating new tasks (2 instead of 3)
- Registry becomes the single "tell me everything about task X" reference
- State File Trigger Index gets more visibility inside the most-referenced document
- Mermaid diagrams provide visual gap detection (user-validated)
- Transition Guide becomes focused on its unique value (ownership, checklists, anti-patterns)

### Challenges
- Registry grows by ~170 lines (manageable in a ~1300-line document)
- Migration requires careful content transfer for 50 task entries
- 6 active files reference the traceability doc and need link updates

## Affected Files

### Primary Documents (content changes)
- `process-framework/infrastructure/process-framework-task-registry.md` — add trigger/output fields, new sections, diagrams
- `process-framework/infrastructure/task-transition-registry.md` — relocate 3 items, remove ~750 lines
- `process-framework/infrastructure/task-trigger-output-traceability.md` — replace with tombstone redirect

### Reference Updates (link changes to traceability doc)
- `process-framework/tasks/support/new-task-creation-process.md` — update 3 references
- `process-framework/tasks/support/framework-extension-task.md` — update 2 references
- `process-framework/tasks/support/framework-evaluation.md` — update 1 reference
- `process-framework/tasks/support/structure-change-task.md` — update 1 reference
- `process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md` — update 1 reference
- `process-framework/PF-documentation-map.md` — update index entry

### Draft File (to be moved)
- `process-framework/infrastructure/trigger-chain-diagram-draft.md` — diagrams integrate into Registry

## Migration Strategy

### Phase 1: Enhance the Registry
- Add Self-Doc, Trigger, and Output Status fields to each of the 50 task entries
- Remove "Enables next steps" prose lines (replaced by Output Status)
- Add "State File Trigger Index" section (verbatim from traceability)
- Add "Framework Gaps" section (verbatim from traceability)
- Add "Trigger Chain Diagrams" section (from validated draft)

### Phase 2: Slim the Transition Guide
- Relocate the 3 identified items to their target sections
- Remove Core Transition Patterns (lines 508-1130)
- Remove Quick Reference Scenarios (lines 2186-2370)

### Phase 3: Redirect and Update References
- Replace traceability doc content with tombstone redirect
- Update 6 active files with new references to Registry
- Update PF-documentation-map.md
- Delete trigger-chain-diagram-draft.md (content now in Registry)

### Phase 4: Validation
- Run Validate-StateTracking.ps1 — 0 errors
- Grep for orphaned references to old traceability doc
- Verify all Mermaid diagrams render in VS Code preview

## Testing Approach

### Success Criteria
- All traceability data findable in Registry (spot-check 5 random tasks)
- State File Trigger Index present and correct in Registry
- Framework Gaps section present and correct in Registry
- All 6 Mermaid diagrams render correctly
- No broken links (LinkWatcher + manual grep)
- Transition Guide retains all unique content (information ownership, transition checklists, troubleshooting)
- Validate-StateTracking.ps1 passes with 0 errors

## Rollback Plan

### Trigger Conditions
- Registry becomes unmanageably large or unreadable after merge
- Critical content discovered missing after trimming

### Rollback Steps
1. Git history preserves all original files — revert specific commits
2. No destructive operations; all changes are additive (new fields) or subtractive (removed sections) with git safety net

## Approval

**Approved By:** _________________
**Date:** 2026-04-12

**Comments:**
