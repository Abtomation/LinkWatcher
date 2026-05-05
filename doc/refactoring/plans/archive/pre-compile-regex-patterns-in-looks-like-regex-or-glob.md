---
id: PD-REF-208
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-29
updated: 2026-04-29
refactoring_scope: Pre-compile regex patterns in looks_like_regex_or_glob
target_area: src/linkwatcher/utils.py
debt_item: TD243
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: Pre-compile regex patterns in looks_like_regex_or_glob

- **Target Area**: src/linkwatcher/utils.py
- **Priority**: Medium
- **Created**: 2026-04-29
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Debt Item**: TD243
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD243 — Pre-compile regex patterns in looks_like_regex_or_glob

**Scope**: Lift the three inline `re.search(pattern_string, text)` calls in [utils.py:looks_like_regex_or_glob](/src/linkwatcher/utils.py#L189-L238) to module-level `re.compile()` constants and use `pattern.search(text)` instead. Behavior is identical; the gain is eliminating Python's per-call regex-cache lookup overhead on a hot path called from every parser-extracted quoted/bare path string (8 parsers × 30+ call sites). Dimension: PE (Performance). No interface or behavioral changes — function signature, semantics, and Windows-path-safety carve-outs are preserved.

**Changes Made**:
- [x] Added three module-level `re.compile()` constants in `utils.py` above `looks_like_regex_or_glob`: `_RE_CHAR_CLASS`, `_RE_REGEX_ESCAPE_QUANT`, `_RE_ESCAPED_METACHAR`
- [x] Replaced `re.search(r"\[[\w\-]+\]", text)` with `_RE_CHAR_CLASS.search(text)` (line 232)
- [x] Replaced `re.search(r"\\[dswDSW](?:[+*?{]|$)", text)` with `_RE_REGEX_ESCAPE_QUANT.search(text)` (line 238)
- [x] Replaced `re.search(r"\\[\.\[\]\(\)\{\}\+\*\?\^\$]", text)` with `_RE_ESCAPED_METACHAR.search(text)` (line 241)

**Test Baseline**: 819 passed, 5 skipped, 4 deselected, 5 xfailed, 0 failed (43.29s) — captured 2026-04-29 before changes. No pre-existing failures.
**Test Result**: 819 passed, 5 skipped, 4 deselected, 5 xfailed, 0 failed (44.59s) — **identical to baseline, no new failures**. Behavior preservation verified.

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1) — **N/A**. Grepped 0.1.1 implementation state — no references to `looks_like_regex_or_glob` or the inline regex patterns. References in 2.1.1/2.2.1 cover PD-BUG-095 behavior history (function existence and purpose), which is unchanged.
- [x] TDD (0.1.1, 2.1.1) — **N/A**. TDD 0.1.1 mentions `utils.py` only at file-summary granularity ("Path utilities (normalize, relative path, file filtering)"). TDD 2.1.1 references `looks_like_file_path()` / `looks_like_directory_path()` as black-box helpers used by `BaseParser`. Internal regex-pattern implementation is not documented — refactoring is invisible to TDD.
- [x] Test spec (0.1.1) — **N/A**. Grepped — no references to the function or regex patterns. Behavior is unchanged so spec doesn't apply.
- [x] FDD — **N/A**. No FDD exists for 0.1.1 (foundation feature, no functional design document).
- [x] ADR — **N/A**. Three ADRs in the project (orchestrator-facade, in-memory DB, timer-based move detection); none cover path classification or regex compilation strategy.
- [x] Integration Narrative — **N/A**. Grepped `doc/technical/integration/`: only `link-health-audit-integration-narrative.md` mentions `looks_like_file_path`/`looks_like_directory_path` as call-site references, not the internal regex implementation.
- [x] Validation tracking — **N/A**. No active validation rounds in `doc/state-tracking/temporary/`, no validation tracking file in permanent/.
- [x] Technical Debt Tracking: TD243 marked resolved via `Update-TechDebt.ps1` (see L10).

**Bugs Discovered**: None.

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD243 | Complete | None | None (all design/state docs N/A — internal optimization, behavior unchanged) |

**Test diff vs baseline**: Baseline 819 passed / 0 failed → Post-change 819 passed / 0 failed. **No regressions, no new failures.**

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
