---
id: PF-REF-034
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
refactoring_scope: Update ADR-039 and ADR-040 to fix documentation drift (TD021, TD023)
target_area: ADR Documents
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: Update ADR-039 and ADR-040 to fix documentation drift (TD021, TD023)

- **Target Area**: ADR Documents
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD021 — ADR-040 public API count outdated (6 → 9 methods)

**Scope**: ADR-040 lists 6 public methods in the lock example comment and Consequences section, but database.py now has 9 public methods after TD006 added `remove_targets_by_path`, `get_all_targets_with_references`, `get_source_files`. Update the method list in the lock example and the "6-method" text in Consequences.

**Changes Made**:
- [x] Updated lock example comment to list all 9 methods: `add_link`, `get_references_to_file`, `update_target_path`, `remove_file_links`, `remove_targets_by_path`, `get_all_targets_with_references`, `get_source_files`, `clear`, `get_stats`
- [x] Updated "consistent 6-method public API" → "consistent 9-method public API"

**Test Baseline**: 393 passed, 5 skipped, 7 xfailed
**Test Result**: 393 passed, 5 skipped, 7 xfailed (identical — no code changes)

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A (ADR-only change)
- [x] TDD updated — N/A (no interface/design change)
- [x] Test spec updated — N/A (no behavior change)
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD021 marked resolved

**Bugs Discovered**: None

## Item 2: TD023 — ADR-039 signal handler registration location incorrect

**Scope**: ADR-039 states signal handlers are registered during `start()` (Decision line 49, Consequences line 74), but code registers them in `__init__()` (service.py:66-68). Update ADR text to say `__init__()`.

**Changes Made**:
- [x] Split Decision bullet: separated signal handler registration (`__init__()`) from `start()` responsibilities into own bullet
- [x] Updated Consequences: "during `start()`" → "during `__init__()`"

**Test Baseline**: 393 passed, 5 skipped, 7 xfailed
**Test Result**: 393 passed, 5 skipped, 7 xfailed (identical — no code changes)

**Documentation & State Updates**:
- [x] Feature implementation state file updated — N/A (ADR-only change)
- [x] TDD updated — N/A (no interface/design change)
- [x] Test spec updated — N/A (no behavior change)
- [x] FDD updated — N/A (no functional change)
- [x] Technical Debt Tracking: TD023 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD021 | Complete | None | ADR-040 |
| 2 | TD023 | Complete | None | ADR-039 |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
