---
id: PF-TEM-034
type: Process Framework
category: Template
version: 1.0
created: 2025-08-15
updated: 2025-08-15
usage_context: Process Framework - Validation Creation
description: Template for foundational codebase validation reports
creates_document_category: Validation
creates_document_prefix: PF-VAL
creates_document_type: Process Framework
creates_document_version: 1.0
template_for: Validation
---

# Validation Report Template

## Purpose

This template provides a standardized structure for creating foundational codebase validation reports. It supports all 6 validation types in the foundational validation framework and ensures consistent reporting across validation sessions.

**Note**: This template is designed for individual validation type reports that populate specific cells in the validation matrix. Each report focuses on one validation type applied to a group of features.

## Template Usage

To create a validation report using this template:

1. **Copy this template** to the appropriate validation subdirectory:

   - `doc/process-framework/validation/reports/architectural-consistency/`
   - `doc/process-framework/validation/reports/code-quality/`
   - `doc/process-framework/validation/reports/integration-dependencies/`
   - `doc/process-framework/validation/reports/documentation-alignment/`
   - `doc/process-framework/validation/reports/extensibility-maintainability/`
   - `doc/process-framework/validation/reports/ai-agent-continuity/`

2. **Name the file** using the pattern: `PF-VAL-XXX-[validation-type]-features-[feature-range].md`

   - Example: `PF-VAL-001-architectural-consistency-features-0.2.1-0.2.3.md`

3. **Replace all placeholder text** (text in [square brackets])
4. **Customize validation criteria** based on the specific validation type
5. **Remove instructional comments** (text between <!-- and -->)
6. **Fill in all required sections**

## Document Template

```markdown
---
id: [PF-VAL-XXX - will be assigned from ID registry]
type: Process Framework
category: Validation Report
version: 1.0
created: [YYYY-MM-DD]
updated: [YYYY-MM-DD]
validation_type:
  [
    architectural-consistency|code-quality|integration-dependencies|documentation-alignment|extensibility-maintainability|ai-agent-continuity,
  ]
features_validated: [e.g., "0.2.1, 0.2.2, 0.2.3"]
validation_session: [Session number for this validation type]
---

# [Validation Type] Validation Report - Features [Feature Range]

## Executive Summary

**Validation Type**: [Validation Type Name]
**Features Validated**: [List of features, e.g., 0.2.1, 0.2.2, 0.2.3]
**Validation Date**: [Date]
**Overall Score**: [X.X/4.0]
**Status**: [PASS/CONDITIONAL_PASS/FAIL]

### Key Findings

- [Brief summary of major findings]
- [Critical issues identified]
- [Strengths observed]

### Immediate Actions Required

- [ ] [High priority action item 1]
- [ ] [High priority action item 2]
- [ ] [High priority action item 3]

## Validation Scope

### Features Included

| Feature ID | Feature Name   | Implementation Status | Validation Focus             |
| ---------- | -------------- | --------------------- | ---------------------------- |
| [0.2.X]    | [Feature Name] | [Implemented/Partial] | [Specific aspects validated] |
| [0.2.Y]    | [Feature Name] | [Implemented/Partial] | [Specific aspects validated] |

### Validation Criteria Applied

[Customize this section based on validation type - see criteria sections below]

## Validation Results

### Overall Scoring

| Criterion     | Score | Weight   | Weighted Score | Notes        |
| ------------- | ----- | -------- | -------------- | ------------ |
| [Criterion 1] | [X/4] | [%]      | [X.X]          | [Brief note] |
| [Criterion 2] | [X/4] | [%]      | [X.X]          | [Brief note] |
| [Criterion 3] | [X/4] | [%]      | [X.X]          | [Brief note] |
| **TOTAL**     |       | **100%** | **[X.X/4.0]**  |              |

### Scoring Scale

- **4 - Excellent**: Exceeds expectations, exemplary implementation
- **3 - Good**: Meets expectations, solid implementation
- **2 - Acceptable**: Meets minimum requirements, minor improvements needed
- **1 - Poor**: Below expectations, significant improvements required

## Detailed Findings

### [Feature 0.2.X] - [Feature Name]

#### Strengths

- [Positive finding 1]
- [Positive finding 2]

#### Issues Identified

| Severity          | Issue               | Impact               | Recommendation       |
| ----------------- | ------------------- | -------------------- | -------------------- |
| [High/Medium/Low] | [Issue description] | [Impact description] | [Recommended action] |

#### Validation Details

[Detailed analysis specific to this feature]

### [Feature 0.2.Y] - [Feature Name]

#### Strengths

- [Positive finding 1]
- [Positive finding 2]

#### Issues Identified

| Severity          | Issue               | Impact               | Recommendation       |
| ----------------- | ------------------- | -------------------- | -------------------- |
| [High/Medium/Low] | [Issue description] | [Impact description] | [Recommended action] |

#### Validation Details

[Detailed analysis specific to this feature]

## Recommendations

### Immediate Actions (High Priority)

1. **[Action Item 1]**

   - **Description**: [What needs to be done]
   - **Rationale**: [Why this is important]
   - **Estimated Effort**: [Time/complexity estimate]
   - **Dependencies**: [What needs to be done first]

2. **[Action Item 2]**
   - **Description**: [What needs to be done]
   - **Rationale**: [Why this is important]
   - **Estimated Effort**: [Time/complexity estimate]
   - **Dependencies**: [What needs to be done first]

### Medium-Term Improvements

1. **[Improvement 1]**
   - **Description**: [What could be enhanced]
   - **Benefits**: [Expected improvements]
   - **Estimated Effort**: [Time/complexity estimate]

### Long-Term Considerations

1. **[Consideration 1]**
   - **Description**: [Strategic improvement]
   - **Benefits**: [Long-term value]
   - **Planning Notes**: [When to address]

## Cross-Feature Analysis

### Patterns Observed

- **Positive Patterns**: [Consistent good practices across features]
- **Negative Patterns**: [Recurring issues across features]
- **Inconsistencies**: [Variations in implementation approaches]

### Integration Points

- [Analysis of how features work together]
- [Potential integration issues identified]
- [Recommendations for better integration]

## Next Steps

### Follow-Up Validation

- [ ] **Re-validation Required**: [List features needing re-validation after fixes]
- [ ] **Additional Validation**: [Other validation types recommended for these features]

### Tracking and Monitoring

- [ ] **Update Validation Tracking**: Record results in [PF-VTR-XXX]
- [ ] **Schedule Follow-Up**: [When to check progress on recommendations]

## Appendices

### Appendix A: Validation Methodology

[Brief description of how validation was conducted]

### Appendix B: Reference Materials

- [List of documents, code files, and other materials reviewed]

### Appendix C: Detailed Evidence

[Supporting evidence for findings - code snippets, screenshots, etc.]

---

## Validation Sign-Off

**Validator**: [AI Agent Role/Session ID]
**Validation Date**: [Date]
**Report Status**: [Draft/Final]
**Next Review Date**: [Date for follow-up]
```

## Validation Type Specific Criteria

### Architectural Consistency Validation

Customize the "Validation Criteria Applied" section with:

- **Design Pattern Adherence**: Consistency with established architectural patterns
- **Component Structure**: Proper separation of concerns and layering
- **Interface Consistency**: Standardized interfaces and contracts
- **Dependency Management**: Proper dependency injection and management
- **Code Organization**: Logical file and directory structure

### Code Quality & Standards Validation

Customize the "Validation Criteria Applied" section with:

- **Code Style Compliance**: Adherence to Dart/Flutter style guidelines
- **Code Complexity**: Cyclomatic complexity and maintainability metrics
- **Error Handling**: Comprehensive and consistent error handling
- **Documentation Quality**: Code comments and documentation completeness
- **Test Coverage**: Unit test coverage and quality

### Integration & Dependencies Validation

Customize the "Validation Criteria Applied" section with:

- **Service Integration**: Proper integration with Supabase and external services
- **State Management**: Correct Riverpod usage and state handling
- **Navigation Integration**: Proper GoRouter implementation
- **Data Flow**: Correct data flow between components
- **API Consistency**: Consistent API usage patterns

### Documentation Alignment Validation

Customize the "Validation Criteria Applied" section with:

- **TDD Alignment**: Implementation matches Technical Design Documents
- **FDD Alignment**: Implementation matches Functional Design Documents
- **API Documentation**: Code matches API specifications
- **Architecture Compliance**: Implementation follows architectural decisions
- **Documentation Currency**: Documentation reflects current implementation

### Extensibility & Maintainability Validation

Customize the "Validation Criteria Applied" section with:

- **Modularity**: Components are properly modularized and reusable
- **Extensibility Points**: Clear extension points for future development
- **Configuration Management**: Proper environment and configuration handling
- **Scalability Considerations**: Code structure supports scaling
- **Refactoring Safety**: Code structure supports safe refactoring

### AI Agent Continuity Validation

Customize the "Validation Criteria Applied" section with:

- **Context Window Optimization**: Code structure fits AI agent context limitations
- **Documentation Clarity**: Clear documentation for AI agent understanding
- **Naming Conventions**: Descriptive and consistent naming
- **Code Readability**: Code is easily understood by AI agents
- **Continuation Points**: Clear handoff points for multi-session work

## Related Resources

- [Foundational Codebase Validation Concept](/doc/process-framework/proposals/foundational-codebase-validation-concept.md)
- [Validation Framework Tasks](/doc/process-framework/tasks/05-validation/) (validation task definitions)
- [Template Development Guide](/doc/process-framework/guides/guides/template-development-guide.md)
- [Feature Tracking](/doc/process-framework/state-tracking/permanent/feature-tracking.md)

---
