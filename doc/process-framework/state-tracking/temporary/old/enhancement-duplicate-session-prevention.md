---
id: PF-STA-049
type: Process Framework
category: State Tracking
version: 1.0
created: 2026-02-25
updated: 2026-02-25
enhancement_name: duplicate-session-prevention
target_feature: 0.1.1
---

# Enhancement State Tracking: Duplicate Session Prevention

> **TEMPORARY FILE**: This file tracks enhancement work on an existing feature. Created by Feature Request Evaluation (PF-TSK-067), consumed by Feature Enhancement (PF-TSK-068). Move to `state-tracking/temporary/old/` when all steps are complete.

## Enhancement Overview

| Metadata | Value |
|----------|-------|
| **Target Feature** | 0.1.1 — Core Architecture |
| **Enhancement Description** | Add PID/lock file mechanism to prevent multiple LinkWatcher instances from running simultaneously on the same project |
| **Change Request** | User asked: "Do we already have the functionality that before LinkWatcher runs it checks if there is already a session running so that we don't have two sessions running at the same time?" — confirmed no such guard exists, requested implementation. |
| **Human Approval** | 2026-02-25 — Target feature confirmed by human partner |
| **Estimated Sessions** | 1 |
| **Created By** | Feature Request Evaluation (PF-TSK-067) |

## Scope Assessment

| Criterion | Assessment |
|-----------|------------|
| **Files Affected** | 3 source files: `main.py` (lock check at entry), `linkwatcher/service.py` (lock lifecycle management), `LinkWatcher_run/start_linkwatcher_background.ps1` (process check before launch). 1 test file: new or extended test for lock mechanism. 2 design docs: FDD and TDD minor amendments. |
| **Design Docs to Amend** | FDD (PD-FDD-022) — add lifecycle guard to functional behavior. TDD (PD-TDD-021) — add lock file technical design. ADR: not needed (no new architectural pattern). |
| **New Tests Required** | Yes — test lock file creation/cleanup, detection of existing instance, stale lock file handling |
| **Interface Impact** | Internal only — public API (`service.start()` / `service.stop()`) unchanged; guard is transparent to callers |
| **Session Estimate** | Single session — straightforward PID/lock file mechanism with clear implementation path |

## Existing Documentation Inventory

| Document Type | ID | Location | Action Needed |
|---------------|-----|----------|---------------|
| Feature State File | PF-FEA-046 | [0.1.1-core-architecture-implementation-state.md](../features/0.1.1-core-architecture-implementation-state.md) | Update on completion |
| FDD | PD-FDD-022 | [fdd-0-1-1-core-architecture.md](../../../product-docs/functional-design/fdds/fdd-0-1-1-core-architecture.md) | Amend — add lifecycle guard to service behavior |
| TDD | PD-TDD-021 | [tdd-0-1-1-core-architecture-t3.md](../../../product-docs/technical/architecture/design-docs/tdd/tdd-0-1-1-core-architecture-t3.md) | Amend — add lock file mechanism technical design |
| ADR | PD-ADR-039 | [orchestrator-facade-pattern.md](../../../product-docs/technical/architecture/design-docs/adr/adr/orchestrator-facade-pattern-for-core-architecture.md) | No change — enhancement works within existing pattern |
| Test Specification | PF-TSP-035 | [test-spec-0-1-1-core-architecture.md](../../../../test/specifications/feature-specs/test-spec-0-1-1-core-architecture.md) | Amend — add lock file test scenarios |

## Execution Steps

> **Structure**: These steps follow the standard feature development workflow from the [Task Transition Guide](../../guides/guides/task-transition-guide.md). Each block corresponds to a task type in the workflow. The Feature Request Evaluation task (PF-TSK-067) marks each block as **Applicable** or **Not applicable** based on the enhancement scope. The Feature Enhancement task (PF-TSK-068) executes applicable blocks in order.

---

### Step 1: Tier Reassessment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Documentation Tier Adjustment (PF-TSK-011)](../../tasks/cyclical/documentation-tier-adjustment-task.md)
- **Rationale**: Enhancement adds a startup guard — a small, self-contained mechanism. The feature remains Tier 3; adding a lock file does not change overall complexity.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 2: FDD Amendment

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [FDD Creation (PF-TSK-010)](../../tasks/02-design/fdd-creation-task.md)
- **Rationale**: The FDD describes service startup behavior. Duplicate session prevention changes user-facing behavior (service now refuses to start if another instance is running).
- **Adaptation Notes**: Amend the Service Lifecycle section of FDD PD-FDD-022 to describe: (1) lock file check at startup, (2) behavior when existing instance detected (exit with message), (3) lock file cleanup on shutdown. Keep amendment brief — 1-2 paragraphs.
- **Deliverable**: Updated FDD with duplicate instance prevention in service lifecycle section
- **Session**: 1

---

### Step 3: System Architecture Review

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [System Architecture Review (PF-TSK-019)](../../tasks/01-planning/system-architecture-review.md)
- **Rationale**: Enhancement works within existing Orchestrator/Facade architecture. Lock file is a standard OS-level mechanism, not a new architectural pattern.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 4: API Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [API Design (PF-TSK-020)](../../tasks/02-design/api-design-task.md)
- **Rationale**: No API endpoints involved — LinkWatcher is a CLI tool.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 5: Database Schema Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Database Schema Design (PF-TSK-021)](../../tasks/02-design/database-schema-design-task.md)
- **Rationale**: No database changes required.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 6: TDD Amendment

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [TDD Creation (PF-TSK-022)](../../tasks/02-design/tdd-creation-task.md)
- **Rationale**: The TDD describes service lifecycle technical design. Lock file mechanism needs technical specification (file location, format, stale lock detection, cleanup strategy).
- **Adaptation Notes**: Add "Duplicate Instance Prevention" subsection to TDD PD-TDD-021's Service Lifecycle section. Define: lock file path convention (project root `.linkwatcher.lock`), PID storage format, stale lock detection (check if PID is still running), lock acquisition/release in service start/stop, and PowerShell startup script process check.
- **Deliverable**: Updated TDD with lock file mechanism technical design
- **Session**: 1

---

### Step 7: Test Specification

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [Test Specification Creation (PF-TSK-016)](../../tasks/03-testing/test-specification-creation-task.md)
- **Rationale**: Feature is Tier 3 with an existing test specification (PF-TSP-035). New testable behavior (lock file lifecycle) should be specified.
- **Adaptation Notes**: Amend PF-TSP-035 to add test scenarios: lock file created on startup, lock file removed on clean shutdown, stale lock file detected and overridden, concurrent startup attempt rejected, lock file contains valid PID.
- **Deliverable**: Updated test specification with lock file test scenarios
- **Session**: 1

---

### Step 8: Feature Implementation Planning

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Feature Implementation Planning (PF-TSK-044)](../../tasks/04-implementation/feature-implementation-planning-task.md)
- **Rationale**: Enhancement is straightforward — clear implementation path from TDD amendment directly to coding. No multi-layer sequencing needed.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 9: Data Layer Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Data Layer Implementation (PF-TSK-051)](../../tasks/04-implementation/data-layer-implementation.md)
- **Rationale**: No data model changes required. Lock file is an OS-level file, not part of the LinkDatabase.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 10: State Management Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [State Management Implementation (PF-TSK-056)](../../tasks/04-implementation/state-management-implementation.md)
- **Rationale**: No state management layer in LinkWatcher.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 11: UI Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [UI Implementation (PF-TSK-052)](../../tasks/04-implementation/ui-implementation.md)
- **Rationale**: No UI components — LinkWatcher is a CLI/background service.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 12: Integration & Testing

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: Lock mechanism spans Python service layer (`main.py`/`service.py`) and PowerShell startup script — needs integration verification that both layers cooperate correctly.
- **Adaptation Notes**: Implement the lock file mechanism in `main.py` or `service.py` (Python-level guard). Update `start_linkwatcher_background.ps1` to check for existing process before launching. Verify end-to-end: startup creates lock, second startup detects lock, shutdown removes lock.
- **Deliverable**: Working lock file mechanism in Python + updated PowerShell startup script, integration verified
- **Session**: 1

---

### Step 13: Quality Validation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Quality Validation (PF-TSK-054)](../../tasks/04-implementation/quality-validation.md)
- **Rationale**: Minor enhancement — code review (Step 16) is sufficient quality assurance.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 14: Implementation Finalization

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Implementation Finalization (PF-TSK-055)](../../tasks/04-implementation/implementation-finalization.md)
- **Rationale**: Single-session enhancement — finalization handled inline during implementation.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 15: Update Tests

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: New testable behavior: lock file creation, cleanup, stale detection, concurrent prevention.
- **Adaptation Notes**: Add test cases to `tests/unit/test_service.py` or create dedicated test file. Test: lock file created on service start, lock file removed on clean stop, stale PID lock overridden, second instance prevented when lock exists with live PID, lock file contains correct PID.
- **Deliverable**: Test cases for lock file mechanism, all passing
- **Session**: 1

---

### Step 16: Code Review

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: [Code Review (PF-TSK-005)](../../tasks/06-maintenance/code-review-task.md)
- **Rationale**: Enhancement modifies service lifecycle — core startup/shutdown path. Review ensures correctness of PID handling and edge cases (stale locks, race conditions).
- **Adaptation Notes**: Focus review on: lock file path construction, PID validation logic, cleanup in error paths (e.g., exception during startup after lock acquired), cross-platform compatibility (Windows PID checking).
- **Deliverable**: Code review completed and any issues resolved
- **Session**: 1

---

### Step 17: Update Feature State

- **Status**: [x] Complete
- **Applicable**: Yes
- **Referenced Task Doc**: N/A — direct state file update
- **Rationale**: Feature state must always be updated to reflect the enhancement
- **Adaptation Notes**: Update 0.1.1 Core Architecture implementation state file (PF-FEA-046) to document the duplicate session prevention enhancement. Add to "What's Working" list and Code Inventory if new files are created.
- **Deliverable**: Updated feature implementation state file
- **Session**: 1

---

## Session Log

### Session 1: 2026-02-25

**Completed**:
- Step 2: FDD Amendment — added FR-8, EC-7, EC-8 to PD-FDD-022
- Step 6: TDD Amendment — added Section 4.2 (Duplicate Instance Prevention) to PD-TDD-021
- Step 7: Test Specification — added 6 lock file test cases to PF-TSP-035
- Step 12: Integration & Testing — implemented lock mechanism in main.py, updated PowerShell script
- Step 15: Update Tests — created tests/unit/test_lock_file.py (10 tests, all passing)
- Step 16: Code Review — reviewed all 4 focus areas, no issues found
- Step 17: Update Feature State — updated PF-FEA-046 with enhancement details

**Issues**:
- None encountered

**Next Session**:
- N/A (single-session enhancement)

## Finalization Checklist

> **Instructions**: Complete when all applicable execution steps are done. This checklist is part of the Feature Enhancement task (PF-TSK-068) completion process.

- [x] All applicable execution steps marked complete
- [x] All non-applicable steps confirmed as "Not applicable" with rationale
- [x] Target feature's implementation state file updated to reflect enhancement
- [x] Feature tracking status restored (set to 🟢 Completed, removed state file link)
- [ ] This file archived to `state-tracking/temporary/old/`
