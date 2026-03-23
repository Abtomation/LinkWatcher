---
id: PF-REF-030
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-02
updated: 2026-03-02
priority: Medium
target_area: linkwatcher/handler.py
mode: lightweight
refactoring_scope: Remove redundant DB queries in _collect_path_updates (TD015)
---

# Lightweight Refactoring Plan: Remove redundant DB queries in _collect_path_updates (TD015)

- **Target Area**: linkwatcher/handler.py
- **Priority**: Medium
- **Created**: 2026-03-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD015 — Remove redundant DB queries in `_collect_path_updates`

**Scope**: `_collect_path_updates` queries `link_db.get_references_to_file()` for all 4 path variations to filter which pairs have active refs — but `_find_references_multi_format` already performed these exact lookups moments earlier. The filter is also unnecessary because the downstream consumer (`_cleanup_database_after_file_move`) handles non-matching variations as no-ops. Fix: remove the DB filter, return all pairs unconditionally.

**Changes Made**:
- [x] Removed DB query filter from `_collect_path_updates` (line 238-240) — now returns all pairs unconditionally
- [x] Updated docstring to reflect simplified behavior

**Test Baseline**: 344 passed, 9 failed (pre-existing), 4 skipped
**Test Result**: 344 passed, 9 failed (pre-existing), 4 skipped — no regressions

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A (internal performance improvement)
- [x] TDD updated — N/A (no interface/design change)
- [x] Test spec updated — N/A (no behavior change)
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD015 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD015 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
