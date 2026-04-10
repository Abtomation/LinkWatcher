---
id: PD-REF-176
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
target_area: ADR-041
priority: Medium
refactoring_scope: Update ADR-041 MoveDetector section to reflect heapq+worker thread architecture (TD192)
feature_id: 1.1.1
mode: documentation-only
debt_item: TD192
---

# Documentation Refactoring Plan: Update ADR-041 MoveDetector section to reflect heapq+worker thread architecture (TD192)

## Overview
- **Target Area**: ADR-041
- **Priority**: Medium
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Planning
- **Mode**: Documentation-only (no code changes, no test impact)
- **Debt Item**: TD192

## Refactoring Scope
<!-- Detailed description of what documentation will be refactored and why -->

### Current Issues
- Issue 1: Decision 1 (line 57) states "Each pending delete has a **per-path timer**" — actual code uses single worker thread + heapq
- Issue 2: Dual-Timer Strategy section (line 76) states "One `threading.Timer` per pending delete" — actual code uses `threading.Event` wake/sleep pattern
- Issue 3: Consequences negative (line 124) states "Each pending delete spawns a `threading.Timer` thread" — this was the pre-TD107 behavior, now resolved

### Scope Discovery
- **Original Tech Debt Description**: ADR-041 still describes per-path threading.Timer design for MoveDetector but TD107 replaced with single worker thread + heapq priority queue
- **Actual Scope Findings**: Confirmed 3 specific inaccuracies in Decision 1, Dual-Timer Strategy, and Consequences sections. The code snippet in Decision 1 (matching logic) is still accurate — only the timer mechanism description is wrong. DirectoryMoveDetector sections are unaffected (still uses threading.Timer correctly).
- **Scope Delta**: None — scope matches original description. TD192 dimension is DA (Documentation Alignment).

### Refactoring Goals
- Goal 1: Update Decision 1 prose to describe single worker thread + heapq priority queue instead of per-path threading.Timer
- Goal 2: Update Dual-Timer Strategy MoveDetector subsection to reflect wake/sleep pattern
- Goal 3: Update Consequences negative bullet to reflect O(1) thread count instead of N threads

## Current State Analysis

### Documentation Quality Baseline
- **Accuracy**: MoveDetector timer mechanism description is wrong — describes pre-TD107 per-path threading.Timer design instead of current heapq + worker thread
- **Completeness**: DirectoryMoveDetector sections are complete and accurate; only MoveDetector timer description is outdated
- **Cross-references**: References section links are valid (move_detector.py, dir_move_detector.py, handler.py, TDD, FDD)
- **Consistency**: After fix, ADR-041 will be consistent with TDD-1-1-1 which already references TD107 correctly

### Affected Documents
- Document 1: `doc/technical/adr/timer-based-move-detection-with-3-phase-directory-batch-algorithm.md` — Update Decision 1 prose, Dual-Timer Strategy MoveDetector subsection, and Consequences negative bullet

### Dependencies and Impact
- **Cross-references**: TDD-1-1-1 references ADR-041 and already documents the TD107 change correctly — no update needed
- **State files**: technical-debt-tracking.md (TD192 → Resolved)
- **Risk Assessment**: Low — documentation-only change to a single file, no code impact

## Refactoring Strategy

### Approach
Update 3 specific sections of ADR-041 to replace per-path threading.Timer descriptions with heapq + single worker thread architecture. Preserve all DirectoryMoveDetector content unchanged. Add version/updated metadata to reflect the update.

### Implementation Plan
1. **Decision 1 section**: Replace "per-path timer" prose with single worker thread + heapq description. Keep the matching logic code snippet (still accurate).
2. **Dual-Timer Strategy section**: Rewrite MoveDetector subsection to describe worker thread wake/sleep pattern. Keep DirectoryMoveDetector subsection unchanged.
3. **Consequences negative bullet**: Replace "spawns a threading.Timer thread" with accurate O(1) thread description. Update the pathological condition description.
4. **Metadata**: Update version to 1.1 and updated date.

## Verification Approach
- **Content accuracy**: Compare updated ADR text against actual move_detector.py implementation line-by-line
- **Consistency check**: Verify alignment with TDD-1-1-1 TD107 references (lines 150, 274, 398)
- **Link validation**: LinkWatcher running — no file moves involved

## Success Criteria

### Documentation Quality Improvements
- **Accuracy**: All 3 inaccurate sections correctly describe heapq + worker thread architecture
- **Completeness**: No new gaps introduced; DirectoryMoveDetector content preserved
- **Cross-references**: No link changes needed — file path unchanged

### Documentation Integrity
<!-- Ensure no documentation regressions -->
- [ ] All existing cross-references preserved or updated
- [ ] No orphaned references created
- [ ] Terminology consistent with project conventions
- [ ] LinkWatcher confirms no broken links

## Implementation Tracking

### Progress Log
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-04-09 | Implementation | Updated Decision 1, Dual-Timer Strategy, Consequences sections; updated metadata | None | Finalize state files |

## Results

- **Documentation-only change** — test baseline and regression testing skipped
- **4 edits applied**: Decision 1 prose, Dual-Timer Strategy MoveDetector subsection, Consequences negative bullet, metadata version/date
- **L8 Documentation & State Updates**: Items 1-4, 6 N/A (grepped — no references to ADR-041 in feature state file, TDD, test spec, FDD, or validation tracking). Item 5 (ADR) is the target of this refactoring. Item 7 (tech debt) resolved via Update-TechDebt.ps1.
- **Bugs discovered**: None

### Remaining Technical Debt
- None introduced by this refactoring

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
