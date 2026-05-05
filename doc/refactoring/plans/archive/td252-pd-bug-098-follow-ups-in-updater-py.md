---
id: PD-REF-219
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
target_area: src/linkwatcher/updater.py
priority: Medium
refactoring_scope: TD252 PD-BUG-098 follow-ups in updater.py
mode: lightweight
debt_item: TD252
---

# Lightweight Refactoring Plan: TD252 PD-BUG-098 follow-ups in updater.py

- **Target Area**: src/linkwatcher/updater.py
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Completed
- **Debt Item**: TD252
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD252 — PD-BUG-098 follow-ups in updater.py

**Scope**: Four small follow-ups to PD-BUG-098 fix in [src/linkwatcher/updater.py](../../../../src/linkwatcher/updater.py) (feature 2.2.1, workflows WF-001/002/004/005/007/008): (1) clarify `_filter_contained_overlaps` docstring that only strictly-contained overlap is handled; (2) make `_replace_at_position` invalid-column ambiguous-fallback (>1 occurrences) increment an `errors` counter via a new return signal so `_apply_replacements` can surface it in `UpdateStats["errors"]` (Option C — visibility without whole-file STALE blast radius); (3) shorten two E501 lines (warning-log `reason=` strings at lines 469 and 602); (4) replace bare `set` annotation with `typing.Set[int]` for consistency with surrounding `Dict`/`List`/`Tuple` annotations.

**Changes Made**:
- [x] Finding 1: Added explicit "Scope — strictly-contained overlap only" paragraph to `_filter_contained_overlaps` docstring noting that partial overlap is not addressed and would still produce bottom-up corruption
- [x] Finding 2 (Option C): Added `self._ambiguous_skip_count: int = 0` in `__init__`; reset at start of `_update_file_references` and `_update_file_references_multi`; incremented in `_replace_at_position`'s `occurrences > 1` branch right after the existing warning log; aggregated into `stats["errors"]` after each per-file call in `update_references` and `update_references_batch`. No public API change — all signatures unchanged.
- [x] Finding 3: Replaced single-line `reason="..."` with parenthesized implicit string concatenation across two lines at the two warning-log sites (formerly lines 469 and 602; now within 100-char limit)
- [x] Finding 4: Added `Set` to `from typing import Dict, List, Set, Tuple, TypedDict`; changed `dropped_indices: set = set()` to `dropped_indices: Set[int] = set()`

**Test Baseline**: 838 passed, 3 skipped, 4 deselected (`not slow`), 4 xfailed, 0 failed, 0 errors (captured 2026-04-29 via `Run-Tests.ps1 -All` followed by `pytest test/automated/ -m "not slow"` for counts)
**Test Result**: 839 passed, 3 skipped, 4 deselected, 4 xfailed, 0 failed, 0 errors. Diff vs. baseline: **+1 passed** (new test `test_ambiguous_fallback_increments_errors_count` in `TestOverlappingReferenceCorruption`); **0 regressions**.

**Documentation & State Updates**:
- [x] Feature implementation state file (2.2.1) updated — added TD252 entry to Implementation Tasks section after TD251 entry, following established format
- [x] TDD (2.2.1) — N/A: grepped `tdd-2-2-1-link-updater-t2.md` for `_replace_at_position`, `_filter_contained_overlaps`, `UpdateStats`, `errors`. The TDD documents `_replace_at_position` only at one-line API granularity ("column-offset replacement; special cases for python-import and quoted types") and lists `errors` as an `UpdateStats` field without defining what increments it. Adding ambiguous-fallback skips to the `errors` count is a behavioral refinement of an already-documented field, not a new data structure, algorithm rewrite, or storage layout change. Docstring update for `_filter_contained_overlaps` is below TDD detail level.
- [x] Test spec (2.2.1) — N/A: grepped `test-spec-2-2-1-link-updating.md` — only mentions `_replace_at_position` at high level (line 122). Spec does not document `errors` semantics or ambiguous-fallback behavior. New behavior is captured in the new unit test `test_ambiguous_fallback_increments_errors_count`, which is the primary spec artifact for that behavior.
- [x] FDD (2.2.1) — N/A: grepped `fdd-2-2-1-link-updater.md` for `errors`, `_replace_at_position`. FR-7 says "tracks statistics (`files_updated`, `references_updated`, `errors`)". My change makes the `errors` count *more accurate* (it now reflects ambiguous-fallback skips, which were previously silent failures). The FR-7 contract is unchanged — the field still tracks errors; it just tracks them more completely.
- [x] ADR — N/A: no ADRs reference `_replace_at_position`, `_filter_contained_overlaps`, `UpdateStats`, or feature 2.2.1 directly (verified via `find doc/technical/adrs ... | xargs grep -l ...`). All four findings are below ADR-level concerns (no architectural decisions affected).
- [x] Integration Narrative — N/A: 6 narratives reference `UpdateStats` / `_replace_at_position` (`single-file-move`, `directory-move`, `multi-format-file-move`, `rapid-sequential-moves`, `configuration-change`, `link-health-audit`). All mention the field list `(files_updated, references_updated, errors, stale_files)` without defining `errors` semantics. My change extends what counts as an error without changing the field set, signal flow, or any narrative-level component interaction.
- [x] Validation tracking — N/A: TD252 was created from PD-BUG-098 code review (2026-04-29), not from a validation round. Grepped `validation-tracking-3.md` and `validation-tracking-4.md` — neither references TD252 or PD-BUG-098. Active round 4 has 2.2.1 with status Completed; this small CQ refactor doesn't change that status.
- [ ] Technical Debt Tracking: TD item marked resolved _[done in L10 via Update-TechDebt.ps1]_

**Bugs Discovered**: None — implementation went cleanly. Note: the `pyproject.toml` (line-length=120) vs. `.pre-commit-config.yaml` (black/isort line-length=100) inconsistency was observed during Finding 3 (the audit's "E501" label is technically wrong because flake8 uses 120, but black/isort under pre-commit do flag the lines). This is a separate config inconsistency — not a TD252 finding, not in scope for this refactor.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD252 | Complete | None | Feature state file 2.2.1 (Implementation Tasks entry); TDD/FDD/test-spec/ADRs/integration-narratives/validation-tracking all N/A with verified justifications |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
