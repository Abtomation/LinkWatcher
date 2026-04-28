---
id: PD-REF-095
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
target_area: validator.py + settings.py
refactoring_scope: Move hardcoded _VALIDATION_EXTRA_IGNORED_DIRS to LinkWatcherConfig
priority: Medium
mode: lightweight
---

# Lightweight Refactoring Plan: Move hardcoded _VALIDATION_EXTRA_IGNORED_DIRS to LinkWatcherConfig

- **Target Area**: validator.py + settings.py
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (no architectural impact)

## Dependencies and Impact
- **Affected Components**: `src/linkwatcher/config/settings.py`, `src/linkwatcher/validator.py`
- **Internal Dependencies**: `LinkValidator` consumes `LinkWatcherConfig`; `service.py` passes config to validator
- **Risk Assessment**: Low — Adding a config field with the same default values; no behavioral change unless user overrides

## Item 1: TD082 — Move hardcoded _VALIDATION_EXTRA_IGNORED_DIRS to LinkWatcherConfig

**Scope**: The module-level constant `_VALIDATION_EXTRA_IGNORED_DIRS` in validator.py contains project-agnostic defaults (`old`, `archive`, `fixtures`, etc.) and one project-specific value (`LinkWatcher_run`). Move to a `validation_extra_ignored_dirs` config field with the current values as defaults so users can customize without code changes.

**Changes Made**:
- [x] Add `validation_extra_ignored_dirs: Set[str]` field to `LinkWatcherConfig` with default `{"LinkWatcher_run", "old", "archive", "fixtures", "e2e-acceptance-testing", "config-examples"}`
- [x] Update `LinkValidator.__init__()` to store `self._extra_ignored_dirs = self.config.validation_extra_ignored_dirs`
- [x] Replace `_VALIDATION_EXTRA_IGNORED_DIRS` usage in `validate()` with `self._extra_ignored_dirs`
- [x] Remove the module-level `_VALIDATION_EXTRA_IGNORED_DIRS` constant (replaced with explanatory comment)
- [x] Add `"validation_extra_ignored_dirs"` to the set-from-list conversion block in `_from_dict()`

**Test Baseline**: 593 passed, 5 skipped, 7 xfailed
**Test Result**: 593 passed, 5 skipped, 7 xfailed (identical)

**Documentation & State Updates**:
- [x] Feature implementation state file (6.1.1) updated, or N/A — grepped state file: no reference to `_VALIDATION_EXTRA_IGNORED_DIRS` or `validation_extra_ignored_dirs`
- [x] TDD (6.1.1) updated, or N/A — grepped TDD directory: no reference to changed component
- [x] Test spec (6.1.1) updated, or N/A — grepped test specs: no reference to changed component
- [x] FDD (6.1.1) updated, or N/A — grepped FDD directory: no reference to changed component
- [x] ADR updated, or N/A — grepped ADR directory: no reference to changed component
- [x] Validation tracking updated — R2-M-008 (6.1.1 Extensibility) and R2-L-016 (6.1.1 Integration) resolved
- [x] Technical Debt Tracking: TD082 marked resolved via Update-TechDebt.ps1

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD082 | Complete | None | Validation tracking R2-M-008, R2-L-016 |

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
