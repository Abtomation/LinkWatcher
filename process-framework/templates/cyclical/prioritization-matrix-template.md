---
id: PF-TEM-096
type: Process Framework
category: Assessment
version: 1.0
created: [Matrix Date]
updated: [Matrix Date]
creates_document_type: Product Documentation
creates_document_category: Technical Debt Matrix
description: "Template for debt prioritization matrices"
---
# Technical Debt Prioritization Matrix: [Matrix Name]

## Matrix Overview

- **Matrix Name**: [Matrix Name]
- **Created Date**: [Matrix Date]
- **Assessment Reference**: [PD-TDA-XXX]
- **Total Items Analyzed**: [Number of debt items]
- **Matrix Type**: Impact vs Effort Analysis

## Prioritization Methodology

### Impact Assessment Criteria
**High Impact** (3 points):
- Significantly affects user experience
- Major security vulnerabilities
- Blocks critical functionality
- Severely impacts development velocity

**Medium Impact** (2 points):
- Moderately affects user experience
- Minor security concerns
- Impacts some functionality
- Slows development in specific areas

**Low Impact** (1 point):
- Minimal user experience impact
- No security implications
- Affects non-critical functionality
- Minor development inconvenience

### Effort Assessment Criteria
**High Effort** (3 points):
- Requires significant architectural changes
- Multiple team members needed
- Complex integration requirements
- Estimated > 2 weeks of work

**Medium Effort** (2 points):
- Moderate code changes required
- 1-2 team members needed
- Some integration complexity
- Estimated 3-10 days of work

**Low Effort** (1 point):
- Simple code changes
- Single developer can handle
- Minimal integration impact
- Estimated < 3 days of work

## Impact vs Effort Matrix

### Visual Matrix

```
                    EFFORT
                Low    Medium    High
              ┌─────┬─────────┬─────┐
         High │  🔴  │   🟡    │  🟢  │
IMPACT       ├─────┼─────────┼─────┤
       Medium│  🟡  │   🟡    │  🟢  │
              ├─────┼─────────┼─────┤
          Low │  🟢  │   🟢    │  🟢  │
              └─────┴─────────┴─────┘

Legend:
🔴 Critical Priority (High Impact, Low Effort)
🟡 High Priority (High Impact, Medium Effort OR Medium Impact, Low Effort)
🟢 Medium/Low Priority (All other combinations)
```

### Priority Quadrants

#### 🔴 Critical Priority (High Impact, Low Effort)
*"Quick Wins" - Address immediately*

| Item ID | Title | Impact | Effort | Score | Notes |
|---------|-------|--------|--------|-------|-------|
| [PD-TDI-XXX] | [Item Title] | High (3) | Low (1) | 3.0 | [Priority justification] |

#### 🟡 High Priority (High Impact, Medium Effort)
*"Major Projects" - Plan for next sprint/release*

| Item ID | Title | Impact | Effort | Score | Notes |
|---------|-------|--------|--------|-------|-------|
| [PD-TDI-XXX] | [Item Title] | High (3) | Medium (2) | 1.5 | [Priority justification] |

#### 🟡 High Priority (Medium Impact, Low Effort)
*"Fill-ins" - Address when capacity allows*

| Item ID | Title | Impact | Effort | Score | Notes |
|---------|-------|--------|--------|-------|-------|
| [PD-TDI-XXX] | [Item Title] | Medium (2) | Low (1) | 2.0 | [Priority justification] |

#### 🟢 Medium Priority (Medium Impact, Medium Effort)
*"Evaluate" - Consider for future planning*

| Item ID | Title | Impact | Effort | Score | Notes |
|---------|-------|--------|--------|-------|-------|
| [PD-TDI-XXX] | [Item Title] | Medium (2) | Medium (2) | 1.0 | [Priority justification] |

#### 🟢 Low Priority (Low Impact, Any Effort)
*"Questionable" - Consider deferring or rejecting*

| Item ID | Title | Impact | Effort | Score | Notes |
|---------|-------|--------|--------|-------|-------|
| [PD-TDI-XXX] | [Item Title] | Low (1) | [Effort] | [Score] | [Priority justification] |

#### 🟢 Low Priority (High Impact, High Effort)
*"Thankless Tasks" - Plan carefully or break down*

| Item ID | Title | Impact | Effort | Score | Notes |
|---------|-------|--------|--------|-------|-------|
| [PD-TDI-XXX] | [Item Title] | High (3) | High (3) | 1.0 | [Consider breaking into smaller items] |

## Priority Summary

### Immediate Action Required (Critical Priority)
**Count**: [X items]
**Total Estimated Effort**: [X days/weeks]

Items requiring immediate attention:
- [PD-TDI-XXX]: [Brief description]
- [PD-TDI-XXX]: [Brief description]

### Next Sprint/Release (High Priority)
**Count**: [X items]
**Total Estimated Effort**: [X days/weeks]

Items for upcoming development cycle:
- [PD-TDI-XXX]: [Brief description]
- [PD-TDI-XXX]: [Brief description]

### Future Planning (Medium Priority)
**Count**: [X items]
**Total Estimated Effort**: [X days/weeks]

Items for future consideration:
- [PD-TDI-XXX]: [Brief description]
- [PD-TDI-XXX]: [Brief description]

### Deferred/Rejected (Low Priority)
**Count**: [X items]

Items with questionable value:
- [PD-TDI-XXX]: [Brief description and reason for deferral]
- [PD-TDI-XXX]: [Brief description and reason for deferral]

## Resource Allocation Recommendations

### Team Capacity Analysis
- **Available Capacity**: [X person-days per sprint/month]
- **Critical Items Capacity**: [X person-days needed]
- **High Priority Items Capacity**: [X person-days needed]
- **Recommended Allocation**: [Percentage breakdown]

### Skill Requirements
- **Critical Items**: [Required skills/expertise]
- **High Priority Items**: [Required skills/expertise]
- **Training Needs**: [Any training required]

## Risk Analysis

### High-Risk Items
Items that could cause significant problems if not addressed:
- [PD-TDI-XXX]: [Risk description]
- [PD-TDI-XXX]: [Risk description]

### Dependencies
Items that block or depend on others:
- [PD-TDI-XXX] blocks [PD-TDI-YYY]
- [PD-TDI-XXX] depends on [PD-TDI-YYY]

## Implementation Roadmap

### Phase 1: Critical Items (Immediate)
**Timeline**: [Timeframe]
**Items**: [List critical priority items]
**Success Criteria**: [How to measure completion]

### Phase 2: High Priority Items (Next Sprint/Release)
**Timeline**: [Timeframe]
**Items**: [List high priority items]
**Success Criteria**: [How to measure completion]

### Phase 3: Medium Priority Items (Future)
**Timeline**: [Timeframe]
**Items**: [List medium priority items]
**Success Criteria**: [How to measure completion]

## Monitoring and Review

### Success Metrics
- **Items Completed**: [Target number per timeframe]
- **Technical Debt Reduction**: [Measurable improvement]
- **Development Velocity**: [Expected improvement]
- **Quality Metrics**: [Code quality improvements]

### Review Schedule
- **Next Review Date**: [Date]
- **Review Frequency**: [How often to update matrix]
- **Review Triggers**: [Events that would trigger earlier review]

## Related Documents

- **Source Assessment**: [PD-TDA-XXX]
- **Individual Debt Items**: [List all PD-TDI-XXX items included]
- **Previous Matrices**: [References to previous prioritization matrices]
- **Technical Debt Tracking**: [Link to permanent state tracking]

## Matrix Validation

### Stakeholder Review
- **Reviewed By**: [Stakeholder names]
- **Review Date**: [Date]
- **Approval Status**: [Approved/Pending/Rejected]

### Assumptions and Constraints
- [Assumption 1]: [Description]
- [Assumption 2]: [Description]
- [Constraint 1]: [Description]
- [Constraint 2]: [Description]

---

**Matrix Status**: [Draft/Final/Approved]
**Next Update**: [Date]
**Matrix Maintainer**: [Person responsible]
