---
id: PD-REF-093
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-27
updated: 2026-03-27
priority: Medium
refactoring_scope: Update FDD EC-2 to match actual defensive parser behavior
target_area: fdd-2-1-1-parser-framework
mode: documentation-only
---

# Documentation Refactoring Plan: Update FDD EC-2 to match actual defensive parser behavior

## Overview
- **Target Area**: fdd-2-1-1-parser-framework
- **Priority**: Medium
- **Created**: 2026-03-27
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Documentation-only (no code changes, no test impact)

## Refactoring Scope

### Current Issues
- **TD091**: FDD PD-FDD-026 EC-2 states parser exceptions propagate to caller, but `LinkParser.parse_file()` (parser.py:81-88) catches all exceptions and returns empty list

### Scope Discovery
- **Original Tech Debt Description**: FDD PD-FDD-026 EC-2 states parser exceptions propagate to caller, but code catches all and returns empty list (parser.py:81-88)
- **Actual Scope Findings**: Confirmed — `LinkParser.parse_file()` wraps all parsing in try/except returning `[]`. Additionally, `BaseParser.parse_file()` (base.py:44-51) also catches all exceptions and returns `[]`. Both layers are defensive. EC-2 is inaccurate.
- **Scope Delta**: None — scope matches original description

### Refactoring Goals
- Update EC-2 to accurately describe the defensive catch-all behavior at the facade level

## Current State Analysis

### Documentation Quality Baseline
- **Accuracy**: EC-2 directly contradicts code behavior — states propagation, code catches all
- **Completeness**: EC-1 is accurate (individual parser returns empty list). Only EC-2 needs correction
- **Cross-references**: No broken cross-references
- **Consistency**: After fix, EC-1 and EC-2 will consistently describe defensive error handling at both levels

### Affected Documents
- `doc/functional-design/fdds/fdd-2-1-1-parser-framework.md` — Update EC-2 text

### Dependencies and Impact
- **Cross-references**: TDD PD-TDD-025, test-spec TE-TSP-039 may reference EC-2 — will verify
- **State files**: Technical debt tracking (TD091 → Resolved)
- **Risk Assessment**: Low — documentation-only change correcting a factual error

## Refactoring Strategy

### Approach
Single-line text replacement in FDD EC-2 to describe the actual defensive behavior.

### Implementation Plan
1. Update EC-2 in FDD PD-FDD-026
2. Verify TDD and test spec consistency with new wording
3. Mark TD091 resolved

## Verification Approach
- **Content accuracy**: Compare updated EC-2 wording against `parser.py:81-88` and `base.py:44-51`
- **Consistency check**: Grep TDD and test spec for EC-2 references to ensure alignment

## Success Criteria

### Documentation Quality Improvements
- **Accuracy**: EC-2 matches actual code behavior (catch-all → return empty list)

### Documentation Integrity
- [ ] All existing cross-references preserved or updated
- [ ] No orphaned references created
- [ ] Terminology consistent with project conventions
- [ ] LinkWatcher confirms no broken links

## Implementation Tracking

### Progress Log
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-03-27 | Implementation | Updated EC-2 in FDD, verified no TDD/test-spec references, marked TD091 resolved | None | Feedback form |

## Results and Lessons Learned

### Achievements
- EC-2 now accurately describes defensive catch-all behavior matching parser.py:81-88

### Challenges and Solutions
- None — straightforward documentation correction

### Remaining Technical Debt
- None introduced

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
