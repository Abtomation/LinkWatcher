---
id: PD-REF-096
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
mode: lightweight
refactoring_scope: Decompose MarkdownParser.parse_content into pattern-specific extraction methods
priority: Medium
target_area: Link Parsing System
---

# Lightweight Refactoring Plan: Decompose MarkdownParser.parse_content into pattern-specific extraction methods

- **Target Area**: Link Parsing System
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD086 — Decompose MarkdownParser.parse_content into pattern-specific extraction methods

**Scope**: `parse_content()` in `src/linkwatcher/parsers/markdown.py` (lines 82-279, ~198 lines) is the single largest method in the codebase. It handles 6 distinct regex patterns (standard links, reference-style links, HTML anchors, quoted paths, quoted directories, standalone references) in one flat loop with duplicated overlap-checking logic. Decompose into private `_extract_*` methods per pattern, and extract the shared overlap-checking into a helper, to reduce complexity and improve maintainability.

**Changes Made**:
- [x] Extract `_is_skippable_target()` shared helper for external/anchor link filtering
- [x] Extract `_overlaps_any(start, end, spans)` shared overlap-checking helper
- [x] Extract `_markdown_link_spans(line)` helper to compute markdown link spans once per line
- [x] Extract `_extract_standard_links(line, line_num, file_path)` for Pattern 1
- [x] Extract `_extract_reference_links(line, line_num, file_path)` for Pattern 3
- [x] Extract `_extract_html_anchors(line, line_num, file_path)` for Pattern 5 (returns refs + spans tuple)
- [x] Extract `_extract_quoted_paths(line, line_num, file_path, md_spans, html_spans)` for Pattern 2
- [x] Extract `_extract_quoted_dirs(line, line_num, file_path, md_spans, html_spans)` for Pattern 6
- [x] Extract `_extract_standalone_refs(line, line_num, file_path, md_spans)` for Pattern 4
- [x] Simplify `parse_content()` to ~20-line orchestrator that delegates to extraction methods

**Test Baseline**: test_markdown.py — 24 passed, 5 xfailed. Full suite: 593 passed, 5 skipped, 7 xfailed.
**Test Result**: test_markdown.py — 24 passed, 5 xfailed. Full suite: 593 passed, 5 skipped, 7 xfailed. No regressions.

**Documentation & State Updates**:
- [x] Feature implementation state file (2.1.1) updated, or N/A — _Grepped state file: only mentions `parse_content()` as abstract method pattern decision. No internal MarkdownParser method structure documented. N/A._
- [x] TDD (2.1.1) updated, or N/A — _Grepped TDD: references `parse_content()` as abstract contract and `MarkdownParser` as registered parser. No internal method decomposition documented. N/A._
- [x] Test spec (2.1.1) updated, or N/A — _Grepped test spec: references `MarkdownParser` at class level only. No behavior change. N/A._
- [x] FDD (2.1.1) updated, or N/A — _Grepped FDD: lists `MarkdownParser` with pattern descriptions but no internal method structure. N/A._
- [x] ADR updated, or N/A — _Grepped ADR directory for `MarkdownParser` and `parse_content` — no hits. N/A._
- [x] Validation tracking updated, or N/A — _2.1.1 is "Completed" in R2 validation. Internal decomposition doesn't change any validated behavior. N/A._
- [x] Technical Debt Tracking: TD086 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD086 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
