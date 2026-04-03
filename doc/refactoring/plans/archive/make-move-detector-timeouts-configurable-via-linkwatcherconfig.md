---
id: PD-REF-070
type: Document
category: General
version: 1.0
created: 2026-03-17
updated: 2026-03-17
refactoring_scope: Make move detector timeouts configurable via LinkWatcherConfig
debt_item: TD057
priority: Medium
target_area: handler.py, settings.py, defaults.py, service.py
---

# Refactoring Plan: Make move detector timeouts configurable via LinkWatcherConfig

## Overview
- **Target Area**: handler.py, settings.py, defaults.py, service.py
- **Priority**: Medium
- **Created**: 2026-03-17
- **Author**: AI Agent & Human Partner
- **Status**: Completed
- **Debt Item**: TD057

## Refactoring Scope

### Current Issues
- MoveDetector delay hardcoded to 10.0s in handler.py:89
- DirectoryMoveDetector max_timeout hardcoded to 300.0s in handler.py:98
- DirectoryMoveDetector settle_delay hardcoded to 5.0s in handler.py:99
- Cannot tune timing for different file systems (SSD vs network storage) or OS behaviors

### Scope Discovery
- **Original Tech Debt Description**: MoveDetector delay=10.0 and DirectoryMoveDetector max_timeout=300.0, settle_delay=5.0 should be configurable via LinkWatcherConfig
- **Actual Scope Findings**: Matched original description exactly. Three hardcoded values in handler.py constructor, config dataclass had no corresponding fields.
- **Scope Delta**: None — scope matches original description

### Refactoring Goals
- Add 3 config fields to LinkWatcherConfig dataclass
- Wire config through service → handler → detector constructors
- Add validation for the new fields
- Add tests for config wiring and roundtrip persistence

## Current State Analysis

### Code Quality Metrics (Baseline)
- **Test Count**: 448 passing
- **Technical Debt**: TD057 open

### Affected Components
- `linkwatcher/config/settings.py` — Config dataclass, needs new fields + validation
- `linkwatcher/config/defaults.py` — DEFAULT_CONFIG instance, needs explicit defaults
- `linkwatcher/handler.py` — Reads hardcoded values, needs to accept config
- `linkwatcher/service.py` — Creates handler, needs to pass config through

### Dependencies and Impact
- **Internal Dependencies**: MoveDetector and DirectoryMoveDetector already accept these as constructor params — no changes needed
- **External Dependencies**: None
- **Risk Assessment**: Low — additive change with backwards-compatible defaults

## Refactoring Strategy

### Approach
Add config fields with current hardcoded values as defaults, then wire config through the existing constructor chain. No interface changes to MoveDetector or DirectoryMoveDetector needed since they already accept these as parameters.

### Implementation Plan
1. Add `move_detect_delay`, `dir_move_max_timeout`, `dir_move_settle_delay` fields to LinkWatcherConfig
2. Add validation rules (must be positive)
3. Add explicit values to DEFAULT_CONFIG
4. Add `config` parameter to LinkMaintenanceHandler.__init__, read timing from config
5. Pass config from service.py to handler
6. Add tests: default values, custom values, validation, handler wiring, JSON/YAML roundtrip

## Results

### Final Metrics
- **Test Count**: 458 passing (+10 new tests)
- **Technical Debt**: TD057 resolved

### Changes Made
- `linkwatcher/config/settings.py`: Added 3 float fields + 3 validation checks
- `linkwatcher/config/defaults.py`: Added 3 explicit defaults in DEFAULT_CONFIG
- `linkwatcher/handler.py`: Added `config` parameter, reads timing from config with DEFAULT_CONFIG fallback
- `linkwatcher/service.py`: Passes `config=config` to handler constructor
- `test/automated/unit/test_config.py`: Added 10 new tests (2 default/custom, 3 validation, 3 wiring, 2 roundtrip)

### Bugs Discovered
None.

### Remaining Technical Debt
None related to this scope.

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
