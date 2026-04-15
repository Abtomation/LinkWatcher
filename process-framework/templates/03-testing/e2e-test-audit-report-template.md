---
id: PF-TEM-074
type: Process Framework
category: Template
version: 1.0
created: 2026-04-13
updated: 2026-04-13
template_for: E2E Test Audit Report
creates_document_prefix: TE-TAR
creates_document_category: Test Audit Report
creates_document_type: E2E Test Audit
description: Template for E2E acceptance test audit reports with 5 criteria
usage_context: Used by New-TestAuditReport.ps1 -TestType E2E during PF-TSK-030
---

# E2E Test Audit Report - Feature [Feature ID]

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | [Feature ID] |
| **Test Case ID** | [TE-E2E-XXX] |
| **Test Group** | [TE-E2G-XXX] |
| **Test Case Location** | `[TEST_CASE_PATH]` |
| **Workflow** | [WF-XXX: Workflow description] |
| **Auditor** | [Auditor Name] |
| **Audit Date** | [Audit Date] |
| **Audit Status** | [PENDING/IN_PROGRESS/COMPLETED] |

## Tests Audited

| Test Case ID | Group | Workflow | Description | Current Status |
|-------------|-------|----------|-------------|----------------|
| [TE-E2E-XXX] | [TE-E2G-XXX] | [WF-XXX] | [Brief description] | [Status] |

## Audit Evaluation

### 1. Fixture Correctness
**Question**: Are `project/` and `expected/` directories accurate representations of the test scenario?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- **Project fixture accuracy**: [Do files in `project/` match the scenario described in test-case.md?]
- **Expected fixture accuracy**: [Are files in `expected/` the correct outcome for this scenario?]
- **Stale content**: [Any files that appear outdated, copied from another test, or contain placeholder content?]
- **File completeness**: [Are all necessary files present? Any missing fixtures?]

**Evidence**:
- [Specific files checked and their correctness]

**Recommendations**:
- [Specific fixture corrections needed]

---

### 2. Scenario Completeness
**Question**: Does the test cover the full user workflow end-to-end, including edge cases?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- **Workflow coverage**: [Are all steps from the workflow specification (user-workflow-tracking.md) exercised?]
- **Edge cases**: [Are boundary conditions included? Empty files, large files, special characters, nested directories]
- **Error paths**: [Are expected error scenarios covered?]
- **Cross-feature interaction**: [Does the test exercise the integration points between features?]

**Evidence**:
- [Comparison of test steps vs workflow specification]

**Recommendations**:
- [Missing scenarios to add]

---

### 3. Expected Outcome Accuracy
**Question**: Are the expected results in `expected/` actually correct for the given scenario?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- **Link target correctness**: [Do updated links in expected files resolve to valid targets?]
- **Content accuracy**: [Is the expected file content correct for the scenario — not just copied from project/?]
- **Diff analysis**: [What differences exist between project/ and expected/? Are they all intentional?]
- **Manual verification**: [Were expected outcomes verified by manual review, not just assumed correct?]

**Evidence**:
- [Specific expected files verified with diff analysis]

**Recommendations**:
- [Corrections to expected outcomes]

---

### 4. Reproducibility
**Question**: Can the test be executed independently and produce consistent results?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- **State independence**: [Does the test depend on state left by other tests? Hidden dependencies?]
- **Setup reliability**: [Does Setup-TestEnvironment.ps1 create a clean, complete workspace?]
- **Clean workspace**: [Does the test pass on a fresh workspace with no prior test runs?]
- **Timing sensitivity**: [Is the test sensitive to execution speed, race conditions, or timeouts?]

**Evidence**:
- [Results from independent execution on clean workspace]

**Recommendations**:
- [Improvements to reproducibility]

---

### 5. Precondition Coverage
**Question**: Are preconditions documented and enforceable?

**Assessment**: [PASS/FAIL/PARTIAL]

**Findings**:
- **Documentation**: [Are all preconditions listed in test-case.md?]
- **Enforcement**: [Does run.ps1 validate or set up preconditions before executing?]
- **LinkWatcher dependency**: [If the test requires LinkWatcher running, is this documented and handled?]
- **Environment assumptions**: [Are OS, Python version, or tool requirements documented?]

**Evidence**:
- [Precondition list from test-case.md vs actual requirements]

**Recommendations**:
- [Missing preconditions to document or enforce]

## Overall Audit Summary

### Audit Decision
**Status**: [AUDIT_APPROVED/NEEDS_UPDATE/AUDIT_FAILED]

**Status Definitions**:
- **🔍 Audit Approved**: All criteria pass — test is ready for execution
- **🔄 Needs Update**: Test case or fixtures need corrections before execution
- **🔴 Audit Failed**: Scenario fundamentally flawed or fixtures incorrect

**Rationale**:
[Detailed explanation of the audit decision based on the five evaluation criteria]

### Critical Issues
- [Critical issue 1 requiring immediate attention]

### Improvement Opportunities
- [Improvement opportunity 1]

### Strengths Identified
- [Strength 1 worth highlighting]

## Minor Fixes Applied

<!-- Delete this section if no minor fixes were applied during audit. -->

| Fix | What Changed | Why | Time Spent |
|-----|-------------|-----|------------|
| [Fix 1] | [Description] | [Rationale] | [X min] |

## Action Items

- [ ] [Action item 1 with specific details]
- [ ] [Action item 2 with specific details]

## Audit Completion

### Validation Checklist
- [ ] All five evaluation criteria have been assessed
- [ ] Specific findings documented with evidence
- [ ] Clear audit decision made with rationale
- [ ] Action items defined
- [ ] E2E test tracking updated with audit status

### Next Steps
1. [Next step — typically "Proceed to execution (PF-TSK-070)" or "Return to case creation (PF-TSK-069) for fixes"]

### Follow-up Required
- **Re-audit Date**: [DATE if NEEDS_UPDATE]
- **Follow-up Items**: [Specific items to track]

---

**Audit Completed By**: [Auditor Name]
**Completion Date**: [Audit Date]
**Report Version**: 1.0
