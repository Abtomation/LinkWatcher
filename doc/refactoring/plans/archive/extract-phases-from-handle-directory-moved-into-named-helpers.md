---
id: PD-REF-133
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
priority: Medium
mode: lightweight
target_area: File System Monitoring (handler.py)
refactoring_scope: Extract phases from _handle_directory_moved() into named helpers
---

# Lightweight Refactoring Plan: Extract phases from _handle_directory_moved() into named helpers

- **Target Area**: File System Monitoring (handler.py)
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD137 — Extract phases from _handle_directory_moved() into named helpers

**Scope**: Extract Phase 1b (batch update + stale retry, ~35 LOC), Phase 1c + deferred rescan (~25 LOC), and Phase 2 (directory-path references, ~50 LOC) from `_handle_directory_moved()` into private helper methods. Pure extract-method refactoring — no behavioral or interface changes. Reduces orchestrator from ~215 LOC to ~105 LOC. Dimension: CQ (Code Quality).

**Changes Made**:
- [x] Extract `_batch_update_references(move_groups)` — Phase 1b batch update + stale retry logic (handler.py:456-504)
- [x] Extract `_cleanup_and_rescan_moved_files(per_file_data, deferred_rescan_files)` — Phase 1c per-file DB cleanup + deferred rescan (handler.py:506-541)
- [x] Extract `_update_directory_path_references(old_dir, new_dir)` — Phase 2 directory-path reference updates (handler.py:543-605)
- [x] Added `normalize_path` to module-level imports (handler.py:101)

**Test Baseline**: 649 passed, 5 skipped, 6 xfailed
**Test Result**: 649 passed, 5 skipped, 6 xfailed (identical — no regressions)

**Documentation & State Updates**:
- [x] Feature implementation state file (1.1.1) updated, or N/A — verified no reference to changed component: _Grepped state file — references `_handle_directory_moved` by name only (method name unchanged); no references to extracted phases by name_
- [x] TDD (1.1.1) updated, or N/A — verified no interface/design changes documented: _TDD pseudocode is high-level conceptual overview; no interface changes; method name unchanged_
- [x] Test spec (1.1.1) updated, or N/A — verified no behavior change affects spec: _Grepped test specs — no references to `_handle_directory_moved`; pure extract-method, no behavior change_
- [x] FDD (1.1.1) updated, or N/A — verified no functional change affects FDD: _Pure refactoring, no functional change_
- [x] ADR (1.1.1) updated, or N/A — verified no architectural decision affected: _No architectural change; same class, same patterns_
- [x] Validation tracking updated, or N/A — verified feature is not tracked in a validation round or change doesn't affect validation: _R3 validation complete; pure extract-method doesn't affect validation results_
- [ ] Technical Debt Tracking: TD137 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD137 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

