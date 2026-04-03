---
id: PD-REF-138
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
mode: lightweight
refactoring_scope: Promote common_extensions local set to module-level frozenset in looks_like_file_path()
target_area: linkwatcher/utils.py
priority: Medium
---

# Lightweight Refactoring Plan: Promote common_extensions local set to module-level frozenset in looks_like_file_path()

- **Target Area**: linkwatcher/utils.py
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD141 — Promote common_extensions to module-level frozenset

**Scope**: `looks_like_file_path()` in `linkwatcher/utils.py` rebuilds a 35-element `common_extensions` set as a local variable on every call. This function is called from all 7 parsers (via `base.py._looks_like_file_path()`) and from `validator.py`, potentially hundreds of times per scan. Promote to module-level `frozenset` to avoid repeated allocation. Dims: PE (Performance).

**Changes Made**:
- [x] Moved `common_extensions` set from inside `looks_like_file_path()` to module-level `_COMMON_EXTENSIONS` frozenset (linkwatcher/utils.py)
- [x] Updated reference inside function from `common_extensions` to `_COMMON_EXTENSIONS`

**Test Baseline**: 645 passed, 5 skipped, 4 deselected, 6 xfailed
**Test Result**: 645 passed, 5 skipped, 4 deselected, 6 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1) updated, or N/A — verified no reference to changed component: _N/A — grepped feature state files; references are to `looks_like_file_path()` function name, not internal variable. No update needed._
- [x] TDD (0.1.1) updated, or N/A — verified no interface/design changes documented: _N/A — grepped TDDs; only references function name in dependency lists. Internal variable promotion doesn't change interface._
- [x] Test spec (0.1.1) updated, or N/A — verified no behavior change affects spec: _N/A — grepped test specs; only `test_all_common_extensions_are_monitored` in 1.1.1 spec references extensions but tests the service, not utils. No behavior change._
- [x] FDD (0.1.1) updated, or N/A — verified no functional change affects FDD: _N/A — grepped FDDs; no references to common_extensions or looks_like_file_path._
- [x] ADR updated, or N/A — verified no architectural decision affected: _N/A — grepped ADR directory; no references to changed component._
- [x] Validation tracking updated, or N/A — verified feature is not tracked in a validation round or change doesn't affect validation: _N/A — internal performance optimization doesn't affect validation criteria._
- [ ] Technical Debt Tracking: TD item marked resolved

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD141 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

