---
id: PD-REF-080
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
refactoring_scope: Auto-generate env var mappings in from_env() from dataclass fields
priority: Medium
mode: lightweight
target_area: linkwatcher/config/settings.py
---

# Lightweight Refactoring Plan: Auto-generate env var mappings in from_env() from dataclass fields

- **Target Area**: linkwatcher/config/settings.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Mode**: Lightweight (no architectural impact)

## Item 1: TD068 — Auto-generate env var mappings in from_env()

**Scope**: Replace the hardcoded `env_mappings` dict in `from_env()` with introspection of the dataclass fields. The method will iterate over `dataclasses.fields(cls)` and auto-derive the env var name from the field name (uppercased, prefixed). Type conversion will use field type annotations (bool, int, float, str, Set[str]). This eliminates the maintenance trap where new fields silently lack env var support.

**Changes Made**:
- [x] Replaced hardcoded `env_mappings` dict (7 entries) with `dataclasses.fields(cls)` introspection covering all 28 fields
- [x] Added `import dataclasses` and `from typing import get_type_hints`
- [x] Type-aware conversion using field type annotations: `Set[str]` (comma-split), `bool`, `int`, `float`, `str`/`Optional[str]`
- [x] Updated 4 test env var references: `LINKWATCHER_DRY_RUN` → `LINKWATCHER_DRY_RUN_MODE` (now matches field name)

**Test Baseline**: 46 passed (test_config.py), 604 passed / 5 skipped / 7 xfailed (full suite)
**Test Result**: 46 passed (test_config.py), 604 passed / 5 skipped / 7 xfailed (full suite) — no regressions

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.3) updated, or N/A — grepped state file: mentions `from_env()` env var support, which remains correct (auto-derived names still produce `LINKWATCHER_VALIDATION_IGNORED_PATTERNS`). _N/A — no update needed._
- [x] TDD (0.1.3) updated, or N/A — 0.1.3 is Tier 1, no TDD exists. _N/A._
- [x] Test spec (0.1.3) updated, or N/A — grepped test spec: references test function names, not env var names. Tests updated to match new env var names. _N/A — spec still accurate._
- [x] FDD (0.1.3) updated, or N/A — 0.1.3 is Tier 1, no FDD exists. _N/A._
- [x] ADR updated, or N/A — grepped ADR directory for `from_env`/`env_mappings`: no references. _N/A._
- [x] Validation tracking updated, or N/A — 0.1.3 is in Round 2 validation but this internal refactoring doesn't affect validation results. _N/A._
- [ ] Technical Debt Tracking: TD068 marked resolved

**Bugs Discovered**: None

<!-- BATCH MODE: Copy the "## Item N" section above for each additional debt item in this session -->

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD068 | Complete | None | None |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
