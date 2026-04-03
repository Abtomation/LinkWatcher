---
id: PD-REF-160
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-03
updated: 2026-04-03
target_area: test/automated/unit/test_validator.py
mode: lightweight
refactoring_scope: Cover 11 remaining uncovered lines in validator.py (96% to ~100%)
priority: Medium
---

# Lightweight Refactoring Plan: Cover 11 remaining uncovered lines in validator.py (96% to ~100%)

- **Target Area**: test/automated/unit/test_validator.py
- **Priority**: Medium
- **Created**: 2026-04-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD170 — Cover 11 remaining uncovered lines in validator.py

**Scope**: Add test cases to test_validator.py covering 11 uncovered lines in validator.py (96% → ~100%). Lines: 405 (code block standalone skip), 481 (_should_check_target separator-but-no-extension fallback), 527-531 (archival details same-line summary), 632-633 (OSError in .linkwatcherignore loading), 659-662 (pure anchor link #section).

**Debt Item ID**: TD170
**Dims**: TST

**Changes Made**:
- [x] Test: fixed existing `test_standalone_link_in_code_block_skipped` to use path not caught by `validation_ignored_patterns`, now exercises line 405
- [x] Test: added parametrize case `("some/dir", "markdown")` to `TestShouldCheckTarget.test_target_skipped` for line 481
- [x] Test: added `test_details_summary_on_same_line` to `TestArchivalDetailsFilter` for lines 527-531
- [x] Test: added `test_oserror_reading_ignore_file_handled` to `TestLinkwatcherIgnoreFile` for lines 632-633
- [x] Test: added `TestTargetExistsPureAnchor` class with 2 tests for lines 659-662

**Test Baseline**: 102 passed, 0 failed. Coverage: 96% (11 lines missing: 405, 481, 527-531, 632-633, 659-662)
**Test Result**: 107 passed, 0 failed. Coverage: 100% (0 lines missing). Full regression suite: all tests pass.

**Documentation & State Updates**:
- [x] Feature implementation state file (6.1.1) updated, or N/A: _N/A — state file references validator.py and test_validator.py but only tracks creation/phase status, not per-method coverage. No design or behavioral change._
- [x] TDD (6.1.1) updated, or N/A: _N/A — 6.1.1 is Tier 1, no TDD exists._
- [x] Test spec (6.1.1) updated, or N/A: _N/A — grepped test/specifications for "validator", no test spec exists for 6.1.1._
- [x] FDD (6.1.1) updated, or N/A: _N/A — 6.1.1 is Tier 1, no FDD exists._
- [x] ADR updated, or N/A: _N/A — no architectural decision affected by adding test coverage._
- [x] Validation tracking updated, or N/A: _N/A — no active validation round for 6.1.1._
- [x] Technical Debt Tracking: TD170 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD170 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
