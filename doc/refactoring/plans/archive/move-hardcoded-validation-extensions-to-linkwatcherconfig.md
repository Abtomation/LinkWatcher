---
id: PD-REF-087
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
target_area: validator.py + settings.py
refactoring_scope: Move hardcoded _VALIDATION_EXTENSIONS to LinkWatcherConfig
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Move hardcoded _VALIDATION_EXTENSIONS to LinkWatcherConfig

- **Target Area**: validator.py + settings.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Dependencies and Impact
- **Affected Components**: `src/linkwatcher/config/settings.py`, `src/linkwatcher/validator.py`, `test/automated/unit/test_validator.py`
- **Internal Dependencies**: `LinkValidator` consumes `LinkWatcherConfig`; `service.py` passes config to validator
- **Risk Assessment**: Low — Adding a config field with the same default values; no behavioral change unless user overrides

## Item 1: TD081 — Move hardcoded _VALIDATION_EXTENSIONS to LinkWatcherConfig

**Scope**: The module-level constant `_VALIDATION_EXTENSIONS` in validator.py prevents users from adding file types to validation without code changes. Move it to a `validation_extensions` config field with the current values as defaults. The validator reads the field from config instead of the module constant.

**Changes Made**:
- [x] Add `validation_extensions: Set[str]` field to `LinkWatcherConfig` with default `{".md", ".yaml", ".yml", ".json"}`
- [x] Update `LinkValidator.__init__()` to store `config.validation_extensions`
- [x] Replace `_VALIDATION_EXTENSIONS` usage in `validate()` with `self._validation_extensions`
- [x] Remove the module-level `_VALIDATION_EXTENSIONS` constant (replaced with explanatory comment)
- [x] No test updates needed — no tests referenced the old constant

**Test Baseline**: 592 passed, 5 skipped, 7 xfailed
**Test Result**: 592 passed, 5 skipped, 7 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file (6.1.1) updated, or N/A — grepped state file: no reference to `_VALIDATION_EXTENSIONS` or `validation_extensions`
- [x] TDD (6.1.1) updated, or N/A — grepped TDD directory: no reference to changed component
- [x] Test spec (6.1.1) updated, or N/A — grepped test specs: no reference to changed component
- [x] FDD (6.1.1) updated, or N/A — grepped FDD directory: no reference to changed component
- [x] ADR updated, or N/A — grepped ADR directory: no reference to changed component
- [x] Validation tracking updated — R2-M-007 (6.1.1 Extensibility) updated via Update-TechDebt.ps1
- [x] Technical Debt Tracking: TD081 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD081 | Complete | None | Validation tracking R2-M-007 |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
