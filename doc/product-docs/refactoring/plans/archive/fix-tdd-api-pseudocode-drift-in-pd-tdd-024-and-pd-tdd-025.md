---
id: PF-REF-061
type: Document
category: General
version: 1.0
created: 2026-03-13
updated: 2026-03-13
refactoring_scope: Fix TDD API/pseudocode drift in PD-TDD-024 and PD-TDD-025
priority: Medium
target_area: TDD Documentation
---

# Refactoring Plan: Fix TDD API/pseudocode drift in PD-TDD-024 and PD-TDD-025

## Overview
- **Target Area**: TDD Documentation
- **Priority**: Medium
- **Created**: 2026-03-13
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Tech Debt Item**: TD049 (partial — 2 of 5 TDDs addressed in this plan)

## Refactoring Scope

### Current Issues

PD-TDD-024 (3.1.1 Logging) had 13 discrepancies with actual source code:
- LogContext documented as `@classmethod` — actual is instance-based with global `log_context`
- `set_context` documented as replace semantics — actual uses `update()` (merge)
- `with_context` decorator uses `logger.set_context()`, not `LogContext.set_context()`
- LinkWatcherLogger missing `name` parameter
- Attribute names wrong: `_logger`→`logger`, `_struct_logger`→`struct_logger`
- All 5 convenience method signatures had wrong parameter names; `file_created()` missing entirely
- LogTimer constructor parameter order reversed; exit behavior differs
- LoggingConfigManager constructor wrong (took 2 params, actual takes 0)
- §7.2 counter names and method name wrong
- `reset_logger()` and `reset_config_manager()` undocumented
- Dead reference to `docs/LOGGING.md`

PD-TDD-025 (2.1.1 Parser) had 7 discrepancies:
- `_parsers`→`parsers`, `_default_parser`→`generic_parser` (public attributes)
- BaseParser abstract method documented as `parse_file()` — actual is `parse_content()`
- `parse_content(content, file_path)` completely absent from LinkParser facade docs
- TDD claims exceptions propagate to callers — actual catches all and returns `[]`
- `.markdown` extension listed but not registered
- Key Files table missing all 6 format-specific parser modules

### Scope Discovery
- **Original Tech Debt Description**: TD049 covers 5 TDDs (PD-TDD-024/025/026/027/031) with 7 Critical + 15 Major issues
- **Actual Scope Findings**: This session addresses 2 of 5 TDDs. Issues found match the validation report (PF-VAL-043) closely
- **Scope Delta**: None — findings match original description

### Refactoring Goals
- Synchronize TDD pseudocode with actual source code for PD-TDD-024 and PD-TDD-025
- Fix error handling documentation that contradicts actual behavior
- Document previously undocumented public API methods

## Current State Analysis

### Code Quality Metrics (Baseline)
- **Complexity Score**: N/A — documentation-only changes
- **Code Coverage**: N/A — no code changes
- **Technical Debt**: TD049 open (5 TDDs with stale pseudocode)

### Affected Components
- `doc/product-docs/technical/architecture/design-docs/tdd/tdd-3-1-1-logging-framework-t2.md` — PD-TDD-024
- `doc/product-docs/technical/architecture/design-docs/tdd/tdd-2-1-1-parser-framework-t2.md` — PD-TDD-025

### Dependencies and Impact
- **Internal Dependencies**: AI agents reading TDDs for onboarding and implementation guidance
- **External Dependencies**: None
- **Risk Assessment**: Low — documentation-only changes, no code modifications

## Refactoring Strategy

### Approach
Read each TDD alongside its source code, identify every discrepancy, and update the TDD pseudocode and prose to match the actual implementation.

### Implementation Plan

1. **Phase 1**: PD-TDD-024 (Logging)
   - Fixed LinkWatcherLogger constructor and attributes (10 edits)
   - Fixed LogContext from classmethod to instance-based
   - Fixed LogTimer constructor and exit behavior
   - Fixed LoggingConfigManager constructor
   - Fixed §7.2 counter names and method name
   - Added `reset_logger()` and `reset_config_manager()` documentation
   - Removed dead `docs/LOGGING.md` reference

2. **Phase 2**: PD-TDD-025 (Parser)
   - Fixed attribute names to public (`parsers`, `generic_parser`)
   - Added `parse_content()` to facade API documentation
   - Fixed BaseParser abstract method (`parse_content`, not `parse_file`)
   - Fixed error handling documentation (catches exceptions, returns `[]`)
   - Removed `.markdown` from extension list
   - Added all 6 parser modules to Key Files table

## Testing Strategy

### Testing Approach
- **Regression Testing**: N/A — documentation-only changes
- **Verification**: Grep-based verification that no stale references remain in updated files

## Results and Lessons Learned

### Achievements
- PD-TDD-024: 13 discrepancies fixed — all pseudocode now matches `linkwatcher/logging.py` and `linkwatcher/logging_config.py`
- PD-TDD-025: 7 discrepancies fixed — all pseudocode now matches `linkwatcher/parser.py` and `linkwatcher/parsers/base.py`
- No bugs discovered during documentation review

### Remaining Technical Debt
- TD049 remains open for 3 TDDs: PD-TDD-026 (2.2.1 Updater), PD-TDD-027 (4.1.1 Tests), PD-TDD-031 (5.1.1 CI/CD)

## Related Documentation
- [Technical Debt Tracking](/doc/product-docs/state-tracking/permanent/technical-debt-tracking.md)
- [Validation Report PF-VAL-043](/doc/product-docs/validation/reports/documentation-alignment/PF-VAL-043-documentation-alignment-features-2.1.1-2.2.1-3.1.1-4.1.1-5.1.1.md)
