---
id: PD-REF-192
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-28
updated: 2026-04-28
priority: Low
debt_item: TD211
refactoring_scope: Fix stale Phase 2 docstring in _apply_replacements (TD211)
mode: lightweight
target_area: src/linkwatcher/updater.py
---

# Lightweight Refactoring Plan: Fix stale Phase 2 docstring in _apply_replacements (TD211)

- **Target Area**: src/linkwatcher/updater.py
- **Priority**: Low
- **Created**: 2026-04-28
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD211
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD211 — Stale Phase 2 description in `_apply_replacements` docstring

**Scope**: The `_apply_replacements` docstring in [updater.py:258-268](src/linkwatcher/updater.py#L258-L268) describes Phase 2 as performing module usage replacement "via word-boundary regex". The PD-BUG-094 fix changed the actual regex to `(?<![.\w])` + `re.escape(old_module)` + `(?!\w)` (negative lookbehind + negative lookahead) — see [updater.py:363](src/linkwatcher/updater.py#L363). Update the docstring text to match the implementation.

**Drift mechanism (DA root cause)**: The PD-BUG-094 fix (regex change) added a correct inline comment at the change site (lines 356-362) explaining why plain `\b` was unsafe and what replaced it, but the higher-level Phase 2 description embedded in the function's main docstring (line 267) was not updated synchronously. The drift originated in the same session that introduced the bug fix — local-comment update without function-level docstring sweep.

**Changes Made**:
- [x] Replaced "via word-boundary regex" (4-line description) with 7-line description of the actual regex (negative lookbehind `(?<![.\w])` + negative lookahead `(?!\w)`) including PD-BUG-094 rationale referencing the `\b` between `.` and a letter pitfall — see [updater.py:264-271](src/linkwatcher/updater.py#L264-L271)

**Test Baseline**: 807 passed, 5 skipped, 5 deselected, 4 xfailed, 0 failed
**Test Result**: 807 passed, 5 skipped, 5 deselected, 4 xfailed, 0 failed — **identical to baseline, no regressions**

**Test Coverage Assessment (L4)**: N/A — docstring text change only, no code paths modified. Existing tests for `_apply_replacements` remain valid.

**Documentation & State Updates**:
<!-- Documentation-only shortcut applied (L8): docstring-only change in a .py file with no behavioral impact -->
- [x] Items 1-7 batched as N/A — _Documentation-only change (docstring text): no behavioral code change; design and state documents do not reference the docstring text or describe the regex implementation choice._
- [x] Technical Debt Tracking: TD item marked resolved (via Update-TechDebt.ps1)

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD211 | Complete | None | None (documentation-only shortcut applied) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

