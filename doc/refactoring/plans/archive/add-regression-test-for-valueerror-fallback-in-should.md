---
id: PD-REF-194
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-28
updated: 2026-04-28
debt_item: TD214
target_area: src/linkwatcher/utils.py - should_monitor_file
refactoring_scope: Add regression test for ValueError fallback in should_monitor_file
priority: Low
mode: lightweight
feature_id: 6.1.1
---

# Lightweight Refactoring Plan: Add regression test for ValueError fallback in should_monitor_file

- **Target Area**: src/linkwatcher/utils.py - should_monitor_file
- **Priority**: Low
- **Created**: 2026-04-28
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD214
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD214 — Missing regression test for ValueError fallback in should_monitor_file()

**Scope**: Dimension: **TST** (Test). Add a single regression test (`test_file_not_under_project_root_falls_back_to_full_path`) to [test_shouldmonitorfileancestorpath.py](/test/automated/unit/test_shouldmonitorfileancestorpath.py) covering the `except ValueError` branch at [utils.py:78-80](/src/linkwatcher/utils.py#L78-L80). This branch fires when `file_path` is not under `project_root` and falls back to checking the full path's parts against `ignored_dirs` — currently exercised by zero tests despite being a defensive branch on the file-watching hot path. Test verifies (a) the fallback still applies the ignored-dirs filter (file under an outside-but-ignored dir is rejected) and (b) the function does not crash on the `ValueError`. Discovered during test audit TE-TAR-065.

**Changes Made**:
- [x] Added `test_file_not_under_project_root_falls_back_to_full_path` to `TestShouldMonitorFileAncestorPath` class in [test_shouldmonitorfileancestorpath.py](/test/automated/unit/test_shouldmonitorfileancestorpath.py)

**Test Baseline**: 808 passed, 1 failed (pre-existing), 5 skipped, 5 deselected, 4 xfailed (49.16s, `pytest test/automated/ -m "not slow"`)
- Pre-existing failure: `test/automated/integration/test_link_updates.py::TestBug094PythonImportDoubleApply::test_bug094_multi_rename_order_independent` (related to PD-BUG-094 / TD-tests for BUG-094)

**Test Result**: 809 passed, 1 failed (same pre-existing), 5 skipped, 5 deselected, 4 xfailed (128.57s)
- **Diff vs baseline**: +1 passed (the new test), **0 new failures owned by this session**
- New test verified in isolation: 6/6 passed in test_shouldmonitorfileancestorpath.py

**Documentation & State Updates**:
<!-- Test-only shortcut: items 1–7 batched N/A — no production code changes -->
- [x] Items 1–7 N/A — *Test-only refactoring — no production code changes; design and state documents do not reference test internals.*
- [x] Technical Debt Tracking: TD214 marked Resolved (Update-TechDebt.ps1, 2026-04-28)
- [x] test-tracking.md: TE-TST-131 row updated — test count 5→6, last-run 2026-04-28: 6 passed, Major Findings note updated to mark TD214 resolved

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD214 | Complete | None | None (test-only refactoring) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

