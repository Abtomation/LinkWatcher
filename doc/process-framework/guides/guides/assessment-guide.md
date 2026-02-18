---
id: PF-GDE-008
type: Process Framework
category: Guide
version: 1.1
created: 2025-04-27
updated: 2025-01-27
---

# Documentation Tier Assessment Guide

This guide provides a structured approach for assessing the appropriate documentation tier for features in the Breakout Buddies project.

## Assessment Process

> **⚠️ CRITICAL: ALWAYS USE THE AUTOMATION SCRIPT**
>
> **DO NOT manually create assessment files.** The automation script is mandatory because it:
>
> - Ensures proper ID sequencing and prevents conflicts
> - Maintains the ../../../methodologies/documentation-tiers/config.json tracking system
> - Applies consistent formatting and metadata
> - Prevents human errors in file naming and structure
>
> **Manual file creation will cause ID conflicts and break the tracking system.**

### Initial Assessment

1. **Identify the Feature**: Locate the feature in the [Feature Tracking Document](../../../state-tracking/permanent/feature-tracking.md) and note its ID and description.

2. **Create Assessment File**: **MANDATORY: Use the provided automation script** to create an assessment file with the correct template:

   ```batch
   # Navigate to the documentation-tiers directory
   cd doc/process-framework/methodologies/documentation-tiers

   # Run the batch wrapper (recommended - handles execution policy automatically)
   ../../../../../methodologies/documentation-tiers/create-assessment.bat "1.2.3" "Feature Name" "Description of the feature"

   # To open in editor immediately after creation
   ../../../../../methodologies/documentation-tiers/create-assessment.bat "1.2.3" "Feature Name" "Description of the feature" -OpenInEditor
   ```

   > **💡 Alternative**: If the batch wrapper doesn't work, use PowerShell directly:
   >
   > ```powershell
   > pwsh -ExecutionPolicy Bypass -File ../../scripts/file-creation/New-Assessment.ps1"1.2.3" -FeatureName "Feature Name" -FeatureDescription "Description of the feature"
   > ```

   The script will:

   - Create a file with a unique artifact ID (ART-ASS-XXX)
   - Use the naming convention: `[assessment-id]-[feature-id]-[feature-name-kebab-case].md`
   - Pre-fill the template with the feature details
   - Set up the complexity assessment table
   - Add placeholders for scores and justifications
   - Open the file in your editor if the -OpenInEditor switch is used

   For more detailed examples of script usage, including how to create multiple assessment files at once, see the <!-- [Script Usage Example](../../../methodologies/documentation-tiers/script-usage-example.md) - Template/example link commented out --> document.

   **Troubleshooting Script Execution:**

   | Issue                      | Solution                                                              |
   | -------------------------- | --------------------------------------------------------------------- |
   | "Execution policy" error   | Use the batch wrapper or run with `-ExecutionPolicy Bypass`           |
   | "Script not recognized"    | Ensure you're in the correct directory and use `.\` prefix            |
   | "Module not found" error   | Verify the `scripts/scripts/DocumentManagement.psm1` file exists      |
   | "Directory.json not found" | Ensure you're running from the documentation-tiers directory          |
   | File already exists        | Check if the feature was already assessed or use different feature ID |

   **Getting Help:**

   ```powershell
   # View detailed help for the script
   Get-Help ../../scripts/file-creation/New-Assessment.ps1 -Full

   # Test what the script would do without making changes
   ../../scripts/file-creation/New-Assessment.ps1"1.2.3" -FeatureName "Test" -FeatureDescription "Test" -WhatIf
   ```

   If you prefer to create the file manually, use the template format shown in the [Example Assessments](#example-assessments) section.

3. **Complete the Assessment**: Fill out the assessment template with the feature details and complexity scores.

4. **Calculate the Normalized Score**:

   - Assign a score (1-3) for each complexity factor
   - Multiply each score by its corresponding weight (see table below)
   - Calculate the weighted average: Sum(Score × Weight) / Sum(Weights)

5. **Evaluate Design Requirements**: Determine if the feature requires API and/or Database design documentation (see [Design Requirements Evaluation](#design-requirements-evaluation) section below).

6. **Assign the Documentation Tier**:

   - 1.0-1.6: Tier 1 (Simple) 🔵
   - 1.61-2.3: Tier 2 (Moderate) 🟠
   - 2.31-3.0: Tier 3 (Complex) 🔴

7. **Document Special Considerations**: Note any special considerations that might affect the tier assignment.

8. **Update the Feature Tracking Document**: Add the documentation tier emoji with link to the assessment, plus API Design and DB Design requirements (e.g., 🔵 [Tier 1](../../../methodologies/documentation-tiers/assessment-link-placeholder)) to the feature in the [Feature Tracking Document](../../../state-tracking/permanent/feature-tracking.md).

### Reassessment During Implementation

During implementation, the actual complexity of a feature may differ from the initial assessment. Follow these steps to reassess and adjust the documentation tier when needed:

1. **Identify Discrepancies**: During implementation, note any significant differences between the initial assessment and the actual complexity encountered.

2. **Determine Need for Reassessment**: Consider a reassessment if:

   - Multiple complexity factors have changed significantly
   - New technical challenges have emerged
   - The implementation approach has substantially changed
   - The feature scope has expanded or contracted

3. **Update the Assessment File**:

   - Create a new section titled "Reassessment" in the original assessment file
   - Document the date and reason for reassessment
   - Update the complexity scores based on implementation realities
   - Recalculate the normalized score and determine the new tier

4. **Document the Adjustment**:

   - Clearly explain the reasons for the tier change
   - Note any specific implementation details that led to the adjustment
   - Update the "Special Considerations" section if needed

5. **Update Project Documentation**:

   - Update the feature tracking document with the new tier emoji
   - Communicate the change to relevant stakeholders
   - Adjust documentation plans according to the new tier requirements

6. **Review Process Improvement**:
   - Consider if the initial assessment process could be improved
   - Note any patterns in tier adjustments for future reference

For detailed guidance on the reassessment process, refer to the examples in the [Reassessment Indicators](#reassessment-indicators) section below.

## Complexity Factors Reference

Use this reference to consistently score each complexity factor. Note that each factor has a weight that reflects its importance in determining documentation needs.

| Factor                | Weight | Description                                     |
| --------------------- | ------ | ----------------------------------------------- |
| **Scope**             | 0.8    | How many components are affected by the feature |
| **State Management**  | 1.2    | Complexity of state management required         |
| **Data Flow**         | 1.5    | Complexity of data transformations and flow     |
| **Business Logic**    | 2.5    | Complexity of business rules and logic          |
| **UI Complexity**     | 0.5    | Complexity of user interface components         |
| **API Integration**   | 1.5    | Complexity of API interactions                  |
| **Database Changes**  | 1.2    | Extent of database schema changes               |
| **Security Concerns** | 2.0    | Level of security requirements                  |
| **New Technologies**  | 1.0    | Introduction of new technologies                |

### Scope (Weight: 0.8)

- **Low (1)**: Affects 1 component
- **Medium (2)**: Affects 2-3 components
- **High (3)**: Affects 4+ components

### State Management (Weight: 1.2)

- **Low (1)**: Simple local state
- **Medium (2)**: Moderate shared state
- **High (3)**: Complex global state

### Data Flow (Weight: 1.5)

- **Low (1)**: Simple data flow
- **Medium (2)**: Moderate data transformations
- **High (3)**: Complex data pipelines

### Business Logic (Weight: 2.5)

- **Low (1)**: Simple rules
- **Medium (2)**: Moderate rule complexity
- **High (3)**: Complex rules with many edge cases

### UI Complexity (Weight: 0.5)

- **Low (1)**: Standard widgets
- **Medium (2)**: Custom widgets
- **High (3)**: Complex interactive elements

### API Integration (Weight: 1.5)

- **Low (1)**: Simple API calls
- **Medium (2)**: Multiple API interactions
- **High (3)**: Complex API orchestration

### Database Changes (Weight: 1.2)

- **Low (1)**: No schema changes
- **Medium (2)**: Minor schema changes
- **High (3)**: Major schema changes

### Security Concerns (Weight: 2.0)

- **Low (1)**: Standard security
- **Medium (2)**: Moderate security needs
- **High (3)**: Complex security requirements

### New Technologies (Weight: 1.0)

- **Low (1)**: No new technologies
- **Medium (2)**: Minor new technologies
- **High (3)**: Major new technologies

## Special Considerations

Consider adjusting the tier assignment based on these special considerations:

- **High-Risk Features**: Consider using a higher tier for features with significant business or technical risk
- **Unfamiliar Domains**: Use a higher tier when working in unfamiliar domains
- **Core Infrastructure**: Features that form the foundation for many other features may warrant a higher tier
- **User-Facing Critical Features**: Features with high visibility and impact on user experience
- **Regulatory Compliance**: Features with legal or compliance implications

## Reassessment Indicators

During implementation, watch for these indicators that a documentation tier reassessment may be needed:

| Indicator                   | Description                                                        | Example                                                                                   |
| --------------------------- | ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------- |
| **Scope Expansion**         | Feature scope has significantly expanded beyond initial assessment | A simple settings screen now includes complex user preference synchronization             |
| **Technical Complexity**    | Implementation reveals unforeseen technical challenges             | What seemed like a simple API integration requires complex data transformation            |
| **State Management Growth** | State management is more complex than anticipated                  | A feature expected to use local state now requires global state with complex interactions |
| **Security Requirements**   | New security considerations have emerged                           | A feature now handles more sensitive data than initially expected                         |
| **Integration Complexity**  | Integration with other systems is more complex                     | What seemed like simple API calls now require complex orchestration and error handling    |
| **Performance Concerns**    | Implementation reveals significant performance challenges          | A feature requires complex optimization strategies not anticipated in initial assessment  |
| **Edge Cases**              | Many more edge cases discovered during implementation              | A form validation feature has many more special cases than initially expected             |
| **Architectural Impact**    | Feature has broader architectural impact than expected             | A feature requires changes to core application architecture                               |

When multiple indicators are present, it's a strong signal that reassessment is needed. Refer to the [Example Assessments](#example-assessments) section below for detailed guidance and examples of tier adjustments.

## Design Requirements Evaluation

As part of the assessment process, evaluate whether the feature requires dedicated UI/UX, API, and/or Database design documentation. This evaluation helps determine if specialized design tasks are needed before implementation.

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

Include the design requirements evaluation in the assessment document using the template section:

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

- **API Design Column**: Enter "Yes" or "No" based on your evaluation
- **DB Design Column**: Enter "Yes" or "No" based on your evaluation
- If "Yes" for either column, the corresponding design task should be completed before or during implementation

### Updating Existing Assessments

For assessment files created before the Design Requirements Evaluation section was added to the template:

1. **Identify assessments needing updates**: Look for assessment files that don't include the "Design Requirements Evaluation" section
2. **Add the missing section**: Insert the Design Requirements Evaluation section after the Complexity Assessment table and before the Documentation Tier Assignment section
3. **Complete the evaluation**: Fill out both API Design and Database Design requirements using the criteria above
4. **Update feature tracking**: Ensure the feature tracking document reflects the API Design and DB Design requirements

**Template for adding to existing assessments:**

```markdown
## Design Requirements Evaluation

### API Design Required

- [ ] Yes - [Justification for why API design is needed]
- [ ] No - [Brief explanation of why API design is not required]

### Database Design Required

- [ ] Yes - [Justification for why database design is needed]
- [ ] No - [Brief explanation of why database design is not required]
```

## Example Assessments

### Initial Assessment Example

```markdown
---
id: ART-ASS-XXX
type: Artifact
version: 1.0
created: YYYY-MM-DD
updated: YYYY-MM-DD
feature_id: 1.1.1
---

# Documentation Tier Assessment: Email + Password Registration

**Assessment ID**: ART-ASS-001
**Feature ID**: 1.1.1
**Assessment Date**: 2025-05-23
**Assessed By**: AI Assistant

## Feature Description

Implementation of a standard email and password registration system for user accounts, including form validation, error handling, and account creation.

## Complexity Assessment

| Factor                | Weight | Score | Weighted Score | Justification                                                             |
| --------------------- | ------ | ----- | -------------- | ------------------------------------------------------------------------- |
| **Scope**             | 0.8    | 2     | 1.6            | Affects authentication screens, services, and state management components |
| **State Management**  | 1.2    | 2     | 2.4            | Requires managing form state, validation state, and authentication state  |
| **Data Flow**         | 1.5    | 2     | 3.0            | Data flows between UI, validation logic, API, and storage                 |
| **Business Logic**    | 2.5    | 2     | 5.0            | Includes validation rules, error handling, and account creation logic     |
| **UI Complexity**     | 0.5    | 1     | 0.5            | Uses standard form widgets and patterns                                   |
| **API Integration**   | 1.5    | 2     | 3.0            | Requires integration with Supabase authentication API                     |
| **Database Changes**  | 1.2    | 1     | 1.2            | Uses existing authentication tables in Supabase                           |
| **Security Concerns** | 2.0    | 3     | 6.0            | Handles sensitive user credentials and requires secure storage            |
| **New Technologies**  | 1.0    | 1     | 1.0            | Uses existing technologies in the project                                 |

**Sum of Weighted Scores**: 23.7
**Sum of Weights**: 12.2
**Normalized Score**: 1.94

## Design Requirements Evaluation

### API Design Required

- [x] Yes - Feature requires new authentication API endpoints for registration, password validation, and account creation. Integration with Supabase authentication API requires careful design of request/response structures and error handling.

### Database Design Required

- [ ] No - Uses existing Supabase authentication tables and user profile structures. No new database schema changes required.

## Documentation Tier Assignment

**Assigned Tier**: Tier 2 (Moderate) 🟠 (1.61-2.3)

## Rationale

Email and password registration is a fundamental feature with moderate complexity. While it uses standard patterns, it involves significant security considerations and affects multiple components. The weighted scoring system appropriately emphasizes the security aspects of this feature, but the total score still falls within the Tier 2 range. The feature requires careful documentation of the authentication flow, data handling, and security measures.

## Special Considerations

- Security is a critical aspect of this feature, requiring careful attention to password handling and storage
- Forms the foundation for other authentication features
- User experience during errors and edge cases is important
- Must comply with data protection regulations

## Implementation Notes

- Consider implementing progressive validation for better user experience
- Ensure proper error messages for different failure scenarios
- Include rate limiting to prevent brute force attacks
- Document the authentication flow for future reference
```

### Reassessment Example

```markdown
---
id: ART-ASS-XXX
type: Artifact
version: 1.1
created: YYYY-MM-DD
updated: YYYY-MM-DD
feature_id: 1.1.1
---

# Documentation Tier Assessment: Email + Password Registration

**Assessment ID**: ART-ASS-001
**Feature ID**: 1.1.1
**Initial Assessment Date**: 2025-05-23
**Initial Assessed By**: AI Assistant
**Reassessment Date**: 2025-06-15
**Reassessed By**: AI Assistant

## Feature Description

Implementation of a standard email and password registration system for user accounts, including form validation, error handling, and account creation.

## Initial Complexity Assessment

[Initial assessment details omitted for brevity]

**Initial Assigned Tier**: Tier 2 (Moderate) 🟠

## Reassessment Reason

During implementation, we discovered that:

1. The feature needed to support multiple authentication providers (not just email/password)
2. Complex password policies were required for regulatory compliance
3. Account verification workflows were more complex than anticipated
4. The feature needed to integrate with existing user profiles in a legacy system

## Reassessment Complexity Assessment

| Factor                | Weight | Initial Score | New Score | New Weighted Score | Justification for Change                                              |
| --------------------- | ------ | ------------- | --------- | ------------------ | --------------------------------------------------------------------- |
| **Scope**             | 1.0    | 2             | 3         | 3.0                | Now affects more components due to multi-provider support             |
| **State Management**  | 1.0    | 2             | 3         | 3.0                | Complex state for multiple auth flows and verification status         |
| **Data Flow**         | 1.0    | 2             | 3         | 3.0                | Data now flows between more systems including legacy integration      |
| **Business Logic**    | 1.5    | 2             | 3         | 4.5                | Complex rules for different auth providers and verification workflows |
| **UI Complexity**     | 0.5    | 1             | 2         | 1.0                | Now requires custom UI components for different auth providers        |
| **API Integration**   | 1.0    | 2             | 3         | 3.0                | Integration with multiple auth providers and legacy systems           |
| **Database Changes**  | 1.0    | 1             | 2         | 2.0                | Required schema changes to support multiple auth providers            |
| **Security Concerns** | 2.0    | 3             | 3         | 6.0                | Still high security concerns (unchanged)                              |
| **New Technologies**  | 1.0    | 1             | 2         | 2.0                | Added OAuth libraries and integration with legacy systems             |

**New Total Weighted Score**: 27.5

## Updated Documentation Tier Assignment

**New Assigned Tier**: Tier 3 (Complex) 🔴

## Rationale for Change

The implementation revealed significantly higher complexity than initially assessed. The addition of multiple authentication providers, complex verification workflows, and integration with legacy systems increased the scope, state management complexity, and business logic requirements. The feature now touches more components and requires more sophisticated error handling and user flows.

## Updated Special Considerations

- Feature now serves as core infrastructure for all authentication methods
- Integration with legacy systems introduces additional security considerations
- Complex verification workflows require detailed documentation for maintenance
- Multiple auth providers require comprehensive testing documentation

## Implementation Impact

- Technical Design Document needs significant expansion
- Additional sequence diagrams needed for each auth provider flow
- Security considerations section needs expansion
- Testing documentation needs to cover all auth providers and edge cases
- User documentation needs to be more comprehensive
```
