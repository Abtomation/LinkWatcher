---
id: PF-TSK-015
type: Process Framework
category: Task Definition
version: 1.12
created: 2023-06-15
updated: 2026-08-04
change_notes: "v1.11 - PF-IMP-1554: Step 10 makes the first-pass empty Dimension Profile explicit (standard tier depth applies)"
description: "Create Technical Design Documents"
complexity: medium
use_when: >-
  Complex feature needs technical design. Triggers: 'create TDD', 'write technical design', 'design feature X technically'.
triggers:
  - "create TDD"
  - "write technical design"
  - "design feature X technically"
automation: full
scripts:
  - ../../scripts/file-creation/02-design/New-TDD.ps1
trigger_status:
  - file: feature-tracking.md
    status: "📝 Needs TDD"
output_status:
  - raw: "`feature-tracking.md` → `🧪 Needs Test Spec`; TDD link inserted into per-feature state file's §4 Documentation Inventory (PF-PRO-002)"
next_tasks:
  - task: ../03-testing/test-specification-creation-task.md
    condition: "Create comprehensive test specifications from the TDD for Test-First Development"
  - task: ../04-implementation/feature-implementation-planning-task.md
    condition: "Uses the TDD and test specifications to plan and implement the feature"
  - task: ../06-maintenance/code-review-task.md
    condition: "Uses the TDD as a reference for evaluating implementation"
---

# Technical Design Document (TDD) Creation

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Create a detailed technical design document for a feature that provides a comprehensive blueprint for implementation, ensuring architectural consistency and facilitating effective collaboration between developers. The document's depth and detail are adjusted based on the feature's complexity tier, ensuring sufficient context while minimizing documentation overhead for simpler features.

## AI Agent Role

**Role**: Technical Lead
**Mindset**: Design-first thinking, risk-aware, collaborative
**Focus Areas**: Technical specifications, risk mitigation, team coordination, design validation
**Communication Style**: Present design options with pros/cons and risk assessment, ask about technical constraints and requirements

## Information Flow

> **📋 Ownership & cross-reference rules**: [Information Flow Guide → TDD Creation Task (PF-TSK-015)](../../guides/framework/information-flow-guide.md#tdd-creation-task-pf-tsk-015) — what this task owns, what it references instead, and the cross-reference format.

### Inputs from Other Tasks

- **FDD Creation Task** (Tier 2+): Functional requirements, user workflows, business rules, acceptance criteria
- **Tier assessment**: Complexity tier, documentation requirements, quality attribute priorities
- **API Design Task**: API contracts, endpoint specifications, data access patterns
- **Database Schema Design Task**: Data model, relationships, constraints, security policies
- **[UI Design Task](ui-design-task.md)** (PF-TSK-090, when applicable): Visual specifications, component details, accessibility requirements, platform adaptations

### Outputs to Other Tasks

- **Test Specification Task**: Technical architecture, component interactions, quality attribute requirements, testing considerations
- **Feature Implementation Task**: Implementation blueprint, component design, technical decisions, code structure guidance


## Context Requirements

- **Critical (Must Read):**

  - **Functional Design Document (FDD)** - For Tier 2+ features, the FDD created in the previous step containing functional requirements and user flows
  - **TDD Templates** - Tier-specific templates for technical design documents:
  - [T1 Template](../../templates/02-design/tdd-t1-template.md) - For Tier 1 (simple) features
  - [T2 Template](../../templates/02-design/tdd-t2-template.md) - For Tier 2 (moderate) features
  - [T3 Template](../../templates/02-design/tdd-t3-template.md) - For Tier 3 (complex) features
  - **Tier assessment** - The tier assessment for the selected feature (locate via [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md))

- **Important (Load If Space):**

  - [`tdd-creation` craft skill](../../../.claude/skills/tdd-creation/SKILL.md) — the customization craft (tier selection, dimension-informed quality-attribute depth, handoff-notes quality, separation of concerns), activated in Preparation Step 1 (Check Recommended Skills). Replaces the former procedural creation guide and **informs the tier choice and content depth throughout Execution.**
  - [Technical Design Documents](../../../doc/technical/tdd) - Existing design documents for reference

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - To identify features that have been assessed but need TDDs

## Process

> **⚠️ MANDATORY: Use the [../../scripts/file-creation/02-design/New-TDD.ps1](../../scripts/file-creation/02-design/New-TDD.ps1) script for consistency across all design documents.**
>
> **⚠️ MANDATORY: Request explicit feedback from the human partner during the TDD creation process.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `tdd-creation-task`. If the `tdd-creation` craft skill is available in the session, activate it — it owns the **customization craft** this task delegates to (tier selection, dimension-informed depth, content quality per tier). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/tdd-creation/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The customization craft is unavailable for this run only if the skill file itself is absent (the retired procedural creation guide has no successor).
2. Review the feature's tier assessment document to understand its complexity tier (🔵/🟠/🔴)
3. **For Tier 2+ features**: Review the Functional Design Document (FDD) to understand functional requirements, user flows, and acceptance criteria
4. Identify the appropriate documentation template based on the tier (the `tdd-creation` craft skill carries the tier-selection criteria and structural differences):
   - **Tier 1 🔵**: Use the lightweight planning template (creates tdd-[ID]-[name]-t1.md)
   - **Tier 2 🟠**: Use the standard TDD template (creates tdd-[ID]-[name]-t2.md)
   - **Tier 3 🔴**: Use the comprehensive TDD template (creates tdd-[ID]-[name]-t3.md)
5. Review any existing documentation related to the feature
6. Gather necessary technical context to understand the feature's requirements

### Quality Attribute Analysis (MANDATORY)

7. **Analyze System Quality Attributes**: Identify applicable quality attributes for this feature:
   - System-wide performance, security, reliability, and usability requirements
   - Feature category-specific requirements that apply to this feature
   - Cross-cutting constraints that affect implementation
8. **Map Quality Attributes to Feature**: Identify which quality attributes are most relevant to this specific feature:
   - Performance requirements (response times, throughput, resource usage)
   - Security requirements (authentication, authorization, data protection)
   - Reliability requirements (error handling, recovery, monitoring)
   - Usability requirements (user experience, accessibility)
9. **Set Feature-Specific Quality Targets**: Adapt system-wide quality requirements to this feature's specific context:
   - Define measurable targets based on system-wide requirements
   - Consider feature complexity and user impact
   - Document any quality attribute trade-offs or constraints
10. **Apply Dimension-Informed Quality Attribute Depth** (D10): The Dimension Profile is populated downstream, at Feature Implementation Planning — on the first-pass workflow the section is still empty here and standard tier depth applies. When it is populated (a re-planned or re-entered feature), use it to guide quality attribute subsection depth in the TDD — the `tdd-creation` craft skill carries the depth matrix and dimension→subsection mapping tables; see the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md) for dimension definitions
11. **🚨 CHECKPOINT**: Present quality attribute analysis, dimension-informed depth decisions, feature-specific targets, and proposed technical approach to human partner for approval

### Execution

12. Create the appropriate document using the automation script:

   ```powershell
   # Run the script with the feature information
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-TDD.ps1 -FeatureId "[Assessment ID]" -FeatureName "[Feature Name]" -Tier "[1, 2, or 3]"
   ```

   **Pass `-Medium` when the feature is not pure code.** Read the feature's declared medium from its tier assessment (`## Implementation Medium`) or the `**Medium**` scalar in its implementation state file §2 — declared, never inferred. `code` is the default and needs no flag.

   ```powershell
   # Pure-instruction feature: selects the tier-agnostic instruction terminal instead of the code TDD
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-TDD.ps1 -FeatureId "[Assessment ID]" -FeatureName "[Feature Name]" -Tier "[1, 2, or 3]" -Medium instruction
   ```

   A **mixed** feature keeps the code TDD by design (`-Medium mixed`) — fill its Instruction Design Reference section so the terminal document integrates both dimensions. A **pure-instruction** feature must never receive the Models/Services/Repositories structure of the code TDD.

   The script will:

   - Generate the appropriate template based on the tier (1, 2, or 3), or the instruction terminal under `-Medium instruction`
   - Include the feature ID and name in the document
   - Create a file with standardized naming: tdd-[FeatureID]-[feature-name]-t[Tier].md
   - Store the file in the /tdd subdirectory
   - Ensure the AI Agent Session Handoff Notes section is included

13. **Populate Workflow Context**: Fill in the "Workflow Context" section by referencing the FDD's Workflow Participation section (if available) or looking up the feature in [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md). List the WF-IDs the feature participates in.
14. Complete the document with appropriate detail for the tier, **including quality attribute requirements and implementation** (apply dimension-informed depth from step 10):

- **Tier 1 🔵**: Key implementation approach, affected components, technical constraints, and relevant quality attribute considerations
- **Tier 2 🟠**: Basic architecture, component interactions, data model, API details, and quality attribute requirements with implementation approach
- **Tier 3 🔴**: Comprehensive design including security, performance, edge cases, testing strategy, and detailed quality attribute implementation with measurement approach

15. **MANDATORY: Include Quality Attribute Sections** in all TDDs:

- **Quality Attribute Requirements**: Feature-specific quality targets based on system-wide requirements
- **Quality Attribute Implementation**: How the technical design achieves quality targets
- **Quality Measurement**: How quality attributes will be monitored and validated

16. Include specific "AI Agent Session Handoff Notes" section in all documents with:

- Summary of decisions made in this session
- Clear next steps for subsequent AI sessions
- Explicit list of files that will need to be modified
- Any specific implementation challenges to be aware of

17. Ensure the documentation includes appropriate diagrams or visual aids:

- **Tier 1 🔵**: Simple component interaction diagram (if needed)
- **Tier 2 🟠**: Data flow diagrams and component architecture
- **Tier 3 🔴**: Comprehensive architecture, sequence diagrams, and state charts

18. **🚨 CRITICAL**: Actively request feedback from your human partner during TDD creation:

- Ask specific questions about technical approach
- Confirm appropriate level of detail for the feature's complexity tier
- Validate security and architectural decisions
- **NEW**: Validate quality attribute requirements and implementation approach
19. **🚨 CHECKPOINT**: Present completed TDD draft including workflow context, dimension-informed quality attribute sections, diagrams, and handoff notes to human partner for review and approval

### Finalization

20. Review the document for completeness, clarity, and appropriateness for the complexity tier, **ensuring quality attribute sections are complete and dimension-informed depth is applied**
21. **Verify Automated Updates**: The [../../scripts/file-creation/02-design/New-TDD.ps1](../../scripts/file-creation/02-design/New-TDD.ps1) script automatically updates feature tracking - verify the updates were applied correctly
22. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Technical Design Document** - New document in `/doc/technical/tdd/tdd-[assessment-id]-[feature-name]-t[tier].md`
- **Updated Feature Tracking** - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) document updated with TDD status
- **AI Session Handoff Notes** - Explicit guidance for the next AI agent session

## Example Output

A completed TDD should look like this (abbreviated, Tier 2 example):

```markdown
# TDD: User Profile Management (2.3.1) — Tier 2

## 1. Overview
### 1.1 Purpose
Technical design for profile CRUD operations, covering data model,
API integration, and state management.

## 2. Key Requirements
| ID | Requirement | Source |
|----|-------------|--------|
| KR-01 | Profile updates persist within 500ms | FDD FR-02 |
| KR-02 | Avatar upload supports concurrent requests | FDD FR-03 |

## 4. Technical Design
### 4.1 Data Models
class UserProfile:
    user_id: UUID (PK, FK -> auth.users)
    display_name: str (3-50 chars, validated)
    avatar_url: Optional[str]
    updated_at: datetime (auto-set on write)

### 4.2 State Management
- Profile state cached in memory after first load
- Invalidated on successful PUT /api/profile
- Optimistic UI update with rollback on 4xx/5xx
```

## State Tracking

The following state files are automatically updated by the [../../scripts/file-creation/02-design/New-TDD.ps1](../../scripts/file-creation/02-design/New-TDD.ps1) script:

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Automatically updated with Status changed from "📝 Needs TDD" to "🧪 Needs Test Spec"
- Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`) - TDD document link inserted into §4 Documentation Inventory by `Add-StateFileDocumentationInventoryRow` (PF-PRO-002 / PF-IMP-760)

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] TDD document created in the correct location using the tier-appropriate template
  - [ ] TDD document follows the required naming convention: `tdd-[assessment-id]-[feature-name]-t[tier].md`
  - [ ] "AI Agent Session Handoff Notes" section is complete and explicit
  - [ ] All required sections for the tier are properly completed according to tier requirements
  - [ ] Technical approach is clearly defined
  - [ ] **MANDATORY**: Quality Attribute Requirements section completed with feature-specific targets
  - [ ] **MANDATORY**: Quality Attribute Implementation section completed with technical approach
  - [ ] **MANDATORY**: Quality Measurement section completed with monitoring approach
  - [ ] Quality attribute analysis integrated throughout technical design
  - [ ] Diagrams and visual aids are included as appropriate for the tier
  - [ ] Human partner feedback has been incorporated
- [ ] **Verify Automated Updates**: Ensure the [../../scripts/file-creation/02-design/New-TDD.ps1](../../scripts/file-creation/02-design/New-TDD.ps1) script successfully updated state tracking files
  - [ ] Feature Tracking Status automatically updated from "📝 Needs TDD" to "🧪 Needs Test Spec"
  - [ ] Feature Tracking Notes column automatically updated with TDD creation date
  - [ ] TDD document link automatically inserted into the per-feature state file's §4 Documentation Inventory
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-015`, context "TDD Creation".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `tdd-[FeatureId]-[feature-name]-t[Tier].md` | `New-TDD.ps1` | Technical design document with architecture and implementation details |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | `New-TDD.ps1` | Status: "📝 Needs TDD" → "🧪 Needs Test Spec" |
| **Updates** | Per-feature state file (`doc/state-tracking/features/<id>-implementation-state.md`) | `New-TDD.ps1` (via `Add-StateFileDocumentationInventoryRow`) | Insert TDD document row into §4 Documentation Inventory (PF-PRO-002 / PF-IMP-760) |

## Next Tasks

- [**Test Specification Creation**](../03-testing/test-specification-creation-task.md) - Create comprehensive test specifications from the TDD for Test-First Development
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - Uses the TDD and test specifications to plan and implement the feature
- [**Code Review**](../06-maintenance/code-review-task.md) - Uses the TDD as a reference for evaluating implementation

<!-- merged from transition-registry entry: TDD Creation -->
### Prerequisites for Transition

- [ ] TDD document created and reviewed
- [ ] TDD linked in Feature Tracking
- [ ] Design decisions documented and approved
- [ ] Technical approach validated

### Next Task Selection

```
What was the original tier assessment?
├─ Tier 2 (🟠) → Feature Implementation → 👀 Needs Review → Code Review
│   └─ Reason: Moderate complexity with lightweight design is sufficient
└─ Tier 3 (🔴) → Test Specification Creation → Feature Implementation → 👀 Needs Review → Code Review
    └─ Reason: Complex features need comprehensive test planning before implementation
```

**When to Use Decomposed Mode:**

- **✅ Use when**:
  - Multi-session implementation expected (feature takes multiple sessions)
  - Complex features with distinct layers (data, state, UI)
  - Context preservation critical between sessions
  - Team collaboration requires clear handoffs
  - Session management and progress tracking important
  - Clear separation of concerns needed

- **❌ Skip when**:
  - Simple features completable in single session
  - Minimal layer separation (e.g., UI-only changes)
  - Single developer working continuously
  - Rapid prototyping or experimental features

### Preparation for Next Task

1. Ensure TDD is complete and addresses all complexity factors
2. Verify technical approach is feasible
3. Confirm all design decisions are documented
4. Review any implementation constraints or considerations

## Related Resources

- **TDD Templates** - Tier-specific templates for technical design documents:
  - [T1 Template](../../templates/02-design/tdd-t1-template.md) - For Tier 1 (simple) features
  - [T2 Template](../../templates/02-design/tdd-t2-template.md) - For Tier 2 (moderate) features
  - [T3 Template](../../templates/02-design/tdd-t3-template.md) - For Tier 3 (complex) features
- [`tdd-creation` craft skill](../../../.claude/skills/tdd-creation/SKILL.md) - the TDD customization craft (replaces the retired creation guide); activated by the Check Recommended Skills step
- [TDD Generation Script](../../scripts/file-creation/02-design/New-TDD.ps1) - Script for generating TDD documents
- [Architecture Decision Records](../../../doc/technical/adr) - Repository of past architectural decisions
