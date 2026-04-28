---
id: PD-REF-085
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
refactoring_scope: Add warning log for unknown keys in _from_dict() config loading
target_area: src/linkwatcher/config/settings.py
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: Add warning log for unknown keys in _from_dict() config loading

- **Target Area**: src/linkwatcher/config/settings.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD069 — Log warning for unknown config keys in _from_dict()

**Scope**: `_from_dict()` silently ignores unknown keys, so config file typos (e.g., `dry_run` instead of `dry_run_mode`) go undetected. Add a `logger.warning()` for each key in the input dict that doesn't match a dataclass field, so users get feedback about typos.

**Changes Made**:
- [x] Added `import logging` and module-level `logger` to settings.py
- [x] Added unknown-key detection loop in `_from_dict()` that logs `logger.warning()` for each unrecognized key
- [x] Changed existing `hasattr(config, key)` to `key in known_fields` for precision (also mitigates TD076 dunder risk)
- [x] Added `test_from_dict_warns_on_unknown_keys` test in test_config.py

**Test Baseline**: 46 passed (test_config.py), 592 passed / 5 skipped / 7 xfailed (full suite)
**Test Result**: 47 passed (test_config.py), 592 passed / 5 skipped / 7 xfailed (full suite) — no regressions

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.3) updated, or N/A — N/A, grepped state file: only mentions `_from_dict()` for list→set conversion which is unchanged
- [x] TDD (0.1.3) updated, or N/A — N/A, 0.1.3 is Tier 1, no TDD exists
- [x] Test spec (0.1.3) updated, or N/A — N/A, grepped test spec: references `test_from_dict` which still passes; new test adds coverage not in spec
- [x] FDD (0.1.3) updated, or N/A — N/A, 0.1.3 is Tier 1, no FDD exists
- [x] ADR (0.1.3) updated, or N/A — N/A, grepped ADR directory: no references to `_from_dict`
- [x] Validation tracking updated, or N/A — N/A, 0.1.3 validation is COMPLETED in Round 2; minor warning addition doesn't affect validation scores
- [x] Technical Debt Tracking: TD069 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD069 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
