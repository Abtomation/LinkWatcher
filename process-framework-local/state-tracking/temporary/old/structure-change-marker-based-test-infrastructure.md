---
id: PF-STA-065
type: Document
category: General
version: 1.0
created: 2026-03-26
updated: 2026-03-26
change_name: marker-based-test-infrastructure
---

# Structure Change State: Marker-Based Test Infrastructure

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of structure change SC-007. Move to `process-framework-local/state-tracking/temporary/old` after all changes are implemented and validated.

## Structure Change Overview
- **Change Name**: Marker-Based Test Infrastructure
- **Change ID**: SC-007
- **Proposal Document**: [PF-PRO-012](/process-framework-local/proposals/structure-change-marker-based-test-infrastructure-proposal.md)
- **Change Type**: Documentation Architecture
- **Scope**: Replace test-registry.yaml with pytest markers as single source of truth
- **Origin**: PF-IMP-207 (Framework Evaluation PF-EVR-001)
- **Subsumes**: PF-IMP-208 (test_query.py covers Get-TestStatus functionality)

## Implementation Roadmap

### Phase 1: Add New Markers (safe, additive) ✅
**Status**: COMPLETED (2026-03-26, Session 1)

- [x] Register `test_type` and `specification` markers in `pyproject.toml`
- [x] Add `pytest.mark.test_type(...)` to all 31 test files
- [x] Add `pytest.mark.specification(...)` to 28 test files with specs
- [x] Verify: `pytest --collect-only --strict-markers` passes (548 tests collected)

### Phase 2: Create test_query.py (new tool, no removals) ✅
**Status**: COMPLETED (2026-03-26, Session 1)

- [x] Implement AST-based marker reader + test function counter
- [x] Support `--feature`, `--type`, `--summary`, `--dump --format yaml|json`, `--file` modes
- [x] Validate output against test-registry.yaml — parity confirmed for all 31 marker-bearing files
- [ ] Document in test-infrastructure-guide.md (deferred to Phase 5)

**Notes**: 1 expected gap — `test/automated/test_config.py` (TE-TST-100) is in registry but has no pytestmark (0 test methods, utility module). This is correct behavior.

### Phase 3: Migrate test-tracking.md Primary Key ✅
**Status**: COMPLETED (2026-03-26, Session 1)

- [x] Write migration script: TE-TST-XXX → file path using registry as lookup
- [x] Remove Test ID column, reorder columns (Feature ID first)
- [x] Pilot on a copy, diff against original — verified correct
- [x] Apply to actual file — 0 remaining TE-TST references, 57 table rows preserved
- [x] Updated Column Definitions, Workflow Integration, Adding New Test Files sections
- [x] Version bumped to 4.0

### Phase 4: Update Scripts ✅
**Status**: COMPLETED (2026-03-26, Session 2)

- [x] `TestTracking.psm1`: Replaced `Add-TestRegistryEntry` with `Add-PytestMarkers`; updated `Add-TestImplementationEntry` and `Update-TestImplementationStatusEnhanced` to use file path (no TestFileId); updated `Ensure-TestTrackingSection` table header to 8-column format
- [x] `New-TestFile.ps1`: Removed registry entry creation; replaced with `Add-PytestMarkers` call; added marker placeholders to template (`[FEATURE_ID]`, `[PRIORITY]`, `[TEST_TYPE_MARKER]`)
- [x] `New-TestAuditReport.ps1`: Changed `TestFileId` param to `TestFilePath`; updated test-tracking.md lookup to match by file name in 8-column format
- [x] `Validate-TestTracking.ps1`: Full rewrite — loads marker data via `test_query.py --dump --format json`; validates markers ↔ disk, markers ↔ tracking, feature IDs, test_type vs directory, test counts; E2E cross-ref check preserved
- [x] `Update-TestFileAuditState.ps1`: Changed `TestFileId` param to `TestFilePath`; updated `Get-FeatureIdFromTestFile` and `Update-IndividualTestFileStatus` to use file path; removed test-registry.yaml backup/update
- [x] `Update-TestAuditState.ps1`: Removed test-registry.yaml backup/update section; updated column format comment
- [x] `test-file-template.py`: Added `pytestmark` block with placeholders for feature, priority, test_type, and specification markers

### Phase 5: Update Documentation ✅
**Status**: COMPLETED (2026-03-26, Session 2)

- [x] Updated 13 task definitions referencing test-registry.yaml (foundation-feature-impl, test-audit, integration-testing, test-spec-creation, test-implementation, codebase-feature-analysis, retrospective-doc-creation, release-deployment, bug-fixing, data-layer-impl, project-initiation, codebase-feature-discovery, core-logic-impl)
- [x] Updated 4 guides (test-infrastructure-guide, integration-and-testing-usage, test-audit-usage, AUTOMATION-USAGE-GUIDE)
- [x] Updated 5 context maps (test-audit-map, test-implementation-map, test-specification-creation-map, core-logic-implementation-map, integration-and-testing-map)
- [x] Updated process-framework-task-registry.md (removed registry rows/references, updated to markers)
- [x] Updated PF-documentation-map.md (replaced registry reference with test_query.py, updated Validate-TestTracking description)
- [x] Updated test-infrastructure-guide.md with test_query.py documentation and marker-based workflow
- [x] Updated 2 audit READMEs (test/audits/, doc/test-audits/) — TestFileId → TestFilePath
- [x] Updated README.md (test_query.py replaces test-registry.yaml reference)
- [x] Updated test-tracking.md process instructions section
- [x] Updated cross-cutting-test-specification-template.md
- [x] Final grep verification: 0 active references to test-registry.yaml remain (1 intentional E2E reference in test-infrastructure-guide noting Phase 7 dependency)

### Phase 6: Retire test-registry.yaml ✅
**Status**: COMPLETED (2026-03-26, Session 2)

- [x] Archived `test/test-registry.yaml` to `test/archive/test-registry-archived-2026-03-26.yaml`
- [x] Removed `TE-TST` prefix from `test/TE-id-registry.json` (updated description, bumped date)
- [x] Ran `Validate-StateTracking.ps1` — 0 new errors (1 pre-existing PD-ASS counter collision)
- [x] Ran `Validate-TestTracking.ps1` — 0 errors, 4 warnings (expected: 2 unmarked files, 1 unknown feature, 1 count mismatch)
- [x] Verified grep: 0 active doc/task/guide references remain; remaining hits are historical (audit reports, IMP notes), E2E scripts (Phase 7), and SC-007 state file itself

**Known remaining script references** (not in Phase 6 scope):
- `Run-Tests.ps1` `-UpdateTracking` switch — uses registry for PD-TST ID lookup; needs update to use file path matching (tracked for Phase 7 or separate IMP)
- `New-E2EAcceptanceTestCase.ps1` — adds E2E entries to registry (Phase 7)
- `New-TestSpecification.ps1` cross-cutting mode — adds placeholder to registry (Phase 7)
- `Validate-StateTracking.ps1` surface 4 — gracefully handles missing registry file

### Phase 7: E2E Entry Decision ✅
**Status**: COMPLETED (2026-03-26, Session 2) — IMP-210 already implemented

- [x] Confirmed IMP-210 (E2E tracking split) was completed on 2026-03-25 — E2E entries tracked in `e2e-test-tracking.md`
- [x] Removed registry write from `New-E2EAcceptanceTestCase.ps1` (step 8 — redundant with e2e-test-tracking.md)
- [x] Removed registry write from `New-TestSpecification.ps1` (cross-cutting mode — redundant with pytest markers)
- [x] Updated `Run-Tests.ps1` `-UpdateTracking` — replaced registry-based PD-TST ID lookup with file name matching against 8-column test-tracking.md

## Session Tracking

### Session 1: 2026-03-26
**Focus**: Phase 1 + Phase 2 + Phase 3
**Completed**:
- Created SC-007 state tracking file (PF-STA-065)
- Phase 1: Registered 2 new markers, updated all 31 test files, verified with pytest
- Phase 2: Created test_query.py with 5 query modes, validated parity against registry
- Phase 3: Migrated test-tracking.md — removed Test ID column, 0 TE-TST references remain

**Issues/Blockers**:
- None

**Next Session Plan**:
- Phase 5: Update documentation

### Session 2: 2026-03-26
**Focus**: Phase 4
**Completed**:
- Updated 6 scripts + 1 template to use file path instead of TE-TST/PD-TST IDs
- `TestTracking.psm1`: Replaced `Add-TestRegistryEntry` with `Add-PytestMarkers`, updated all functions to 8-column format
- `New-TestFile.ps1`: Removed registry calls, added marker template placeholders and `Add-PytestMarkers` call
- `New-TestAuditReport.ps1`: `TestFileId` → `TestFilePath`, 8-column test-tracking.md lookup
- `Validate-TestTracking.ps1`: Full rewrite — marker-based validation via `test_query.py --dump --format json`
- `Update-TestFileAuditState.ps1`: `TestFileId` → `TestFilePath`, file path lookup, removed registry backup
- `Update-TestAuditState.ps1`: Removed registry section, updated column comment
- `test-file-template.py`: Added `pytestmark` block with feature/priority/test_type/specification placeholders
- All scripts verified with `-WhatIf`/`-DryRun` — 0 errors

**Issues/Blockers**:
- None

**Completed in same session**:
- Phase 4: Updated 6 scripts + 1 template
- Phase 5: Updated ~30 documentation files (13 task definitions, 4 guides, 5 context maps, 3 infrastructure docs, 3 READMEs, 1 template, 1 state tracking)
- Phase 6: Archived test-registry.yaml, removed TE-TST prefix, validation passed
- Phase 7: Resolved — IMP-210 already completed; removed registry writes from 3 scripts (New-E2EAcceptanceTestCase, New-TestSpecification, Run-Tests.ps1)

**Next Session Plan**:
- Finalization: feedback form, proposal archive, move state file to old/

## Success Criteria

- [x] `Validate-StateTracking.ps1` reports 0 new errors after migration (1 pre-existing PD-ASS counter issue)
- [x] `test_query.py --summary` produces correct feature → test count mapping (verified Phase 2)
- [x] No active script references `test-registry.yaml` or `TE-TST-XXX` (grep verified — remaining hits are in Old/ archived modules and historical state tracking notes only)
- [x] `pytest --collect-only --strict-markers` passes (verified Phase 1: 548 tests)
- [x] Documentation grep for `test-registry.yaml` returns 0 hits outside archive/historical

## Completion Criteria

This file can be archived when:
- [x] All phases (1–7) completed successfully
- [x] All success criteria met
- [x] Phase 7 resolved (IMP-210 already completed; E2E scripts updated)
- [ ] Feedback forms completed
- [ ] Proposal archived to `proposals/old`
