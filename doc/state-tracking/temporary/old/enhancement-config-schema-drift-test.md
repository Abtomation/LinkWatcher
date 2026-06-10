---
id: PF-STA-108
type: Process Framework
category: State Tracking
version: 1.0
created: 2026-06-10
updated: 2026-06-10
inherited_dimensions: EM,SE,DI
target_feature: 0.1.3
enhancement_name: config-schema-drift-test
---

# Enhancement State Tracking: Config Schema Drift Test

> **TEMPORARY FILE**: This file tracks enhancement work on an existing feature. Created by Feature Request Evaluation (PF-TSK-067), consumed by Feature Enhancement (PF-TSK-068). Move to `state-tracking/temporary/old/` when all steps are complete.

## Enhancement Overview

| Metadata | Value |
|----------|-------|
| **Target Feature** | 0.1.3 — Configuration System |
| **Secondary Features Affected** | None |
| **Enhancement Description** | Unit test asserting LinkWatcherConfig dataclass fields stay in sync with the configuration guide Full Reference block (keys + scalar defaults) and the WIP template config-examples/linkwatcher-config.yaml (keys only), so schema drift fails the release-gating test sweep |
| **Change Request** | Ad-hoc (2026-06-10): after manual de-duplication of the config schema across handbooks surfaced 4 drift instances, add an automated guard so future drift fails `Run-Tests.ps1 -All` (release gate Step 10 of PF-TSK-008). Test design approved at checkpoint: keys-equality both directions against guide Full Reference block + WIP template; scalar-default value equality against guide only; quick-reference and capabilities-reference deliberately untested (intentionally partial). |
| **Human Approval** | 2026-06-10 — Classification, target feature, and test design confirmed by human partner |
| **Estimated Sessions** | 1 |
| **Created By** | Feature Request Evaluation (PF-TSK-067) |

## Scope Assessment

| Criterion | Assessment |
|-----------|------------|
| **Files Affected** | ~3: one new test file under `test/automated/unit/0-system-architecture-foundation/` (via `New-TestFile.ps1`, which also updates test tracking); one test-case row appended to TE-TSP-037; no production code changes |
| **Design Docs to Amend** | None — Tier 1 feature, no FDD/TDD/ADR exists; no design change |
| **New Tests Required** | Yes — one new test file (drift assertions); no modifications to existing tests |
| **Interface Impact** | Internal only — no public interface change; couples test to configuration-guide.md structure (Full Reference heading + fenced YAML block) by design |
| **Session Estimate** | Single session — one self-contained test file plus registration |

## Existing Documentation Inventory

| Document Type | ID | Location | Action Needed |
|---------------|-----|----------|---------------|
| Feature State File | PD-FIS-048 | [0.1.3-configuration-system-implementation-state.md](../../features/0.1.3-configuration-system-implementation-state.md) | Update on completion |
| FDD | N/A | None exists (Tier 1) | No change |
| TDD | N/A | None exists (Tier 1) | No change |
| ADR | N/A | None exists | No change |
| Test Specification | TE-TSP-037 | [test-spec-0-1-3-configuration-system.md](../../../../test/specifications/feature-specs/test-spec-0-1-3-configuration-system.md) | Amend — add drift-test case row |

## Dimension Impact Assessment

> **Reference**: [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md)
>
> Inherited from parent feature (0.1.3): EM,SE,DI
> **Additional for this enhancement**: none — test-only change; no new input handling, no writes, no user surface
> **Reduced for this enhancement**: SE and DI do not actively apply to the test itself (it reads two repo files and a dataclass); they remain Critical/Relevant on the parent feature unchanged

### Key Dimension Considerations

- **Extensibility & Maintainability (EM)**: The driving dimension — the test exists to keep the config schema's documentation surface maintainable. Failure messages must name the exact missing/stale keys so the fix is obvious. Any future legitimate doc-only key goes in an explicit allowlist constant, not a silent relaxation.

## Execution Steps

> **Structure**: These steps follow the standard feature development workflow from the [Task Transition Registry](../../infrastructure/task-transition-registry.md). Each block corresponds to a task type in the workflow. The Feature Request Evaluation task (PF-TSK-067) marks each block as **Applicable** or **Not applicable** based on the enhancement scope. The Feature Enhancement task (PF-TSK-068) executes applicable blocks in order.

---

### Step 1: Tier Reassessment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Documentation Tier Adjustment (PF-TSK-011)](../../tasks/cyclical/documentation-tier-adjustment-task.md)
- **Rationale**: Not applicable — test-only addition adds no complexity to the Tier 1 feature; current tier remains appropriate
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 2: FDD Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [FDD Creation (PF-TSK-010)](../../tasks/02-design/fdd-creation-task.md)
- **Rationale**: Not applicable — no FDD exists (Tier 1) and the enhancement has no functional/user-facing change
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 3: System Architecture Review

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [System Architecture Review (PF-TSK-019)](../../tasks/01-planning/system-architecture-review.md)
- **Rationale**: Not applicable — works entirely within the existing pytest unit-test infrastructure
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 4: API Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [API Design (PF-TSK-020)](../../tasks/02-design/api-design-task.md)
- **Rationale**: Not applicable — no API changes
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 5: Database Schema Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Database Schema Design (PF-TSK-021)](../../tasks/02-design/database-schema-design-task.md)
- **Rationale**: Not applicable — no database in this project
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 6: TDD Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [TDD Creation (PF-TSK-022)](../../tasks/02-design/tdd-creation-task.md)
- **Rationale**: Not applicable — no TDD exists (Tier 1); the approved test design is recorded in this file's Change Request row
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 7: Test Specification

- **Status**: [x] Complete (2026-06-10) — TE-TSP-037 amended with "Config Schema Drift Guard" scenario table
- **Applicable**: Yes (lightweight)
- **Referenced Task Doc**: [Test Specification Creation (PF-TSK-012)](../../tasks/03-testing/test-specification-creation-task.md)
- **Rationale**: The new test should be traceable from the feature's existing test specification — one amendment, not a new spec
- **Adaptation Notes**: Append one test-case entry to TE-TSP-037 describing the three drift assertions (guide keys both directions, template keys both directions, guide scalar defaults) and the allowlist convention. Do this in the same session as Step 15, after the test exists
- **Deliverable**: TE-TSP-037 amended with the drift-test case
- **Session**: 1

---

### Step 8: Feature Implementation Planning

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Feature Implementation Planning (PF-TSK-044)](../../tasks/04-implementation/feature-implementation-planning-task.md)
- **Rationale**: Not applicable — one self-contained test file; the approved design in the Change Request row is the plan
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 9: Data Layer Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Data Layer Implementation (PF-TSK-051)](../../tasks/04-implementation/data-layer-implementation.md)
- **Rationale**: Not applicable — no data model changes
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 10: State Management Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [State Management Implementation (PF-TSK-052)](../../tasks/04-implementation/state-management-implementation.md)
- **Rationale**: Not applicable — no state management layer involved
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 11: UI Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [UI Implementation (PF-TSK-050)](../../tasks/04-implementation/ui-implementation.md)
- **Rationale**: Not applicable — no UI in this project
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 12: Integration & Testing

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: Not applicable — single-layer change; the deliverable is itself a test, verified by running the suite in Step 15
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 13: Quality Validation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Quality Validation (PF-TSK-054)](../../tasks/04-implementation/quality-validation.md)
- **Rationale**: Not applicable — minor change, code review (Step 16) suffices
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 14: Implementation Finalization

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Implementation Finalization (PF-TSK-055)](../../tasks/04-implementation/implementation-finalization.md)
- **Rationale**: Not applicable — single-session enhancement, finalization handled inline via the Finalization Checklist below
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 15: Update Tests

- **Status**: [x] Complete (2026-06-10) — TE-TST-136 created via New-TestFile.ps1, relocated to feature dir, 5 tests implemented and passing; full sweep green (878 passed); deviation: template assertion is one-way (template ⊆ fields) because the WIP template is the curated project-configurable subset, not a full schema mirror
- **Applicable**: Yes — **this is the core step**
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: The enhancement *is* a new test file
- **Adaptation Notes**: Create the test file via `New-TestFile.ps1` (feature 0.1.3, unit category — script registers tracking + markers). Implement per the approved design: (1) `dataclasses.fields(LinkWatcherConfig)` as code truth; (2) keys-equality both directions vs. `yaml.safe_load` of `config-examples/linkwatcher-config.yaml` top-level keys; (3) keys-equality both directions vs. the fenced YAML block under the configuration guide's "Full Reference" heading; (4) scalar-default equality (bool/int/float/str) guide-only; (5) empty allowlist constant for future legitimate exceptions; failure messages name exact keys. Verify green via `Run-Tests.ps1 -Category unit` (or direct pytest), and verify it *fails correctly* by temporarily checking a key mismatch detection (e.g., assert against a doctored copy in the test's own negative case, not by editing real files)
- **Deliverable**: New passing drift-test file, registered in test tracking
- **Session**: 1

---

### Step 16: Code Review

- **Status**: [x] Complete (2026-06-10) — focused review of extraction regex (CRLF, sanity floor), set-difference directions, scalar edge cases (None/null, bool-as-int, factory skip); no blocking findings
- **Applicable**: Yes (lightweight)
- **Referenced Task Doc**: [Code Review (PF-TSK-005)](../../tasks/06-maintenance/code-review-task.md)
- **Rationale**: Single test file, but it encodes a contract (doc structure coupling, allowlist convention) worth a focused review
- **Adaptation Notes**: Review scope: correctness of the YAML-block extraction, set-difference directions, scalar-default comparison edge cases (None/null, bool capitalization), and clarity of failure messages
- **Deliverable**: Review completed, issues resolved
- **Session**: 1

---

### Step 17: User Documentation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [User Documentation Creation (PF-TSK-081)](../../tasks/07-deployment/user-documentation-creation.md)
- **Rationale**: Not applicable — developer-facing test with no user-visible behavior; the related handbook consolidation was already completed separately (PF-TSK-081 session, 2026-06-10)
- **Adaptation Notes**: —
- **Deliverable**: N/A
- **Session**: —

---

### Step 18: Update Feature State

- **Status**: [x] Complete (2026-06-10) — PD-FIS-048 §2 enhancement entry added, §5 Test Files row added
- **Applicable**: Yes — always required
- **Referenced Task Doc**: N/A — direct state file update
- **Rationale**: Feature state must always be updated to reflect the enhancement
- **Adaptation Notes**: Update PD-FIS-048 (0.1.3 state file): add the drift test to §5 Code Inventory (Test Files) and note the enhancement in §2 Current State Summary; restore feature-tracking status per the Finalization Checklist
- **Deliverable**: Updated 0.1.3 implementation state file
- **Session**: 1

---

## Session Boundary Planning

Single-session enhancement — all applicable steps (7, 15, 16, 18) in Session 1, in execution order 15 → 7 → 16 → 18.

## Session Log

### Session 1: 2026-06-10

**Completed**:
- All applicable steps (15 → 7 → 16 → 18) in one session; full sweep green (878 passed, 3 skipped, 4 xfailed); Validate-TestTracking 0 errors

**Issues**:
- Design deviation (approved design said "keys-equality both directions" for both targets): the WIP template is a curated minimal subset (only `path_resolution_overrides` active), so the template assertion is one-way (template keys ⊆ config fields). Guide assertions unchanged (full equality + scalar defaults).
- New-TestFile.ps1 placed the file at `unit/` root rather than the feature subdir; relocated via Move-Item while still template-content.
- **Potential product bug observed**: LinkWatcher detected the relocation (delete+create correlation, `move_detected` logged) but reported `no_references_found` — the minutes-old link in test-tracking.md was not in its database, so the reference was not rewritten (fixed manually). Filed as PD-BUG-102 (Medium, 2026-06-10): freshly-written links may not be indexed before a subsequent move.

## Finalization Checklist

> **Instructions**: Complete when all applicable execution steps are done. This checklist is part of the Feature Enhancement task (PF-TSK-068) completion process.

- [ ] All applicable execution steps marked complete
- [ ] All non-applicable steps confirmed as "Not applicable" with rationale
- [ ] Target feature's implementation state file updated to reflect enhancement
- [ ] Feature tracking status restored (removed "🔄 Needs Enhancement", set appropriate status, removed state file link)
- [ ] This file archived to `state-tracking/temporary/old/`
