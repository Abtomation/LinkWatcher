---
id: PF-TSK-005
type: Process Framework
category: Task Definition
version: 2.1
created: 2023-06-15
updated: 2026-04-03
---

# Code Review

## Purpose & Context

Review implemented code to ensure it meets quality standards, follows project coding best practices, and correctly implements the requirements specified in the Technical Design Document. This task acts as a quality gate to prevent issues from reaching production while ensuring performance, security, and maintainability standards are met.

## AI Agent Role

**Role**: Code Quality Auditor
**Mindset**: Critical but constructive, standards-focused, quality-oriented
**Focus Areas**: Coding best practices, performance, state management, external integrations, accessibility, security, maintainability
**Communication Style**: Provide specific improvement suggestions with rationale, ask about design decisions, focus on long-term maintainability and user experience

## When to Use

- After feature implementation is complete but before deployment
- When a bug fix has been implemented and needs verification
- When code needs to be evaluated against established project standards
- When significant changes have been made to critical components
- Before merging code into main branches
- When external service integration or state management changes are made

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/06-maintenance/code-review-map.md)

- **Critical (Must Read):**

  - [Technical Design Document](/doc/technical/tdd) - The technical design document for the feature
  - Source code files that were created or modified during implementation
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams
  - Project dependency configuration file - To verify dependency changes and versions

- **Important (Load If Space):**

  - Test files associated with the implementation
  - Linting/analysis configuration files - To understand code standards
  - Environment configuration files - For environment-specific settings review

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - To identify features with "👀 Ready for Review" status
  - [Architecture Decision Records](/doc/technical/adr) - For architectural context
  - [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - For test coverage context

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Always use the Code Review Checklist to ensure comprehensive reviews.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**
>
> **🚫 NO CODE CHANGES: This task is a read-only quality gate. Do NOT fix bugs, refactor code, or make any code changes during Code Review. Report all findings as bugs (via New-BugReport.ps1) or technical debt items. If the user requests code changes during review, explain that fixes should be done in a separate Bug Fixing or Code Refactoring task after the review is complete.**

### Preparation

1. Review the [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) document to identify features with "👀 Ready for Review" status
2. Select the next feature for code review
3. Review the TDD to understand the intended design and requirements
4. **Read the feature's Dimension Profile** from its implementation state file (or the bug's Dims column for bug fix reviews). Focus the review on **Critical** dimensions using the review focus points from the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md)
5. Review the implementation checklist to ensure all aspects are covered
6. Set up the development environment and ensure all dependencies are installed
7. Verify environment setup (e.g., correct Python/runtime version, tools available)
8. Install all project dependencies (e.g., `pip install -r requirements.txt`)
9. **🚨 CHECKPOINT**: Present feature selection, TDD review, dimension profile focus areas, implementation checklist, and environment setup to human partner for approval before starting code review analysis

### Pre-Review Analysis

10. Run automated code quality checks using the project's configured tools:
   ```bash
   # Commands are defined in languages-config/{language}/{language}-config.json
   # - Static analysis / linting: testing.lintCommand
   # - Test runner with coverage: testing.baseCommand + testing.coverageArgs
   # Project language and test directory are in doc/project-config.json
   #
   # Or use the framework test runner:
   pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -All -Coverage
   ```
11. Review dependency changes in the project's dependency configuration for:
   - Version compatibility
   - Security implications
   - License compliance
   - Necessity of new dependencies

### Code Review Execution

12. Examine the implemented code, focusing on:
    - **Coding Best Practices**: Language idioms, type safety, proper use of language features
    - **Architecture Adherence**: Design patterns, service layer, proper separation of concerns
    - **State Management**: State handling patterns, immutability, proper resource cleanup
    - **External Integrations**: Authentication flow, data models, error handling, connection management
    - **Performance**: Resource usage, memory management, efficient algorithms, lazy loading
    - **Accessibility**: Semantic labels, screen reader support, keyboard navigation
    - **Security**: Data validation, secure storage, authentication tokens, API security
    - **Platform Compatibility**: OS-specific considerations if applicable
    - **Error Handling**: Network errors, loading states, user-friendly error messages
    - **Testing**: Unit tests, integration tests, test coverage

### Testing Verification

13. Run and verify all test suites using the project's test runner:
    ```bash
    # Run by category (categories defined in languages-config/)
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Category unit
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -Category integration
    # Run full suite
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/test/Run-Tests.ps1 -All
    ```
14. Verify test coverage meets project standards (aim for >80% for critical paths)
15. Test the feature in relevant environments (if applicable):
    - Development environment
    - Staging/test environment
    - Target platform(s)

### Performance & Accessibility Review

16. Use profiling tools to check for:
    - Unnecessary processing or redundant operations
    - Memory leaks
    - Performance bottlenecks
17. Test accessibility features:
    - Screen reader compatibility
    - Keyboard navigation
    - Color contrast
    - Text scaling

### Security Review

18. Verify security considerations:
    - Input validation and sanitization
    - Secure data storage
    - Authentication token handling
    - API endpoint security
    - Sensitive data exposure in logs

### Defect Discovery During Review

19. **Identify Defects**: During code review, systematically identify any defects:

    - **Logic Errors**: Incorrect business logic implementation or algorithmic flaws
    - **Security Vulnerabilities**: Authentication bypasses, data exposure, injection vulnerabilities
    - **Performance Issues**: Memory leaks, inefficient queries, blocking operations
    - **Integration Problems**: API contract violations, data format mismatches
    - **Error Handling Gaps**: Missing error handling, improper exception management
    - **State Management Issues**: Incorrect state handling, state mutation problems
    - **Platform-Specific Issues**: Platform compatibility problems, accessibility violations
    - **Technical Debt**: Code that works but has known quality/design problems — shortcuts, suboptimal patterns, missing abstractions

20. **Route Discovered Defects**: Classify each finding and route to the correct tracking system:

    | Finding type | Condition | Route to | Fix task |
    |---|---|---|---|
    | **Bug** | Wrong behavior on a released/completed feature | [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) via [New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) | [Bug Triage](bug-triage-task.md) → [Bug Fixing](bug-fixing-task.md) |
    | **Tech Debt** | Code works but has quality/design problems (any feature) | [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md) via [Update-TechDebt.ps1 -Add](../../scripts/update/Update-TechDebt.ps1) | [Technical Debt Assessment](../cyclical/technical-debt-assessment-task.md) → [Code Refactoring](code-refactoring-task.md) |
    | **Implementation Gap** | Wrong behavior on an in-progress/unreleased feature | Feature's [implementation state file](/doc/state-tracking/features) section 8 (Issues & Resolutions Log) with status OPEN | Current implementation or [Feature Enhancement](../04-implementation/feature-enhancement.md) task |

    For all finding types:
    - Document in the code review findings with severity levels
    - Reference specific code locations and line numbers
    - Note impact on code review results and deployment readiness

    > **Key distinction**: Bugs are wrong behavior on released features. Tech debt is working code with quality problems. Implementation gaps are defects on features still being built. Do not route implementation gaps through Bug Triage — they are picked up by the next implementation session via the feature state file.

    **Example Bug Report Command (released features only)**:

    ```powershell
    # Navigate to the scripts directory from project root
    Set-Location "process-framework/scripts/file-creation"

    # Create bug report for issues found during code review
    ../../scripts/file-creation/06-maintenance/New-BugReport.ps1 -Title "Unhandled exception in data validation" -Description "Method validate_input() doesn't handle None parameter" -DiscoveredBy "CodeReview" -Severity "High" -Component "Data Validation" -Environment "Development" -Evidence "Code location: src/services/validator.py:142"
    ```

### Finalization

21. **🚨 CHECKPOINT**: Present code review findings, bug reports, test results, performance analysis, and security review to human partner for review before finalization
22. Document findings using the severity levels from the Code Review Checklist:
    - 🔴 **Critical**: Security vulnerabilities, crashes, data corruption
    - 🟠 **Major**: Significant functionality or maintainability issues
    - 🟡 **Minor**: Issues that should be addressed but don't block deployment
    - 🔵 **Suggestion**: Recommendations for improvement
    - 🟢 **Positive**: Acknowledge good practices and well-implemented solutions
23. Update the feature tracking document to reflect the review status
24. Update test implementation tracking based on test review results
25. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Code Review Document** - Comprehensive document with findings, recommendations, and positive acknowledgments
- **Updated Feature Tracking** - [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) with review status updated
- **Test Coverage Report** - Generated coverage report from test runner
- **Code Quality Metrics** - Results from static analysis and formatting checks
- **Performance Analysis** - Profiling tool findings and performance recommendations
- **Defect Reports** - Findings routed per step 20: bugs → [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md), tech debt → [Technical Debt Tracking](../../../doc/state-tracking/permanent/technical-debt-tracking.md), implementation gaps → feature state file

## State Tracking

The following state files must be updated as part of this task:

- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Update with:
  - Code review status (🟢 Completed/🔄 Needs Revision)
  - Test Summary status (recalculated based on test case implementation tracking updates)
  - Review date and time
  - Link to review document
  - Reviewer information (AI Agent + human partner collaboration)
  - List of major findings or concerns
  - Performance and accessibility notes
- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Update test status based on review:
  - Confirm "✅ Tests Implemented" if tests are passing and well-implemented
  - Change to "🔴 Tests Failing" if test issues are found
  - Change to "🔄 Needs Update" if tests need updates due to code changes
  - Update test coverage percentages

**Automation Available**: Use `Update-CodeReviewState.ps1` to automate state file updates. See [Automation Usage Guide](../../scripts/AUTOMATION-USAGE-GUIDE.md) for examples.

**Additional Automation**: Consider creating additional automation for:

- Automated code quality report generation
- Test coverage threshold validation
- Performance benchmark comparison

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Pre-Review Setup**: Environment and tooling verification
  - [ ] Development environment verified and tools available
  - [ ] All dependencies installed
  - [ ] Code Review Checklist reviewed and understood
- [ ] **Automated Analysis**: Code quality and testing verification

  - [ ] Static analysis / linting executed and results reviewed
  - [ ] Code formatting checked
  - [ ] All test suites executed with coverage
  - [ ] Test coverage report generated and reviewed
  - [ ] Dependency changes reviewed for security and compatibility

- [ ] **Manual Code Review**: Comprehensive code examination

  - [ ] Coding best practices verified (language idioms, type safety, proper patterns)
  - [ ] Architecture adherence confirmed (design patterns, service layer, separation of concerns)
  - [ ] State management implementation reviewed
  - [ ] External integration security and error handling verified
  - [ ] Performance considerations addressed (resource usage, memory management)
  - [ ] Accessibility features tested (screen reader, keyboard navigation, color contrast)
  - [ ] Platform compatibility verified (target environments as applicable)
  - [ ] Security review completed (input validation, secure storage, API security)
  - [ ] Defect discovery performed systematically across all review areas
  - [ ] Discovered defects routed correctly: bugs → bug-tracking (released features), tech debt → technical-debt-tracking, implementation gaps → feature state file (in-progress features)

- [ ] **Verify Outputs**: Confirm all required outputs have been produced

  - [ ] Comprehensive code review document with findings and recommendations
  - [ ] All critical and major issues identified and documented with severity levels
  - [ ] Positive aspects of the implementation acknowledged
  - [ ] Test coverage report included
  - [ ] Performance analysis completed
  - [ ] Review follows the code review checklist completely

- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) shows correct review status
  - [ ] [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) updated with test review results
  - [ ] Review date, time, and reviewer information recorded
  - [ ] Link to review document included
  - [ ] Major findings and performance notes summarized in the tracking document
  - [ ] Test coverage percentages updated
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-005" and context "Code Review"

## Next Tasks

- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - If issues were found, addresses the feedback from the code review
- [**Code Refactoring**](code-refactoring-task.md) - If technical debt or code quality issues were identified
- [**User Documentation Creation**](../07-deployment/user-documentation-creation.md) - If the feature introduces or changes user-visible behavior, create/update handbooks before release
- [**Release Deployment**](../07-deployment/release-deployment-task.md) - If the review passed and user docs are complete, proceeds to deployment preparation

- [**Technical Debt Assessment**](../cyclical/technical-debt-assessment-task.md) - If systemic issues were found that affect multiple features

## Related Resources

### General Coding Resources

- Project-specific coding standards and style guides
- Language-specific best practices documentation
- Performance optimization guidelines for your technology stack
- Accessibility implementation guides

### Project-Specific Resources

- [Architecture Decision Records](/doc/technical/adr) - Architectural context and decisions
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Feature status and dependencies
- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Test coverage and status

### Development Tools & Standards

- Project linting/analysis configuration - Code standards
- Project dependency configuration - Dependencies and versions
- [Task Creation and Improvement Guide](../../guides/support/task-creation-guide.md) - Guide for creating and improving tasks

### Automation & Scripts

- [Automation Usage Guide](../../scripts/AUTOMATION-USAGE-GUIDE.md) - Available automation scripts
- `Update-CodeReviewState.ps1` - Automated state file updates
- CLI commands for analysis and testing

### Fallback Guidance

If referenced files are missing or incomplete:

1. Refer to the [Definition of Done](/process-framework/guides/04-implementation/definition-of-done.md) as the primary quality reference
2. Focus on the review areas outlined in this task
3. Consult with your human partner for project-specific standards and requirements
