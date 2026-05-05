---
id: PF-GDE-041
type: Process Framework
category: Guide
version: 2.0
created: 2025-08-07
updated: 2026-04-13
related_task: PF-TSK-030
related_script: New-TestAuditReport.ps1
---
# Test Audit Usage Guide

## Overview

This guide provides comprehensive instructions for using the Test Audit task (PF-TSK-030) to conduct systematic quality assessments of test implementations across three test types: automated (unit/integration/parser), performance, and E2E acceptance tests. The task uses type-specific criteria and templates to evaluate tests and make informed decisions about approval or improvement needs.

## When to Use

Use this guide when:

- Test implementations have reached "🔄 Needs Audit" status
- You need to conduct systematic quality assessment of test suites
- Test files require evaluation against established quality criteria
- You're transitioning tests from implementation to approved status
- Quality assurance is needed before test suite finalization

> **🚨 CRITICAL**: Test audits must be conducted by AI agents with Quality Assurance Engineer role and analytical mindset. Do not skip evaluation criteria or make decisions without thorough analysis.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Audit Criteria Overview](#audit-criteria-overview)
4. [Step-by-Step Instructions](#step-by-step-instructions)
5. [Quality Assurance](#quality-assurance)
6. [Examples](#examples)
7. [Troubleshooting](#troubleshooting)
8. [Related Resources](#related-resources)

## Prerequisites

Before you begin, ensure you have:

- **AI Agent Role**: Quality Assurance Engineer with analytical mindset
- **Test Status**: Test implementation must be in "🔄 Needs Audit" status
- **Context Access**: Access to test files, implementation code, and specifications
- **Documentation**: Test Tracking file and Test Registry available
- **Tools**: PowerShell execution capability for audit report generation
- **Understanding**: Familiarity with the six evaluation criteria and audit process

## Background

The Test Audit task was created to address the quality assurance gap between test implementation and test approval. Previously, tests moved directly from "Implementation In Progress" to "Audit Approved" without systematic quality evaluation. This led to potential quality issues and inconsistent test standards.

### Key Concepts

- **Quality Gate**: Test audits serve as a quality gate ensuring only high-quality tests are approved
- **Six Evaluation Criteria**: Systematic assessment framework covering all aspects of test quality
- **Audit Decision**: Binary decision (Audit Approved or Needs Update) based on comprehensive evaluation
- **Status Workflow**: Integration with test implementation tracking for seamless workflow management

### Audit Philosophy

Test audits follow a quality-first approach:
- **Thorough Analysis**: Every criterion must be evaluated with specific findings
- **Evidence-Based Decisions**: All assessments must be supported by concrete evidence
- **Constructive Feedback**: Focus on improvement opportunities and actionable recommendations
- **Consistency**: Apply the same standards across all test implementations

## Test Type Selection

PF-TSK-030 supports three test types, each with distinct criteria, templates, and tracking files. Determine the test type **before** starting the audit:

| Test Type | When to Audit | Tracking File | Criteria Count | Template |
|-----------|--------------|---------------|----------------|----------|
| **Automated** (default) | After `✅ Audit Approved` in test-tracking.md | test-tracking.md | 6 criteria | Standard or Lightweight |
| **Performance** | After `📋 Needs Baseline` in performance-test-tracking.md | performance-test-tracking.md | 4 criteria | Performance Audit (PF-TEM-073) |
| **E2E** | After `📋 Needs Execution` in e2e-test-tracking.md | e2e-test-tracking.md | 5 criteria | E2E Audit (PF-TEM-074) |

Use `-TestType Performance` or `-TestType E2E` with all audit scripts. Omitting `-TestType` defaults to Automated for backward compatibility.

## Minor Fix Authority

During any audit, you may implement fixes directly if they meet **all** of these conditions:
- Takes **≤15 minutes**
- Falls into an **allowed fix type**: assertion additions, test renames, dead test removal, trivial fixture fixes, missing pytest markers, tolerance/threshold adjustments
- Does **not** create new test methods/files, refactor structure, or fix infrastructure

Document each fix in the audit report's "Minor Fixes Applied" section. This avoids routing trivial issues through the Tech Debt → Code Refactoring pipeline.

## Scalability Guidance

For large test suites, not every test needs individual audit:

- **Risk-based sampling**: Critical-path tests get full audit; stable utility tests get spot checks or can be skipped
- **Batch patterns**: Group tests by feature or type; audit one batch per session
- **Re-audit triggers**: Re-audit when (a) major refactoring of tested code, (b) coverage drops >10%, (c) 6+ months since last audit, (d) test failures increase without code changes

## Audit Criteria Overview

### Automated Test Criteria

The automated test audit evaluates tests against six comprehensive quality criteria. Each criterion must be assessed with specific findings, evidence, and recommendations.

### 1. Purpose Fulfillment
**Question**: Does the test really fulfill its intended purpose?

**Focus Areas**:
- Test objectives alignment with specifications
- Coverage of intended functionality
- Validation of expected behaviors
- Edge case handling appropriateness
- **Assertion Quality** (sub-assessment):
  - *Assertion density*: Count assertions per test method — target ≥2. Tests with only one `assert` or none beyond "no exception" are weak.
  - *Behavioral assertions*: Do assertions check actual return values, state changes, and side effects? Flag tests that only assert `is not None` or `assertTrue(True)`.
  - *Edge case assertions*: Are boundary conditions, error paths, and empty/null inputs covered with specific assertions?
  - *Mutation testing* (optional): If tools are available (e.g., `mutmut` for Python), report mutation kill rate. Not required.

**Assessment Levels**: PASS (fully fulfills purpose), PARTIAL (mostly fulfills with gaps), FAIL (does not fulfill purpose)

### 2. Coverage Completeness
**Question**: Are all implementable scenarios covered with tests?

**Focus Areas**:
- **Code Coverage Data**: Quantitative line/branch coverage from `Run-Tests.ps1 -Coverage` — include per-module percentages and overall project coverage in the audit report
- **Existing Implementation Coverage**: Test coverage for existing implementations
- **Missing Implementation Analysis**: Identification of tests that cannot be implemented due to missing dependencies
- **Placeholder Test Quality**: Assessment of placeholder tests for missing implementations
- **Edge Case Coverage**: Boundary condition testing for existing implementations
- **Error Scenario Testing**: Exception and error handling for existing implementations

**Assessment Levels**: PASS (comprehensive coverage for existing implementations), PARTIAL (good coverage with minor gaps), FAIL (significant coverage gaps for existing implementations)

**Implementation Dependency Considerations**:
- Tests that cannot be implemented due to missing classes should be evaluated as placeholders, not coverage gaps
- Focus evaluation on what CAN be tested with current implementations
- Document missing dependencies that block test implementation

### 3. Test Quality & Structure
**Question**: Could the test be optimized?

**Focus Areas**:
- Code quality and readability
- Test structure and organization
- Assertion quality and specificity
- Test maintainability

**Assessment Levels**: PASS (high quality, well-structured), PARTIAL (good quality with improvement opportunities), FAIL (poor quality requiring significant changes)

### 4. Performance & Efficiency
**Question**: Are tests efficient and performant?

**Focus Areas**:
- Execution time efficiency
- Resource usage optimization
- Test isolation and independence
- Setup/teardown efficiency

**Assessment Levels**: PASS (efficient and performant), PARTIAL (acceptable performance with optimization opportunities), FAIL (performance issues requiring attention)

### 5. Maintainability
**Question**: Will these tests be maintainable long-term?

**Focus Areas**:
- Code clarity and documentation
- Test data management
- Dependency management
- Future change adaptability

**Assessment Levels**: PASS (highly maintainable), PARTIAL (maintainable with minor improvements), FAIL (maintainability concerns requiring changes)

### 6. Integration Alignment
**Question**: Do tests align with overall testing strategy?

**Focus Areas**:
- Consistency with project patterns
- Integration with testing framework
- Alignment with testing standards
- Compatibility with CI/CD pipeline

**Assessment Levels**: PASS (fully aligned), PARTIAL (mostly aligned with minor adjustments needed), FAIL (alignment issues requiring changes)

### Performance Test Criteria

Performance test audits evaluate against four criteria specific to benchmark and scale tests. These criteria assess whether the test will produce reliable, meaningful baselines.

#### 1. Measurement Methodology
**Question**: Is the test measuring the right thing with appropriate precision?

**Focus Areas**:
- Warmup cycles — sufficient to reach steady state
- Iteration count — enough for statistical significance
- Timing precision — `time.perf_counter()` preferred over `time.time()`
- Isolation — measurement free from external interference (I/O, GC, other processes)
- Result stability — low coefficient of variation across runs

**Assessment Levels**: PASS (stable, well-isolated measurements), PARTIAL (mostly stable with minor issues), FAIL (unreliable or poorly isolated)

#### 2. Tolerance Appropriateness
**Question**: Are thresholds realistic, meaningful, and calibrated to observed variance?

**Focus Areas**:
- Tolerance derived from observed variance, not arbitrary values
- Sensitivity balance — not too tight (noisy false alarms) or too loose (misses regressions)
- Level-appropriate — Component (L1) benchmarks have tighter tolerance than Scale (L3) tests
- Units consistency with measurement
- Calibration intent recorded — both the ratio (e.g., `10× typical`) and the baseline measurement go into the Tests Audited table's `Calibration Baseline` and `Tolerance Ratio` columns, so downstream refactorings can recompute thresholds when typical measurements drift

**Assessment Levels**: PASS (well-calibrated), PARTIAL (acceptable but could be refined), FAIL (arbitrary or clearly wrong)

#### 3. Baseline Readiness
**Question**: Is the test ready for reliable baseline capture?

**Focus Areas**:
- Clean setup/teardown with no leftover state
- Deterministic results in consistent environment
- No external dependencies that vary between runs
- Environment requirements documented
- Tracking-file consistency: `performance-test-tracking.md` Tolerance column matches code assertions (drift indicates upstream refactoring left documentation behind)

**Assessment Levels**: PASS (ready for baseline), PARTIAL (minor environment issues), FAIL (not ready — results would be unreliable)

#### 4. Regression Detection Config
**Question**: Will this test actually catch meaningful regressions?

**Focus Areas**:
- Minimum detectable regression size
- False positive rate under normal variance
- Comparison method (absolute threshold, percentage delta, statistical test)
- Trend tracking via performance_db.py

**Assessment Levels**: PASS (effective detection), PARTIAL (would catch large regressions but miss subtle ones), FAIL (unable to distinguish regression from noise)

### E2E Acceptance Test Criteria

E2E test audits evaluate against five criteria specific to acceptance tests with fixtures. These criteria assess whether the test will produce valid, reproducible results when executed.

#### 1. Fixture Correctness
**Question**: Are `project/` and `expected/` directories accurate?

**Focus Areas**:
- Files in `project/` match scenario described in test-case.md
- Files in `expected/` show correct outcome for the scenario
- No stale content, placeholders, or content copied from other tests
- All necessary files present

**Assessment Levels**: PASS (accurate fixtures), PARTIAL (mostly correct with minor issues), FAIL (incorrect or stale fixtures)

#### 2. Scenario Completeness
**Question**: Does the test cover the full user workflow end-to-end?

**Focus Areas**:
- All workflow steps from user-workflow-tracking.md exercised
- Boundary conditions included (empty files, special characters, nested directories)
- Error paths covered where applicable
- Cross-feature integration points tested

**Assessment Levels**: PASS (complete scenario), PARTIAL (main path covered, edge cases missing), FAIL (incomplete scenario)

#### 3. Expected Outcome Accuracy
**Question**: Are the expected results actually correct?

**Focus Areas**:
- Updated links in expected files resolve to valid targets
- Content differences between project/ and expected/ are all intentional
- Expected outcomes verified by manual review
- No "copy of project/" without actual expected changes

**Assessment Levels**: PASS (verified correct), PARTIAL (mostly correct with minor issues), FAIL (incorrect expectations)

#### 4. Reproducibility
**Question**: Can the test produce consistent results independently?

**Focus Areas**:
- No hidden state dependencies between tests
- Clean setup via Setup-TestEnvironment.ps1
- Passes on fresh workspace with no prior runs
- Not sensitive to timing or race conditions

**Assessment Levels**: PASS (fully reproducible), PARTIAL (usually passes but occasionally flaky), FAIL (unreliable)

#### 5. Precondition Coverage
**Question**: Are preconditions documented and enforceable?

**Focus Areas**:
- All preconditions listed in test-case.md
- run.ps1 validates or sets up preconditions
- LinkWatcher dependency documented if required
- OS/Python/tool requirements documented

**Assessment Levels**: PASS (well-documented and enforced), PARTIAL (documented but not enforced), FAIL (undocumented preconditions)

## Step-by-Step Instructions

### 1. Preparation and Context Gathering

1. **Identify Test for Audit**
   - Locate test entry in Test Tracking with "🔄 Needs Audit" status
   - Note the Feature ID, Test File ID, and test file location
   - Verify test file exists and is accessible

2. **Gather Required Context**
   - Review test specification or feature requirements
   - Examine the actual test file implementation
   - Check related source code being tested
   - Review any existing documentation or comments

3. **Run Code Coverage Analysis**
   - Execute `Run-Tests.ps1 -All -Coverage` to generate coverage data
   - Review the terminal summary for per-source-file percentages
   - Open the HTML coverage report (e.g., `htmlcov/index.html`) for line-by-line detail
   - Note which source files relevant to the feature have low coverage — this feeds into criterion "2. Coverage Completeness"

4. **Set Up Audit Environment**
   - Ensure you have Quality Assurance Engineer mindset
   - Prepare for systematic evaluation against all six criteria
   - Have Test Tracking file and coverage data ready for the audit

**Expected Result:** Complete context understanding, coverage data collected, and readiness to conduct systematic audit

### 2. Create Audit Report

1. **Generate Audit Report Template**
   ```powershell
   # Navigate to scripts directory
   cd process-framework/scripts/file-creation

   # Create new audit report (example for feature 0.2.3)
   New-TestAuditReport.ps1 -FeatureId "0.2.3" -TestFilePath "test/automated/unit/test_example.py" -AuditorName "AI Agent"

   # Re-audit: overwrite existing report (archive the old one first)
   New-TestAuditReport.ps1 -FeatureId "0.2.3" -TestFilePath "test/automated/unit/test_example.py" -AuditorName "AI Agent" -Force
   ```

2. **Verify Report Creation**
   - Check that report was created in correct feature category directory
   - Confirm TE-TAR ID was assigned correctly
   - Open the generated report file

3. **Initial Report Customization**
   - Fill in test file path and basic information
   - Update audit overview section with specific details
   - Verify metadata accuracy

**Expected Result:** Audit report template created and ready for detailed evaluation

### 3. Assess Implementation Dependencies

1. **Check Implementation Status**
   - **Verify Existing Classes**: Check which classes/components referenced in tests actually exist in the codebase
   - **Identify Missing Dependencies**: List classes, interfaces, or components that don't exist yet
   - **Analyze Testability**: Determine which tests can be implemented vs which are blocked by missing dependencies

2. **Evaluate Placeholder Tests**
   - **Structure Quality**: Assess if placeholder tests follow proper test structure
   - **Documentation Completeness**: Check if placeholders clearly specify what needs to be implemented
   - **Implementation Readiness**: Evaluate if placeholders are ready for implementation when dependencies exist

3. **Document Dependency Analysis**
   - Create implementation dependency table in audit report
   - Clearly distinguish between implementable tests and blocked tests
   - Note quality of placeholder tests for missing implementations

**Expected Result:** Clear understanding of what can be tested vs what awaits implementation

### 4. Conduct Systematic Evaluation

1. **Evaluate Each Criterion Systematically**

   For each of the six evaluation criteria (focusing on implementable tests):

   a. **Read the criterion question carefully**
   b. **Analyze the implementable test portions** against the criterion
   c. **Document specific findings** with concrete examples
   d. **Provide evidence** (code snippets, observations, metrics)
   e. **Make assessment decision** (PASS/PARTIAL/FAIL)
   f. **Write actionable recommendations** for improvements

2. **Maintain Evaluation Standards**
   - Be thorough and analytical in each assessment
   - Support all findings with specific evidence
   - Focus on constructive feedback and improvement opportunities
   - Ensure consistency across all criteria

3. **Document Findings Comprehensively**
   ```markdown
   **Assessment**: PASS/PARTIAL/FAIL

   **Findings**:
   - Specific finding 1 with details
   - Specific finding 2 with details

   **Evidence**:
   - Code examples or specific observations

   **Recommendations**:
   - Actionable improvement suggestions
   ```

**Expected Result:** All six evaluation criteria completed with detailed assessments

### 4. Make Audit Decision

1. **Analyze Overall Assessment**
   - Review all six criterion assessments
   - Identify patterns and critical issues
   - Consider cumulative impact of findings

2. **Make Audit Decision**
   - **✅ TESTS_APPROVED**: All implementable tests are complete and high quality
   - **🔄 NEEDS_UPDATE**: Existing tests have issues that need fixing
   - **🔴 TESTS_INCOMPLETE**: Missing tests for existing implementations

3. **Document Decision Rationale**
   - Provide clear explanation for the decision
   - Reference specific findings that influenced the decision
   - Ensure decision consistency with individual assessments

**Expected Result:** Clear audit decision with comprehensive rationale

### 5. Complete Action Items and Validation

1. **Define Action Items**
   - Create specific, actionable items for test implementation team
   - Include any items for feature implementation team if needed
   - Assign priorities and provide clear guidance

2. **Complete Validation Checklist**
   - Check all six evaluation criteria are addressed
   - Verify specific findings are documented with evidence
   - Confirm clear audit decision with rationale
   - Ensure action items are defined

3. **Validate Report Completeness**
   ```powershell
   # Validate the completed audit report
   Validate-AuditReport.ps1 -ReportFile "foundation/audit-report-0-2-3-test_example.md" -Detailed
   ```

**Expected Result:** Complete, validated audit report ready for finalization

### 6. Update Tracking and Finalize

1. **Update Test Tracking**
   - Change status based on audit decision:
     - **TESTS_APPROVED** → "✅ Audit Approved"
     - **NEEDS_UPDATE** → "🔄 Needs Update"
   - Update last updated date
   - Add audit completion note

2. **Update Test Registry** (if applicable)
   - Add audit status information
   - Reference audit report ID

3. **Archive and Document**
   - Ensure audit report is properly saved
   - Update any related documentation
   - Complete audit process documentation

**Expected Result:** Test audit process completed with all tracking updated

## Quality Assurance

### Self-Review Checklist

Before finalizing any audit report, complete this comprehensive checklist:

#### Evaluation Completeness
- [ ] All six evaluation criteria have been assessed
- [ ] Each criterion has specific findings documented
- [ ] Evidence is provided for all assessments
- [ ] Recommendations are actionable and specific
- [ ] Assessment levels (PASS/PARTIAL/FAIL) are justified

#### Audit Decision Quality
- [ ] Binary decision (TESTS_APPROVED/NEEDS_UPDATE) is clear
- [ ] Decision rationale references specific findings
- [ ] Decision is consistent with individual criterion assessments
- [ ] Critical issues are properly identified and prioritized

#### Report Completeness
- [ ] Metadata section is complete and accurate
- [ ] Test file information is correct
- [ ] Action items are specific and assignable
- [ ] Validation checklist is completed
- [ ] No template placeholders remain

#### Process Compliance
- [ ] Quality Assurance Engineer role maintained throughout
- [ ] Systematic evaluation approach followed
- [ ] Evidence-based decision making applied
- [ ] Constructive feedback provided

### Validation Criteria

#### Content Validation
- **Accuracy**: All information is factually correct and current
- **Completeness**: No required sections or assessments are missing
- **Specificity**: Findings and recommendations are specific and actionable
- **Evidence**: All assessments are supported by concrete evidence

#### Process Validation
- **Systematic Approach**: All six criteria evaluated systematically
- **Consistency**: Same standards applied across all assessments
- **Objectivity**: Assessments based on evidence, not assumptions
- **Constructiveness**: Focus on improvement opportunities

#### Integration Validation
- **Tracking Updates**: Test Tracking properly updated
- **Status Consistency**: Audit decision aligns with status updates
- **Documentation Links**: All references and links are correct
- **Workflow Integration**: Audit fits seamlessly into development workflow

### Common Quality Issues to Avoid

#### Assessment Issues
- **Superficial Analysis**: Failing to provide specific, detailed findings
- **Unsupported Decisions**: Making assessments without concrete evidence
- **Inconsistent Standards**: Applying different criteria to similar tests
- **Missing Recommendations**: Failing to provide actionable improvement suggestions

#### Process Issues
- **Skipping Criteria**: Not evaluating all six required criteria
- **Template Placeholders**: Leaving template content unchanged
- **Incomplete Validation**: Not using validation script before finalization
- **Tracking Neglect**: Failing to update test implementation tracking

#### Decision Issues
- **Unclear Rationale**: Not explaining the basis for audit decisions
- **Inconsistent Decisions**: Decision doesn't match individual assessments
- **Missing Action Items**: Not providing clear next steps
- **Incomplete Follow-up**: Not defining re-audit requirements for NEEDS_UPDATE decisions

## Examples

### Example 1: Foundation Feature Test Audit

**Scenario**: Auditing AppError base class tests (Feature 0.2.4, test file test_app_error.py)

**Step 1: Create Audit Report**
```powershell
cd process-framework/scripts/file-creation
New-TestAuditReport.ps1 -FeatureId "0.2.4" -TestFilePath "test/automated/unit/test_app_error.py" -AuditorName "AI Agent"
```

**Result**: Creates `foundation/audit-report-0-2-4-test_app_error.md` with TE-TAR-001 ID

**Step 2: Sample Evaluation (Purpose Fulfillment)**
```markdown
### 1. Purpose Fulfillment
**Question**: Does the test really fulfill its intended purpose?

**Assessment**: PASS

**Findings**:
- Tests validate AppError constructor with all required parameters
- Covers display message generation for user-facing errors
- Validates log formatting for debugging purposes
- Tests inheritance hierarchy and polymorphic behavior

**Evidence**:
- 11 test cases covering constructor validation, message formatting, and inheritance
- Specific assertions for displayMessage and logMessage methods
- Edge case testing for null/empty parameters

**Recommendations**:
- Consider adding tests for error serialization if needed for API responses
- Validate error code uniqueness across error types
```

**Step 3: Final Decision**
```markdown
### Audit Decision
**Status**: TESTS_APPROVED

**Rationale**:
All six evaluation criteria received PASS or PARTIAL assessments. The test suite comprehensively covers AppError functionality with good structure and maintainability. Minor recommendations for enhancement do not prevent approval.
```

### Example 2: Authentication Feature Audit with Issues

**Scenario**: Auditing authentication service tests (Feature 1.2.1, test file test_auth.py) that need improvements

**Sample Evaluation (Coverage Completeness)**
```markdown
### 2. Coverage Completeness
**Question**: Are all necessary scenarios covered with tests?

**Assessment**: FAIL

**Findings**:
- Missing tests for token expiration scenarios
- No coverage for concurrent login attempts
- Password reset flow not tested
- Multi-factor authentication scenarios absent

**Evidence**:
- Only 8 test cases for complex authentication service
- No tests in test file for tokenExpiration() method
- Missing error scenarios for invalid credentials

**Recommendations**:
- Add comprehensive token lifecycle testing
- Implement concurrent access testing
- Create password reset workflow tests
- Add MFA integration tests
```

**Final Decision**
```markdown
### Audit Decision
**Status**: NEEDS_UPDATE

**Rationale**:
Critical coverage gaps in authentication testing pose security risks. The test suite requires significant expansion to cover essential authentication scenarios before approval.
```

## Troubleshooting

### Audit Report Creation Fails

**Symptom:** New-TestAuditReport.ps1 script fails with module import error

**Cause:** Common-ScriptHelpers module not found or PowerShell execution policy restrictions

**Solution:**
1. Verify you're running the script from the correct directory: `process-framework/scripts/file-creation`
2. Check PowerShell execution policy: `Get-ExecutionPolicy`
3. If restricted, set policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
4. Verify Common-ScriptHelpers.psm1 exists at `../../scripts/Common-ScriptHelpers.psm1`

### Validation Script Reports Template Placeholders

**Symptom:** Validate-AuditReport.ps1 shows warnings about template placeholders remaining

**Cause:** Audit report sections not fully customized with specific content

**Solution:**
1. Search for `[PLACEHOLDER_NAME]` patterns in the audit report
2. Replace all placeholders with actual audit findings and assessments
3. Ensure all six evaluation criteria have specific findings, not template text
4. Re-run validation script to confirm all placeholders are resolved

### Difficulty Making Audit Decision

**Symptom:** Uncertain whether to choose TESTS_APPROVED or NEEDS_UPDATE

**Cause:** Mixed assessment results across the six criteria

**Solution:**
1. **Count FAIL assessments**: Any FAIL assessment typically requires NEEDS_UPDATE
2. **Evaluate PARTIAL assessments**: Multiple PARTIAL assessments may require NEEDS_UPDATE
3. **Consider critical issues**: Security, functionality, or maintainability issues should trigger NEEDS_UPDATE
4. **Apply quality gate principle**: When in doubt, choose NEEDS_UPDATE to ensure quality

### Test File Not Found During Audit

**Symptom:** Cannot locate test file referenced in Test Tracking

**Cause:** Test file moved, renamed, or tracking information outdated

**Solution:**
1. Search project for test file by name: `Get-ChildItem -Recurse -Name "*test_name*"`
2. Check git history for file moves: `git log --follow --name-status -- path/to/file`
3. Update Test Tracking with correct path
4. If file deleted, update status to "🗑️ Removed"

### Audit Report Validation Fails

**Symptom:** Validate-AuditReport.ps1 reports errors preventing finalization

**Cause:** Missing required sections, malformed metadata, or incomplete assessments

**Solution:**
1. Run validation with `-Detailed` flag to see all issues
2. Address each error systematically:
   - **Metadata errors**: Verify YAML format and required fields
   - **Missing sections**: Add all required sections from template
   - **Assessment errors**: Ensure all criteria have PASS/PARTIAL/FAIL assessments
3. Re-run validation until all errors are resolved

### Inconsistent Assessment Results

**Symptom:** Individual criterion assessments don't align with overall audit decision

**Cause:** Logical inconsistency between detailed findings and final decision

**Solution:**
1. Review each FAIL assessment - these typically require NEEDS_UPDATE decision
2. Consider cumulative impact of multiple PARTIAL assessments
3. Ensure decision rationale explains how individual assessments led to final decision
4. If necessary, revise individual assessments or final decision for consistency

## Related Resources

### Core Documentation
- [Test Audit Task Definition](../../tasks/03-testing/test-audit-task.md) - Complete task specification and process
- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Status tracking and workflow


### Scripts and Tools
- [New-TestAuditReport.ps1](../../scripts/file-creation/03-testing/New-TestAuditReport.ps1) - Audit report creation script
- [Validate-AuditReport.ps1](../../scripts/validation/Validate-AuditReport.ps1) - Audit report validation script
- [Test Audits Directory](../../../test/audits/README.md) - Directory structure and usage

### Templates and References
- [Test Audit Report Template](../../templates/03-testing/test-audit-report-template.md) - Report structure template
- [Test Query Tool](/process-framework/scripts/test/test_query.py) - Query test file metadata via pytest markers

### Process Framework
- [AI Tasks Registry](../../ai-tasks.md) - Complete task catalog and workflow integration
- [Documentation Map](../../PF-documentation-map.md) - Complete framework documentation overview
