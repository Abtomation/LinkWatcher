---
id: PF-PRO-008
type: Document
category: General
version: 3.0
created: 2026-03-18
updated: 2026-03-18
extension_scope: User workflow map, cross-feature test planning, E2E test infrastructure, task/guide updates
extension_name: Scenario-Based E2E Acceptance Testing
extension_description: Introduce user workflow mapping, milestone-triggered E2E test planning, multi-feature attribution, and dedicated E2E tracking — bridging the gap between feature-centric development and cross-feature user workflow validation
---

# Scenario-Based E2E Acceptance Testing — Process Improvement Proposal

## Document Metadata

| Metadata | Value |
|----------|-------|
| Document Type | Process Improvement Proposal |
| Created Date | 2026-03-18 |
| Status | Awaiting Human Review |
| Proposal Name | Scenario-Based E2E Acceptance Testing |
| Scope | User workflow map, cross-feature test planning, E2E infrastructure, task/guide updates |
| Author | AI Agent & Human Partner |

---

## 🎯 Problem Statement

### The feature-centric gap

The process framework is **feature-centric**: features are planned, designed, implemented, and tested individually. This works well for automated tests (unit, integration) but creates a blind spot for **user-facing workflows** that span multiple features.

**Current state:**
- All 4 existing E2E test cases target a single feature (2.1.1 — Link Parsing)
- Zero E2E coverage for features 0.1.1, 0.1.2, 0.1.3, 1.1.1, 2.2.1, 3.1.1
- No artifact maps user workflows to the features that enable them
- No process trigger says "features X, Y, Z are all implemented — now create E2E tests for the workflow they enable"
- No mechanism for E2E test cases to reference multiple features
- test-tracking.md mixes E2E entries into per-feature sections

**The bridge problem:** Even if we define E2E tests, there's no connection between "feature X is done" and "now test workflow W." The framework has no concept of milestones or user workflow slices.

### Two distinct test categories

This proposal identifies two categories of cross-feature testing with different characteristics:

| | Category A: E2E Acceptance Tests | Category B: Cross-Feature Integration Tests |
|---|---|---|
| **What** | Simulate user-visible behavior | Validate internal system behavior across components |
| **Examples** | Move a file → links update; click UI button → state changes | Database consistency after concurrent updates; config propagation across subsystems |
| **Execution** | Running system + human/scripted validation | Automated pytest — no running system needed |
| **Infrastructure** | `test/e2e-acceptance-testing/` with fixtures, workspace | `test/automated/integration/` as regular test files |
| **Process support** | E2E tasks (PF-TSK-069, PF-TSK-070), E2E scripts | Cross-cutting test spec template exists but no process trigger |
| **When created** | After all required features are implemented and tested | Can be identified early, implemented when dependent features exist |

**Category A** is the primary focus of this proposal. **Category B** needs a process trigger added but otherwise uses existing infrastructure (cross-cutting test spec template, `New-TestSpecification.ps1 -CrossCutting`, `test/automated/integration/`).

---

## 🗺️ User Workflow Map — The Missing Artifact

### What it is

A **User Workflow Map** is a product design artifact that answers: *"What does the user actually DO with this software?"* It maps each user-facing workflow to the features required to enable it.

### Where it's stored

**Location**: `doc/product-docs/technical/design/user-workflow-map.md`
**ID**: PD-DES-002
**Sibling to**: `feature-dependencies.md` (PD-DES-001) — which maps technical dependencies between features

One workflow map per project. The file serves as both template (for new projects) and live document. No separate template or creation script needed — the file is created directly during Feature Discovery or Codebase Feature Analysis. The process framework backup preserves it as a reusable starting point.

The workflow map is a **product documentation** artifact — it describes what the user does, not how we develop. But the process framework **references** it as a trigger for cross-feature testing.

### Structure

```markdown
# User Workflow Map

## Workflows

### WF-001: [Workflow Name]
- **Description**: [What the user does and what they expect to happen]
- **User Action**: [The concrete action — e.g., "Move a file in the project directory"]
- **Required Features**: [1.1.1, 2.1.1, 2.2.1]
- **Priority**: [P1-P4 based on user impact]

### WF-002: ...
```

> **Note**: The workflow map contains only the *planning* data — what workflows exist, what features they need, and their priority. *Tracking* data (features ready, E2E spec status, execution status) lives in test-tracking.md's Workflow Milestone Tracking section. This avoids duplication and keeps the workflow map stable while tracking changes frequently.

### Difference from E2E table in test-tracking.md

| Aspect | User Workflow Map | E2E section in test-tracking.md |
|--------|-------------------|--------------------------------|
| **Purpose** | Planning — what user workflows exist | Execution tracking — what E2E tests exist and their status |
| **Content** | Workflow definitions, feature mappings, priorities | Milestone readiness, test case entries, execution dates, pass/fail |
| **Updated when** | New feature discovered, enhancement scoped | E2E test created, executed, or invalidated |
| **Stability** | Changes infrequently (new workflows are rare) | Changes with every test execution |
| **Owned by** | Planning tasks (Feature Discovery, Feature Request Evaluation) | Testing tasks (E2E Test Case Creation, E2E Test Execution) |

The **Workflow Milestone Tracking** rows in test-tracking.md reference workflow IDs from the map and bridge planning to execution.

### Lifecycle — which tasks create, update, and consume it

| Phase | Task | Action | Details |
|-------|------|--------|---------|
| **Create** | Feature Discovery (PF-TSK-013) | Create workflow map | During feature research, ask: "What does the user DO?" Each answer = a workflow candidate. Map workflows to features being discovered. |
| **Create (onboarding)** | Codebase Feature Analysis (PF-TSK-065) | Create workflow map | During dependency analysis (Step 4), user workflows emerge from observed cross-feature interactions. Document as workflow map. |
| **Update** | Feature Request Evaluation (PF-TSK-067) | Check/extend workflow map | When classifying a new feature: does it create a new workflow or extend an existing one? Update the map. When scoping an enhancement: does it affect workflow behavior? Note in map. |
| **Reference** | Test Specification Creation (PF-TSK-012) | Note workflow participation | Each per-feature test spec includes a "Cross-Feature Workflows" section listing which workflows this feature participates in (short list, not full scenarios). |
| **Trigger** | Milestone check | Trigger E2E test spec creation | When all features for a workflow reach "Implemented" status → the workflow is ready for E2E testing. This check happens during Test Specification Creation (for the last feature in a group), or during Release & Deployment preparation. |
| **Consume** | E2E Test Case Creation (PF-TSK-069) | Scenarios from cross-cutting spec | The cross-cutting E2E test spec (created at milestone) defines concrete scenarios. PF-TSK-069 creates test cases from those scenarios. |
| **Gate** | Release & Deployment (PF-TSK-008) | Verify E2E coverage | Pre-release: check workflow map — are all workflows in release scope covered by E2E tests with ✅ Passed status? |

### How workflows are identified

This is domain analysis, not testing. The method depends on the project:

- **LinkWatcher**: User workflows = file system operations that trigger behavior (move file, rename directory, start/stop service, change config)
- **UI application**: User workflows = screens/flows the user navigates (login → dashboard → action → result)
- **API service**: User workflows = API call sequences that accomplish a user goal

**The question to ask**: *"What are the 5-15 things a user does in a typical session with this software?"* Each answer is a workflow candidate.

---

## 📊 Tracking Structure Changes

### Dedicated E2E section in test-tracking.md

Move E2E entries out of per-feature sections into a dedicated top-level section organized by workflow/scenario group:

```markdown
## E2E Acceptance Tests

### Workflow Milestone Tracking

| Workflow | Required Features | Features Ready | E2E Spec | E2E Cases | Status |
|----------|------------------|----------------|----------|-----------|--------|
| WF-001: File move → links updated | 1.1.1, 2.1.1, 2.2.1 | 3/3 | PF-TSP-XXX | TE-E2G-001, TE-E2G-002, TE-E2G-003 | ✅ Covered |
| WF-002: Startup + initial scan | 0.1.1, 0.1.2, 1.1.1, 2.1.1 | 4/4 | — | — | ⬜ Not Created |

### E2E Test Cases

| Test ID | Workflow | Feature IDs | Test Type | Test File/Case | Status | Last Executed | Last Updated | Notes |
|---------|----------|-------------|-----------|----------------|--------|---------------|--------------|-------|
| TE-E2G-001 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Group | [master-test-...] | ✅ Passed | 2026-03-15 | ... | ... |
| TE-E2E-001 | WF-001 | 1.1.1, 2.1.1, 2.2.1 | E2E Case | [test-case.md] | ✅ Passed | 2026-03-15 | ... | ... |
```

**Key changes:**
- E2E entries get a **Workflow** column linking to the workflow map
- E2E entries get a **Feature IDs** column (plural) — all features validated
- Workflow Milestone Tracking sub-section shows readiness at a glance
- Per-feature sections in test-tracking.md contain **only automated tests**

### test-registry.yaml integration

E2E test cases need entries in test-registry.yaml. Currently missing entirely. Add:

```yaml
# E2E Acceptance Tests
TE-E2E-001:
  name: "Regex preserved on file move"
  type: e2e-acceptance
  path: "test/e2e-acceptance-testing/templates/powershell-regex-preservation/TE-E2E-001-regex-preserved-on-file-move/test-case.md"
  featureIds: ["1.1.1", "2.1.1", "2.2.1"]
  group: "TE-E2G-001"
  workflow: "WF-001"
  priority: Critical
  executionMode: scripted  # or manual
  status: Passed
```

### feature-tracking.md

Keep the existing Test Status column lean. E2E status is delegated to test-tracking.md's dedicated section. Feature-tracking.md's Test Status column reflects overall test health (automated + E2E combined), not E2E specifics.

---

## 🔧 Script & Infrastructure Changes

### `New-E2EAcceptanceTestCase.ps1`

| Change | Details |
|--------|---------|
| `-FeatureId` → `-FeatureIds` | Accept comma-separated string (e.g., `"1.1.1,2.1.1,2.2.1"`), split to array internally. Single feature still works. |
| `-Workflow` parameter | Optional. Links test case to workflow in workflow map (e.g., `"WF-001"`). |
| test-registry.yaml | Add E2E entry with `featureIds`, `group`, `workflow`, `executionMode` fields |
| test-tracking.md | Write entry to dedicated E2E section (not per-feature section) |
| test-case.md metadata | `feature_ids` field (array) instead of single `feature_id` |

### `TestTracking.psm1`

| Change | Details |
|--------|---------|
| `Add-TestImplementationEntry` | Support `FeatureIds` array parameter; write to dedicated E2E section |

### `Update-TestExecutionStatus.ps1`

| Change | Details |
|--------|---------|
| Search location | Find E2E entries in dedicated section instead of per-feature sections |
| Feature-tracking update | Update Test Status for all features in the entry's `FeatureIds` list |
| Workflow milestone update | When an E2E entry status changes, update the corresponding Workflow Milestone Tracking row's Status column (e.g., if all cases in a workflow pass → "✅ Covered"; if any fail → "🔴 Failing") |

> **Script integration note**: `Update-TestExecutionStatus.ps1` already updates both test-tracking.md and feature-tracking.md. The workflow milestone update is a natural extension — no new helper script needed. The script reads the E2E entry's Workflow column, finds the corresponding milestone row, and recalculates status from all entries in that workflow.

### `Validate-TestTracking.ps1`

| Change | Details |
|--------|---------|
| E2E section validation | Validate dedicated E2E section entries against disk and test-registry.yaml |
| Workflow milestone validation | Check that milestone tracking matches actual feature status |
| Cross-reference | Verify E2E entries in test-registry.yaml match test-tracking.md |

---

## 📋 Task Definition Updates

### Feature Discovery (PF-TSK-013) — Add workflow identification step

**Where**: After Step 10 (Group related features), before Step 11 (Prioritize)
**Add**: "Identify user-facing workflows — ask 'What does the user DO with this software?' Map each workflow to the features that enable it. Create/update User Workflow Map (`doc/product-docs/technical/design/user-workflow-map.md`)."
**Output**: Add User Workflow Map to task outputs
**State files**: Add `user-workflow-map.md` to state tracking section

### Codebase Feature Analysis (PF-TSK-065) — Add workflow identification step

**Where**: During Step 4 (Document Dependencies), as part of cross-feature dependency analysis
**Add**: "Identify user-facing workflows from observed cross-feature interactions. Create User Workflow Map documenting which features combine to enable each user workflow."
**Output**: Add User Workflow Map to task outputs
**State files**: Add `user-workflow-map.md` to updated files list

### Feature Request Evaluation (PF-TSK-067) — Add workflow map check

**Where**: Step 5a (New Feature Routing) and Step 5b (Enhancement Scoping)
**Add**: "Check User Workflow Map — does this feature create a new user workflow or extend an existing one? Update the map accordingly."
**State files**: Add `user-workflow-map.md` to updated files list

### Test Specification Creation (PF-TSK-012) — Add cross-feature workflow section + terminology fix

**Where**: During Step 9 (Define Test Categories), after classifying test scenarios
**Add**: "Add 'Cross-Feature Workflows' section to the test specification. Reference the User Workflow Map to list which workflows this feature participates in. For each workflow, note whether this is the **last** feature needed — if so, the milestone is reached and a cross-cutting E2E test specification should be created."

**Step 12 terminology update**: Step 12 currently references "Manual Test Requirements" and "manual test scenarios" — this is legacy terminology from before the rename to E2E acceptance testing. Update Step 12 to use E2E terminology:
- "Manual Test Requirements" → "E2E Acceptance Test Requirements"
- "manual test scenarios" → "E2E acceptance test scenarios"
- "manual or both" classification → "e2e or both" classification
- Reference workflow map to ensure cross-feature E2E coverage is planned for scenarios that span workflows

**Milestone trigger**: When the test spec being created is for the last feature in a workflow group, add to the task output: "Milestone reached for workflow WF-XXX — cross-cutting E2E test specification creation is now unblocked."

### E2E Test Case Creation (PF-TSK-069) — Accept cross-cutting spec as input

**Where**: Context Requirements and Step 2 (Review Inputs)
**Add**: Cross-cutting E2E test specification as an input source (alongside per-feature test specs, bug reports, refactoring plans)
**Add**: User Workflow Map as reference context
**Change**: Steps that reference single `FeatureId` → `FeatureIds`

### E2E Test Execution (PF-TSK-070) — Workflow-based execution

**Where**: Step 1 (Identify what needs testing)
**Add**: "Check dedicated E2E section in test-tracking.md. Also check Workflow Milestone Tracking for workflows with 'Not Created' status — these may need E2E test case creation first."

### Release & Deployment (PF-TSK-008) — E2E coverage gate

**Where**: Step 9 (Verify manual test status)
**Extend**: "Check User Workflow Map — are all workflows in the release scope covered by E2E tests? All E2E groups must show ✅ Passed. If any workflow has no E2E coverage, flag as release risk."

---

## 📖 Guide Updates

### Test Infrastructure Guide (PF-GDE-050)

**Add section**: "User Workflow Map and E2E Test Planning"
- Explain the relationship: workflow map → milestone → cross-cutting E2E spec → test cases
- Document the dedicated E2E section structure in test-tracking.md
- Document E2E entry format in test-registry.yaml
- Update the "Source of Truth Files" table to include `user-workflow-map.md`
- Update the "Related Tasks" table with workflow map creation/consumption

**Update**: "E2E Acceptance Testing" section
- Reflect multi-feature attribution in test-case.md metadata
- Document the Workflow Milestone Tracking sub-section

### Test Specification Creation Guide (PF-GDE-028)

**Add section**: "Cross-Feature Workflow Participation"
- How to identify which workflows the feature participates in (reference workflow map)
- How to write the "Cross-Feature Workflows" section in the test spec
- How to recognize a milestone trigger (this is the last feature needed for a workflow)
- What to do when a milestone is reached (flag for cross-cutting E2E spec creation)

### E2E Acceptance Test Case Customization Guide (PF-GDE-049)

**Update**: Script invocation examples
- Show `-FeatureIds "1.1.1,2.1.1,2.2.1"` syntax
- Show `-Workflow "WF-001"` parameter
- Update test-case.md metadata examples with `feature_ids` array

**Add**: "Multi-Feature Test Cases" section
- When to use multi-feature vs. single-feature attribution
- How to determine the feature list (reference workflow map)

### Task Transition Guide (PF-GDE-018)

**Add workflow**: Milestone-triggered E2E testing
```
Per-feature: ... → Test Specification Creation (milestone detected)
                           ↓
              Cross-cutting E2E Test Specification (New-TestSpecification.ps1 -CrossCutting)
                           ↓
              E2E Test Case Creation (PF-TSK-069)
                           ↓
              E2E Test Execution (PF-TSK-070)
```

**Add**: Information flow from User Workflow Map → Test Specification → E2E Spec → Test Cases

---

## 📁 E2E Test Specification Directory

### Current state

All test specifications live in `test/specifications/feature-specs/`. The cross-cutting test specification template already references `test/specifications/cross-cutting-specs/` as the intended directory, but it doesn't exist yet.

### Proposed structure

```
test/specifications/
├── feature-specs/              # Per-feature test specs (existing, unchanged)
│   ├── test-spec-0-1-1-core-architecture.md
│   ├── test-spec-2-1-1-link-parsing-system.md
│   └── ...
└── cross-cutting-specs/        # Cross-feature test specs (new)
    ├── e2e-spec-file-move-workflow.md          # Category A: E2E acceptance scenarios
    ├── e2e-spec-startup-workflow.md            # Category A: E2E acceptance scenarios
    └── integration-spec-database-consistency.md # Category B: Cross-feature integration
```

**Naming convention**:
- `e2e-spec-*` — Category A (E2E acceptance, user-facing)
- `integration-spec-*` — Category B (cross-feature integration, automated)

Both use the cross-cutting test specification template (`PF-TEM-062`) as their base. The `test_type` metadata field distinguishes them (`e2e-acceptance` vs. `cross-feature-integration`).

---

## 📊 Category B: Cross-Feature Integration Tests — Process Gap

### Current state

The infrastructure exists (cross-cutting test spec template, `New-TestSpecification.ps1 -CrossCutting`, `test/automated/integration/`) but **no process trigger** directs anyone to create cross-feature integration test specs.

### Proposed solution

Use the **same milestone mechanism** as Category A:

1. **User Workflow Map** identifies workflows and their required features
2. **Test Specification Creation** notes cross-feature workflows this feature participates in
3. **Milestone reached** → two actions are triggered:
   - **Category A**: Create cross-cutting E2E test spec for user-facing scenarios
   - **Category B**: Create cross-cutting integration test spec for automated backend scenarios (if applicable — not all workflows need backend integration tests beyond what per-feature integration tests cover)
4. **Category B specs** are implemented as automated tests via Integration & Testing (PF-TSK-053)

### Key difference from Category A

Category B integration tests can be **identified earlier** (during per-feature test spec creation as forward-looking notes) and **implemented** as soon as the dependent features exist, without waiting for a full E2E-ready state. The milestone acts as a consolidation trigger, not a hard gate.

### Task updates for Category B

**Test Specification Creation (PF-TSK-012)**: Add "Forward-Looking Integration Scenarios" section where the author can note: "When feature X.Y.Z is also implemented, the following cross-feature integration scenarios should be tested: ..."

**Integration & Testing (PF-TSK-053)**: When implementing tests for a feature, check if there are forward-looking integration scenarios from other feature's test specs that are now unblocked.

---

## 🔧 Implementation Plan

### Multi-session approach

The scope covers 3 layers (content, infrastructure, documentation) that benefit from separate sessions to ensure quality and context management.

### Session 1: Content — Workflow Map + Cross-Cutting E2E Spec

**Focus**: Create the planning artifacts that everything else depends on.

- [ ] Create User Workflow Map for LinkWatcher (`doc/product-docs/technical/design/user-workflow-map.md`)
  - Identify all user-facing workflows (file move, directory move, startup, config change, etc.)
  - Map each workflow to required features
  - Assign priorities based on user impact
- [ ] Create `test/specifications/cross-cutting-specs/` directory
- [ ] Create cross-cutting E2E test specification using `New-TestSpecification.ps1 -CrossCutting`
  - Define scenario groups per workflow
  - Map scenarios to features
  - Prioritize by user impact and automated test coverage gaps
- [ ] Add dedicated E2E section to test-tracking.md
  - Workflow Milestone Tracking sub-section (populated from workflow map)
  - E2E Test Cases sub-section with Workflow and Feature IDs columns
  - Migrate existing E2E-001–004 and E2E-GRP-01–03 entries to dedicated section
- [ ] Add E2E entries to test-registry.yaml for existing test cases
- [ ] Update documentation-map.md: User Workflow Map, cross-cutting E2E spec, cross-cutting-specs directory
- [ ] Run `Validate-StateTracking.ps1`
- [ ] Feedback form

### Session 2: Infrastructure — Script Updates

**Focus**: Update automation scripts for multi-feature attribution and dedicated E2E section.

- [ ] Update `New-E2EAcceptanceTestCase.ps1`:
  - `-FeatureId` → `-FeatureIds` (comma-separated, backward-compatible)
  - Add `-Workflow` parameter (optional)
  - Add test-registry.yaml E2E entry creation
  - Target dedicated E2E section in test-tracking.md instead of per-feature sections
  - Update test-case.md metadata template (`feature_ids` array)
- [ ] Update `TestTracking.psm1`:
  - `Add-TestImplementationEntry` supports `FeatureIds` array parameter
  - New function or parameter to target dedicated E2E section
- [ ] Update `Update-TestExecutionStatus.ps1`:
  - Search dedicated E2E section for entries
  - Update feature-tracking.md Test Status for all features in `FeatureIds` list
  - Update Workflow Milestone Tracking row status
- [ ] Update `Validate-TestTracking.ps1`:
  - Validate dedicated E2E section entries against disk and test-registry.yaml
  - Validate Workflow Milestone Tracking matches actual feature status
  - Cross-reference E2E entries between test-registry.yaml and test-tracking.md
- [ ] Test all scripts with `-WhatIf` or test invocations
- [ ] Run `Validate-StateTracking.ps1`
- [ ] Feedback form

### Session 3: Documentation — Task Definitions + Guides

**Focus**: Update task definitions and guides to integrate the workflow map and E2E changes.

- [ ] Update task definitions (7 tasks):
  - PF-TSK-013 (Feature Discovery) — add workflow identification step
  - PF-TSK-065 (Codebase Feature Analysis) — add workflow identification step
  - PF-TSK-067 (Feature Request Evaluation) — add workflow map check
  - PF-TSK-012 (Test Specification Creation) — add cross-feature workflow section + fix legacy "manual" terminology to "E2E"
  - PF-TSK-069 (E2E Test Case Creation) — accept cross-cutting spec input, multi-feature attribution
  - PF-TSK-070 (E2E Test Execution) — workflow-based execution, dedicated section
  - PF-TSK-008 (Release & Deployment) — E2E coverage gate
- [ ] Update guides (4 guides):
  - PF-GDE-050 (Test Infrastructure Guide) — workflow map section, E2E section structure, test-registry.yaml format
  - PF-GDE-028 (Test Specification Creation Guide) — cross-feature workflow participation
  - PF-GDE-049 (E2E Acceptance Test Case Customization Guide) — multi-feature examples
  - PF-GDE-018 (Task Transition Guide) — milestone-triggered E2E workflow
- [ ] Update ai-tasks.md: add milestone-triggered E2E workflow to Common Workflows
- [ ] Update documentation-map.md if any new entries needed
- [ ] Run `Validate-StateTracking.ps1`
- [ ] Feedback form

### Session dependencies

```
Session 1 (Content)
    ↓ Creates workflow map + E2E spec + tracking structure
Session 2 (Infrastructure)
    ↓ Scripts now support the new structure
Session 3 (Documentation)
    → Task definitions and guides reference the new artifacts and scripts
```

Sessions 2 and 3 both depend on Session 1 but are independent of each other — they could theoretically run in parallel, but sequential execution is safer to avoid merge conflicts in shared files like documentation-map.md.

---

## 🎯 Success Criteria

### Functional

- [ ] User Workflow Map exists with all LinkWatcher user workflows mapped to features
- [ ] Cross-cutting E2E test spec defines scenario groups with feature mappings and priorities
- [ ] Multi-feature attribution works: `New-E2EAcceptanceTestCase.ps1` accepts `-FeatureIds` and `-Workflow`
- [ ] E2E entries in test-registry.yaml with `featureIds`, `group`, `workflow` fields
- [ ] Dedicated E2E tracking section in test-tracking.md with Workflow Milestone Tracking
- [ ] Existing E2E entries migrated to dedicated section
- [ ] `Validate-StateTracking.ps1` reports 0 errors

### Process Integration

- [ ] Task definitions updated with workflow map creation/consumption steps
- [ ] Guides updated with cross-feature workflow guidance
- [ ] doc/process-framework/ai-tasks.md shows milestone-triggered E2E workflow
- [ ] Clear process path from feature completion → milestone detection → E2E test creation
- [ ] Release deployment task includes E2E coverage gate

---

## 📋 Human Review Checklist

**🚨 This proposal requires human review before implementation can begin! 🚨**

### Concept Validation

- [ ] **Two-category separation**: Agree that Category A (user-facing E2E) and Category B (backend cross-feature integration) should be treated separately?
- [ ] **Workflow map as artifact**: Agree with single `user-workflow-map.md` in `doc/product-docs/technical/design/` (no separate template/script)?
- [ ] **Workflow map vs. tracking separation**: Agree that planning data (what workflows exist) stays in the map, while execution data (test status, dates) stays in test-tracking.md?
- [ ] **Milestone trigger mechanism**: Agree that "all features for workflow implemented" triggers E2E spec creation?
- [ ] **Dedicated E2E section**: Agree with restructuring test-tracking.md to separate E2E from per-feature automated tests?
- [ ] **test-registry.yaml integration**: Agree that E2E cases should be in test-registry.yaml?
- [ ] **E2E spec directory**: Agree with `test/specifications/cross-cutting-specs/` for both Category A and B specs?
- [ ] **Legacy terminology fix**: Agree to update "manual" → "E2E" in PF-TSK-012 step 12?

### Task/Guide Integration

- [ ] **Task update scope**: 7 task definitions + 4 guides across Session 3 — acceptable scope?
- [ ] **Onboarding integration**: Workflow map creation during Codebase Feature Analysis — correct insertion point?
- [ ] **Release gate**: E2E coverage check during Release & Deployment — appropriate?

### Implementation Plan

- [ ] **3-session split**: Content → Infrastructure → Documentation — agree with this sequencing?
- [ ] **Session 1 scope**: Workflow map + E2E spec + tracking restructure — achievable in one session?
- [ ] **Session 2 scope**: 4 script updates + validation — achievable in one session?
- [ ] **Session 3 scope**: 7 tasks + 4 guides + doc/process-framework/ai-tasks.md — achievable in one session?

### Approval Decision

- [ ] **APPROVED**: Proposal is approved for implementation
- [ ] **NEEDS REVISION**: Proposal needs changes before approval
- [ ] **REJECTED**: Proposal is not suitable

**Human Reviewer**: [Name]
**Review Date**: 2026-03-18
**Decision**: [APPROVED/NEEDS REVISION/REJECTED]
**Comments**: [Review comments and feedback]

---

*This proposal was developed through collaborative review between AI Agent and Human Partner. Originally created using the Framework Extension Concept Template (PF-TEM-032), revised to Process Improvement scope after review feedback.*
