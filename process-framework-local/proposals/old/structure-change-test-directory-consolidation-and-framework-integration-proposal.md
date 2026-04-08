---
id: PF-PRO-006
type: Document
category: Proposal
version: 2.0
created: 2026-03-16
updated: 2026-03-16
---

# Structure Change Proposal: Test Directory Consolidation & Framework Integration

## Overview

Consolidate 4 test directories (`test/`, `tests/`, `manual-tests/`, `manual_markdown_tests/`) into a single unified `test/` directory. Eliminate redundant documentation, formalize ad-hoc tests into the manual testing framework, relocate test audits, create a project-agnostic test runner script, and integrate test infrastructure setup into existing onboarding tasks.

**Structure Change ID:** SC-006
**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-03-16
**Target Implementation Date:** TBD

## Current Structure

Four separate test directories at the project root with no structural bridge between the process framework's test governance and the product's test implementation:

```
project-root/
├── test/                           # Process framework test governance
│   ├── specifications/feature-specs/   # 9 test specifications (PF-TSP-*)
│   ├── test-registry.yaml              # Central registry (PD-TST-*)
│   └── manual-testing/                 # Formal manual test framework (MT-*)
│       ├── templates/                  #   Pristine test fixtures (MT-GRP-01)
│       ├── workspace/                  #   Generated working copies (gitignored)
│       └── results/                    #   Execution logs (gitignored)
│
├── tests/                          # Product test code (feature 4.1.1)
│   ├── unit/                           # 35+ test methods
│   ├── integration/                    # 45+ test methods
│   ├── parsers/                        # 80+ test methods
│   ├── performance/                    # 5+ test methods
│   ├── manual/                         # 13 bug validation scripts
│   ├── fixtures/                       # 3 static test data files
│   ├── conftest.py, utils.py, __init__.py, test_*.py
│   ├── README.md                       # REDUNDANT — duplicates framework guides
│   ├── TEST_PLAN.md                    # STALE — duplicates test specs + TDDs
│   ├── TEST_CASE_STATUS.md             # REDUNDANT — triple-tracks test-registry.yaml + test-tracking.md
│   └── TEST_CASE_TEMPLATE.md           # REDUNDANT — framework has PF-TEM-054
│
├── manual-tests/                   # Ad-hoc (orphan, untracked)
│   └── powershell-parser/              # 3 files: PS parser pattern tests
│
├── manual_markdown_tests/          # Ad-hoc (orphan, untracked)
│   ├── MP-*.md, LR-*.md (12 files)     # Markdown parser test scenarios
│   ├── test_runner.py                  # Interactive test runner (LW-specific)
│   └── test_project/                   # Simulated project with special-char filenames
│
├── doc/test-audits   # Test audit reports (7 files)
│   ├── foundation/                     # 3 audit reports (features 0.x.x)
│   ├── authentication/                 # 1 audit report (feature 1.1.1)
│   └── core-features/                  # 3 audit reports (features 2.x.x, 3.x.x)
│
└── run_tests.py                    # Python test runner (product-specific)
```

### Problems with Current Structure

1. **No bridge**: Process framework (`test/`) and product tests (`tests/`) are disconnected — feature 4.1.1's state file points to `tests/` but the framework governs `test/`
2. **Orphan directories**: `manual-tests/` and `manual_markdown_tests/` are untracked by any framework artifact
3. **Duplicated purpose**: `tests/manual/` (bug validations) and `test/manual-testing/` (formal MT-* cases) both do manual testing with no clear relationship
4. **Redundant documentation**: 4 markdown files in `tests/` (~1,200 lines) duplicate information already tracked by the process framework:
   - `TEST_CASE_STATUS.md` triple-tracks what test-registry.yaml + test-tracking.md already cover
   - `TEST_PLAN.md` is stale (last updated 2025-01-27) and duplicates individual test specifications
   - `TEST_CASE_TEMPLATE.md` duplicates PF-TEM-054 (manual-test-case-template) and `test-file-template.py` (automated test template used by `New-TestFile.ps1`)
   - `README.md` duplicates process framework guides and state tracking
5. **Test audits separated from tests**: Audit reports about test quality live in `doc/test-audits` instead of near the tests they evaluate
6. **Product-specific test runner**: `run_tests.py` is a Python script with hard-coded paths; a project-agnostic PowerShell equivalent would serve the framework better

## Proposed Structure

### Directory Layout

```
test/                               # Single unified test directory
├── specifications/feature-specs/   # [KEPT] Test specifications (PF-TSP-*)
├── test-registry.yaml              # [KEPT] Central registry (PD-TST-*)
├── manual-testing/                 # [KEPT+EXPANDED] Formal manual test framework (MT-*)
│   ├── templates/
│   │   ├── powershell-regex-preservation/      # [KEPT] MT-GRP-01
│   │   ├── powershell-parser-patterns/         # [NEW] MT-GRP-02 (from manual-tests/)
│   │   └── markdown-parser-scenarios/          # [NEW] MT-GRP-03 (from manual_markdown_tests/)
│   ├── workspace/                  # [KEPT] Generated (gitignored)
│   └── results/                    # [KEPT] Logs (gitignored)
│
├── audits/                         # [MOVED from doc/test-audits/]
│   ├── foundation/                 #   Features 0.x.x
│   ├── authentication/             #   Feature 1.1.1
│   └── core-features/              #   Features 2.x.x, 3.x.x
│
├── automated/                      # [NEW grouping] All pytest-discovered test code
│   ├── unit/                       # [MOVED from tests/unit/]
│   ├── integration/                # [MOVED from tests/integration/]
│   ├── parsers/                    # [MOVED from tests/parsers/]
│   ├── performance/                # [MOVED from tests/performance/]
│   ├── bug-validation/             # [MOVED from tests/manual/] PD-BUG-* regression scripts
│   ├── fixtures/                   # [MOVED from tests/fixtures/, expanded]
│   │   └── special-characters/     # [NEW] From manual_markdown_tests/test_project/
│   ├── conftest.py                 # [MOVED from tests/conftest.py]
│   ├── utils.py                    # [MOVED from tests/utils.py]
│   ├── __init__.py                 # [MOVED from tests/__init__.py]
│   ├── test_config.py              # [MOVED from tests/test_config.py]
│   ├── test_move_detection.py      # [MOVED from tests/test_move_detection.py]
│   └── test_directory_move_detection.py # [MOVED from tests/test_directory_move_detection.py]
```

### What Happens to Each Source

| Source | Destination | Action |
|--------|------------|--------|
| `test/` (existing content) | `test/` | Kept in place |
| `tests/unit/`, `integration/`, `parsers/`, `performance/` | `test/automated/` (same subdirs) | Moved into `automated/` grouping |
| `tests/conftest.py`, `utils.py`, `__init__.py`, `test_*.py` | `test/automated/` | Moved into `automated/` |
| `tests/fixtures/` | `test/automated/fixtures/` | Moved into `automated/` |
| `tests/manual/` (PD-BUG-* regression scripts) | `test/automated/bug-validation/` | Moved into `automated/` (these are Python scripts, not manual test cases) |
| `tests/README.md` | — | **Deleted** (60% redundant with framework guides; "AI notes" moved to conftest.py comment) |
| `tests/TEST_PLAN.md` | — | **Deleted** (80% stale/redundant with test specs + TDDs) |
| `tests/TEST_CASE_STATUS.md` | — | **Deleted** (95% redundant with test-registry.yaml + test-tracking.md) |
| `tests/TEST_CASE_TEMPLATE.md` | — | **Deleted** (framework has PF-TEM-054 for manual tests, `test-file-template.py` + `New-TestFile.ps1` for automated tests) |
| `doc/test-audits` | `test/audits/` | Moved (audit reports belong near the tests they evaluate) |
| `manual-tests/powershell-parser/` | `test/manual-testing/templates/` | Formalized as MT-GRP-* via PF-TSK-069 (Manual Test Case Creation) using `New-ManualTestCase.ps1` for proper ID assignment from id-registry.json |
| `manual_markdown_tests/` (MP-*, LR-* scenarios) | `test/manual-testing/templates/` | Formalized as MT-GRP-* via PF-TSK-069 using `New-ManualTestCase.ps1` for proper ID assignment from id-registry.json |
| `manual_markdown_tests/test_project/` special-char files | `test/automated/fixtures/special-characters/` | Extracted as reusable automated test fixtures |
| `manual_markdown_tests/test_runner.py` | — | **Deleted** (LinkWatcher-specific debugging tool, not generalizable) |
| `run_tests.py` | — | **Replaced** by project-agnostic `Run-Tests.ps1` in process framework |

### Framework Additions

```
process-framework/
├── scripts/test/
│   └── Run-Tests.ps1               # [NEW] Project-agnostic test runner
│                                    #   Reads project-config.json for module name,
│                                    #   test directory, and test categories.
│                                    #   Wraps pytest with --unit/--integration/etc.
│
└── guides/guides/03-testing/
    └── test-infrastructure-guide.md # [NEW] How test/ connects to the process
                                     #   framework, directory conventions, fixture
                                     #   patterns, relationship to test-registry.yaml
                                     #   and test-tracking.md
```

**No new templates.** The process framework already has:
- Test specification template (PF-TEM for test specs)
- Manual test case template (PF-TEM-054)
- Manual master test template (PF-TEM-053)
- Test-registry.yaml as the central test registry
- Test-tracking.md as the workflow status tracker

The deleted .md files (TEST_PLAN, TEST_CASE_STATUS, README, TEST_CASE_TEMPLATE) were redundant with these existing framework artifacts. No replacements needed.

## Rationale

### Benefits

1. **Single source of truth**: One `test/` directory contains everything — framework governance (specs, registry, manual tests, audits) AND product test code (unit, integration, etc.)
2. **Feature 4.1.1 bridge**: Product test infrastructure lives inside the framework-governed `test/` directory, not in a disconnected `tests/` directory
3. **Eliminated redundancy**: ~1,200 lines of redundant/stale documentation removed (4 .md files that duplicated test-registry.yaml, test-tracking.md, test specs, and framework templates)
4. **Eliminated orphans**: `manual-tests/` and `manual_markdown_tests/` formalized as proper MT-GRP-* groups via PF-TSK-069 with IDs from id-registry.json
5. **Test audits co-located**: Audit reports live near the tests they evaluate, not in a separate doc tree
6. **Clearer naming**: `tests/manual/` (PD-BUG-* regression scripts) moved to `test/automated/bug-validation/` — clearly separated from `test/manual-testing/` (formal MT-* cases)
7. **Task alignment**: All existing tasks already reference `test/` — the consolidation brings reality in line with task definitions
8. **Project-agnostic test runner**: `Run-Tests.ps1` reads `project-config.json` instead of hard-coding paths

### Challenges

1. **Configuration updates**: `pytest.ini`, `pyproject.toml` hard-code `tests/` as testpaths — must change to `test/automated`
2. **CI/CD pipeline**: `.github/workflows/ci.yml` references `tests` in flake8/black/isort commands
3. **test-registry.yaml**: All `filePath` entries use `../tests/` or `tests/` relative paths — must update to `test/automated/` paths
4. **Feature 4.1.1 state file**: References `tests/` throughout
5. **Documentation references**: 60+ files reference `tests/` paths (LinkWatcher handles markdown links automatically)
6. **Manual test formalization**: Creating new MT-GRP groups requires following PF-TSK-069 process with `New-ManualTestCase.ps1` for proper ID assignment from id-registry.json

## Affected Files

### Configuration & Scripts (must update paths)

| File | Change |
|------|--------|
| `pytest.ini` | `testpaths = tests` → `testpaths = test/automated` |
| `pyproject.toml` | `testpaths = ["tests"]` → `testpaths = ["test/automated"]` |
| `.github/workflows/ci.yml` | `flake8 linkwatcher tests` → `flake8 linkwatcher test/automated` (same for black, isort) |

### Files Deleted

| File | Reason |
|------|--------|
| `tests/README.md` | 60% redundant with process framework guides |
| `tests/TEST_PLAN.md` | 80% stale; duplicates test specs + TDDs |
| `tests/TEST_CASE_STATUS.md` | 95% redundant with test-registry.yaml + test-tracking.md |
| `tests/TEST_CASE_TEMPLATE.md` | Redundant with PF-TEM-054 |
| `run_tests.py` | Replaced by project-agnostic `Run-Tests.ps1` |
| `manual_markdown_tests/test_runner.py` | LinkWatcher-specific debugging tool |

### Files Replaced

| Old | New |
|-----|-----|
| `run_tests.py` (Python, hard-coded) | `process-framework/scripts/test/Run-Tests.ps1` (PowerShell, project-agnostic) |

### Test Registry (path updates)

- `test/test-registry.yaml` — ~30 entries with `filePath` patterns needing update

### Feature State File

- `process-framework-local/state-tracking/features/4.1.1-test-suite-implementation-state.md` — all `tests/` references

### Test Audit Reports (path updates after move)

- 7 audit reports moving from `doc/test-audits` to `test/audits/`
- References in `test-tracking.md` (audit report paths in ~20 entries)
- References in `PF-documentation-map.md`

### Documentation (LinkWatcher handles markdown links automatically)

- Feature state files (9) — references to test directories
- Validation reports (10) — references to test paths
- Process framework `PF-documentation-map.md` — test document links, test audit links
- Project `README.md` — test command examples

## Migration Strategy

### Phase 1: Physical Consolidation (Session 1)

Move files, update configs, ensure tests pass.

1. Create `test/automated/` directory
2. Move all code content from `tests/` into `test/automated/` (unit/, integration/, parsers/, performance/, fixtures/, conftest.py, utils.py, __init__.py, test_*.py)
3. Move `tests/manual/` (PD-BUG-* regression scripts) to `test/automated/bug-validation/`
4. Delete the 4 redundant .md files (README, TEST_PLAN, TEST_CASE_STATUS, TEST_CASE_TEMPLATE)
5. Move `doc/test-audits` to `test/audits/`
6. Update `pytest.ini`: `testpaths = test/automated`
7. Update `pyproject.toml`: `testpaths = ["test/automated"]`
8. Update `.github/workflows/ci.yml`: flake8/black/isort paths to `test/automated`
9. Update `test/test-registry.yaml`: all `filePath` entries
10. Run `pytest` — verify all 247+ tests pass
11. Delete empty `tests/` directory
12. **CHECKPOINT**: Tests pass, no regressions

### Phase 2: Ad-hoc Test Formalization (Session 1 continued)

Formalize orphan directories into the manual testing framework using the **Manual Test Case Creation task (PF-TSK-069)**.

> **CRITICAL**: All MT-GRP and MT IDs must be assigned from `id-registry.json` via `New-ManualTestCase.ps1`. Do NOT reuse or copy IDs from the ad-hoc test files — the old MP-001/LR-001 naming is ad-hoc and not part of the framework ID system.

1. Follow PF-TSK-069 process to formalize `manual-tests/powershell-parser/` as a new MT-GRP in `test/manual-testing/templates/` — use `New-ManualTestCase.ps1` for proper ID assignment
2. Follow PF-TSK-069 process to formalize `manual_markdown_tests/` MP-*/LR-* scenarios as a new MT-GRP in `test/manual-testing/templates/` — use `New-ManualTestCase.ps1` for proper ID assignment
3. Extract special-character filename fixtures from `manual_markdown_tests/test_project/` to `test/automated/fixtures/special-characters/`
4. Delete `manual-tests/` and `manual_markdown_tests/`
5. Verify test-tracking.md was updated by `New-ManualTestCase.ps1` with new MT-GRP entries
6. **CHECKPOINT**: All 4 source directories resolved, 0 orphan test directories remain

### Phase 3: Framework Script & Guide (Session 2)

Create the project-agnostic test runner and infrastructure guide.

1. Create `process-framework/scripts/test/Run-Tests.ps1` — project-agnostic test runner that reads `project-config.json` for module name, test directory, and test categories
2. Delete `run_tests.py`
3. Create `process-framework/guides/guides/03-testing/test-infrastructure-guide.md` — how `test/` connects to the process framework (directory conventions, relationship between `test/automated/`, `test/specifications/`, `test/manual-testing/`, `test/audits/`, `test-registry.yaml`, and `test-tracking.md`)
4. **CHECKPOINT**: Script tested, guide reviewed

### Phase 4: Documentation & State Updates (Session 2 continued)

Update all references across the codebase.

1. Update feature 4.1.1 state file — all `tests/` → `test/automated/` paths, update Code Inventory
2. Update `PF-documentation-map.md` — test audit links, removed .md files, new guide
3. Update `README.md` — test command examples (use `Run-Tests.ps1` instead of `run_tests.py`)
4. Update test-tracking.md — audit report path references (now `test/audits/`)
5. Let LinkWatcher handle markdown link updates for moved files
6. Run `Validate-StateTracking.ps1` — verify 0 errors
7. Run `Validate-TestTracking.ps1` — verify consistency
8. **CHECKPOINT**: All validation passes

## Task Modifications

### Integration and Testing (PF-TSK-053)

**Changes needed:**
- Add step in Preparation: "If project has no test infrastructure (conftest.py, pytest.ini), set it up following the [Test Infrastructure Guide] — automated tests go in `test/automated/`"
- Add reference to `Run-Tests.ps1` as the standard test runner
- Reference the test infrastructure guide in Context Requirements (Important section)
- Update test directory references from `test/` to `test/automated/` for automated test file locations

**Rationale:** This task creates test files but currently assumes test infrastructure exists. With the guide, it can bootstrap infrastructure when needed.

### Codebase Feature Discovery (PF-TSK-064) — Onboarding

**Changes needed:**
- Add step: "Identify existing test infrastructure and map it to the framework's `test/` structure"
- Add substep: "If tests exist outside `test/`, plan migration as part of onboarding"

**Rationale:** When adopting the framework into an existing project, existing tests need to be discovered and mapped. This is the natural place for that work — during feature discovery, not in a separate task.

### Retrospective Documentation Creation (PF-TSK-066) — Onboarding

**Changes needed:**
- Add step: "Migrate existing test code into the `test/` directory structure following the Test Infrastructure Guide"
- Add substep: "Create conftest.py and pytest.ini if not present"
- Add substep: "Register existing test files in test-registry.yaml"

**Rationale:** After feature discovery identifies existing tests, the retrospective documentation task is where the actual migration happens — it's already responsible for creating test specifications and other framework artifacts for pre-existing code.

### Feature 4.1.1 Implementation State (PF-FEA-053)

**Changes needed:**
- Update all `tests/` path references to `test/`
- Update Code Inventory (Section 5) with new file locations
- Note that the 4 redundant .md files were deleted

**Rationale:** Feature 4.1.1's code inventory must reflect actual file locations.

## New Tasks

No new tasks. Test infrastructure setup is absorbed into existing onboarding tasks (PF-TSK-064 for discovery, PF-TSK-066 for migration) and PF-TSK-053 (for new projects needing bootstrap).

## Handover Interfaces

No new handover interfaces. The existing task flow is preserved:

| From Task | To Task | Interface | Change |
|-----------|---------|-----------|--------|
| PF-TSK-064 (Feature Discovery) | PF-TSK-066 (Retrospective Docs) | Feature inventory including test infrastructure assessment | Modified — now includes test structure mapping |
| PF-TSK-066 (Retrospective Docs) | PF-TSK-012 (Test Spec Creation) | Migrated test/ directory + test-registry.yaml | Modified — test code now in framework-standard location |
| PF-TSK-053 (Integration & Testing) | PF-TSK-030 (Test Audit) | Test files in test/ + test-registry.yaml | Modified — audit reports now in test/audits/ |

### Additional Tasks to Review

- **Test Audit (PF-TSK-030)** — Update audit report output location from `doc/test-audits` to `test/audits/`. Update `New-TestAuditReport.ps1` script if it hard-codes the output path.
- **Bug Fixing (PF-TSK-007)** — Uses `project-config.json` for test paths; may need config update
- **Manual Test Case Creation (PF-TSK-069)** — Already uses `test/manual-testing/`, no change expected
- **Manual Test Execution (PF-TSK-070)** — Already uses `test/manual-testing/`, no change expected
- **Validation scripts** — `Validate-TestTracking.ps1` and `Validate-StateTracking.ps1` may reference `tests/` or `doc/test-audits` paths

## Testing Approach

### Test Cases

1. **Pytest discovery**: Run `pytest` from project root — all 247+ tests must be discovered and pass from `test/automated/`
2. **Category execution**: Run `Run-Tests.ps1 -Unit`, `-Integration`, `-Parsers`, `-Performance` — each must find and execute correct tests in `test/automated/`
3. **Coverage**: Run `Run-Tests.ps1 -Coverage` — coverage report must generate correctly for `linkwatcher` module
4. **Manual test framework**: Run `Setup-TestEnvironment.ps1` for existing MT-001 — must still copy from `test/manual-testing/templates/`
5. **New manual test groups**: PowerShell and Markdown manual test cases (created via PF-TSK-069) should be executable through the manual testing framework
6. **Validation scripts**: Run `Validate-StateTracking.ps1` and `Validate-TestTracking.ps1` — 0 errors
7. **CI simulation**: Run `flake8 linkwatcher test/automated`, `black --check linkwatcher test/automated`, `isort --check-only linkwatcher test/automated` — must work with new path
8. **Audit report access**: Verify test audit reports are accessible at `test/audits/` and all references in test-tracking.md are valid

### Success Criteria

1. All 247+ automated tests pass with 0 failures
2. `Run-Tests.ps1` works with all category flags
3. `Validate-StateTracking.ps1` reports 0 errors
4. `Validate-TestTracking.ps1` reports 0 errors
5. Only 1 test-related directory (`test/`) exists at project root
6. No references to `tests/`, `manual-tests/`, or `manual_markdown_tests/` remain in active codebase
7. Feature 4.1.1 state file accurately reflects new `test/automated/` paths
8. Test audit reports accessible in `test/audits/`
9. New MT-GRP groups (from formalized ad-hoc tests) registered in test-tracking.md with IDs from id-registry.json

## Rollback Plan

### Trigger Conditions

- Tests fail after move and cannot be fixed within 30 minutes
- CI/CD pipeline breaks in ways that aren't simple path fixes
- Python import resolution issues that require architectural changes

### Rollback Steps

1. `git checkout -- .` to restore all modified files
2. `git clean -fd test/` to remove any new files in test/
3. Verify `tests/` is restored and tests pass
4. Document what went wrong for next attempt

## Resources Required

### Sessions

- **Session 1**: Physical consolidation + ad-hoc test formalization (Phases 1-2)
- **Session 2**: Framework script + guide + documentation updates (Phases 3-4)

### Tools

- LinkWatcher (running in background for automatic markdown link updates)
- `Validate-StateTracking.ps1` / `Validate-TestTracking.ps1` (verification)
- `New-ManualTestCase.ps1` (MT-GRP-02 and MT-GRP-03 formalization)

## Metrics

### Implementation Metrics

- Test-related directories at project root: 4 → 1
- Orphan/untracked test directories: 2 → 0
- Redundant documentation lines removed: ~1,200
- Redundant documentation files removed: 4 (.md) + 1 (run_tests.py) + 1 (test_runner.py)
- New framework artifacts: 1 script (Run-Tests.ps1) + 1 guide (test-infrastructure-guide.md)
- Formal manual test groups: 1 → 3 (2 new groups with IDs from id-registry.json)
- All tests passing: 247+ (no regression)
- Validation script errors: 0

### User Experience Metrics

- Single entry point for all test-related work: `test/`
- Clear separation within: specs / automated tests / manual tests / audits / validation / fixtures
- Reduced documentation maintenance burden (no triple-tracking)
- Project-agnostic test runner available for framework adoption

## Approval

**Approved By:** _________________
**Date:** YYYY-MM-DD

**Comments:**
