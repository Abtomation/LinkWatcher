---
id: PF-STA-086
type: Document
category: General
version: 1.0
created: 2026-04-12
updated: 2026-04-12
change_name: infrastructure-doc-consolidation
---

# Structure Change State: Infrastructure Doc Consolidation

> **⚠️ TEMPORARY FILE**: This file tracks implementation of a content update structure change. Move to `process-framework-local/state-tracking/temporary/old` after all changes are validated.

## Structure Change Overview
- **Change Name**: Infrastructure Doc Consolidation
- **Change ID**: PF-PRO-021
- **Proposal**: [Structure Change Proposal](../../../proposals/structure-change-infrastructure-doc-consolidation-proposal.md)
- **Change Type**: Content Update
- **Scope**: Merge traceability into registry, add Mermaid diagrams, slim transition guide
- **Expected Completion**: 2026-04-26

## Content Changes

### Change Description
Consolidate 3 overlapping infrastructure docs into 2 + Mermaid diagrams:
1. Merge task-trigger-output-traceability.md into process-framework-task-registry.md
2. Add validated Mermaid trigger chain diagrams to Registry
3. Slim task-transition-guide.md by removing duplicated workflow sequences (~750 lines)
4. Relocate 3 unique items from removed sections to kept sections before trimming

### Affected Files

| File | Change Required | Priority | Status |
|------|----------------|----------|--------|
| `infrastructure/process-framework-task-registry.md` | Add trigger/output fields per task, State File Trigger Index, Framework Gaps, Mermaid diagrams | HIGH | PENDING |
| `guides/framework/task-transition-guide.md` | Relocate 3 items, remove ~750 lines of duplicated content | HIGH | PENDING |
| `infrastructure/task-trigger-output-traceability.md` | Replace with tombstone redirect | HIGH | PENDING |
| `infrastructure/trigger-chain-diagram-draft.md` | Delete after content integrated into Registry | LOW | PENDING |
| `tasks/support/new-task-creation-process.md` | Update 3 traceability doc references to Registry | MEDIUM | PENDING |
| `tasks/support/framework-extension-task.md` | Update 2 traceability doc references to Registry | MEDIUM | PENDING |
| `tasks/support/framework-evaluation.md` | Update 1 traceability doc reference to Registry | MEDIUM | PENDING |
| `tasks/support/structure-change-task.md` | Update 1 traceability doc reference to Registry | MEDIUM | PENDING |
| `tasks/03-testing/performance-and-e2e-test-scoping-task.md` | Update 1 traceability doc reference to Registry | MEDIUM | PENDING |
| `PF-documentation-map.md` | Update index entry for traceability doc | MEDIUM | PENDING |

## Implementation Roadmap

### Phase 1: Enhance Registry (Session 2)
- [x] **Analysis and proposal** — scope assessment, content audit, no-loss validation
  - **Status**: COMPLETED
- [x] **Add trigger/output fields** to all 50 task entries in Registry
  - **Status**: COMPLETED — `🔗 TRIGGER & OUTPUT` blocks added with Self-Doc, Trigger, Output
- [x] **Add State File Trigger Index** section (verbatim from traceability)
  - **Status**: COMPLETED
- [x] **Framework Gaps** — registered as PF-IMP-499 through PF-IMP-506 in process-improvement-tracking (not added to Registry per human partner decision)
  - **Status**: COMPLETED (redirected to IMP items)
- [x] **Add Trigger Chain Diagrams** section (from validated draft, 6 diagrams + legend)
  - **Status**: COMPLETED
- [x] **Remove "Enables next steps"** prose lines (50 lines removed, replaced by Output Status fields)
  - **Status**: COMPLETED
- [x] **Checkpoint**: Present enhanced Registry to human partner
  - **Status**: COMPLETED — approved with Framework Gaps redirect to IMP items

### Phase 2: Slim Transition Guide (Session 3)
- [x] **Relocate 3 items** to their target sections in the kept content
  - **Status**: COMPLETED — Optional Task Guidelines → FROM Feature Tier Assessment; Decomposed Mode guidance → FROM TDD Creation; 4-outcome audit tree → FROM Test Audit
- [x] **Remove Core Transition Patterns** (622 lines removed)
  - **Status**: COMPLETED
- [x] **Remove Common Transition Scenarios** (182 lines removed)
  - **Status**: COMPLETED
- [x] **Checkpoint**: Present slimmed Transition Guide to human partner
  - **Status**: COMPLETED — approved

### Phase 3: Redirect and Update References (Session 2)
- [x] **Replace traceability doc** with tombstone redirect
  - **Status**: COMPLETED — PF-INF-002 now contains redirect to Registry
- [x] **Update 6 referencing files** with new links to Registry
  - **Status**: COMPLETED — structure-change-task, new-task-creation-process (5 refs), framework-extension-task (2 refs), framework-evaluation, performance-and-e2e-test-scoping-task
- [x] **Update PF-documentation-map.md**
  - **Status**: COMPLETED — Registry description enhanced, traceability entry struck through with tombstone link
- [x] **Delete trigger-chain-diagram-draft.md**
  - **Status**: COMPLETED

### Phase 4: Validation (Session 2)
- [x] **Run Validate-StateTracking.ps1** — warnings are all pre-existing (feature state file links, ID gaps, Surface 6 path error)
  - **Status**: COMPLETED — no new errors from our changes
- [x] **Grep for orphaned traceability references** — 0 active references remain (6 hits are tombstone, our own state/proposal, and historical docs)
  - **Status**: COMPLETED
- [x] **Verify Mermaid diagrams render** in VS Code preview
  - **Status**: COMPLETED — verified by human partner
- [x] **Spot-check 5 tasks** — trigger/output data correct in Registry
  - **Status**: COMPLETED — verified by human partner

## Session Tracking

### Session 1: 2026-04-12
**Focus**: Analysis, proposal, start Phase 1
**Completed**:
- Content audit of all 3 documents
- No-loss validation with section-by-section mapping
- Mermaid diagram draft created and validated (6 diagrams)
- Structure change proposal (PF-PRO-021)
- State tracking file (PF-STA-086)

**Issues/Blockers**:
- Registry is large (35k tokens) — Phase 1 edits must be done carefully to avoid context exhaustion

**Next Session Plan**:
- Phase 1 execution: Add trigger/output fields to 50 task entries in Registry
- Add State File Trigger Index, Framework Gaps, and Mermaid diagrams sections to Registry
- Remove "Enables next steps" lines
- Checkpoint with human partner after Registry is enhanced

### Session 2: 2026-04-12
**Focus**: Phase 1 execution, Phase 3 (redirect + references), Phase 4 (validation)
**Completed**:
- Added `🔗 TRIGGER & OUTPUT` blocks to all 50 task entries (Self-Doc, Trigger, Output)
- Removed all 50 "Enables next steps" prose lines
- Added State File Trigger Index section (24-row table)
- Added Trigger Chain Diagrams section (6 Mermaid diagrams + legend)
- Framework Gaps registered as PF-IMP-499–506 in process-improvement-tracking (per human partner: gaps belong there, not in Registry)
- Replaced traceability doc with tombstone redirect
- Updated all 6 referencing task files + PF-documentation-map
- Deleted trigger-chain-diagram-draft.md
- Ran Validate-StateTracking (no new errors), grepped for orphaned refs (clean)
- Registry grew from 1,624 → ~2,150 lines

**Decisions**:
- Phase 2 (Slim Transition Guide) deferred — human partner chose to skip this session
- Framework Gaps NOT added to Registry — registered as IMP items instead

**Issues/Blockers**:
- None

**Next Session Plan**:
- Phase 2 (if desired): Relocate 3 items in Transition Guide, remove ~750 lines
- Human partner: verify Mermaid diagrams render in VS Code, spot-check 5 task trigger/output entries
- Feedback form

### Session 3: 2026-04-12
**Focus**: Phase 2 execution (Slim Transition Guide)
**Completed**:
- Relocated 3 items from removed sections to kept sections in Detailed Transition Procedures
- Removed Core Transition Patterns section (622 lines)
- Removed Common Transition Scenarios section (182 lines)
- Guide slimmed from 2,485 → 1,681 lines (804 lines removed, ~32% reduction)
- Human partner approved checkpoint

**Decisions**:
- None — executed per approved proposal

**Issues/Blockers**:
- None

**Next Session Plan**:
- Human partner: verify Mermaid diagrams render in VS Code, spot-check 5 task trigger/output entries
- Feedback form
- Archive state file

## State File Updates Required

- [x] **PF-documentation-map.md**: Registry description enhanced, traceability entry struck through
  - **Status**: COMPLETED
- [x] **Process Improvement Tracking**: 8 framework gap items registered (PF-IMP-499–506)
  - **Status**: COMPLETED

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [x] All traceability content migrated to Registry
- [x] Transition Guide slimmed with 3 items relocated
- [x] Traceability doc replaced with tombstone
- [x] All 6 referencing files updated
- [x] Validation passes (Validate-StateTracking, grep)
- [x] Mermaid render verified by human partner
- [x] Feedback form completed (PF-FEE-897)
