---
id: PD-REF-159
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-03
updated: 2026-04-03
refactoring_scope: TD167: Replace tempfile with tmp_path, remove hardcoded extension lists in test_comprehensive_file_monitoring.py
target_area: test/automated/unit/test_comprehensive_file_monitoring.py
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: TD167: Replace tempfile with tmp_path, remove hardcoded extension lists in test_comprehensive_file_monitoring.py

- **Target Area**: test/automated/unit/test_comprehensive_file_monitoring.py
- **Priority**: Medium
- **Created**: 2026-04-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD167 — Replace tempfile with tmp_path, remove hardcoded extension lists

**Scope**: Replace all 7 `tempfile.TemporaryDirectory()` context managers with pytest `tmp_path` fixture. Replace hardcoded extension sets with references to `DEFAULT_CONFIG.monitored_extensions` to prevent drift (4 extensions already missing: `.ps1`, `.psm1`, `.bat`, `.toml`). Dims: TST.

**Changes Made**:
<!-- Fill in after implementation -->
- [x] Convert all 7 methods from `tempfile.TemporaryDirectory` to `tmp_path` fixture parameter
- [x] Remove `import tempfile` import
- [x] Add `from linkwatcher.config.defaults import DEFAULT_CONFIG` import
- [x] Replace hardcoded `expected_extensions` set in `test_all_common_extensions_are_monitored` with `DEFAULT_CONFIG.monitored_extensions`
- [x] Keep category spot-check subsets in `test_extension_coverage_by_category` (intentional spot-checks, not full-set duplicates)

**Test Baseline**: 7 passed, 0 failed (test_comprehensive_file_monitoring.py)
**Test Result**: 7 passed, 0 failed. Full regression: 706 passed, 5 skipped, 4 deselected, 6 xfailed

**Documentation & State Updates**:
- [x] Feature implementation state file (1.1.1) updated, or N/A — _N/A: test-internal refactoring, no changes to feature implementation code_
- [x] TDD (1.1.1) updated, or N/A — _N/A: no interface or design changes, only test fixture replacement_
- [x] Test spec (1.1.1) updated, or N/A — _N/A: no behavior change, same tests verifying same behavior_
- [x] FDD (1.1.1) updated, or N/A — _N/A: no functional change_
- [x] ADR updated, or N/A — _N/A: no architectural decision affected_
- [x] Validation tracking updated, or N/A — _N/A: test-internal change doesn't affect validation_
- [x] Technical Debt Tracking: TD167 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD167 | Complete | None | None (all N/A — test-internal refactoring) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
