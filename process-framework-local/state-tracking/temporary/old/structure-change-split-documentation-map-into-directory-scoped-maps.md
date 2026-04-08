---
id: PF-STA-072
type: Document
category: General
version: 1.0
created: 2026-04-03
updated: 2026-04-03
change_name: split-documentation-map-into-directory-scoped-maps
---

# Structure Change State: Split Documentation Map Into Directory-Scoped Maps

> **Lightweight state file**: This change has a detailed proposal document. This file tracks **execution progress only** — see the proposal for rationale, affected files, and migration strategy.

## Structure Change Overview
- **Change Name**: Split Documentation Map Into Directory-Scoped Maps
- **Change ID**: SC-009
- **Proposal Document**: [PF-PRO-014](/process-framework-local/proposals/old/structure-change-split-documentation-map-into-directory-scoped-maps-proposal.md)
- **Change Type**: Documentation Architecture
- **Scope**: Split monolithic PF-documentation-map.md into three directory-scoped maps for process-framework/, doc/, and test/
- **Expected Completion**: 2026-04-03

## Implementation Roadmap

### Phase 1: Create New Maps
- [x] Create `doc/PD-documentation-map.md` with product documentation content
- [x] Create `test/TE-documentation-map.md` with test documentation content
- [x] Add cross-reference sections to both new maps

### Phase 2: Trim and Rename Process Framework Map
- [x] Rename `documentation-map.md` → `PF-documentation-map.md`
- [x] Remove doc/ and test/ content from `process-framework/PF-documentation-map.md`
- [x] Add cross-reference section to other two maps
- [x] Move "Process Framework Guides" to correct section (was misplaced under "Product Documentation")

### Phase 3: Update Scripts
- [x] `Update-UserDocumentationState.ps1` — changed path to `doc/PD-documentation-map.md`
- [x] `Update-ValidationReportState.ps1` — changed path to `doc/PD-documentation-map.md`
- [x] `New-Task.ps1` — verified: LinkWatcher auto-updated to `PF-documentation-map.md` (correct)

### Phase 4: Update Task Definitions
- [x] 12 validation task checklists (11 dimensions + preparation) → `doc/PD-documentation-map.md`
- [x] Test Specification Creation (PF-TSK-012) → `test/TE-documentation-map.md`
- [x] Retrospective Documentation Creation (PF-TSK-066) → clarified all three maps
- [x] Structure Change Task (PF-TSK-014) → clarified all three maps
- [x] New Task Creation Process (PF-TSK-001) → `PF-documentation-map.md`
- [x] Framework Extension Task (PF-TSK-026) → clarified all three maps
- [x] User Documentation Creation (PF-TSK-081) → `doc/PD-documentation-map.md`
- [x] Framework Domain Adaptation → `PF-documentation-map.md`
- [x] All other tasks verified (LinkWatcher auto-updated)

### Phase 5: Update Guides, Templates, Infrastructure
- [x] `guides/support/migration-best-practices.md` — updated archive step with three-map guidance
- [x] `guides/support/document-creation-script-development-guide.md` — updated code example
- [x] `templates/support/framework-extension-concept-template.md` — clarified map scope
- [x] All other guides/templates/infrastructure verified (LinkWatcher auto-updated)
- [x] `CLAUDE.md` — verified: LinkWatcher auto-updated to `PF-documentation-map.md`

### Bonus: Fix PD-ASS ID Counter
- [x] Fixed `PD-ASS.nextAvailable` from 200 → 201 in `doc/PD-id-registry.json`

## Session Tracking

### Session 1: 2026-04-03
**Focus**: All phases (single-session execution)
**Completed**:
- [x] Proposal created and approved (PF-PRO-014)
- [x] State tracking file created (PF-STA-072)
- [x] All 5 phases executed
- [x] Validation passed (1 pre-existing error fixed: PD-ASS counter)
- [x] Zero bare `documentation-map.md` references remain in active files

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [x] All phases completed successfully
- [x] All proposal-listed files addressed
- [x] Validation passes (Validate-StateTracking.ps1) — 0 errors after PD-ASS fix
- [ ] Feedback form completed
