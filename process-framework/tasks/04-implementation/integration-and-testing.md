---
id: PF-TSK-053
type: Process Framework
category: Task Definition
domain: development
version: 2.2
created: 2025-12-13
updated: 2026-04-06
change_notes: "v2.2 - Added Tier 1/tech-debt guidance box and conditional qualifiers for steps assuming TDD/Test Spec exist (IMP-022). Added (if applicable) to checklist items for unit-test-only sessions (IMP-023)"
---

# Integration and Testing

## Purpose & Context

Verify unit test completeness, implement integration and cross-component tests, validate end-to-end workflows, and ensure proper coverage across all required test types. Unit tests are created by implementation tasks (PF-TSK-078, PF-TSK-051, PF-TSK-022); this task verifies their completeness against the Test Specification, fills any remaining gaps, and builds the higher-level test layers (component, integration, e2e). The goal is to confirm the feature functions as a cohesive system with robust test coverage.


## AI Agent Role

**Role**: Test Engineer
**Mindset**: Quality-focused engineer specializing in test strategy, comprehensive coverage, and integration verification
**Focus Areas**: Integration test design, cross-component validation, e2e workflow testing, coverage gap analysis, mock/stub creation, error scenario testing, bug discovery
**Communication Style**: Propose test scenarios with edge cases, highlight integration risks, ask about acceptable test coverage thresholds and testing priorities

## When to Use

- After feature implementation is complete (any workflow path)
- After all implementation layers are complete in decomposed workflow (data, state, UI)
- When comprehensive test coverage is required for a feature
- When Test Specifications exist and tests need to be implemented against real code
- When integration verification is needed between components
- Before quality validation via PF-TSK-054 (decomposed workflow)
- Before Test Audit via PF-TSK-030 (standard workflow)
- **Prerequisites**: Feature implementation complete, TDD test requirements identified, testing framework configured

## When NOT to Use

- For features marked as "No Test Required" in feature tracking (assessment/documentation features)
- For pure analysis or documentation tasks that don't produce testable code
- For architectural assessment features that only establish baselines

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/04-implementation/integration-and-testing-map.md)

- **Critical (Must Read):**

  - **Test Specification Document** (if exists) - The test specification for the feature (located in `/test/specifications/feature-specs`), serving as the checklist for required test scenarios
  - **TDD (Technical Design Document)** - Testing requirements section describing test scenarios, coverage expectations, and acceptance criteria
  - **Completed Implementation Code** - All implemented feature code to be tested
  - [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Current test implementation status
  - [Test Query Tool](/process-framework/scripts/test/test_query.py) - Query test files by feature, priority, and markers
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

- **Important (Load If Space):**

  - **Feature Tracking** - [Feature details from feature-tracking.md](../../../doc/state-tracking/permanent/feature-tracking.md) for context
  - **Feature Implementation State File** (if exists) - Implementation progress and context at `/doc/state-tracking/features`
  - [Existing Test Structure](/test/) - Current test organization and patterns

- **Reference Only (Access When Needed):**
  - **Existing Test Examples** - Similar test implementations in codebase for pattern consistency
  - [Development Guide](/process-framework/guides/04-implementation/development-guide.md) - Testing standards and practices

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished!**
>
> **⚠️ MANDATORY: Use automation scripts for test file creation. Update state files throughout implementation.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

> **Tier 1 Path**: If no TDD or Test Specification exists for this feature (common for Tier 1 features), skip Steps 1–2 and derive test scenarios directly from the implementation code (Step 3) and the feature's state file. Steps 5–6 and checklist items referencing these artifacts are also N/A — base your test strategy on code analysis and coverage goals instead.

1. **Review Test Specification** (if exists): Study the test specification document for the feature to understand test requirements, scenarios, and coverage expectations
2. **Review TDD Test Requirements** (if exists): Read testing section from TDD to understand required test scenarios, acceptance criteria, and coverage thresholds
3. **Analyze Implementation Code**: Review all implemented code to understand integration points, component boundaries, and potential failure scenarios
4. **Identify Test Scenarios**: Determine which test types are needed based on the specification and project language (check `project-config.json` for valid test types)
5. **Plan Test Strategy**: Map out test types needed, mock/stub requirements, test data setup, and prioritize by risk. **Ensure test coverage addresses Critical dimensions** from the feature's Dimension Profile — e.g., Critical DI → include data integrity/atomicity tests, Critical SE → include input validation and security boundary tests. (Note: PE dimension is handled by the dedicated [Performance & E2E Test Scoping](/process-framework/tasks/03-testing/performance-and-e2e-test-scoping-task.md) → [Performance Test Creation](/process-framework/tasks/03-testing/performance-test-creation-task.md) workflow, not this task.)
6. **🚨 CHECKPOINT**: Present test specification review (if applicable), implementation code analysis, identified test scenarios, and test strategy to human partner for approval before implementation

### Execution

7. **Create Test Files**: Use the `New-TestFile.ps1` script to generate test files with proper PD-TST IDs and automatic state tracking updates

   ```powershell
   # Create test files using automation script (generates PD-TST-[SEQUENCE] IDs)
   # Test types depend on project language (auto-detected from project-config.json)
   cd process-framework/scripts/file-creation
   New-TestFile.ps1 -TestName "FeatureName" -TestType "Unit" -FeatureId "X.Y.Z" -ComponentName "ComponentName" -Priority "Critical"
   New-TestFile.ps1 -TestName "FeatureName" -TestType "Integration" -FeatureId "X.Y.Z" -ComponentName "ComponentName"

   # -Priority: Critical (must pass before release), Standard (default), Extended (not blocking)
   # Use Critical for foundation features, parsers, core data models
   # Use Extended for performance benchmarks and stress tests

   # Script automatically:
   # - Writes pytest markers (feature, priority, test_type)
   # - Creates test file from template with proper structure
   # - Updates test-tracking.md with correct file links and status
   # - Updates feature-tracking.md with test implementation progress
   ```

8. **Verify Unit Test Completeness**: Review unit tests created by implementation tasks (PF-TSK-078, PF-TSK-051, PF-TSK-022) against the Test Specification (if exists) or against the implementation code
   - Check that all specified test scenarios are covered (or, without a Test Spec, that all public methods/critical paths have tests)
   - Identify any gaps in edge case coverage, error handling, or state transitions
   - Fill remaining gaps by creating additional unit tests via `New-TestFile.ps1`
   - Verify minimum 80% code coverage for business logic
9. **Implement Component Tests**: Build tests for component-level interactions
   - Test component behavior with different state inputs
   - Test user interactions and event handling
   - Test error states and boundary conditions
10. **Implement Integration Tests**: Create end-to-end integration tests validating full workflows
   - Set up test environment with mock backends/services
   - Test complete workflows across component boundaries
   - Verify layer integration and data flow
   - Test error propagation across layers
11. **Implement Additional Test Types**: Implement any remaining test types required by the specification and project configuration
12. **Create Test Mocks and Stubs**: Build necessary mocks for external dependencies
    - Mock external services, databases, and APIs
    - Create test data fixtures and factories
    - Set up dependency injection overrides for testing
13. **Verify Test Coverage**: Run project coverage tool and validate thresholds
    - Use the project's configured coverage tool
    - Review coverage report for gaps in critical paths
14. **Update State Files**: Document test implementation, coverage metrics, and testing notes in Feature Implementation State File (if exists)
15. **(Optional) Identify Cross-Cutting Test Opportunities**: When integration testing reveals behaviors that span multiple features:
    - Check if existing tests adequately cover the cross-feature interaction
    - If not, consider creating a cross-cutting test specification using the [Cross-Cutting Test Specification Template](../../templates/03-testing/cross-cutting-test-specification-template.md)
    - Store cross-cutting specs in `/test/specifications/cross-cutting-specs/`
    - Add `cross_cutting` pytest marker to cross-cutting test files listing the additional feature IDs
    - This step is optional guidance — not every integration test warrants a formal cross-cutting specification
16. **Verify Non-Test-Suite Artifacts**: If the implementation modified any artifacts that are not exercised by the project's automated test suite (scripts, configuration generators, build definitions, deployment manifests, etc.):
    - Manually invoke each modified artifact with representative inputs
    - Verify the output matches expected behavior
    - Test the artifact in its real context (e.g., run a startup script and confirm the process launches correctly, apply a config and verify settings take effect)
    - This step is required whenever the implementation scope extends beyond source code covered by the test framework

### Finalization

17. **Run Test Suite**: Execute all implemented tests to verify they pass
18. **Review Coverage Report**: Confirm test coverage meets project thresholds (typically 80%+ for business logic)
19. **Validate Error Scenarios**: Ensure error handling and edge cases are properly tested

20. **🚨 CHECKPOINT**: Present test execution results, coverage report, and error scenario validation to human partner for review before finalizing

21. **Bug Discovery During Testing**: Systematically identify and document any bugs discovered while implementing or running tests:

    - **Implementation Bugs**: Issues found in the code being tested (logic errors, edge case failures)
    - **Test Framework Issues**: Problems with test setup, mocking, or test infrastructure
    - **Integration Problems**: Issues discovered when testing component interactions
    - **Data Handling Bugs**: Problems with data validation, transformation, or persistence
    - **Performance Issues**: Slow operations or memory leaks revealed through testing
    - **Error Handling Gaps**: Missing or inadequate error handling discovered during testing

22. **Report Discovered Bugs**: If bugs are identified during test implementation:

    - Use [New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) script to create standardized bug reports
    - Follow [Bug Reporting Guide](../../guides/06-maintenance/bug-reporting-guide.md) for consistent documentation
    - Add bug entries to [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status Reported
    - Include test implementation context and evidence in bug reports
    - Reference specific test cases that revealed the bugs

    **Example Bug Report Command**:

    ```powershell
    Set-Location "process-framework/scripts/file-creation"

    New-BugReport.ps1 -Title "Service throws exception on empty input" -Description "Method fails with exception when passed empty string instead of returning proper error" -DiscoveredBy "Testing" -Severity "High" -Component "Component Name" -Environment "Development" -Evidence "Test case: test_method_empty_input_returns_error"
    ```

23. **Mark manual test groups for re-execution**: If the feature has manual test cases, implementation changes may have invalidated previous results. Run `Update-TestExecutionStatus.ps1` to mark affected groups:
    ```bash
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1 -FeatureId "X.Y.Z" -Status "Needs Re-execution" -Reason "Implementation changes during Integration & Testing" -Confirm:\$false
    ```
24. **Update Test Status**: Update test implementation status to reflect completion (automation handles initial tracking)
24. **Validate Test Tracking**: Run validation scripts to ensure consistency
    ```powershell
    # Validate test tracking consistency
    process-framework/scripts/validation/Validate-TestTracking.ps1
    ```
25. **Update Code Inventory**: Document all test files and coverage metrics in Feature Implementation State File (if applicable)
26. **MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Test Files** - Comprehensive test suite organized by test type in the project's test directory (as configured in `project-config.json`)
- **Updated Test Tracking** - Test case implementation tracking updated with completion status via automation scripts
- **Test Results Documentation** - Record of test implementation completion and coverage metrics
- **Coverage Report** - Test coverage analysis showing percentage coverage by file/class
- **Bug Reports** - Any bugs discovered during test implementation documented in [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status Reported
- **Updated Feature Implementation State File** (if applicable) - Test implementation details, coverage metrics, and testing notes

## State Tracking

The following state files are automatically updated by the `New-TestFile.ps1` script:

- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Automatically updated with Implementation In Progress status, test file links with correct relative paths, and metadata
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Automatically updated with Test Status column reflecting implementation progress

**Manual updates required for:**

- Updating test case counts after implementation completion
- Changing status from Implementation In Progress to Needs Audit
- Updating Feature Implementation State File (if applicable) with test metrics and notes
- **Closing audit-flagged gaps**: if this session added tests that close findings from a prior `TE-TAR-*` audit report (gap-filling rather than net-new test file creation), the existing test file's audit status in `test-tracking.md` retains the stale status from the original audit. After tests pass and the associated TD is resolved, update the audit status via:
  ```powershell
  Update-TestFileAuditState.ps1 -TestFilePath <test file> -AuditStatus "Audit Approved" -AuditReportPath <original TE-TAR report>
  ```
  Only use `Audit Approved` if ALL findings from the audit are now addressed — otherwise route to [Test Audit (PF-TSK-030)](../03-testing/test-audit-task.md) for a re-audit.

## MANDATORY Task Completion Checklist

**TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Unit test completeness verified against Test Specification or implementation code (gaps filled via `New-TestFile.ps1`)
  - [ ] Component, integration, and e2e test files created using `New-TestFile.ps1` (if applicable — unit-test-only sessions skip this)
  - [ ] All tests pass when executed
  - [ ] Test coverage meets specification requirements (typically 80%+ for business logic)
  - [ ] Integration tests validate end-to-end workflows (if applicable)
  - [ ] Error handling and edge cases tested comprehensively
  - [ ] Test mocks and fixtures created for external dependencies (if applicable)
  - [ ] Coverage report generated and reviewed
  - [ ] Bug discovery performed systematically during test implementation
  - [ ] Any discovered bugs reported using `New-BugReport.ps1` script with proper context and evidence
- [ ] **Verify State Files**: Confirm all state tracking files have been automatically updated by the script
  - [ ] [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) shows correct test file links and status
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) Test Status column reflects implementation progress
- [ ] **Manual Status Updates**: Update completion status after test implementation
  - [ ] Change test status from Implementation In Progress to Needs Audit
  - [ ] Update test case counts with actual implemented test count
  - [ ] If this session closed audit-flagged gaps (TE-TAR-* findings): audit status updated via `Update-TestFileAuditState.ps1` OR routed to re-audit (PF-TSK-030)
- [ ] **Run Validation**: Execute validation scripts to ensure tracking consistency
  - [ ] Run `Validate-TestTracking.ps1` and verify no errors
- [ ] **Code Quality Verification**
  - [ ] Test code follows project testing conventions
  - [ ] Tests are maintainable and well-organized
  - [ ] Mock usage is appropriate and not excessive
  - [ ] Integration tests cover critical workflows (if applicable)
  - [ ] Test execution time is reasonable (fast feedback loop)
- [ ] **Update Feature Implementation State File** (if applicable)
  - [ ] Code Inventory section updated with test files and metrics
  - [ ] Implementation Progress section reflects testing completion
  - [ ] Testing patterns and challenges documented in Implementation Notes
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Guide](../../guides/framework/feedback-form-guide.md) for each tool used, using task ID "PF-TSK-053" and context "Integration & Testing"

## Next Tasks

- [**Test Audit (PF-TSK-030)**](../03-testing/test-audit-task.md) - Systematic quality assessment of the test implementation (standard workflow)
- [**Quality Validation (PF-TSK-054)**](quality-validation.md) - Validate complete implementation against quality standards and business requirements (decomposed workflow)
- [**Implementation Finalization (PF-TSK-055)**](implementation-finalization.md) - Complete remaining items and prepare feature for production (decomposed workflow)
- [**Code Review**](../06-maintenance/code-review-task.md) - Review implemented tests for quality and completeness

## Related Resources

- [Test Specification Creation Task](../03-testing/test-specification-creation-task.md) - For creating test specifications before implementation
- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Track test implementation progress
- [Test File Creation Guide](../../guides/03-testing/test-file-creation-guide.md) - Guide for customizing test file templates
- [Bug Reporting Guide](../../guides/06-maintenance/bug-reporting-guide.md) - Standardized procedures for reporting bugs
- [Feature Implementation State Tracking Guide](../../guides/04-implementation/feature-implementation-state-tracking-guide.md) - Guide for maintaining feature state file
- [Cross-Cutting Test Specification Template](../../templates/03-testing/cross-cutting-test-specification-template.md) - Template for cross-feature test specs
- [Development Guide](/process-framework/guides/04-implementation/development-guide.md) - Testing standards and practices
