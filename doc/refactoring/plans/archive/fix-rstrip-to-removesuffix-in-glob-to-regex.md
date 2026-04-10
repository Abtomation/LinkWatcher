---
id: PD-REF-171
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
priority: High
debt_item: TD182
mode: lightweight
target_area: Link Validation
refactoring_scope: Fix rstrip to removesuffix in _glob_to_regex
feature_id: 6.1.1
---

# Lightweight Refactoring Plan: Fix rstrip to removesuffix in _glob_to_regex

- **Target Area**: Link Validation
- **Priority**: High
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Debt Item**: TD182
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD182 — Replace rstrip with removesuffix in _glob_to_regex

**Scope**: In `linkwatcher/validator.py:600`, `_glob_to_regex()` uses `.rstrip(r"\Z").rstrip("$")` to strip the `fnmatch.translate()` anchor. `rstrip` strips individual characters from a set, not a substring — semantically incorrect. Replace with `.removesuffix(r"\Z").removesuffix("$")` which is the correct operation. No behavioral change for current inputs (the `)` in fnmatch output acts as a natural boundary), but prevents a latent bug if fnmatch output format changes. **Dims: CQ**.

**Changes Made**:
- [x] Replace `rstrip(r"\Z").rstrip("$")` with `removesuffix(r"\Z").removesuffix("$")` in `linkwatcher/validator.py:587`
- [x] Bump `requires-python` from `>=3.8` to `>=3.9` in `pyproject.toml`
- [x] Remove `Programming Language :: Python :: 3.8` classifier from `pyproject.toml`
- [x] Update `[tool.mypy] python_version` from `3.8` to `3.9` in `pyproject.toml`
- [x] Update README badge and requirements section from 3.8 to 3.9

**Test Baseline**: 758 passed, 5 skipped, 4 deselected, 4 xfailed, 0 failures
**Test Result**: 758 passed, 5 skipped, 4 deselected, 4 xfailed, 0 failures — identical to baseline

**Documentation & State Updates**:
- [x] Feature implementation state file (6.1.1) updated, or N/A — _Grepped state file for `_glob_to_regex` and `rstrip` — no references_
- [x] TDD (6.1.1) updated, or N/A — _No interface or design change; `rstrip` hit in tdd-0-1-2 is unrelated code sample_
- [x] Test spec (6.1.1) updated, or N/A — _Grepped test specs — no references to changed method_
- [x] FDD (6.1.1) updated, or N/A — _No functional change_
- [x] ADR (6.1.1) updated, or N/A — _Grepped ADR directory — no references_
- [x] Validation tracking updated, or N/A — _Change doesn't affect validation findings — same behavior_
- [x] Technical Debt Tracking: TD182 marked resolved

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD182 | Complete | None | README, pyproject.toml (Python version bump) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
