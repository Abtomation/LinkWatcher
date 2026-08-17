---
id: PF-TSK-083
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.2
created: 2026-04-08
updated: 2026-07-13
description: "Create Integration Narratives explaining how 2+ features collaborate in cross-cutting workflows"
complexity: medium
use_when: >-
  Create Integration Narratives for cross-feature workflows
automation: semi
scripts:
  - ../../scripts/file-creation/02-design/New-IntegrationNarrative.ps1
trigger_status:
  - raw: "`user-workflow-tracking.md` → all workflow features = `Implemented` + Integration Doc empty"
output_status:
  - raw: "`user-workflow-tracking.md` → Integration Doc = PD-INT-XXX link"
next_tasks:
  - task: ../03-testing/e2e-acceptance-test-case-creation-task.md
    condition: "The Integration Narrative provides verified cross-feature understanding that improves E2E test case design for the same workflow"
  - task: ../05-validation/documentation-alignment-validation-path.md
    condition: "Validates Integration Narratives against source code as part of documentation validation rounds"
---

# Integration Narrative Creation

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

This task creates Integration Narratives — focused documents that explain how 2+ features collaborate in a cross-cutting workflow. While TDDs describe individual feature internals and ADRs record specific decisions, Integration Narratives answer: "How do features X, Y, Z work together in workflow W?" They synthesize scattered cross-feature knowledge into a single, verified reference.

## AI Agent Role

**Role**: Integration Architect
**Mindset**: Cross-cutting, verification-first, synthesis-oriented
**Focus Areas**: Component interaction patterns, data flow across feature boundaries, callback/event chains, error propagation paths
**Communication Style**: Present verified findings with source code evidence, flag TDD/code divergence explicitly, ask about workflow scope when boundaries are ambiguous

## Context Requirements

- **Critical (Must Read):**

  - [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md) - Identifies which workflow to document and its participating features
  - Feature TDDs for participating features (paths in feature state files) - Source of per-feature architecture details
  - **Actual source code** for participating features - Must verify documented interactions match implementation

- **Important (Load If Space):**

  - Feature ADRs for participating features - Architectural decisions affecting cross-feature interactions
  - Feature state files for participating features - Implementation status and artifact links
  - [`integration-narrative` craft skill](../../../.claude/skills/integration-narrative/SKILL.md) — the customization craft (how to fill each template section, source-verification discipline), activated in Preparation Step 1 (Check Recommended Skills). Replaces the former procedural customization guide and **drives the narrative customization in Execution.**
  - [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) - PowerShell execution patterns

## Process

> **⚠️ MANDATORY: Use `New-IntegrationNarrative.ps1` for narrative creation — never create PD-INT files manually.**
>
> **🔍 CRITICAL: Verify all cross-feature interactions against actual source code. Do NOT trust TDDs alone — code may have diverged from design documentation.**

### Preparation

1. **Check Recommended Skills** — Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `integration-narrative-creation`. If the `integration-narrative` craft skill is available in the session, activate it — it owns the **customization craft** this task delegates to (how to fill the narrative well). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/integration-narrative/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The customization craft is unavailable for this run only if the skill file itself is absent (the retired procedural customization guide has no successor).

2. **Identify the target workflow** — Check [user-workflow-tracking.md](../../../doc/state-tracking/permanent/user-workflow-tracking.md) for the workflow to document. Confirm all participating features have reached "Implemented" status. Note the Workflow ID (e.g., WF-002).

3. **Determine workflow boundaries** — Identify:
   - Which features participate in this workflow
   - What is the entry event (e.g., filesystem event, user action, API call)
   - What is the final output (e.g., updated file, state change, response)
   - What is the scope boundary (where does this workflow end and another begin)

4. **Gather input documentation** — For each participating feature, locate and read from the [feature state files directory](../../../doc/state-tracking/temporary):
   - The feature's TDD (from feature state file → Documentation Inventory)
   - Any relevant ADRs affecting cross-feature interactions
   - The feature state file for implementation status and known issues

5. **🚨 CHECKPOINT**: Present the workflow scope, participating features, and entry/exit points to human partner for approval before proceeding.

### Execution

6. **Read source code for each participating feature** — For each feature, read the key source files that implement the cross-feature interaction points. Focus on:
   - Function/method signatures at feature boundaries
   - Callback registrations and event handlers
   - Shared data structures passed between features
   - Configuration values that propagate across feature boundaries
   - Error handling at boundary crossings

7. **Map cross-feature interactions** — Document how components actually communicate:
   - Direct function calls across feature boundaries
   - Event/callback chains
   - Shared data structures and their lifecycle
   - Configuration propagation paths
   - Error propagation and recovery patterns

8. **Report TDD/code divergence as technical debt** — Compare what TDDs say about cross-feature interactions with what the code actually does. For each discrepancy found, report it as technical debt using the automation script:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-TechDebt.ps1 -Add -Description "TDD divergence: [description]" -Dims "DA" -Location "[path/to/tdd-or-code]" -Priority "Medium" -EstimatedEffort "S" -Confirm:\$false
   ```
   The Integration Narrative itself should document the **actual** state (what the code does), not the outdated TDD claims.

9. **Create the Integration Narrative** using the automation script:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1 -WorkflowName "Workflow Name" -WorkflowId "WF-XXX" -Description "Brief description of the workflow" -Confirm:\$false
   ```
   The script automatically: assigns PD-INT ID, creates the file, updates PD-id-registry.json, and sets the "Integration Doc" column in user-workflow-tracking.md for the specified workflow.

10. **Customize the narrative** — Fill in all template sections, driven by the `integration-narrative` craft skill (activated in Preparation, Step 1) — it is the **canonical home for the narrative customization craft** (scoping, diagram detail, source-verified data-flow authoring). This task orchestrates around it; do not hand-author the craft the skill owns:
   - **Workflow Overview**: Entry point, exit point, high-level flow
   - **Participating Features**: Table of features with their roles in this workflow
   - **Component Interaction Diagram**: Mermaid diagram showing how components connect
   - **Data Flow Sequence**: Step-by-step data transformation through the pipeline
   - **Callback/Event Chains**: How events propagate across feature boundaries
   - **Configuration Propagation**: Which config values affect multiple features
   - **Error Handling Across Boundaries**: How errors in one feature affect others

11. **🚨 CHECKPOINT**: Present the completed narrative to human partner for review. Focus review on accuracy of cross-feature interactions and whether the narrative would help someone debug a cross-feature issue.

### Finalization

12. **Verify auto-updates** — Confirm the script correctly updated:
    - [user-workflow-tracking.md](../../../doc/state-tracking/permanent/user-workflow-tracking.md) — "Integration Doc" column set to the assigned PD-INT ID for the specified workflow

    **Recovery from script warnings**: If the script emitted a warning in its stdout (e.g., "Workflow Tracking: 'Integration Doc' column not found", "Workflow Tracking: WF-XXX not found"), the auto-update silently failed:

    1. **Manually patch** the affected file with the entry the script could not write.
    2. **Check for existing tech debt** — grep [technical-debt-tracking.md](../../../doc/state-tracking/permanent/technical-debt-tracking.md) for `New-IntegrationNarrative.ps1` and the failing behavior. The same script defect has been filed redundantly across sessions (e.g., TD221/TD222/TD225/TD230 are 4 entries for one regex bug). Only file a new entry if no open match exists.
    3. **File new tech debt** (if not duplicate) via:
       ```bash
       pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-TechDebt.ps1 -Add -Description "New-IntegrationNarrative.ps1: [behavior]" -Dims "CQ" -Location "process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1" -Priority "Low" -EstimatedEffort "S" -Confirm:\$false
       ```

13. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Integration Narrative** (PD-INT-XXX) - Cross-feature workflow documentation in `doc/technical/integration/[workflow-name]-integration-narrative.md`. Contains component interaction diagram, data flow sequence, callback/event chains, configuration propagation, and error handling across feature boundaries.
- **Technical debt items** - Any TDD/code divergence found during source code verification, reported via `Update-TechDebt.ps1`
- **✅ AUTOMATED by script**: user-workflow-tracking.md "Integration Doc" column, PD-id-registry.json counter

## State Tracking

The following state files are updated automatically by `New-IntegrationNarrative.ps1`:

- [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md) - "Integration Doc" column auto-set to assigned PD-INT ID for the specified workflow
- [PD ID Registry](../../../doc/PD-id-registry.json) - PD-INT counter auto-incremented

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Integration Narrative created via `New-IntegrationNarrative.ps1` (not manually)
  - [ ] All template sections filled in with verified content (no placeholders remaining)
  - [ ] Cross-feature interactions verified against actual source code (not just TDDs)
  - [ ] TDD/code divergence reported as tech debt items if found
  - [ ] Human partner reviewed and approved the narrative content
- [ ] **Verify Auto-Updated State Files**: Confirm script correctly updated all tracking files
  - [ ] [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md) "Integration Doc" column set to correct PD-INT ID
- [ ] **Technical Debt Reported**: All TDD/code discrepancies reported via `Update-TechDebt.ps1`
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-083`, context "Integration Narrative Creation".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| Create | `doc/technical/integration/[workflow]-integration-narrative.md` | Script | Integration Narrative with PD-INT ID |
| Update | `doc/PD-id-registry.json` | Script (auto) | Increment PD-INT nextAvailable counter |
| Update | `doc/state-tracking/permanent/user-workflow-tracking.md` | Script (auto) | Set "Integration Doc" column to PD-INT ID (by WorkflowId parameter) |

## Next Tasks

- [**E2E Acceptance Test Case Creation**](../03-testing/e2e-acceptance-test-case-creation-task.md) - The Integration Narrative provides verified cross-feature understanding that improves E2E test case design for the same workflow
- [**Documentation Alignment Validation**](../05-validation/documentation-alignment-validation-path.md) - Validates Integration Narratives against source code as part of documentation validation rounds

<!-- merged from transition-registry entry: Integration Narrative Creation (PF-TSK-083) -->
### Prerequisites for Transition

- [ ] Integration Narrative created via New-IntegrationNarrative.ps1
- [ ] All cross-feature interactions verified against source code
- [ ] Data flow, callback chains, and error propagation paths documented
- [ ] user-workflow-tracking.md updated with Integration Doc link

### Next Task Selection

```
Is a cross-cutting E2E test specification needed for this workflow?
├─ Yes (all workflow features implemented + E2E milestone exists) →
│   Cross-cutting E2E Test Specification (New-TestSpecification.ps1 -CrossCutting)
│   → then E2E Test Case Creation (PF-TSK-069) → Test Audit → E2E Execution
│   └─ Reason: Integration Narrative provides verified cross-feature understanding for E2E tests
├─ No (workflow not yet E2E-ready) → Continue with other work
│   └─ Reason: Remaining workflow features must reach Implemented status first
└─ Documentation validation round active? → Documentation Alignment Validation
    └─ Reason: Integration Narratives are validated as part of documentation accuracy checks
```

### Preparation for Next Task

1. Review narrative for complete coverage of cross-feature touchpoints
2. Confirm all participating features are listed in user-workflow-tracking.md
3. Verify the workflow's E2E readiness status in e2e-test-tracking.md
4. Ensure narrative includes sufficient detail for E2E test case design (data formats, expected states, error scenarios)

## Related Resources

- [`integration-narrative` craft skill](../../../.claude/skills/integration-narrative/SKILL.md) - the narrative customization craft (replaces the retired customization guide); activated by the Check Recommended Skills step
- [Integration Narrative Template](../../templates/02-design/integration-narrative-template.md) - Standardized structure for integration narratives
- [Cross-Feature Integration Documentation Concept](../../../process-framework-central/proposals/old/cross-feature-integration-documentation.md) - Original concept document for this extension
- [User Workflow Tracking](../../../doc/state-tracking/permanent/user-workflow-tracking.md) - Workflow status and trigger tracking
