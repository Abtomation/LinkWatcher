---
id: PF-PRO-013
type: Document
category: General
version: 1.0
created: 2026-03-31
updated: 2026-03-31
extension_name: Workflow-Level Framework Layer
extension_scope: Cross-phase framework extension affecting tasks in phases 00-06
extension_description: Thread workflow awareness through design, implementation, validation, and maintenance phases
---

# Workflow-Level Framework Layer - Framework Extension Concept

## Document Metadata
| Metadata | Value |
|----------|-------|
| Document Type | Framework Extension Concept |
| Created Date | 2026-03-31 |
| Status | Awaiting Human Review |
| Extension Name | Workflow-Level Framework Layer |
| Extension Scope | Cross-phase framework extension affecting tasks in phases 00-06 |
| Source | [PF-IMP-258](/process-framework/state-tracking/permanent/process-improvement-tracking.md) |
| Author | AI Agent & Human Partner |

---

## 1. Purpose & Context

### Problem Statement

The framework operates at the **feature level** through phases 02-06 (design, implementation, validation, maintenance), but **workflow-level thinking** exists only at two "bookend" positions:

1. **Planning entry**: Feature Request Evaluation maps features to workflows
2. **Testing exit**: E2E acceptance testing validates cross-feature workflows

This creates a systematic gap where:
- Designers don't consider which workflows a feature participates in
- Implementers don't verify workflow correctness across feature boundaries
- Validators assess features in isolation, missing emergent cross-feature effects
- Maintainers fix bugs without understanding workflow blast radius

### Evidence

- `user-workflow-tracking.md` is referenced by only **2 of 32+ tasks** in phases 02-06 (6%)
- `feature-dependencies.md` is referenced by **0 implementation/validation/maintenance tasks**
- 17 phase 02-06 tasks have **zero** workflow references

### Extension Overview

This extension threads workflow awareness through existing tasks by:
- Making `user-workflow-tracking.md` a proper state tracking artifact
- Adding lightweight workflow integration points to key tasks in each phase
- Ensuring the workflow map is populated during project onboarding
- Using workflow context to improve prioritization, session planning, and blast radius assessment

### Key Distinction from Existing Framework Components

| Existing Component | Purpose | Scope |
|-------------------|---------|-------|
| **Structure Change Task** | Reorganizes existing framework components | Rearrangement of current elements |
| **Process Improvement Task** | Makes granular improvements to existing processes | Optimization of current workflows |
| **New Task Creation Process** | Creates individual new tasks | Single task creation |
| **Workflow-Level Framework Layer** *(This Extension)* | **Threads cross-feature workflow awareness through all framework phases** | **Modifies existing tasks, promotes workflow map to state tracking, adds workflow fields to state files and tracking tables** |

---

## 2. Workflow Map as State Tracking Artifact

### Current State

`user-workflow-tracking.md` (PD-DES-002) currently lives in `doc/product-docs/technical/design/` as a design artifact. It is treated as a one-time planning output, not as a living state file.

### Proposed Change

**Promote `user-workflow-tracking.md` to a state tracking artifact** by:

1. **Relocating** from `doc/product-docs/technical/design/` to `doc/product-docs/state-tracking/permanent/`
2. **Adding status tracking** — a "Workflow Implementation Status" column indicating whether all required features are implemented
3. **Adding an "E2E Status" column** — tracking whether the workflow has been E2E tested
4. **Updating the ID** to follow state tracking conventions (PD-STA-xxx)
5. **Cross-referencing** from feature state files back to the workflows they participate in

### Updated Workflow Table Format

```markdown
| ID | Workflow | User Action | Required Features | Priority | Impl Status | E2E Status |
|----|----------|-------------|-------------------|----------|-------------|------------|
| WF-001 | Single file move → links updated | Move/rename a file | 1.1.1, 2.1.1, 2.2.1 | P1 | All Implemented | TE-E2G-001 |
| WF-004 | Rapid sequential moves → consistency | Multiple quick file moves | 1.1.1, 0.1.2, 2.2.1 | P2 | All Implemented | Not Tested |
```

**Impl Status** is derived from feature-tracking.md — when all required features reach "Implemented", the workflow status auto-updates. This could be validated by `Validate-StateTracking.ps1`.

### Ownership

- **Creation**: Setup tasks (Codebase Feature Discovery or Project Initiation)
- **Updates**: Feature Request Evaluation adds new workflows when new features introduce new user-facing behaviors
- **Consumption**: All phase 02-06 tasks read it; no phase 02-06 task modifies it (read-only downstream)

---

## 3. Knowledge Flow: How Workflow Context Is Used

The key question is not just "add workflow info" but **what does each phase DO with it**. Workflow knowledge flows downstream through increasingly specific channels:

```
user-workflow-tracking.md (source of truth)
    ↓
Feature Request Evaluation: "Feature X participates in WF-001, WF-004"
    ↓
FDD: "Workflow Participation" section — lists workflows + interaction points
    ↓
TDD: References FDD workflow section in "Context"
    ↓
Implementation: Developer reads FDD/TDD → verifies workflow correctness
    ↓
Validation: Groups co-participating features → flags cross-feature effects
    ↓
Bug Triage: Looks up affected workflows → informs priority
    ↓
Bug Fix: Assesses workflow blast radius → regression scope
```

Each phase consumes the workflow context differently — the next sections detail this per phase.

---

## 4. Phase-by-Phase Integration

### Phase 00: Setup (Onboarding)

**Goal**: Ensure the workflow map is completely populated when onboarding an existing project.

| Aspect | Detail |
|---|---|
| **Tasks affected** | Codebase Feature Discovery (PF-TSK-064), Codebase Feature Analysis (PF-TSK-065), Project Initiation (PF-TSK-059) |
| **What changes** | Add a step: "Create `user-workflow-tracking.md` in `state-tracking/permanent/` by identifying all user-facing workflows and mapping them to discovered features" |
| **Ownership** | The onboarding agent creates the initial workflow tracking file during feature discovery |
| **Information flow** | Discovered features → "What does the user actually DO?" → workflow tracking file |
| **Tools** | `user-workflow-tracking.md` (created directly as a permanent state file — no template) |
| **Effort** | ~15 minutes during onboarding: list user actions, map to features |

**For Project Initiation** (new projects): The workflow tracking file starts empty (just header + table structure) and is populated incrementally as features are planned via Feature Request Evaluation.

### Phase 01: Planning

**Goal**: Ensure every new feature is mapped to its workflows at classification time.

| Aspect | Detail |
|---|---|
| **Tasks affected** | Feature Request Evaluation (PF-TSK-067) |
| **What changes** | Add step: "Identify which existing workflows this feature participates in, or whether it introduces a new workflow. Update user-workflow-tracking.md." |
| **Ownership** | The planning agent updates the workflow map |
| **Information flow** | New feature → check against existing workflows → update map if needed |
| **Tools** | `user-workflow-tracking.md` (read + write) |
| **Effort** | ~3 minutes: check workflow table, add/update rows |

### Phase 02: Design

**Goal**: Designers consider which workflows a feature participates in, surfacing cross-feature interaction points.

| Aspect | Detail |
|---|---|
| **Tasks affected** | FDD Creation (PF-TSK-005), TDD Creation (PF-TSK-002) |
| **Tasks NOT affected** | API Design, Database Schema Design, ADR Creation (too focused; workflow context adds noise without value) |
| **What changes in FDD** | Add "Workflow Participation" section after "Feature Overview": list WF-IDs, co-participant features, and cross-feature interaction points |
| **What changes in TDD** | Add a "Workflow Context" field in the "Context" section referencing the FDD's workflow participation |
| **Ownership** | Design agent reads workflow map, writes workflow section in FDD |
| **Information flow** | `user-workflow-tracking.md` → FDD "Workflow Participation" section → TDD "Workflow Context" reference |
| **Usefulness** | Forces the designer to think about feature boundaries. Example: designing parser 2.1.1 while knowing it participates in WF-001/WF-002/WF-005 surfaces "what happens if the updater is writing while the parser is scanning?" |
| **Tools** | `user-workflow-tracking.md` (read), FDD template (add section), TDD template (add field) |
| **Effort** | ~5 minutes per FDD: look up workflows, list them, note interaction points |

**FDD "Workflow Participation" section example:**

```markdown
## Workflow Participation

This feature participates in the following user workflows:

| Workflow | Role in Workflow | Co-Participant Features | Interaction Points |
|----------|-----------------|------------------------|-------------------|
| WF-001 (Single file move) | Parses all files to find references to moved file | 1.1.1 (triggers), 2.2.1 (consumes output) | Parser output feeds directly to updater; must complete before updater starts |
| WF-005 (Multi-format move) | Must handle all registered formats for the moved file | 1.1.1 (triggers), 2.2.1 (consumes output) | All format parsers must return consistent Link objects |
```

### Phase 04: Implementation

**Goal**: Implementers know which workflows their feature participates in and verify they don't break workflow correctness.

| Aspect | Detail |
|---|---|
| **Tasks affected** | All implementation tasks — via a shared guideline in the Development Guide |
| **What changes** | Add "Workflow Awareness" section to [Development Guide](/process-framework/guides/04-implementation/development-guide.md) with 3 checklist questions. Implementation tasks reference it. |
| **Ownership** | Implementation agent reads FDD workflow section |
| **Information flow** | FDD "Workflow Participation" → implementation decisions → feature state file (add "Workflows" field) |
| **Usefulness** | Implementer knows "I'm not just building a parser — I'm building the parser that WF-001 and WF-005 depend on." |
| **Tools** | Development Guide (add section), feature state file template (add "Workflows" field listing WF-IDs) |
| **Effort** | ~3 minutes: read FDD workflow section, verify no workflow-breaking changes, note WF-IDs in state file |

**Development Guide "Workflow Awareness" checklist:**

1. Which workflows does this feature participate in? (check FDD or `user-workflow-tracking.md`)
2. Which other features are co-participants in those workflows? (check `feature-dependencies.md`)
3. Could this implementation change break any workflow-level invariant? (e.g., ordering assumptions, concurrency, error propagation)

### Phase 05: Validation

**Goal**: Validators consider cross-feature workflow effects when features that co-participate in a workflow are validated together.

| Aspect | Detail |
|---|---|
| **Tasks affected** | Validation Preparation (PF-TSK-077) — primary. Validation dimension tasks — secondary (optional subsection). |
| **What changes in Validation Preparation** | Add step: "Cross-reference selected features against user-workflow-tracking.md. If multiple features in a batch co-participate in a workflow, flag this as a workflow cohort and note it in the validation tracking file. Prefer batching co-participating features together." |
| **What changes in validation dimension tasks** | Add optional "Workflow Impact" subsection to validation report template. Used only when the batch contains a workflow cohort. |
| **Ownership** | Validation Preparation agent groups features by workflow; dimension validators note cross-feature effects |
| **Information flow** | `user-workflow-tracking.md` → Validation Preparation (session grouping) → validation tracking (cohort annotation) → validation reports (optional workflow impact subsection) |
| **Tools** | `user-workflow-tracking.md` (read), validation tracking template (add cohort annotation), validation report template (add optional subsection) |
| **Effort** | ~5 minutes in Validation Preparation (cross-reference), ~3 minutes per report if cohort present |

**Concrete Example — Validation of WF-004 (Rapid Sequential Moves):**

Features 1.1.1 (File System Monitoring) and 2.2.1 (Link Updating) are validated in the same Performance & Scalability session.

- **Feature-level finding for 1.1.1**: "Move detection timer has 500ms delay before processing"
- **Feature-level finding for 2.2.1**: "Atomic write takes ~50ms per file"
- **Workflow-level insight (only visible with both)**: "In WF-004 (rapid moves), 500ms timer + 50ms/file write means rapid moves could queue up — if user moves 20 files in 2 seconds, the updater may still be processing the first batch when the second arrives"

This insight is **invisible at the feature level** because each feature's performance is acceptable in isolation. It only emerges when you consider the workflow.

**Tracking in validation state file:**

```markdown
### Session 14: Performance & Scalability — Batch A

| Feature | Score | Notes |
|---------|-------|-------|
| 0.1.1 | 2.5/3.0 | ... |
| 1.1.1 | 2.6/3.0 | ... |

**Workflow Cohort: WF-004 (Rapid Sequential Moves)**
Features 1.1.1 + 2.2.1 co-participate. Workflow-level finding: timer delay + write time could cause queuing under burst load. See report PD-VAL-xxx §Workflow Impact.
```

### Phase 06: Maintenance

**Goal**: Bug fixers and refactorers assess which workflows are affected by changes.

| Aspect | Detail |
|---|---|
| **Tasks affected** | Bug Triage (PF-TSK-041), Bug Fixing (PF-TSK-022), Code Refactoring (PF-TSK-007) |
| **What changes in Bug Triage** | Add step: "Look up the affected feature in user-workflow-tracking.md. List all workflows that include this feature. Record in bug tracking table." |
| **What changes in Bug Fixing** | Add step: "Assess workflow blast radius — which workflows could be affected by this fix? Verify fix doesn't break other workflows." |
| **What changes in Code Refactoring** | Add post-refactoring check: "Verify workflow correctness for all workflows the refactored feature participates in." |
| **What changes in Bug Tracking** | Add **"Workflows"** column to bug tracking tables (after "Related Feature"): comma-separated WF-IDs |
| **Ownership** | Bug triager looks up workflows; bug fixer assesses blast radius |
| **Information flow** | Bug report → affected feature → `user-workflow-tracking.md` lookup → workflows listed in bug tracking |
| **Usefulness** | A bug in updater (2.2.1) affects WF-001, WF-002, WF-004, WF-005, WF-007, WF-008 — 6 of 8 workflows. This context changes priority assessment significantly. |
| **Tools** | `user-workflow-tracking.md` (read), bug tracking template (add column) |
| **Effort** | ~2 minutes per bug: look up feature → find workflows → note in tracking |

**Bug tracking table — updated format:**

```markdown
| ID | Title | Status | Priority | Scope | Reported | Description | Related Feature | Workflows | Dims | Notes |
```

---

## 5. State Tracking File Audit: Workflow Value Assessment

An audit of all state tracking files across the project assessed whether adding WF-IDs would bring value to the tasks that work with each file.

### High Value — Include in Extension

| State Tracking File | Current Location | Would Add Value? | Reasoning |
|---------------------|-----------------|------------------|-----------|
| **bug-tracking.md** | `doc/product-docs/state-tracking/permanent/` | **YES — HIGH** | Bugs impact workflows differently. A bug in 2.2.1 affects 6/8 workflows. Workflow column enables workflow-scoped triage, blast radius assessment, and regression scope. |
| **technical-debt-tracking.md** | `doc/product-docs/state-tracking/permanent/` | **YES — HIGH** | Tech debt affects specific workflows. Knowing WF-IDs enables workflow-scoped debt analysis ("what debt blocks WF-001?") and prioritization by workflow criticality. Refactoring tasks (PF-TSK-007) benefit from knowing which workflows are impacted by the debt being resolved. |
| **Feature state files** | `doc/product-docs/state-tracking/features/` | **YES — MEDIUM** | Add "Workflows" metadata field (list of WF-IDs). Enables implementation and validation tasks to see workflow context without looking up the workflow map separately. |

**Note on feature-tracking.md**: A "Workflows" column was considered but excluded — feature-tracking.md links to feature state files which will have WF-IDs, and the workflow tracking file itself provides the reverse lookup (workflow → features). Adding it to feature-tracking.md would duplicate information available one click away.

### Low/No Value — Exclude from Extension

| State Tracking File | Would Add Value? | Reasoning |
|---------------------|------------------|-----------|
| **e2e-test-tracking.md** | **Already integrated** | Already maps tests to WF-IDs. Reference model for this extension. |
| **test-tracking.md** | **LOW** | Unit/integration tests are feature-scoped. Workflow mapping would be indirect and add noise. E2E tracking already covers workflow-level test tracking. |
| **feature-request-tracking.md** | **LOW** | Requests are classified before workflows are known. Feature Request Evaluation adds workflow context downstream. |
| **architecture-tracking.md** | **LOW** | Architecture is stable; workflow context adds value only during major reviews, not routine tracking. |
| **process-improvement-tracking.md** | **NO** | Process improvements are framework-level, not product-level. WF-IDs not applicable. |
| **Validation tracking files** | **CONDITIONAL** | Handled via cohort annotations in Validation Preparation (§4 Phase 05), not via a permanent column. |
| **Enhancement state files** | **LOW** | Short-lived temporary files. Workflow context flows from the feature state file they reference. |

---

## 6. Automation: Workflow Status Derivation

### Existing Pattern

`Update-FeatureDependencies.ps1` auto-generates `feature-dependencies.md` from feature state files. `Validate-StateTracking.ps1` validates consistency across 6 surfaces. `Update-TestExecutionStatus.ps1` updates e2e-test-tracking.md and feature-tracking.md with E2E test results.

### Proposed Automation

**`Update-WorkflowTracking.ps1`** — a focused script that:
1. Reads `user-workflow-tracking.md`
2. Cross-references each workflow's "Required Features" against `feature-tracking.md` to derive "Impl Status"
3. Cross-references against `e2e-test-tracking.md` to derive "E2E Status"
4. Writes updated status columns back to `user-workflow-tracking.md`

**Integration with existing scripts**: Rather than requiring manual execution as a separate step, this script is **called automatically** by:
- `Update-FeatureImplementationState.ps1` — when a feature's implementation status changes, workflow status may change too
- `Update-TestExecutionStatus.ps1` — when E2E test results are recorded, workflow E2E status may change too

This ensures workflow tracking stays current without adding a manual "remember to run this" step.

**Validation**: Extend `Validate-StateTracking.ps1` with **Surface 7 — "WorkflowTracking"** that validates the derived status columns are consistent with source data (same pattern as Surface 6 for FeatureDeps).

---

## 7. Naming: user-workflow-tracking.md

The renamed file will be `user-workflow-tracking.md` (not `user-workflow-tracking.md`) to match state tracking naming conventions. No template is needed — the empty `user-workflow-tracking.md` file is created directly in `doc/product-docs/state-tracking/permanent/` during setup/onboarding (Project Initiation or Codebase Feature Discovery), following the same pattern as other permanent state files like `bug-tracking.md`.

---

## 8. Guide Updates

When tasks and templates are modified, their associated guides must be updated too. The audit identified these guides:

### Must Update (directly reference modified tasks/templates)

| Guide | Associated Task/Template | What Needs Updating |
|-------|-------------------------|---------------------|
| **FDD Customization Guide** | FDD Creation + fdd-template.md | Add section on "Workflow Participation" — how to fill in the table, what interaction points to look for |
| **TDD Creation Guide** | TDD Creation + tdd-template.md | Add guidance on the "Workflow Context" field — what to reference from FDD |
| **Code Refactoring Usage Guide** | Code Refactoring (PF-TSK-007) | Add subsection on workflow correctness checks post-refactoring |
| **Feature Validation Guide** | Validation Preparation (PF-TSK-077) | Add section on workflow cohort grouping and when to use "Workflow Impact" subsection |
| **Bug Reporting Guide** | Bug Triage (PF-TSK-041) + bug tracking | Add "Workflows Affected" field guidance |
| **Feature Implementation State Tracking Guide** | Feature state files | Add guidance on "Workflows" metadata field |
| **Enhancement State Tracking Customization Guide** | Feature Request Evaluation | Add explanation of workflow mapping during enhancement evaluation |

### Consider Updating (indirect references)

| Guide | Reasoning |
|-------|-----------|
| **Task Transition Guide** | Add note about workflow information flow between tasks (FDD → TDD → implementation → validation → maintenance) |
| **Feature Granularity Guide** | Add note about how workflow participation affects feature scoping |
| **Test Specification Creation Guide** | Add note about referencing workflow context from FDD when creating test specs |

### No Update Needed

| Guide | Reasoning |
|-------|-----------|
| API Specification Creation Guide | API Design task not affected |
| Schema Design Creation Guide | Database Schema Design task not affected |
| Architecture Decision Creation Guide | ADR task not affected |

---

## 9. Summary of All Changes

### Task Modifications (10 tasks)

| Task | Phase | Change | Effort |
|------|-------|--------|--------|
| Codebase Feature Discovery (PF-TSK-064) | 00 | Add step: create initial workflow tracking file | Small |
| Codebase Feature Analysis (PF-TSK-065) | 00 | Add step: validate workflow map completeness | Small |
| Project Initiation (PF-TSK-059) | 00 | Add step: create empty workflow tracking file | Small |
| Feature Request Evaluation (PF-TSK-067) | 01 | Add step: map feature to workflows, update tracking | Small |
| FDD Creation (PF-TSK-005) | 02 | Add "Workflow Participation" section | Medium |
| TDD Creation (PF-TSK-002) | 02 | Add "Workflow Context" field | Small |
| Validation Preparation (PF-TSK-077) | 05 | Add workflow cohort grouping step | Medium |
| Bug Triage (PF-TSK-041) | 06 | Add workflow lookup step | Small |
| Bug Fixing (PF-TSK-022) | 06 | Add workflow blast radius assessment | Small |
| Code Refactoring (PF-TSK-007) | 06 | Add workflow correctness verification | Small |

### State Tracking File Modifications (3 files + 8 feature state files)

| File | Change |
|------|--------|
| **bug-tracking.md** | Add "Workflows" column (after "Related Feature") |
| **technical-debt-tracking.md** | Add "Workflows" column (after "Location") |
| **Feature state files** (all 8) | Add "Workflows" metadata field in Feature Overview |

### Template Modifications (5 templates)

| Template | Change |
|----------|--------|
| FDD Template | Add "Workflow Participation" section |
| TDD Template | Add "Workflow Context" field in Context section |
| Validation Report Template | Add optional "Workflow Impact" subsection |
| Bug Tracking (table format) | Add "Workflows" column |
| Feature State File Template | Add "Workflows" metadata field |

### Guide Modifications (7 must-update + 3 optional)

| Guide | Change |
|-------|--------|
| Development Guide | Add "Workflow Awareness" section with 3-question checklist |
| FDD Customization Guide | Add Workflow Participation guidance |
| TDD Creation Guide | Add Workflow Context field guidance |
| Code Refactoring Usage Guide | Add workflow correctness check subsection |
| Feature Validation Guide | Add workflow cohort grouping guidance |
| Bug Reporting Guide | Add "Workflows Affected" field guidance |
| Feature Implementation State Tracking Guide | Add "Workflows" metadata guidance |
| Task Transition Guide *(optional)* | Add workflow information flow note |
| Feature Granularity Guide *(optional)* | Add workflow-scoping note |
| Test Specification Creation Guide *(optional)* | Add workflow context reference note |

### Artifact Promotions

| Artifact | From | To | New Name |
|----------|------|-----|----------|
| `user-workflow-tracking.md` | `doc/product-docs/technical/design/` | `doc/product-docs/state-tracking/permanent/` | `user-workflow-tracking.md` |

### New Automation

| Script | Purpose |
|--------|---------|
| `Update-WorkflowTracking.ps1` *(new)* | Auto-derive workflow Impl/E2E Status; called by Update-FeatureImplementationState.ps1 and Update-TestExecutionStatus.ps1 |
| `Validate-StateTracking.ps1` Surface 7 *(extend)* | Validate workflow tracking consistency |

### New Artifacts Created

| Type | Count | Items |
|------|-------|-------|
| New tasks | 0 | — |
| New templates | 0 | Empty state file created directly during setup |
| New scripts | 1 | `Update-WorkflowTracking.ps1` (called by existing update scripts) |
| New validation surfaces | 1 | Surface 7 in Validate-StateTracking.ps1 |

---

## 10. Implementation Roadmap

### Session 1: Foundation — Workflow Map Promotion + State Tracking Integration
**Priority**: HIGH — the workflow tracking file must exist as a state artifact before downstream tasks can reference it

- [ ] Relocate `user-workflow-tracking.md` to `doc/product-docs/state-tracking/permanent/user-workflow-tracking.md`
- [ ] Rename to `user-workflow-tracking.md`, update ID to PD-STA-xxx
- [ ] Add "Impl Status" and "E2E Status" columns to workflow table, populate from current state
- [ ] Update all existing references (LinkWatcher handles markdown links; check non-markdown refs)
- [ ] Add "Workflows" column to bug-tracking.md tables
- [ ] Add "Workflows" column to technical-debt-tracking.md
- [ ] Add "Workflows" metadata field to all 8 feature state files
- [ ] Update documentation-map.md for relocated file

### Session 2: Phase 06 Maintenance + Phase 02 Design Integration
**Priority**: HIGH — maintenance tasks get immediate value; design artifacts carry workflow context downstream

- [ ] Modify Bug Triage task (PF-TSK-041): add workflow lookup step
- [ ] Modify Bug Fixing task (PF-TSK-022): add workflow blast radius step
- [ ] Modify Code Refactoring task (PF-TSK-007): add workflow correctness check
- [ ] Update Bug Reporting Guide with "Workflows Affected" guidance
- [ ] Update Code Refactoring Usage Guide with workflow correctness subsection
- [ ] Add "Workflow Participation" section to FDD template
- [ ] Modify FDD Creation task (PF-TSK-005): add workflow participation step
- [ ] Update FDD Customization Guide
- [ ] Add "Workflow Context" field to TDD template
- [ ] Modify TDD Creation task (PF-TSK-002): add workflow context reference
- [ ] Update TDD Creation Guide

### Session 3: Phase 04-05 Implementation + Validation + Automation
**Priority**: MEDIUM — implementation guide, validation preparation, automation script

- [ ] Add "Workflow Awareness" section to Development Guide
- [ ] Update Feature Implementation State Tracking Guide
- [ ] Add optional "Workflow Impact" subsection to validation report template
- [ ] Modify Validation Preparation task (PF-TSK-077): add workflow cohort grouping step
- [ ] Update Feature Validation Guide with cohort grouping guidance
- [ ] Update validation tracking template to support cohort annotations
- [ ] Create `Update-WorkflowTracking.ps1` script (auto-derive Impl/E2E status)
- [ ] Integrate call to `Update-WorkflowTracking.ps1` into `Update-FeatureImplementationState.ps1`
- [ ] Integrate call to `Update-WorkflowTracking.ps1` into `Update-TestExecutionStatus.ps1`
- [ ] Extend `Validate-StateTracking.ps1` with Surface 7 (WorkflowTracking)

### Session 4: Phase 00-01 Setup + Planning + Finalization
**Priority**: MEDIUM — ensures new projects get workflow tracking from the start

- [ ] Modify Codebase Feature Discovery (PF-TSK-064): add workflow tracking creation step
- [ ] Modify Codebase Feature Analysis (PF-TSK-065): add workflow map validation step
- [ ] Modify Project Initiation (PF-TSK-059): add empty workflow tracking creation
- [ ] Modify Feature Request Evaluation (PF-TSK-067): add workflow mapping step
- [ ] Update Enhancement State Tracking Customization Guide
- [ ] Update Task Transition Guide with workflow information flow *(optional)*
- [ ] Update ai-tasks.md if workflow references needed
- [ ] Final documentation-map.md sweep
- [ ] Archive temporary state tracking file
- [ ] Complete feedback form

---

## 11. Success Criteria

### Functional Success Criteria
- [ ] **Workflow tracking is a state artifact**: Lives in `state-tracking/permanent/user-workflow-tracking.md`, has Impl/E2E status columns, is validated by Validate-StateTracking.ps1 Surface 7
- [ ] **Every phase references workflows**: Each phase 00-06 has at least one task that consumes or produces workflow context
- [ ] **No new tasks required**: All integration is through modifications to existing tasks
- [ ] **Workflow context flows downstream**: FDD → TDD → implementation → validation → maintenance chain is unbroken
- [ ] **State tracking files enriched**: bug-tracking, technical-debt-tracking, feature-tracking, and feature state files all have Workflows fields
- [ ] **Automation works**: `Update-WorkflowTracking.ps1` correctly derives status; Surface 7 validates consistency

### Human Collaboration Requirements
- [ ] **Concept Approval**: This document reviewed and approved before implementation
- [ ] **Scope Validation**: Confirmed that lightweight integration (modify existing tasks) is the right approach
- [ ] **Per-Session Review**: Each implementation session reviewed at completion

---

## 12. Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Workflow sections become boilerplate that nobody reads | Keep sections minimal — table format, not prose. FDD section is ~5 lines. |
| Overhead slows down simple features | Workflow lookup is ~2-3 minutes. For Tier 1 features, it's a single sentence in the state file. |
| Validation cohort grouping constrains session planning | Cohort grouping is a preference, not a requirement. Validation Preparation notes cohorts but doesn't force batching. |
| Feature state files become cluttered with WF-IDs | WF-IDs are a single metadata field, not a section. |

---

## Human Review Checklist

**This concept requires human review before implementation can begin.**

### Concept Validation
- [ ] **Extension Necessity**: Confirm the bookend gap is real and worth closing
- [ ] **Scope Appropriateness**: Lightweight integration (modify tasks) vs. heavy infrastructure (new tasks/scripts)
- [ ] **Workflow Map Promotion**: Agree that moving to state-tracking is the right call
- [ ] **Bug Tracking Column**: Agree that "Workflows" column adds value

### Per-Phase Review
- [ ] **Phase 00 (Setup)**: Workflow map creation during onboarding makes sense
- [ ] **Phase 01 (Planning)**: Feature Request Evaluation updates the map
- [ ] **Phase 02 (Design)**: FDD gets full section, TDD gets reference only
- [ ] **Phase 04 (Implementation)**: Development Guide checklist, not per-task changes
- [ ] **Phase 05 (Validation)**: Cohort grouping in Validation Preparation + optional report subsection
- [ ] **Phase 06 (Maintenance)**: Workflow lookup in triage, blast radius in fixing

### Approval Decision
- [ ] **APPROVED**: Concept is approved for implementation
- [ ] **NEEDS REVISION**: Concept needs changes before approval
- [ ] **REJECTED**: Concept is not suitable for framework extension

**Human Reviewer**: ___
**Review Date**: 2026-03-31
**Decision**: ___
**Comments**: ___

---

*This concept document was created using the Framework Extension Concept Template (PF-TEM-032) as part of the Framework Extension Task (PF-TSK-026). Source: PF-IMP-258.*
