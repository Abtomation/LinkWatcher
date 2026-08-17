---
id: PF-TSK-092
type: Process Framework
category: Task Definition
version: 1.0
created: 2026-06-16
updated: 2026-06-16
automation: semi
complexity: medium
description: "Execute a single validation dimension against selected features using the shared validation process plus the dimension's path file."
domain: agnostic
use_when: >-
  Execute one validation dimension (security, performance, code quality, architectural consistency, etc.) against selected features after Validation Preparation; the dimension's path file supplies the specialized role, analysis steps, and criteria. Triggers: 'run the security validation', 'validate code quality', 'do the architectural-consistency dimension'.
triggers:
  - "run the security validation"
  - "validate code quality"
  - "do the architectural-consistency dimension"
scripts:
  - ../../scripts/file-creation/05-validation/New-ValidationReport.ps1
  - ../../scripts/update/Update-ValidationReportState.ps1
  - ../../scripts/update/Update-TechDebt.ps1
trigger_status:
  - raw: "Validation tracking → dimension assigned in the feature×dimension matrix"
output_status:
  - raw: "`technical-debt-tracking.md` → new items (Dims: AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI)"
next_tasks:
  - task: ../06-maintenance/code-review-task.md
    condition: "After all planned dimensions in the validation round are complete"
---

# Dimension Validation

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Executes **one** validation dimension against a set of selected features, producing a scored validation report and routing significant findings to technical-debt tracking. This task is the **dispatcher**: it holds the validation process shared by every dimension, while each dimension's specialized role, analysis steps, and scoring criteria live in a per-dimension **path file** (`<dimension>-validation-path.md`) that you read and plug into the steps below.

Entry is planned by [Validation Preparation (PF-TSK-077)](validation-preparation.md), which selects the feature×dimension matrix. Validate **one dimension per session** — see [One Batch Per Session](../../ai-tasks.md#one-batch-per-session-validation-tasks).

> **Why a dispatcher + path files**: the 11 validation dimensions share one process (scope → analyze → score → report → tech-debt). Only the *analysis steps* and *criteria* differ per dimension. The shared process lives here once; the per-dimension delta is individually editable in each path file.

## Dimension Path Files

Identify your dimension from the [Validation Preparation](validation-preparation.md) plan, then open its path file. Each path file supplies the specialized **Role**, the dimension-specific **Context to load**, the **Execution analysis steps**, the scoring **criteria**, the `-ValidationType` token (step 6), and the `Dims` code (step 13).

| Dimension | Path file | `-ValidationType` | Dims |
|---|---|---|---|
| Architectural Consistency | [architectural-consistency-validation-path.md](architectural-consistency-validation-path.md) | `ArchitecturalConsistency` | AC |
| Code Quality & Standards | [code-quality-standards-validation-path.md](code-quality-standards-validation-path.md) | `CodeQuality` | CQ |
| Integration & Dependencies | [integration-dependencies-validation-path.md](integration-dependencies-validation-path.md) | `IntegrationDependencies` | ID |
| Documentation Alignment | [documentation-alignment-validation-path.md](documentation-alignment-validation-path.md) | `DocumentationAlignment` | DA |
| Extensibility & Maintainability | [extensibility-maintainability-validation-path.md](extensibility-maintainability-validation-path.md) | `ExtensibilityMaintainability` | EM |
| AI Agent Continuity | [ai-agent-continuity-validation-path.md](ai-agent-continuity-validation-path.md) | `AIAgentContinuity` | — ¹ |
| Security & Data Protection | [security-data-protection-validation-path.md](security-data-protection-validation-path.md) | `SecurityDataProtection` | SE |
| Performance & Scalability | [performance-scalability-validation-path.md](performance-scalability-validation-path.md) | `PerformanceScalability` | PE |
| Observability | [observability-validation-path.md](observability-validation-path.md) | `Observability` | OB |
| Accessibility / UX Compliance | [accessibility-ux-compliance-validation-path.md](accessibility-ux-compliance-validation-path.md) | `AccessibilityUX` | UX |
| Data Integrity | [data-integrity-validation-path.md](data-integrity-validation-path.md) | `DataIntegrity` | DI |

> ¹ AI Agent Continuity is a standalone validation task, not a development dimension — it does not appear in feature Dimension Profiles. Its path file states the `Dims` code to use for any tech-debt items it raises.

## AI Agent Role

**Adopt the specialized role declared in your dimension's path file** (e.g., Security Auditor, Software Architect, Code Quality Auditor, Integration Specialist). In general, across all dimensions:

**Mindset**: Systematic, evidence-based, risk-prioritized
**Focus Areas**: Per the dimension path file's criteria
**Communication Style**: Present findings with severity and concrete remediation; ask about project-specific quality priorities and acceptable-risk levels

## Context Requirements

- **Critical (Must Read):**

  - **Your dimension's path file** — `<dimension>-validation-path.md` (table above) — specialized role, analysis steps, criteria, ValidationType token, Dims code
  - **Feature Validation Guide** - [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) - validation methodology and the Dimension Catalog
  - **Feature Tracking** - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - status of features to be validated
  - **Validation Tracking** - the active validation tracking state file for the current round (created by [Validation Preparation](validation-preparation.md))
  - **Validation Report Template** - [Validation Report Template](../../templates/05-validation/validation-report-template.md)
  - **Codebase Structure** - source code for the selected features

- **Important (Load If Space):**

  - Dimension-specific context — listed in the dimension path file (configuration files, API specs, dependency manifests, logs, etc.)
  - **New-ValidationReport Script** - [New-ValidationReport.ps1](../../scripts/file-creation/05-validation/New-ValidationReport.ps1)

- **Reference Only (Access When Needed):**
  - **Architecture Decision Records** - [ADR Directory](../../../doc/technical/architecture)
  - **ID Registry** - [PF ID Registry](../../PF-id-registry.json)

## Process

> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint. Never proceed past a checkpoint without presenting findings and getting explicit approval.**
>
> **▶ Dispatch**: Before step 1, identify the dimension you are validating (from the Validation Preparation plan) and open its **path file** (table above). The path file plugs into steps 2, 3, 5, 6, 7, 8, 12, and 13 below.

### Preparation

1. **Review Validation Scope**: Identify the specific selected features to validate (typically 2–4 features per session, per the round plan).
2. **Load Context Files**: Review the feature implementations and the **dimension-specific context listed in the path file**.
3. **Prepare Dimension Criteria**: Review the scoring criteria and standards in the **dimension path file** (e.g., OWASP for Security, SOLID for Code Quality, ADRs for Architectural Consistency).
4. **🚨 CHECKPOINT**: Present validation scope, selected features, context review, and dimension criteria to the human partner for approval before execution.

### Execution

5. **Dimension Analysis**: Perform the **Execution analysis steps from the dimension path file** — the dimension-specific aspects to examine. This is the analytical core of the dimension.
6. **Generate Validation Report**: Create the report using the automation script, with the dimension's `-ValidationType` token (table above):
   ```powershell
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/05-validation/New-ValidationReport.ps1 -ValidationType "<token>" -FeatureIds "X.Y.Z,A.B.C" -SessionNumber 1
   ```
7. **Score Criteria**: Apply the 4-point scoring system (0–3) to each criterion defined in the path file.
8. **Document Findings**: Record dimension-specific issues, risks, and remediation recommendations — with severity ratings where the path file calls for them.
9. **🚨 CHECKPOINT**: Present scoring, findings, and remediation recommendations to the human partner for review before finalization.

### Finalization

10. **Update Validation Tracking**: Update the validation tracking matrix with the report creation date and link.
11. **Review Quality Gates**: Confirm the validation meets the minimum quality threshold (average score ≥ 2.0).
12. **Plan Remediation**: For scores below threshold, create action items for improvement, prioritized per the dimension path file's guidance (e.g., severity for Security, user-experience impact for Performance).
13. **🤖 AUTOMATED — Update Technical Debt Tracking**: Add new open issues — **apply the [Tech Debt Quality Gate](../../guides/05-validation/feature-validation-guide.md#tech-debt-item-quality-gate) filters before creating each item** — to [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md), using the dimension's `Dims` code (table above):
    ```powershell
    process-framework/scripts/update/Update-TechDebt.ps1 -Add -Description "Description" -Dims "<code>" -Location "Location" -Priority "Priority" -EstimatedEffort "Effort" -AssessmentId "PD-VAL-XXX" -Notes "Notes"
    ```
14. **Generate Round Summary** (if this is the final dimension in the current validation round):
    ```powershell
    process-framework/scripts/file-creation/05-validation/Generate-ValidationSummary.ps1 -OutputPath "doc/validation/summaries" -SummaryType "Detailed"
    ```
15. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below.

## Outputs

- **Dimension Validation Report** (`PD-VAL-XXX`) - Scored report with findings, created under `doc/validation/reports/<dimension>/`
- **Updated Validation Tracking Matrix** - Tracking file updated with report date and link in the dimension's column for the validated features
- **Remediation Action Items / Tech-Debt Items** - For features scoring below the quality threshold (registered via `Update-TechDebt.ps1`)

## State Tracking

The following state files must be updated as part of this task:

- **Validation Tracking State File** - Update the active validation tracking matrix with the report creation date and link
- [Product Documentation Map](../../../doc/PD-documentation-map.md) - Regenerate (`Build-DocumentationMap.ps1 -Tree PD`) to pick up the new validation report's `description:` (generated DO-NOT-EDIT projection, PF-PRO-050)
- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - Add new open issues identified during validation

## ⚠️ Task Completion Checklist (task-specific)

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Dimension validation report created with proper ID and scoring
  - [ ] Report contains detailed findings and remediation recommendations
  - [ ] Quality gate assessment completed (average score ≥ 2.0 or remediation plan created)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Validation tracking state file updated with report creation date and link
  - [ ] [Product Documentation Map](../../../doc/PD-documentation-map.md) regenerated via `Build-DocumentationMap.ps1 -Tree PD` and `-Check`-clean (reflects the new validation report's `description:`)
  - [ ] **AUTOMATED**: [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) updated with new open issues using `Update-TechDebt.ps1`
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-092`, context "Dimension Validation (<dimension>)".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Validation report (`PD-VAL-XXX`) | `New-ValidationReport.ps1` | Report file from template; content filled manually by AI agent |
| **Updates** | Validation tracking state file | `Update-ValidationReportState.ps1` | Update validation matrix with report results and link |
| **Updates** | [`PD-documentation-map.md`](../../../doc/PD-documentation-map.md) | Generated by [`Build-DocumentationMap.ps1 -Tree PD`](../../scripts/validation/Build-DocumentationMap.ps1); `-Check` drift gate | Regenerate to reflect the new validation report's `description:` (DO-NOT-EDIT projection, PF-PRO-050) |
| **Updates** | [`technical-debt-tracking.md`](../../../doc/state-tracking/permanent/technical-debt-tracking.md) | `Update-TechDebt.ps1` (conditional) | Register significant findings as tech debt items |

## Next Tasks

- **Next Dimension** - Return to the [Validation Preparation](validation-preparation.md) plan and run this task again for the next dimension in the round (one dimension per session).
- **Code Review** - After all planned dimensions in the round are validated, proceed to [Code Review](../06-maintenance/code-review-task.md).

### Prerequisites for Transition

- [ ] Dimension validation report created and scored
- [ ] Validation tracking matrix updated with report date and link
- [ ] Tech-debt items filed for sub-threshold findings

### Next Task Selection

- **More dimensions planned in this round** → run Dimension Validation again for the next dimension (fresh session).
- **All planned dimensions complete** → Code Review, then Release & Deployment.

### Preparation for Next Task

1. Confirm the validation tracking matrix reflects the just-completed dimension.
2. Identify the next dimension (and feature batch) from the round plan.

## Related Resources

- [Validation Preparation](validation-preparation.md) - Plans the feature×dimension matrix that feeds this task
- [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) - Methodology and the Dimension Catalog
- The per-dimension **path files** (table above) - dimension-specific role, analysis steps, and criteria
