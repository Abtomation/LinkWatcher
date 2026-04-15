---
id: PF-PRO-020
type: Process Framework
category: Framework Extension Concept
version: 1.0
created: 2026-04-12
updated: 2026-04-12
extension_name: Performance and E2E Test Scoping Workflow
extension_description: New task and status chain for identifying performance and E2E test needs after per-feature validation
extension_scope: New task definition, one new feature-tracking status, workflow integration with Code Review task, ai-tasks.md updates
source: PF-EVR-014 (Framework Evaluation), PF-IMP-492
---

# Performance and E2E Test Scoping Workflow - Framework Extension Concept

## Document Metadata
| Metadata | Value |
|----------|-------|
| Document Type | Framework Extension Concept |
| Created Date | 2026-04-12 |
| Status | Awaiting Human Review |
| Extension Name | Performance and E2E Test Scoping Workflow |
| Extension Scope | New task definition, one new feature-tracking status, workflow integration with Code Review task, ai-tasks.md updates |
| Source | PF-EVR-014 findings C-1, C-2, C-4, C-5, E-1, E-2; PF-IMP-492 |
| Author | AI Agent & Human Partner |

---

## 🔀 Extension Type

**Selected Type**: Hybrid

Creates one new task definition + modifies multiple existing tasks, state files, and workflow documentation.

---

## 🎯 Purpose & Context

**Brief Description**: Closes the workflow gap between Code Review and Completed by adding two mandatory gates — per-feature validation and performance/E2E test scoping — with corresponding statuses in feature-tracking.md.

### Extension Overview

Currently, the feature lifecycle jumps from Code Review directly to `🟢 Completed`. Framework Evaluation PF-EVR-014 identified that:
- No task owns identification of performance test needs (C-1, E-1)
- No task owns identification of E2E test needs for cross-feature dependencies (C-2)
- No status signals "needs test scoping" after implementation (C-4)
- Validation tasks are user-initiated only, not wired into the per-feature lifecycle (C-5)

This extension adds one new gate to the feature status chain:
- **`🔎 Needs Test Scoping`** — after Code Review passes, triggers a new task that evaluates performance and E2E test needs

A new task, **"Performance & E2E Test Scoping"**, is created to own the `🔎 Needs Test Scoping` gate. It uses a decision matrix (migrated from PF-GDE-060 into the new scoping guide) and user-workflow-tracking.md to identify test needs, then outputs entries to performance-test-tracking.md and e2e-test-tracking.md.

Validation (PF-TSK-077 + dimension tasks) remains user-initiated only — batch rounds, pre-release checks, targeted concerns. It is not wired into the per-feature lifecycle.

### Key Distinction from Existing Framework Components

| Existing Component | Purpose | Scope |
|-------------------|---------|-------|
| **Validation Preparation (PF-TSK-077)** | Plans batch validation rounds (user-initiated) | Multi-feature, multi-dimension batch rounds |
| **Performance Test Creation (PF-TSK-084)** | Implements performance tests (assumes someone decided they're needed) | Test creation from specifications |
| **E2E Test Case Creation (PF-TSK-069)** | Creates E2E test cases from specifications | Test case creation from specifications |
| **Performance & E2E Test Scoping** *(This Extension)* | **Identifies WHICH performance and E2E tests are needed for a specific feature** | **Per-feature test needs identification — the missing upstream trigger for PF-TSK-084 and PF-TSK-069** |

## 🔍 When to Use This Extension

This extension is a one-time framework modification. Once implemented, its effects are permanent:

- The new statuses (`🔬 Needs Validation`, `🔎 Needs Test Scoping`) become part of the standard feature lifecycle
- The new task (Performance & E2E Test Scoping) becomes available in ai-tasks.md
- Code Review automatically routes to the new status chain


## 🔎 Existing Project Precedents

| Precedent | Where It Lives | What It Does | How It Relates to This Extension |
|-----------|---------------|--------------|----------------------------------|
| Next-action status model | feature-tracking.md Status Legends | Each status tells the AI agent which task to pick up next (e.g., `📝 Needs TDD` → PF-TSK-015) | **Reuse directly**: The new `🔎 Needs Test Scoping` status follows this exact pattern → new scoping task |
| Performance Testing Guide decision matrix | PF-GDE-060 (migrated to new scoping guide) | Maps code change types to performance test levels (Component/Operation/Scale/Resource) | **Migrate**: Decision matrix moves from PF-GDE-060 to the new scoping guide; the scoping task owns "when to test" |
| E2E milestone trigger | user-workflow-tracking.md | When all features for a workflow reach "Implemented," E2E testing is triggered | **Reuse as input**: The new scoping task checks if completing this feature makes any workflow E2E-ready |
| Design status branching | feature-tracking.md (DB Design → API Design → TDD) | Parallel design tasks are gated by column values, not primary status | **Contrast**: The new statuses are sequential in the primary status chain, not parallel branches |

**Key takeaways**: The project already has the next-action status pattern and the performance/E2E tracking files. The gap is purely in the workflow wiring — no task triggers test scoping after Code Review. This extension fills that gap by adding one status and one task, reusing all existing infrastructure.

## 🔌 Interfaces to Existing Framework

### Task Interfaces

| Existing Task | Interface Type | Description |
|--------------|----------------|-------------|
| Code Review (PF-TSK-005) | Modified by extension | Output status changes from `🟢 Completed` to `🔎 Needs Test Scoping` (when review passes) |
| Performance Test Creation (PF-TSK-084) | Downstream consumer | Triggered by rows added to performance-test-tracking.md by the new scoping task |
| E2E Test Case Creation (PF-TSK-069) | Downstream consumer | Triggered by entries added to e2e-test-tracking.md by the new scoping task |
| Integration and Testing (PF-TSK-053) | Modified by extension | Remove orphaned performance routing reference to PF-TSK-084 (PF-IMP-493) |

### State File Interfaces

| State File | Read / Write / Both | What the Extension Uses or Updates |
|-----------|---------------------|-----------------------------------|
| feature-tracking.md | Both | Read: current feature status, dependencies. Write: new status `🔎 Needs Test Scoping` in Status Legends; update existing feature statuses |
| performance-test-tracking.md | Write | New scoping task adds rows with status `⬜ Specified` for identified performance tests |
| e2e-test-tracking.md | Write | New scoping task adds entries for identified E2E test needs |
| user-workflow-tracking.md | Read | New scoping task reads workflow-to-feature mappings to evaluate E2E milestone readiness |
| feature implementation state files | Read | New scoping task reads to understand what code changed (for decision matrix evaluation) |
| Performance Testing Guide (PF-GDE-060) | Read | New scoping task references for methodology context (4-level system); decision matrix itself lives in the new scoping guide |

### Artifact Interfaces

| Existing Artifact | Relationship | Description |
|------------------|--------------|-------------|
| ai-tasks.md | Updated by extension | Add new task to task registry, update workflow diagrams |
| Task Transition Guide | Updated by extension | Add transitions for new statuses (FROM Needs Validation, FROM Needs Test Scoping) |
| Task Trigger & Output Traceability (PF-INF-002) | Updated by extension | Add new task's trigger/output chain, add new statuses to State File Trigger Index |
| Process Framework Task Registry | Updated by extension | Register new task with automation status and file update patterns |
| PF-documentation-map.md | Updated by extension | Register new task definition, context map |

## 🏗️ Core Process Overview

This describes the process of the **new task** (Performance & E2E Test Scoping), not the extension implementation.

### Phase 1: Context Gathering
1. **Read feature state** - Load the feature's implementation state file to understand what code was changed
2. **Read feature dependencies** - Check feature-dependencies.md for dependent features

### Phase 2: Performance Test Scoping
4. **Consult decision matrix** - Apply the decision matrix (in the scoping guide) against the feature's code changes
5. **Identify performance test needs** - Determine which performance test levels apply (Component/Operation/Scale/Resource)
6. **Add entries to performance-test-tracking.md** - Add rows with status `⬜ Specified` for each identified test, or document "No performance tests needed" with rationale

### Phase 3: E2E Test Scoping
7. **Check user-workflow-tracking.md** - Determine which workflows this feature participates in
8. **Evaluate E2E milestone readiness** - Check if completing this feature makes any workflow E2E-ready (all required features implemented)
9. **Add entries to e2e-test-tracking.md** - For newly E2E-ready workflows, add entries or update existing ones, or document "No new E2E tests needed" with rationale

### Phase 4: Finalization
10. **Update feature status** - Set feature-tracking.md status to `🟢 Completed`
11. **Update user-workflow-tracking.md** - Update workflow implementation status if this feature completion changes it
12. **Complete feedback form** - Standard task completion

## 🔗 Integration with Task-Based Development Principles

### Adherence to Core Principles
- **Task Granularity**: The new scoping task is lightweight — evaluating test needs for a single feature fits within one session
- **State Tracking**: Uses the existing feature-tracking status chain — no new state files needed
- **Artifact Management**: Outputs go to existing tracking files (performance-test-tracking.md, e2e-test-tracking.md) — no new document types
- **Task Handover**: Feature status in feature-tracking.md tells the next agent exactly what to do

### Framework Evolution Approach
- **Incremental Extension**: Inserts two statuses into the existing chain without changing the chain's semantics
- **Consistency Maintenance**: New statuses follow the established `emoji + descriptive name` pattern
- **Integration Focus**: Reuses existing validation infrastructure and tracking files
- **Zero new document types**: No new templates, no new tracking files, no new ID prefixes

## 📊 Detailed Workflow & Artifact Management

### Workflow Definition

#### Input Requirements

- **Feature at `🔎 Needs Test Scoping` status**: The trigger — a feature that has passed Code Review
- **Feature implementation state file**: What code changed, which modules were affected
- **Scoping guide decision matrix**: Rules for which code changes need which performance test levels (migrated from PF-GDE-060)
- **user-workflow-tracking.md**: Workflow-to-feature mappings for E2E milestone evaluation
- **feature-dependencies.md**: To understand which features depend on this one

#### Process Flow

```
Feature at 🔎 Needs Test Scoping
    ↓
Read feature state + dependencies
    ↓
Apply scoping guide decision matrix
    ↓
├─ Performance tests needed → Add rows to performance-test-tracking.md (⬜ Specified)
└─ No performance tests needed → Document rationale in task output
    ↓
Check user-workflow-tracking.md for E2E milestone readiness
    ↓
├─ Workflow now E2E-ready → Add/update entries in e2e-test-tracking.md
└─ Not E2E-ready yet → Document which features are still pending
    ↓
Set feature status → 🟢 Completed
```

### Artifact Dependency Map

#### New Artifacts Created

| Artifact Type | Name | Directory | Purpose | Serves as Input For |
|---------------|------|-----------|---------|-------------------|
| Task Definition | Performance & E2E Test Scoping | process-framework/tasks/03-testing/ | Define the scoping process for identifying test needs per feature | AI agent executing the task |
| Guide | Performance & E2E Test Scoping Guide | process-framework/guides/03-testing/ | Worked examples for applying decision matrix per-feature and evaluating E2E milestone readiness | AI agent executing the task (referenced from task Context Requirements) |
| Context Map | Performance & E2E Test Scoping Map | process-framework/visualization/context-maps/03-testing/ | Visual component relationships for the new task | AI agent understanding task context |

Design checklist:
- [x] **Referenced by**: ai-tasks.md, PF-documentation-map.md, Task Transition Guide, Traceability doc; guide referenced from task Context Requirements
- [x] **Creator**: New-Task.ps1 / New-Guide.ps1 (structure) + manual customization (content)
- [x] **Updater**: Process Improvement task if refinements needed post-deployment

#### Dependencies on Existing Artifacts
| Required Artifact | Source | Usage |
|------------------|--------|-------|
| Performance Testing Guide (PF-GDE-060) | process-framework/guides/03-testing/performance-testing-guide.md | Referenced for methodology context (4-level system); decision matrix migrated to new scoping guide |
| user-workflow-tracking.md (PD-STA-066) | doc/state-tracking/permanent/user-workflow-tracking.md | Workflow-to-feature mappings for E2E milestone evaluation |
| feature-dependencies.md | doc/technical/architecture/feature-dependencies.md | Understanding which features depend on the scoped feature |
| Feature implementation state files | doc/state-tracking/features/*.md | What code changed in the feature |
| performance-test-tracking.md | test/state-tracking/permanent/performance-test-tracking.md | Target for new performance test entries |
| e2e-test-tracking.md | test/state-tracking/permanent/e2e-test-tracking.md | Target for new E2E test entries |

### State Tracking Integration Strategy

#### New Permanent State Files Required

None. All outputs go to existing tracking files.

#### Updates to Existing State Files
- **feature-tracking.md**: Add one new status to Status Legends table; migrate all `🟢 Completed` features to `🔎 Needs Test Scoping`
- **performance-test-tracking.md**: New rows added by the scoping task (status `⬜ Specified`)
- **e2e-test-tracking.md**: New entries added by the scoping task

#### State Update Triggers
- **Code Review passes** → feature status changes to `🔎 Needs Test Scoping`
- **Test scoping completes** → feature status changes to `🟢 Completed`

## 🔄 Modification-Focused Sections

### State Tracking Audit

| State File | Current Purpose | Modification Needed | Change Type |
|-----------|-----------------|---------------------|-------------|
| feature-tracking.md | Track feature development status with next-action statuses | Add `🔎 Needs Test Scoping` to Status Legends; update `🟢 Completed` Next Task; migrate 7 existing Completed features to `🔎 Needs Test Scoping` | Modify schema (Status Legends), modify data (feature rows) |
| feature-tracking.md "Tasks That Update This File" | Lists which tasks update this file | Add new scoping task and validation lifecycle reference | Add entries |

**Cross-reference impact**: Validate-StateTracking.ps1 parses feature-tracking.md statuses — the new status must be added to its allowed status list or the validation will fail. Update-FeatureDependencies.ps1 reads feature-tracking.md but only cares about feature IDs and dependencies, not statuses — no change needed.

### Guide Update Inventory

| File to Update | References To | Update Needed |
|---------------|---------------|---------------|
| Task Transition Guide (PF-GDE-011) | Code Review → Completed transition | Replace with Code Review → Needs Validation → Needs Test Scoping → Completed chain; add new transition sections |
| ai-tasks.md | Feature workflow diagrams, task tables | Add new task to 03-Testing table; update all workflow diagrams (Complex, Simple, Enhancement, etc.) |
| Task Trigger & Output Traceability (PF-INF-002) | Trigger chain table, State File Trigger Index | Add new task row; add two new status triggers; resolve "Performance test needs not signaled" gap |
| Process Framework Task Registry | Task catalog | Register new task with automation status |
| Code Review task (PF-TSK-005) | Output status `🟢 Completed` | Change output to `🔎 Needs Test Scoping` when review passes |
| Integration and Testing (PF-TSK-053) | Orphaned reference to PF-TSK-084 (line ~84) | Remove orphaned reference (PF-IMP-493) |
| Performance Testing Guide (PF-GDE-060) | Decision matrix + 4-level methodology | Remove decision matrix (migrated to new scoping guide); keep methodology, baselines, trends; update any references to the matrix to point to the new guide |
| PF-documentation-map.md | Task/context map listings | Add new task definition and context map entries |

**Discovery method**: Grep for `Completed`, `Code Review`, `PF-TSK-084`, `PF-TSK-005` output references; manual review of traceability document and task transition guide.

### Automation Integration Strategy

| Existing Script | Current Behavior | Required Change | Backward Compatible? |
|----------------|-----------------|-----------------|---------------------|
| Validate-StateTracking.ps1 | Validates feature-tracking statuses against allowed set | Add `🔎 Needs Test Scoping` to allowed status set | Yes — new status is additive |
| Update-FeatureDependencies.ps1 | Reads feature IDs and dependencies from feature-tracking.md | No change needed — doesn't parse status values | N/A |
| Update-BatchFeatureStatus.ps1 | Batch-updates feature statuses | May need to support new status values in ValidateSet | Yes — additive |

**New automation needed**: None. The new scoping task is manual (AI agent applies decision matrix from scoping guide and evaluates tracking files). Future automation could be considered if the scoping process proves repetitive.

---

## 🔧 Implementation Roadmap

### Required Components Analysis

#### New Tasks Required

| Task Name | Purpose | Dependencies |
|-----------|---------|--------------|
| Performance & E2E Test Scoping | Identify per-feature performance and E2E test needs after validation | Requires `🔎 Needs Test Scoping` status in feature-tracking.md |

Design checklist:
- [x] **Trigger**: Feature status = `🔎 Needs Test Scoping` in feature-tracking.md
- [x] **Output storage**: Rows in performance-test-tracking.md and e2e-test-tracking.md; status update in feature-tracking.md
- [x] **Interface to prev/next task**: Previous task (validation) sets `🔎 Needs Test Scoping`; this task sets `🟢 Completed`; downstream tasks (PF-TSK-084, PF-TSK-069) are triggered by their tracking file entries
- [x] **Redundancy check**: Removes ad-hoc "consult Performance Testing Guide" guidance from PF-TSK-053 (orphaned reference); replaces manual judgment with systematic evaluation

#### Supporting Infrastructure Required
| Component Type | Name | Purpose | Priority |
|----------------|------|---------|----------|
| Guide | Performance & E2E Test Scoping Guide | Step-by-step instructions for applying the decision matrix per-feature and evaluating E2E milestone readiness, with worked examples | HIGH |
| Context Map | Performance & E2E Test Scoping Map | Visual component relationships | MEDIUM |

The guide is needed because the task involves judgment-heavy evaluation steps: applying the performance test decision matrix to a specific feature's code changes, and determining E2E milestone readiness from user-workflow-tracking.md. Without a guide, different AI agents will apply these inconsistently.

**Decision matrix migration**: The decision matrix currently lives in the Performance Testing Guide (PF-GDE-060). Since the new scoping task now owns "when to test" decisions, the decision matrix moves to the new guide. PF-GDE-060 retains the "how to test" content: 4-level methodology, baseline management, trend tracking, regression detection. This creates a clean separation: PF-GDE-060 = how to test, new guide = when to test.

#### Integration Points
| Integration Point | Current Framework Component | Integration Method |
|------------------|----------------------------|-------------------|
| Post-Code-Review gate | Code Review (PF-TSK-005) | Modify output status from `🟢 Completed` to `🔬 Needs Validation` |
| Post-Validation gate | Validation dimension tasks | After lifecycle-triggered validation, set `🔎 Needs Test Scoping` |
| Performance test trigger | Performance Test Creation (PF-TSK-084) | New rows in performance-test-tracking.md serve as trigger |
| E2E test trigger | E2E Test Case Creation (PF-TSK-069) | New entries in e2e-test-tracking.md serve as trigger |
| Feature lifecycle | feature-tracking.md Status Legends | Two new statuses added to the chain |

### Multi-Session Implementation Plan

#### Session 1: Status Chain + Task Definition + Guide + Code Review Modification
**Priority**: HIGH - Core functionality; everything else depends on these
- [ ] Add `🔎 Needs Test Scoping` to feature-tracking.md Status Legends
- [ ] Migrate all 7 `🟢 Completed` features to `🔎 Needs Test Scoping`
- [ ] Create new task definition (Performance & E2E Test Scoping) using New-Task.ps1 + extensive customization
- [ ] Create usage guide (Performance & E2E Test Scoping Guide) using New-Guide.ps1 + extensive customization with worked examples; migrate decision matrix from PF-GDE-060 into it
- [ ] Update Performance Testing Guide (PF-GDE-060): remove decision matrix, add cross-reference to new guide
- [ ] Modify Code Review task (PF-TSK-005) output status
- [ ] Create context map for the new task
- [ ] Update Validate-StateTracking.ps1 allowed statuses

#### Session 2: Workflow Documentation + Framework Integration
**Priority**: HIGH - Ensures the new workflow is discoverable and traceable
- [ ] Update ai-tasks.md (task table, all workflow diagrams)
- [ ] Update Task Transition Guide (new transition sections)
- [ ] Update Task Trigger & Output Traceability (new rows, resolve gap)
- [ ] Update Process Framework Task Registry
- [ ] Update PF-documentation-map.md
- [ ] Remove orphaned PF-TSK-084 reference from PF-TSK-053 (PF-IMP-493)
- [ ] Update process-improvement-tracking.md (close PF-IMP-492, PF-IMP-493)
- [ ] Feedback form

## 🎯 Success Criteria

### Functional Success Criteria
- [ ] **Status chain complete**: Feature can progress through `👀 Needs Review → Code Review → 🔎 Needs Test Scoping → Test Scoping → 🟢 Completed`
- [ ] **Test scoping outputs**: New task produces entries in performance-test-tracking.md and/or e2e-test-tracking.md
- [ ] **Retroactive migration**: All 7 previously-Completed features are at `🔎 Needs Test Scoping`
- [ ] **No orphaned references**: PF-TSK-053 performance routing cleaned up

### Human Collaboration Requirements
- [ ] **Concept Approval**: Mandatory human review and approval before implementation
- [ ] **Integration Review**: Verify the Code Review output change is acceptable
- [ ] **Final Validation**: Human confirmation that the new workflow is correct

### Technical & Integration Requirements
- [ ] **Validate-StateTracking.ps1 passes** with the new statuses
- [ ] **ai-tasks.md workflows** are consistent with the new status chain
- [ ] **Task Transition Guide** covers all new transition paths
- [ ] **Traceability document** has no remaining gaps for the new task

## 📝 Next Steps

### Immediate Actions Required
1. **Human Review**: This concept document requires human review and approval
2. **Scope Validation**: Confirm retroactive migration of Completed features
3. **Implementation Authorization**: Human approval to proceed with Session 1

### Implementation Preparation
1. **Create Temporary State Tracking File**: Use `New-TempTaskState.ps1 -Variant FrameworkExtension` for multi-session tracking
2. **Read all files to be modified**: Complete read of Code Review task, Validation Preparation task, ai-tasks.md workflow sections

---

## 📋 Human Review Checklist

**🚨 This concept requires human review before implementation can begin! 🚨**

### Concept Validation
- [ ] **Extension Necessity**: Confirmed — PF-EVR-014 identified a critical workflow gap
- [ ] **Scope Appropriateness**: New task + two statuses + modifications to ~8 existing files
- [ ] **Integration Feasibility**: All integration points use existing infrastructure
- [ ] **Dual-Mode Validation**: Lifecycle-triggered vs. user-initiated distinction is clear

### Technical Review
- [ ] **Workflow Definition**: `Code Review → 🔎 Needs Test Scoping → Test Scoping → 🟢 Completed`
- [ ] **Retroactive Migration**: 7 Completed features → `🔎 Needs Test Scoping`
- [ ] **State Tracking Strategy**: No new state files; outputs to existing tracking files
- [ ] **Implementation Roadmap**: 2 sessions (core + documentation)

### Approval Decision
- [ ] **APPROVED**: Concept is approved for implementation
- [ ] **NEEDS REVISION**: Concept needs changes before approval
- [ ] **REJECTED**: Concept is not suitable for framework extension

**Human Reviewer**:
**Review Date**: 2026-04-12
**Decision**:
**Comments**:

---

*This concept document was created using the Framework Extension Concept Template (PF-TEM-032) as part of the Framework Extension Task (PF-TSK-026). Source: PF-EVR-014, PF-IMP-492.*
