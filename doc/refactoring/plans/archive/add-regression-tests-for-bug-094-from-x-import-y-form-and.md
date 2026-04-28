---
id: PD-REF-193
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-28
updated: 2026-04-28
refactoring_scope: Add regression tests for BUG-094 'from X import Y' form and multi-rename order-independence
priority: Low
debt_item: TD212,TD213
target_area: test/automated/integration/test_link_updates.py::TestBug094PythonImportDoubleApply
mode: lightweight
---

# Lightweight Refactoring Plan: Add regression tests for BUG-094 'from X import Y' form and multi-rename order-independence

- **Target Area**: test/automated/integration/test_link_updates.py::TestBug094PythonImportDoubleApply
- **Priority**: Low
- **Created**: 2026-04-28
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Debt Item**: TD212,TD213
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD212 — Regression test for `from X import Y` form in Phase 2 module usage replacement

**Scope**: BUG-094 introduced a negative-lookbehind regex `(?<![.\w])` in `updater.py:363` to prevent double-application of module-rename prefixes. Existing tests in `TestBug094PythonImportDoubleApply` only exercise the `import X` + `X.usage` forms. The lookbehind logic *should* also handle the `from X import Y` form when the new module contains the old as a prefix (e.g., `from utils.helpers import f` after move from `utils/` → `src/utils/`), but this is currently only reasoned about, not verified. Add a regression test that exercises the `from X import Y` form in the prefix-overlap scenario.

**Dimension**: TST (Testing) — coverage gap, no production code change.

**Changes Made**:
- [x] Added `test_bug094_from_import_no_double_prefix` to `TestBug094PythonImportDoubleApply`

**Test Baseline**: 807 passed, 5 skipped, 5 deselected, 4 xfailed, 0 failed, 0 errors (44.00s, `pytest -m "not slow"`).
**Test Result**: New test passes. Full-suite re-run showed flaky failures in performance benchmarks (BM-001, BM-002, BM-004, PH-004) that fluctuate around hard timing thresholds — these match issues already tracked by TD215 (loose tolerances) and TD216 (missing warmup cycles) and are environmental, not caused by this session (changes are test-only additions to integration test file).

**Documentation & State Updates**:
<!-- Test-only shortcut applies: items 1-7 batched as N/A -->
- [x] Items 1–7: N/A — _Test-only refactoring; no production code changes; design and state documents do not reference test internals._
- [ ] Technical Debt Tracking: TD212 marked resolved

**Bugs Discovered**: None

## Item 2: TD213 — Regression test for multi-rename order-independence in Phase 2 module usage replacement

**Scope**: When `python_module_renames` has multiple entries (e.g., both `utils.a` and `utils.b` are renamed in the same file move), the lookbehind `(?<![.\w])` is intended to make substitution order-independent. This is by design but not verified. Add a regression test that exercises Phase 2 with 2+ rename entries and asserts that the result is correct.

**Dimension**: TST (Testing) — coverage gap, no production code change.

**Changes Made**:
- [x] Added `test_bug094_phase2_multi_rename_order_independent` (direct `_apply_replacements` call with manually-crafted unique PYTHON_IMPORT refs) to `TestBug094PythonImportDoubleApply`. This isolates Phase 2 lookbehind verification from the dir-move ref-collection path.
- [x] Added `test_bug094_dir_move_multi_import_no_double_prefix` (xfail strict, ref PD-BUG-096) — integration-level coverage of the same intent at the dir-move layer; will pass once PD-BUG-096 is fixed.

**Test Baseline**: 807 passed, 5 skipped, 5 deselected, 4 xfailed, 0 failed, 0 errors (same baseline as Item 1).
**Test Result**: Direct Phase 2 test passes (verifies lookbehind cooperation for multi-rename). Integration-level test xfails strict against PD-BUG-096 as expected. Same flaky perf-test environmental fluctuations noted in Item 1 — not regression.

**Documentation & State Updates**:
<!-- Test-only shortcut applies: items 1-7 batched as N/A -->
- [x] Items 1–7: N/A — _Test-only refactoring; no production code changes; design and state documents do not reference test internals._
- [ ] Technical Debt Tracking: TD213 marked resolved

**Bugs Discovered**: **PD-BUG-096** — Directory move with multiple Python imports double-prefixes import statements. The TD213 integration test (initially designed to exercise Phase 2 multi-rename via `DirMovedEvent`) uncovered that `_handle_directory_moved` ([handler.py:454-466](/src/linkwatcher/handler.py#L454-L466)) duplicates each moved file's PYTHON_IMPORT references in `move_groups` (once as `file_refs`, once as `module_refs`), causing Phase 1's unbounded `str.replace` ([updater.py:476](/src/linkwatcher/updater.py#L476)) to substring-match inside the already-prefixed result. Phase 2's negative lookbehind correctly protects against this; Phase 1 has no such guard. Reproduced via debug trace showing 4 replacement_items where each ref appears twice. Filed as bug; xfail-strict integration test in place to catch the fix.

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD212 | Complete | None | None (test-only) |
| 2 | TD213 | Complete | PD-BUG-096 | None (test-only) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

