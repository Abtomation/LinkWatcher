---
id: PF-TSK-023
type: Process Framework
category: Task Definition
version: 1.1
created: 2025-07-24
updated: 2026-03-04
task_type: Cyclical
---

# Technical Debt Assessment Task

## Purpose & Context

Systematic approach to identifying, categorizing, and prioritizing technical debt across the codebase

## AI Agent Role

**Role**: Technical Lead
**Mindset**: Design-first thinking, risk-aware, collaborative
**Focus Areas**: Technical specifications, risk mitigation, code quality assessment, debt prioritization
**Communication Style**: Present design options with pros/cons and risk assessment, ask about technical constraints and quality standards

## When to Use

- Before major releases to assess debt that could impact release stability
- After significant feature development to identify newly introduced debt
- On scheduled intervals (monthly or quarterly) for systematic assessment
- When planning refactoring efforts or technical improvement initiatives
- When technical debt becomes a blocker for new feature development

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/cyclical/technical-debt-assessment-task-map.md)

- **Critical (Must Read):**

  - [Technical Debt Tracking](../../../doc/product-docs/state-tracking/permanent/technical-debt-tracking.md) - Current debt registry and management strategy
  - **Current Codebase** - Source code files in scope for assessment (lib/, test/, integration_test/)
  - **Recent Change Logs** - Git commit history and recent development activity

- **Important (Load If Space):**

  - [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md) - Dimension definitions and abbreviations for tagging debt items with their primary dimension (AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI, TST)
  - [Architecture Documentation](/doc/product-docs/technical/architecture/) - System architecture and design patterns
  - [Coding Standards](/process-framework/guides/03-testing) - Project coding standards and best practices
  - **Test Coverage Reports** - Current test coverage metrics and gaps
  - [Bug Tracking](../../../doc/product-docs/state-tracking/permanent/bug-tracking.md) - Known bugs that may indicate debt areas
  - [Feature Tracking](../../../doc/product-docs/state-tracking/permanent/feature-tracking.md) - Recent feature development that may have introduced debt

- **Reference Only (Access When Needed):**
  - **Performance Metrics** - Application performance data and bottlenecks
  - **Developer Feedback** - Team feedback on code maintainability and development friction
  - [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - Process effectiveness metrics
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the appropriate automation tools where indicated.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Define Assessment Scope**: Determine assessment scope (full codebase, specific modules, or feature areas based on recent development activity)
2. **Review Context**: Load current [Technical Debt Tracking](../../../doc/product-docs/state-tracking/permanent/technical-debt-tracking.md) and review recent changes, known issues, and previous assessments
3. **Prepare Assessment Tools**: Set up assessment templates and tracking documents for systematic evaluation
4. **🚨 CHECKPOINT**: Present assessment scope, context findings, and initial observations to human partner

### Assessment Phase

5. **Systematic Code Analysis**: Review code areas using the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md) as the lens for identifying debt. Scan for issues across these categories (dimension abbreviation in parentheses):

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

6. **Document Debt Items**: For each identified debt item, document:
   - Detailed description and location
   - **Primary dimension(s)**: Tag with standard dimension abbreviation(s) from the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md) — AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI, or TST (Testing). This replaces the free-text category and enables prioritization by dimension impact (e.g., SE-tagged debt ranks higher)
   - Severity assessment
   - Impact on development velocity, maintainability, and system stability
   - Estimated effort required for remediation
   - Risk assessment if left unaddressed

   > **⚠️ Data Quality**: Before finalizing each debt item description, verify it against the actual source code. Descriptions must accurately reflect the current state of the code — not assumptions from static analysis, documentation, or analogy with similar items. Inaccurate descriptions waste remediation effort downstream (ref: PF-IMP-088).

7. **🚨 CHECKPOINT**: Present identified debt items for review before prioritization

### Prioritization Phase

8. **Apply Priority Matrix**: Use impact vs. effort matrix to prioritize debt items:

   - **Critical**: High impact, any effort - must address before next release
   - **High**: High impact, low-medium effort - address in next development cycle
   - **Medium**: Medium impact, low effort OR high impact, high effort - address when convenient
   - **Low**: Low impact, any effort - nice to fix but not urgent

9. **Risk Assessment**: Evaluate risks of leaving high-priority debt unaddressed
10. **Create Remediation Plan**: Develop actionable plan for addressing prioritized debt items with timeline recommendations
11. **🚨 CHECKPOINT**: Present prioritized matrix and remediation plan to human partner for approval

### Finalization

12. **🤖 AUTOMATED: Update Technical Debt Registry**: Use automation to add new debt items to [Technical Debt Tracking](../../../doc/product-docs/state-tracking/permanent/technical-debt-tracking.md):

   **OPTION A - Full Automation (Recommended):**

   ```powershell
   # Process all debt items from the assessment automatically
   process-framework/scripts/update/Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PF-TDA-XXX"
   ```

   **OPTION B - Individual Item Addition:**

   ```powershell
   # Add individual debt items manually (use dimension abbreviation for -Category: AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI, TST)
   process-framework/scripts/update/Update-TechDebt.ps1 -Add -Description "Description" -Category "PE" -Location "Location" -Priority "Priority" -EstimatedEffort "Effort" -DebtItemId "PF-TDI-XXX" -AssessmentId "PF-TDA-XXX"
   ```

   **Automation Benefits:**

   - Automatically assigns next available TD### ID to each debt item
   - References the assessment ID (PF-TDA-XXX) in the Assessment ID column
   - Updates individual debt item files (PF-TDI-XXX) with assigned registry ID
   - Marks debt items as "Added" in their Registry Integration section
   - Maintains bidirectional linking between assessments and registry

13. **Generate Assessment Report**: Create comprehensive assessment report with findings, priorities, and recommendations
14. **Plan Integration**: Identify how debt remediation can be integrated into upcoming development cycles
15. **🚨 CHECKPOINT**: Review complete assessment report with human partner before marking task complete
16. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

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
- **Updated Technical Debt Registry** - Enhanced [Technical Debt Tracking](../../../doc/product-docs/state-tracking/permanent/technical-debt-tracking.md) with newly identified debt items
- **Debt Prioritization Matrix** - Visual representation of debt priority based on impact/effort analysis (included in assessment report)
- **Remediation Roadmap** - Actionable plan for addressing prioritized debt items with timeline recommendations (included in assessment report)
- **Integration Recommendations** - Specific guidance on integrating debt remediation into upcoming development cycles

## State Tracking

The following state files must be updated as part of this task:

- [Technical Debt Tracking](../../../doc/product-docs/state-tracking/permanent/technical-debt-tracking.md) - Add newly identified debt items with complete metadata (ID, description, category, location, priority, effort estimation, status)
- [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - Track assessment effectiveness and process improvements identified during the assessment
- [Feature Tracking](../../../doc/product-docs/state-tracking/permanent/feature-tracking.md) - Update with debt-related blockers or considerations that may impact feature development

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Technical Debt Assessment Report created with comprehensive findings and analysis
  - [ ] Debt Prioritization Matrix completed with impact/effort analysis
  - [ ] Remediation Roadmap created with actionable timeline recommendations
  - [ ] Integration Recommendations documented for upcoming development cycles
- [ ] **🤖 AUTOMATED: Update State Files**: Ensure all state tracking files have been updated using automation scripts
  - [ ] **AUTOMATED**: [Technical Debt Tracking](../../../doc/product-docs/state-tracking/permanent/technical-debt-tracking.md) updated with newly identified debt items using `Update-TechnicalDebtFromAssessment.ps1`
  - [ ] **AUTOMATED**: All debt items assigned TD### IDs and linked to assessment ID (PF-TDA-XXX) via automation
  - [ ] **AUTOMATED**: Individual debt item files (PF-TDI-XXX) updated with registry IDs and marked as "Added" via automation
  - [ ] **MANUAL**: [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) updated with assessment effectiveness metrics
  - [ ] **MANUAL**: [Feature Tracking](../../../doc/product-docs/state-tracking/permanent/feature-tracking.md) updated with debt-related considerations (if applicable)
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-023" and context "Technical Debt Assessment"

## Next Tasks

- [**Code Refactoring Task**](../06-maintenance/code-refactoring-task.md) - Use prioritized debt items from assessment for systematic remediation
- [**System Architecture Review**](../01-planning/system-architecture-review.md) - Address architectural debt identified during assessment
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - Entry point to consider debt remediation during new feature development (leads to decomposed tasks PF-TSK-051 through PF-TSK-055)
- [**Process Improvement Task**](../support/process-improvement-task.md) - Improve assessment process based on effectiveness metrics

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

- [Technical Debt Tracking](../../../doc/product-docs/state-tracking/permanent/technical-debt-tracking.md) - Current debt registry and management strategy
- [Code Refactoring Task](../06-maintenance/code-refactoring-task.md) - Systematic approach to debt remediation
- [System Architecture Review](../01-planning/system-architecture-review.md) - Architectural assessment and improvement
- [Process Improvement Tracking](../../state-tracking/permanent/process-improvement-tracking.md) - Process effectiveness metrics and improvements
