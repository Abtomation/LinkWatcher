---
id: PF-TSK-030
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.7
created: 2025-08-07
updated: 2026-04-03
---

# Test Audit

## Purpose & Context

Comprehensive quality assurance task that evaluates implemented test suites against effectiveness, completeness, and maintainability criteria. Serves as a quality gate between test implementation and production use, ensuring tests truly fulfill their intended purpose and provide adequate coverage.

**🚨 CRITICAL SCOPE CLARIFICATION**: This task is **EVALUATION ONLY** - it assesses and reports on test quality but does NOT implement fixes or modifications to tests. Any identified issues should be documented in the audit report for separate implementation tasks.

## AI Agent Role

**Role**: Quality Assurance Engineer
**Mindset**: Quality-first, thorough, analytical, improvement-oriented
**Focus Areas**: Test effectiveness, coverage analysis, code quality, maintainability, performance assessment
**Communication Style**: Provide constructive feedback with specific improvement recommendations, ask clarifying questions about test requirements and edge cases

## When to Use

- After test implementation is complete (status: "✅ Tests Implemented")
- Before tests are considered production-ready for feature implementation
- When test quality concerns are raised during code review
- As part of quality gates for critical features
- When comprehensive test validation is required

## When NOT to Use

- For tests that are still in development (status: "🟡 Implementation In Progress" or "🔄 Ready for Validation")
- For features marked as "🚫 No Test Required"
- For simple tests that don't warrant comprehensive audit (use discretion based on feature complexity)

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/03-testing/test-audit-map.md)

- **Critical (Must Read):**

  - **Test Implementation Files** - The actual test files to be audited (located in the project's test directory as configured in `project-config.json`)
  - **Test Specification Document** - The test specification file for the feature being audited (located in `/test/specifications/feature-specs`)
  - [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Current test implementation status and audit tracking
  - [Technical Design Document](/doc/technical/tdd) - The TDD for the feature to understand implementation requirements

- **Important (Load If Space):**

  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Feature development status and context
  - [Existing Test Structure](/test/) - Current test organization and patterns for consistency evaluation
  - [Development Guide](/process-framework/guides/04-implementation/development-guide.md) - Testing standards and practices

- **Reference Only (Access When Needed):**
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the appropriate automation tools where indicated.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

> **Re-Audit Workflow**: If a prior audit report exists for this test file (check [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) for linked reports):
> 1. **Archive prior report** — move it to the `old/` subdirectory within its category folder (e.g., `doc/test-audits/foundation/old/`)
> 2. **Create fresh report** — use `New-TestAuditReport.ps1 -Force` to overwrite the existing report; evaluate all criteria from scratch
> 3. **Use prior report as reference** — read the archived report for context on previously identified issues, but do not carry over scores or findings — re-evaluate everything independently
>
> Re-audits follow the same full process below. The prior report provides context, not a shortcut.

> **Multi-Session Scoping**: For audit rounds spanning multiple sessions (e.g., auditing all features), create a tracking file to plan and track progress:
> ```powershell
> # From project root — creates audit-tracking-N.md with auto-populated inventory from test-tracking.md
> process-framework/scripts/file-creation/03-testing/New-AuditTracking.ps1 -RoundNumber 1
>
> # Scope to specific features
> process-framework/scripts/file-creation/03-testing/New-AuditTracking.ps1 -RoundNumber 1 -FeatureFilter "0.1.1,2.1.1" -Description "Foundation re-audit"
> ```
> The tracking file is created in `test/state-tracking/audit/` and auto-populates the test file inventory. Update it after each session to maintain cross-session continuity.

1. **Review Test Implementation**: Examine the implemented test suite files and understand their structure and coverage
2. **Analyze Test Specification**: Compare implementation against original test specification to understand intended behavior
3. **Understand Feature Context**: Review feature documentation, TDD, and requirements to grasp the feature's purpose and complexity
4. **Run Code Coverage Analysis**: Execute tests with coverage to gather quantitative data for the audit

   ```powershell
   # Run tests with coverage using the language-agnostic test runner
   Run-Tests.ps1 -All -Coverage
   ```

   - Review the coverage summary output (per-source-file percentages)
   - Open the HTML coverage report for detailed line-by-line analysis
   - Note low-coverage source files relevant to the feature being audited
   - This data feeds into criterion "2. Coverage Completeness" as quantitative evidence

5. **🚨 CHECKPOINT**: Present audit scope, test implementation overview, coverage summary, and feature context to human partner for approval before conducting audit

### Execution

6. **Assess Implementation Dependencies**: Before evaluating test quality, determine what can actually be tested:

   - **Implementation Status Check**: Verify which classes/components referenced in tests actually exist in the codebase
   - **Testability Analysis**: Identify tests that cannot be implemented due to missing dependencies
   - **Placeholder Assessment**: Evaluate quality and completeness of placeholder tests for missing implementations
   - **Documentation Review**: Check if placeholder tests clearly specify implementation requirements

7. **Conduct Systematic Audit**: Evaluate implementable tests against all six quality criteria:

   - **Purpose Fulfillment**: Does the test really fulfill its intended purpose? Include **Assertion Quality Assessment**: assertion density (target ≥2 per method), behavioral vs superficial assertions, edge case coverage, and optional mutation testing.
   - **Coverage Completeness**: Are all implementable scenarios covered with tests?
   - **Test Quality & Structure**: Could the test be optimized?
   - **Performance & Efficiency**: Are tests efficient and performant?
   - **Maintainability**: Will these tests be maintainable long-term?
   - **Integration Alignment**: Do tests align with overall testing strategy?

8. **Create Audit Report**: Generate comprehensive audit report using automation script

   ```powershell
   # Navigate to the test-audits directory from project root
   Set-Location "test/audits"

   # Default: full report (use when any criterion is FAIL or PARTIAL, or when there are action items)
   ../../scripts/file-creation/03-testing/New-TestAuditReport.ps1 -FeatureId "X.X.X" -TestFilePath "test/automated/unit/test_example.py" -AuditorName "AI Agent"

   # Preferred for Tests Approved: use -Lightweight when ALL six criteria PASS
   # (omits Implementation Dependencies, Feature Implementation Team, Implementation Recommendations)
   ../../scripts/file-creation/03-testing/New-TestAuditReport.ps1 -FeatureId "X.X.X" -TestFilePath "test/automated/unit/test_example.py" -AuditorName "AI Agent" -Lightweight

   # Script automatically:
   # - Generates unique TE-TAR ID (format: TE-TAR-XXX)
   # - Creates audit report from template in appropriate feature category directory
   # - Updates TE-id-registry.json with the new ID
   # - Links audit report in test-tracking.md for the target test file
   # - Returns the full path to the created audit report file
   ```

   **Script Location**: /process-framework/scripts/file-creation/03-testing/New-TestAuditReport.ps1
   **Output Location**: `/doc/test-audits/[category]/audit-report-[feature-id]-[test-file-id].md`

9. **Document Findings**: Complete the audit report with specific findings, recommendations, and audit decision

   **⚠️ Error Handling Guidance**:

   - **Compilation Failures**: Document syntax errors, missing imports, or dependency issues without attempting fixes
   - **Runtime Errors**: Note test execution failures and their root causes for separate resolution
   - **Missing Test Files**: Report gaps in test coverage or missing test specifications
   - **Configuration Issues**: Identify test setup or environment configuration problems

10. **Bug Discovery During Audit**: Identify and document any bugs discovered during test execution:

   - **Test Failures**: Analyze failing tests to determine if they indicate actual bugs
   - **Unexpected Behavior**: Document any behavior that doesn't match expected outcomes
   - **Edge Case Issues**: Identify bugs revealed through comprehensive test coverage
   - **Integration Problems**: Note issues discovered during integration test execution
   - **Performance Issues**: Document performance-related bugs found during testing

11. **Report Discovered Bugs**: If bugs are identified during audit:

   - Use [New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) script to create standardized bug reports
   - Follow [Bug Reporting Guide](../../guides/06-maintenance/bug-reporting-guide.md) for consistent documentation
   - Add bug entries to [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Reported
   - Include test audit context and evidence in bug reports
   - Reference audit report in bug documentation
   - Note impact on test audit results

   **Example Bug Report Command**:

   ```powershell
   # Navigate to the scripts directory from project root
   Set-Location "process-framework/scripts/file-creation"

   # Create bug report for issues found during test audit
   New-BugReport.ps1 -Title "Test failure reveals bug in component" -Description "Test consistently fails due to validation issue" -DiscoveredBy "TestAudit" -Severity "High" -Component "Component Name" -Environment "Development" -RelatedFeature "X.Y.Z"
   ```

12. **Assign Audit Status**: Determine audit outcome based on evaluation results:

- **✅ Tests Approved**: All implementable tests are complete and high quality
- **🟡 Tests Approved with Dependencies**: Current tests are good, but some tests await implementation
- **🔄 Needs Update**: Existing tests have issues that need fixing
- **🔴 Tests Incomplete**: Missing tests for existing implementations

13. **Register Significant Findings as Tech Debt**: For audit findings that warrant a dedicated follow-up session (e.g., zero-assertion tests, anti-patterns, structural issues across multiple test methods), register them in [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) using `Update-TechDebt.ps1 -Add -Dims "TST"`. Minor findings that are documented in the audit report but don't need separate tracking can be skipped.

    ```powershell
    # Register significant test quality finding as tech debt
    Update-TechDebt.ps1 -Add -Description "Zero-assertion tests in test_example.py (5 methods)" -Dims "TST" -Location "test/automated/unit/test_example.py" -Priority "Medium" -EstimatedEffort "Small"
    ```

    > **Routing**: Test-related tech debt items (zero-assertion tests, anti-patterns, coverage gaps) route to [Code Refactoring](../06-maintenance/code-refactoring-task.md) (PF-TSK-022) for resolution — use the Lightweight Path with the test-only shortcut.

14. **Validate Audit Report**: Run the validation script to verify report completeness before presenting to human partner

   ```powershell
   # Navigate to scripts/validation directory from project root
   Set-Location "process-framework/scripts/validation"

   # Validate the completed audit report
   Validate-AuditReport.ps1 -ReportFile "[category]/audit-report-[feature-id]-[test-file-id].md" -Detailed
   ```

   Address any errors or warnings before proceeding. The script checks metadata completeness, all six evaluation criteria, audit decision consistency, required sections, and template placeholders.

15. **🚨 CHECKPOINT**: Present audit findings, quality criteria scores, coverage data, discovered bugs, tech debt items registered, and proposed audit status to human partner for review and approval

### Finalization

16. **Update Test Tracking**: **🤖 AUTOMATED** - Update test implementation tracking with audit results using automation script

```powershell
# Navigate to scripts directory from project root
Set-Location "process-framework/scripts"

# Update test audit state with comprehensive details
Update-TestFileAuditState.ps1 -TestFilePath "test/automated/unit/test_example.py" -AuditStatus "Tests Approved" -AuditorName "AI Agent" -TestCasesAudited 15 -PassedTests 14 -FailedTests 1 -MajorFindings @("Finding 1", "Finding 2") -AuditReportPath "doc/test-audits/relative/path/to/audit-report.md"

# Script automatically:
# - Updates ../../../test/state-tracking/permanent/test-tracking.md with audit status and detailed results
# - Updates ../../../doc/state-tracking/permanent/feature-tracking.md with aggregated test status for the feature
# - Creates automatic backups before making changes
# - Calculates intelligent feature-level status based on all test files
```

**Available Audit Statuses**:

- `"Tests Approved"` → ✅ Tests Approved
- `"Tests Approved with Dependencies"` → 🟡 Tests Approved with Dependencies
- `"Needs Update"` → 🔄 Needs Update
- `"Audit Failed"` → 🔴 Audit Failed
- `"Audit In Progress"` → 🔍 Audit In Progress

17. **Verify Automated Updates**: Confirm the automation script successfully updated all state files:

    - **../../state-tracking/permanent/test-tracking.md**: Individual test file status with audit details
    - **doc/state-tracking/permanent/feature-tracking.md**: Aggregated feature test status

18. **Document Implementation Dependencies**: If status is "🟡 Tests Approved with Dependencies", clearly document:

    - Which implementations are missing and blocking tests
    - Recommended implementation priority order
    - Expected impact on feature development timeline

19. **Provide Feedback**: Deliver actionable recommendations for improvement if tests need updates

20. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Test Audit Report** - Comprehensive document analyzing test quality with specific findings and recommendations (located in `/doc/test-audits/[category]`)
- **Updated Test Tracking** - Test tracking updated with audit status and audit report link
- **Updated Test Registry** - Test registry updated with audit completion status
- **Bug Reports** - Any bugs discovered during audit documented in [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Reported
- **Tech Debt Items** (if applicable) - Significant test quality findings registered in [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) with category "Testing", routed to PF-TSK-053

## State Tracking

**🤖 FULLY AUTOMATED** - All state file updates are handled by the `Update-TestFileAuditState.ps1` script:

- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - **Automatically updated** with audit status, detailed audit results, and completion timestamp
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - **Automatically updated** with intelligent aggregated test status based on all test files for the feature
- [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - **Manually updated** with any bugs discovered during audit, including test context and evidence
- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - **Manually updated** (via `Update-TechDebt.ps1 -Add -Dims "TST"`) with significant test quality findings, routed to [Integration & Testing](../04-implementation/integration-and-testing.md) (PF-TSK-053)

**Key Automation Features**:

- **Individual Test File Updates**: Updates specific test file status with comprehensive audit details
- **Intelligent Aggregation**: Calculates feature-level test status based on all associated test files
- **Automatic Backups**: Creates backups of all state files before making changes
- **Comprehensive Audit Trail**: Maintains detailed history of audit results, findings, and auditor information

**Script Location**: `/process-framework/scripts/update/Update-TestFileAuditState.ps1`
**Usage Guide**: See [Automation Usage Guide](../../scripts/AUTOMATION-USAGE-GUIDE.md) for detailed examples and parameters.

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Test audit report created with comprehensive analysis and specific recommendations
  - [ ] All six evaluation criteria addressed in the audit report
  - [ ] Clear audit decision made (Tests Approved or Needs Update)
- [ ] **Update State Files**: **🤖 AUTOMATED** - Verify automation script successfully updated all state tracking files
  - [ ] Executed `Update-TestFileAuditState.ps1` with appropriate parameters
  - [ ] Confirmed [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) updated with audit status and detailed results
  - [ ] Checked [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Test Status column shows correct aggregated status
  - [ ] Significant test quality findings registered as tech debt items in [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) (category "Testing", routed to PF-TSK-022) — or confirmed no findings warrant tech debt registration
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-030" and context "Test Audit"

## Next Tasks

- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - If tests are approved, proceed with feature implementation planning using tests for validation
- [**Foundation Feature Implementation Task**](../04-implementation/foundation-feature-implementation-task.md) - For foundation features with approved tests
- [**Integration & Testing (PF-TSK-053)**](../04-implementation/integration-and-testing.md) - If tests need updates, return to test implementation with audit recommendations
- [**Bug Triage Task**](../06-maintenance/bug-triage-task.md) - If bugs are discovered during audit, proceed with bug triage and prioritization
- [**Code Review Task**](../06-maintenance/code-review-task.md) - Review test improvements after re-implementation

## Related Resources

- [Integration & Testing (PF-TSK-053)](../04-implementation/integration-and-testing.md) - For implementing tests before audit
- [Test Specification Creation Task](test-specification-creation-task.md) - For creating test specifications that guide implementation
- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Track test implementation and audit progress
- [Development Guide](/process-framework/guides/04-implementation/development-guide.md) - Testing standards and practices
