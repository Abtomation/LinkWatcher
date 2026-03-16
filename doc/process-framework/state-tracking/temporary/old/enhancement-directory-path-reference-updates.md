---
id: PF-STA-053
type: Process Framework
category: State Tracking
version: 1.0
created: 2026-03-13
updated: 2026-03-13
enhancement_name: directory-path-reference-updates
target_feature: 1.1.1
---

# Enhancement State Tracking: Directory Path Reference Updates

> **TEMPORARY FILE**: This file tracks enhancement work on an existing feature. Created by Feature Request Evaluation (PF-TSK-067), consumed by Feature Enhancement (PF-TSK-068). Move to `state-tracking/temporary/old/` when all steps are complete.

## Enhancement Overview

| Metadata | Value |
|----------|-------|
| **Target Feature** | 1.1.1 — File System Monitoring |
| **Enhancement Description** | Extend directory move handler to also update references that point to directory paths themselves (e.g., `"doc/some/directory"` in PowerShell scripts), not just files within moved directories |
| **Change Request** | User moved `documentation-tiers` directory and discovered that directory path strings in `.ps1` files were not updated. Parser change (2.1.1) already done — handler change (1.1.1) is the remaining gap. |
| **Human Approval** | 2026-03-13 — Target feature confirmed by human partner |
| **Estimated Sessions** | 1 |
| **Secondary Feature** | 2.1.1 — Link Parsing System (parser change already implemented) |
| **Created By** | Feature Request Evaluation (PF-TSK-067) |

## Scope Assessment

| Criterion | Assessment |
|-----------|------------|
| **Files Affected** | 2-3 files: `handler.py` (directory move handler logic), `reference_lookup.py` (reference search/matching), possibly `database.py` (query by path prefix). Parser change in `parsers/powershell.py` already done. |
| **Design Docs to Amend** | TDD-023 (File System Monitoring) — add directory-path reference update to move handling section. FDD-024 minimal update. |
| **New Tests Required** | Yes — new test cases for directory-path reference updates during directory moves. Modify existing handler/integration tests. |
| **Interface Impact** | Internal only — no public interface change. Move detection and update pipeline unchanged externally. |
| **Session Estimate** | Single session — localized change in move handler, parser already done |

## Existing Documentation Inventory

| Document Type | ID | Location | Action Needed |
|---------------|-----|----------|---------------|
| Feature State File | PF-FEA-049 | [1.1.1 File System Monitoring](../features/1.1.1-file-system-monitoring-implementation-state.md) | Update on completion |
| FDD | PD-FDD-024 | [FDD: File System Monitoring](../../../product-docs/functional-design/fdds/fdd-1-1-1-file-system-monitoring.md) | Minor amend — add directory-path reference handling |
| TDD | PD-TDD-023 | [TDD: File System Monitoring](../../../product-docs/technical/architecture/design-docs/tdd/tdd-1-1-1-file-system-monitoring-t2.md) | Amend — add directory-path update logic to move handling |
| ADR | N/A | None exists | No change — no new architectural decision needed |
| Test Specification | PF-TSP-038 | [Test Spec: File System Monitoring](../../../../test/specifications/feature-specs/test-spec-1-1-1-file-system-monitoring.md) | Amend — add test cases for directory-path reference updates |
| Feature State File (secondary) | PF-FEA-050 | [2.1.1 Link Parsing System](../features/2.1.1-link-parsing-system-implementation-state.md) | Update on completion (parser change already done) |

## Execution Steps

> **Structure**: These steps follow the standard feature development workflow from the [Task Transition Guide](../../guides/guides/framework/task-transition-guide.md). Each block corresponds to a task type in the workflow. The Feature Request Evaluation task (PF-TSK-067) marks each block as **Applicable** or **Not applicable** based on the enhancement scope. The Feature Enhancement task (PF-TSK-068) executes applicable blocks in order.

---

### Step 1: Tier Reassessment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Documentation Tier Adjustment (PF-TSK-011)](../../tasks/cyclical/documentation-tier-adjustment-task.md)
- **Rationale**: Not applicable — enhancement is a localized internal change to the directory move handler. Feature 1.1.1 is already Tier 2, which remains appropriate.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 2: FDD Amendment

- **Status**: [x] Complete
- **Applicable**: Yes — minor
- **Referenced Task Doc**: [FDD Creation (PF-TSK-010)](../../tasks/02-design/fdd-creation-task.md)
- **Rationale**: FDD-024 should mention that directory moves update both file references within the directory AND references to the directory path itself. This is a functional behavior change.
- **Adaptation Notes**: Add a brief note to the "Directory Move Handling" section of FDD-024 documenting that directory-path string references are now also updated.
- **Deliverable**: Updated FDD-024 with amended directory move handling description
- **Session**: 1

---

### Step 3: System Architecture Review

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [System Architecture Review (PF-TSK-019)](../../tasks/01-planning/system-architecture-review.md)
- **Rationale**: Not applicable — enhancement works within the existing handler→reference_lookup→updater pipeline. No new architectural patterns or cross-cutting concerns introduced.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 4: API Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [API Design (PF-TSK-020)](../../tasks/02-design/api-design-task.md)
- **Rationale**: Not applicable — LinkWatcher has no external API. This is an internal handler change.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 5: Database Schema Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Database Schema Design (PF-TSK-021)](../../tasks/02-design/database-schema-design-task.md)
- **Rationale**: Not applicable — the in-memory LinkDatabase already stores directory-path references (the parser adds them). No schema changes needed; the database already supports looking up references by target path.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 6: TDD Amendment

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [TDD Creation (PF-TSK-022)](../../tasks/02-design/tdd-creation-task.md)
- **Rationale**: TDD-023 documents the directory move handling algorithm. It should be amended to describe how directory-path references (not just file references within the directory) are found and updated during a directory move.
- **Adaptation Notes**: Amend the "Directory Move Handling" section of TDD-023 to add a step: after processing per-file references, scan the database for references whose `link_target` matches or starts with the old directory path, and update those targets to the new directory path.
- **Deliverable**: Updated TDD-023 with directory-path reference update logic
- **Session**: 1

---

### Step 7: Test Specification

- **Status**: [ ] Not started
- **Applicable**: No — test cases defined inline in Step 15 (Update Tests)
- **Referenced Task Doc**: [Test Specification Creation (PF-TSK-016)](../../tasks/03-testing/test-specification-creation-task.md)
- **Rationale**: Not applicable as a formal step — enhancement is small enough that test cases can be defined directly during implementation. The existing test spec PF-TSP-038 can be amended during Step 15.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 8: Feature Implementation Planning

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Feature Implementation Planning (PF-TSK-044)](../../tasks/04-implementation/feature-implementation-planning-task.md)
- **Rationale**: Not applicable — enhancement is straightforward and localized. Implementation approach is clear: add directory-path reference lookup to `_handle_directory_moved` in `handler.py`. No formal planning needed.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 9: Data Layer Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Data Layer Implementation (PF-TSK-051)](../../tasks/04-implementation/data-layer-implementation.md)
- **Rationale**: Not applicable — the in-memory database already stores directory-path references from the parser. No data model changes needed. May need a query helper in `database.py` to find references by path prefix, but this is minor enough to handle inline during Step 10.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

---

### Step 10: Core Implementation

- **Status**: [x] Complete
- **Applicable**: Yes — this is the main implementation step
- **Referenced Task Doc**: N/A — direct code change
- **Rationale**: The core change: in `_handle_directory_moved` (handler.py), after processing per-file references, also search the database for references whose `link_target` equals or starts with the old directory path, and update those to the new directory path.
- **Adaptation Notes**: Key implementation points:
  1. In `handler.py` `_handle_directory_moved`: after the per-file loop, query the database for references targeting the old directory path (exact match and prefix match for subdirectory paths)
  2. Use `reference_lookup.py` `find_references()` or add a new method to find directory-path references
  3. Call `updater.update_references()` for matched directory-path references, replacing old_dir with new_dir in the target
  4. The PowerShell parser change (adding `quoted_dir_pattern` and `_looks_like_directory_path()`) is already done
- **Deliverable**: Updated `handler.py` and possibly `reference_lookup.py` with directory-path reference update logic
- **Session**: 1

---

### Step 12: Integration & Testing

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: Enhancement spans parser → database → handler → updater pipeline. Need to verify the full flow: parser extracts directory path → database stores it → directory move triggers lookup → updater replaces path in file.
- **Adaptation Notes**: Manual testing: run LinkWatcher from repo source, move a directory containing files referenced by `.ps1` scripts, verify both file-path and directory-path references are updated. Automated: add integration test simulating directory move with directory-path references.
- **Deliverable**: Integration tests passing, manual verification confirmed
- **Session**: 1

---

### Step 13: Quality Validation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Quality Validation (PF-TSK-054)](../../tasks/04-implementation/quality-validation.md)
- **Rationale**: Not applicable — minor change, code review (Step 16) suffices for quality assurance.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 14: Implementation Finalization

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Implementation Finalization (PF-TSK-055)](../../tasks/04-implementation/implementation-finalization.md)
- **Rationale**: Not applicable — single-session enhancement, finalization handled inline.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 15: Update Tests

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: New behavior needs test coverage — directory-path reference updates during directory moves are not currently tested.
- **Adaptation Notes**: Add test cases to:
  1. `tests/parsers/test_powershell.py` — test directory path detection (the `powershell-quoted-dir` link type)
  2. Handler/integration tests — test that directory move triggers update of directory-path references in `.ps1` files
  3. Test scenarios: directory path exact match, directory path as prefix of longer path, mixed file+directory references in same file
- **Deliverable**: New test cases in existing test files
- **Session**: 1

---

### Step 16: Code Review

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [Code Review (PF-TSK-005)](../../tasks/06-maintenance/code-review-task.md)
- **Rationale**: Enhancement modifies core move-handling logic in handler.py. Review should verify no regressions in existing file-move handling and confirm correct path matching for directory references.
- **Adaptation Notes**: Focus review on: (1) directory-path reference lookup logic, (2) correct path replacement (old_dir → new_dir), (3) no duplicate updates when both file and directory references exist for the same path.
- **Deliverable**: Code review completed and any issues resolved
- **Session**: 1

---

### Step 17: Update Feature State

- **Status**: [x] Complete
- **Applicable**: Yes — always required
- **Referenced Task Doc**: N/A — direct state file update
- **Rationale**: Feature state must always be updated to reflect the enhancement.
- **Adaptation Notes**: Update both feature state files: (1) PF-FEA-049 (1.1.1 File System Monitoring) — document directory-path reference update capability in move handler, (2) PF-FEA-050 (2.1.1 Link Parsing System) — document directory path detection in PowerShell parser.
- **Deliverable**: Updated feature implementation state files for 1.1.1 and 2.1.1
- **Session**: 1

---

## Session Boundary Planning

Single-session enhancement. All applicable steps (2, 6, 10, 12, 15, 16, 17) completed in one session.

## Session Log

### Session 1: [YYYY-MM-DD]

**Completed**:
- [List completed steps]

**Issues**:
- [Any issues encountered]

**Next Session**:
- [What to continue with]

## Finalization Checklist

> **Instructions**: Complete when all applicable execution steps are done. This checklist is part of the Feature Enhancement task (PF-TSK-068) completion process.

- [ ] All applicable execution steps marked complete
- [ ] All non-applicable steps confirmed as "Not applicable" with rationale
- [ ] Target feature's implementation state file updated to reflect enhancement
- [ ] Feature tracking status restored (removed "🔄 Needs Revision", set appropriate status, removed state file link)
- [ ] This file archived to `state-tracking/temporary/old/`
