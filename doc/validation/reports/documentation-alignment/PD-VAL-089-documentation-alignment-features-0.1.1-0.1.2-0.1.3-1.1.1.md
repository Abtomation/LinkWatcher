---
id: PD-VAL-089
type: Process Framework
category: Validation Report
version: 1.0
created: 2026-04-09
updated: 2026-04-09
validation_type: documentation-alignment
features_validated: "0.1.1, 0.1.2, 0.1.3, 1.1.1"
validation_session: 7
---

# Documentation Alignment Validation Report - Features 0.1.1, 0.1.2, 0.1.3, 1.1.1

## Executive Summary

**Validation Type**: Documentation Alignment
**Features Validated**: 0.1.1, 0.1.2, 0.1.3, 1.1.1
**Validation Date**: 2026-04-09
**Validation Round**: Round 4
**Overall Score**: 2.20/3.0
**Status**: PASS
**Prior Round**: PD-VAL-072 (R3, 2026-04-01, score 2.35/3.0)

### Key Findings

- TDD-0-1-1 (PD-TDD-021) documents `start()` with scan-before-observer ordering, but PD-BUG-053 fix reversed this to observer-first — TDD never updated
- TDD-1-1-1 (PD-TDD-023) missing `config` parameter from `LinkMaintenanceHandler.__init__` signature and 10+ post-onboarding features (event deferral, on_error, Phase 0, PD-BUG-046)
- ADR-041 still describes per-path `threading.Timer` design for MoveDetector despite TD107 replacing it with single worker + heapq
- Feature state files contain stale method names (`calculate_relative_path`, `get_links_to_target`) and incorrect field counts/names
- Feature 0.1.3 (Tier 1) inline documentation remains good; main gap is `DEFAULT_CONFIG` vs dataclass default divergence undocumented
- No Integration Narratives exist for any feature (`doc/technical/integration/` is empty)

### Immediate Actions Required

- [ ] Update TDD-0-1-1 Section 4.1 `start()` to reflect observer-first ordering (PD-BUG-053 fix)
- [ ] Update TDD-0-1-1 to document `--validate` CLI flag and `LinkValidator` integration in main.py
- [ ] Update TDD-1-1-1 to add `config` parameter to `LinkMaintenanceHandler.__init__` signature
- [ ] Update ADR-041 to reflect TD107 heapq-based MoveDetector design (single worker thread, not per-path timers)

### R3→R4 Score Comparison

| Criterion | R3 Score | R4 Score | Delta |
|---|---|---|---|
| TDD Alignment | 2.25/3 | 2.0/3 | -0.25 |
| FDD Alignment | 2.0/3 | 2.25/3 | +0.25 |
| ADR Compliance | 3.0/3 | 2.5/3 | -0.50 |
| Feature State File Accuracy | 2.5/3 | 2.0/3 | -0.50 |
| Documentation Currency | 2.0/3 | 2.25/3 | +0.25 |
| **Overall** | **2.35/3.0** | **2.20/3.0** | **-0.15** |

> Prior round report: PD-VAL-072

**Score regression explanation**: R3 rated ADRs 3.0/3 stating "ADRs accurately reflect current implementation including the TD107 heapq modernization." This R4 assessment found ADR-041 does NOT reflect TD107 — it still documents per-path `threading.Timer`. The R3 assessment was incorrect. Additionally, feature state files have accumulated more stale content since onboarding without updates.

## Validation Scope

### Features Included

| Feature ID | Feature Name | Implementation Status | Validation Focus |
| ---------- | ------------ | --------------------- | ---------------- |
| 0.1.1 | Core Architecture | Completed (MAINTAINED) | TDD/FDD/ADR alignment, start() ordering, --validate flag, public API |
| 0.1.2 | In-Memory Link Database | Completed (MAINTAINED) | TDD/FDD/ADR alignment, data structure counts, return types |
| 0.1.3 | Configuration System | Completed (MAINTAINED) | Inline doc accuracy (Tier 1), config field documentation |
| 1.1.1 | File System Monitoring | Completed (MAINTAINED) | TDD/FDD/ADR alignment, handler signature, phase numbering, bug fix docs |

### Dimensions Validated

**Validation Dimension**: Documentation Alignment (DA)
**Dimension Source**: Fresh evaluation comparing source code against TDDs, FDDs, ADRs, feature state files, and inline documentation

### Validation Criteria Applied

| Criterion | Weight | Description |
|-----------|--------|-------------|
| TDD Alignment | 25% | Implementation matches Technical Design Documents (or inline docs for Tier 1) |
| FDD Alignment | 25% | Implementation matches Functional Design Documents (or N/A for Tier 1) |
| ADR Compliance | 20% | Implementation follows architectural decisions documented in ADRs |
| Feature State File Accuracy | 15% | State files accurately reflect current implementation status, linked docs, and known issues |
| Documentation Currency | 15% | Documentation reflects current implementation including recent changes |

## Validation Results

### Overall Scoring

| Criterion | Score | Weight | Weighted Score | Notes |
| --------- | ----- | ------ | -------------- | ----- |
| TDD Alignment | 2.0/3 | 25% | 0.50 | 0.1.1 TDD has start() ordering wrong; 1.1.1 TDD missing config param + 10 features; 0.1.2 TDD mostly current; 0.1.3 inline docs good |
| FDD Alignment | 2.25/3 | 25% | 0.56 | FDDs generally accurate; FDD-0-1-2 EC-3 wrong about duplicates; FDD-0-1-1 EC-2 correct; FDD-1-1-1 has dep numbering error |
| ADR Compliance | 2.5/3 | 20% | 0.50 | ADR-039 accurate; ADR-040 API count stale (10 vs 13); ADR-041 timer design outdated (per-path Timer vs heapq) |
| Feature State File Accuracy | 2.0/3 | 15% | 0.30 | Multiple stale method names, wrong field counts, missing test files documented as existing |
| Documentation Currency | 2.25/3 | 15% | 0.34 | Post-onboarding changes poorly propagated to TDDs/state files; inline docs and FDDs better maintained |
| **TOTAL** | | **100%** | **2.20/3.0** | |

### Scoring Scale

- **3 - Fully Met**: Exemplary implementation, no significant issues
- **2 - Mostly Met**: Solid implementation, minor issues identified
- **1 - Partially Met**: Major issues requiring attention
- **0 - Not Met**: Fundamental problems or not implemented

## Detailed Findings

### Feature 0.1.1 - Core Architecture

#### Strengths

- Module docstring in service.py accurately describes delegation pattern and common tasks
- FDD-0-1-1 (PD-FDD-022) correctly documents PD-BUG-053 event deferral in EC-2
- ADR-039 accurately describes Orchestrator/Facade pattern, lazy Observer creation, and signal handling
- `__init__` signature in TDD matches implementation

#### Issues Identified

| Severity | Issue | Impact | Recommendation |
| -------- | ----- | ------ | -------------- |
| Medium | TDD `start()` ordering: TDD shows scan→observer (`tdd-0-1-1-core-architecture-t3.md:208-214`), actual is observer→scan (`service.py:107-136`, PD-BUG-053) | Developers following TDD would implement wrong ordering, missing the critical event deferral mechanism | Update TDD Section 4.1 and component diagram to show observer-first ordering with begin_event_deferral/notify_scan_complete |
| Medium | TDD does not document `--validate` CLI flag or `LinkValidator` integration (`main.py:365-387`) | An entire operational mode is undocumented in the TDD | Add `--validate` to TDD Section 4.4 CLI arguments; document LinkValidator workflow |
| Medium | TDD states main.py ~80 LOC (`tdd-0-1-1-core-architecture-t3.md:Section 11.2`); actual is 408 LOC | Severely misleading size estimate; suggests scope has grown 5× without TDD update | Update LOC table in TDD Section 11.2 |
| Low | TDD `__init__.py __all__` missing `LinkDatabaseInterface` (`tdd-0-1-1-core-architecture-t3.md:Section 4.5` vs `__init__.py:__all__`) | Public API documentation incomplete | Add `LinkDatabaseInterface` to TDD Section 4.5 |
| Low | State file (PD-FIS-046) Section 8 lists `LinkReference` with wrong field names: `source_file`, `target_path` (5 fields) vs actual `file_path`, `link_target`, `column_start`, `column_end` (7 fields) (`models.py:7-14`) | State file contradicts both TDD and implementation | Update state file Section 8 Decision 3 |
| Low | State file lists `calculate_relative_path()` and `is_subpath()` as utils functions; actual names are `get_relative_path()` and `is_subpath` does not exist (`utils.py` has 8 functions) | Function references in state file are wrong | Update state file code inventory for utils.py |
| Low | State file lists test files `test_models.py` and `test_utils.py` as "Not Found on Disk" | Documented tests do not exist | Remove or create the missing test files |

#### Validation Details

**TDD Alignment (0.1.1)**: Score 1.75/3. The `start()` ordering discrepancy is the most critical issue — the TDD describes the pre-PD-BUG-053 design where scan runs before observer starts. The actual implementation (since PD-BUG-053) starts the observer first, activates event deferral, runs the scan, then replays deferred events. This is a deliberate and important design change that the TDD never captured. The `--validate` flag representing an entire operational mode is absent from the TDD. The FDD correctly captures the event deferral behavior in EC-2, creating an inconsistency between FDD and TDD for the same feature.

**FDD Alignment (0.1.1)**: Score 2.5/3. The FDD (PD-FDD-022) is more current than the TDD. EC-2 correctly describes the PD-BUG-053 fix. FR-8 covers lock file. All acceptance criteria are accurate. Minor issue: BR-3 says "~32 extensions default" but `DEFAULT_CONFIG` has ~30 and the dataclass default has 11.

**ADR Compliance (0.1.1)**: Score 3.0/3. ADR-039 accurately describes the Orchestrator/Facade pattern. Lazy Observer creation, daemon thread, try/finally cleanup, and single `self.running` boolean all match the implementation exactly.

### Feature 0.1.2 - In-Memory Link Database

#### Strengths

- TDD (PD-TDD-022) is the most accurate of the batch — correctly documents 13 abstract methods, 7 data structures, and the two-phase lookup algorithm
- Module docstring in database.py comprehensively describes index architecture and data flow
- All public methods have accurate docstrings matching their behavior

#### Issues Identified

| Severity | Issue | Impact | Recommendation |
| -------- | ----- | ------ | -------------- |
| Medium | FDD EC-3 states "no uniqueness enforcement" for duplicate LinkReferences (`fdd-0-1-2-in-memory-database.md:EC-3`); actual `add_link()` has a duplicate guard checking source file + line_number + column_start (`database.py:add_link`) | FDD contradicts implementation behavior | Update FDD EC-3 to document duplicate guard |
| Low | FDD BR-2 describes "three-level path resolution"; actual is 4-phase: direct + anchored + resolved (Phase 1) + suffix matching with extension-aware filtering (Phase 2) (`database.py:get_references_to_file`) | FDD understates lookup sophistication | Update FDD BR-2 to describe current resolution approach |
| Low | ADR-040 states "10-method public API" (`target-indexed-in-memory-link-database.md:Positive Consequences`); actual interface has 13 abstract members | API count is stale | Update ADR-040 consequence |
| Low | State file references `LinkDatabase.get_links_to_target()` (`0.1.2-in-memory-link-database-implementation-state.md:Section 5`); actual method is `get_references_to_file()` | Wrong method name in state file | Fix method name reference |
| Low | State file says `defaultdict(list)` structure; actual uses plain `dict` `{}` (`database.py:__init__`) | Minor structural inaccuracy | Update state file |
| Low | Module docstring lists 6 data structures in Index Architecture section; actual has 7 (omits `_basename_to_keys`) (`database.py:docstring`) | One index structure missing from module-level docs | Add `_basename_to_keys` to docstring Index Architecture |
| Low | FDD FR-7 says "statistics (total links count, total unique targets)"; actual `get_stats()` returns `{total_targets, total_references, files_with_links}` — 3 fields, different naming (`database.py:get_stats`) | Minor naming mismatch | Update FDD FR-7 |

#### Validation Details

**TDD Alignment (0.1.2)**: Score 2.5/3. The TDD was updated to reflect the expanded API (13 methods), data structures, and two-phase algorithm. It correctly documents `_basename_to_keys`, `_parser_type_extensions`, and `_key_to_resolved_paths`. The only remaining gap is the `get_all_targets_with_references()` return type previously flagged in PD-VAL-072 — verified: the interface signature in code is `-> Dict[str, List[LinkReference]]` which matches the TDD Section 3.4 listing.

**FDD Alignment (0.1.2)**: Score 2.0/3. The FDD has not been updated since its retrospective creation (2026-02-20). The duplicate guard contradiction (EC-3) and path resolution understatement (BR-2) are the main gaps.

**ADR Compliance (0.1.2)**: Score 2.5/3. ADR-040 core decisions (target-indexed storage, single lock, multi-level resolution) are all correctly implemented. The API count in consequences is stale (10 vs 13).

### Feature 0.1.3 - Configuration System

**Tier**: 1 (Simple). No TDD or FDD required. Substitute criterion: Configuration/Code Documentation Accuracy.

#### Strengths

- `LinkWatcherConfig` class docstring clearly documents precedence order and configuration groups
- All 6 public methods have accurate docstrings
- Module docstring AI Context section correctly describes entry point and precedence chain
- `validate()` constraints are clearly expressed and match implementation
- `_from_dict()` type coercion logic is well-documented in code comments

#### Issues Identified

| Severity | Issue | Impact | Recommendation |
| -------- | ----- | ------ | -------------- |
| Low | `DEFAULT_CONFIG` in `defaults.py` has 30+ monitored extensions vs dataclass default of 11 extensions in `settings.py`; no documentation explains why two different defaults exist | Confusion about which default applies in which context | Add comment in defaults.py explaining relationship to dataclass defaults |
| Low | Config example YAML files missing 6+ fields: `enable_powershell_parser`, `parser_type_extensions`, `python_source_root`, `move_detect_delay`, `dir_move_max_timeout`, `dir_move_settle_delay` | Users won't know about these config options from examples | Add missing fields to at least one example file |
| Low | `from_env()` docstring doesn't mention specific env var names for newer fields (e.g., `LINKWATCHER_VALIDATION_IGNORED_PATTERNS`, `LINKWATCHER_MOVE_DETECT_DELAY`) | Users must read source to discover env var support for newer fields | Add examples of newer env vars to docstring |
| Low | Feature state file (PD-FIS-048) "Last Updated: 2026-02-21" but enhancement PF-STA-066 (validation_ignored_patterns) completed 2026-03-26 | State file header is stale | Update state file timestamp |

#### Validation Details

**Inline Documentation Accuracy (0.1.3, TDD substitute)**: Score 2.5/3. Settings.py has good documentation quality overall. The class docstring, method docstrings, and AI Context section are all accurate. The main gaps are the undocumented DEFAULT_CONFIG/dataclass divergence and incomplete config example files.

**Feature State File Accuracy (0.1.3)**: Score 2.0/3. Stale timestamp. Enhancement PF-STA-066 content was appended but the header wasn't refreshed.

### Feature 1.1.1 - File System Monitoring

#### Strengths

- Handler.py module docstring is excellent — comprehensive Event Dispatch Tree, Move Detection Strategies, Key Collaborators, and AI Context sections
- FDD (PD-FDD-024) correctly documents PD-BUG-053 (EC-8) and PD-BUG-071 (EC-9) edge cases
- Code comments throughout handler.py reference bug IDs and design decisions clearly

#### Issues Identified

| Severity | Issue | Impact | Recommendation |
| -------- | ----- | ------ | -------------- |
| Medium | TDD `LinkMaintenanceHandler.__init__` missing `config` parameter (`tdd-1-1-1-file-system-monitoring-t2.md:99-100` shows 6 params; actual `handler.py:119` has 7 including `config=None`) | Config-driven behavior (move_detect_delay, dir_move timing) not reflected in TDD | Add `config` parameter to TDD signature |
| Medium | TDD does not document event deferral mechanism: `begin_event_deferral()`, `notify_scan_complete()`, `_deferred_events`, `_deferred_lock`, `_scan_complete` (`handler.py:215-260`) — added for PD-BUG-053 | Critical startup mechanism absent from TDD | Add event deferral section to TDD |
| Medium | ADR-041 describes per-path `threading.Timer` design for MoveDetector (`timer-based-move-detection-with-3-phase-directory-batch-algorithm.md:Decision 1`); TD107 replaced with single worker thread + heapq (`move_detector.py:__init__` creates one daemon worker thread) | ADR describes a design that no longer exists | Update ADR-041 Decision 1 to reflect heapq + worker thread |
| Medium | TDD phase numbering uses 1, 1b, 2, 3; actual code uses 0, 1, 1b, 1c, 1.5, 2 (`handler.py:_handle_directory_moved` comments) — Phase 0 (update_source_path) and Phase 1c (cleanup/rescan) not in TDD | Phase documentation inconsistent with implementation | Update TDD phase numbering to match code |
| Low | TDD does not document `on_error(self, event)` handler (`handler.py:273-283`) | Error handling for observer thread death not documented | Add on_error to TDD event routing |
| Low | TDD does not document `_is_known_reference_target()` and PD-BUG-046 non-monitored known targets logic (`handler.py:163-168, 786-800`) | Important edge case handling undocumented | Add to TDD |
| Low | TDD does not document `has_pending` property on MoveDetector (`move_detector.py:70-72`) | Public interface gap | Add property to TDD |
| Low | TDD does not document `_stats_lock` for thread-safe statistics (`handler.py:155`, PD-BUG-026) | Threading detail omitted | Add to TDD |
| Low | State file says handler.py is 474 LOC; actual is 844 LOC | LOC nearly doubled since onboarding without state file update | Update state file LOC |
| Low | FDD references "0.1.3 In-Memory Database" (`fdd-1-1-1-file-system-monitoring.md:Dependencies`); should be "0.1.2 In-Memory Database" | Feature numbering error | Fix dependency number |
| Low | PD-BUG-075 fix in `dir_move_detector.py:get_files_under_directory()` not documented in TDD | Recent bug fix not reflected | Add note to TDD |
| Low | Performance metric logging throughout detectors (`self._logger.performance.log_metric(...)`) not mentioned in TDD | Implementation detail not documented | Low priority — add if TDD is updated |

#### Validation Details

**TDD Alignment (1.1.1)**: Score 1.75/3. The TDD has the most gaps of any feature in this batch. It was last substantively updated 2026-03-16 (PF-STA-058) but significant changes have occurred since: PD-BUG-053 event deferral, Phase 0 addition, TD107 heapq refactor, TD128 deferred rescan deduplication, and multiple methods extracted. The handler.py has nearly doubled in size (474→844 LOC) since the TDD was written. The TDD remains useful as a structural reference but is increasingly divergent from the implementation.

**FDD Alignment (1.1.1)**: Score 2.5/3. The FDD was updated to include PD-BUG-053 and PD-BUG-071 edge cases, making it more current than the TDD for bug fix behaviors. Main gap is the dependency numbering error (0.1.3 vs 0.1.2).

**ADR Compliance (1.1.1)**: Score 2.0/3. ADR-041 core concept (delete+create correlation, dual-timer strategy) is correctly implemented. However, the MoveDetector implementation detail (per-path Timer → heapq worker) is wrong in the ADR. ADR-041 was created 2026-03-27, the same day as TD107, but documents the pre-TD107 design.

## Recommendations

### Immediate Actions (High Priority)

- Update TDD-0-1-1 `start()` ordering to reflect observer-first design (PD-BUG-053) — est. 15 min
- Update TDD-1-1-1 `LinkMaintenanceHandler.__init__` to add `config` parameter and document event deferral mechanism — est. 30 min
- Update ADR-041 Decision 1 to describe heapq + single worker thread (TD107) — est. 15 min

### Medium-Term Improvements

- Update TDD-0-1-1 to document `--validate` mode and main.py growth (408 LOC) — est. 20 min
- Update FDD-0-1-2 EC-3 to document duplicate guard, BR-2 for 4-phase resolution — est. 15 min
- Update TDD-1-1-1 phase numbering (0, 1, 1b, 1c, 1.5, 2) and add missing methods — est. 30 min
- Clean up feature state files: fix stale method names, field counts, LOC — est. 30 min

### Long-Term Considerations

- Consider establishing a "TDD sync" step in bug-fixing and refactoring task completion checklists to prevent future TDD drift
- Create Integration Narratives for WF-003 (Startup) workflow — all 4 features participate but no narrative exists
- Evaluate whether feature state file LOC/method counts should be dropped entirely (they go stale quickly and add no value over reading the code)

## Cross-Feature Analysis

### Patterns Observed

- **Positive Patterns**: Module docstrings are consistently high quality across all 4 features — they include AI Context sections, entry points, and common tasks. FDDs are better maintained for edge cases than TDDs.
- **Negative Patterns**: TDDs have not been updated after post-onboarding bug fixes and refactoring. Feature state files accumulate stale method names, function references, and LOC counts. All retrospective documents (created 2026-02-19/20) show the same drift pattern — they captured a snapshot that is now ~7 weeks old.
- **Inconsistencies**: FDD-0-1-1 EC-2 correctly documents PD-BUG-053 behavior but TDD-0-1-1 does not. ADR-041 created same day as TD107 but documents pre-TD107 design.

### Integration Points

- Service.py (0.1.1) creates `LinkMaintenanceHandler` (1.1.1) with `config` parameter — TDD-1-1-1 doesn't show this parameter, so the integration point is incompletely documented
- `LinkDatabaseInterface` (0.1.2) is exported in `__init__.py` but not in TDD-0-1-1's `__all__` list — the public API surface for consumers is misrepresented
- `DEFAULT_CONFIG` (0.1.3) vs dataclass defaults creates ambiguity about which defaults apply at the service level (0.1.1)

### Workflow Impact

- **Affected Workflows**: WF-003 (Startup) — all 4 features participate
- **Cross-Feature Risks**: The `start()` ordering discrepancy in TDD-0-1-1 could mislead anyone implementing a similar pattern for a different project. The event deferral mechanism (handler.begin_event_deferral → service._initial_scan → handler.notify_scan_complete) spans features 0.1.1 and 1.1.1 but is only partially documented in each.
- **Recommendations**: Create Integration Narrative for WF-003 to document the full startup sequence across service, handler, and database features.

## Root Cause Analysis

### Why TDDs Drift

The TDDs were created retrospectively during framework onboarding (PF-TSK-066, 2026-02-19). Since then, bug fixes (PD-BUG-053, PD-BUG-046, PD-BUG-071, PD-BUG-075) and refactoring (TD107, TD128) have changed the implementation. The Bug Fixing task (PF-TSK-028) does not include a step to update TDDs. The Code Refactoring task (PF-TSK-037) also lacks explicit TDD update requirements in its completion checklist.

**Process Improvement Opportunity**: Add "Update TDD if implementation changes affect documented interfaces, algorithms, or startup sequences" to Bug Fixing and Code Refactoring completion checklists.

### Why State Files Drift

Feature state files were created during onboarding and are rarely revisited. They contain snapshot data (LOC counts, method lists) that goes stale rapidly. The Feature Enhancement task (PF-TSK-084) does update state files, but bug fixes and refactoring do not.

## Next Steps

- [ ] **Re-validation Required**: 1.1.1 File System Monitoring (most gaps; re-validate after TDD update)
- [ ] **Additional Validation**: None — documentation gaps don't affect runtime behavior
- [ ] **Update Validation Tracking**: Record results in validation tracking file
