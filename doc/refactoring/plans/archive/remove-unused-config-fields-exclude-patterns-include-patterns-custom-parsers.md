---
id: PD-REF-072
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-17
updated: 2026-03-17
debt_item: TD059
refactoring_scope: Remove unused config fields exclude_patterns include_patterns custom_parsers
target_area: settings.py, defaults.py
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: Remove unused config fields exclude_patterns include_patterns custom_parsers

- **Target Area**: settings.py, defaults.py
- **Priority**: Medium
- **Created**: 2026-03-17
- **Author**: AI Agent & Human Partner
- **Status**: Completed
- **Debt Item**: TD059
- **Mode**: Lightweight

## Item 1: TD059 — Remove unused config fields

**Scope**: Remove 3 config fields (`exclude_patterns`, `include_patterns`, `custom_parsers`) from `LinkWatcherConfig` that no runtime component ever reads. Their presence creates false expectations — users can set them but nothing happens.

**Changes Made**:
- [x] `settings.py`: Removed 3 field definitions, `_from_dict` special handling for exclude/include_patterns, and exclusion list entries
- [x] `defaults.py`: Removed 3 lines from DEFAULT_CONFIG
- [x] `test_config.py`: Removed `test_config_with_custom_parsers` test, removed exclude/include_patterns from `test_from_dict` and roundtrip test
- [x] `test-spec-0-1-3-configuration-system.md`: Removed custom_parsers test spec row, updated test count 7→6

**Test Baseline**: 458 passed, 5 skipped, 7 xfailed
**Test Result**: 457 passed, 5 skipped, 7 xfailed (1 dead test removed)

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.3) updated, or N/A — _N/A: grepped state file, no reference to these 3 fields_
- [x] TDD (0.1.3) updated, or N/A — _N/A: 0.1.3 is Tier 1, no TDD exists_
- [x] Test spec (0.1.3) updated — removed `test_config_with_custom_parsers` row, updated test count
- [x] FDD (0.1.3) updated, or N/A — _N/A: 0.1.3 is Tier 1, no FDD exists_
- [x] ADR updated, or N/A — _N/A: no ADR references these config fields_
- [x] Foundational validation tracking (0.1.3) updated via Update-TechDebt.ps1 -FoundationalNote
- [x] Technical Debt Tracking: TD059 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD059 | Complete | None | Test spec 0.1.3 updated |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
