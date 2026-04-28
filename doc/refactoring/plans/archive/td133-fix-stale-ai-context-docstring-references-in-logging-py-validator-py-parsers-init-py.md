---
id: PD-REF-134
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
refactoring_scope: TD133: Fix stale AI Context docstring references in logging.py, validator.py, parsers/__init__.py
target_area: linkwatcher module docstrings
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: TD133: Fix stale AI Context docstring references in logging.py, validator.py, parsers/__init__.py

- **Target Area**: linkwatcher module docstrings
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Dependencies and Impact
- **Affected Components**: src/linkwatcher/logging.py, src/linkwatcher/validator.py, src/linkwatcher/parsers/__init__.py
- **Internal Dependencies**: None — docstring-only changes, no code behavior affected
- **Risk Assessment**: Low — only AI Context docstrings are modified

## Item 1: TD133 — Fix stale AI Context docstring references

**Scope**: Three AI Context docstrings reference symbols that no longer exist, misleading AI agents searching for them. Fix: (1) logging.py — remove `LogFilter` reference (no such class; filtering is via `structlog.stdlib.filter_by_level`) and replace `_configure_structlog()` with correct inline structlog config in `LinkWatcherLogger.__init__`; (2) validator.py — replace `_should_skip_target()` with `_should_check_target()`; (3) parsers/__init__.py — replace `LinkParser._get_parser()` with correct routing description (constructor-based `self.parsers` dict).

**Dims**: DA (Documentation Alignment)

**Changes Made**:
- [x] logging.py:65-66: Replaced `LogFilter` and `_configure_structlog()` with `structlog.stdlib.filter_by_level` and `LinkWatcherLogger.__init__`
- [x] validator.py:20: Replaced `_should_skip_target()` with `_should_check_target()`
- [x] parsers/__init__.py:15: Replaced `LinkParser._get_parser()` with `LinkParser.__init__()` (self.parsers dict)

**Test Baseline**: 645 passed, 5 skipped, 4 deselected, 6 xfailed
**Test Result**: 645 passed, 5 skipped, 4 deselected, 6 xfailed (identical — no regression)

**Documentation & State Updates**:
- [x] Feature implementation state file — N/A: _Docstring-only changes, no feature behavior affected_
- [x] TDD — N/A: _Docstring-only changes, no interface/design changes_
- [x] Test spec — N/A: _No behavior change_
- [x] FDD — N/A: _No functional change_
- [x] ADR — N/A: _No architectural decision affected_
- [x] Validation tracking — N/A: _Docstring corrections don't affect validation dimensions_
- [ ] Technical Debt Tracking: TD133 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD133 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
