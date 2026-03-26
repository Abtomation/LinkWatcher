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

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of structure change SC-007. Move to `doc/process-framework/state-tracking/temporary/old/` after all changes are implemented and validated.

## Structure Change Overview
- **Change Name**: Marker-Based Test Infrastructure
- **Change ID**: SC-007
- **Proposal Document**: [PF-PRO-012](/doc/process-framework/proposals/proposals/structure-change-marker-based-test-infrastructure-proposal.md)
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

### Phase 3: Migrate test-tracking.md Primary Key
**Status**: NOT_STARTED

- [ ] Write migration script: TE-TST-XXX → file path using registry as lookup
- [ ] Remove Test ID column, reorder columns (Feature ID first)
- [ ] Pilot on a copy, diff against original
- [ ] Apply to actual file after approval

### Phase 4: Update Scripts
**Status**: NOT_STARTED

- [ ] `TestTracking.psm1`: Replace `Add-TestRegistryEntry` with marker-writing function
- [ ] `New-TestFile.ps1`: Remove registry entry creation; ensure `specification` marker placeholder
- [ ] `New-TestAuditReport.ps1`: Accept file path instead of TestFileId
- [ ] `Validate-TestTracking.ps1`: Rewrite to validate `test_query.py --dump` against test-tracking.md

### Phase 5: Update Documentation
**Status**: NOT_STARTED

- [ ] Update ~10 task definitions referencing test-registry.yaml
- [ ] Update 5 guides (test-infrastructure-guide, integration-and-testing, test-file-creation, test-audit-usage, AUTOMATION-USAGE-GUIDE)
- [ ] Update ~5 context maps in 03-testing/
- [ ] Update process-framework-task-registry.md
- [ ] Update documentation-map.md (remove registry reference, add test_query.py)
- [ ] Document test_query.py in test-infrastructure-guide.md

### Phase 6: Retire test-registry.yaml
**Status**: NOT_STARTED

- [ ] Archive `test/test-registry.yaml` to `test/archive/`
- [ ] Remove `TE-TST` prefix from `test/TE-id-registry.json`
- [ ] Run `Validate-StateTracking.ps1` — 0 errors
- [ ] Verify grep for `test-registry.yaml` returns 0 hits outside archive

### Phase 7: E2E Entry Decision (depends on IMP-210)
**Status**: DEFERRED

- [ ] Determine E2E entry approach after IMP-210 status is resolved

## Session Tracking

### Session 1: 2026-03-26
**Focus**: Phase 1 + Phase 2
**Completed**:
- Created SC-007 state tracking file (PF-STA-065)
- Phase 1: Registered 2 new markers, updated all 31 test files, verified with pytest
- Phase 2: Created test_query.py with 5 query modes, validated parity against registry

**Issues/Blockers**:
- None

**Next Session Plan**:
- Phase 3: Migrate test-tracking.md primary key from TE-TST-XXX to file paths

## Success Criteria

- [ ] `Validate-StateTracking.ps1` reports 0 errors after full migration
- [ ] `test_query.py --summary` produces correct feature → test count mapping
- [ ] No script references `test-registry.yaml` or `TE-TST-XXX` (grep verified)
- [ ] `pytest --collect-only --strict-markers` passes
- [ ] Documentation grep for `test-registry.yaml` returns 0 hits outside archive

## Completion Criteria

This file can be archived when:
- [ ] All phases (1–6) completed successfully
- [ ] All success criteria met
- [ ] Phase 7 resolved or explicitly deferred with tracking
- [ ] Feedback forms completed
- [ ] Proposal archived to `proposals/old/`
