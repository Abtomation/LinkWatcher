---
id: PF-TSK-005
type: Process Framework
category: Task Definition
version: 2.1
created: 2023-06-15
updated: 2026-03-02
task_type: Discrete
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

- [Code Review Context Map](/doc/process-framework/visualization/context-maps/06-maintenance/code-review-map.md) - Visual guide to the components relevant to this task

- **Critical (Must Read):**

  - [Technical Design Document](/doc/product-docs/technical/design) - The technical design document for the feature
  - Source code files that were created or modified during implementation
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams
  - Project dependency configuration file - To verify dependency changes and versions

- **Important (Load If Space):**

  - Test files associated with the implementation
  - Linting/analysis configuration files - To understand code standards
  - Environment configuration files - For environment-specific settings review

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - To identify features with "👀 Ready for Review" status
  - [Architecture Decision Records](/doc/product-docs/technical/architecture/design-docs/adr/) - For architectural context
  - [Test Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md) - For test coverage context

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Always use the Code Review Checklist to ensure comprehensive reviews.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. Review the [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) document to identify features with "👀 Ready for Review" status
2. Select the next feature for code review
3. Review the TDD to understand the intended design and requirements
4. Review the implementation checklist to ensure all aspects are covered
5. Set up the development environment and ensure all dependencies are installed
6. Verify environment setup (e.g., correct Python/runtime version, tools available)
7. Install all project dependencies (e.g., `pip install -r requirements.txt`)
8. **🚨 CHECKPOINT**: Present feature selection, TDD review, implementation checklist, and environment setup to human partner for approval before starting code review analysis

### Pre-Review Analysis

9. Run automated code quality checks:
   ```bash
   # Static analysis / linting
   flake8 src/ tests/               # or your project's linter
   # Code formatting check
   black --check src/ tests/        # or your project's formatter
   # Run tests with coverage
   pytest --cov=src tests/          # or your project's test runner
   ```
10. Review dependency changes in the project's dependency configuration for:
   - Version compatibility
   - Security implications
   - License compliance
   - Necessity of new dependencies

### Code Review Execution

11. Examine the implemented code, focusing on:
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

12. Run and verify all test suites:
    ```bash
    pytest tests/unit/               # Unit tests
    pytest tests/integration/        # Integration tests
    pytest tests/                    # Full test suite
    ```
13. Verify test coverage meets project standards (aim for >80% for critical paths)
14. Test the feature in relevant environments (if applicable):
    - Development environment
    - Staging/test environment
    - Target platform(s)

### Performance & Accessibility Review

15. Use profiling tools to check for:
    - Unnecessary processing or redundant operations
    - Memory leaks
    - Performance bottlenecks
16. Test accessibility features:
    - Screen reader compatibility
    - Keyboard navigation
    - Color contrast
    - Text scaling

### Security Review

17. Verify security considerations:
    - Input validation and sanitization
    - Secure data storage
    - Authentication token handling
    - API endpoint security
    - Sensitive data exposure in logs

### Bug Discovery During Review

18. **Identify and Document Bugs**: During code review, systematically identify any bugs or defects:

    - **Logic Errors**: Incorrect business logic implementation or algorithmic flaws
    - **Security Vulnerabilities**: Authentication bypasses, data exposure, injection vulnerabilities
    - **Performance Issues**: Memory leaks, inefficient queries, blocking operations
    - **Integration Problems**: API contract violations, data format mismatches
    - **Error Handling Gaps**: Missing error handling, improper exception management
    - **State Management Issues**: Incorrect state handling, state mutation problems
    - **Platform-Specific Issues**: Platform compatibility problems, accessibility violations

19. **Report Discovered Bugs**: If bugs are identified during code review:

    - Use [../../scripts/file-creation/New-BugReport.ps1](../../scripts/file-creation/New-BugReport.ps1) script to create standardized bug reports
    - Follow [Bug Reporting Guide](../../guides/guides/bug-reporting-guide.md) for consistent documentation
    - Add bug entries to [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) with status 🆕 Reported
    - Include code review context and evidence in bug reports
    - Reference specific code locations and line numbers
    - Note impact on code review results and deployment readiness

    **Example Bug Report Command**:

    ```powershell
    # Navigate to the scripts directory from project root
    Set-Location "doc/process-framework/scripts/file-creation"

    # Create bug report for issues found during code review
    ../../scripts/file-creation/New-BugReport.ps1 -Title "Unhandled exception in data validation" -Description "Method validate_input() doesn't handle None parameter" -DiscoveredBy "Code Review" -Severity "High" -Component "Data Validation" -Environment "Development" -Evidence "Code location: src/services/validator.py:142"
    ```

### Finalization

20. **🚨 CHECKPOINT**: Present code review findings, bug reports, test results, performance analysis, and security review to human partner for review before finalization
21. Document findings using the severity levels from the Code Review Checklist:
    - 🔴 **Critical**: Security vulnerabilities, crashes, data corruption
    - 🟠 **Major**: Significant functionality or maintainability issues
    - 🟡 **Minor**: Issues that should be addressed but don't block deployment
    - 🔵 **Suggestion**: Recommendations for improvement
    - 🟢 **Positive**: Acknowledge good practices and well-implemented solutions
22. Update the feature tracking document to reflect the review status
23. Update test implementation tracking based on test review results
24. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Code Review Document** - Comprehensive document with findings, recommendations, and positive acknowledgments
- **Updated Feature Tracking** - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) with review status updated
- **Test Coverage Report** - Generated coverage report from test runner
- **Code Quality Metrics** - Results from static analysis and formatting checks
- **Performance Analysis** - Profiling tool findings and performance recommendations
- **Bug Reports** - Any bugs discovered during code review documented in [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) with status 🆕 Reported

## State Tracking

The following state files must be updated as part of this task:

- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Update with:
  - Code review status (🟢 Completed/🔄 Needs Revision)
  - Test Summary status (recalculated based on test case implementation tracking updates)
  - Review date and time
  - Link to review document
  - Reviewer information (AI Agent + human partner collaboration)
  - List of major findings or concerns
  - Performance and accessibility notes
- [Test Case Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md) - Update test status based on review:
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
  - [ ] Bug discovery performed systematically across all review areas
  - [ ] Any discovered bugs reported using ../../scripts/file-creation/New-BugReport.ps1 script with proper context and evidence

- [ ] **Verify Outputs**: Confirm all required outputs have been produced

  - [ ] Comprehensive code review document with findings and recommendations
  - [ ] All critical and major issues identified and documented with severity levels
  - [ ] Positive aspects of the implementation acknowledged
  - [ ] Test coverage report included
  - [ ] Performance analysis completed
  - [ ] Review follows the code review checklist completely

- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) shows correct review status
  - [ ] [Test Case Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md) updated with test review results
  - [ ] Review date, time, and reviewer information recorded
  - [ ] Link to review document included
  - [ ] Major findings and performance notes summarized in the tracking document
  - [ ] Test coverage percentages updated
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-005" and context "Code Review"

## Next Tasks

- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - If issues were found, addresses the feedback from the code review
- [**Code Refactoring**](code-refactoring-task.md) - If technical debt or code quality issues were identified
- [**Release Deployment**](../07-deployment/release-deployment-task.md) - If the review passed, proceeds to deployment preparation

- [**Technical Debt Assessment**](../cyclical/technical-debt-assessment-task.md) - If systemic issues were found that affect multiple features

## Related Resources

### General Coding Resources

- Project-specific coding standards and style guides
- Language-specific best practices documentation
- Performance optimization guidelines for your technology stack
- Accessibility implementation guides

### Project-Specific Resources

- [Architecture Decision Records](/doc/product-docs/technical/architecture/design-docs/adr/) - Architectural context and decisions
- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Feature status and dependencies
- [Test Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md) - Test coverage and status

### Development Tools & Standards

- Project linting/analysis configuration - Code standards
- Project dependency configuration - Dependencies and versions
- [Task Creation and Improvement Guide](../task-creation-guide.md) - Guide for creating and improving tasks

### Automation & Scripts

- [Automation Usage Guide](../../scripts/AUTOMATION-USAGE-GUIDE.md) - Available automation scripts
- `Update-CodeReviewState.ps1` - Automated state file updates
- CLI commands for analysis and testing

### Fallback Guidance

If referenced files are missing or incomplete:

1. Refer to the [Definition of Done](/doc/process-framework/methodologies/definition-of-done.md) as the primary quality reference
2. Focus on the review areas outlined in this task
3. Consult with your human partner for project-specific standards and requirements
