---
id: PD-REF-036
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
refactoring_scope: TD020 and TD024 in updater.py
target_area: linkwatcher/updater.py
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: TD020 and TD024 in updater.py

- **Target Area**: linkwatcher/updater.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD020 — Replace bare except: with except Exception: in updater.py

**Scope**: Three bare `except:` clauses in `_calculate_new_target_relative()` (lines 274, 298) and `_write_file_safely()` (line 599) catch SystemExit/KeyboardInterrupt. Replace with `except Exception:` to match the pattern established by resolved TD011.

**Changes Made**:
- [x] Line 274: `except:` → `except Exception:`
- [x] Line 298: `except:` → `except Exception:`
- [x] Line 588: `except:` → `except Exception:` (originally line 599, shifted by Enum class insertion)

**Test Baseline**: 393 passed, 5 skipped, 7 xfailed
**Test Result**: 389 passed, 5 skipped, 7 xfailed, 0 failures (4 fewer passes due to concurrent changes by other agent resolving TD025; 0 failures from TD020 changes)

**Documentation & State Updates**:
- [x] Feature implementation state file updated (N/A — no feature change)
- [x] TDD updated (N/A — no interface/design change)
- [x] Test spec updated (N/A — no behavior change)
- [x] FDD updated (N/A — no functional change)
- [x] Technical Debt Tracking: TD020 marked resolved

**Bugs Discovered**: None

## Item 2: TD024 — Replace magic string returns with UpdateResult Enum

**Scope**: `_update_file_references()` returns magic strings `"updated"`, `"stale"`, `"no_changes"` which are compared in `update_references()`. Define an `UpdateResult` Enum and replace all string returns/comparisons for type safety and IDE support. All changes are internal to updater.py.

**Changes Made**:
- [x] Add `from enum import Enum` import and define `UpdateResult` Enum class with UPDATED, STALE, NO_CHANGES values
- [x] Replace 5 string returns in `_update_file_references()` with Enum values
- [x] Replace 3 string comparisons in `update_references()` with Enum comparisons
- [x] Update docstring of `_update_file_references()` to reference the Enum
- [x] Update 5 test assertions in `tests/unit/test_updater.py` (`TestStaleLineNumberDetection`) to use Enum values

**Test Baseline**: 393 passed, 5 skipped, 7 xfailed
**Test Result**: 389 passed, 5 skipped, 7 xfailed, 0 failures (4 fewer passes due to concurrent changes by other agent; 0 failures from TD024 changes)

**Documentation & State Updates**:
- [x] Feature implementation state file updated (N/A — no feature change)
- [x] TDD updated (N/A — no interface/design change, Enum is internal)
- [x] Test spec updated (N/A — no behavior change)
- [x] FDD updated (N/A — no functional change)
- [x] Technical Debt Tracking: TD024 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD020 | Complete | None | None |
| 2 | TD024 | Complete | None | Test assertions updated (5 in test_updater.py) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
