---
id: PD-REF-215
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
mode: lightweight
debt_item: TD251
priority: Medium
refactoring_scope: Phase-1 idempotency guard for PYTHON_IMPORT in _replace_at_position; reorder PYTHON_IMPORT filter in collect_directory_file_refs
target_area: linkwatcher.updater + linkwatcher.reference_lookup
---

# Lightweight Refactoring Plan: Phase-1 idempotency guard for PYTHON_IMPORT in _replace_at_position; reorder PYTHON_IMPORT filter in collect_directory_file_refs

- **Target Area**: linkwatcher.updater + linkwatcher.reference_lookup
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Debt Item**: TD251
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD251 — Phase-1 idempotency guard for PYTHON_IMPORT (defense-in-depth) + filter reorder

**Dimension (TD Dims column)**: DI (Data Integrity)

**Scope**:

Two related changes to harden the PYTHON_IMPORT replacement path against duplicate-application corruption (PD-BUG-096 class):

1. **Add Phase-1 idempotency guard** in [`_replace_at_position`](src/linkwatcher/updater.py#L469-L476) for `LinkType.PYTHON_IMPORT`. Currently uses unbounded `line.replace(ref.link_text, new_import_text)`, which would substring-match inside an already-prefixed import if any future caller produced duplicate refs. Replace with a bounded regex matching Phase 2's pattern (`(?<![.\w]) + re.escape(old_module) + (?!\w)`, see [updater.py:367](src/linkwatcher/updater.py#L367), PD-BUG-094 fix) so a second application is a safe no-op. The collection-layer fix in `reference_lookup.collect_directory_file_refs` (PD-BUG-096) currently prevents duplicates from reaching this method, but that single guard is the only thing standing between a future regression and silent file corruption.

2. **Reorder the PYTHON_IMPORT filter** in [`collect_directory_file_refs`](src/linkwatcher/reference_lookup.py#L336-L348). Currently `module_references` is computed first using the unfiltered `file_references`, then `file_references` is filtered. Move the filter before the module-reference lookup so the intent ("PYTHON_IMPORT refs belong only in `module_references`") is clear at first read. No behavior change — `module_references` is computed via `link_db.get_references_to_file(old_module_path)` which doesn't depend on `file_references`.

**Why now**: PD-BUG-096 was a High-severity silent-corruption bug. The current fix is a single thin barrier; defense-in-depth at the replacement layer eliminates the latent hazard.

**Affected Workflows**: WF-001, WF-002, WF-005 (per PD-BUG-096 metadata) — single file rename, single file move, directory move scenarios involving Python imports.

**Changes Made**:
- [x] Replaced unbounded `line.replace` in `_replace_at_position` (PYTHON_IMPORT branch, [updater.py:472-483](src/linkwatcher/updater.py#L472-L483)) with bounded regex `(?<![.\w]) + re.escape(ref.link_text) + (?!\w)`, mirroring Phase 2's PD-BUG-094 pattern.
- [x] Reordered the PYTHON_IMPORT filter in [reference_lookup.py:336-348](src/linkwatcher/reference_lookup.py#L336-L348) to execute before the `module_references = link_db.get_references_to_file(...)` lookup. Pure stylistic reorder; behavior unchanged.
- [x] Added `TestPythonImportIdempotency` to [test/automated/unit/test_updater.py](test/automated/unit/test_updater.py) with 3 tests: `test_first_application_updates_import` (sanity), `test_second_application_is_no_op` (idempotency property), `test_dot_preceded_module_not_replaced` (negative-lookbehind property).

**Test Baseline** (captured 2026-04-29 via `python -m pytest test/automated/ -m "not slow" --tb=no -q`):
- 830 passed, 1 failed (pre-existing), 3 skipped, 4 deselected, 4 xfailed
- Pre-existing failure: `test/automated/unit/test_validator.py::TestLinkValidator::test_linkwatcher_local_dir_ignored`

**Test Result** (post-refactor, 2026-04-29):
- 834 passed, 0 failed, 3 skipped, 4 deselected, 4 xfailed (101.48s)
- **+3 new tests** (`TestPythonImportIdempotency` class) all passing.
- **0 regressions.** The baseline's pre-existing 1 failed test (`test_linkwatcher_local_dir_ignored`) was unrelated to TD251 — caused by uncommitted parallel-session edits to `validator.py` + `test_validator.py` (test renamed from `test_linkwatcher_run_dir_ignored` → `test_linkwatcher_dir_ignored`). After the refactor, `test_validator.py` is fully clean (111 passed).
- All 6 PD-BUG-094/096 regression tests in `TestBug094PythonImportDoubleApply` still passing.

**Documentation & State Updates**:
- [x] Feature implementation state file (2.2.1 + 1.1.1) updated — added Refactoring Activity entries in both files (2.2.1 owns updater.py, 1.1.1 owns reference_lookup.py).
- [x] TDD (PD-TDD-026, 2.2.1) — N/A. Grepped TDD: it documents `_replace_at_position` at the dispatch level only ("Column-offset replacement for non-markdown link types; includes special handling for `python-import`"); does not specify the str.replace vs. re.sub implementation. Refactor preserves documented behavior. Phase 2's PD-BUG-094 lookbehind guard is also not in the TDD, so the analogous Phase-1 guard is consistent with the existing documentation level.
- [x] Test spec (test-spec-2-2-1-link-updating.md) — N/A. References `_replace_at_position` by name only; doesn't specify implementation strategy. New unit tests tracked via test-tracking.md count update (41 → 44).
- [x] FDD (PD-FDD-027, 2.2.1) — N/A. References `_replace_at_position` only as part of dispatch (FR-5, EC-3); no functional requirement change.
- [x] ADR — N/A. Grepped `doc/technical/adrs/`: no ADR documents Python import replacement strategy.
- [x] Integration Narrative — Updated [multi-format-file-move-integration-narrative.md:132](doc/technical/integration/multi-format-file-move-integration-narrative.md#L132) (the only narrative that explicitly mentioned `line.replace(ref.link_text, new_import_text)`). Now describes the bounded-regex pattern with a TD251 reference. `single-file-move-integration-narrative.md` and `directory-move-integration-narrative.md` reference `_replace_at_position` only at dispatch level — no update needed.
- [x] Validation tracking — N/A. Feature 2.2.1 is not in an active validation round; closed validation reports (PD-VAL-059 etc.) are historical snapshots and are not retroactively updated.
- [x] Technical Debt Tracking: TD251 marked resolved in L10 below (via Update-TechDebt.ps1).

**Bugs Discovered**: None.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status   | Bugs Found | Doc Updates                                                                                                |
| ---- | ------- | -------- | ---------- | ---------------------------------------------------------------------------------------------------------- |
| 1    | TD251   | Complete | None       | multi-format-file-move-integration-narrative.md (line 132); 1.1.1 + 2.2.1 feature state files; test-tracking.md (test count 41→44) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
