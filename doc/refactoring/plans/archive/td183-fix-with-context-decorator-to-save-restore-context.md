---
id: PD-REF-166
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
refactoring_scope: TD183: Fix with_context decorator to save/restore context instead of clearing
priority: Medium
mode: lightweight
target_area: Logging System
---

# Lightweight Refactoring Plan: TD183: Fix with_context decorator to save/restore context instead of clearing

- **Target Area**: Logging System
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD183 — Fix with_context decorator to save/restore context

**Scope**: The `with_context` decorator in `linkwatcher/logging.py:575-590` clears ALL thread-local context in its `finally` block. If nested, the inner decorator wipes the outer's context. Fix: save previous context before setting new, restore it in `finally`. Dimension: CQ (Code Quality).

**Changes Made**:
- [x] Save previous context snapshot before `set_context`, restore in `finally` (`linkwatcher/logging.py:575-592`)
- [x] Add `test_nested_context_decorators` test to `test/automated/unit/test_logging.py`

**Test Baseline**: 760 passed, 1 failed (pre-existing: test_bug025_yaml_substring_path_not_corrupted), 5 skipped, 4 xfailed
**Test Result**: 762 passed, 0 failed, 5 skipped, 4 xfailed — zero regressions (+1 new test, pre-existing failure resolved independently)

**Documentation & State Updates**:
- [x] Feature implementation state file (3.1.1) updated, or N/A — grepped state file, references `with_context` only in public API listing; no update needed as no interface change: _N/A_
- [x] TDD (PD-TDD-025) updated — pseudocode in §4 updated to reflect save/restore behavior instead of clear-on-exit
- [x] Test spec (TE-TSP-022) updated — added nested decorators test case row to with_context Decorator table
- [x] FDD (3.1.1) updated, or N/A — grepped FDD, no references to `with_context` internal behavior: _N/A_
- [x] ADR updated, or N/A — grepped ADR directory, no references to `with_context`: _N/A_
- [x] Validation tracking updated, or N/A — 3.1.1 tracked in validation-tracking-4; change is a correctness fix that doesn't affect open validation items: _N/A_
- [ ] Technical Debt Tracking: TD item marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD183 | Complete | None | TDD PD-TDD-025 pseudocode, test spec TE-TSP-022 |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
