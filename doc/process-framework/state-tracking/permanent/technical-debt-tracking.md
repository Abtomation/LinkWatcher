---
id: PF-STA-002
type: Process Framework
category: State Tracking
version: 1.1
created: 2025-06-15
updated: 2025-01-27
---

# Technical Debt Tracker

This document tracks technical debt. As a solo developer, it's important to be intentional about technical debt - sometimes taking shortcuts is necessary to make progress, but these should be documented and addressed later.

## What is Technical Debt?

Technical debt refers to the implied cost of future rework caused by choosing an easy or quick solution now instead of a better approach that would take longer. It's not inherently bad, but it should be managed.

## Technical Debt Categories

- **Architectural**: Issues related to the overall system design
- **Code Quality**: Issues related to code readability, maintainability, or duplication
- **Testing**: Missing or inadequate tests
- **Documentation**: Missing, outdated, or inadequate documentation
- **Performance**: Known performance issues
- **Security**: Known security vulnerabilities or concerns
- **Accessibility**: Known accessibility issues
- **UX**: User experience compromises

## Priority Levels

- **Critical**: Must be addressed before the next release
- **High**: Should be addressed in the next development cycle
- **Medium**: Should be addressed when convenient
- **Low**: Nice to fix, but not urgent

## Technical Debt Registry

| ID    | Description                                                | Category      | Location                                                                     | Created Date | Priority | Estimated Effort | Status      | Resolution Date | Assessment ID | Notes                                                                                                |
| ----- | ---------------------------------------------------------- | ------------- | ---------------------------------------------------------------------------- | ------------ | -------- | ---------------- | ----------- | --------------- | ------------- | ---------------------------------------------------------------------------------------------------- |
| TD005 | God Class: LinkMaintenanceHandler has 10+ responsibilities (event dispatch, move detection, dir move detection, reference lookup, update orchestration, database manipulation, file scanning, link recalculation, statistics, timer management) in 1409 lines | Architectural | `linkwatcher/handler.py` | 2026-02-27 | High | High (2-3 sessions) | Open | - | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-001. Root cause of cascading bug risk. Recommended: phased decomposition into handler.py, move_detector.py, dir_move_detector.py, reference_lookup.py |
| TD007 | Mega Method: _handle_file_moved spans ~270 lines (197-468) combining reference lookup, deduplication, update orchestration, stale retry, database cleanup, and statistics | Code Quality | `linkwatcher/handler.py:197-468` | 2026-02-27 | High | Medium (1-2 sessions) | Open | - | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-003. Decompose into _find_references(), _update_references_with_retry(), _cleanup_database_after_move() |
| TD009 | Duplicated Stale Retry Logic: stale-detection-rescan-retry pattern duplicated between _handle_file_moved and _handle_directory_moved (~90 lines) | Code Quality | `linkwatcher/handler.py:308-393,524-544` | 2026-02-27 | Medium | Low (1 hour) | Open | - | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-005. Extract into shared _retry_with_rescan() method |
| TD015 | Redundant DB queries in _collect_path_updates: same lookups already performed in _find_references_multi_format | Performance | `linkwatcher/handler.py:250-254` | 2026-03-02 | Low | Low (<30 min) | Open | - | - | Discovered during TD010 refactoring. 4 extra lock-acquiring queries per file move. |
| TD016 | Double-rescan of moved file links: _handle_file_moved rescans affected files then _update_links_within_moved_file re-removes and re-adds entries | Code Quality | `linkwatcher/handler.py:346-380` | 2026-03-02 | Medium | Low (1 hour) | Open | - | - | Discovered during TD010 refactoring. Can cause duplicate DB entries for self-referencing files. |
| TD017 | Inconsistent DB update strategies: file moves use remove+rescan, directory moves use in-place update_target_path | Code Quality | `linkwatcher/handler.py:470 vs 345` | 2026-03-02 | Medium | Medium (1-2 hours) | Open | - | - | Discovered during TD010 refactoring. Different edge case behaviors for anchors, normalization. |
| TD018 | Per-file move detection timers never tracked or cancelled | Code Quality | `linkwatcher/handler.py:513-516` | 2026-03-02 | Low | Low (<30 min) | Open | - | - | Discovered during TD010 refactoring. Timer fires harmlessly but wastes thread in high-churn scenarios. Dir move detection properly tracks timers. |

## Recently Resolved Technical Debt

| ID  | Description | Category | Location | Created Date | Priority | Resolution Date | Assessment ID | Notes |
| --- | ----------- | -------- | -------- | ------------ | -------- | --------------- | ------------- | ----- |
| [TD014](../../refactoring/plans/remove-repeated-inline-path-import-in-updater-py-td014.md) | Repeated Inline Import: `from pathlib import Path` imported 3 times inside method bodies despite module-level import. Removed all 3 inline imports. | Code Quality | `linkwatcher/updater.py` | 2026-02-27 | Low | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-010. 3 redundant inline imports removed. |
| [TD013](../../refactoring/plans/unify-duplicate-synthetic-event-classes-in-handler-py-td013.md) | Duplicate Synthetic Event Classes: Unified `SyntheticMoveEvent` and `_SyntheticDirMoveEvent` into single `_SyntheticMoveEvent` class with `__slots__` at module level | Code Quality | `linkwatcher/handler.py` | 2026-02-27 | Low | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-009. 2 inline classes → 1 module-level class with is_directory parameter. |
| [TD010](../../refactoring/plans/remove-dual-print-logger-output-pattern-in-handler-py-td010.md) | Dual Print+Logger Output: 55 print() and 46 logger calls throughout handler.py, nearly always paired. Eliminated all 39 paired duplicates, assigned each message to one channel (print for progress feedback, logger for persistent records), converted 6 print-only errors to logger | Code Quality | `linkwatcher/handler.py` (throughout) | 2026-02-27 | Medium | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-006. 55→23 prints, 46→41 loggers, 1365→1275 lines. Also discovered 3 bugs (PD-BUG-024/025/026) and 4 new TD items (TD015-018). |
| TD012 | Inline Imports: `import re` and `import shutil` moved from method bodies to module level | Code Quality | `linkwatcher/handler.py` | 2026-02-27 | Low | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-008. Fixed incidentally during TD010 refactoring (linter auto-moved). |
| [TD011](../../refactoring/plans/replace-bare-except-clauses-in-handler-py-td011.md) | Bare Except Clauses: Two bare `except:` handlers caught all exceptions including SystemExit/KeyboardInterrupt. Replaced with `except Exception:` | Code Quality | `linkwatcher/handler.py:503,650` | 2026-02-27 | Medium | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-007. 2 bare except: replaced with except Exception: |
| [TD006](../../refactoring/plans/td006-encapsulation-violation-fix.md) | Encapsulation Violation: Handler/service directly accessed link_db.links dict and files_with_links set, bypassing thread-safe public API. Added remove_targets_by_path(), get_all_targets_with_references(), get_source_files() to database.py | Architectural | `linkwatcher/handler.py, service.py, database.py` | 2026-02-27 | High | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-002. 4 violations replaced (3 handler, 1 service). Also fixed latent race condition. |
| [TD008](../../refactoring/plans/archive/td008-duplicated-reference-lookup-extraction.md) | Duplicated Reference Lookup: "try multiple path formats" pattern repeated 3x in _handle_file_moved. Extracted into `_get_path_variations()`, `_find_references_multi_format()`, `_collect_path_updates()` | Code Quality | `linkwatcher/handler.py` | 2026-02-27 | High | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-004. Also fixed missing backslash variation in stale retry. |
| TD001 | 4 dead functions in utils.py — consolidated `normalize_path()`, `get_relative_path()`, `find_line_number()` as shared utilities; deleted `format_file_size()` (zero callers) | Code Quality | `linkwatcher/utils.py` | 2026-02-18 | Medium | 2026-02-25 | - | Resolved with TD002. Private copies in database.py, updater.py, handler.py, base.py now delegate to utils.py |
| TD002 | Duplicate `normalize_path()` in utils.py, database.py, updater.py | Code Quality | `linkwatcher/utils.py`, `linkwatcher/database.py`, `linkwatcher/updater.py` | 2026-02-18 | Medium | 2026-02-25 | - | Resolved with TD001. Single implementation in utils.py, private copies removed |
| TD003 | Parser exception handlers used `print()` instead of logger (original description was inaccurate — `safe_file_read()` does NOT swallow exceptions) | Code Quality | `linkwatcher/parsers/*.py` | 2026-02-18 | High | 2026-02-25 | - | Replaced `print()` with `self.logger.warning()` in all 6 parsers. Added `get_logger()` to BaseParser.__init__ |
| TD004 | Handler hard-coded `monitored_extensions` and `ignored_directories` — config fields had no effect | Architectural | `linkwatcher/handler.py`, `linkwatcher/service.py` | 2026-02-19 | Medium | 2026-02-25 | - | Handler now accepts config params in constructor. Service passes config through. main.py no longer overwrites post-construction |

## Technical Debt Management Strategy

As a solo developer, follow these guidelines for managing technical debt:

1. **Be intentional**: When creating technical debt, do so consciously and document it immediately
2. **Comment in code**: Mark technical debt in code with `// TODO: [TD###] Description` comments
3. **Regular review**: Review this document periodically to reassess priorities
4. **Batch similar items**: Address similar technical debt items together for efficiency
5. **Refactoring sessions**: Dedicate occasional focused sessions to addressing technical debt

## Linking with Assessment System

**Assessment ID Column**: Links debt items to their originating technical debt assessments:

- **Assessment IDs**: Use format `PF-TDA-XXX` for items identified during formal assessments
- **Debt Item IDs**: Individual debt items get `PF-TDI-XXX` IDs during assessment
- **Manual Items**: Items identified outside assessments leave Assessment ID blank (`-`)

**Workflow Integration**:

1. During Technical Debt Assessment, individual debt items are created with `PF-TDI-XXX` IDs
2. Assessment generates report with `PF-TDA-XXX` ID
3. When adding items to this registry, reference the assessment ID in the Assessment ID column
4. This creates traceability from registry entries back to detailed assessment documentation

## Adding New Technical Debt Items

When adding a new technical debt item:

1. Assign the next available ID (TD###)
2. Add a detailed description
3. Categorize it appropriately
4. Note the exact location in code
5. Assign a priority
6. Estimate the effort required to fix it
7. Add any relevant notes
8. Add a corresponding comment in the code

## Resolving Technical Debt Items

Use [Update-TechDebt.ps1](../../scripts/update/Update-TechDebt.ps1) to automate steps 1-4:

```powershell
# Mark as in progress
.\Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "InProgress"

# Resolve (moves to Recently Resolved, sets date)
.\Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "Resolved" -ResolutionNotes "What was done."

# Resolve with plan link
.\Update-TechDebt.ps1 -DebtId "TD###" -NewStatus "Resolved" -ResolutionNotes "What was done." -PlanLink "[TD###](../../refactoring/plans/plan-file.md)"
```

After running the script:
5. Remove the corresponding TODO comment from the code

---

_This document is part of the Process Framework and provides a system for tracking and managing technical debt._
