---
id: PF-TSK-002
type: Process Framework
category: Task Definition
version: 1.5
created: 2023-06-15
updated: 2026-04-04
---

# Feature Tier Assessment

## Purpose & Context

Assess the complexity tier of unassessed features to determine appropriate documentation requirements, evaluate API and database design needs, and help with planning, resource allocation, and prioritization within the development process.

## AI Agent Role

**Role**: Product Analyst
**Mindset**: User-focused, research-oriented, questioning
**Focus Areas**: User needs, requirements validation, feasibility analysis, complexity assessment
**Communication Style**: Ask clarifying questions about user value and priorities, discuss feature impact and complexity trade-offs

## When to Use

- When new features are added to the feature tracking document
- When features need to be prioritized for implementation
- When determining documentation requirements for features
- When planning resource allocation for feature development
- Before creating Technical Design Documents (TDDs)

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/01-planning/feature-tier-assessment-map.md)

- **Critical (Must Read):**

  - [Assessment Guide](../../guides/01-planning/assessment-guide.md) - Detailed guidelines for assessing feature complexity tiers
  - [Documentation Tiers README](../../../doc/documentation-tiers/README.md) - Definitions of each complexity tier and their criteria
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - [Feature Implementation State Template](../../templates/04-implementation/feature-implementation-state-template.md) - Full template for Tier 2/3 features
  - [Feature Implementation State Lightweight Template](../../templates/04-implementation/feature-implementation-state-lightweight-template.md) - Lightweight template for Tier 1 features

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - List of features and their current assessment status

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
>
> **⚠️ MANDATORY: Use the PowerShell automation script for ALL assessment file creation. Manual file creation is prohibited as it breaks ID tracking and causes conflicts.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. Review the [Assessment Guide](../../guides/01-planning/assessment-guide.md) for detailed instructions on how to perform assessments
2. Identify features without tier assessments in the [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) document
3. Select a feature or group of similar features to assess

### Execution

4. **ALWAYS use the provided PowerShell script** to create assessment documents:

   ```powershell
   # Navigate to the documentation tiers directory
   cd ../../../doc/documentation-tiers

   # Create a new assessment document (ALL THREE PARAMETERS ARE MANDATORY)
   ../../scripts/file-creation/01-planning/New-Assessment.ps1 -FeatureId "X.X.X" -FeatureName "Feature Name" -FeatureDescription "Brief description of what the feature does"
   ```

   **⚠️ CRITICAL**: All three parameters are mandatory:

   - `-FeatureId`: The feature ID in format X.X.X (e.g., 1.2.3)
   - `-FeatureName`: The human-readable name of the feature
   - `-FeatureDescription`: A brief description of what the feature does

5. Complete the assessment by evaluating and scoring each complexity factor
6. **Evaluate API and Database Design Requirements** (see [Design Requirements Evaluation](#design-requirements-evaluation) section below)
7. Calculate the normalized score and determine the appropriate documentation tier
8. **🚨 CHECKPOINT**: Present assessment scores, tier assignment, and design requirements to human partner for approval
9. Verify the assessment meets quality standards

### Create Feature Implementation State File

10. **Create the Feature Implementation State file** using the automation script. The tier determines which template variant to use:

    ```powershell
    # Tier 1 (lightweight template — 7 sections)
    New-FeatureImplementationState.ps1 -FeatureName "[name]" -FeatureId "X.Y.Z" -Lightweight -Description "[description]"

    # Tier 2/3 (full template — 10 sections)
    New-FeatureImplementationState.ps1 -FeatureName "[name]" -FeatureId "X.Y.Z" -Description "[description]"
    ```

    - Script location: `/process-framework/scripts/file-creation/04-implementation/New-FeatureImplementationState.ps1`
    - Creates file at: `/doc/state-tracking/features/[X.Y.Z]-[name]-implementation-state.md`
    - Automatically links the file in [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)
    - **For retrospective onboarding**: Add `-ImplementationMode "Retrospective Analysis"` to set the correct metadata

    > **Why here?** The tier determines the appropriate template variant. Creating the state file immediately after assessment ensures downstream tasks (analysis, design, implementation planning) have a state file ready to enrich.

11. **🚨 CHECKPOINT**: Present the created state file to human partner for confirmation

### Finalization

12. **Run the automated update script** to update feature tracking:

   ```powershell
   # Navigate to the documentation tiers directory (if not already there)
   cd doc/documentation-tiers

   # Run the automated update script (AssessmentId and FeatureId are required)
   .\Update-FeatureTrackingFromAssessment.ps1 -FeatureId "X.X.X" -AssessmentId "ART-ASS-XXX"
   ```

   **⚠️ CRITICAL**: This script automatically updates the feature tracking document with:

   - Status change from "⬜ Needs Assessment" to next status:
     - Tier 2+: `📋 Needs FDD`
     - Tier 1 with DB Design = Yes: `🗄️ Needs DB Design`
     - Tier 1 with API Design = Yes (no DB): `🔌 Needs API Design`
     - Tier 1 with neither: `📝 Needs TDD`
   - Documentation tier emoji (🔵/🟠/🔴) and assessment link
   - UI Design column with "Yes" or "No" based on the assessment
   - API Design column with "Yes" or "No" based on the assessment
   - DB Design column with "Yes" or "No" based on the assessment

   **Manual verification**: After running the script, verify the feature tracking document was updated correctly

13. **For existing assessments missing Design Requirements Evaluation**: If updating an assessment that was created before the Design Requirements Evaluation section was added, add the section to the existing assessment file using the template format from the [Assessment Guide](../../guides/01-planning/assessment-guide.md#design-requirements-evaluation)
14. Document any insights or lessons learned from the assessment process
15. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Assessment Document** - New document in the `../../../doc/documentation-tiers/assessments` directory with tier assignment, design requirements evaluation, and rationale
- **Feature Implementation State File** - Created at `/doc/state-tracking/features/` using lightweight template (Tier 1) or full template (Tier 2/3). This permanent living document is enriched by downstream tasks
- **Updated Feature Tracking** - Feature entry in the tracking document updated with assessment results, including API Design and DB Design requirements

## State Tracking

### New State Files Created

- **Feature Implementation State File** (PERMANENT):
  - Location: `/doc/state-tracking/features/[X.Y.Z]-[name]-implementation-state.md`
  - Template: Lightweight (Tier 1) or Full (Tier 2/3)
  - Lifecycle: Permanent — enriched by downstream tasks (analysis, design, implementation)

### Existing State Files Updated

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Update with:
  - Status change from "⬜ Needs Assessment" to "📋 Needs FDD" (Tier 2+) or next design status (Tier 1: `🗄️`/`🔌`/`📝` based on DB/API columns)
  - Documentation tier emoji (🔵/🟠/🔴)
  - UI Design column with "Yes" or "No"
  - API Design column with "Yes" or "No"
  - DB Design column with "Yes" or "No"
  - Link to the assessment document
  - Link to the Feature Implementation State file (auto-created by script)

## ⚠️ MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Assessment document created in the correct location with proper formatting
  - [ ] Assessment includes scores for all applicable complexity factors
  - [ ] Assessment includes clear rationale for each score
  - [ ] Assessment includes Design Requirements Evaluation section with UI Design, API Design, and DB Design evaluations
  - [ ] UI Design requirement clearly marked as "Yes" or "No" with justification
  - [ ] API Design requirement clearly marked as "Yes" or "No" with justification
  - [ ] DB Design requirement clearly marked as "Yes" or "No" with justification
  - [ ] Final tier assignment is correct based on the normalized score
- [ ] **Verify Feature Implementation State File Created**:
  - [ ] State file created at `/doc/state-tracking/features/` with correct naming
  - [ ] Lightweight template used for Tier 1; full template used for Tier 2/3
  - [ ] For retrospective onboarding: `implementation_mode: Retrospective Analysis` set in metadata
  - [ ] State file linked in Feature Tracking (auto-created by script)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Feature Tracking document status updated from "⬜ Needs Assessment" to "📋 Needs FDD" (Tier 2+) or next design status (Tier 1: `🗄️`/`🔌`/`📝` based on DB/API columns)
  - [ ] Feature Tracking document updated with correct tier emoji and assessment link
  - [ ] Feature Tracking document UI Design column updated with "Yes" or "No" based on assessment
  - [ ] Feature Tracking document API Design column updated with "Yes" or "No" based on assessment
  - [ ] Feature Tracking document DB Design column updated with "Yes" or "No" based on assessment
  - [ ] For existing assessments: Added Design Requirements Evaluation section if it was missing
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-002" and context "Feature Tier Assessment"

## Design Requirements Evaluation

For detailed criteria on evaluating UI Design, API Design, and Database Design requirements, see the [Assessment Guide — Design Requirements Evaluation](../../guides/01-planning/assessment-guide.md#design-requirements-evaluation) section.

## Next Tasks

**📋 For guidance on choosing the next task, see the [Task Transition Registry](../../infrastructure/task-transition-registry.md)**

**Based on Tier Assessment Result:**

- **Tier 1 (🔵)**: [Feature Implementation Planning](../04-implementation/feature-implementation-planning-task.md) - Simple features can be implemented with lightweight design
- **Tier 2 (🟠)**: A-planning/fdd-creation-task.md) - Moderate complexity requires functional design documentation before technical design
- **Tier 3 (🔴)**: A-planning/fdd-creation-task.md) - Complex features need comprehensive functional design documentation before technical design

**Continuous Tasks:**

## Related Resources

- [Documentation Tier Assignments README](../../../doc/documentation-tiers/README.md) - Comprehensive overview of the tier system
- [Normalized Scoring System](/doc/documentation-tiers/README.md#normalized-scoring-system) - Details on how the scoring system works

- [Task Creation and Improvement Guide](../../guides/support/task-creation-guide.md) - Guide for creating and improving tasks
