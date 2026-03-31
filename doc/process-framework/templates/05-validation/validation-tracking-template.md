---
id: PF-TEM-051
type: Process Framework
category: Template
version: 1.0
created: 2025-01-28
updated: 2026-03-15
usage_context: Process Framework - Validation Tracking
description: Template for creating validation tracking state files
creates_document_category: State Tracking
creates_document_prefix: PF-STA
creates_document_type: Process Framework
creates_document_version: 1.0
template_for: Validation Tracking
---

# Feature Validation Tracking — [Round N]

## Purpose & Context

This file tracks the progress and results of the **Feature Validation Framework** across all validation types and selected features. It provides a centralized view of validation status, findings, and remediation progress.

> **Template Instructions**: Replace all `[PLACEHOLDER]` values with project-specific information. Remove this note after customization.

## Validation Framework Overview

### Validation Types

1. **Architectural Consistency Validation** — Design patterns, component structure, interfaces
2. **Code Quality & Standards Validation** — Code style, complexity, error handling, documentation
3. **Integration & Dependencies Validation** — Service integration, state management, data flow
4. **Documentation Alignment Validation** — TDD/FDD alignment, API documentation currency
5. **Extensibility & Maintainability Validation** — Modularity, extensibility points, scalability
6. **AI Agent Continuity Validation** — Context optimization, documentation clarity, readability

> **Note**: These are the default core dimensions. Add or remove dimensions based on your project's needs. See the [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) for the complete Dimension Catalog.
>
> **Dimension Source**: Start from each feature's **Dimension Profile** in its implementation state file (Section 7). If no profile exists (legacy features), evaluate from scratch using the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md).

### Feature Scope

| Feature ID | Feature Name | Implementation Status | Priority |
|------------|-------------|----------------------|----------|
| [X.Y.Z] | [Feature Name] | [Status] | [High/Medium/Low] |

## Validation Progress Matrix

### Overall Progress

| Validation Type                 | Items Validated | Reports Generated | Status      | Next Session |
|---------------------------------|-----------------|-------------------|-------------|--------------|
| Architectural Consistency       | 0/[N]           | 0                 | NOT_STARTED | TBD          |
| Code Quality & Standards        | 0/[N]           | 0                 | NOT_STARTED | TBD          |
| Integration & Dependencies      | 0/[N]           | 0                 | NOT_STARTED | TBD          |
| Documentation Alignment         | 0/[N]           | 0                 | NOT_STARTED | TBD          |
| Extensibility & Maintainability | 0/[N]           | 0                 | NOT_STARTED | TBD          |
| AI Agent Continuity             | 0/[N]           | 0                 | NOT_STARTED | TBD          |

### Feature-by-Feature Progress

| Feature | Architectural | Code Quality | Integration | Documentation | Extensibility | AI Continuity | Overall Status |
|---------|---------------|--------------|-------------|---------------|---------------|---------------|----------------|
| [X.Y.Z] | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | NOT_STARTED |

**Cell Content Guidelines**:

- **⏳ Pending**: No validation performed yet
- **🔄 In Progress**: Validation session active
- **[YYYY-MM-DD](link-to-report)**: Validation completed — date links to validation report
- **❌ Failed**: Validation failed, needs remediation
- **🔁 Needs Re-validation**: Previous validation invalidated by code changes

**Overall Status Legend**:

- **NOT_STARTED**: No validations completed
- **IN_PROGRESS**: Some validations completed, others pending
- **VALIDATED**: All 6 validation types completed successfully
- **ISSUES_FOUND**: Validations completed but issues require attention

## Validation Reports Registry

### Architectural Consistency Validation Reports

| Report ID | Features | Date | Score | Status | Issues | Actions |
|-----------|----------|------|-------|--------|--------|---------|

### Code Quality & Standards Validation Reports

| Report ID | Features | Date | Score | Status | Issues | Actions |
|-----------|----------|------|-------|--------|--------|---------|

### Integration & Dependencies Validation Reports

| Report ID | Features | Date | Score | Status | Issues | Actions |
|-----------|----------|------|-------|--------|--------|---------|

### Documentation Alignment Validation Reports

| Report ID | Features | Date | Score | Status | Issues | Actions |
|-----------|----------|------|-------|--------|--------|---------|

### Extensibility & Maintainability Validation Reports

| Report ID | Features | Date | Score | Status | Issues | Actions |
|-----------|----------|------|-------|--------|--------|---------|

### AI Agent Continuity Validation Reports

| Report ID | Features | Date | Score | Status | Issues | Actions |
|-----------|----------|------|-------|--------|--------|---------|

## Critical Issues Tracking

### High Priority Issues

| Issue ID | Feature | Validation Type | Severity | Description | Status | Assigned Session |
|----------|---------|-----------------|----------|-------------|--------|------------------|

### Medium Priority Issues

| Issue ID | Feature | Validation Type | Severity | Description | Status | Assigned Session |
|----------|---------|-----------------|----------|-------------|--------|------------------|

### Low Priority Issues

| Issue ID | Feature | Validation Type | Severity | Description | Status | Assigned Session |
|----------|---------|-----------------|----------|-------------|--------|------------------|

## Remediation Tracking

### Active Remediations

| Remediation ID | Original Issue | Feature | Assigned To | Target Date | Status | Progress |
|----------------|---------------|---------|-------------|-------------|--------|----------|

### Completed Remediations

| Remediation ID | Original Issue | Feature | Action Taken | Date Completed | Validation Status |
|----------------|---------------|---------|--------------|----------------|-------------------|

## Validation Metrics & Trends

### Overall Quality Scores

| Validation Type                 | Average Score | Trend | Best Feature | Worst Feature |
|---------------------------------|---------------|-------|--------------|---------------|
| Architectural Consistency       | N/A           | N/A   | N/A          | N/A           |
| Code Quality & Standards        | N/A           | N/A   | N/A          | N/A           |
| Integration & Dependencies      | N/A           | N/A   | N/A          | N/A           |
| Documentation Alignment         | N/A           | N/A   | N/A          | N/A           |
| Extensibility & Maintainability | N/A           | N/A   | N/A          | N/A           |
| AI Agent Continuity             | N/A           | N/A   | N/A          | N/A           |

### Feature Quality Rankings

| Rank | Feature | Overall Score | Primary Strengths | Primary Weaknesses |
|------|---------|---------------|-------------------|--------------------|

## Session Planning

### Recommended Validation Sequence

1. **Session 1**: [Validation Type] — [Feature Group] ([Rationale])
2. **Session 2**: [Validation Type] — [Feature Group] ([Rationale])

### Next Session Details

- **Planned Session**: [Session identifier]
- **Validation Type**: [Which validation type]
- **Features to Validate**: [Feature IDs]
- **Expected Outcomes**: [What to look for]
- **Prerequisites**: [What must be ready]

## Integration with Other State Tracking

### Cross-References

- **Feature Implementation Status**: [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md)
- **Quality Issues**: [Technical Debt Tracking](../../../product-docs/state-tracking/permanent/technical-debt-tracking.md)
- **Test Coverage**: [Test Tracking](../../../../test/state-tracking/permanent/test-tracking.md)

### Synchronization Points

- **When validation identifies issues**: Create entries in Technical Debt Tracking
- **When validation affects implementation**: Update Feature Tracking with quality notes
- **When validation requires tests**: Reference Test Tracking for coverage

## Change Log

### [YYYY-MM-DD]

- **Created**: Initial validation tracking file
- **Status**: Ready for validation sessions
- **Next Steps**: [Describe first validation session]

## Usage Instructions

### For AI Agents Running Validation Sessions

1. **Before Starting**:
   - Check the Feature-by-Feature Progress matrix for current status
   - Review prior validation reports for comparison context
2. **During Validation**:
   - Update matrix cells from ⏳ to 🔄 when starting
   - Document findings in the validation report
3. **After Validation**:
   - Replace 🔄 with **[YYYY-MM-DD](link-to-report)** when complete
   - Add report entry to the appropriate registry section
   - Update Overall Progress statistics
   - Add critical issues to the Issues Tracking section
   - Update Overall Status for the feature

4. **After All Validation Types Complete**:
   - Run `Generate-ValidationSummary.ps1` to create a consolidated report:
     ```powershell
     doc/process-framework/scripts/file-creation/05-validation/Generate-ValidationSummary.ps1 -IncludeDetails
     ```
   - Output is saved to `doc/product-docs/validation/reports/consolidated-validation-report.md`
   - Review the summary for overall quality gate assessment and prioritized action items

### Update Frequency

- **Real-time**: During active validation sessions
- **Session End**: Complete update after each session
- **Round End**: Comprehensive summary and trend analysis
