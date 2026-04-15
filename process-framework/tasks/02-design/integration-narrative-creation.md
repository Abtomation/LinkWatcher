---
id: PF-TSK-083
type: Process Framework
category: Task Definition
version: 1.0
created: 2026-04-08
updated: 2026-04-08
---

# Integration Narrative Creation

## Purpose & Context

This task creates Integration Narratives — focused documents that explain how 2+ features collaborate in a cross-cutting workflow. While TDDs describe individual feature internals and ADRs record specific decisions, Integration Narratives answer: "How do features X, Y, Z work together in workflow W?" They synthesize scattered cross-feature knowledge into a single, verified reference.

## AI Agent Role

**Role**: Integration Architect
**Mindset**: Cross-cutting, verification-first, synthesis-oriented
**Focus Areas**: Component interaction patterns, data flow across feature boundaries, callback/event chains, error propagation paths
**Communication Style**: Present verified findings with source code evidence, flag TDD/code divergence explicitly, ask about workflow scope when boundaries are ambiguous

## When to Use

- When all features in a cross-cutting workflow have reached "Implemented" status in [user-workflow-tracking.md](/doc/state-tracking/permanent/user-workflow-tracking.md)
- When a bug fix or maintenance task reveals that cross-feature understanding is required and no Integration Narrative exists
- When onboarding to a workflow area where individual feature docs don't convey the full picture
- When 2+ features collaborate in a pipeline where Feature A's output feeds Feature B's input and understanding requires reading 3+ separate documents

**Prerequisites:**
- All participating features must have TDDs (or at minimum, implemented source code)
- The workflow must be identified in [user-workflow-tracking.md](/doc/state-tracking/permanent/user-workflow-tracking.md)
- `New-IntegrationNarrative.ps1` script must be available

## Context Requirements

<!-- Uncomment and update when context map is created:
[View Context Map for this task](../../visualization/context-maps/02-design/integration-narrative-creation-map.md) -->

- **Critical (Must Read):**

  - [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) - Identifies which workflow to document and its participating features
  - Feature TDDs for participating features (paths in feature state files) - Source of per-feature architecture details
  - **Actual source code** for participating features - Must verify documented interactions match implementation

- **Important (Load If Space):**

  - Feature ADRs for participating features - Architectural decisions affecting cross-feature interactions
  - Feature state files for participating features - Implementation status and artifact links
  - [Integration Narrative Customization Guide](/process-framework/guides/02-design/integration-narrative-customization-guide.md) - How to fill in each template section
  - [Script Development Quick Reference](/process-framework/guides/support/script-development-quick-reference.md) - PowerShell execution patterns

- **Reference Only (Access When Needed):**
  - [PD Documentation Map](/doc/PD-documentation-map.md) - For verifying narrative is indexed after creation
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use `New-IntegrationNarrative.ps1` for narrative creation — never create PD-INT files manually.**
>
> **🔍 CRITICAL: Verify all cross-feature interactions against actual source code. Do NOT trust TDDs alone — code may have diverged from design documentation.**

### Preparation

1. **Identify the target workflow** — Check [user-workflow-tracking.md](/doc/state-tracking/permanent/user-workflow-tracking.md) for the workflow to document. Confirm all participating features have reached "Implemented" status. Note the Workflow ID (e.g., WF-002).

2. **Determine workflow boundaries** — Identify:
   - Which features participate in this workflow
   - What is the entry event (e.g., filesystem event, user action, API call)
   - What is the final output (e.g., updated file, state change, response)
   - What is the scope boundary (where does this workflow end and another begin)

3. **Gather input documentation** — For each participating feature, locate and read from the [feature state files directory](/doc/state-tracking/temporary/):
   - The feature's TDD (from feature state file → Documentation Inventory)
   - Any relevant ADRs affecting cross-feature interactions
   - The feature state file for implementation status and known issues

4. **🚨 CHECKPOINT**: Present the workflow scope, participating features, and entry/exit points to human partner for approval before proceeding.

### Execution

5. **Read source code for each participating feature** — For each feature, read the key source files that implement the cross-feature interaction points. Focus on:
   - Function/method signatures at feature boundaries
   - Callback registrations and event handlers
   - Shared data structures passed between features
   - Configuration values that propagate across feature boundaries
   - Error handling at boundary crossings

6. **Map cross-feature interactions** — Document how components actually communicate:
   - Direct function calls across feature boundaries
   - Event/callback chains
   - Shared data structures and their lifecycle
   - Configuration propagation paths
   - Error propagation and recovery patterns

7. **Report TDD/code divergence as technical debt** — Compare what TDDs say about cross-feature interactions with what the code actually does. For each discrepancy found, report it as technical debt using the automation script:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/update/Update-TechDebt.ps1 -Add -Title "TDD divergence: [description]" -Category "Documentation" -Severity "Medium" -Confirm:\$false
   ```
   The Integration Narrative itself should document the **actual** state (what the code does), not the outdated TDD claims.

8. **Create the Integration Narrative** using the automation script:
   ```bash
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/02-design/New-IntegrationNarrative.ps1 -WorkflowName "Workflow Name" -WorkflowId "WF-XXX" -Description "Brief description of the workflow" -Confirm:\$false
   ```
   The script automatically: assigns PD-INT ID, creates the file, updates PD-id-registry.json, appends to PD-documentation-map.md, and sets the "Integration Doc" column in user-workflow-tracking.md for the specified workflow.

9. **Customize the narrative** — Fill in all template sections following the [Integration Narrative Customization Guide](/process-framework/guides/02-design/integration-narrative-customization-guide.md):
   - **Workflow Overview**: Entry point, exit point, high-level flow
   - **Participating Features**: Table of features with their roles in this workflow
   - **Component Interaction Diagram**: Mermaid diagram showing how components connect
   - **Data Flow Sequence**: Step-by-step data transformation through the pipeline
   - **Callback/Event Chains**: How events propagate across feature boundaries
   - **Configuration Propagation**: Which config values affect multiple features
   - **Error Handling Across Boundaries**: How errors in one feature affect others

10. **🚨 CHECKPOINT**: Present the completed narrative to human partner for review. Focus review on accuracy of cross-feature interactions and whether the narrative would help someone debug a cross-feature issue.

### Finalization

11. **Verify auto-updates** — Confirm the script correctly updated:
    - [user-workflow-tracking.md](/doc/state-tracking/permanent/user-workflow-tracking.md) — "Integration Doc" column set to the assigned PD-INT ID for the specified workflow
    - [PD-documentation-map.md](/doc/PD-documentation-map.md) — narrative entry appended to "Integration Narratives" section

13. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Integration Narrative** (PD-INT-XXX) - Cross-feature workflow documentation in `doc/technical/integration/[workflow-name]-integration-narrative.md`. Contains component interaction diagram, data flow sequence, callback/event chains, configuration propagation, and error handling across feature boundaries.
- **Technical debt items** - Any TDD/code divergence found during source code verification, reported via `Update-TechDebt.ps1`
- **✅ AUTOMATED by script**: user-workflow-tracking.md "Integration Doc" column, PD-documentation-map.md entry, PD-id-registry.json counter

## State Tracking

The following state files are updated automatically by `New-IntegrationNarrative.ps1`:

- [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) - "Integration Doc" column auto-set to assigned PD-INT ID for the specified workflow
- [PD Documentation Map](/doc/PD-documentation-map.md) - Narrative entry auto-appended to "Integration Narratives" section
- [PD ID Registry](/doc/PD-id-registry.json) - PD-INT counter auto-incremented

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Integration Narrative created via `New-IntegrationNarrative.ps1` (not manually)
  - [ ] All template sections filled in with verified content (no placeholders remaining)
  - [ ] Cross-feature interactions verified against actual source code (not just TDDs)
  - [ ] TDD/code divergence documented if found
  - [ ] Human partner reviewed and approved the narrative content
- [ ] **Verify Auto-Updated State Files**: Confirm script correctly updated all tracking files
  - [ ] [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) "Integration Doc" column set to correct PD-INT ID
  - [ ] [PD Documentation Map](/doc/PD-documentation-map.md) contains entry for the new narrative
- [ ] **Technical Debt Reported**: All TDD/code discrepancies reported via `Update-TechDebt.ps1`
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-083" and context "Integration Narrative Creation"

## Next Tasks

- [**E2E Acceptance Test Case Creation**](/process-framework/tasks/03-testing/e2e-acceptance-test-case-creation-task.md) - The Integration Narrative provides verified cross-feature understanding that improves E2E test case design for the same workflow
- [**Documentation Alignment Validation**](/process-framework/tasks/05-validation/documentation-alignment-validation.md) - Validates Integration Narratives against source code as part of documentation validation rounds

## Related Resources

- [Integration Narrative Customization Guide](/process-framework/guides/02-design/integration-narrative-customization-guide.md) - Step-by-step instructions for filling in the template
- [Integration Narrative Template](/process-framework/templates/02-design/integration-narrative-template.md) - Standardized structure for integration narratives
- [Cross-Feature Integration Documentation Concept](/process-framework-local/proposals/old/cross-feature-integration-documentation.md) - Original concept document for this extension
- [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md) - Workflow status and trigger tracking
