---
id: PD-REF-179
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
priority: Medium
mode: documentation-only
refactoring_scope: TD191: Update TDD-1-1-1 __init__ pseudocode to reflect config parameter, event deferral, on_error, _is_known_reference_target
target_area: tdd-1-1-1-file-system-monitoring-t2
---

# Documentation Refactoring Plan: TD191: Update TDD-1-1-1 __init__ pseudocode to reflect config parameter, event deferral, on_error, _is_known_reference_target

## Overview
- **Target Area**: tdd-1-1-1-file-system-monitoring-t2
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Documentation-only (no code changes, no test impact)

## Refactoring Scope

### Current Issues
- TDD Section 4.1 `__init__` pseudocode missing `config=None` parameter (lines 98-100 of TDD)
- No documentation of `begin_event_deferral()` / `notify_scan_complete()` public methods (PD-BUG-053)
- No documentation of `on_error()` in Section 4.2 Event Routing Architecture
- No documentation of `_is_known_reference_target()` helper used in all three event handlers (PD-BUG-046)
- Event routing table (Section 4.2) missing Phase 0 deferral check at top of each handler
- `_stats_lock` (PD-BUG-026 thread safety fix) not reflected in Section 4.1 or 3.3

### Scope Discovery
- **Original Tech Debt Description**: TDD-1-1-1 `LinkMaintenanceHandler.__init__` missing config parameter and event deferral mechanism. Also add `on_error`, Phase 0, `_is_known_reference_target`.
- **Actual Scope Findings**: All items confirmed. The `__init__` pseudocode (TDD lines 98-141) is a snapshot from the pre-config, pre-deferral era. Actual code (handler.py:130-217) has diverged significantly.
- **Scope Delta**: None — scope matches original description

### Refactoring Goals
- Update Section 4.1 `__init__` pseudocode to match actual handler.py:130-217
- Add `begin_event_deferral()` / `notify_scan_complete()` to documented API
- Add `on_error()` to Section 4.2 event routing
- Add Phase 0 deferral check to event routing description
- Add `_is_known_reference_target()` to documented internals
- Update Section 3.3 to mention `_stats_lock`

## Current State Analysis

### Documentation Quality Baseline
- **Accuracy**: LOW — `__init__` pseudocode missing config param, deferral state, stats lock
- **Completeness**: LOW — 3 public methods undocumented (`begin_event_deferral`, `notify_scan_complete`, `on_error`), 1 key helper undocumented (`_is_known_reference_target`)
- **Cross-references**: OK — existing cross-references are correct
- **Consistency**: OK — formatting consistent with rest of TDD

### Affected Documents
- `doc/technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md` — Section 4.1 (data models/init), Section 4.2 (event routing), Section 3.3 (reliability)

### Dependencies and Impact
- **Cross-references**: No other documents reference the specific pseudocode being updated
- **State files**: technical-debt-tracking.md (TD191 status update)
- **Risk Assessment**: Low — documentation-only, no code changes

## Refactoring Strategy

### Approach
Update TDD sections in-place to match actual implementation. Changes are additive (new content) plus corrections to existing pseudocode.

### Implementation Plan
1. **Section 4.1**: Replace `__init__` pseudocode with version matching handler.py:130-217 (config param, deferral state, stats lock)
2. **Section 4.2**: Add Phase 0 deferral check to event routing table, add `on_error()` entry, note `_is_known_reference_target` in routing logic
3. **Section 3.3**: Add `_stats_lock` mention to thread safety description
4. **Section 9**: Update session handoff notes with this update

## Verification Approach
- **Content accuracy**: Diff each TDD pseudocode block against actual handler.py source
- **Consistency check**: Verify terminology matches existing TDD style

## Success Criteria

### Documentation Quality Improvements
- **Accuracy**: All TDD pseudocode matches current handler.py implementation
- **Completeness**: All public methods and key helpers documented

### Documentation Integrity
- [ ] All existing cross-references preserved or updated
- [ ] No orphaned references created
- [ ] Terminology consistent with project conventions
- [ ] LinkWatcher confirms no broken links

## Implementation Tracking

### Progress Log
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-04-09 | Planning | Created plan, verified TD191 against code | None | Implement changes |
| 2026-04-09 | Implementation | Updated TDD Sections 4.1, 4.2, 3.3, 8, 9; resolved TD191 | None | Archive plan |

## Results

### Results Summary
- Documentation-only change — test baseline skipped, regression testing skipped
- TDD PD-TDD-023 updated: Sections 4.1, 4.2, 3.3, 8, 9
- TD191 resolved via Update-TechDebt.ps1
- No bugs discovered
- No new tech debt introduced

### Documentation & State Updates
1. Feature state file: N/A — documentation-only, no code impact
2. TDD: Updated (this IS the TDD update — PD-TDD-023)
3. Test spec: N/A — no behavior change
4. FDD: N/A — no functional change
5. ADR: N/A — no architectural decisions
6. Validation tracking: N/A — no active validation tracking
7. Tech debt: TD191 marked Resolved

### Remaining Technical Debt
- None

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
- [TDD 1.1.1 File System Monitoring](/doc/technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md)
