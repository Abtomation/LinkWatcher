---
id: PF-STA-085
type: Process Framework
category: Temporary State
version: 1.0
created: 2026-04-12
updated: 2026-04-12
task_name: performance-and-e2e-test-scoping-workflow
---

# Temporary Framework Extension State: Performance and E2E Test Scoping Workflow

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of a framework extension (PF-TSK-048). Move to `process-framework-local/state-tracking/temporary/old` after all phases are complete.

## Extension Overview

- **Extension Name**: Performance and E2E Test Scoping Workflow
- **Source Concept**: [PF-PRO-020](/process-framework-local/proposals/old/performance-and-e2e-test-scoping-workflow.md)
- **Source IMP(s)**: PF-IMP-492 (primary), PF-IMP-493 (cleanup)
- **Source Evaluation**: [PF-EVR-014](/process-framework-local/evaluation-reports/20260412-framework-evaluation-performance-testing-workflow-trigger-mechanism-for.md)
- **Scope**: One new task + one new status (`🔎 Needs Test Scoping`) + decision matrix migration + modifications to ~9 existing files
- **Estimated Sessions**: 2

## Artifact Tracking

| Artifact | Type | Location | Creator Task | Updater Task(s) | Status |
|----------|------|----------|-------------|-----------------|--------|
| Performance & E2E Test Scoping task (PF-TSK-086) | Task Def | process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md | PF-TSK-048 (via New-Task.ps1) | PF-TSK-009 | COMPLETED |
| Performance & E2E Test Scoping Guide (PF-GDE-061) | Guide | process-framework/guides/03-testing/performance-and-e2e-test-scoping-guide.md | PF-TSK-048 (via New-Guide.ps1) | PF-TSK-009 | COMPLETED |
| Performance & E2E Test Scoping Map (PF-VIS-054) | Context Map | process-framework/visualization/context-maps/03-testing/performance-e2e-test-scoping-map.md | PF-TSK-048 | PF-TSK-009 | COMPLETED |

**Status Legend**: NOT_STARTED | IN_PROGRESS | COMPLETED | DEFERRED

## Task Impact

Existing tasks/files affected by this extension:

| Task/File | ID | Change Required | Priority | Status |
|-----------|----|----|----------|--------|
| Code Review | PF-TSK-005 | Output status `🟢 Completed` → `🔎 Needs Test Scoping`; update Next Tasks | HIGH | COMPLETED |
| feature-tracking.md | PD-STA-001 | Add `🔎 Needs Test Scoping` to Status Legends; migrate 7 Completed features; update Progress Summary | HIGH | COMPLETED |
| Performance Testing Guide | PF-GDE-060 | Remove decision matrix section (migrated to new guide); update overview + "When to Use" + Related Tasks | HIGH | COMPLETED |
| Integration and Testing | PF-TSK-053 | Update orphaned PF-TSK-084 reference (line 84) to reference new scoping task | LOW | COMPLETED |
| Update-BatchFeatureStatus.ps1 | — | Add `🔎 Needs Test Scoping` to ValidateSet (line 98) | MEDIUM | COMPLETED |
| ai-tasks.md | — | Add new task to 03-Testing table; update 8 workflow diagrams | HIGH | COMPLETED |
| Task Transition Guide | PF-GDE-011 | Update FROM Code Review; add FROM Needs Test Scoping; update Standard Code QA Path | HIGH | COMPLETED |
| Task Trigger & Output Traceability | PF-INF-002 | Add new task row; update PF-TSK-005 output; add status trigger; resolve gap | MEDIUM | COMPLETED |
| Process Framework Task Registry | — | Register new task | MEDIUM | COMPLETED |
| PF-documentation-map.md | — | Add task, guide, context map entries | MEDIUM | COMPLETED |
| test-specification-creation-guide.md | PF-GDE-040 | Update decision matrix reference to point to new scoping guide | LOW | COMPLETED |

## Implementation Roadmap

### Phase 1: Concept & Approval ✅

**Priority**: HIGH — Must complete before implementation begins

- [x] **Pre-concept analysis**: Study existing patterns, trace lifecycle, establish abstraction model
  - **Status**: COMPLETED
  - **Key findings**: Gap between Code Review and Completed; no task owns test scoping; existing infrastructure (tracking files, decision matrix) is solid

- [x] **Create concept document**: PF-PRO-020
  - **Status**: COMPLETED
  - **Concept ID**: PF-PRO-020

- [x] **Impact analysis**: Read all files to be modified, document precise changes
  - **Status**: COMPLETED

- [x] **CHECKPOINT**: Present concept + impact analysis to human partner
  - **Status**: APPROVED
  - **Key decisions**: (1) Dropped `🔬 Needs Validation` — validation stays user-initiated only; (2) Added scoping guide with decision matrix migrated from PF-GDE-060; (3) Retroactive migration of 7 Completed features to `🔎 Needs Test Scoping`

### Phase 2: Session 1 — Core Implementation

**Priority**: HIGH — Status chain + task definition + guide + Code Review modification

- [x] Add `🔎 Needs Test Scoping` to feature-tracking.md Status Legends
  - **Status**: COMPLETED
- [x] Migrate 7 `🟢 Completed` features to `🔎 Needs Test Scoping`
  - **Status**: COMPLETED
- [x] Create task definition (New-Task.ps1 + extensive customization)
  - **Status**: COMPLETED — PF-TSK-086 created at process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md
- [x] Create guide (New-Guide.ps1 + extensive customization); migrate decision matrix from PF-GDE-060
  - **Status**: COMPLETED — PF-GDE-061 created at process-framework/guides/03-testing/performance-and-e2e-test-scoping-guide.md
- [x] Update Performance Testing Guide (PF-GDE-060): remove decision matrix, add cross-reference
  - **Status**: COMPLETED
- [x] Modify Code Review task (PF-TSK-005) output status + Next Tasks
  - **Status**: COMPLETED
- [x] Create context map
  - **Status**: COMPLETED — PF-VIS-054 created at process-framework/visualization/context-maps/03-testing/performance-e2e-test-scoping-map.md
- [x] Update Update-BatchFeatureStatus.ps1 ValidateSet
  - **Status**: COMPLETED
- [ ] **CHECKPOINT**: Review with human partner
  - **Status**: IN_PROGRESS

### Phase 3: Session 2 — Workflow Documentation + Framework Integration

**Priority**: HIGH — Ensures new workflow is discoverable and traceable

- [x] Update ai-tasks.md (task table + 8 workflow diagrams)
  - **Status**: COMPLETED
- [x] Update Task Transition Guide (new transition sections)
  - **Status**: COMPLETED
- [x] Update Task Trigger & Output Traceability (new rows + gap resolution)
  - **Status**: COMPLETED
- [x] Update Process Framework Task Registry
  - **Status**: COMPLETED
- [x] Update PF-documentation-map.md
  - **Status**: COMPLETED
- [x] Update Integration and Testing (PF-TSK-053) orphaned reference
  - **Status**: COMPLETED
- [x] Update test-specification-creation-guide.md decision matrix reference
  - **Status**: COMPLETED
- [x] Update process-improvement-tracking.md (complete PF-IMP-492, PF-IMP-493)
  - **Status**: COMPLETED
- [x] Complete feedback form
  - **Status**: COMPLETED — PF-FEE-876

## Session Tracking

### Session 1: 2026-04-12

**Focus**: Concept development, approval, state tracking setup
**Completed**:

- Pre-concept analysis (landscape study, lifecycle trace)
- Concept document PF-PRO-020 created and extensively customized
- Human review with 3 key design decisions
- Impact analysis of all ~9 affected files
- State tracking file PF-STA-085 created

**Issues/Blockers**:

- None

**Next Session Plan**:

- Execute Phase 2: core implementation (status chain, task definition, guide, Code Review modification)

### Session 2: 2026-04-12

**Focus**: Phase 2 — Core Implementation
**Completed**:

- Added `🔎 Needs Test Scoping` to feature-tracking.md Status Legends
- Migrated all 7 Completed features to `🔎 Needs Test Scoping`
- Created task definition PF-TSK-086 (Performance & E2E Test Scoping) with extensive customization
- Created guide PF-GDE-061 (Performance & E2E Test Scoping Guide) with decision matrix migrated from PF-GDE-060
- Updated Performance Testing Guide (PF-GDE-060): removed decision matrix, added cross-references
- Modified Code Review task (PF-TSK-005): output status → `🔎 Needs Test Scoping`, updated Next Tasks
- Created context map PF-VIS-054
- Updated Update-BatchFeatureStatus.ps1 ValidateSet

- Broadened E2E scoping beyond tracked workflows (Option A: discover untracked cross-feature interactions, add to user-workflow-tracking.md first)
- Created New-PerformanceTestEntry.ps1 with ID registry integration (BM/PH prefixes in TE-id-registry.json)
- Created New-WorkflowEntry.ps1 with ID registry integration (WF prefix in PD-id-registry.json)
- Created New-E2EMilestoneEntry.ps1 for e2e-test-tracking.md milestone table
- Added BM, PH routing to IdRegistry.psm1; WF routing to IdRegistry.psm1
- Updated Update-WorkflowTracking.ps1 to consider `🔎 Needs Test Scoping` as "implemented"
- Updated PF-TSK-084 (Performance Test Creation) references to point to new scoping task
- Updated Process Framework Task Registry (PF-TSK-086 entry fully populated)
- Updated PF-documentation-map.md with all 3 new scripts
- Updated task PF-TSK-086 Steps 7/9/11/13/14 to reference automation scripts

**Issues/Blockers**:

- None

**Next Session Plan**:

- Execute Phase 3: ai-tasks.md, Task Transition Guide, Traceability, PF-TSK-053 cleanup, test-specification-creation-guide.md, process-improvement-tracking, feedback form

## Completion Criteria

This temporary state file can be moved to `process-framework-local/state-tracking/temporary/old` when:

- [ ] All artifacts in the Artifact Tracking table are COMPLETED or DEFERRED
- [ ] All task impacts in the Task Impact table are COMPLETED
- [ ] Documentation maps updated
- [ ] Process improvement tracking updated (PF-IMP-492, PF-IMP-493)
- [ ] Feedback form completed

## Notes and Decisions

### Key Decisions Made

- **Dropped `🔬 Needs Validation`**: Per-feature validation after Code Review adds overhead without enforcement power (validation outputs tech debt, doesn't block). Validation stays user-initiated (batch rounds). Only `🔎 Needs Test Scoping` added.
- **Decision matrix migration**: Moved from PF-GDE-060 (Performance Testing Guide) to the new scoping guide. Clean separation: PF-GDE-060 = how to test, new guide = when to test.
- **Retroactive migration**: All 7 Completed features → `🔎 Needs Test Scoping` so they go through the new gate.
- **No new state files**: Scoping task outputs directly to existing performance-test-tracking.md and e2e-test-tracking.md.
