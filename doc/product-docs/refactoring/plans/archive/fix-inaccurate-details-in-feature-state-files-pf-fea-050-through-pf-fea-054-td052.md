---
id: PD-REF-065
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-13
updated: 2026-03-13
target_area: Feature State Files
refactoring_scope: Fix inaccurate details in feature state files PF-FEA-050 through PF-FEA-054 (TD052)
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: Fix inaccurate details in feature state files PF-FEA-050 through PF-FEA-054 (TD052)

- **Target Area**: Feature State Files
- **Priority**: Medium
- **Created**: 2026-03-13
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (documentation-only, no code changes, no architectural impact)

## Item 1: TD052 — Fix inaccurate details in PF-FEA-050 (2.1.1 Link Parsing System)

**Scope**: Fix parser count (6→7 for PowerShell), stale consolidation status, wrong abstract method name, missing test spec, stale Next Steps.

**Changes Made**:
- [x] Section 1 Scope: Changed "6 format-specific parsers" to "7 format-specific parsers" (PowerShell added)
- [x] Section 2 What's Working: Changed "All 6 format-specific parsers" to "All 7"
- [x] Section 2: Updated Current Task from "Feature Consolidation" to "None (maintenance)"
- [x] Section 2: Cleared In Progress (was: feature consolidation)
- [x] Section 4: Added test spec PF-TSP-039 to Design Documentation table
- [x] Section 7 Decision 3: Fixed "abstract `parse()` method" → "abstract `parse_content()` method"
- [x] Section 9: Updated Next Steps — PF-TSP-039 already exists

**Test Baseline**: N/A — documentation-only changes
**Test Result**: N/A

**Bugs Discovered**: None

## Item 2: TD052 — Fix inaccurate details in PF-FEA-051 (2.2.1 Link Updating)

**Scope**: Fix wrong FileOperation API description, stale status, wrong method names, missing colorama dependency, missing test spec, stale Next Steps.

**Changes Made**:
- [x] Section 1 Description: Fixed "receives a `FileOperation`" → receives `LinkReference` list + separate `old_path`, `new_path` strings; added PathResolver mention
- [x] Section 2: Updated Current Task from "Feature Consolidation" to "None (maintenance)"
- [x] Section 2: Cleared In Progress
- [x] Section 4: Added test spec PF-TSP-040 to Design Documentation table
- [x] Section 6 System Dependencies: Added `colorama ≥0.4` (imported in updater.py for dry-run output)
- [x] Section 7 Implementation Patterns: Fixed `LinkUpdater.update_file()` → `LinkUpdater._write_file_safely()`
- [x] Section 7 Implementation Patterns: Fixed `LinkUpdater._apply_replacements()` → `LinkUpdater._update_file_references()`
- [x] Section 9: Updated Next Steps — PF-TSP-040 already exists

**Test Baseline**: N/A — documentation-only changes
**Test Result**: N/A

**Bugs Discovered**: None

## Item 3: TD052 — Fix inaccurate details in PF-FEA-052 (3.1.1 Logging System)

**Scope**: Fix stale status, missing test file, missing test spec, stale Next Steps.

**Changes Made**:
- [x] Section 2: Updated Current Task from "Feature Consolidation" to "None (maintenance)"
- [x] Section 2: Cleared In Progress
- [x] Section 4: Added test spec PF-TSP-041 to Design Documentation table
- [x] Section 5 Test Files: Added missing `test_advanced_logging.py` row
- [x] Section 9: Updated Next Steps — PF-TSP-041 already exists

**Test Baseline**: N/A — documentation-only changes
**Test Result**: N/A

**Bugs Discovered**: None

## Item 4: TD052 — Fix inaccurate details in PF-FEA-053 (4.1.1 Test Suite)

**Scope**: Fix wrong marker name, stale status, ghost test files, wrong test spec claims, stale Next Steps.

**Changes Made**:
- [x] Section 1 Description: Fixed "slow, windows, etc." → full marker list (10 markers correctly enumerated)
- [x] Section 2: Updated Current Task from "Feature Consolidation" to "None (maintenance)"
- [x] Section 2: Cleared In Progress; updated parser count from 6 to 7
- [x] Section 4: Added test spec PF-TSP-042 to Design Documentation table
- [x] Section 5 Key Test Files: Removed 3 ghost entries (test_handler.py, test_models.py, test_utils.py); added 3 actual files (test_advanced_logging.py, test_lock_file.py, test_parser.py)
- [x] Section 8: Updated tech debt row — all 9 test specs now exist (PF-TSP-035 through PF-TSP-043)
- [x] Section 9: Updated Next Steps — all test specs already created

**Test Baseline**: N/A — documentation-only changes
**Test Result**: N/A

**Bugs Discovered**: None

## Item 5: TD052 — Fix inaccurate details in PF-FEA-054 (5.1.1 CI/CD & Development Tooling)

**Scope**: Fix wrong CI job names, wrong pre-commit hook list (mypy not in pre-commit), stale status, missing test spec, stale Next Steps.

**Changes Made**:
- [x] Section 1 Description: Fixed CI job names from "lint, test, coverage, security, build" → "test, performance, quality, security, build"
- [x] Section 1 Description: Fixed pre-commit hooks from "black, isort, flake8, mypy" → "black, isort, flake8, pytest-quick"; noted mypy is CI-only
- [x] Section 1 Scope: Fixed job names and pre-commit hook list
- [x] Section 2: Updated Current Task from "Feature Consolidation" to "None (maintenance)"
- [x] Section 2: Cleared In Progress; updated What's Working with correct job names and hook list
- [x] Section 4: Added test spec PF-TSP-043 to Design Documentation table
- [x] Section 5 Code Inventory: Fixed CI job names and pre-commit hook list
- [x] Section 7 Decision 3: Fixed pre-commit hook list; noted mypy is CI-only
- [x] Section 9: Updated Next Steps — PF-TSP-043 already exists

**Test Baseline**: N/A — documentation-only changes
**Test Result**: N/A

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Feature State | Status | Bugs Found | Corrections |
|------|---------|---------------|--------|------------|-------------|
| 1 | TD052 | PF-FEA-050 (2.1.1) | Complete | None | 7 corrections |
| 2 | TD052 | PF-FEA-051 (2.2.1) | Complete | None | 8 corrections |
| 3 | TD052 | PF-FEA-052 (3.1.1) | Complete | None | 5 corrections |
| 4 | TD052 | PF-FEA-053 (4.1.1) | Complete | None | 6 corrections |
| 5 | TD052 | PF-FEA-054 (5.1.1) | Complete | None | 9 corrections |

**Total**: 35 corrections across 5 feature state files.

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
- [Validation Report PF-VAL-043](/doc/product-docs/validation/reports/documentation-alignment/PD-VAL-043-documentation-alignment-features-2.1.1-2.2.1-3.1.1-4.1.1-5.1.1.md)
- [TD047 Refactoring Plan (PF-FEA-046 through PF-FEA-049)](/doc/product-docs/refactoring/plans/fix-inaccurate-details-in-feature-state-files-pf-fea-046-through-pf-fea-049-td047.md)
