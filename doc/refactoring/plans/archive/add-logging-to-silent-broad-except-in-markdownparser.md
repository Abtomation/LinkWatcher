---
id: PD-REF-206
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
priority: Low
refactoring_scope: Add logging to silent broad-except in MarkdownParser._extract_frontmatter_refs
target_area: src/linkwatcher/parsers/markdown.py
debt_item: TD241
mode: lightweight
---

# Lightweight Refactoring Plan: Add logging to silent broad-except in MarkdownParser._extract_frontmatter_refs

- **Target Area**: src/linkwatcher/parsers/markdown.py
- **Priority**: Low
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Complete (2026-04-29)
- **Debt Item**: TD241
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD241 — Silent broad-except in MarkdownParser._extract_frontmatter_refs

**Scope**: The `try/except Exception:` at [markdown.py:461-465](/src/linkwatcher/parsers/markdown.py#L461-L465) swallows any error from `YamlParser().parse_content(...)` without logging — Observability gap (Dims: OB). Add `self.logger.warning("frontmatter_parse_error", ...)` before returning empty refs, matching the project pattern at [yaml_parser.py:73-75](/src/linkwatcher/parsers/yaml_parser.py#L73-L75) and [base.py:46-50](/src/linkwatcher/parsers/base.py#L46-L50).

**Deviation from TD's proposed fix**: TD241 also recommends "narrow exception type to YAMLError". Independent verification rejected this — `YamlParser.parse_content` already catches `yaml.YAMLError` internally (yaml_parser.py:64) and falls back to `GenericParser`, then catches all other `Exception`s (line 73) and returns `[]`. `YAMLError` cannot propagate to the markdown helper, so narrowing to `YAMLError` would never match. Keeping `except Exception` (consistent with the parser-level error-handling pattern) and adding the missing logger call delivers the OB improvement the TD actually wants.

**Changes Made**:
- [x] Added `self.logger.warning("frontmatter_parse_error", file_path=file_path, parser="markdown", error=str(e))` to the `except` branch in `_extract_frontmatter_refs` ([markdown.py:464-470](/src/linkwatcher/parsers/markdown.py#L464-L470))
- [x] Bound the exception via `except Exception as e:`

**Test Baseline** (2026-04-29, `Run-Tests.ps1 -All` excludes `slow` marker): 819 passed, 5 skipped, 4 deselected, 5 xfailed, **0 failed, 0 errors**. No pre-existing failing tests.

**Test Coverage Assessment**: Happy paths of `_extract_frontmatter_refs` are covered by `test_bug_092_frontmatter_directory_paths`, `test_bug_092_frontmatter_line_numbers`, `test_bug_092_no_frontmatter_no_regression` in `test/automated/parsers/test_markdown.py`. The exception branch is **not** directly tested, but `YamlParser.parse_content` swallows all exceptions internally — the markdown helper's `except` is unreachable in practice. Adding a characterization test for an unreachable branch via mock injection is not justified; existing tests are sufficient to verify the change preserves happy-path behavior (the only modification is adding a `logger.warning` call on the dead branch + binding the exception variable).

**Test Result** (2026-04-29, post-change): 819 passed, 5 skipped, 4 deselected, 5 xfailed, **0 failed, 0 errors**. Identical to baseline — **no regressions**.

**Documentation & State Updates**:
- [x] Feature implementation state file (2.1.1, [PD-FIS-050](/doc/state-tracking/features/2.1.1-link-parsing-system-implementation-state.md)) — **N/A**: grepped state file; the only reference to `_extract_frontmatter_refs` is in the PD-BUG-092 row describing the function's introduction and behavior. The change adds a single logger call to a defensive branch and does not change the function's contract or behavior description.
- [x] TDD (2.1.1, [tdd-2-1-1-parser-framework-t2.md](/doc/technical/tdd/tdd-2-1-1-parser-framework-t2.md)) — **N/A**: grepped TDD for `_extract_frontmatter` (no match) and `except Exception` (3 matches at lines 63/92/99 — all describe `LinkParser.parse_file()` / `parse_content()` orchestrator-level error handling, not the markdown frontmatter helper). No interface or significant internal design change.
- [x] Test spec (2.1.1, [test-spec-2-1-1-link-parsing-system.md](/test/specifications/feature-specs/test-spec-2-1-1-link-parsing-system.md)) — **N/A**: grepped test spec for `frontmatter` / `_extract_frontmatter` / `except Exception` — no matches. Refs returned by `_extract_frontmatter_refs` are unchanged; only added a side-effect log call.
- [x] FDD — **N/A**: no FDD exists for feature 2.1.1 (Retrospective Analysis feature consolidating 7 former features per [PD-FIS-050](/doc/state-tracking/features/2.1.1-link-parsing-system-implementation-state.md) frontmatter). No functional change to document anyway — log calls are not user-visible behavior.
- [x] ADR — **N/A**: 3 ADRs exist (target-indexed-in-memory-link-database, timer-based-move-detection-with-3-phase-directory-batch-algorithm, orchestrator-facade-pattern-for-core-architecture); none address parser-internal error handling. No architectural decision affected.
- [x] Integration Narrative — **N/A**: grepped `doc/technical/integration/` for `frontmatter` / `_extract_frontmatter` / `MarkdownParser._extract` — no matches. None of the existing PD-INT narratives reference this internal helper.
- [x] Validation tracking ([validation-tracking-4.md](/doc/state-tracking/validation/validation-tracking-4.md)) — **N/A**: TD241 was discovered during code review (PF-TSK-005), not a validation finding. Feature 2.1.1's validation status in round 4 is "Completed"; the round's R4-* findings list does not include TD241. No validation tracking update required.
- [x] Technical Debt Tracking: TD241 marked resolved (handled in L10 via `Update-TechDebt.ps1`).

**Bugs Discovered**: None.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD241 | Complete | None | None (all 7 surfaces N/A — see Item 1 checklist for justifications) |

**Test diff vs. baseline**: 819 passed, 0 failed, 0 errors → 819 passed, 0 failed, 0 errors. No new failures.

**Status**: Planning → **Complete**.

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
