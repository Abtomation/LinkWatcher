---
id: PD-REF-064
type: Document
category: General
version: 1.0
created: 2026-03-13
updated: 2026-03-13
refactoring_scope: Fix TDD API/pseudocode drift in PD-TDD-026, PD-TDD-027, and PD-TDD-031
priority: Medium
target_area: TDD Documentation
---

# Refactoring Plan: Fix TDD API/pseudocode drift in PD-TDD-026, PD-TDD-027, and PD-TDD-031

## Overview
- **Target Area**: TDD Documentation
- **Priority**: Medium
- **Created**: 2026-03-13
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Tech Debt Item**: TD049 (continuation — 3 of 5 TDDs addressed in this plan; PD-TDD-024/025 addressed by PF-REF-061)

## Refactoring Scope

### Current Issues

PD-TDD-026 (2.2.1 Link Updater) had 10 discrepancies:
- Constructor showed `dry_run`/`backup_enabled` as parameters — actually instance attributes
- `UpdateResult` enum completely missing from TDD
- `_replace_in_line()` dispatcher method missing from internal methods and data flow
- Link type constant `"markdown_link"` wrong — actual is `"markdown"`
- Stale detection feature entirely undocumented
- `_update_file_references()` return type wrong (void vs `UpdateResult`)
- Statistics dict missing `stale_files` key
- Python import handling (`"python-import"`, `"python-quoted"`) undocumented
- `LogTimer` listed in dependencies but not imported
- `re` module missing from dependencies

PD-TDD-027 (4.1.1 Test Suite) had 6 discrepancies:
- `test_powershell.py` missing from parser test table (8 files, not 7)
- Root-level test files (`test_move_detection.py`, `test_directory_move_detection.py`) not in documented 4-category structure
- Test count outdated (247+ vs actual 380+)
- Fixture scoping wrong (said "session/function", all are function-scoped)
- Manual test directory described as "24 markdown files" — actually bug validation scripts
- `TESTING_CONFIG` source unclear (from `linkwatcher.config.defaults`, not test files)

PD-TDD-031 (5.1.1 CI/CD) had 5 discrepancies:
- Build job trigger wrong (said "push, PR" — actual is push only)
- `requirements-test.txt` referenced but doesn't exist (TD053)
- `setup_cicd.py` Python validation overstated
- Performance tests `-m slow` marker filtering not mentioned
- Job gating conditions (`if:` clauses) not documented

### Scope Discovery
- **Original Tech Debt Description**: TD049 covers 5 TDDs with 7 Critical + 15 Major issues
- **Actual Scope Findings**: This session addresses 3 of 5 TDDs (PD-TDD-026/027/031). 21 total issues found (3 Critical + 12 Major + 6 Minor)
- **Scope Delta**: None — findings match the validation report (PF-VAL-043)

### Refactoring Goals
- Synchronize all TDD pseudocode with actual source code
- Document previously undocumented features (UpdateResult enum, stale detection, PowerShell parser tests)
- Fix incorrect structural claims (test counts, directory organization, fixture scopes)

## Current State Analysis

### Code Quality Metrics (Baseline)
- **Complexity Score**: N/A — documentation-only changes
- **Code Coverage**: N/A — no code changes
- **Technical Debt**: TD049 open (5 TDDs with stale pseudocode, 2 already fixed by PF-REF-061)

### Affected Components
- `doc/technical/tdd/tdd-2-2-1-link-updater-t2.md` — PD-TDD-026
- `doc/technical/architecture/design-docs/tdd/tdd-4-1-1-test-suite-t2.md` — PD-TDD-027
- `doc/technical/architecture/design-docs/tdd/tdd-5-1-1-cicd-development-tooling-t2.md` — PD-TDD-031

### Dependencies and Impact
- **Internal Dependencies**: AI agents reading TDDs for onboarding and implementation guidance
- **External Dependencies**: None
- **Risk Assessment**: Low — documentation-only changes, no code modifications

## Refactoring Strategy

### Approach
Read each TDD alongside its source code, identify every discrepancy, and update the TDD to match the actual implementation.

### Implementation Plan

1. **Phase 1**: PD-TDD-026 (Link Updater) — 10 issues
   - Fixed constructor signature (removed false parameters, added type hints)
   - Added `UpdateResult` enum section with values and usage
   - Added stale detection section documenting two-check algorithm
   - Added `_replace_in_line()` to internal methods and data flow diagram
   - Fixed link type constants (`"markdown"`, `"markdown-reference"`)
   - Documented Python import/quoted handling in `_replace_at_position`
   - Fixed statistics dict to include `stale_files` key
   - Updated dependencies (added `re`, `enum`, removed `LogTimer`)

2. **Phase 2**: PD-TDD-027 (Test Suite) — 6 issues
   - Added `test_powershell.py` to parser test table
   - Documented root-level test files outside 4-category structure
   - Updated test count from 247+ to 380+
   - Fixed fixture scoping description (all function-scoped)
   - Updated manual test directory to reflect bug validation scripts
   - Clarified `TESTING_CONFIG` import source

3. **Phase 3**: PD-TDD-031 (CI/CD) — 5 issues
   - Fixed build job trigger (push only, not PRs)
   - Added TD053 note about missing `requirements-test.txt`
   - Fixed setup_cicd.py validation description
   - Added `-m slow` marker for performance tests
   - Documented `if:` conditions for performance and build jobs

## Testing Strategy

### Testing Approach
- **Regression Testing**: N/A — documentation-only changes
- **Verification**: All changes verified by reading source code alongside TDD edits

## Results and Lessons Learned

### Achievements
- PD-TDD-026: 10 discrepancies fixed — all pseudocode now matches `linkwatcher/updater.py` and `linkwatcher/path_resolver.py`
- PD-TDD-027: 6 discrepancies fixed — test structure documentation now matches actual `tests/` directory
- PD-TDD-031: 5 discrepancies fixed — CI pipeline documentation now matches `.github/workflows/ci.yml`
- No bugs discovered during documentation review
- TD049 fully resolved (all 5 TDDs now fixed: PD-TDD-024/025 via PF-REF-061, PD-TDD-026/027/031 via this plan)

### Remaining Technical Debt
- TD053 (missing `requirements-test.txt`) — noted in TDD but not fixed (separate code issue)
- TD055 (TDD PD-TDD-031 scope narrower than FDD) — separate scope concern, not a drift issue

## Related Documentation
- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
- [Validation Report PF-VAL-043](/doc/validation/reports/documentation-alignment/PD-VAL-043-documentation-alignment-features-2.1.1-2.2.1-3.1.1-4.1.1-5.1.1.md)
- [PF-REF-061: PD-TDD-024/025 fixes](/doc/refactoring/plans/fix-tdd-api-pseudocode-drift-in-pd-tdd-024-and-pd-tdd-025.md)
