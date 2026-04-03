---
id: PD-STA-058
type: Process Framework
category: State Tracking
version: 1.0
created: 2026-03-16
updated: 2026-03-16
enhancement_name: parent-directory-reference-updates
target_feature: 1.1.1
---

# Enhancement State Tracking: Parent Directory Reference Updates

> **TEMPORARY FILE**: This file tracks enhancement work on an existing feature. Created by Feature Request Evaluation (PF-TSK-067), consumed by Feature Enhancement (PF-TSK-068). Move to `state-tracking/temporary/old/` when all steps are complete.

## Enhancement Overview

| Metadata | Value |
|----------|-------|
| **Target Feature** | 1.1.1 — File System Monitoring |
| **Secondary Features Affected** | 0.1.2 — In-Memory Link Database (new prefix-based query method) |
| **Enhancement Description** | When subdirectories move, also update references to parent directory paths by applying prefix-based replacement in the directory move handler |
| **Change Request** | After moving `doc/validation` to `doc/product-ddoc/validation to the parent directory path (e.g., `"doc/validation/reports"` in id-registry.json) were not updated, even though references to specific subdirectories were. The directory move handler's Phase 2 only matches references whose path starts with the moved directory — it doesn't update references to ancestor/parent paths. |
| **Human Approval** | 2026-03-16 — Target feature confirmed by human partner |
| **Estimated Sessions** | 1 |
| **Created By** | Feature Request Evaluation (PF-TSK-067) |

## Scope Assessment

| Criterion | Assessment |
|-----------|------------|
| **Files Affected** | 3-4 source files (`handler.py`, `reference_lookup.py`, `database.py`), 1-2 test files (`test/automated/integration/test_file_movement.py` or new test file) |
| **Design Docs to Amend** | TDD (PD-TDD-023) — directory move handling section; FDD (PD-FDD-024) — directory move behavior |
| **New Tests Required** | Yes — parent directory reference update scenarios when subdirectories move |
| **Interface Impact** | Internal only — no public API change |
| **Session Estimate** | Single session — focused logic change in directory move pipeline |

## Existing Documentation Inventory

| Document Type | ID | Location | Action Needed |
|---------------|-----|----------|---------------|
| Feature State File | PF-FEA-049 | [1.1.1-file-system-monitoring-implementation-state.md](../features/1.1.1-file-system-monitoring-implementation-state.md) | Update on completion |
| FDD | PD-FDD-024 | [fdd-1-1-1-file-system-monitoring.md](/doc/functional-design/fdds/fdd-1-1-1-file-system-monitoring.md) | Amend — update directory move behavior to describe parent path updates |
| TDD | PD-TDD-023 | [tdd-1-1-1-file-system-monitoring-t2.md](/doc/technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md) | Amend — update Phase 2 directory move handling to describe prefix-based parent path replacement |
| ADR | N/A | N/A | No change |
| Test Specification | PF-TSP-038 | [test-spec-1-1-1-file-system-monitoring.md](../../../../test/specifications/feature-specs/test-spec-1-1-1-file-system-monitoring.md) | No change |

## Execution Steps

> **Structure**: These steps follow the standard feature development workflow from the [Task Transition Guide](../../guides/framework/task-transition-guide.md). Each block corresponds to a task type in the workflow. The Feature Request Evaluation task (PF-TSK-067) marks each block as **Applicable** or **Not applicable** based on the enhancement scope. The Feature Enhancement task (PF-TSK-068) executes applicable blocks in order.

---

### Step 1: Tier Reassessment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Documentation Tier Adjustment (PF-TSK-011)](../../tasks/cyclical/documentation-tier-adjustment-task.md)
- **Rationale**: Enhancement extends existing directory move pipeline logic. Feature remains Tier 2.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 2: FDD Amendment

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [FDD Creation (PF-TSK-010)](../../tasks/02-design/fdd-creation-task.md)
- **Rationale**: The FDD describes directory move behavior. Parent directory prefix updates change the observable behavior during directory moves.
- **Adaptation Notes**: Amend PD-FDD-024 directory move section to document that when subdirectories move, references to parent directory paths that are prefixes of the moved path are also updated via prefix replacement.
- **Deliverable**: Updated FDD with parent directory update behavior
- **Session**: 1

---

### Step 3: System Architecture Review

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [System Architecture Review (PF-TSK-019)](../../tasks/01-planning/system-architecture-review.md)
- **Rationale**: Enhancement works within existing directory move pipeline architecture (Phase 2 of `_handle_directory_moved`).
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 4: API Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [API Design (PF-TSK-020)](../../tasks/02-design/api-design-task.md)
- **Rationale**: No API involved.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 5: Database Schema Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Database Schema Design (PF-TSK-021)](../../tasks/02-design/database-schema-design-task.md)
- **Rationale**: No database schema changes required.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 6: TDD Amendment

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [TDD Creation (PF-TSK-022)](../../tasks/02-design/tdd-creation-task.md)
- **Rationale**: The TDD documents the Phase 2 directory-path reference update pipeline. The prefix-based parent path matching logic is a technical design change.
- **Adaptation Notes**: Amend PD-TDD-023 directory move handling section to describe: (1) when a subdirectory moves, `find_directory_path_references` also queries for references whose target is a parent/ancestor of the moved directory path, (2) prefix replacement logic replaces the matching prefix portion of the reference target. Possibly add a new method to `database.py` for prefix-based directory reference queries.
- **Deliverable**: Updated TDD with parent directory prefix replacement design
- **Session**: 1

---

### Step 7: Test Specification

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Test Specification Creation (PF-TSK-016)](../../tasks/03-testing/test-specification-creation-task.md)
- **Rationale**: Feature is Tier 2 — test specification exists but does not need formal amendment. Test cases will be defined in Step 15.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 8: Feature Implementation Planning

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Feature Implementation Planning (PF-TSK-044)](../../tasks/04-implementation/feature-implementation-planning-task.md)
- **Rationale**: Enhancement scope is clear — extend the existing directory move Phase 2 to also match parent path references.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 9: Data Layer Implementation

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [Data Layer Implementation (PF-TSK-051)](../../tasks/04-implementation/data-layer-implementation.md)
- **Rationale**: May need a new query method in `database.py` to find references whose target is an ancestor/prefix of a given directory path (inverse of current `get_references_to_directory` which finds references starting with the directory).
- **Adaptation Notes**: Add a method like `get_references_to_parent_directories(dir_path)` to `database.py` that finds all stored directory-path references where the reference target is a prefix/ancestor of `dir_path`. Alternatively, extend `find_directory_path_references` in `reference_lookup.py` to also check ancestor paths.
- **Deliverable**: New or extended database/lookup method for parent directory matching
- **Session**: 1

---

### Step 12: Integration & Testing

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: Enhancement touches handler, reference_lookup, and database layers — needs integration verification that the full pipeline works for parent directory references.
- **Adaptation Notes**: Implement the prefix replacement logic in `handler.py` `_handle_directory_moved()` Phase 2 and/or `reference_lookup.py`. When a subdirectory moves, identify all stored references whose target path is an ancestor of the moved path, then apply prefix replacement so the ancestor reference points to the new parent location. Run full test suite to verify no regressions.
- **Deliverable**: Updated handler/reference_lookup code, all existing tests passing
- **Session**: 1

---

### Step 13: Quality Validation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Quality Validation (PF-TSK-054)](../../tasks/04-implementation/quality-validation.md)
- **Rationale**: Code review suffices for this focused logic change.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 14: Implementation Finalization

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Implementation Finalization (PF-TSK-055)](../../tasks/04-implementation/implementation-finalization.md)
- **Rationale**: Single-session enhancement, no finalization needed.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 15: Update Tests

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: Parent directory prefix replacement is new testable behavior.
- **Adaptation Notes**: Add test cases: (1) when subdirectory moves, a reference to the parent directory path gets its prefix updated, (2) when multiple subdirectories share a parent, the parent reference is updated on the first move, (3) nested ancestor paths (grandparent) are also updated, (4) non-matching parent paths are not affected.
- **Deliverable**: New test cases covering parent directory reference updates
- **Session**: 1

---

### Step 16: Code Review

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [Code Review (PF-TSK-005)](../../tasks/06-maintenance/code-review-task.md)
- **Rationale**: Enhancement modifies core directory move pipeline logic — review is warranted to catch edge cases (e.g., false positive parent matching, partial path overlaps).
- **Adaptation Notes**: Focus review on: prefix matching correctness (avoid partial directory name matches like `doc/val` matching `doc/validation`), interaction with existing Phase 2 logic, performance impact of additional database queries.
- **Deliverable**: Code review completed and any issues resolved
- **Session**: 1

---

### Step 17: Update Feature State

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: N/A — direct state file update
- **Rationale**: Feature state must always be updated to reflect the enhancement
- **Adaptation Notes**: Update 1.1.1 implementation state file (PF-FEA-049) to document parent directory reference updates enhancement in the Enhancement Log and Recently Completed sections.
- **Deliverable**: Updated feature implementation state file
- **Session**: 1

---

## Session Log

### Session 1: [YYYY-MM-DD]

**Completed**:
- [List completed steps]

**Issues**:
- [Any issues encountered]

## Finalization Checklist

> **Instructions**: Complete when all applicable execution steps are done. This checklist is part of the Feature Enhancement task (PF-TSK-068) completion process.

- [ ] All applicable execution steps marked complete
- [ ] All non-applicable steps confirmed as "Not applicable" with rationale
- [ ] Target feature's implementation state file updated to reflect enhancement
- [ ] Feature tracking status restored (removed "🔄 Needs Revision", set appropriate status, removed state file link)
- [ ] This file archived to `state-tracking/temporary/old/`
