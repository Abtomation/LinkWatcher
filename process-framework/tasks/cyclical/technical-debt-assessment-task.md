---
id: PF-TSK-023
type: Process Framework
category: Task Definition
version: 1.4
created: 2025-07-24
updated: 2026-07-20
change_notes: "v1.4 - PF-IMP-1592 BL-5 residue removal: Step 9's effort-collapsed quadrant scheme (contradicting the skill on every quadrant) replaced with a pointer to the skill's prioritization reference — the impact×effort matrix there is canonical"
description: "Systematic approach to identifying, categorizing, and prioritizing technical debt across the codebase"
use_when: >-
  Periodic code quality review or before major releases
frequency: "Quarterly/As needed"
automation: full
scripts:
  - ../../scripts/file-creation/cyclical/New-TechnicalDebtAssessment.ps1
  - ../../scripts/file-creation/cyclical/New-PrioritizationMatrix.ps1
  - ../../scripts/file-creation/cyclical/New-DebtItem.ps1
  - ../../scripts/update/Update-TechDebt.ps1
  - ../../scripts/update/Update-TechnicalDebtFromAssessment.ps1
trigger_status:
  - raw: "_(schedule / user request)_"
output_status:
  - raw: "`technical-debt-tracking.md` → new items added (triggers PF-TSK-022)"
next_tasks:
  - task: ../06-maintenance/code-refactoring-task.md
    condition: "Use prioritized debt items from assessment for systematic remediation"
  - task: ../01-planning/system-architecture-review.md
    condition: "Address architectural debt identified during assessment"
  - task: ../04-implementation/feature-implementation-planning-task.md
    condition: "Entry point to consider debt remediation during new feature development (leads to decomposed tasks PF-TSK-051 through PF-TSK-055)"
  - task: ../support/process-improvement-task.md
    condition: "Improve assessment process based on effectiveness metrics"
---

# Technical Debt Assessment Task

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Systematic approach to identifying, categorizing, and prioritizing technical debt across the codebase

## AI Agent Role

**Role**: Technical Lead
**Mindset**: Design-first thinking, risk-aware, collaborative
**Focus Areas**: Technical specifications, risk mitigation, code quality assessment, debt prioritization
**Communication Style**: Present design options with pros/cons and risk assessment, ask about technical constraints and quality standards

## Context Requirements

- **Critical (Must Read):**

  - [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - Current debt registry and management strategy
  - **Current Codebase** - Source code files in scope for assessment (lib/, test/, integration_test/)
  - **Recent Change Logs** - Git commit history and recent development activity

- **Important (Load If Space):**

  - [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md) - Dimension definitions and abbreviations for tagging debt items with their primary dimension (AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI, TST, AIC)
  - [Architecture Documentation](../../../doc/technical/architecture) - System architecture and design patterns
  - [Coding Standards](../../guides/03-testing) - Project coding standards and best practices
  - **Test Coverage Reports** - Current test coverage metrics and gaps
  - [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - Known bugs that may indicate debt areas
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Recent feature development that may have introduced debt
  - [`technical-debt-assessment` craft skill](../../../.claude/skills/technical-debt-assessment/SKILL.md) — the assessment judgment craft (what-counts-as-debt test, per-category identification criteria, impact/effort prioritization frameworks, debt-item customization), activated in Step 1 (Check Recommended Skills). Replaces the retired Assessment Criteria, Prioritization, and Debt Item Creation guides.

- **Reference Only (Access When Needed):**
  - **Performance Metrics** - Application performance data and bottlenecks
  - **Developer Feedback** - Team feedback on code maintainability and development friction
  - [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - Process effectiveness metrics

## Process

> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `technical-debt-assessment-task`. If the `technical-debt-assessment` craft skill is available in the session, activate it — it owns the **assessment judgment craft** this task delegates to (the what-counts-as-debt test, per-category identification criteria, impact/effort prioritization frameworks, and per-item debt-record customization). If it is not listed in the session, read [`SKILL.md`](../../../.claude/skills/technical-debt-assessment/SKILL.md) directly and apply it — that file is the canonical source the Skill tool loads, so a direct read is equivalent, not degraded. The judgment craft is unavailable for this run only if the skill file itself is absent (the retired procedural guides have no successors).
2. **Define Assessment Scope**: Determine assessment scope (full codebase, specific modules, or feature areas based on recent development activity)
3. **Review Context**: Load current [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) and review recent changes, known issues, and previous assessments
4. **Prepare Assessment Tools**: Set up assessment templates and tracking documents for systematic evaluation
5. **🚨 CHECKPOINT**: Present assessment scope, context findings, and initial observations to human partner

### Assessment Phase

6. **Systematic Code Analysis**: Review code areas using the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md) as the lens for identifying debt (the `technical-debt-assessment` skill's assessment-criteria reference carries the per-category identification criteria and the what-counts-as-debt test). Scan for issues across these categories (dimension abbreviation in parentheses):

   - **Architectural Issues** (AC): System design problems, missing patterns, coupling issues
   - **Code Quality Issues** (CQ): Readability, maintainability, duplication, complexity
   - **Integration Issues** (ID): Fragile interfaces, tight coupling between components
   - **Documentation Debt** (DA): Missing, outdated, or inadequate documentation
   - **Extensibility & Maintainability Issues** (EM): Missing extension points, rigid design
   - **Security Concerns** (SE): Vulnerabilities, insecure patterns, missing validations
   - **Performance Issues** (PE): Known bottlenecks, inefficient algorithms, resource usage
   - **Observability Gaps** (OB): Missing logging, insufficient error tracing
   - **Accessibility / UX Issues** (UX): Missing accessibility features, compliance gaps, UX compromises
   - **Data Integrity Issues** (DI): Missing atomicity, inconsistent state handling
   - **Testing Gaps** (TST): Missing tests, inadequate coverage, test quality issues
   - **Source Layout Compliance** (AC): Verify files are in the correct feature directories per [Source Code Layout](../../../doc/technical/architecture/source-code-layout.md) — no source files at repository root, no files in wrong feature directories, naming conventions followed

7. **Document Debt Items**: For each identified debt item, document:
   - Detailed description and location
   - **Primary dimension(s)**: Tag with standard dimension abbreviation(s) from the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md) — AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI, TST (Testing), or AIC (AI Agent Continuity). This replaces the free-text category and enables prioritization by dimension impact (e.g., SE-tagged debt ranks higher)
   - Severity assessment
   - Impact on development velocity, maintainability, and system stability
   - Estimated effort required for remediation
   - Risk assessment if left unaddressed

   > **⚠️ Data Quality**: Before finalizing each debt item description, verify it against the actual source code. Descriptions must accurately reflect the current state of the code — not assumptions from static analysis, documentation, or analogy with similar items. Inaccurate descriptions waste remediation effort downstream (ref: PF-IMP-088).

8. **🚨 CHECKPOINT**: Present identified debt items for review before prioritization

### Prioritization Phase

9. **🤖 AUTOMATED - Create Prioritization Matrix**: Use the automation script to generate the matrix document, then populate it with debt items (the `technical-debt-assessment` skill's prioritization reference carries the impact/effort scoring frameworks and business-context adjustment):

   ```powershell
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/cyclical/New-PrioritizationMatrix.ps1 -MatrixName "[Assessment Name] Prioritization" -AssessmentId "[PD-TDA-XXX]" -ItemCount [N]
   ```

   Assign each item to a Critical / High / Medium / Low quadrant using the impact×effort matrix in the skill's [prioritization reference](../../../.claude/skills/technical-debt-assessment/references/prioritization.md) — the canonical quadrant definitions and priority-score formula live there.

10. **Risk Assessment**: Evaluate risks of leaving high-priority debt unaddressed
11. **Create Remediation Plan**: Develop actionable plan for addressing prioritized debt items with timeline recommendations
12. **🚨 CHECKPOINT**: Present prioritized matrix and remediation plan to human partner for approval

### Finalization

13. **🤖 AUTOMATED: Update Technical Debt Registry**: Use automation to add new debt items to [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md):

   **OPTION A - Full Automation (Recommended):**

   ```powershell
   # Process all debt items from the assessment automatically
   process-framework/scripts/update/Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PD-TDA-XXX"
   ```

   **OPTION B - Individual Item Addition:**

   ```powershell
   # Add individual debt items manually (use dimension abbreviation(s) for -Dims, e.g., "PE" or "PE OB". Valid: AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI, TST, AIC)
   process-framework/scripts/update/Update-TechDebt.ps1 -Add -Description "Description" -Dims "PE" -Location "Location" -Priority "Priority" -EstimatedEffort "Effort" -DebtItemId "PD-TDI-XXX" -AssessmentId "PD-TDA-XXX"
   ```

   **Automation Benefits:**

   - Automatically assigns next available TD### ID to each debt item
   - References the assessment ID (PD-TDA-XXX) in the Assessment ID column
   - Updates individual debt item files (PD-TDI-XXX) with assigned registry ID
   - Marks debt items as "Added" in their Registry Integration section
   - Maintains bidirectional linking between assessments and registry

14. **Generate Assessment Report**: Create comprehensive assessment report with findings, priorities, and recommendations
15. **Plan Integration**: Identify how debt remediation can be integrated into upcoming development cycles
16. **🚨 CHECKPOINT**: Review complete assessment report with human partner before marking task complete
17. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Integration Points

**Feeds Into:**

- [Code Refactoring Task](../06-maintenance/code-refactoring-task.md) - Provides prioritized debt items for systematic remediation
- [System Architecture Review](../01-planning/system-architecture-review.md) - Informs architectural improvement decisions
- [Feature Implementation Planning](../04-implementation/feature-implementation-planning-task.md) - Identifies debt considerations for new development

**Supports:**

- Release planning by identifying release-blocking debt
- Sprint planning by providing technical improvement backlog items
- Architecture evolution through systematic debt identification

**Workflow Integration:**

- **Before Major Releases**: Focus on release-stability debt assessment
- **After Feature Development**: Identify newly introduced debt from recent development
- **During Planning Cycles**: Provide technical debt backlog for development prioritization

## Outputs

- **Technical Debt Assessment Report** - Comprehensive assessment document with findings, analysis, and recommendations (stored in `/process-framework/technical-debt-assessments/reports`)
- **Updated Technical Debt Registry** - Enhanced [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) with newly identified debt items
- **Debt Prioritization Matrix** - Visual representation of debt priority based on impact/effort analysis (included in assessment report)
- **Remediation Roadmap** - Actionable plan for addressing prioritized debt items with timeline recommendations (included in assessment report)
- **Integration Recommendations** - Specific guidance on integrating debt remediation into upcoming development cycles

## State Tracking

The following state files must be updated as part of this task:

- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - Add newly identified debt items with complete metadata (ID, description, category, location, priority, effort estimation, status)
- [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - Track assessment effectiveness and process improvements identified during the assessment
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Update with debt-related blockers or considerations that may impact feature development

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Technical Debt Assessment Report created with comprehensive findings and analysis
  - [ ] Debt Prioritization Matrix completed with impact/effort analysis
  - [ ] Remediation Roadmap created with actionable timeline recommendations
  - [ ] Integration Recommendations documented for upcoming development cycles
- [ ] **🤖 AUTOMATED: Update State Files**: Ensure all state tracking files have been updated using automation scripts
  - [ ] **AUTOMATED**: [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) updated with newly identified debt items using `Update-TechnicalDebtFromAssessment.ps1`
  - [ ] **AUTOMATED**: All debt items assigned TD### IDs and linked to assessment ID (PD-TDA-XXX) via automation
  - [ ] **AUTOMATED**: Individual debt item files (PD-TDI-XXX) updated with registry IDs and marked as "Added" via automation
  - [ ] **MANUAL**: [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) updated with assessment effectiveness metrics
  - [ ] **MANUAL**: [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) updated with debt-related considerations (if applicable)
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-023`, context "Technical Debt Assessment".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[PD-TDA-XXX]-[assessment-name].md` | `New-TechnicalDebtAssessment.ps1` | Technical debt assessment document with systematic evaluation and prioritization matrix |
| **Creates** | `[PD-TDI-XXX]-[item-title].md` (multiple) | `New-DebtItem.ps1` | Individual debt item records with **assessment linking** and automation command guidance<br/>• Include `-AssessmentId` parameter for traceability<br/>• Auto-populate assessment reference and registry integration fields<br/>• Provide ready-to-use automation commands |
| **Updates** | [`technical-debt-tracking.md`](../../../doc/state-tracking/permanent/technical-debt-tracking.md) | [`Update-TechnicalDebtFromAssessment.ps1`](../../scripts/update/Update-TechnicalDebtFromAssessment.ps1) | **FULLY AUTOMATED REGISTRY INTEGRATION:**<br/>• Automatically add new debt items with TD### IDs<br/>• Auto-reference assessment ID (PD-TDA-XXX) in Assessment ID column<br/>• Create bidirectional traceability between registry and assessments<br/>• **Usage:** `.\Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PD-TDA-XXX"` |
| **Updates** | Individual debt item files | [`Update-TechDebt.ps1`](../../scripts/update/Update-TechDebt.ps1) | **AUTOMATED REGISTRY INTEGRATION:**<br/>• Auto-update Registry Status: "Not Added" → "Added"<br/>• Auto-assign TD### Registry ID<br/>• Mark items as integrated into permanent tracking system<br/>• Maintain bidirectional linking automatically |
| **Updates** | [`process-improvement-tracking.md`](../../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) | Manual | Track assessment effectiveness and process improvements identified |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | Manual (conditional) | When debt affects feature development blockers |

## Next Tasks

- [**Code Refactoring Task**](../06-maintenance/code-refactoring-task.md) - Use prioritized debt items from assessment for systematic remediation
- [**System Architecture Review**](../01-planning/system-architecture-review.md) - Address architectural debt identified during assessment
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - Entry point to consider debt remediation during new feature development (leads to decomposed tasks PF-TSK-051 through PF-TSK-055)
- [**Process Improvement Task**](../support/process-improvement-task.md) - Improve assessment process based on effectiveness metrics

<!-- merged from transition-registry entry: Technical Debt Assessment -->
### Prerequisites for Transition

- [ ] Technical debt assessment completed
- [ ] Debt items prioritized and documented
- [ ] Technical Debt Tracking updated
- [ ] Refactoring recommendations made

### Next Task Selection

```
What was the assessment result?
├─ High priority debt identified → Code Refactoring
│   └─ Reason: Address critical technical debt immediately
├─ Medium priority debt identified → Schedule Code Refactoring
│   └─ Reason: Plan refactoring for appropriate time
└─ Low priority debt identified → Continue current development
    └─ Reason: Technical debt can be addressed later
```

### Preparation for Next Task

1. **Prioritize Refactoring Scope**: Select technical debt items by impact and effort
2. **Prepare Refactoring Context**: Gather target code area, quality issues, and test coverage information
3. **Plan Comprehensive Workflow**: Prepare for temporary state tracking, bug discovery, and potential ADR creation
4. **Update Technical Debt Tracking**: Mark selected items as "🔄 In Progress" before starting refactoring
5. **Prepare Decision Matrix**: Review 4-tier bug severity decision process for systematic bug discovery

## Metrics and Evaluation

- **Debt Identification Rate**: Number of new debt items identified per assessment cycle
- **Debt Resolution Rate**: Percentage of identified debt items resolved within planned timeframes
- **Assessment Coverage**: Percentage of codebase systematically reviewed during assessment
- **Priority Accuracy**: How well prioritized debt items align with actual development impact
- **Process Efficiency**: Time spent on assessment vs. value of debt items identified
- **Development Velocity Impact**: Correlation between debt remediation and development speed improvements
- Success criteria: Systematic identification of actionable debt items with clear prioritization and successful integration into development workflow

## Continuous Improvement

**Process Evaluation:**

- Review assessment effectiveness after each cycle
- Track correlation between identified debt and actual development friction
- Adjust assessment criteria based on debt resolution outcomes
- Refine prioritization matrix based on actual remediation impact

**Process Enhancement:**

- Improve debt identification criteria based on missed debt items discovered later
- Enhance prioritization accuracy through feedback from remediation efforts
- Streamline assessment process to reduce overhead while maintaining thoroughness
- Integrate lessons learned from debt remediation back into assessment methodology

## Related Resources

- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - Current debt registry and management strategy
- [Code Refactoring Task](../06-maintenance/code-refactoring-task.md) - Systematic approach to debt remediation
- [System Architecture Review](../01-planning/system-architecture-review.md) - Architectural assessment and improvement
- [Process Improvement Tracking](../../../process-framework-central/state-tracking/permanent/process-improvement-tracking.md) - Process effectiveness metrics and improvements
- [`technical-debt-assessment` craft skill](../../../.claude/skills/technical-debt-assessment/SKILL.md) - the assessment judgment craft (replaces the retired Assessment Criteria / Prioritization / Debt Item Creation guides); activated by the Check Recommended Skills step
