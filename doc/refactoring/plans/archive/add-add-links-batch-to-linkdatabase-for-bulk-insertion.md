---
id: PD-REF-184
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
priority: Medium
refactoring_scope: Add add_links_batch() to LinkDatabase for bulk insertion during initial scan (TD202)
mode: lightweight
target_area: LinkDatabase / LinkWatcherService
---

# Lightweight Refactoring Plan: Add add_links_batch() to LinkDatabase for bulk insertion during initial scan (TD202)

- **Target Area**: LinkDatabase / LinkWatcherService
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD202 — Batch insertion API for initial scan

**Scope**: Add `add_links_batch()` method to `LinkDatabase` that acquires the lock once and inserts multiple references. Update `_initial_scan()` in `LinkWatcherService` to batch references per-file instead of calling `add_link()` per-reference. Dims: PE (Performance).

**Changes Made**:
- [x] Add `add_links_batch()` to `LinkDatabaseInterface` (abstract method) — database.py:99
- [x] Extract `_add_link_unlocked()` private method with core insertion logic — database.py:270
- [x] Refactor `add_link()` to delegate to `_add_link_unlocked()` under lock — database.py:253
- [x] Implement `add_links_batch()` — single lock, iterates refs calling `_add_link_unlocked()` — database.py:259
- [x] Update `_initial_scan()` to call `add_links_batch()` per-file — service.py:197
- [x] Updated AI Context docblock in database.py to document new methods and data flow
- [x] Added 4 tests: batch add, batch dedup, batch empty, batch skip empty targets — test_database.py

**Test Baseline**: 758 passed, 5 skipped, 4 deselected, 4 xfailed, 0 failed
**Test Result**: 763 passed, 5 skipped, 4 deselected, 4 xfailed, 0 failed (+4 new batch tests, +1 from discovery)

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.2) — N/A: grepped state file for "add_link" — mentions it in API summary but no specific interface change; `add_link()` unchanged, `add_links_batch()` is additive
- [x] TDD (0.1.2) — N/A: grepped TDD — references `add_link()` as public API which remains unchanged; `add_links_batch()` is additive convenience method, `_add_link_unlocked()` is private implementation detail
- [x] Test spec (0.1.2) — N/A: grepped test spec — references `add_link()` test focus; batch method covered by 4 new tests but no behavior change to spec'd functionality
- [x] FDD (0.1.2) — N/A: feature 0.1.2 has no FDD (Tier 2 feature)
- [x] ADR — N/A: grepped ADR directory — `target-indexed-in-memory-link-database.md` describes storage design, not insertion API; no architectural decision affected
- [x] Validation tracking — N/A: no active validation round tracking feature 0.1.2
- [x] Technical Debt Tracking: TD202 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD202 | Complete | None | AI Context docblock updated in database.py |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
