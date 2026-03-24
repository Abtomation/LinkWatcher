---
id: PD-REF-069
type: Document
category: General
version: 1.0
created: 2026-03-17
updated: 2026-03-17
priority: Medium
debt_item: TD056
refactoring_scope: Wire parser enable/disable config flags into LinkParser runtime
target_area: linkwatcher/parser.py, linkwatcher/config/settings.py
---

# Refactoring Plan: Wire parser enable/disable config flags into LinkParser runtime

## Overview
- **Target Area**: linkwatcher/parser.py, linkwatcher/config/settings.py, linkwatcher/config/defaults.py, linkwatcher/service.py
- **Priority**: High
- **Created**: 2026-03-17
- **Author**: AI Agent & Human Partner
- **Status**: Completed
- **Debt Item**: TD056

## Refactoring Scope

### Current Issues
- 6 `enable_*_parser` config flags in settings.py had zero runtime effect — LinkParser always loaded all parsers
- Missing `enable_powershell_parser` flag (7th parser had no config flag)
- `generic_parser` fallback path assumed non-null — would fail if generic parser were disabled

### Scope Discovery
- **Original Tech Debt Description**: "6 enable_*_parser flags and custom_parsers field exist in LinkWatcherConfig but LinkParser.__init__ always loads all parsers regardless"
- **Actual Scope Findings**: Confirmed. Also discovered missing PowerShell flag. custom_parsers wiring deferred (TD059 scope).
- **Scope Delta**: Added missing `enable_powershell_parser` flag. Deferred `custom_parsers` to TD059.

### Refactoring Goals
- Wire all 7 `enable_*_parser` config flags into LinkParser runtime
- Add missing `enable_powershell_parser` flag
- Maintain backward compatibility (no config = all parsers loaded)

## Current State Analysis

### Affected Components
- `linkwatcher/config/settings.py` — Added missing flag
- `linkwatcher/config/defaults.py` — Added missing flag to DEFAULT_CONFIG
- `linkwatcher/parser.py` — Conditional parser registration based on config
- `linkwatcher/service.py` — Passes config to LinkParser
- `test/automated/unit/test_parser.py` — 12 new tests

### Dependencies and Impact
- **Internal Dependencies**: service.py, handler.py, reference_lookup.py all use LinkParser
- **Risk Assessment**: Low — backward-compatible (config=None loads all parsers)

## Results

### Final Metrics
| Metric | Before | After |
|--------|--------|-------|
| Config flags | 6 (missing PowerShell) | 7 (complete) |
| Flags wired to runtime | 0 | 7 |
| Tests (parser+config) | 45 | 57 (+12) |
| Full suite | 460 pass | 460 pass |
| Regressions | 0 | 0 |

### Achievements
- All 7 `enable_*_parser` flags now control parser loading at runtime
- Backward-compatible: `LinkParser()` without config loads all parsers as before
- Disabled specialized parsers fall back to generic parser (if enabled)
- Generic parser can be fully disabled (returns empty for unsupported extensions)

### Remaining Technical Debt
- TD059: `custom_parsers`, `exclude_patterns`, `include_patterns` config fields still unused

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
