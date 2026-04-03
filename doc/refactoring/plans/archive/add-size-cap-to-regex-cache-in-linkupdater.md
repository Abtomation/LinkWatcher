---
id: PD-REF-140
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-02
updated: 2026-04-02
refactoring_scope: Add size cap to _regex_cache in LinkUpdater
target_area: LinkUpdater
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Add size cap to _regex_cache in LinkUpdater

- **Target Area**: LinkUpdater
- **Priority**: Medium
- **Created**: 2026-04-02
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD142 — Add size cap to _regex_cache in LinkUpdater

**Scope**: `_regex_cache` dict in `LinkUpdater` (linkwatcher/updater.py:70) grows unbounded across the session lifetime. Add a size cap that clears the cache when it exceeds a threshold, preventing theoretical unbounded memory growth. Dimension: PE (Performance).

**Changes Made**:
<!-- Fill in after implementation -->
- [x] Added `_REGEX_CACHE_MAX_SIZE = 1024` constant in `__init__`
- [x] Extracted `_get_cached_regex()` helper with size-cap eviction (clear on overflow)
- [x] Replaced two inline cache-lookup sites with `_get_cached_regex()` calls

**Test Baseline**: 649 passed, 5 skipped, 6 xfailed
**Test Result**: 649 passed, 5 skipped, 6 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file (2.2.1) updated, or N/A — _N/A: grepped feature state files — no references to `_regex_cache`_
- [x] TDD (2.2.1) updated, or N/A — _N/A: grepped TDD — no references to `_regex_cache`_
- [x] Test spec (2.2.1) updated, or N/A — _N/A: grepped test specs — no references to `_regex_cache`; no behavior change_
- [x] FDD (2.2.1) updated, or N/A — _N/A: grepped FDDs — no references to `_regex_cache`_
- [x] ADR updated, or N/A — _N/A: grepped ADR directory — no references to `_regex_cache`_
- [x] Validation tracking updated, or N/A — _N/A: internal implementation detail, no validation-tracked behavior change_
- [x] Technical Debt Tracking: TD142 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD142 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)

