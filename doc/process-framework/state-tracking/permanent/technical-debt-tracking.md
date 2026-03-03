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

## Recently Resolved Technical Debt

| ID  | Description | Category | Location | Created Date | Priority | Resolution Date | Assessment ID | Notes |
| --- | ----------- | -------- | -------- | ------------ | -------- | --------------- | ------------- | ----- |
| [TD014](../../refactoring/plans/remove-repeated-inline-path-import-in-updater-py-td014.md) | Repeated Inline Import: `from pathlib import Path` imported 3 times inside method bodies despite module-level import. Removed all 3 inline imports. | Code Quality | `linkwatcher/updater.py` | 2026-02-27 | Low | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-010. 3 redundant inline imports removed. |
| [TD013](../../refactoring/plans/unify-duplicate-synthetic-event-classes-in-handler-py-td013.md) | Duplicate Synthetic Event Classes: Unified `SyntheticMoveEvent` and `_SyntheticDirMoveEvent` into single `_SyntheticMoveEvent` class with `__slots__` at module level | Code Quality | `linkwatcher/handler.py` | 2026-02-27 | Low | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-009. 2 inline classes → 1 module-level class with is_directory parameter. |
| [TD010](../../refactoring/plans/remove-dual-print-logger-output-pattern-in-handler-py-td010.md) | Dual Print+Logger Output: 55 print() and 46 logger calls throughout handler.py, nearly always paired. Eliminated all 39 paired duplicates, assigned each message to one channel (print for progress feedback, logger for persistent records), converted 6 print-only errors to logger | Code Quality | `linkwatcher/handler.py` (throughout) | 2026-02-27 | Medium | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-006. 55→23 prints, 46→41 loggers, 1365→1275 lines. Also discovered 3 bugs (PD-BUG-024/025/026) and 4 new TD items (TD015-018). |
| TD012 | Inline Imports: `import re` and `import shutil` moved from method bodies to module level | Code Quality | `linkwatcher/handler.py` | 2026-02-27 | Low | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-008. Fixed incidentally during TD010 refactoring (linter auto-moved). |
| [TD011](../../refactoring/plans/replace-bare-except-clauses-in-handler-py-td011.md) | Bare Except Clauses: Two bare `except:` handlers caught all exceptions including SystemExit/KeyboardInterrupt. Replaced with `except Exception:` | Code Quality | `linkwatcher/handler.py:503,650` | 2026-02-27 | Medium | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-007. 2 bare except: replaced with except Exception: |
| [TD006](../../refactoring/plans/td006-encapsulation-violation-fix.md) | Encapsulation Violation: Handler/service directly accessed link_db.links dict and files_with_links set, bypassing thread-safe public API. Added remove_targets_by_path(), get_all_targets_with_references(), get_source_files() to database.py | Architectural | `linkwatcher/handler.py, service.py, database.py` | 2026-02-27 | High | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-002. 4 violations replaced (3 handler, 1 service). Also fixed latent race condition. |
| [TD008](../../refactoring/plans/archive/td008-duplicated-reference-lookup-extraction.md) | Duplicated Reference Lookup: "try multiple path formats" pattern repeated 3x in _handle_file_moved. Extracted into `_get_path_variations()`, `_find_references_multi_format()`, `_get_old_path_variations()` | Code Quality | `linkwatcher/handler.py` | 2026-02-27 | High | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-004. Also fixed missing backslash variation in stale retry. |
| TD001 | 4 dead functions in utils.py — consolidated `normalize_path()`, `get_relative_path()`, `find_line_number()` as shared utilities; deleted `format_file_size()` (zero callers) | Code Quality | `linkwatcher/utils.py` | 2026-02-18 | Medium | 2026-02-25 | - | Resolved with TD002. Private copies in database.py, updater.py, handler.py, base.py now delegate to utils.py |
| TD002 | Duplicate `normalize_path()` in utils.py, database.py, updater.py | Code Quality | `linkwatcher/utils.py`, `linkwatcher/database.py`, `linkwatcher/updater.py` | 2026-02-18 | Medium | 2026-02-25 | - | Resolved with TD001. Single implementation in utils.py, private copies removed |
| TD003 | Parser exception handlers used `print()` instead of logger (original description was inaccurate — `safe_file_read()` does NOT swallow exceptions) | Code Quality | `linkwatcher/parsers/*.py` | 2026-02-18 | High | 2026-02-25 | - | Replaced `print()` with `self.logger.warning()` in all 6 parsers. Added `get_logger()` to BaseParser.__init__ |
| TD004 | Handler hard-coded `monitored_extensions` and `ignored_directories` — config fields had no effect | Architectural | `linkwatcher/handler.py`, `linkwatcher/service.py` | 2026-02-19 | Medium | 2026-02-25 | - | Handler now accepts config params in constructor. Service passes config through. main.py no longer overwrites post-construction |
| TD005 | God Class: LinkMaintenanceHandler has 10+ responsibilities (event dispatch, move detection, dir move detection, reference lookup, update orchestration, database manipulation, file scanning, link recalculation, statistics, timer management) in 1409 lines | Architectural | `linkwatcher/handler.py` | 2026-02-27 | High | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-001. Root cause of cascading bug risk. Recommended: phased decomposition into handler.py, move_detector.py, dir_move_detector.py, reference_lookup.py Decomposed into move_detector.py and dir_move_detector.py via PF-REF-029. Handler reduced from 1281 to 839 lines. |
| TD009 | Duplicated Stale Retry Logic: stale-detection-rescan-retry pattern duplicated between _handle_file_moved and _handle_directory_moved (~90 lines) | Code Quality | `linkwatcher/handler.py:308-393,524-544` | 2026-02-27 | Medium | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-005. Extract into shared _retry_with_rescan() method Inline stale retry in _handle_directory_moved replaced with call to shared _retry_stale_references(). Resolved as part of PF-REF-029. |
| [TD015](../../refactoring/plans/remove-redundant-db-queries-in-collect-path-updates-td015.md) | Redundant DB queries in _collect_path_updates (now _get_old_path_variations): same lookups already performed in _find_references_multi_format | Performance | `linkwatcher/handler.py:250-254` | 2026-03-02 | Low | 2026-03-02 | - | Discovered during TD010 refactoring. 4 extra lock-acquiring queries per file move. Removed redundant DB query filter. Method renamed to _get_old_path_variations (PD-BUG-024 fix) — now delegates to _get_path_variations, returning flat list of old targets. Eliminates 4 lock-acquiring DB reads per file move. |
| [TD018](../../refactoring/plans/track-and-cancel-per-file-move-detection-timers-in-movedetector.md) | Per-file move detection timers never tracked or cancelled | Code Quality | `linkwatcher/handler.py:513-516` | 2026-03-02 | Low | 2026-03-02 | - | Discovered during TD010 refactoring. Timer fires harmlessly but wastes thread in high-churn scenarios. Dir move detection properly tracks timers. Added _timers dict to MoveDetector. Timers now stored, cancelled on match/re-buffer, and marked daemon. See PF-REF-032. |
| [TD016](../../refactoring/plans/eliminate-double-rescan-of-moved-file-links-td016.md) | Double-rescan of moved file links: _handle_file_moved rescans affected files then _update_links_within_moved_file re-removes and re-adds entries | Code Quality | `linkwatcher/handler.py:346-380` | 2026-03-02 | Medium | 2026-03-02 | - | Discovered during TD010 refactoring. Can cause duplicate DB entries for self-referencing files. Added moved_file_path parameter to _cleanup_database_after_file_move to skip the moved file in rescan loop. _update_links_within_moved_file is now the single authority for the moved files own DB entries, eliminating double-rescan and preventing duplicate DB entries for self-referencing files. |
| [TD017](../../refactoring/plans/unify-db-update-strategy-for-directory-moves-to-use-remove-rescan-pattern.md) | Inconsistent DB update strategies: file moves use remove+rescan, directory moves use in-place update_target_path | Code Quality | `linkwatcher/handler.py:470 vs 345` | 2026-03-02 | Medium | 2026-03-02 | - | Discovered during TD010 refactoring. Different edge case behaviors for anchors, normalization. Replaced update_target_path with _cleanup_database_after_file_move (remove+rescan) and get_references_to_file with _find_references_multi_format in _handle_directory_moved. Both file and directory moves now use identical DB update strategy. |
| [TD021](../../refactoring/plans/update-adr-039-and-adr-040-to-fix-documentation-drift-td021-td023.md) | ADR-040 documents 6-method public API but database.py now has 9 public methods (added remove_targets_by_path, get_all_targets_with_references, get_source_files) | Documentation | doc/product-docs/technical/architecture/design-docs/adr/adr/target-indexed-in-memory-link-database.md | 2026-03-03 | Low | 2026-03-03 | PF-VAL-035 | 3 methods added during TD006 encapsulation fix. ADR text needs updating to match. Updated ADR-040: method list expanded to 9 (add remove_targets_by_path, get_all_targets_with_references, get_source_files), 6-method → 9-method text. |
| [TD023](../../refactoring/plans/update-adr-039-and-adr-040-to-fix-documentation-drift-td021-td023.md) | ADR-039 says signal handlers registered during start() but code registers in __init__() - minor documentation drift | Documentation | doc/product-docs/technical/architecture/design-docs/adr/adr/orchestrator-facade-pattern-for-core-architecture.md | 2026-03-03 | Low | 2026-03-03 | PF-VAL-035 | Current behavior is acceptable; only the ADR text needs correction. Updated ADR-039: signal handler registration corrected from start() to __init__() in Decision and Consequences sections. |
| [TD019](../../refactoring/plans/replace-bare-except-with-except-exception-in-database-py.md) | Bare except: in _reference_points_to_file() catches SystemExit/KeyboardInterrupt - should be except Exception: | Code Quality | linkwatcher/database.py:131 | 2026-03-03 | Low | 2026-03-03 | PF-VAL-035 | Same pattern as resolved TD011 in handler.py Replaced bare except: with except Exception: on line 131 of database.py. Same pattern as TD011. |
| [TD025](../../refactoring/plans/remove-inline-import-re-in-updater-py.md) | Inline `import re` in updater.py methods: re imported inside `_update_markdown_link()` (line 476) and `_update_yaml_reference()` (line 504) instead of at module level | Code Quality | linkwatcher/updater.py:476,504 | 2026-03-03 | Low | 2026-03-03 | PF-VAL-036 | Same pattern as resolved TD012/TD014 in handler.py. Module-level import already exists. Added import re at module level, removed 2 inline import re from _replace_markdown_target() and _replace_reference_target(). Note: TD025 description incorrectly stated module-level import already existed. |
| TD030 | Bare `except:` in run_tests.py:148 catches SystemExit/KeyboardInterrupt — should be `except Exception:` | Code Quality | run_tests.py:148 | 2026-03-03 | Low | 2026-03-03 | PF-VAL-036 | Same pattern as resolved TD011 in handler.py. Replaced bare except: with except Exception: in run_tests.py:148 |
| [TD032](../../refactoring/plans/extract-match-strategies-from-calculate-new-target-relative-in-updater-py.md) | Updater `_calculate_new_target_relative` is ~90 LOC with 3 nested fallback match strategies and deep nesting | Code Quality | `linkwatcher/updater.py` | 2026-03-03 | Medium | 2026-03-03 | PF-VAL-038 | Extract match strategies into `_match_direct`, `_match_stripped`, `_match_resolved` helpers Extracted 3 match strategies (_match_direct, _match_stripped, _match_resolved) from _calculate_new_target_relative. Method reduced from ~108 to ~62 lines. 386 tests pass. |
| [TD031](../../refactoring/plans/decompose-dartparser-parse-content-monolithic-method-into-focused-sub-methods.md) | DartParser.parse_content is ~155 LOC monolithic method handling 5 pattern types (imports, parts, quoted refs, standalone refs, embedded refs) | Code Quality | `linkwatcher/parsers/dart.py` | 2026-03-03 | Medium | 2026-03-03 | PF-VAL-038 | Extract into sub-methods: `_extract_imports`, `_extract_quoted_refs`, `_extract_standalone_refs`, etc. Extracted 5 sub-methods (_extract_imports, _extract_parts, _extract_quoted_refs, _extract_standalone_refs, _extract_embedded_refs) from monolithic parse_content. Method reduced from ~155 to ~25 LOC. All 389 tests pass. |
| [TD033](../../refactoring/plans/extract-pathresolver-from-linkupdater-td033.md) | Updater SRP violation: LinkUpdater mixes path resolution, regex replacement, and file I/O in single class (3 distinct responsibilities) | Architectural | `linkwatcher/updater.py` | 2026-03-03 | Medium | 2026-03-03 | PF-VAL-038 | Consider extracting `PathResolver` for path calculation logic. Coordinate with TD032 Extracted PathResolver class (10 methods, 332 LOC) into linkwatcher/path_resolver.py. LinkUpdater reduced from 628 to 348 LOC. All 386 tests pass. |
| [TD034](../../refactoring/plans/remove-dual-print-logger-output-in-service-py-td034.md) | Dual print()+logger output in service.py: 33 print() calls alongside 21 structured logger calls | Code Quality | `linkwatcher/service.py` | 2026-03-03 | Medium | 2026-03-03 | PF-VAL-037 | Same pattern as resolved TD010 (handler.py) and PF-REF-039 (updater.py). Assign each message to one channel Removed 12 paired print()+logger duplicates. 7 logger calls removed (user-facing progress), 5 print blocks removed (error/record duplicates). 33 to 22 prints, 21 to 14 loggers. Same pattern as TD010 and PF-REF-039. All 386 tests pass. |
| [TD036](../../refactoring/plans/add-reset-functions-for-global-singletons-in-logging-modules.md) | Global mutable singletons `_logger` and `_config_manager` in logging.py limit dependency injection and complicate testing | Code Quality | `linkwatcher/logging.py` | 2026-03-03 | Low | 2026-03-03 | PF-VAL-038 | Standard pattern for logging; could add `reset_logger()` for test isolation Added reset_logger() to logging.py and reset_config_manager() to logging_config.py. Updated tests to use public API instead of private _logger = None. All 386 tests pass. |
| [TD038](../../refactoring/plans/replace-8-module-stdlib-regex-with-comprehensive-set-lookup-using-sys-stdlib-module-names-3-10-with-fallback.md) | PythonParser stdlib exclusion list only has 8 modules — causes false-positive file references for unlisted stdlib imports | Code Quality | `linkwatcher/parsers/python.py` | 2026-03-03 | Low | 2026-03-03 | PF-VAL-038 | Expand list or use `sys.stdlib_module_names` (Python 3.10+) Replaced 8-module stdlib regex with sys.stdlib_module_names (3.10+) frozenset + comprehensive fallback for 3.8/3.9. Set lookup in parse_content replaces regex alternation. Added test_skip_dotted_stdlib_imports. 387 tests pass. |
| [TD035](../../refactoring/plans/extract-update-links-within-moved-file-and-handle-directory-moved-from-handler-py.md) | Handler.py further decomposition needed: still 681 LOC/24 methods after TD005/TD022 extractions. `_update_links_within_moved_file` (~140 LOC) and `_handle_directory_moved` (~80 LOC) should be extracted | Architectural | `linkwatcher/handler.py` | 2026-03-03 | Medium | 2026-03-03 | PF-VAL-037 | Continuation of TD005. Handler reduced from 1409→839→681 LOC but still violates SRP Extracted _update_links_within_moved_file + _calculate_updated_relative_path and _handle_directory_moved per-file loop into ReferenceLookup. Handler reduced from 681 to 474 LOC (30%). All 387 tests pass. |
| [TD037](../../refactoring/plans/remove-export-logs-placeholder-from-loggingconfigmanager.md) | `export_logs` placeholder in LoggingConfigManager returns 0 — dead code with no implementation | Code Quality | `linkwatcher/logging_config.py` | 2026-03-03 | Low | 2026-03-03 | PF-VAL-038 | Either implement log export or remove placeholder method Removed export_logs placeholder method (18 lines) from LoggingConfigManager. Method had no callers, no tests, no implementation. |
| [TD039](../../refactoring/plans/remove-duplicate-makefile-dev-bat-is-canonical.md) | dev.bat and Makefile define same targets — changes must be mirrored in both | Code Quality | `dev.bat`, `Makefile` | 2026-03-03 | Low | 2026-03-03 | PF-VAL-038 | Consider generating one from the other or documenting which is canonical Deleted Makefile (duplicate of dev.bat). Updated CONTRIBUTING.md to remove Makefile references. dev.bat is the canonical build tool. All 387 tests pass. |
| [TD040](../../refactoring/plans/remove-duplicate-setup-py-td040.md) | setup.py duplicates pyproject.toml metadata — legacy file | Code Quality | `setup.py` | 2026-03-03 | Low | 2026-03-03 | PF-VAL-038 | Migrate fully to pyproject.toml when dropping legacy support Deleted setup.py (73 lines). All metadata already in pyproject.toml. Removed setup.py references from scripts/setup_cicd.py and pyproject.toml coverage omit. All 387 tests pass. |
| [TD042](../../refactoring/plans/consolidate-3-pass-get-references-to-file-into-single-pass.md) | `get_references_to_file` uses 3 separate scanning passes over full collection | Performance | `linkwatcher/database.py` | 2026-03-03 | Low | 2026-03-03 | PF-VAL-037 | Consolidate into single pass with union set for better performance on large databases Consolidated 3-pass get_references_to_file into 2 passes (direct lookup + single merged iteration). Replaced O(n) ref not in list dedup with O(1) id-based seen set. All 387 tests pass. |
| [TD041](../../refactoring/plans/replace-generic-exception-with-ioerror-in-safe-file-read.md) | `safe_file_read` raises generic `Exception()` instead of specific `IOError`/`FileReadError` | Code Quality | `linkwatcher/utils.py` | 2026-03-03 | Low | 2026-03-03 | PF-VAL-037 | Use specific exception types for better caller error handling Replaced 2 raise Exception(...) with raise IOError(...) in safe_file_read(). Updated docstring. IOError is subclass of Exception so all existing catch handlers continue working. 387 tests pass. |
| [PF-REF-042](../../refactoring/plans/extract-reference-lookup-from-handler-py-into-reference-lookup-py-td022.md) | Handler still ~870 LOC after TD005 partial decomposition - reference_lookup.py extraction was never done | Architectural | linkwatcher/handler.py | 2026-03-03 | Medium | 2026-03-03 | PF-VAL-035 | TD005 resolved move detection extraction only. Extracted 7 reference-lookup methods into ReferenceLookup class in linkwatcher/reference_lookup.py. Handler.py reduced from 873 to 681 lines (22%). All 386 tests pass. |
| [PF-REF-041](../../refactoring/plans/remove-dead-replace-path-part-from-updater-py.md) | Dead code: `_replace_path_part()` method in updater.py is defined but never called | Code Quality | linkwatcher/updater.py:441 | 2026-03-03 | Low | 2026-03-03 | PF-VAL-036 | Method can be safely removed. Removed dead _replace_path_part() method (15 lines) from updater.py. Method was present since first commit but never called — updater uses _calculate_new_target_relative() instead. Also removed 3 dead tests and 3 test spec rows. |
| [PF-REF-040](/doc/process-framework/refactoring/plans/fix-pytest-ini-testpaths-typo-td029.md) | pytest.ini `testpaths = test` but actual directory is `tests/` — pytest resolves via fallback but configuration is misleading | Testing | pytest.ini | 2026-03-03 | Low | 2026-03-03 | PF-VAL-036 | Change `testpaths = test` to `testpaths = tests`. Changed testpaths = test to testpaths = tests in pytest.ini |
| [PF-REF-039](../../refactoring/plans/remove-dual-print-logger-output-in-updater-py-td026.md) | Dual print+logger output in updater.py: 5 `print()` calls alongside structured logger calls | Code Quality | linkwatcher/updater.py | 2026-03-03 | Medium | 2026-03-03 | PF-VAL-036 | Same pattern as resolved TD010 in handler.py. Should assign each message to one channel. Removed 5 paired print() calls (kept logger), removed 1 paired logger.info() call (kept print for dry-run preview). 6 dual-output pairs → 6 single-channel. Same pattern as TD010. |
| [PF-REF-038](../../refactoring/plans/add-missing-wraps-decorator-to-with-context-in-logging-py-td028.md) | Missing `@wraps(func)` in logging.py `with_context()` decorator causes decorated functions to lose their `__name__`, `__doc__`, and `__module__` attributes | Code Quality | linkwatcher/logging.py:428 | 2026-03-03 | Low | 2026-03-03 | PF-VAL-036 | Add `from functools import wraps` and `@wraps(func)` to inner wrapper. Added from functools import wraps to module imports and @wraps(func) to inner wrapper function in with_context() decorator. |
| [PF-REF-036](../../refactoring/plans/td020-and-td024-in-updater-py.md) | Magic string returns (updated, stale, no_changes) from updater - should use Enum or Literal type for type safety | Code Quality | linkwatcher/updater.py | 2026-03-03 | Low | 2026-03-03 | PF-VAL-035 | Handler must know the string protocol. Enum/Literal would provide IDE support and prevent typos. Replaced magic string returns with UpdateResult Enum in updater.py; updated 5 test assertions in test_updater.py |
| [PF-REF-036](../../refactoring/plans/td020-and-td024-in-updater-py.md) | Bare except: catches SystemExit/KeyboardInterrupt - should be except Exception: | Code Quality | linkwatcher/updater.py:274,298,599 | 2026-03-03 | Low | 2026-03-03 | PF-VAL-035, PF-VAL-036 | Same pattern as resolved TD011 in handler.py. Lines 274 and 298 discovered in Batch 2 validation. Replaced 3 bare except: with except Exception: in updater.py (lines 274, 298, 588) |
| [PF-REF-028](/doc/process-framework/refactoring/plans/decompose-handle-file-moved-mega-method-into-focused-sub-methods.md) | Mega Method: _handle_file_moved spans ~270 lines (197-468) combining reference lookup, deduplication, update orchestration, stale retry, database cleanup, and statistics | Code Quality | `linkwatcher/handler.py:197-468` | 2026-02-27 | High | 2026-03-02 | [PF-TDA-001](../../assessments/technical-debt/assessments/handler-module-structural-debt-assessment.md) | PF-TDI-003. Decompose into _find_references(), _update_references_with_retry(), _cleanup_database_after_move() Decomposed into _retry_stale_references() and _cleanup_database_after_file_move(). Method reduced from 136 to 62 lines. See PF-REF-028. |

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
