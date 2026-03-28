---
id: PD-REF-112
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
mode: lightweight
refactoring_scope: Optimize YAML/JSON parser line scanning from O(V*L) to O(V+L)
target_area: Parser System
priority: Medium
---

# Lightweight Refactoring Plan: Optimize YAML/JSON parser line scanning from O(V*L) to O(V+L)

- **Target Area**: Parser System
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Dependencies and Impact
- **Affected Components**: linkwatcher/parsers/yaml_parser.py, linkwatcher/parsers/json_parser.py
- **Internal Dependencies**: Both parsers are used by the parser registry; no external API changes
- **Risk Assessment**: Low — internal scanning optimization, same outputs, same signatures

## Item 1: TD116 — Optimize YAML/JSON parser line scanning from O(V×L) to O(V+L)

**Scope**: Both `YamlParser._find_next_occurrence()` and `JsonParser._find_unclaimed_line()` restart scanning from line 0 for every string value. Since Python 3.7+ dicts (and thus yaml.safe_load/json.loads) preserve insertion order, values appear in file order. Track a `start_line` offset so each call resumes from where the previous one left off, reducing total work from O(V×L) to O(V+L).

**Changes Made**:
- [x] YAML: Add `_search_start_line` instance state, start `_find_next_occurrence()` scan from it, with fallback to lines before offset
- [x] JSON: Add `_search_start_line` instance state, pass `start_line` to `_find_unclaimed_line()`, update offset after each find

**Test Baseline**: parsers/ — 130 passed, 7 xfailed
**Test Result**: parsers/ — 130 passed, 7 xfailed. Full regression: 597 passed, 5 skipped, 7 xfailed. No new failures.

**Documentation & State Updates**:
- [x] Feature implementation state file (2.1.1) updated, or N/A — _Grepped state file: mentions yaml_parser.py/json_parser.py by name but only as file listings. No method-level detail to update._
- [x] TDD (2.1.1) updated, or N/A — _Grepped TDD: mentions yaml_parser.py/json_parser.py as component descriptions only. No internal scanning algorithm documented._
- [x] Test spec (2.1.1) updated, or N/A — _Grepped test spec: no references to _find_next_occurrence or _find_unclaimed_line. No behavior change._
- [x] FDD (2.1.1) updated, or N/A — _Grepped FDD: no references to changed methods._
- [x] ADR updated, or N/A — _Grepped ADR directory: no references to changed methods._
- [x] Validation tracking updated, or N/A — _R2-L-017 references this issue. Will be updated when TD116 is marked resolved via Update-TechDebt.ps1 -ValidationNote._
- [x] Technical Debt Tracking: TD116 marked resolved

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD116 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
