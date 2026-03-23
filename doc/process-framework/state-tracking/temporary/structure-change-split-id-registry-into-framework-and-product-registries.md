---
id: PF-STA-064
type: Document
category: General
version: 1.0
created: 2026-03-23
updated: 2026-03-23
change_name: split-id-registry-into-framework-and-product-registries
---

# Structure Change State: Split ID Registry Into Framework And Product Registries

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of structure change. Move to `doc/process-framework/state-tracking/temporary/old/` after all changes are implemented and validated.

## Structure Change Overview
- **Change Name**: Split ID Registry Into Framework And Product Registries
- **Change ID**: SC-008
- **Proposal Document**: [Structure Change Proposal PF-PRO-011](/doc/process-framework/proposals/proposals/structure-change-split-id-registry-into-framework-and-product-registries-proposal.md)
- **Change Type**: Documentation Architecture
- **Scope**: Split doc/id-registry.json into three domain-specific registries (PF, PD, TE) with prefix renames, metadata updates (~668 files), and script refactoring
- **Expected Completion**: TBD (3-4 sessions)

## Affected Components Analysis

### Content Files Affected (Metadata Prefix Updates)

| Scope | Old → New Prefix | Count | Location Pattern | Complexity |
|-------|------------------|-------|------------------|------------|
| Feedback artifacts | ART-FEE → PF-FEE | ~434 | `doc/process-framework/feedback/` | SIMPLE (bulk replace) |
| Refactoring plans | PF-REF → PD-REF | 55 | `doc/product-docs/refactoring/plans/` | SIMPLE |
| Assessment artifacts | ART-ASS → PD-ASS | ~53 | `doc/product-docs/documentation-tiers/assessments/` | SIMPLE |
| Feature impl. states | PF-FEA → PD-FIS | 51 | `doc/product-docs/state-tracking/features/` | SIMPLE |
| State tracking (product) | PF-STA → PD-STA | 27 | `doc/process-framework/state-tracking/` | SIMPLE |
| Review artifacts | ART-REV → PF-REV | 14 | `doc/process-framework/feedback/reviews/` | SIMPLE |
| Validation reports | PF-VAL → PD-VAL | 12 | `doc/product-docs/validation/reports/` | SIMPLE |
| Test specifications | PF-TSP → TE-TSP | 10 | `test/specifications/` | SIMPLE |
| Test audit reports | PF-TAR → TE-TAR | 7 | `test/audits/` | SIMPLE |
| User guide handbooks | PD-UGD (add) | 2 | `doc/product-docs/user/handbooks/` | SIMPLE (add frontmatter) |
| State tracking (test) | PF-STA → TE-STA | 1 | `doc/process-framework/state-tracking/permanent/` → `test/` | MODERATE (move + rename) |
| Tier assessments README | PF-ASS → PF-DOC | 1 | `doc/product-docs/documentation-tiers/` | SIMPLE |
| Development guide | PD-GDE → PF-GDE | 1 | `doc/process-framework/guides/` | SIMPLE |
| **Total** | | **~668** | | |

### Infrastructure Components

| Component Type | Name | Location | Change Required | Priority |
|----------------|------|----------|----------------|----------|
| Module | IdRegistry.psm1 | `doc/process-framework/scripts/` | Hardcoded prefix→registry mapping | HIGH |
| Script | validate-id-registry.ps1 | `doc/process-framework/scripts/validation/` | Scan all 3 registries | HIGH |
| Script | Validate-StateTracking.ps1 | `doc/process-framework/scripts/validation/` | Update registry path | HIGH |
| Script | Validate-TestTracking.ps1 | `doc/process-framework/scripts/validation/` | Update registry path | HIGH |
| Script | New-TestSpecification.ps1 | `doc/process-framework/scripts/file-creation/03-testing/` | Update prefix + path | MEDIUM |
| Script | New-E2EAcceptanceTestCase.ps1 | `doc/process-framework/scripts/file-creation/03-testing/` | Update path | MEDIUM |
| Script | New-ValidationReport.ps1 | `doc/process-framework/scripts/file-creation/05-validation/` | Update prefix + path | MEDIUM |
| Script | New-FeatureImplementationState.ps1 | `doc/process-framework/scripts/file-creation/04-implementation/` | Update prefix + path | MEDIUM |
| Script | All other file-creation scripts | `doc/process-framework/scripts/file-creation/` | Update path via module | MEDIUM |
| Documentation | CLAUDE.md | project root | Update registry reference | MEDIUM |
| Documentation | documentation-map.md | `doc/process-framework/` | Update prefix references | MEDIUM |
| Tasks | Multiple task definitions | `doc/process-framework/tasks/` | Update id-registry.json context refs | LOW |

## Migration Strategy

### Migration Approach
- **Strategy Type**: Phased (6 phases, 3-4 sessions)
- **Rollback Strategy**: Merge 3 registries back, revert IdRegistry.psm1, bulk-replace metadata prefixes back
- **Key insight**: Move `doc/id-registry.json` → `doc/process-framework/PF-id-registry.json` instead of delete+create, so LinkWatcher updates references

### File Mapping

| Current Structure | New Structure | Migration Method |
|-------------------|---------------|------------------|
| `doc/id-registry.json` | `doc/process-framework/PF-id-registry.json` | Move (LinkWatcher updates refs) |
| _(new)_ | `doc/product-docs/PD-id-registry.json` | Create from extracted PD-* prefixes |
| _(new)_ | `test/TE-id-registry.json` | Create from extracted TE-* prefixes |
| `doc/process-framework/feedback/README.md` | _(removed)_ | Delete |
| `doc/process-framework/state-tracking/permanent/test-tracking.md` | `test/test-tracking.md` | Move |

## Implementation Roadmap

### Phase 1: Create Registry Files (Session 1)
**Priority**: HIGH — Foundation for all subsequent work

- [x] **Structure Change Proposal**: PF-PRO-011 created and approved
  - **Status**: COMPLETED
  - **Location**: [Proposal](/doc/process-framework/proposals/proposals/structure-change-split-id-registry-into-framework-and-product-registries-proposal.md)

- [ ] **Move id-registry.json**: Move `doc/id-registry.json` → `doc/process-framework/PF-id-registry.json`
  - **Status**: NOT_STARTED
  - **Notes**: LinkWatcher updates all references automatically

- [ ] **Clean PF-id-registry.json**: Remove non-PF prefixes, apply renames, remove PF-MTH
  - **Status**: NOT_STARTED
  - **Renames**: ART-FEE→PF-FEE, ART-REV→PF-REV, PF-ASS→PF-DOC (merge)
  - **Removals**: PF-MTH, PF-FEA (→PD-FIS), all PD-*/ART-*/TE-* prefixes
  - **PF-STA**: Keep with process-improvement-tracking.md only

- [ ] **Create PD-id-registry.json**: Extract PD-* prefixes with renames
  - **Status**: NOT_STARTED
  - **Location**: `doc/product-docs/PD-id-registry.json`
  - **Renames**: PF-STA(product)→PD-STA, PF-VAL→PD-VAL, PF-REF→PD-REF, PF-TDA/TDI/TDM→PD-*, ART-ASS→PD-ASS, PF-FEA→PD-FIS
  - **Removals**: PD-GDE, PD-USR, orphaned old PD-ASS

- [ ] **Create TE-id-registry.json**: Extract TE-* prefixes with renames
  - **Status**: NOT_STARTED
  - **Location**: `test/TE-id-registry.json`
  - **Content**: TE-E2G, TE-E2E, PF-TSP→TE-TSP, PF-TAR→TE-TAR, PD-TST→TE-TST, PF-STA(test)→TE-STA

- [ ] **Remove feedback README**: Delete `doc/process-framework/feedback/README.md` (PF-FEE-000)
  - **Status**: NOT_STARTED

- [ ] **Verify registry integrity**: Count prefixes across all 3 files
  - **Status**: NOT_STARTED

### Phase 2: Update IdRegistry.psm1 (Session 1 continued)
**Priority**: HIGH — Scripts depend on this module

- [ ] **Implement prefix→registry mapping**: Hardcoded lookup in `Get-IdRegistryPath`
  - **Status**: NOT_STARTED
  - **Pattern**: PF-* → PF-id-registry.json, PD-* → PD-id-registry.json, TE-* → TE-id-registry.json

- [ ] **Update downstream functions**: Propagate prefix through Get-IdRegistry, New-NextId, etc.
  - **Status**: NOT_STARTED

- [ ] **Test module**: Verify with PF-*, PD-*, and TE-* prefixes
  - **Status**: NOT_STARTED

### Phase 3: Update Scripts (Session 2)
**Priority**: HIGH — Must work before bulk metadata updates

- [ ] **Update validation scripts**: validate-id-registry.ps1, Validate-StateTracking.ps1, Validate-TestTracking.ps1
  - **Status**: NOT_STARTED

- [ ] **Update file creation scripts**: All scripts that reference old id-registry.json path or renamed prefixes
  - **Status**: NOT_STARTED
  - **Key scripts**: New-TestSpecification.ps1 (PF-TSP→TE-TSP), New-ValidationReport.ps1 (PF-VAL→PD-VAL), New-FeatureImplementationState.ps1 (PF-FEA→PD-FIS)

- [ ] **Test script updates**: Run at least one creation per registry
  - **Status**: NOT_STARTED

### Phase 4: Bulk Metadata Updates (Session 3)
**Priority**: HIGH — Largest phase (~668 files)

- [ ] **ART-FEE → PF-FEE**: ~434 feedback form files
  - **Status**: NOT_STARTED
  - **Method**: PowerShell bulk replace `^id: ART-FEE-` → `id: PF-FEE-`

- [ ] **PF-REF → PD-REF**: 55 refactoring plan files
  - **Status**: NOT_STARTED

- [ ] **ART-ASS → PD-ASS**: ~53 assessment artifact files
  - **Status**: NOT_STARTED

- [ ] **PF-FEA → PD-FIS**: 51 feature implementation state files
  - **Status**: NOT_STARTED

- [ ] **PF-STA → PD-STA**: 27 product state tracking files
  - **Status**: NOT_STARTED

- [ ] **ART-REV → PF-REV**: 14 review artifact files
  - **Status**: NOT_STARTED

- [ ] **PF-VAL → PD-VAL**: 12 validation report files
  - **Status**: NOT_STARTED

- [ ] **PF-TSP → TE-TSP**: 10 test specification files
  - **Status**: NOT_STARTED

- [ ] **PF-TAR → TE-TAR**: 7 test audit report files
  - **Status**: NOT_STARTED

- [ ] **PD-UGD**: Add YAML frontmatter to 2 handbook files
  - **Status**: NOT_STARTED

- [ ] **PF-STA → TE-STA**: 1 test-tracking file (also move to `test/`)
  - **Status**: NOT_STARTED

- [ ] **PF-ASS → PF-DOC**: 1 tier assessments README
  - **Status**: NOT_STARTED

- [ ] **PD-GDE → PF-GDE**: 1 development guide
  - **Status**: NOT_STARTED

- [ ] **Verify zero old prefixes remain**: Grep for all old prefixes in frontmatter
  - **Status**: NOT_STARTED

### Phase 5: Documentation Updates (Session 4)
**Priority**: MEDIUM — Ensure docs reflect new state

- [ ] **Update CLAUDE.md**: Describe all 3 registry files
  - **Status**: NOT_STARTED

- [ ] **Update documentation-map.md**: Fix all renamed prefix references (PF-VAL-035→PD-VAL-035, etc.)
  - **Status**: NOT_STARTED

- [ ] **Update task definitions**: Fix id-registry.json context references in tasks
  - **Status**: NOT_STARTED

- [ ] **Update cross-references**: Fix prefix mentions in guides, proposals, etc.
  - **Status**: NOT_STARTED

### Phase 6: Validation & Cleanup (Session 4 continued)
**Priority**: HIGH — Final verification

- [ ] **Run validate-id-registry.ps1**: Zero errors across all 3 registries
  - **Status**: NOT_STARTED

- [ ] **Run Validate-StateTracking.ps1**: Zero errors across all surfaces
  - **Status**: NOT_STARTED

- [ ] **Run Validate-TestTracking.ps1**: Zero errors
  - **Status**: NOT_STARTED

- [ ] **Test document creation**: One PF-*, one PD-*, one TE-* prefix
  - **Status**: NOT_STARTED

- [ ] **Grep for old paths**: Zero references to `doc/id-registry.json`
  - **Status**: NOT_STARTED

- [ ] **Grep for old prefixes**: Zero frontmatter with ART-ASS, ART-FEE, ART-REV, PF-STA(product), PF-TSP, PF-TAR, PF-VAL, PF-REF, PF-TDA, PF-TDI, PF-TDM, PD-TST, PF-FEA
  - **Status**: NOT_STARTED

- [ ] **Archive proposal**: Move PF-PRO-011 to `proposals/proposals/old/`
  - **Status**: NOT_STARTED

- [ ] **Archive this state file**: Move to `state-tracking/temporary/old/`
  - **Status**: NOT_STARTED

## Session Tracking

### Session 1: 2026-03-23
**Focus**: Proposal creation + state tracking file
**Completed**:
- Created structure change proposal PF-PRO-011
- Created this state tracking file PF-STA-064
- Researched all prefix file counts and collision impacts

**Issues/Blockers**:
- None

**Next Session Plan**:
- Execute Phase 1 (registry creation) and Phase 2 (IdRegistry.psm1 refactor)

## Testing & Validation

### Test Cases

| Test Case | Description | Expected Result | Status |
|-----------|-------------|----------------|--------|
| TC-001 | `New-NextId -Prefix "PF-TSK"` reads from PF-id-registry.json | Correct ID, correct file updated | PENDING |
| TC-002 | `New-NextId -Prefix "PD-TDD"` reads from PD-id-registry.json | Correct ID, correct file updated | PENDING |
| TC-003 | `New-NextId -Prefix "TE-TSP"` reads from TE-id-registry.json | Correct ID, correct file updated | PENDING |
| TC-004 | validate-id-registry.ps1 scans all 3 registries | Zero errors | PENDING |
| TC-005 | Validate-StateTracking.ps1 Surface 5 | Zero errors | PENDING |
| TC-006 | New-FeedbackForm.ps1 creates with PF-FEE prefix | Correct prefix, updates PF-id-registry.json | PENDING |
| TC-007 | New-TestSpecification.ps1 creates with TE-TSP prefix | Correct prefix, updates TE-id-registry.json | PENDING |
| TC-008 | Grep for old prefixes in frontmatter | Zero hits | PENDING |
| TC-009 | Grep for `doc/id-registry.json` in codebase | Zero hits | PENDING |

### Issues & Resolutions

| Issue | Description | Impact | Resolution | Status |
|-------|-------------|--------|------------|--------|
| _(none yet)_ | | | | |

## Rollback Plan

1. Merge 3 registries back into `doc/id-registry.json`
2. Revert IdRegistry.psm1 to single-path implementation
3. Revert script hardcoded paths
4. Bulk-replace metadata prefixes back to originals

> **Note**: Phase 4 (bulk metadata, ~668 files) is the hardest to rollback. Validate Phases 1-3 thoroughly before starting Phase 4.

## Completion Criteria

This state file moves to `doc/process-framework/state-tracking/temporary/old/` when:

- [ ] All 6 phases completed
- [ ] All 9 test cases pass
- [ ] All ~668 files have updated metadata
- [ ] All validation scripts pass with zero errors
- [ ] Documentation (CLAUDE.md, documentation-map.md) updated
- [ ] Feedback form completed

## Notes and Decisions

### Key Decisions
- **Three registries** (not two): PF, PD, TE — test artifacts get their own registry
- **Move not delete**: `doc/id-registry.json` moved to `doc/process-framework/PF-id-registry.json` so LinkWatcher updates references
- **PF-STA split**: process-improvement-tracking stays PF-STA, product files → PD-STA, test-tracking → TE-STA
- **PF-FEA → PD-FIS**: Feature implementation states are product-specific
- **No collisions**: PD-ASS orphaned (0 files), feedback README removed
- **PF-MTH removed**: methodologies directory was deleted
