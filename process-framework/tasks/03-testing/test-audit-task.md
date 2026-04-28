---
id: PF-TSK-030
type: Process Framework
category: Task Definition
domain: agnostic
version: 2.1
created: 2025-08-07
updated: 2026-04-28
---

# Test Audit

## Purpose & Context

Comprehensive quality assurance task that evaluates test suites against type-specific effectiveness, completeness, and maintainability criteria. Serves as a quality gate between test creation and production use across three test categories:

- **Automated tests** (unit/integration/parser) — quality gate between implementation and feature development
- **Performance tests** — quality gate between test creation (`📋 Needs Baseline`) and baseline capture (`✅ Baselined`)
- **E2E acceptance tests** — quality gate between case creation (`📋 Needs Execution`) and execution (`✅ Passed`/`🔴 Failed`)

**🚨 CRITICAL SCOPE CLARIFICATION**: This task is primarily **EVALUATION ONLY**. However, **minor fixes ≤15 minutes** may be implemented directly during the audit (see [Minor Fix Authority](#minor-fix-authority)). All other issues should be documented in the audit report for separate implementation tasks.

## AI Agent Role

**Role**: Quality Assurance Engineer
**Mindset**: Quality-first, thorough, analytical, improvement-oriented
**Focus Areas**: Test effectiveness, coverage analysis, code quality, maintainability, performance assessment
**Communication Style**: Provide constructive feedback with specific improvement recommendations, ask clarifying questions about test requirements and edge cases

## When to Use

- **Automated tests**: After test implementation is complete (status: "✅ Audit Approved") — before tests are considered production-ready
- **Performance tests**: After performance test creation (status: "📋 Needs Baseline") — **mandatory** before baseline capture (PF-TSK-085)
- **E2E acceptance tests**: After E2E test case creation (status: "📋 Needs Execution") — **mandatory** before execution (PF-TSK-070)
- When test quality concerns are raised during code review
- As part of quality gates for critical features
- When comprehensive test validation is required (any test type)

## When NOT to Use

- For tests that are still in development (status: "🟡 Implementation In Progress" or "🔄 Needs Audit")
- For features marked as "🚫 No Test Required"
- For simple tests that don't warrant comprehensive audit (use discretion based on feature complexity)
- For performance tests with status `⚠️ Needs Re-baseline` — these have already been audited; re-capture directly via PF-TSK-085
- For E2E tests with status `🔄 Needs Re-execution` — these have already been audited; re-execute directly via PF-TSK-070

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/03-testing/test-audit-map.md)

- **Critical (Must Read):**

  - **Test artifacts to be audited** — varies by test type:
    - *Automated*: Test files in the project's test directory (as configured in `project-config.json`)
    - *Performance*: Test files in `test/automated/performance/`
    - *E2E*: `test-case.md` + `project/` + `expected/` fixtures in `test/e2e-acceptance-testing/`
  - **Tracking file for the test type**:
    - *Automated*: [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md)
    - *Performance*: [Performance Test Tracking](/doc/state-tracking/permanent/performance-test-tracking.md)
    - *E2E*: [E2E Test Tracking](/test/state-tracking/permanent/e2e-test-tracking.md)
  - **Test Specification Document** - The test specification for the feature (in `/test/specifications/`)
  - [Technical Design Document](/doc/technical/tdd) - The TDD for the feature

- **Important (Load If Space):**

  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Feature development status and context
  - [Existing Test Structure](/test/) - Current test organization and patterns for consistency evaluation
  - [Development Guide](/process-framework/guides/04-implementation/development-guide.md) - Testing standards and practices
  - [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) - Performance test methodology (for performance audits)

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

### Test Type Determination

Before starting the audit, determine the test type. This determines which criteria, template, and tracking file to use.

| Test Type | Trigger Status | Tracking File | Audit Criteria | Report Template |
|-----------|---------------|---------------|----------------|-----------------|
| **Automated** (default) | `✅ Audit Approved` | test-tracking.md | 6 criteria (see [Automated Test Criteria](#automated-test-criteria)) | Standard or Lightweight |
| **Performance** | `📋 Needs Baseline` | performance-test-tracking.md | 4 criteria (see [Performance Test Criteria](#performance-test-criteria)) | Performance Audit |
| **E2E** | `📋 Needs Execution` | e2e-test-tracking.md | 5 criteria (see [E2E Test Criteria](#e2e-test-criteria)) | E2E Audit |

### Preparation

> **Re-Audit Workflow**: If a prior audit report exists for this test (check the relevant tracking file for linked reports):
> 1. **Archive prior report** — move it to the `old/` subdirectory within its category folder (e.g., `test/audits/foundation/old/`)
> 2. **Create fresh report** — use `New-TestAuditReport.ps1 -Force` to overwrite the existing report; evaluate all criteria from scratch
> 3. **Use prior report as reference** — read the archived report for context on previously identified issues, but do not carry over scores or findings — re-evaluate everything independently
>
> Re-audits follow the same full process below. The prior report provides context, not a shortcut.

> **Multi-Session Scoping**: For audit rounds spanning multiple sessions, create a tracking file to plan and track progress:
> ```powershell
> # Automated test audits (default)
> process-framework/scripts/file-creation/03-testing/New-AuditTracking.ps1 -RoundNumber 1
>
> # Performance test audits
> process-framework/scripts/file-creation/03-testing/New-AuditTracking.ps1 -RoundNumber 1 -TestType Performance
>
> # E2E test audits
> process-framework/scripts/file-creation/03-testing/New-AuditTracking.ps1 -RoundNumber 1 -TestType E2E
>
> # Scope to specific features
> process-framework/scripts/file-creation/03-testing/New-AuditTracking.ps1 -RoundNumber 1 -FeatureFilter "0.1.1,2.1.1" -Description "Foundation re-audit"
> ```
> The tracking file is created in `test/state-tracking/audit/` and auto-populates the inventory from the appropriate tracking file. Update it after each session to maintain cross-session continuity.

> **Scalability Guidance** (for large test suites):
> - **Risk-based sampling**: Not every test file needs individual audit. Prioritize: critical-path tests (full audit), recently changed tests (targeted audit), stable utility tests (spot check or skip)
> - **Batch patterns**: Group tests by feature or test type; audit one batch per session
> - **Re-audit triggers**: Re-audit when: (a) major refactoring of tested code, (b) coverage drops >10% from baseline, (c) 6+ months since last audit, (d) test failures increase without code changes

1. **Review Test Artifacts**: Examine the test artifacts appropriate for the test type:
   - *Automated*: Test suite files — understand structure and coverage
   - *Performance*: Benchmark definitions — understand measurements, tolerances, and setup
   - *E2E*: `test-case.md`, `project/` fixtures, `expected/` fixtures, `run.ps1` — understand scenario and expectations

2. **Analyze Test Specification**: Compare implementation against original test specification to understand intended behavior

3. **Understand Feature Context**: Review feature documentation, TDD, and requirements to grasp the feature's purpose and complexity

4. **Run Type-Appropriate Analysis**:

   **For Automated tests** — run code coverage analysis:
   ```powershell
   Run-Tests.ps1 -All -Coverage
   ```
   - Review coverage summary output (per-source-file percentages)
   - Open HTML coverage report for detailed line-by-line analysis
   - Note low-coverage source files relevant to the feature being audited
   - **Regression check**: Compare current coverage against last known baseline; flag drops >10% for investigation
   - This data feeds into criterion "2. Coverage Completeness" as quantitative evidence

   **For Performance tests** — review measurement setup:
   - Check warmup cycles, iteration counts, timing methodology
   - Verify tolerance thresholds against observed variance
   - Run test to check result stability (at least 2 runs)

   **For E2E tests** — verify fixture integrity:
   - Compare `project/` fixtures against scenario described in `test-case.md`
   - Verify `expected/` output files are correct for the scenario
   - Check `run.ps1` for proper setup/teardown

5. **🚨 CHECKPOINT**: Present audit scope, test type, artifact overview, and feature context to human partner for approval before conducting audit

### Execution

6. **Assess Implementation Dependencies** (Automated tests only): Before evaluating test quality, determine what can actually be tested:

   - **Implementation Status Check**: Verify which classes/components referenced in tests actually exist in the codebase
   - **Testability Analysis**: Identify tests that cannot be implemented due to missing dependencies
   - **Placeholder Assessment**: Evaluate quality and completeness of placeholder tests for missing implementations
   - **Documentation Review**: Check if placeholder tests clearly specify implementation requirements

   > For Performance and E2E tests, skip this step — these test types audit created artifacts, not code dependencies.

7. **Conduct Systematic Audit**: Evaluate tests against the criteria for the determined test type:

#### Automated Test Criteria

   Evaluate against all six quality criteria:

   - **Purpose Fulfillment**: Does the test really fulfill its intended purpose? Include **Assertion Quality Assessment**: assertion density (target ≥2 per method), behavioral vs superficial assertions, edge case coverage, and optional mutation testing.
   - **Coverage Completeness**: Are all implementable scenarios covered with tests?
   - **Test Quality & Structure**: Could the test be optimized?
   - **Performance & Efficiency**: Are tests efficient and performant?
   - **Maintainability**: Will these tests be maintainable long-term?
   - **Integration Alignment**: Do tests align with overall testing strategy?

#### Performance Test Criteria

   Evaluate against four quality criteria:

   - **Measurement Methodology**: Is the test measuring the right thing? Appropriate warmup, iteration count, timing precision, isolation from external factors. *Pass*: Stable results across runs; no I/O bottlenecks masking CPU measurements; proper warmup cycles.
   - **Tolerance Appropriateness**: Are thresholds realistic and meaningful? Not too loose (meaningless) or too tight (noisy false alarms). *Pass*: Tolerance based on observed variance, not guesswork; matches the test's performance level expectations.
   - **Baseline Readiness**: Is the test ready for baseline capture? Clean setup/teardown, deterministic environment, no external dependencies that vary. *Pass*: Consistent results in clean environment; no flaky prerequisites.
   - **Regression Detection Config**: Will the test actually catch regressions? Sensitivity vs. noise tradeoff; appropriate comparison method. *Pass*: False positive rate manageable; meaningful regressions would be caught.

#### E2E Test Criteria

   Evaluate against five quality criteria:

   - **Fixture Correctness**: Are `project/` and `expected/` directories accurate representations of the test scenario? *Pass*: Files match the scenario described in test-case.md; no stale or placeholder content.
   - **Scenario Completeness**: Does the test cover the full user workflow end-to-end, including edge cases? *Pass*: All steps from the workflow specification are exercised; boundary conditions included.
   - **Expected Outcome Accuracy**: Are the expected results in `expected/` actually correct for the given scenario? *Pass*: Expected files verified by manual review; link targets resolve correctly.
   - **Reproducibility**: Can the test be executed independently and produce consistent results? *Pass*: No hidden state dependencies; clean setup via Setup-TestEnvironment.ps1; passes on clean workspace.
   - **Precondition Coverage**: Are preconditions documented and enforceable? *Pass*: test-case.md specifies all preconditions; run.ps1 validates or sets up preconditions.

8. **Create Audit Report**: Generate audit report using automation script with the appropriate test type

   ```powershell
   # Navigate to the test-audits directory from project root
   Set-Location "test/audits"

   # Automated tests (default — same as before)
   ../../scripts/file-creation/03-testing/New-TestAuditReport.ps1 -FeatureId "X.X.X" -TestFilePath "test/automated/unit/test_example.py" -AuditorName "AI Agent"

   # Automated tests — lightweight (when ALL six criteria PASS)
   ../../scripts/file-creation/03-testing/New-TestAuditReport.ps1 -FeatureId "X.X.X" -TestFilePath "test/automated/unit/test_example.py" -AuditorName "AI Agent" -Lightweight

   # Performance tests
   ../../scripts/file-creation/03-testing/New-TestAuditReport.ps1 -FeatureId "X.X.X" -TestFilePath "test/automated/performance/test_benchmark.py" -AuditorName "AI Agent" -TestType Performance

   # E2E tests
   ../../scripts/file-creation/03-testing/New-TestAuditReport.ps1 -FeatureId "X.X.X" -TestFilePath "test/e2e-acceptance-testing/TE-E2G-001/TE-E2E-001/test-case.md" -AuditorName "AI Agent" -TestType E2E

   # Script automatically:
   # - Generates unique TE-TAR ID (format: TE-TAR-XXX)
   # - Creates audit report from type-specific template in appropriate category directory
   # - Updates TE-id-registry.json with the new ID
   # - Links audit report in the correct tracking file for the test type
   # - Returns the full path to the created audit report file
   ```

   **Script Location**: /process-framework/scripts/file-creation/03-testing/New-TestAuditReport.ps1
   **Output Locations**:
   - Automated: `test/audits/[category]/audit-report-[feature-id]-[test-file-id].md`
   - Performance: `test/audits/performance/audit-report-[feature-id]-[test-id].md`
   - E2E: `test/audits/e2e/audit-report-[feature-id]-[test-id].md`

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
   - Add bug entries to [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Needs Triage
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

12. <a id="minor-fix-authority"></a>**Minor Fix Authority**: If the audit identifies issues that can be fixed in ≤15 minutes, implement them directly during the audit session instead of routing through Tech Debt → Code Refactoring:

    **Allowed fix types** (≤15 minutes each):
    - Adding missing assertions to existing test methods (assertion density improvement)
    - Renaming tests to follow naming conventions
    - Removing dead/unreachable test code
    - Fixing trivial fixture issues (typos in expected values, stale file paths)
    - Adding missing `@pytest.mark` markers

    **NOT allowed** (route to Tech Debt → Code Refactoring):
    - Adding new test methods or test files
    - Refactoring test structure (splitting/merging test classes)
    - Fixing test infrastructure or shared fixtures
    - Any change that takes >15 minutes

    **Documentation**: Record each minor fix in the audit report's "Minor Fixes Applied" section with: what was changed, why, and time spent. This creates an audit trail and avoids double-counting in tech debt tracking.

13. **Assign Audit Status**: Determine audit outcome based on evaluation results:

    **For Automated tests**:
    - **✅ Audit Approved**: All implementable tests are complete and high quality
    - **🔄 Needs Update**: Existing tests have issues that need fixing
    - **🔴 Tests Incomplete**: Missing tests for existing implementations

    **For Performance tests**:
    - **✅ Audit Approved**: All criteria pass — test is ready for baseline capture
    - **🔍 Audit In Progress**: Multi-session audit underway — interim state until approved or marked Needs Update
    - **🔄 Needs Update**: Test has issues that need fixing before baseline capture
    - **🔴 Audit Failed**: Fundamental methodology or measurement issues

    **For E2E tests**:
    - **✅ Audit Approved**: All criteria pass — test is ready for execution
    - **🔍 Audit In Progress**: Multi-session audit underway — interim state until approved or marked Needs Update
    - **🔄 Needs Update**: Test case or fixtures need corrections before execution
    - **🔴 Audit Failed**: Scenario fundamentally flawed or fixtures incorrect

14. **Register Significant Findings as Tech Debt**: For audit findings that warrant a dedicated follow-up session (e.g., zero-assertion tests, anti-patterns, structural issues across multiple test methods), register them in [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) using `Update-TechDebt.ps1 -Add -Dims "TST"`. Minor findings that were fixed via [Minor Fix Authority](#minor-fix-authority) or that are documented in the audit report but don't need separate tracking can be skipped.

    ```powershell
    # Register significant test quality finding as tech debt
    Update-TechDebt.ps1 -Add -Description "Zero-assertion tests in test_example.py (5 methods)" -Dims "TST" -Location "test/automated/unit/test_example.py" -Priority "Medium" -EstimatedEffort "Small"
    ```

    > **Routing**: Test-related tech debt items (zero-assertion tests, anti-patterns, coverage gaps) route to [Code Refactoring](../06-maintenance/code-refactoring-task.md) (PF-TSK-022) for resolution — use the Lightweight Path with the test-only shortcut.

15. **Validate Audit Report**: Run the validation script to verify report completeness before presenting to human partner

   ```powershell
   # Navigate to scripts/validation directory from project root
   Set-Location "process-framework/scripts/validation"

   # Validate the completed audit report
   Validate-AuditReport.ps1 -ReportFile "[category]/audit-report-[feature-id]-[test-file-id].md" -Detailed
   ```

   Address any errors or warnings before proceeding. The script checks metadata completeness, type-specific evaluation criteria, audit decision consistency, required sections, and template placeholders.

16. **🚨 CHECKPOINT**: Present audit findings, quality criteria scores, any minor fixes applied, discovered bugs, tech debt items registered, and proposed audit status to human partner for review and approval

### Finalization

17. **Update Test Tracking**: **🤖 AUTOMATED** - Update tracking with audit results using the automation script with the appropriate test type

```powershell
# Navigate to scripts directory from project root
Set-Location "process-framework/scripts"

# Automated tests (default)
Update-TestFileAuditState.ps1 -TestFilePath "test/automated/unit/test_example.py" -AuditStatus "Audit Approved" -AuditorName "AI Agent" -TestCasesAudited 15 -PassedTests 14 -FailedTests 1 -MajorFindings @("Finding 1", "Finding 2") -AuditReportPath "test/audits/relative/path/to/audit-report.md"

# Performance tests
Update-TestFileAuditState.ps1 -TestType Performance -TestFilePath "test/automated/performance/test_benchmark.py" -AuditStatus "Audit Approved" -AuditorName "AI Agent" -AuditReportPath "test/audits/performance/audit-report.md"

# E2E tests
Update-TestFileAuditState.ps1 -TestType E2E -TestFilePath "test/e2e-acceptance-testing/TE-E2G-001/TE-E2E-001/test-case.md" -AuditStatus "Audit Approved" -AuditorName "AI Agent" -AuditReportPath "test/audits/e2e/audit-report.md"

# Script automatically:
# - Updates the correct tracking file based on -TestType
# - Updates feature-tracking.md with aggregated test status for the feature
# - Creates automatic backups before making changes
# - Calculates intelligent feature-level status based on all test files
```

**Available Audit Statuses**:

Automated tests:
- `"Audit Approved"` → ✅ Audit Approved
- `"Needs Update"` → 🔄 Needs Update
- `"Audit Failed"` → 🔴 Audit Failed
- `"Audit In Progress"` → 🔍 Audit In Progress

Performance and E2E tests:
- `"Audit Approved"` → ✅ Audit Approved
- `"Audit In Progress"` → 🔍 Audit In Progress
- `"Needs Update"` → 🔄 Needs Update
- `"Audit Failed"` → 🔴 Audit Failed

18. **Verify Automated Updates**: Confirm the automation script successfully updated the correct state files:

    - **Automated**: test-tracking.md + feature-tracking.md
    - **Performance**: performance-test-tracking.md + feature-tracking.md
    - **E2E**: e2e-test-tracking.md + feature-tracking.md

19. **Provide Feedback**: Deliver actionable recommendations for improvement if tests need updates

20. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Test Audit Report** - Type-specific document analyzing test quality with findings and recommendations:
  - Automated: `test/audits/[category]/audit-report-[feature-id]-[test-file-id].md`
  - Performance: `test/audits/performance/audit-report-[feature-id]-[test-id].md`
  - E2E: `test/audits/e2e/audit-report-[feature-id]-[test-id].md`
- **Updated Tracking File** - The correct tracking file updated with audit status and report link (test-tracking.md, performance-test-tracking.md, or e2e-test-tracking.md)
- **Bug Reports** - Any bugs discovered during audit documented in [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Needs Triage
- **Tech Debt Items** (if applicable) - Significant test quality findings registered in [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) with category "Testing", routed to PF-TSK-022
- **Minor Fixes** (if applicable) - Fixes ≤15 minutes applied directly during audit, documented in the audit report

## State Tracking

**🤖 FULLY AUTOMATED** - All state file updates are handled by the `Update-TestFileAuditState.ps1` script with `-TestType` parameter:

- **Automated** (`-TestType Automated`, default): [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - **Automatically updated** with audit status, detailed results, and completion timestamp
- **Performance** (`-TestType Performance`): [Performance Test Tracking](/doc/state-tracking/permanent/performance-test-tracking.md) - **Automatically updated** with audit status and report link
- **E2E** (`-TestType E2E`): [E2E Test Tracking](/test/state-tracking/permanent/e2e-test-tracking.md) - **Automatically updated** with audit status and report link
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - **Automatically updated** with intelligent aggregated test status based on all test files for the feature (all types)
- [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - **Manually updated** with any bugs discovered during audit, including test context and evidence
- [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) - **Manually updated** (via `Update-TechDebt.ps1 -Add -Dims "TST"`) with significant test quality findings, routed to [Code Refactoring](../06-maintenance/code-refactoring-task.md) (PF-TSK-022)

**Key Automation Features**:

- **Multi-Type Support**: Writes to the correct tracking file based on `-TestType` parameter
- **Intelligent Aggregation**: Calculates feature-level test status based on all associated test files (all types)
- **Automatic Backups**: Creates backups of all state files before making changes
- **Comprehensive Audit Trail**: Maintains detailed history of audit results, findings, and auditor information

**Script Location**: `/process-framework/scripts/update/Update-TestFileAuditState.ps1`
**Usage Guide**: See [Automation Usage Guide](../../scripts/AUTOMATION-USAGE-GUIDE.md) for detailed examples and parameters.

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Test audit report created with type-appropriate criteria and specific recommendations
  - [ ] All type-specific evaluation criteria addressed in the audit report (6 for automated, 4 for performance, 5 for E2E)
  - [ ] Clear audit decision made (appropriate status for the test type)
  - [ ] Minor fixes (if any) documented in audit report with time spent
- [ ] **Update State Files**: **🤖 AUTOMATED** - Verify automation script successfully updated all state tracking files
  - [ ] Executed `Update-TestFileAuditState.ps1` with appropriate `-TestType` and parameters
  - [ ] Confirmed correct tracking file updated with audit status and detailed results
  - [ ] Checked [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Test Status column shows correct aggregated status
  - [ ] Significant test quality findings registered as tech debt items in [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) (category "Testing", routed to PF-TSK-022) — or confirmed no findings warrant tech debt registration
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-030" and context "Test Audit"

## Next Tasks

**After Automated test audit**:
- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - If tests are approved, proceed with feature implementation planning
- [**Foundation Feature Implementation Task**](../04-implementation/foundation-feature-implementation-task.md) - For foundation features with approved tests
- [**Integration & Testing (PF-TSK-053)**](../04-implementation/integration-and-testing.md) - If tests need updates, return to test implementation with audit recommendations

**After Performance test audit**:
- [**Performance Baseline Capture (PF-TSK-085)**](performance-baseline-capture-task.md) - If audit approved (`✅ Audit Approved`), proceed with baseline capture
- [**Performance Test Creation (PF-TSK-084)**](performance-test-creation-task.md) - If tests need updates, return to test creation with audit recommendations

**After E2E test audit**:
- [**E2E Acceptance Test Execution (PF-TSK-070)**](e2e-acceptance-test-execution-task.md) - If audit approved (`✅ Audit Approved`), proceed with execution
- [**E2E Acceptance Test Case Creation (PF-TSK-069)**](e2e-acceptance-test-case-creation-task.md) - If tests need updates, return to case creation with audit recommendations

**Any test type**:
- [**Bug Triage Task**](../06-maintenance/bug-triage-task.md) - If bugs are discovered during audit
- [**Code Review Task**](../06-maintenance/code-review-task.md) - Review test improvements after re-implementation

## Related Resources

- [Integration & Testing (PF-TSK-053)](../04-implementation/integration-and-testing.md) - For implementing automated tests before audit
- [Performance Test Creation (PF-TSK-084)](performance-test-creation-task.md) - For creating performance tests before audit
- [E2E Acceptance Test Case Creation (PF-TSK-069)](e2e-acceptance-test-case-creation-task.md) - For creating E2E test cases before audit
- [Test Specification Creation Task](test-specification-creation-task.md) - For creating test specifications that guide implementation
- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Track automated test audit progress
- [Performance Test Tracking](/doc/state-tracking/permanent/performance-test-tracking.md) - Track performance test audit progress
- [E2E Test Tracking](/test/state-tracking/permanent/e2e-test-tracking.md) - Track E2E test audit progress
- [Development Guide](/process-framework/guides/04-implementation/development-guide.md) - Testing standards and practices
- [Performance Testing Guide](/process-framework/guides/03-testing/performance-testing-guide.md) - Performance test methodology
