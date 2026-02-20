---
id: PF-TSK-002
type: Process Framework
category: Task Definition
version: 1.3
created: 2023-06-15
updated: 2025-08-02
task_type: Discrete
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

- [Feature Tier Assessment Context Map](/doc/process-framework/visualization/context-maps/01-planning/feature-tier-assessment-map.md) - Visual guide to the components relevant to this task

- **Critical (Must Read):**

  - [Assessment Guide](../guides/guides/assessment-guide.md) - Detailed guidelines for assessing feature complexity tiers
  - [Documentation Tiers README](../methodologies/documentation-tiers/README.md) - Definitions of each complexity tier and their criteria
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../state-tracking/permanent/feature-tracking.md) - List of features and their current assessment status

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the PowerShell automation script for ALL assessment file creation. Manual file creation is prohibited as it breaks ID tracking and causes conflicts.**

### Preparation

1. Review the [Assessment Guide](../guides/guides/assessment-guide.md) for detailed instructions on how to perform assessments
2. Identify features without tier assessments in the [Feature Tracking](../state-tracking/permanent/feature-tracking.md) document
3. Select a feature or group of similar features to assess

### Execution

4. **ALWAYS use the provided PowerShell script** to create assessment documents:

   ```powershell
   # Navigate to the documentation tiers directory
   cd ../../methodologies/documentation-tiers

   # Create a new assessment document (ALL THREE PARAMETERS ARE MANDATORY)
   ../../scripts/file-creation/New-Assessment.ps1 -FeatureId "X.X.X" -FeatureName "Feature Name" -FeatureDescription "Brief description of what the feature does"
   ```

   **⚠️ CRITICAL**: All three parameters are mandatory:

   - `-FeatureId`: The feature ID in format X.X.X (e.g., 1.2.3)
   - `-FeatureName`: The human-readable name of the feature
   - `-FeatureDescription`: A brief description of what the feature does

5. Complete the assessment by evaluating and scoring each complexity factor
6. **Evaluate API and Database Design Requirements** (see [Design Requirements Evaluation](#design-requirements-evaluation) section below)
7. Calculate the normalized score and determine the appropriate documentation tier
8. Verify the assessment meets quality standards

### Finalization

9. **Run the automated update script** to update feature tracking:

   ```powershell
   # Navigate to the documentation tiers directory (if not already there)
   cd doc/process-framework/methodologies/documentation-tiers

   # Run the automated update script (AssessmentId and FeatureId are required)
   .\Update-FeatureTrackingFromAssessment.ps1 -FeatureId "X.X.X" -AssessmentId "ART-ASS-XXX"
   ```

   **⚠️ CRITICAL**: This script automatically updates the feature tracking document with:

   - Status change from "⬜ Not Started" to "📊 Assessment Created"
   - Documentation tier emoji (🔵/🟠/🔴) and assessment link
   - UI Design column with "Yes" or "No" based on the assessment
   - API Design column with "Yes" or "No" based on the assessment
   - DB Design column with "Yes" or "No" based on the assessment

   **Manual verification**: After running the script, verify the feature tracking document was updated correctly

10. **For existing assessments missing Design Requirements Evaluation**: If updating an assessment that was created before the Design Requirements Evaluation section was added, add the section to the existing assessment file using the template format from the [Assessment Guide](../guides/guides/assessment-guide.md#design-requirements-evaluation)
11. Document any insights or lessons learned from the assessment process
12. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Assessment Document** - New document in the `../../methodologies/documentation-tiers/assessments/` directory with tier assignment, design requirements evaluation, and rationale
- **Updated Feature Tracking** - Feature entry in the tracking document updated with assessment results, including API Design and DB Design requirements

## State Tracking

The following state files must be updated as part of this task:

- [Feature Tracking](../state-tracking/permanent/feature-tracking.md) - Update with:
  - Status change from "⬜ Not Started" to "📊 Assessment Created"
  - Documentation tier emoji (🔵/🟠/🔴)
  - UI Design column with "Yes" or "No"
  - API Design column with "Yes" or "No"
  - DB Design column with "Yes" or "No"
  - Link to the assessment document

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

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
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Feature Tracking document status updated from "⬜ Not Started" to "📊 Assessment Created"
  - [ ] Feature Tracking document updated with correct tier emoji and assessment link
  - [ ] Feature Tracking document UI Design column updated with "Yes" or "No" based on assessment
  - [ ] Feature Tracking document API Design column updated with "Yes" or "No" based on assessment
  - [ ] Feature Tracking document DB Design column updated with "Yes" or "No" based on assessment
  - [ ] For existing assessments: Added Design Requirements Evaluation section if it was missing
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-002" and context "Feature Tier Assessment"

## Design Requirements Evaluation

As part of the assessment process, evaluate whether the feature requires dedicated API and/or Database design documentation. This evaluation helps determine if specialized design tasks are needed before implementation.

### UI Design Requirements

Evaluate if the feature requires **UI Design** documentation by considering:

**Answer "Yes" if the feature involves:**

- Creating new screens or major screen layouts
- New UI components not in the existing design system
- Complex user interaction flows or navigation patterns
- Custom visual design requirements (animations, transitions, illustrations)
- Significant changes to existing UI patterns
- Responsive design adaptations across multiple breakpoints
- Platform-specific UI adaptations (iOS, Android, Web differences)
- Accessibility requirements beyond standard implementations
- Complex form designs with multi-step flows
- Visual data presentation (charts, graphs, custom visualizations)

**Answer "No" if the feature:**

- Only uses existing, well-documented UI components without modification
- Is purely backend-focused with no UI changes
- Makes minor text or content updates to existing screens
- Uses standard UI patterns already established in the app
- Has minimal or no user interface requirements

**Examples:**

- **Yes**: "Escape room detail screen" (new screen layout with custom components)
- **Yes**: "Booking flow redesign" (complex multi-step user flow)
- **Yes**: "Points & leveling system" (custom visual progress indicators)
- **No**: "Database migration" (backend-only feature)
- **No**: "Bug fix for null pointer" (code fix with no UI changes)

### API Design Requirements

Evaluate if the feature requires **API Design** documentation by considering:

**Answer "Yes" if the feature involves:**

- Creating new API endpoints or modifying existing ones
- Complex API request/response structures
- API integration with external services (payment providers, booking systems, maps, etc.)
- Authentication or authorization changes affecting APIs
- API versioning or backward compatibility concerns
- Complex data validation or transformation in API layers
- Real-time API features (WebSocket, Server-Sent Events)

**Answer "No" if the feature:**

- Only uses existing, well-documented APIs without modification
- Is purely UI-focused with no backend API changes
- Uses simple, standard CRUD operations on existing endpoints
- Has minimal or no API interaction requirements

**Examples:**

- **Yes**: "Credit card integration" (new payment API endpoints)
- **Yes**: "Bookeo integration" (complex external API integration)
- **No**: "Responsive design" (UI-only changes)
- **No**: "FAQ section" (static content display)

### Database Design Requirements

Evaluate if the feature requires **Database Design** documentation by considering:

**Answer "Yes" if the feature involves:**

- Creating new database tables or collections
- Modifying existing database schemas (adding/removing/changing columns)
- Complex database relationships or foreign key constraints
- Database indexing strategies for performance
- Data migration requirements
- Complex queries or stored procedures
- Database-level security or access control changes
- Data archiving or retention policies

**Answer "No" if the feature:**

- Only reads from existing database structures without changes
- Uses existing tables with simple CRUD operations
- Is purely UI-focused with no data storage changes
- Uses existing data models without modification

**Examples:**

- **Yes**: "Friends management" (new friendship tables and relationships)
- **Yes**: "Points & leveling system" (new tables for points, levels, achievements)
- **No**: "Loading state informational content" (UI enhancement only)
- **No**: "Review reminder emails" (uses existing review data)

### Documentation in Assessment

Include the design requirements evaluation in the assessment document by adding a new section:

```markdown
## Design Requirements Evaluation

### UI Design Required

- [ ] Yes - [Justification for why UI design is needed]
- [ ] No - [Brief explanation of why UI design is not required]

### API Design Required

- [ ] Yes - [Justification for why API design is needed]
- [ ] No - [Brief explanation of why API design is not required]

### Database Design Required

- [ ] Yes - [Justification for why database design is needed]
- [ ] No - [Brief explanation of why database design is not required]
```

### Updating Feature Tracking

When updating the feature tracking document:

- **UI Design Column**: Enter "Yes" or "No" based on your evaluation
- **API Design Column**: Enter "Yes" or "No" based on your evaluation
- **DB Design Column**: Enter "Yes" or "No" based on your evaluation
- If "Yes" for any column, the corresponding design task should be completed before or during implementation

## Next Tasks

**📋 For guidance on choosing the next task, see the [Task Transition Guide](../guides/guides/task-transition-guide.md)**

**Based on Tier Assessment Result:**

- **Tier 1 (🔵)**: [Feature Implementation Planning](../04-implementation/feature-implementation-planning-task.md) - Simple features can be implemented with lightweight design
- **Tier 2 (🟠)**: A-planning/fdd-creation-task.md) - Moderate complexity requires functional design documentation before technical design
- **Tier 3 (🔴)**: A-planning/fdd-creation-task.md) - Complex features need comprehensive functional design documentation before technical design

**Continuous Tasks:**

## Related Resources

- [Documentation Tier Assignments README](../methodologies/documentation-tiers/README.md) - Comprehensive overview of the tier system
- <!-- [Normalized Scoring System Guide](../methodologies/documentation-tiers/normalized-scoring-guide.md) - File not found --> - Details on how the scoring system works
- <!-- [Assessment Best Practices](../guides/assessment-best-practices.md) - File not found --> - Tips for accurate assessments
- [Task Creation and Improvement Guide](../support/task-creation-guide.md) - Guide for creating and improving tasks
