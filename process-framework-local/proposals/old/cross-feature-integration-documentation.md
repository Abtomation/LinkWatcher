---
id: PF-PRO-016
type: Document
category: General
version: 1.0
created: 2026-04-08
updated: 2026-04-08
extension_description: New document type, template, and task ownership for cross-feature workflow integration narratives that explain how multiple components collaborate across feature boundaries
extension_scope: Cross-cutting
extension_name: Cross-Feature Integration Documentation
---

# Cross-Feature Integration Documentation - Framework Extension Concept

## Document Metadata
| Metadata | Value |
|----------|-------|
| Document Type | Framework Extension Concept |
| Created Date | 2026-04-08 |
| Status | Awaiting Human Review |
| Extension Name | Cross-Feature Integration Documentation |
| Extension Scope | Cross-cutting |
| Author | AI Agent & Human Partner |

---

## 🔀 Extension Type

> **Select one** — this determines which template sections to use.

| Type | Use When | Sections to Use |
|------|----------|-----------------|
| **Creation** | Extension adds entirely new artifacts (tasks, templates, guides, scripts) | Use sections as-is; remove Modification-Focused Sections |
| **Modification** | Extension modifies existing artifacts (adds steps to tasks, updates templates, changes guides) | Use Modification-Focused Sections; remove "New Artifacts Created", "New Tasks Required", and multi-session plan |
| **Hybrid** | Extension both creates new artifacts and modifies existing ones | Use all sections; fill in both creation and modification tables |

**Selected Type**: Hybrid

---

## 🎯 Purpose & Context

**Brief Description**: New document type, template, and task ownership for cross-feature workflow integration narratives that explain how multiple components collaborate across feature boundaries

### Extension Overview

The framework currently produces per-feature documentation (TDDs, FDDs, ADRs) that explains each feature in isolation. When multiple features collaborate to deliver a cross-cutting workflow — such as directory move detection combining database structures, filesystem event detection, and link updating — there is no document type that explains how these features interact. The information is scattered across individual TDDs, ADRs, and source code docstrings, requiring readers to manually synthesize a cross-feature understanding.

This extension adds:
1. **A new document type**: "Integration Narrative" — a focused document explaining how 2+ features collaborate in a specific workflow
2. **A template**: Standardized structure for integration narratives
3. **A creation script**: `New-IntegrationNarrative.ps1` for automated creation with ID tracking
4. **Task ownership**: A defined trigger point in the existing workflow for when to create these documents
5. **Tracking**: Integration into existing feature-tracking.md via a new "Integration Docs" column

### Key Distinction from Existing Framework Components

| Existing Component | Purpose | Scope |
|-------------------|---------|-------|
| **TDD** | Technical design of a single feature | One feature's internal architecture |
| **ADR** | Records a specific architectural decision | One decision with context and alternatives |
| **FDD** | Functional specification of a single feature | One feature's behavior and requirements |
| **Cross-cutting Test Specification** | Test coverage spanning multiple features | Testing interactions, not explaining architecture |
| **Integration Narrative** *(This Extension)* | **Explains how 2+ features collaborate in a workflow** | **Cross-feature data flow, callback chains, event routing, and component coordination** |

## 🔍 When to Create an Integration Narrative

An Integration Narrative should be created when:

- **Cross-feature workflow exists**: 2+ features collaborate in a pipeline where Feature A's output feeds Feature B's input (e.g., filesystem events → move detection → link updating)
- **Information is scattered**: Understanding the workflow requires reading 3+ separate documents (TDDs, ADRs, docstrings) and mentally stitching them together
- **Debugging requires cross-feature knowledge**: Bug reports in one feature require understanding how upstream/downstream features behave (e.g., PD-BUG-075 required understanding database structures + detection + updating together)
- **New contributors struggle**: When onboarding to a workflow area, individual feature docs don't convey the full picture

### Example Use Cases
- **Directory Move Detection Workflow**: How `handler.py` routes filesystem events → `MoveDetector` / `DirectoryMoveDetector` detect moves → `ReferenceLookup` finds affected links → `Updater` modifies files. Info currently scattered across TDD-023, TDD-022, ADR-041, and source docstrings.
- **Link Parsing & Update Pipeline**: How parsers extract links → database stores them → updater replaces old paths → rescanner validates. Spans parser TDDs, database TDD, updater TDD.
- **Configuration Loading Chain**: How CLI args → env vars → config file → defaults merge and propagate to all components. Spans multiple feature TDDs with no unified view.

## 🏗️ Workflow for Creating Integration Narratives

### Trigger
An Integration Narrative is created when **all features in a cross-cutting workflow have reached "Implemented" status** in `user-workflow-tracking.md`. This parallels how cross-cutting E2E test specifications are triggered by the same workflow milestones.

**Position in workflow**: Integration Narrative creation happens **before** E2E Acceptance Test Case Creation (PF-TSK-069). The narrative serves as input for E2E test design by providing a verified understanding of how components actually collaborate.

Alternatively, created reactively when a bug fix or maintenance task reveals that cross-feature understanding is required and no integration narrative exists.

### Process (new lightweight task)

The new task will follow this process:

1. **Identify the workflow boundary** — Check `user-workflow-tracking.md` for the workflow. Which features participate? What is the entry event and final output?
2. **Read each feature's TDD and ADR** — Extract the documented cross-feature interaction points (callbacks, shared data structures, event routing)
3. **Verify against actual source code** — Read the implementation to confirm documented interactions match reality. Flag any divergence. This is critical — TDDs may be outdated or incomplete.
4. **Create the Integration Narrative** using `New-IntegrationNarrative.ps1`:
   ```powershell
   New-IntegrationNarrative.ps1 -WorkflowName "Directory Move Detection" -WorkflowId "WF-002" -Description "How filesystem events flow through detection, database, and link updating"
   ```
5. **Customize the template** — Fill in: component interaction diagram, data flow sequence, callback/event chains, configuration propagation, error handling across boundaries
6. **Update user-workflow-tracking.md** — Set the "Integration Doc" column to the PD-INT ID
7. **Update PD-documentation-map.md** — Add narrative to "Integration Narratives" section

## 📋 Expected Outputs

### New Artifacts Created

| Artifact | Type | Directory | Purpose |
|----------|------|-----------|---------|
| Integration Narrative Template | Template | `process-framework/templates/02-design/` | Standardized structure for integration narratives |
| `New-IntegrationNarrative.ps1` | Script | `process-framework/scripts/file-creation/02-design/` | Automated creation with PD-INT ID assignment |
| Integration Narrative Customization Guide | Guide | `process-framework/guides/02-design/` | How to customize the template for specific workflows |

### Modified Existing Artifacts

| Artifact | Modification |
|----------|-------------|
| `doc/PD-id-registry.json` | Add `PD-INT` prefix for Integration Narratives |
| `doc/PD-documentation-map.md` | Add "Integration Narratives" section |
| `doc/state-tracking/permanent/user-workflow-tracking.md` | Add "Integration Doc" column to workflow table (1:1 workflow-to-narrative mapping) |
| `process-framework/tasks/06-maintenance/bug-fixing-task.md` | Add maintenance check: "If fix changes cross-feature interactions, update affected Integration Narrative" |
| `process-framework/tasks/06-maintenance/code-refactoring-task.md` | Add maintenance check: "If refactoring changes component interfaces or data flow, update affected Integration Narrative" |
| `process-framework/tasks/04-implementation/feature-enhancement.md` | Add maintenance check: "If enhancement modifies a feature in a documented workflow, update affected Integration Narrative" |
| `process-framework/tasks/05-validation/documentation-alignment-validation.md` | Extend validation scope: validate Integration Narratives against actual source code |
| `process-framework/ai-tasks.md` | Add new lightweight task to 02-design section + update workflow diagrams to position before E2E test case creation |

### No New Permanent State Files Needed
Integration Narratives are tracked via an "Integration Doc" column in `user-workflow-tracking.md` (not feature-tracking.md — narratives map 1:1 to workflows, not to features) and indexed in `PD-documentation-map.md`. No separate tracking file is warranted — the volume is low (estimated 5-10 across the entire project).

## 🔗 Integration with Task-Based Development Principles

### Artifact Sharing Principle
Integration Narratives are a distinct artifact type because they serve a different purpose than TDDs or ADRs:
- **TDDs** answer "How is feature X designed internally?"
- **ADRs** answer "Why did we make decision Y?"
- **Integration Narratives** answer "How do features X, Y, Z work together in workflow W?"

Future tasks (bug fixing, enhancement, onboarding) need the integration view, not the individual feature design. This aligns with the Separate Artifact Principle from ai-tasks.md.

### Task Ownership

A **new lightweight task** will be created for Integration Narrative creation (via PF-TSK-001 Lightweight Mode). Rationale:

- Integration Narratives operate at the **workflow level**, not the feature level — no existing feature-level task (Implementation Finalization, User Documentation Creation) is the right owner
- The task must **verify against actual source code**, not just trust existing TDDs/ADRs — code may have diverged from design docs
- Integration Narratives should be created **before E2E test case creation** (PF-TSK-069) — understanding how features integrate helps write better E2E tests

**Workflow position**:
```
All workflow features reach "Implemented" in user-workflow-tracking.md
        ↓
Integration Narrative Creation (new task) ← verifies against code
        ↓
E2E Acceptance Test Case Creation (PF-TSK-069) ← uses narrative as input
```

**Maintenance triggers** — existing tasks must check/update Integration Narratives when they change cross-feature behavior:
- **Bug Fixing** (PF-TSK-008) — if fix changes cross-feature interactions, update affected narrative
- **Code Refactoring** (PF-TSK-007) — if refactoring changes component interfaces or data flow, update affected narrative
- **Feature Enhancement** (PF-TSK-056) — if enhancement modifies a feature participating in a documented workflow, update affected narrative
- **Documentation Alignment Validation** (PF-TSK-079) — must validate Integration Narratives against code (new validation dimension)

## 📊 Detailed Workflow & Artifact Management

### Workflow Definition

#### Input Requirements

- **Feature TDDs**: Technical design documents for each participating feature — source of internal architecture details
- **Feature ADRs**: Relevant architectural decisions that affect cross-feature interactions
- **Source code**: Actual implementation to verify documented interactions match reality
- **Feature state files**: To identify which features participate in a workflow and their implementation status

#### Process Flow

```
Feature TDDs + ADRs + Source Code
        ↓
Identify cross-feature interaction points (callbacks, shared data, events)
        ↓
Create Integration Narrative via New-IntegrationNarrative.ps1
        ↓
Customize template: component diagram, data flow, error propagation
        ↓
Link from feature state files + update feature-tracking.md
```

### Artifact Dependency Map

#### New Artifacts Created

| Artifact Type | Name | Directory | Purpose | Serves as Input For |
|---------------|------|-----------|---------|-------------------|
| Template | integration-narrative-template.md | `process-framework/templates/02-design/` | Standardized structure | All integration narrative creation |
| Script | New-IntegrationNarrative.ps1 | `process-framework/scripts/file-creation/02-design/` | Automated creation + ID tracking | All integration narrative creation |
| Guide | integration-narrative-customization-guide.md | `process-framework/guides/02-design/` | How to fill in the template | AI agents creating narratives |

#### Dependencies on Existing Artifacts

| Required Artifact | Source | Usage |
|------------------|--------|-------|
| Feature TDDs | `doc/technical/tdd/` | Extract per-feature architecture to synthesize cross-feature view |
| Feature ADRs | `doc/technical/adr/` | Extract decisions that affect component interactions |
| Feature state files | `doc/state-tracking/temporary/` | Identify participating features and link back |
| PD-id-registry.json | `doc/PD-id-registry.json` | Register PD-INT prefix |

### State Tracking Integration Strategy

#### No New Permanent State Files Required

Integration Narratives are low-volume artifacts (estimated 5-10 total). Tracking via existing mechanisms is sufficient:
- **user-workflow-tracking.md**: New "Integration Doc" column (1:1 mapping — one narrative per workflow)
- **PD-documentation-map.md**: New "Integration Narratives" section lists all narratives

#### Updates to Existing State Files

- **user-workflow-tracking.md**: Add "Integration Doc" column (values: `—` / `PD-INT-XXX`)
- **PD-documentation-map.md**: Add "Integration Narratives" section under Technical Documentation
- **PD-id-registry.json**: Add `PD-INT` prefix with `nextAvailable: 1`

#### State Update Triggers

- **Creation trigger**: When `New-IntegrationNarrative.ps1` runs — auto-updates PD-id-registry.json
- **Auto-update**: Script auto-updates PD-documentation-map.md (Integration Narratives section)
- **Manual update**: Author updates user-workflow-tracking.md "Integration Doc" column after creation
- **Maintenance triggers**: Bug Fixing, Code Refactoring, and Feature Enhancement tasks check if changes affect documented workflows and update narratives accordingly
- **Validation trigger**: Documentation Alignment Validation checks narratives against source code

## 🔄 Modification-Focused Sections

### State Tracking Audit

| State File | Current Purpose | Modification Needed | Change Type |
|-----------|-----------------|---------------------|-------------|
| `doc/state-tracking/permanent/user-workflow-tracking.md` | Map workflows to features, track impl/E2E status | Add "Integration Doc" column to workflow table | Add field |
| `doc/PD-id-registry.json` | Assign IDs to product documentation artifacts | Add `PD-INT` prefix entry | Add section |
| `doc/PD-documentation-map.md` | Index all product documentation | Add "Integration Narratives" section | Add section |

**Cross-reference impact**:
- `user-workflow-tracking.md` is referenced by `Validate-StateTracking.ps1` — need to verify whether the workflow table validation is column-strict or tolerant of extra columns.
- `PD-id-registry.json` is read by `Common-ScriptHelpers.psm1` (`New-StandardProjectDocument`) — adding a new prefix is backward compatible; no script changes needed.

### Guide Update Inventory

| File to Update | References To | Update Needed |
|---------------|---------------|---------------|
| `process-framework/tasks/06-maintenance/bug-fixing-task.md` | Bug fixing process | Add maintenance check: update affected Integration Narrative if fix changes cross-feature interactions |
| `process-framework/tasks/06-maintenance/code-refactoring-task.md` | Code refactoring process | Add maintenance check: update affected Integration Narrative if refactoring changes interfaces/data flow |
| `process-framework/tasks/04-implementation/feature-enhancement.md` | Enhancement execution | Add maintenance check: update affected Integration Narrative if enhancement modifies workflow participant |
| `process-framework/tasks/05-validation/documentation-alignment-validation.md` | Documentation validation | Extend scope: validate Integration Narratives against source code |
| `process-framework/guides/05-validation/documentation-guide.md` | Documentation standards | Mention Integration Narratives as a document type |
| `process-framework/PF-documentation-map.md` | All PF artifacts | Add template, script, guide, and new task entries |
| `process-framework/ai-tasks.md` | Task registry + workflows | Add new task; update workflow diagrams to position before E2E test case creation |
| `doc/state-tracking/permanent/user-workflow-tracking.md` | Workflow tracking | Add "Integration Doc" column; update "How to use" instructions |

**Discovery method**: Grep for task IDs of maintenance/validation tasks; review of user-workflow-tracking.md usage notes; manual review of ai-tasks.md workflow diagrams.

### Automation Integration Strategy

| Existing Script | Current Behavior | Required Change | Backward Compatible? |
|----------------|-----------------|-----------------|---------------------|
| `Validate-StateTracking.ps1` | Validates workflow tracking, feature tracking | May need to accept "Integration Doc" column in user-workflow-tracking.md | Yes — verify if column validation is strict |
| `Common-ScriptHelpers.psm1` | Handles `New-StandardProjectDocument` with ID registry | No change — PD-INT prefix follows existing pattern | Yes |

**New automation needed**: `New-IntegrationNarrative.ps1` — new creation script using `New-StandardProjectDocument` pattern. Parameters: `-WorkflowName`, `-WorkflowId`, `-Description`. Assigns PD-INT IDs, creates file in `doc/technical/integration/`, updates PD-id-registry.json, and auto-updates PD-documentation-map.md (following the pattern of New-Task.ps1 auto-updating PF-documentation-map.md).

---

## 🔧 Implementation Roadmap

### Required Components Analysis

#### No New Tasks Required

Integration Narratives are created within existing tasks (Implementation Finalization, Bug Fixing). No dedicated task definition is needed — this keeps the framework lean for a low-frequency artifact type.

#### Supporting Infrastructure Required

| Component Type | Name | Purpose | Priority |
|----------------|------|---------|----------|
| Template | `integration-narrative-template.md` | Standardized structure for narratives | HIGH |
| Script | `New-IntegrationNarrative.ps1` | Automated creation with PD-INT IDs | HIGH |
| Guide | `integration-narrative-customization-guide.md` | How to customize the template | MEDIUM |
| Directory | `doc/technical/integration/` | Storage for integration narrative files | HIGH |

#### Integration Points

| Integration Point | Current Framework Component | Integration Method |
|------------------|----------------------------|-------------------|
| ID assignment | `PD-id-registry.json` + `Common-ScriptHelpers.psm1` | Add PD-INT prefix — standard `New-StandardProjectDocument` pattern |
| Feature tracking | `feature-tracking.md` | Add "Integration Docs" column |
| Documentation index | `PD-documentation-map.md` | Add "Integration Narratives" section |
| Creation trigger | `implementation-finalization.md` (PF-TSK-055) | Add optional step with trigger criteria |
| Reactive trigger | `bug-fixing-task.md` (PF-TSK-008) | Add guidance note |

### Implementation Plan (4 sessions — PF-TSK-001 Full Mode)

The extension creates new file types (PD-INT), needs new templates/guides/scripts, and requires multiple sessions — Full Mode is required per PF-TSK-001 scope assessment.

**Session 1: Core Task Infrastructure**

1. **Create temporary state tracking file** via `New-TempTaskState.ps1`
2. **Create task definition** via `New-Task.ps1` — "Integration Narrative Creation" in `02-design` phase
3. **Customize task definition** — process steps (identify workflow → read TDDs/ADRs → verify against source code → create narrative → update tracking), triggers, code verification emphasis, position before E2E test case creation
4. **🚨 CHECKPOINT**: Present customized task definition for human review

**Session 2: Document Creation Infrastructure**

5. **Create directory** `doc/technical/integration/`
6. **Update PD-id-registry.json** — add `PD-INT` prefix
7. **Create script** (`New-IntegrationNarrative.ps1`) — `New-StandardProjectDocument` wrapper with PD-INT prefix, `-WorkflowName`, `-WorkflowId`, `-Description` parameters, auto-updates PD-documentation-map.md
8. **Test script** — verify ID assignment, file creation, doc-map update

**Session 3: Template + Guide**

9. **Create template** (`integration-narrative-template.md`) via `New-Template.ps1` — sections: Workflow Overview, Participating Features, Component Interaction Diagram, Data Flow Sequence, Callback/Event Chains, Configuration Propagation, Error Handling Across Boundaries
10. **Create customization guide** (`integration-narrative-customization-guide.md`) via `New-Guide.ps1` — how to fill in each template section, with emphasis on code verification

**Session 4: Framework Integration + Documentation**

11. **Create context map** for the new task
12. **Update user-workflow-tracking.md** — add "Integration Doc" column
13. **Update PD-documentation-map.md** — add Integration Narratives section header (entries auto-added by script)
14. **Update PF-documentation-map.md** — add template, script, guide, task entries
15. **Update ai-tasks.md** — add new task + update workflow diagrams to position before E2E test case creation
16. **Update bug-fixing-task.md** — add maintenance check for Integration Narratives
17. **Update code-refactoring-task.md** — add maintenance check for Integration Narratives
18. **Update feature-enhancement.md** — add maintenance check for Integration Narratives
19. **Update documentation-alignment-validation.md** — extend validation scope to include Integration Narratives
20. **Cross-cutting updates** — task transition guide, process framework task registry, related task references
21. **Validate** — run `Validate-StateTracking.ps1` to confirm no breakage
22. **Move temporary state file** to `process-framework-local/state-tracking/temporary/old`

## 🎯 Success Criteria

### Functional Success Criteria
- [ ] **Task definition usable**: New lightweight task has clear process with code verification emphasis
- [ ] **Template usable**: An AI agent can create a complete Integration Narrative for the directory move detection workflow using only the task, template, and guide
- [ ] **Script works**: `New-IntegrationNarrative.ps1` creates a properly structured file with auto-assigned PD-INT ID
- [ ] **Tracking works**: Created narratives appear in user-workflow-tracking.md and PD-documentation-map.md
- [ ] **Maintenance integrated**: Bug Fixing, Code Refactoring, and Feature Enhancement tasks include narrative maintenance checks
- [ ] **Validation extended**: Documentation Alignment Validation validates narratives against source code
- [ ] **No validation breakage**: `Validate-StateTracking.ps1` passes after all changes

### Human Collaboration Requirements
- [ ] **Concept Approval**: This document reviewed and approved before implementation
- [ ] **Task Definition Review**: New task reviewed before creating supporting infrastructure
- [ ] **Template Review**: Integration Narrative template reviewed for appropriate section structure
- [ ] **Final Validation**: First real narrative (WF-002: directory move detection) reviewed for quality

## 📝 Next Steps

### After Approval
1. **Session 1**: Core task infrastructure — task definition via PF-TSK-001 Full Mode + temp state file
2. **Session 2**: Document creation infrastructure — script, directory, ID prefix
3. **Session 3**: Template + customization guide
4. **Session 4**: Framework integration — context map, modify 8 existing files, cross-cutting updates, validate
5. **First real use**: Create the directory move detection Integration Narrative (WF-002) as the first test of the new task (addresses original IMP-386 gap)

---

## 📋 Human Review Checklist

### Key Questions for Reviewer

1. **Resolved**: Standalone doc type approved
2. **Resolved**: Template sections approved
3. **Resolved**: Directory `doc/technical/integration/` approved
4. **Resolved**: Separate "Integration Doc" column in user-workflow-tracking.md approved
5. **Resolved**: Full Mode (4 sessions) per PF-TSK-001 scope assessment
6. **Resolved**: Script auto-updates PD-documentation-map.md; user-workflow-tracking.md remains manual

### Approval Decision
- [ ] **APPROVED**: Proceed to implementation
- [ ] **NEEDS REVISION**: Concept needs changes
- [ ] **REJECTED**: Not suitable for framework extension

**Human Reviewer**:
**Review Date**: 2026-04-08
**Decision**:
**Comments**:

---

*This concept document was created using the Framework Extension Concept Template (PF-TEM-032) as part of the Framework Extension Task (PF-TSK-026).*
