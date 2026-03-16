---
id: PF-STA-055
type: Document
category: State Tracking
version: 1.0
created: 2026-03-16
updated: 2026-03-16
change_name: test-directory-consolidation
---

# Structure Change State: Test Directory Consolidation

> **⚠️ TEMPORARY FILE**: This file tracks multi-session implementation of structure change. Move to `doc/process-framework/state-tracking/temporary/old/` after all changes are implemented and validated.

## Structure Change Overview
- **Change Name**: Test Directory Consolidation & Framework Integration
- **Change ID**: SC-006
- **Proposal Document**: [Structure Change Proposal (PF-PRO-006)](/doc/process-framework/proposals/proposals/structure-change-test-directory-consolidation-and-framework-integration-proposal.md)
- **Change Type**: Directory Reorganization
- **Scope**: Consolidate 4 test directories into unified `test/` structure, formalize ad-hoc tests via PF-TSK-069, relocate test audits, create project-agnostic test runner, eliminate redundant documentation
- **Expected Completion**: 2026-03-17

## Affected Components Analysis

### Configuration Files Affected

| File | Change Required | Priority | Impact Level |
|------|----------------|----------|--------------|
| `pytest.ini` | `testpaths = tests` → `testpaths = test/automated` | HIGH | BREAKING |
| `pyproject.toml` | `testpaths = ["tests"]` → `testpaths = ["test/automated"]` | HIGH | BREAKING |
| `.github/workflows/ci.yml` | `flake8/black/isort linkwatcher tests` → `test/automated` | HIGH | BREAKING |

### Content Files Affected

| File Type | Count | Location Pattern | Migration Complexity | Notes |
|-----------|-------|------------------|---------------------|-------|
| Automated test files (*.py) | ~30 | `tests/**/*.py` → `test/automated/**/*.py` | SIMPLE (move) | conftest.py, utils.py, unit/, integration/, parsers/, performance/ |
| Bug validation scripts | 13 | `tests/manual/*.py` → `test/automated/bug-validation/*.py` | SIMPLE (move) | PD-BUG-* regression scripts |
| Test fixtures | 4 | `tests/fixtures/*` → `test/automated/fixtures/*` | SIMPLE (move) | sample_markdown.md, sample_config.yaml, sample_data.json, __init__.py |
| Test audit reports | 7 | `doc/product-docs/test-audits/**` → `test/audits/**` | SIMPLE (move) | 3 subdirectories: foundation/, authentication/, core-features/ |
| Redundant .md files | 4 | `tests/*.md` | DELETE | README, TEST_PLAN, TEST_CASE_STATUS, TEST_CASE_TEMPLATE |
| Ad-hoc PS parser tests | 3 | `manual-tests/powershell-parser/` | MODERATE (formalize) | Formalize via PF-TSK-069 |
| Ad-hoc MD parser tests | 12+ | `manual_markdown_tests/` | MODERATE (formalize) | Formalize via PF-TSK-069 |
| test-registry.yaml | 1 | `test/test-registry.yaml` | MODERATE (update ~30 paths) | All filePath entries need updating |

### Infrastructure Components

| Component Type | Name | Location | Change Required | Priority |
|----------------|------|----------|----------------|----------|
| Script | `run_tests.py` | Project root | Replace with `Run-Tests.ps1` | HIGH |
| Script (new) | `Run-Tests.ps1` | `doc/process-framework/scripts/test/` | Create project-agnostic test runner | HIGH |
| Guide (new) | `test-infrastructure-guide.md` | `doc/process-framework/guides/guides/03-testing/` | Create — explains test/ structure | MEDIUM |
| State File | `4.1.1-test-suite-implementation-state.md` | `doc/process-framework/state-tracking/features/` | Update all `tests/` → `test/automated/` paths | HIGH |
| State File | `test-tracking.md` | `doc/process-framework/state-tracking/permanent/` | Update audit report path references | HIGH |
| State File | `documentation-map.md` | `doc/process-framework/` | Update test audit links, remove deleted .md refs | MEDIUM |
| Validation Script | `Validate-TestTracking.ps1` | `doc/process-framework/scripts/validation/` | Verify paths work with new structure | MEDIUM |
| Validation Script | `Validate-StateTracking.ps1` | `doc/process-framework/scripts/validation/` | Verify paths work with new structure | MEDIUM |
| Audit Script | `New-TestAuditReport.ps1` | `doc/process-framework/scripts/file-creation/` | Update output path to `test/audits/` | MEDIUM |

## Implementation Roadmap

> **Delegation Tracking**: PF-TSK-014 orchestrates the overall change. Phase 2 delegates manual test formalization to PF-TSK-069 (Manual Test Case Creation). All MT IDs assigned from id-registry.json via `New-ManualTestCase.ps1`.

### Phase 1: Physical Consolidation (Session 1)
**Priority**: HIGH — Must complete before any other work

- [ ] **Create `test/automated/` directory**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct

- [ ] **Move automated test code from `tests/` to `test/automated/`**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Files**: unit/, integration/, parsers/, performance/, fixtures/, conftest.py, utils.py, __init__.py, test_config.py, test_move_detection.py, test_directory_move_detection.py

- [ ] **Move `tests/manual/` to `test/automated/bug-validation/`**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Files**: 13 PD-BUG-* regression scripts + test_procedures.md

- [ ] **Delete redundant .md files from `tests/`**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Files**: README.md, TEST_PLAN.md, TEST_CASE_STATUS.md, TEST_CASE_TEMPLATE.md

- [ ] **Move `doc/product-docs/test-audits/` to `test/audits/`**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Files**: 7 audit reports across 3 subdirectories + README.md

- [ ] **Update pytest configuration**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Files**: pytest.ini (`testpaths = test/automated`), pyproject.toml (`testpaths = ["test/automated"]`)

- [ ] **Update CI/CD pipeline**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **File**: `.github/workflows/ci.yml` — flake8/black/isort paths

- [ ] **Update test-registry.yaml**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Scope**: ~30 filePath entries changing from `tests/` to `test/automated/` relative paths

- [ ] **Run pytest — verify all 247+ tests pass**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct

- [ ] **Delete empty `tests/` directory**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct

- [ ] **🚨 CHECKPOINT**: Tests pass, no regressions — get human approval before Phase 2

### Phase 2: Ad-hoc Test Formalization (Session 1 continued)
**Priority**: HIGH — Formalize orphan directories via PF-TSK-069

> **CRITICAL**: All MT-GRP and MT IDs must come from id-registry.json via `New-ManualTestCase.ps1`. Do NOT reuse ad-hoc naming (MP-001, LR-001, etc.).

- [ ] **Formalize `manual-tests/powershell-parser/` as MT-GRP-***
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-069 (Manual Test Case Creation)
  - **Process**: Follow PF-TSK-069, use `New-ManualTestCase.ps1` for ID assignment
  - **Feature mapping**: 2.1.1 (Link Parsing System), cross-cuts 2.2.1 (Link Updating)

- [ ] **Formalize `manual_markdown_tests/` MP-*/LR-* as MT-GRP-***
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-069 (Manual Test Case Creation)
  - **Process**: Follow PF-TSK-069, use `New-ManualTestCase.ps1` for ID assignment
  - **Feature mapping**: 2.1.1 (Link Parsing System)

- [ ] **Extract special-character fixtures**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **From**: `manual_markdown_tests/test_project/` (files with spaces, parentheses, ampersands, brackets)
  - **To**: `test/automated/fixtures/special-characters/`

- [ ] **Delete `manual-tests/` and `manual_markdown_tests/`**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct

- [ ] **Verify test-tracking.md updated with new MT-GRP entries**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Notes**: `New-ManualTestCase.ps1` should handle this automatically

- [ ] **🚨 CHECKPOINT**: All 4 source directories resolved, 0 orphan test directories remain

### Phase 3: Framework Script & Guide (Session 2)
**Priority**: HIGH — Create project-agnostic infrastructure

- [ ] **Create `Run-Tests.ps1`**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Location**: `doc/process-framework/scripts/test/Run-Tests.ps1`
  - **Requirements**: Read project-config.json for module name, test directory, test categories; wrap pytest

- [ ] **Delete `run_tests.py`**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Dependencies**: `Run-Tests.ps1` tested and working

- [ ] **Create test infrastructure guide**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct (use New-Guide.ps1)
  - **Location**: `doc/process-framework/guides/guides/03-testing/test-infrastructure-guide.md`
  - **Content**: How test/ connects to process framework, directory conventions, relationship between automated/, specifications/, manual-testing/, audits/

- [ ] **🚨 CHECKPOINT**: Script tested, guide reviewed

### Phase 4: Documentation & State Updates (Session 2 continued)
**Priority**: MEDIUM — Update all references

- [ ] **Update feature 4.1.1 state file**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Scope**: All `tests/` → `test/automated/` paths, Code Inventory section, note deleted .md files

- [ ] **Update documentation-map.md**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Scope**: Test audit links, removed .md file references, new guide reference

- [ ] **Update README.md**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Scope**: Test command examples (Run-Tests.ps1 instead of run_tests.py)

- [ ] **Update test-tracking.md**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Scope**: Audit report path references (now `test/audits/` instead of `doc/product-docs/test-audits/`)

- [ ] **Update task definitions**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Tasks**: PF-TSK-053 (add test infrastructure guide ref), PF-TSK-064 (add test discovery step), PF-TSK-066 (add test migration step), PF-TSK-030 (update audit output path)

- [ ] **Update `New-TestAuditReport.ps1`**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct
  - **Scope**: Output path from `doc/product-docs/test-audits/` to `test/audits/`

- [ ] **Let LinkWatcher handle markdown link updates**
  - **Status**: NOT_STARTED
  - **Notes**: Verify LinkWatcher is running; it handles moved .md files automatically

- [ ] **Run `Validate-StateTracking.ps1` — 0 errors**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct

- [ ] **Run `Validate-TestTracking.ps1` — 0 errors**
  - **Status**: NOT_STARTED
  - **Delegated To**: PF-TSK-014 direct

- [ ] **🚨 CHECKPOINT**: All validation passes

## Session Tracking

### Session 1: 2026-03-16
**Focus**: Proposal & State File Creation
**Completed**:
- Structure Change Proposal (PF-PRO-006) created and iterated to v2.0
- Scope assessment: Full Process confirmed
- Structure Change State Tracking File (PF-STA-055) created

**Issues/Blockers**:
- None

**Next Session Plan**:
- Execute Phase 1 (Physical Consolidation) + Phase 2 (Ad-hoc Test Formalization)

## Testing & Validation

### Test Cases

| Test Case | Description | Expected Result | Actual Result | Status |
|-----------|-------------|----------------|---------------|--------|
| TC-001 | Run `pytest` from project root | All 247+ tests discovered and pass from `test/automated/` | — | PENDING |
| TC-002 | Run `Run-Tests.ps1 -Unit` | Unit tests execute from `test/automated/unit/` | — | PENDING |
| TC-003 | Run `Run-Tests.ps1 -Integration` | Integration tests execute from `test/automated/integration/` | — | PENDING |
| TC-004 | Run `Run-Tests.ps1 -Parsers` | Parser tests execute from `test/automated/parsers/` | — | PENDING |
| TC-005 | Run `Run-Tests.ps1 -Performance` | Performance tests execute from `test/automated/performance/` | — | PENDING |
| TC-006 | Run `Run-Tests.ps1 -Coverage` | Coverage report generates for `linkwatcher` module | — | PENDING |
| TC-007 | Run `Setup-TestEnvironment.ps1` for MT-001 | Copies from `test/manual-testing/templates/` correctly | — | PENDING |
| TC-008 | Run `Validate-StateTracking.ps1` | 0 errors across all surfaces | — | PENDING |
| TC-009 | Run `Validate-TestTracking.ps1` | 0 errors, consistent with disk | — | PENDING |
| TC-010 | Run `flake8 linkwatcher test/automated` | Linting works with new path | — | PENDING |
| TC-011 | Verify test audit reports in `test/audits/` | All 7 reports accessible, test-tracking.md references valid | — | PENDING |
| TC-012 | Verify new MT-GRP groups | Registered in test-tracking.md with IDs from id-registry.json | — | PENDING |

### Success Criteria

- [ ] All 247+ automated tests pass with 0 failures
- [ ] `Run-Tests.ps1` works with all category flags
- [ ] `Validate-StateTracking.ps1` reports 0 errors
- [ ] `Validate-TestTracking.ps1` reports 0 errors
- [ ] Only 1 test-related directory (`test/`) at project root
- [ ] No references to `tests/`, `manual-tests/`, `manual_markdown_tests/` in active codebase
- [ ] Feature 4.1.1 state file reflects `test/automated/` paths
- [ ] Test audit reports accessible in `test/audits/`
- [ ] New MT-GRP groups registered with IDs from id-registry.json

## Rollback Information

### Rollback Triggers

- Tests fail after move and cannot be fixed within 30 minutes
- CI/CD pipeline breaks in ways that aren't simple path fixes
- Python import resolution issues requiring architectural changes

### Rollback Procedure

1. `git checkout -- .` to restore all modified files
2. `git clean -fd test/` to remove any new files in test/
3. Verify `tests/` is restored and all tests pass
4. Document what went wrong for next attempt

## State File Updates Required

- [ ] **Documentation Map**: Update test audit links, remove deleted .md refs, add new guide
  - **Status**: PENDING

- [ ] **Feature 4.1.1 State**: Update all `tests/` → `test/automated/` paths
  - **Status**: PENDING

- [ ] **Test Tracking**: Update audit report path references
  - **Status**: PENDING

- [ ] **Test Registry**: Update ~30 filePath entries
  - **Status**: PENDING

- [ ] **Task Definitions**: Update PF-TSK-053, PF-TSK-064, PF-TSK-066, PF-TSK-030
  - **Status**: PENDING

## Completion Criteria

This temporary state file can be moved to `doc/process-framework/state-tracking/temporary/old/` when:

- [ ] All 4 phases completed successfully
- [ ] All 12 test cases pass
- [ ] All success criteria met
- [ ] All state file updates completed
- [ ] Task definitions updated
- [ ] Feedback forms completed for PF-TSK-014

## Notes and Decisions

### Key Decisions Made
- **v2.0 proposal**: Eliminated 6 proposed templates — framework already has what's needed (test-registry.yaml, test-tracking.md, PF-TEM-054, test-file-template.py)
- **No new task**: Test infrastructure setup absorbed into onboarding tasks (PF-TSK-064/066) and PF-TSK-053
- **`test/automated/`**: Automated pytest code grouped under `automated/` subdirectory for clear separation from specifications, manual tests, and audits
- **PD-BUG-* scripts**: Moved to `test/automated/bug-validation/` (they're Python scripts, not manual test cases)
- **4 .md files deleted**: README.md (60% redundant), TEST_PLAN.md (80% stale), TEST_CASE_STATUS.md (95% redundant), TEST_CASE_TEMPLATE.md (framework has equivalents)
- **Run-Tests.ps1**: Project-agnostic PowerShell script in `scripts/test/` replaces hard-coded `run_tests.py`
- **Ad-hoc tests formalized via PF-TSK-069**: IDs from id-registry.json, not copied from old naming
