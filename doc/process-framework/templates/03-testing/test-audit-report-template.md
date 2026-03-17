---
id: [DOCUMENT_ID]
type: Process Framework
category: Test Audit Report
version: 1.0
created: [CREATION_DATE]
updated: [CREATION_DATE]
feature_id: [Feature ID]
test_file_id: [Test File ID]
auditor: [Auditor Name]
audit_date: [Audit Date]
---

# Test Audit Report - Feature [Feature ID]

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | [Feature ID] |
| **Test File ID** | [Test File ID] |
| **Test File Location** | `[TEST_FILE_PATH]` |
| **Feature Category** | [Feature Category] |
| **Auditor** | [Auditor Name] |
| **Audit Date** | [Audit Date] |
| **Audit Status** | [PENDING/IN_PROGRESS/COMPLETED] |

## Test Files Audited

| Test File | Location | Test Cases | Status |
|-----------|----------|------------|--------|
| [TEST_FILE_NAME] | [TEST_FILE_PATH] | [TEST_CASE_COUNT] | [AUDIT_STATUS] |

## Implementation Dependency Analysis

| Test File | Implementation Status | Can Be Tested? | Blocker | Placeholder Quality |
|-----------|----------------------|----------------|---------|-------------------|
| [TEST_FILE_NAME] | [EXISTS/MISSING/PARTIAL] | [YES/NO/PARTIAL] | [BLOCKER_DESCRIPTION] | [GOOD/POOR/N/A] |

**Implementation Dependencies Summary**:
- **Testable Components**: [List components that exist and can be tested]
- **Missing Dependencies**: [List missing implementations blocking tests]
- **Placeholder Tests**: [Assessment of placeholder test quality and completeness]

## Audit Evaluation

### 1. Purpose Fulfillment
**Question**: Does the test really fulfill its intended purpose?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- [Specific finding 1]
- [Specific finding 2]
- [Specific finding 3]

**Evidence**:
- [Evidence or code examples supporting the assessment]

**Recommendations**:
- [Specific recommendation 1]
- [Specific recommendation 2]

---

### 2. Coverage Completeness
**Question**: Are all implementable scenarios covered with tests?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- **Existing Implementation Coverage**: [Analysis of test coverage for existing implementations]
- **Missing Test Scenarios**: [Identified gaps in testing existing code]
- **Placeholder Test Quality**: [Assessment of placeholder tests for missing implementations]
- **Edge Cases Coverage**: [Assessment of boundary condition testing]

**Evidence**:
- [Coverage metrics or analysis for existing implementations]
- [Examples of well-structured vs poor placeholder tests]

**Recommendations**:
- [Coverage improvement recommendations for existing implementations]
- [Implementation priority recommendations for missing dependencies]

---

### 3. Test Quality & Structure
**Question**: Could the test be optimized?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- [Code quality assessment]
- [Test structure analysis]
- [Maintainability evaluation]

**Evidence**:
- [Code examples or structural issues]

**Recommendations**:
- [Quality improvement suggestions]

---

### 4. Performance & Efficiency
**Question**: Are tests efficient and performant?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- [Performance analysis]
- [Execution time assessment]
- [Resource usage evaluation]

**Evidence**:
- [Performance metrics or observations]

**Recommendations**:
- [Performance optimization suggestions]

---

### 5. Maintainability
**Question**: Will these tests be maintainable long-term?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- [Maintainability assessment]
- [Code clarity evaluation]
- [Documentation quality]

**Evidence**:
- [Maintainability indicators]

**Recommendations**:
- [Maintainability improvements]

---

### 6. Integration Alignment
**Question**: Do tests align with overall testing strategy?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- [Integration assessment]
- [Testing strategy alignment]
- [Consistency with project patterns]

**Evidence**:
- [Integration examples or misalignments]

**Recommendations**:
- [Integration improvements]

## Overall Audit Summary

### Audit Decision
**Status**: [TESTS_APPROVED/TESTS_APPROVED_WITH_DEPENDENCIES/NEEDS_UPDATE/TESTS_INCOMPLETE]

**Status Definitions**:
- **✅ Tests Approved**: All implementable tests are complete and high quality
- **🟡 Tests Approved with Dependencies**: Current tests are good, but some tests await implementation
- **🔄 Needs Update**: Existing tests have issues that need fixing
- **🔴 Tests Incomplete**: Missing tests for existing implementations

**Rationale**:
[Detailed explanation of the audit decision based on the six evaluation criteria and implementation dependency analysis]

### Critical Issues
- [Critical issue 1 requiring immediate attention]
- [Critical issue 2 requiring immediate attention]

### Improvement Opportunities
- [Improvement opportunity 1]
- [Improvement opportunity 2]
- [Improvement opportunity 3]

### Strengths Identified
- [Strength 1 worth highlighting]
- [Strength 2 worth highlighting]

## Action Items

### For Test Implementation Team
- [ ] [Action item 1 with specific details]
- [ ] [Action item 2 with specific details]
- [ ] [Action item 3 with specific details]

### For Feature Implementation Team
- [ ] [Action item 1 for feature team]
- [ ] [Action item 2 for feature team]

### Implementation Dependencies (if status is "Tests Approved with Dependencies")
- [ ] **Priority 1**: [Missing implementation 1] - [Impact description]
- [ ] **Priority 2**: [Missing implementation 2] - [Impact description]
- [ ] **Priority 3**: [Missing implementation 3] - [Impact description]

**Implementation Recommendations**:
- [Recommended implementation order and rationale]
- [Expected timeline impact]
- [Suggested approach for implementation]

## Audit Completion

### Validation Checklist
- [ ] All six evaluation criteria have been assessed
- [ ] Specific findings documented with evidence
- [ ] Clear audit decision made with rationale
- [ ] Action items defined with assignees
- [ ] Test implementation tracking updated
- [ ] Test registry updated with audit status

### Next Steps
1. [Next step 1]
2. [Next step 2]
3. [Next step 3]

### Follow-up Required
- **Re-audit Date**: [DATE if NEEDS_UPDATE]
- **Follow-up Items**: [Specific items to track]

---

**Audit Completed By**: [Auditor Name]
**Completion Date**: [Audit Date]
**Report Version**: 1.0
