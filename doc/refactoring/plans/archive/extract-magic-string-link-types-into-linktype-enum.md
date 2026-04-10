---
id: PD-REF-167
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
priority: Medium
mode: lightweight
target_area: linkwatcher (cross-cutting)
refactoring_scope: Extract magic string link types into LinkType enum
---

# Lightweight Refactoring Plan: Extract magic string link types into LinkType enum

- **Target Area**: linkwatcher (cross-cutting)
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD181 — Extract magic string link types into LinkType enum

**Scope**: 38 unique link type magic strings (including derived powershell variants) scattered across 11 files in linkwatcher/ with no central definition. Created `LinkType(str, Enum)` in `linkwatcher/link_types.py` with 38 members and replaced all string literals with enum members. Using `str` mixin ensures backward compatibility — `LinkType.MARKDOWN == "markdown"` is `True`, so no interface change.

**Dims**: CQ (Code Quality)

**Changes Made**:
- [x] Created `linkwatcher/link_types.py` with `LinkType(str, Enum)` containing 38 members (7 parser families + legacy)
- [x] Updated `linkwatcher/parsers/markdown.py` — replaced 10 string literals with enum members
- [x] Updated `linkwatcher/parsers/python.py` — replaced 6 string literals
- [x] Updated `linkwatcher/parsers/yaml_parser.py` — replaced 3 string literals (1 conditional + 2 direct)
- [x] Updated `linkwatcher/parsers/json_parser.py` — replaced 2 string literals (1 conditional + 1 direct)
- [x] Updated `linkwatcher/parsers/dart.py` — replaced 5 string literals
- [x] Updated `linkwatcher/parsers/powershell.py` — replaced 4 direct string arguments + 2 dynamic derivations with `LinkType()` lookups
- [x] Updated `linkwatcher/parsers/generic.py` — replaced 3 string literals
- [x] Updated `linkwatcher/validator.py` — replaced 2 frozensets + 1 lambda comparison with enum members
- [x] Updated `linkwatcher/updater.py` — replaced 6 comparisons + 2 list memberships with enum members
- [x] Updated `linkwatcher/path_resolver.py` — replaced 1 comparison
- [x] Updated `linkwatcher/reference_lookup.py` — replaced 1 comparison

**Test Baseline**: 756 passed, 1 failed (pre-existing: test_bug025_yaml_substring_path_not_corrupted), 5 skipped, 4 deselected, 4 xfailed
**Test Result**: 758 passed, 0 failed, 5 skipped, 4 deselected, 4 xfailed (baseline had 1 pre-existing failure resolved by external fix to validator.py rstrip→removesuffix; no new failures from this refactoring)

**Documentation & State Updates**:
- [x] Feature implementation state file — N/A: _Cross-cutting refactoring across 2.1.1, 2.2.1, 6.1.1; no behavioral change — enum is str-compatible so state files don't reference link type string values_
- [x] TDD — N/A: _No interface or design change — LinkType(str, Enum) is backward compatible, no new data structures or algorithm changes_
- [x] Test spec — N/A: _No behavior change — tests continue to pass with identical assertions_
- [x] FDD — N/A: _No functional change — link type identification unchanged_
- [x] ADR — N/A: _No architectural decision affected — adding a constants module is not architectural_
- [x] Validation tracking — N/A: _Change doesn't affect validation results — string equality preserved_
- [x] Technical Debt Tracking: TD181 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD181 | Complete | None | None (all N/A — cross-cutting, no interface change) |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
