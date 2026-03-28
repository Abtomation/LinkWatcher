---
id: PD-REF-090
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
refactoring_scope: Extract duplicated quoted path regex to shared parsers/patterns.py
priority: Medium
target_area: linkwatcher/parsers
mode: lightweight
---

# Lightweight Refactoring Plan: Extract duplicated quoted path regex to shared parsers/patterns.py

- **Target Area**: linkwatcher/parsers
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Dependencies and Impact
- **Affected Components**: `linkwatcher/parsers/patterns.py` (new), `generic.py`, `markdown.py`, `python.py`, `powershell.py`, `dart.py`
- **Internal Dependencies**: All 5 parsers import from new `patterns.py`; no external consumers affected (patterns are internal implementation detail)
- **Risk Assessment**: Low — extracting compile-time constants; regex behavior identical; full test suite validates

## Item 1: TD087 — Extract duplicated quoted path regex to shared constants module

**Scope**: Create `linkwatcher/parsers/patterns.py` with pre-compiled shared regex constants (`QUOTED_PATH_PATTERN`, `QUOTED_DIR_PATTERN`, `QUOTED_DIR_PATTERN_STRICT`). Replace inline `re.compile()` calls in 5 parsers with imports from this module. The PowerShell parser uses a stricter dir pattern variant (`[^\'"]+` vs `[^\'"]*` at end) which is preserved as a separate constant.

**Changes Made**:
- [x] Create `linkwatcher/parsers/patterns.py` with `QUOTED_PATH_PATTERN`, `QUOTED_DIR_PATTERN`, `QUOTED_DIR_PATTERN_STRICT`
- [x] Update `generic.py` to import from `patterns`
- [x] Update `markdown.py` to import from `patterns`
- [x] Update `python.py` to import from `patterns`
- [x] Update `powershell.py` to import from `patterns`
- [x] Update `dart.py` to import from `patterns`

**Test Baseline**: 592 passed, 5 skipped, 7 xfailed
**Test Result**: 592 passed, 5 skipped, 7 xfailed (1 pre-existing benchmark flake — unrelated)

**Documentation & State Updates**:
- [x] Feature implementation state file (2.1.1) updated, or N/A: _N/A — grepped state file; references to `quoted_pattern` are historical descriptions of attribute names which are preserved unchanged_
- [x] TDD (PD-TDD-025) updated, or N/A: _N/A — grepped TDD; mentions `quoted_pattern` as PowerShellParser attribute name in component table, attribute name unchanged_
- [x] Test spec (TE-TSP-039) updated, or N/A: _N/A — no references to internal regex patterns, only validates parsing behavior_
- [x] FDD (PD-FDD-026) updated, or N/A: _N/A — grepped FDD; no references to specific regex constants_
- [x] ADR updated, or N/A: _N/A — no ADR for parser internals; grepped ADR directory — no hits_
- [x] Validation tracking updated, or N/A: _N/A — internal constant extraction doesn't affect validation results_
- [x] Technical Debt Tracking: TD087 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD087 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
