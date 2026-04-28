---
id: PD-REF-180
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-09
updated: 2026-04-09
debt_item: TD194
target_area: src/linkwatcher/utils.py
priority: Low
mode: documentation-only
feature_id: 0.1.1
refactoring_scope: Add AI Context docblock to utils.py and fix phantom function names in feature state file
---

# Documentation Refactoring Plan: Add AI Context docblock to utils.py and fix phantom function names in feature state file

## Overview
- **Target Area**: src/linkwatcher/utils.py
- **Priority**: Low
- **Created**: 2026-04-09
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Documentation-only (no code changes, no test impact)
- **Debt Item**: TD194

## Refactoring Scope
<!-- Detailed description of what documentation will be refactored and why -->

### Current Issues
- Issue 1: `src/linkwatcher/utils.py` has no AI Context docblock despite being imported by 8 modules — navigation blind spot for AI agents
- Issue 2: Feature state file `0.1.1-core-architecture-implementation-state.md` lists `calculate_relative_path()` and `is_subpath()` as key components of utils.py, but **neither function exists or ever existed in git history**. Actual function is `get_relative_path()`. Missing functions: `looks_like_file_path()`, `looks_like_directory_path()`, `safe_file_read()`, `find_line_number()`, `should_ignore_directory()`

### Scope Discovery
- **Original Tech Debt Description**: "utils.py has no AI Context section despite being imported by 5+ modules — navigation blind spot for AI agents"
- **Actual Scope Findings**: Import count is 8 (not 5+). Additionally, the feature state file has phantom function names that were likely hallucinated during Codebase Feature Discovery — creating a secondary documentation drift issue.
- **Scope Delta**: Slightly broader than original — adding state file correction alongside the AI Context docblock

### Root Cause Analysis
The documentation drift has two distinct causes:
1. **Missing AI Context**: In commit `cf30016` (Round 2 validation), AI Context sections were batch-added to 12 modules but utils.py was skipped entirely — it wasn't in the commit's `--stat` output. Likely overlooked as "just utility functions" despite being the most-imported module.
2. **Phantom function names**: The 0.1.1 state file was created during Codebase Feature Discovery (PF-TSK-064). The agent listed `calculate_relative_path()` and `is_subpath()` instead of the actual `get_relative_path()` — plausible names inferred rather than verified against source code.

### Refactoring Goals
- Goal 1: Add AI Context docblock to utils.py following the established pattern (entry point, callers, common tasks)
- Goal 2: Correct phantom function names in the 0.1.1 feature state file to match actual code
- Goal 3: Eliminate navigation blind spot for AI agents working with core utility functions

## Current State Analysis

### Documentation Quality Baseline
- **Accuracy**: Feature state file lists 2 phantom functions (`calculate_relative_path`, `is_subpath`) that never existed — inaccurate
- **Completeness**: utils.py has 0 of 8 functions listed in any AI Context section; state file lists 4 of 8 functions
- **Cross-references**: Links in state file are correct (file path resolves)
- **Consistency**: 12/29 linkwatcher modules have AI Context sections; utils.py is a gap in the pattern

### Affected Documents
- Document 1: `src/linkwatcher/utils.py` — Add AI Context docblock section to module docstring
- Document 2: `doc/state-tracking/features/0.1.1-core-architecture-implementation-state.md` — Fix phantom function names in Code Inventory table

### Dependencies and Impact
- **Cross-references**: No documents reference specific function names from utils.py docstring — safe to modify
- **State files**: Technical debt tracking (TD194 → Resolved)
- **Risk Assessment**: Low — docstring additions and state file corrections have zero runtime impact

*Documentation-only change — test baseline skipped (L3 exemption).*

## Refactoring Strategy

### Approach
Add AI Context docblock following the established pattern from validator.py/markdown.py. Fix state file function names by cross-referencing actual `def` statements in utils.py.

### Implementation Plan
1. **Phase 1**: Add AI Context docblock to `src/linkwatcher/utils.py`
   - Step 1.1: Write AI Context section covering entry points, 8 importers, and common tasks
   - Step 1.2: Verify format matches established pattern (validator.py, markdown.py)

2. **Phase 2**: Fix phantom function names in feature state file
   - Step 2.1: Replace `calculate_relative_path()` → `get_relative_path()` in Code Inventory
   - Step 2.2: Replace `is_subpath()` with actual functions: `looks_like_file_path()`, `safe_file_read()`
   - Step 2.3: Update the feature description paragraph that also references phantom names

## Verification Approach
- **Link validation**: LinkWatcher running in background; no new links being created
- **Content accuracy**: Cross-check every function name in AI Context against `grep "^def " linkwatcher/utils.py`
- **Consistency check**: Compare AI Context format with validator.py pattern

## Success Criteria

### Documentation Quality Improvements
- **Accuracy**: All function names in state file match actual code — zero phantom names
- **Completeness**: AI Context lists all 8 public functions with their primary callers
- **Cross-references**: No new cross-references needed (docstring-internal only)

### Documentation Integrity
- [x] All existing cross-references preserved or updated
- [x] No orphaned references created
- [x] Terminology consistent with project conventions
- [x] LinkWatcher confirms no broken links

## Implementation Tracking

### Progress Log
<!-- Track progress during implementation -->
| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-04-09 | Planning | Plan created, root cause identified | None | Implement changes |
| 2026-04-09 | Implementation | AI Context docblock added to utils.py; phantom function names fixed in 0.1.1 state file (3 locations) and 2.2.1 state file (1 location) | Found additional phantom in 2.2.1 state file — updater.py doesn't import utils at all | Resolve TD, archive plan |

## Results

### Remaining Technical Debt
- TD193 (models.py AI Context) and TD199 (5 parser modules AI Context) remain open — related but separate items

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
