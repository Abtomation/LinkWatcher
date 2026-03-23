---
id: PF-REF-045
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-03
updated: 2026-03-03
refactoring_scope: Decompose DartParser.parse_content monolithic method into focused sub-methods
mode: lightweight
priority: Medium
target_area: linkwatcher/parsers/dart.py
---

# Lightweight Refactoring Plan: Decompose DartParser.parse_content monolithic method into focused sub-methods

- **Target Area**: linkwatcher/parsers/dart.py
- **Priority**: Medium
- **Created**: 2026-03-03
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (≤15 min effort, single file, no architectural impact)

## Item 1: TD031 — Decompose DartParser.parse_content into focused sub-methods

**Scope**: `parse_content` is ~155 LOC handling 5 pattern types (imports, parts, quoted refs, standalone refs, embedded refs) in a single method with deep nesting. Extract each pattern type into a private sub-method (`_extract_imports`, `_extract_parts`, `_extract_quoted_refs`, `_extract_standalone_refs`, `_extract_embedded_refs`) called from a simplified `parse_content` loop. No behavioral change — pure structural decomposition.

**Changes Made**:
- [x] Extracted `_extract_imports()` — handles import statement matching, skips package:/dart: prefixes
- [x] Extracted `_extract_parts()` — handles part statement matching
- [x] Extracted `_extract_quoted_refs()` — handles quoted file path matching with package:/dart: filtering
- [x] Extracted `_extract_standalone_refs()` — handles unquoted standalone file path matching
- [x] Extracted `_extract_embedded_refs()` — handles embedded file path matching with URL skip logic and deduplication against existing refs
- [x] Simplified `parse_content()` to a thin loop calling the 5 extractors (~25 LOC down from ~155 LOC)

**Test Baseline**: 389 passed, 5 skipped, 7 xfailed, 2 errors (pre-existing manual test errors). Dart-specific: 11 passed.
**Test Result**: 389 passed, 5 skipped, 7 xfailed, 2 errors. Dart-specific: 11 passed. Identical to baseline.

**Documentation & State Updates**:
- [x] Feature implementation state file updated (N/A — no feature scope change)
- [x] TDD updated (N/A — no interface/design change)
- [x] Test spec updated (N/A — no behavior change)
- [x] FDD updated (N/A — no functional change)
- [x] Technical Debt Tracking: TD031 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD031 | Complete | None | None (all N/A) |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
