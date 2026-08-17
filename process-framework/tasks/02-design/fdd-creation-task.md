---
id: PF-TSK-027
type: Process Framework
category: Task Definition
version: 1.9
created: 2025-08-01
updated: 2026-08-05
change_notes: "v1.5 - Check Recommended Skills wiring: fdd-creation craft skill replaces the retired FDD Customization Guide (Craft-as-Skill BL-5 batch 1)"
description: "Create Functional Design Documents for Tier 2+ features"
complexity: medium
use_when: >-
  Create functional specifications for Tier 2/3 features before technical design. Triggers: 'create FDD', 'write functional design', 'document feature X functionally'.
triggers:
  - "create FDD"
  - "write functional design"
  - "document feature X functionally"
automation: full
scripts:
  - ../../scripts/file-creation/02-design/New-FDD.ps1
trigger_status:
  - file: feature-tracking.md
    status: "📋 Needs FDD"
output_status:
  - raw: "`feature-tracking.md` → next design status (`🗄️`/`🔌`/`🎨`/`📜`/`📝` — the first gate the assessment's design-required flags set, in chain order DB → API → UI → Instruction); FDD link inserted into per-feature state file's §4 Documentation Inventory (PF-PRO-002)"
next_tasks:
  - task: database-schema-design-task.md
    condition: "Feature Status is `🗄️ Needs DB Design` — the first design-chain gate"
  - task: api-design-task.md
    condition: "Feature Status is `🔌 Needs API Design`"
  - task: ui-design-task.md
    condition: "Feature Status is `🎨 Needs UI Design`"
  - task: instruction-design-task.md
    condition: "Feature Status is `📜 Needs Instruction Design` — the feature has an instruction dimension"
  - task: tdd-creation-task.md
    condition: "Create Technical Design Document based on functional requirements defined in the FDD"
  - task: ../03-testing/test-specification-creation-task.md
    condition: "Create comprehensive test specifications using FDD acceptance criteria"
  - task: ../04-implementation/feature-implementation-planning-task.md
    condition: "Plan and implement the feature using both FDD and TDD as guidance"
---

# FDD Creation

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Create comprehensive Functional Design Documents (FDD) that capture functional requirements, user interactions, and business logic before technical implementation begins. FDDs bridge the gap between feature requirements and technical design, ensuring clear understanding of what the feature does from a user perspective.

## AI Agent Role

**Role**: Product Analyst
**Mindset**: User-focused, detail-oriented, requirement-driven
**Focus Areas**: User experience flows, business logic, acceptance criteria, edge case identification
**Communication Style**: Ask clarifying questions about user needs and business rules, validate understanding with examples

## Information Flow

> **📋 Ownership & cross-reference rules**: [Information Flow Guide → FDD Creation Task (PF-TSK-027)](../../guides/framework/information-flow-guide.md#fdd-creation-task-pf-tsk-027) — what this task owns, what it references instead, and the cross-reference format.

### Inputs from Other Tasks

- **Tier assessment**: Complexity tier, FDD requirement determination, quality attribute priorities
- **Feature implementation state file**: any design decisions or open threads seeded during evaluation (§Design Decisions, §Open Questions)
- **Feature Discovery Task** (if available): Background research, user needs analysis, competitive analysis
- **Feature Tracking**: Feature ID, name, description, initial requirements

### Outputs to Other Tasks

- **API Design Task**: Functional requirements for API endpoints, user-facing data requirements, functional workflows
- **Database Schema Design Task**: User data requirements, functional relationships, business rules for validation
- **UI/UX Design Task**: User interaction flows, functional workflows, user requirements, acceptance criteria for visual design
- **TDD Creation Task**: Functional requirements, user workflows, business rules, acceptance criteria
- **Test Specification Task**: Acceptance criteria, user workflows, functional validation requirements

## Context Requirements

- **Critical (Must Read):**

  - **Feature Information** - Feature details from [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) including ID, name, description, and tier assessment
  - **Tier assessment** - Complexity evaluation and FDD requirement determination from the tier assessment (produced via [Feature Request Evaluation](../01-planning/feature-request-evaluation.md))
  - **Feature implementation state file** (`doc/state-tracking/features/<id>-implementation-state.md`) - read its §Design Decisions and §Open Questions for any design context seeded during evaluation, so decisions made there carry into the FDD
  - **Human Input on Feature Behavior** - Direct consultation with human partner about how the feature should work from user perspective

- **Important (Load If Space):**

  - [`fdd-creation` craft skill](../../../.claude/skills/fdd-creation/SKILL.md) — the customization craft (requirement-prefix convention, granularity decisions, separation of concerns), activated in Preparation Step 1 (Check Recommended Skills). Replaces the former procedural customization guide and **drives the requirement authoring in Execution.**
  - [FDD Template](../../templates/02-design/fdd-template.md) - Template structure for creating FDD documents
  - [Feature Discovery Task](../01-planning/feature-discovery-task.md) - Background research and analysis if available
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Any existing user stories or requirements documentation

- **Reference Only (Access When Needed):**
  - [PD ID Registry](../../PF-id-registry.json) - For FDD ID assignment and directory mapping

## Process

> **⚠️ MANDATORY: Use the ../../scripts/file-creation/02-design/New-FDD.ps1 automation script for document creation.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `fdd-creation-task`. If the `fdd-creation` craft skill is available in the session, activate it — it owns the **customization craft** this task delegates to (how to fill the FDD well). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/fdd-creation/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The customization craft is unavailable for this run only if the skill file itself is absent (the retired procedural customization guide has no successor).
2. **Identify Target Feature**: Locate the feature in [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) and verify it requires FDD creation
3. **Review the tier assessment**: Confirm the feature is Tier 2 or Tier 3, or has specific FDD triggers (complex interactions, business rules, etc.)
4. **Gather Existing Information**: Collect any available feature discovery results, user stories, or requirements documentation
5. **🚨 CHECKPOINT**: Present feature context, tier assessment results, and existing information to human partner for approval before proceeding

### Execution

6. **🚨 MANDATORY: Consult Human Partner**: Focus consultation on high-level requirements and business context
   - **Human Responsibilities**: High-level user workflow, business value, and key business rules
   - **AI Responsibilities**: Detailed functional specifications, edge cases, acceptance criteria, and technical integration
   - Request overall user experience flow and primary business objectives
   - Ask about critical business constraints and validation rules
   - Clarify success criteria from business perspective
7. **Create FDD Document**: Use the automation script to generate the FDD structure
   ```powershell
   # Run the FDD creation script
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-FDD.ps1 -FeatureId [Feature-ID] -FeatureName "Feature Name Here"
   ```
   > **Note**: Replace `[Feature-ID]` with the feature ID (e.g., 6.4.1), and `"Feature Name Here"` with your feature name.
   >
   > **Retrospective mode** (`-Retrospective`): When documenting an **already-implemented** feature as-built (the [Retrospective Documentation Creation task](../00-setup/retrospective-documentation-creation.md) does this during onboarding), add `-Retrospective` to scaffold from the as-built sibling template — forward-planning scaffolding pre-stripped, the "Related Documentation" block collapsed to a flat cross-reference list, and checklists/closing note reframed for as-built documentation. Omit it for forward design of a new feature.
8. **Develop Detailed Functional Requirements**: Using human input as foundation, create comprehensive specifications with Feature ID prefixes (the `fdd-creation` craft skill, activated in Preparation Step 1, carries the prefix convention and granularity decision points):
   - Core functionality requirements ([Feature-ID]-FR-1, [Feature-ID]-FR-2, etc.)
   - User interaction flows ([Feature-ID]-UI-1, [Feature-ID]-UI-2, etc.)
   - Business rules and validation logic ([Feature-ID]-BR-1, [Feature-ID]-BR-2, etc.)
9. **Create Detailed User Experience Flow**: Expand human-provided workflow into complete user journey with decision points and alternative paths
10. **Document Workflow Participation**: Look up the feature in [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md) and populate the FDD's "Workflow Participation" section with the workflows this feature participates in and its role in each. If the feature introduces a new user workflow, note it for addition to the tracking file. When the finalized functional model changes how an existing workflow behaves, reconcile that workflow's User Action and Workflow Details prose in the tracking file so it matches the FDD.
11. **Define Comprehensive Acceptance Criteria**: Create testable, measurable acceptance criteria based on functional requirements
12. **Identify Edge Cases and Error Handling**: Document edge cases and error handling scenarios with expected behaviors
13. **Map Dependencies**: Identify functional and technical dependencies from other features or systems
14. **🚨 CHECKPOINT**: Present draft FDD with functional requirements, workflow participation, acceptance criteria, and edge cases to human partner for review and approval

### Finalization

15. **Validate Completeness**: Review FDD against the validation checklist in the template
16. **Verify Automated Updates**: The ../../scripts/file-creation/02-design/New-FDD.ps1 script automatically updates feature tracking - verify the updates were applied correctly
17. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Functional Design Document (FDD)** - Complete FDD document in `/doc/functional-design/fdds/fdd-[feature-id]-[feature-name].md` with assigned FDD ID
- **Updated Feature Tracking** - Feature Status in [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) updated based on assessment-time design-required flags (recorded in the assessment document's Design Requirements Evaluation section, per PF-PRO-002 / PF-IMP-760):
  - DB design required → status set to `🗄️ Needs DB Design`
  - DB design not required, API design required → status set to `🔌 Needs API Design`
  - Neither, UI design required → status set to `🎨 Needs UI Design`
  - None of those, instruction design required → status set to `📜 Needs Instruction Design`
  - No design dimension flagged → status set to `📝 Needs TDD`
- **State File Documentation Inventory** - FDD link inserted into the per-feature state file's §4 Documentation Inventory by `Add-StateFileDocumentationInventoryRow`

## Example Output

A completed FDD should look like this (abbreviated):

```markdown
# FDD: User Profile Management (2.3.1)

## Feature Overview
Allows users to view and edit their profile information including
display name, avatar, and notification preferences.

## Functional Requirements
### Core Functionality
- 2-3-1-FR-1: Users can view their current profile data
- 2-3-1-FR-2: Users can update display name (3-50 characters, alphanumeric + spaces)
- 2-3-1-FR-3: Users can upload avatar images (PNG/JPG, max 2MB, auto-resized to 256x256)

### Business Rules
- 2-3-1-BR-1: Display name changes limited to once per 24 hours
- 2-3-1-BR-2: Avatar must pass content moderation before becoming visible

## Acceptance Criteria
- [ ] 2-3-1-AC-1: User can view all profile fields on a single page (verifies 2-3-1-FR-1)
- [ ] 2-3-1-AC-2: Validation errors display inline next to the relevant field (verifies 2-3-1-FR-2)
- [ ] 2-3-1-AC-3: Profile changes are saved atomically, all-or-nothing (verifies 2-3-1-FR-2, 2-3-1-FR-3)
```

## State Tracking

The following state files are automatically updated by the ../../scripts/file-creation/02-design/New-FDD.ps1 script:

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Automatically updated with next design Status (`🗄️ Needs DB Design` / `🔌 Needs API Design` / `🎨 Needs UI Design` / `📜 Needs Instruction Design` / `📝 Needs TDD`, gated by the tier-assessment design-required flags, in that chain order). The FDD document link itself is inserted into the per-feature state file's §4 Documentation Inventory by `Add-StateFileDocumentationInventoryRow` (PF-PRO-002 / PF-IMP-760).

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] FDD document created with proper ID and complete content in `/doc/functional-design/fdds`
  - [ ] All FDD template sections filled with meaningful content (no placeholders remaining)
  - [ ] Functional requirements, user interactions, and business rules clearly documented
  - [ ] Acceptance criteria are testable and measurable
  - [ ] Edge cases and error handling scenarios identified
- [ ] **Verify Automated Updates**: Ensure the ../../scripts/file-creation/02-design/New-FDD.ps1 script successfully updated state tracking files
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Status automatically updated to next design status; FDD link inserted into the per-feature state file's §4 Documentation Inventory
- [ ] **Human Consultation Completed**: Confirmed that human partner was consulted about feature behavior and requirements
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-027`, context "FDD Creation".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `fdd-[feature-id]-[feature-name].md` | `New-FDD.ps1` | Functional design document with requirements and specifications |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | `New-FDD.ps1` | Status: `📋 Needs FDD` → the first design-chain gate the tier assessment flagged (`🗄️ Needs DB Design` / `🔌 Needs API Design` / `🎨 Needs UI Design` / `📜 Needs Instruction Design`), or `📝 Needs TDD` when none is flagged<br/>• Add FDD creation date to Notes |
| **Updates** | Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`) | `New-FDD.ps1` (via `Add-StateFileDocumentationInventoryRow`) | Insert FDD document row into §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760) |

## Next Tasks

- [TDD Creation Task](tdd-creation-task.md) - Create Technical Design Document based on functional requirements defined in the FDD
- [Test Specification Creation Task](../03-testing/test-specification-creation-task.md) - Create comprehensive test specifications using FDD acceptance criteria
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - Plan and implement the feature using both FDD and TDD as guidance

<!-- merged from transition-registry entry: FDD Creation -->
### Prerequisites for Transition

- [ ] FDD document created using New-FDD.ps1 script
- [ ] Functional requirements documented with user perspective
- [ ] User flows and acceptance criteria defined
- [ ] FDD linked in Feature Tracking
- [ ] Human consultation completed for feature behavior

### Next Task Selection

```
Does the feature impact system architecture or introduce new patterns?
├─ Yes → System Architecture Review
│   └─ Reason: Architectural analysis needed before technical design
└─ No → Check Design Requirements → [Database Schema Design if "Yes"] → [API Design if "Yes"] → [UI Design if "Yes"] → TDD Creation
    └─ Reason: Proceed directly to targeted design work based on requirements evaluation
```

### Preparation for Next Task

1. Review functional requirements to understand user needs
2. Ensure user flows are clear and complete
3. Verify acceptance criteria are testable and specific
4. Prepare functional context for technical design decisions

## Related Resources

- [FDD Template](../../templates/02-design/fdd-template.md) - Template for creating Functional Design Documents
- [`fdd-creation` craft skill](../../../.claude/skills/fdd-creation/SKILL.md) - the FDD customization craft (replaces the retired customization guide); activated by the Check Recommended Skills step
- [Feature Request Evaluation](../01-planning/feature-request-evaluation.md) - Determines (via embedded tier assessment) whether an FDD is required
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Central tracking document for all features
