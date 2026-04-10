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
7. **Security & Data Protection Validation** — Auth, input validation, secrets management, OWASP
8. **Performance & Scalability Validation** — Resource efficiency, algorithmic complexity, I/O patterns
9. **Observability Validation** — Logging coverage, monitoring, alerting, error traceability
10. **Accessibility / UX Compliance Validation** — WCAG compliance, keyboard navigation, screen reader support
11. **Data Integrity Validation** — Data consistency, constraint enforcement, migration safety

> **Note**: These are the full 11 validation dimensions. Remove dimensions not applicable to your project's feature profiles. See the [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md) for the complete Dimension Catalog.
>
> **Dimension Source**: Start from each feature's **Dimension Profile** in its implementation state file (Section 7). If no profile exists (legacy features), evaluate from scratch using the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md).

### Feature Scope

| Feature ID | Feature Name | Implementation Status | Priority | Workflow Cohort |
|------------|-------------|----------------------|----------|-----------------|
| [X.Y.Z] | [Feature Name] | [Status] | [High/Medium/Low] | [WF-IDs or —] |

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
| Security & Data Protection      | 0/[N]           | 0                 | NOT_STARTED | TBD          |
| Performance & Scalability       | 0/[N]           | 0                 | NOT_STARTED | TBD          |
| Observability                   | 0/[N]           | 0                 | NOT_STARTED | TBD          |
| Accessibility / UX Compliance   | 0/[N]           | 0                 | NOT_STARTED | TBD          |
| Data Integrity                  | 0/[N]           | 0                 | NOT_STARTED | TBD          |

### Feature-by-Feature Progress

| Feature | Architectural | Code Quality | Integration | Documentation | Extensibility | AI Continuity | Security | Performance | Observability | Accessibility | Data Integrity | Overall Status |
|---------|---------------|--------------|-------------|---------------|---------------|---------------|----------|-------------|---------------|---------------|----------------|----------------|
| [X.Y.Z] | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | NOT_STARTED |

**Cell Content Guidelines**:

- **⏳ Pending**: No validation performed yet
- **🔄 In Progress**: Validation session active
- **[YYYY-MM-DD](link-to-report)**: Validation completed — date links to validation report
- **❌ Failed**: Validation failed, needs remediation
- **🔁 Needs Re-validation**: Previous validation invalidated by code changes

**Overall Status Legend**:

- **NOT_STARTED**: No validations completed
- **IN_PROGRESS**: Some validations completed, others pending
- **VALIDATED**: All applicable validation types completed successfully
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

### Security & Data Protection Validation Reports

| Report ID | Features | Date | Score | Status | Issues | Actions |
|-----------|----------|------|-------|--------|--------|---------|

### Performance & Scalability Validation Reports

| Report ID | Features | Date | Score | Status | Issues | Actions |
|-----------|----------|------|-------|--------|--------|---------|

### Observability Validation Reports

| Report ID | Features | Date | Score | Status | Issues | Actions |
|-----------|----------|------|-------|--------|--------|---------|

### Accessibility / UX Compliance Validation Reports

| Report ID | Features | Date | Score | Status | Issues | Actions |
|-----------|----------|------|-------|--------|--------|---------|

### Data Integrity Validation Reports

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
| Security & Data Protection      | N/A           | N/A   | N/A          | N/A           |
| Performance & Scalability       | N/A           | N/A   | N/A          | N/A           |
| Observability                   | N/A           | N/A   | N/A          | N/A           |
| Accessibility / UX Compliance   | N/A           | N/A   | N/A          | N/A           |
| Data Integrity                  | N/A           | N/A   | N/A          | N/A           |

### Feature Quality Rankings

| Rank | Feature | Overall Score | Primary Strengths | Primary Weaknesses |
|------|---------|---------------|-------------------|--------------------|

## Cross-Dimensional Synthesis

> **When to complete**: In a dedicated synthesis session after all dimension tasks are finished. This session reviews all dimension reports together, fills in the sections below, then runs `Generate-ValidationSummary.ps1`. Plan this as the final session in the [Session Planning](#session-planning) sequence.

### Correlated Findings

Findings that appear across multiple dimensions, suggesting a shared root cause:

| Root Cause | Dimensions Affected | Features Affected | Evidence Summary |
|------------|--------------------|--------------------|------------------|

### Systemic Patterns

Codebase-wide trends visible only when comparing findings across dimensions:

| Pattern | Description | Dimensions Where Observed | Recommended Action |
|---------|-------------|---------------------------|-------------------|

### Prioritized Cross-Dimensional Remediation

Actions that address root causes spanning multiple dimensions, ordered by impact:

| Priority | Action | Addresses (Dimensions) | Addresses (Features) | Estimated Effort |
|----------|--------|------------------------|----------------------|-----------------|

## Session Planning

### Recommended Validation Sequence

1. **Session 1**: [Validation Type] — [Feature Group] ([Rationale])
2. **Session 2**: [Validation Type] — [Feature Group] ([Rationale])
3. **Final Session**: Cross-Dimensional Synthesis — Review all dimension reports, fill in [Cross-Dimensional Synthesis](#cross-dimensional-synthesis), run `Generate-ValidationSummary.ps1`

### Next Session Details

- **Planned Session**: [Session identifier]
- **Validation Type**: [Which validation type]
- **Features to Validate**: [Feature IDs]
- **Expected Outcomes**: [What to look for]
- **Prerequisites**: [What must be ready]

## Integration with Other State Tracking

### Cross-References

- **Feature Implementation Status**: [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)
- **Quality Issues**: [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md)
- **Test Coverage**: [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md)

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

4. **After All Dimension Sessions Complete** (dedicated synthesis session):
   - **Cross-Dimensional Synthesis**: Review all dimension reports together and fill in the [Cross-Dimensional Synthesis](#cross-dimensional-synthesis) section. Look for: (a) the same root cause flagged independently in multiple dimensions, (b) systemic codebase-wide patterns only visible when comparing dimension findings, (c) remediation actions that resolve issues across multiple dimensions at once.
   - Run `Generate-ValidationSummary.ps1` to create a consolidated report:
     ```powershell
     process-framework/scripts/file-creation/05-validation/Generate-ValidationSummary.ps1 -IncludeDetails
     ```
   - Output is saved to `doc/validation/reports/consolidated-validation-report.md`
   - Review the summary for overall quality gate assessment and prioritized action items

### Update Frequency

- **Real-time**: During active validation sessions
- **Session End**: Complete update after each session
- **Round End**: Comprehensive summary and trend analysis
