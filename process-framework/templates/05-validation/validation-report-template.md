---
id: PF-TEM-034
type: Process Framework
category: Template
version: 1.3
created: 2025-08-15
updated: 2026-07-27
usage_context: Process Framework - Validation Creation
description: Template for feature validation reports
creates_document_category: Validation Report
creates_document_prefix: PD-VAL
creates_document_type: Product Documentation
creates_document_version: 1.0
template_for: Validation
---

# Validation Report Template

> **Payload template.** The fenced block below is the document body emitted by
> [`New-ValidationReport.ps1`](../../scripts/file-creation/05-validation/New-ValidationReport.ps1),
> which assigns the `PD-VAL` ID, names the file, and fills the placeholders. The creation
> process, the `-ValidationType` token, and each dimension's scoring **criteria** are owned by
> the [Dimension Validation task](../../tasks/05-validation/dimension-validation-task.md) and
> its per-dimension path files — not by this template.

## Document Template

```markdown
---
id: [PD-VAL-XXX - will be assigned from ID registry]
type: Product Documentation
category: Validation Report
description: "[Validation Type Name] validation report — features [Feature Range]"
version: 1.0
created: [YYYY-MM-DD]
updated: [YYYY-MM-DD]
validation_type: [validation-type]
features_validated: [e.g., "0.2.1, 0.2.2, 0.2.3"]
validation_session: [Session number for this validation type]
---

# [Validation Type] Validation Report - Features [Feature Range]

## Executive Summary

**Validation Type**: [Validation Type Name]
**Features Validated**: [List of features, e.g., 0.2.1, 0.2.2, 0.2.3]
**Validation Date**: [Date]
**Validation Round**: Round [RoundNumber]
**Overall Score**: [X.X/3.0]
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

### Dimensions Validated

**Validation Dimension**: [e.g., Architectural Consistency (AC)]
**Dimension Source**: Implementation state file profiles / fresh evaluation

### Validation Criteria Applied

[Populate from your dimension's path file (`<dimension>-validation-path.md`) — it owns the
per-dimension criteria. See the Dimension Validation task.]

## Validation Results

### Overall Scoring

| Criterion     | Score | Weight   | Weighted Score | Notes        |
| ------------- | ----- | -------- | -------------- | ------------ |
| [Criterion 1] | [X/3] | [%]      | [X.X]          | [Brief note] |
| [Criterion 2] | [X/3] | [%]      | [X.X]          | [Brief note] |
| [Criterion 3] | [X/3] | [%]      | [X.X]          | [Brief note] |
| **TOTAL**     |       | **100%** | **[X.X/3.0]**  |              |

### Scoring Scale

- **3 - Fully Met**: Exemplary implementation, no significant issues
- **2 - Mostly Met**: Solid implementation, minor issues identified
- **1 - Partially Met**: Major issues requiring attention
- **0 - Not Met**: Fundamental problems or not implemented

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

- [Action item — what, why, estimated effort]

### Medium-Term Improvements

- [Improvement — what, benefit, estimated effort]

### Long-Term Considerations

- [Consideration — what, benefit, when to address]

## Cross-Feature Analysis

### Patterns Observed

- **Positive Patterns**: [Consistent good practices across features]
- **Negative Patterns**: [Recurring issues across features]
- **Inconsistencies**: [Variations in implementation approaches]

### Integration Points

- [Analysis of how features work together]
- [Potential integration issues identified]
- [Recommendations for better integration]

### Workflow Impact *(optional — include when validated features share workflows)*

[For features that co-participate in user workflows (per [User Workflow Tracking](/doc/state-tracking/permanent/user-workflow-tracking.md)), note any findings that affect end-to-end workflow correctness:]

- **Affected Workflows**: [WF-IDs where issues may propagate across co-participating features]
- **Cross-Feature Risks**: [Issues in one feature that could degrade another feature's contribution to the same workflow]
- **Recommendations**: [Workflow-level testing or coordination needed]

## Next Steps

- [ ] **Re-validation Required**: [List features needing re-validation, or "None"]
- [ ] **Additional Validation**: [Other validation types recommended, or "None"]
- [ ] **Update Validation Tracking**: Record results in validation tracking file
```

## Related Resources

- [Dimension Validation Task](../../tasks/05-validation/dimension-validation-task.md) — owns the report-creation process, the `-ValidationType` token, and (via each path file) the per-dimension scoring criteria
- [Feature Validation Guide](../../guides/05-validation/feature-validation-guide.md)
- [Validation Framework Tasks](../../tasks/05-validation) (validation task definitions)
- [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md)
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md)

---
