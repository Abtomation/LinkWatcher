---
id: PF-REF-059
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-03-04
updated: 2026-03-13
target_area: Feature State Files
refactoring_scope: Fix inaccurate details in feature state files PF-FEA-046 through PF-FEA-049 (TD047)
mode: lightweight
priority: Medium
---

# Lightweight Refactoring Plan: Fix inaccurate details in feature state files PF-FEA-046 through PF-FEA-049 (TD047)

- **Target Area**: Feature State Files
- **Priority**: Medium
- **Created**: 2026-03-04
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Lightweight (documentation-only, no code changes, no architectural impact)

## Item 1: TD047 — Fix inaccurate details in PF-FEA-046 (0.1.1 Core Architecture)

**Scope**: Fix wrong FileOperation data model type (named tuple → dataclass), wrong signal handler registration location (start() → __init__()), add missing path_resolver.py to code inventory, update stale Next Steps.

**Changes Made**:
- [x] Section 1: Fixed `FileOperation` from "named tuple: old_path, new_path, timestamp" to "dataclass: operation_type, old_path, new_path, timestamp"
- [x] Section 1 Scope: Changed "FileOperation named tuple" to "FileOperation dataclass"
- [x] Section 7 Decision 2: Fixed signal handler registration from "during `start()`" to "in `__init__()`"
- [x] Section 7 Decision 3: Updated title and content from "Named Tuple for FileOperation" to "Dataclass for Both"
- [x] Section 7 Implementation Patterns: Updated Data Model Pattern description
- [x] Section 5: Added `linkwatcher/path_resolver.py` to Code Inventory
- [x] Section 9: Updated Next Steps — test spec PF-TSP-035 already exists

**Test Baseline**: N/A — documentation-only changes, no code modified
**Test Result**: N/A

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.1) updated — this IS the target file
- [x] TDD (0.1.1) — N/A: _TDD has its own drift issues tracked separately as TD045; this task only fixes state file inaccuracies_
- [x] Test spec (0.1.1) — N/A: _No behavior change — documentation corrections only_
- [x] FDD (0.1.1) — N/A: _No functional change — documentation corrections only_
- [x] ADR (0.1.1) — N/A: _ADR PD-ADR-039 already correct (says __init__())_
- [x] Foundational validation tracking — N/A: _TD047 is tracked in foundational-validation-tracking.md; will be updated via Update-TechDebt.ps1_
- [ ] Technical Debt Tracking: TD047 marked resolved (L7)

**Bugs Discovered**: None

## Item 2: TD047 — Fix inaccurate details in PF-FEA-047 (0.1.2 In-Memory Link Database)

**Scope**: Fix 3 wrong method names, add 4 missing public methods to API description, update stale Current Task and Next Steps.

**Changes Made**:
- [x] Section 1: Fixed method names — `remove_links_for_file()` → `remove_file_links()`, `get_links_to_target()` → `get_references_to_file()`, `get_all_links()` → `get_all_targets_with_references()`
- [x] Section 1: Added missing methods — `update_target_path()`, `remove_targets_by_path()`, `get_source_files()`, `get_stats()`
- [x] Section 1 Scope: Updated from "5 operations" to "9 public methods", added target path updating and bulk removal
- [x] Section 2: Updated Current Task from "Feature Consolidation" to "None (maintenance)", cleared In Progress
- [x] Section 2: Added "Full CRUD operations (9 public methods)" and "Target path updating and bulk removal"
- [x] Section 9: Updated Next Steps — test spec PF-TSP-036 already exists

**Test Baseline**: N/A — documentation-only changes
**Test Result**: N/A

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.2) updated — this IS the target file
- [x] TDD (0.1.2) — N/A: _TDD has its own drift tracked as TD045; this task only fixes state file_
- [x] Test spec (0.1.2) — N/A: _No behavior change_
- [x] FDD (0.1.2) — N/A: _No functional change_
- [x] ADR (0.1.2) — N/A: _ADR PD-ADR-040 already lists correct methods_
- [x] Foundational validation tracking — N/A: _Handled via TD047 resolution_
- [ ] Technical Debt Tracking: TD047 marked resolved (L7)

**Bugs Discovered**: None

## Item 3: TD047 — Fix inaccurate details in PF-FEA-048 (0.1.3 Configuration System)

**Scope**: Fix phantom "debug" preset — change "4 presets" to "3 presets" and remove "debug" from list. Update stale Current Task.

**Changes Made**:
- [x] Section 1: Changed "Four environment presets (development, production, testing, debug)" to "Three environment presets (development, production, testing)"
- [x] Section 1 Scope: Changed "4 environment presets" to "3 environment presets"
- [x] Section 2: Updated Current Task from "Feature Consolidation" to "None (maintenance)", cleared In Progress
- [x] Section 2: Updated "4 environment presets functional" to "3 environment presets functional"
- [x] Section 7 Decision 3: Changed "4 named presets" to "3 named presets", removed "debug" from list

**Test Baseline**: N/A — documentation-only changes
**Test Result**: N/A

**Documentation & State Updates**:
- [x] Feature implementation state file (0.1.3) updated — this IS the target file
- [x] TDD (0.1.3) — N/A: _Tier 1 feature, no TDD exists_
- [x] Test spec (0.1.3) — N/A: _No behavior change_
- [x] FDD (0.1.3) — N/A: _Tier 1 feature, no FDD exists_
- [x] ADR (0.1.3) — N/A: _No ADR exists for this feature_
- [x] Foundational validation tracking — N/A: _Handled via TD047 resolution_
- [ ] Technical Debt Tracking: TD047 marked resolved (L7)

**Bugs Discovered**: None

## Item 4: TD047 — Fix inaccurate details in PF-FEA-049 (1.1.1 File System Monitoring)

**Scope**: Fix "2-second timer" to "10-second timer" (actual `delay=10.0` in move_detector.py) across all occurrences.

**Changes Made**:
- [x] Section 1: Fixed "2-second timer" → "10-second timer" in feature description (2 occurrences)
- [x] Section 1 Scope: Fixed "2-second pairing window" → "10-second pairing window"
- [x] Section 2: Fixed "within 2s" → "within 10s" in What's Working
- [x] Section 2 Success Metrics: Fixed "within 2 seconds" → "within 10 seconds"
- [x] Section 7 Decision 1: Fixed "2-second timer-based pairing" and "within 2s" → 10-second
- [x] Section 7 Implications: Fixed "2-second delay" → "10-second delay"
- [x] Section 8: Fixed "2-second move detection delay" → "10-second move detection delay"

**Test Baseline**: N/A — documentation-only changes
**Test Result**: N/A

**Documentation & State Updates**:
- [x] Feature implementation state file (1.1.1) updated — this IS the target file
- [x] TDD (1.1.1) — N/A: _TDD has its own timer drift tracked as TD045_
- [x] Test spec (1.1.1) — N/A: _No behavior change_
- [x] FDD (1.1.1) — N/A: _FDD timer drift tracked as TD046_
- [x] ADR (1.1.1) — N/A: _No ADR exists for this feature_
- [x] Foundational validation tracking — N/A: _Handled via TD047 resolution_
- [ ] Technical Debt Tracking: TD047 marked resolved (L7)

**Bugs Discovered**: None

## Results Summary

| Item | Debt ID | Status | Bugs Found | Doc Updates |
|------|---------|--------|------------|-------------|
| 1 | TD047 (PF-FEA-046) | Complete | None | State file: 7 corrections |
| 2 | TD047 (PF-FEA-047) | Complete | None | State file: 6 corrections |
| 3 | TD047 (PF-FEA-048) | Complete | None | State file: 5 corrections |
| 4 | TD047 (PF-FEA-049) | Complete | None | State file: 7 corrections |

## Related Documentation
- [Technical Debt Tracking](/doc/process-framework/state-tracking/permanent/technical-debt-tracking.md)
- [Validation Report PF-VAL-042](/doc/product-docs/validation/reports/documentation-alignment/PF-VAL-042-documentation-alignment-features-0.1.1-0.1.2-0.1.3-1.1.1.md)
