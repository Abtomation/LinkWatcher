---
id: PF-TSK-005
type: Process Framework
category: Task Definition
version: 2.0
created: 2023-06-15
updated: 2025-08-30
task_type: Discrete
---

# Code Review

## Purpose & Context

Review implemented code to ensure it meets quality standards, follows Flutter/Dart best practices, and correctly implements the requirements specified in the Technical Design Document. This task acts as a quality gate to prevent issues from reaching production while ensuring mobile app performance, security, and maintainability standards are met.

## AI Agent Role

**Role**: Flutter Code Quality Auditor
**Mindset**: Critical but constructive, standards-focused, quality-oriented, mobile-first
**Focus Areas**: Flutter/Dart best practices, mobile performance, Riverpod state management, Supabase integration, accessibility, security, maintainability
**Communication Style**: Provide specific improvement suggestions with rationale, ask about design decisions, focus on long-term maintainability and mobile user experience

## When to Use

- After feature implementation is complete but before deployment
- When a bug fix has been implemented and needs verification
- When code needs to be evaluated against established Flutter/Dart standards
- When significant changes have been made to critical components
- Before merging code into main branches
- When Supabase integration or state management changes are made

## Context Requirements

- [Code Review Context Map](/doc/process-framework/visualization/context-maps/06-maintenance/code-review-map.md) - Visual guide to the components relevant to this task

- **Critical (Must Read):**

  - [Technical Design Document](/doc/product-docs/technical/design) - The technical design document for the feature
  - [Code Review Checklist](/doc/product-docs/checklists/checklists/code-review-checklist.md) - Comprehensive Flutter-specific checklist for code reviews
  - Source code files that were created or modified during implementation
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams
  - ../../../../pubspec.yaml - To verify dependency changes and versions

- **Important (Load If Space):**

  - Test files associated with the implementation (unit, widget, integration tests)
  - [Feature Implementation Checklist](/doc/product-docs/checklists/checklists/feature-implementation-checklist.md) - General checklist that can be adapted for code review
  - ../../../../analysis_options.yaml - To understand linting rules and code standards
  - Environment configuration files (env/) - For environment-specific settings review

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - To identify features with "👀 Ready for Review" status
  - [Architecture Decision Records](/doc/product-docs/technical/architecture/design-docs/adr/) - For architectural context
  - [Test Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md) - For test coverage context

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Always use the Code Review Checklist to ensure comprehensive reviews.**

### Preparation

1. Review the [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) document to identify features with "👀 Ready for Review" status
2. Select the next feature for code review
3. Review the TDD to understand the intended design and requirements
4. Review the implementation checklist to ensure all aspects are covered
5. Set up the Flutter development environment and ensure all dependencies are installed
6. Run `flutter doctor` to verify environment setup
7. Execute `flutter pub get` to ensure all dependencies are available

### Pre-Review Analysis

8. Run automated code quality checks:
   ```bash
   flutter analyze                    # Static analysis
   dart format --set-exit-if-changed lib/ test/  # Code formatting check
   flutter test --coverage          # Run tests with coverage
   ```
9. Review dependency changes in ../../../../pubspec.yaml for:
   - Version compatibility
   - Security implications
   - License compliance
   - Necessity of new dependencies

### Code Review Execution

10. Examine the implemented code using the [Code Review Checklist](/doc/product-docs/checklists/checklists/code-review-checklist.md), focusing on:
    - **Flutter/Dart Best Practices**: Widget lifecycle, BuildContext usage, const constructors, null safety
    - **Architecture Adherence**: Repository pattern, service layer, proper separation of concerns
    - **State Management**: Riverpod provider usage, state immutability, proper disposal
    - **Supabase Integration**: Authentication flow, data models, error handling, real-time subscriptions
    - **Mobile Performance**: Widget rebuilds, memory management, image optimization, list builders
    - **Accessibility**: Semantic labels, screen reader support, keyboard navigation
    - **Security**: Data validation, secure storage, authentication tokens, API security
    - **Platform Compatibility**: Android/iOS/Web specific considerations
    - **Error Handling**: Network errors, loading states, user-friendly error messages
    - **Testing**: Unit tests, widget tests, integration tests, test coverage

### Testing Verification

11. Run and verify all test suites:
    ```bash
    flutter test test/unit/           # Unit tests
    flutter test test/widget/         # Widget tests
    flutter test integration_test/    # Integration tests
    ```
12. Verify test coverage meets project standards (aim for >80% for critical paths)
13. Test the feature on multiple platforms (if applicable):
    - Android device/emulator
    - iOS device/simulator
    - Web browser (if web support enabled)

### Performance & Accessibility Review

14. Use Flutter Inspector to check for:
    - Unnecessary widget rebuilds
    - Memory leaks
    - Performance bottlenecks
15. Test accessibility features:
    - Screen reader compatibility
    - Keyboard navigation
    - Color contrast
    - Text scaling

### Security Review

16. Verify security considerations:
    - Input validation and sanitization
    - Secure data storage
    - Authentication token handling
    - API endpoint security
    - Sensitive data exposure in logs

### Bug Discovery During Review

17. **Identify and Document Bugs**: During code review, systematically identify any bugs or defects:

    - **Logic Errors**: Incorrect business logic implementation or algorithmic flaws
    - **Security Vulnerabilities**: Authentication bypasses, data exposure, injection vulnerabilities
    - **Performance Issues**: Memory leaks, inefficient queries, blocking operations
    - **Integration Problems**: API contract violations, data format mismatches
    - **Error Handling Gaps**: Missing error handling, improper exception management
    - **State Management Issues**: Incorrect Riverpod usage, state mutation problems
    - **Mobile-Specific Issues**: Platform compatibility problems, accessibility violations

18. **Report Discovered Bugs**: If bugs are identified during code review:

    - Use [../../scripts/file-creation/New-BugReport.ps1](../../scripts/file-creation/New-BugReport.ps1) script to create standardized bug reports
    - Follow [Bug Reporting Guide](../../guides/guides/bug-reporting-guide.md) for consistent documentation
    - Add bug entries to [Bug Tracking](../../state-tracking/permanent/bug-tracking.md) with status 🆕 Reported
    - Include code review context and evidence in bug reports
    - Reference specific code locations and line numbers
    - Note impact on code review results and deployment readiness

    **Example Bug Report Command**:

    ```powershell
    # Navigate to the scripts directory from project root
    Set-Location "c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\process-framework\scripts\file-creation"

    # Create bug report for issues found during code review
    ../../scripts/file-creation/New-BugReport.ps1 -Title "Null pointer exception in user validation" -Description "Method getUserProfile() doesn't handle null user ID parameter" -DiscoveredBy "Code Review" -Severity "High" -Component "User Management" -Environment "Development" -Evidence "Code location: lib/services/user_service.dart:142"
    ```

### Finalization

19. Document findings using the severity levels from the Code Review Checklist:
    - 🔴 **Critical**: Security vulnerabilities, crashes, data corruption
    - 🟠 **Major**: Significant functionality or maintainability issues
    - 🟡 **Minor**: Issues that should be addressed but don't block deployment
    - 🔵 **Suggestion**: Recommendations for improvement
    - 🟢 **Positive**: Acknowledge good practices and well-implemented solutions
20. Update the feature tracking document to reflect the review status
21. Update test implementation tracking based on test review results
22. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Code Review Document** - Comprehensive document with findings, recommendations, and positive acknowledgments
- **Updated Feature Tracking** - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) with review status updated
- **Test Coverage Report** - Generated coverage report from `flutter test --coverage`
- **Code Quality Metrics** - Results from `flutter analyze` and formatting checks
- **Performance Analysis** - Flutter Inspector findings and performance recommendations
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

**Flutter-Specific Automation**: Consider creating additional automation for:

- Automated code quality report generation
- Test coverage threshold validation
- Performance benchmark comparison

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Pre-Review Setup**: Environment and tooling verification
  - [ ] Flutter development environment verified with `flutter doctor`
  - [ ] All dependencies installed with `flutter pub get`
  - [ ] Code Review Checklist reviewed and understood
- [ ] **Automated Analysis**: Code quality and testing verification

  - [ ] `flutter analyze` executed and results reviewed
  - [ ] Code formatting checked with `dart format`
  - [ ] All test suites executed (`flutter test --coverage`)
  - [ ] Test coverage report generated and reviewed
  - [ ] Dependency changes in ../../../../pubspec.yaml reviewed for security and compatibility

- [ ] **Manual Code Review**: Comprehensive code examination

  - [ ] Flutter/Dart best practices verified (const constructors, null safety, widget lifecycle)
  - [ ] Architecture adherence confirmed (repository pattern, service layer, separation of concerns)
  - [ ] Riverpod state management implementation reviewed
  - [ ] Supabase integration security and error handling verified
  - [ ] Mobile performance considerations addressed (widget rebuilds, memory management)
  - [ ] Accessibility features tested (screen reader, keyboard navigation, color contrast)
  - [ ] Platform compatibility verified (Android/iOS/Web as applicable)
  - [ ] Security review completed (input validation, secure storage, API security)
  - [ ] Bug discovery performed systematically across all review areas
  - [ ] Any discovered bugs reported using ../../scripts/file-creation/New-BugReport.ps1 script with proper context and evidence

- [ ] **Verify Outputs**: Confirm all required outputs have been produced

  - [ ] Comprehensive code review document with findings and recommendations
  - [ ] All critical and major issues identified and documented with severity levels
  - [ ] Positive aspects of the implementation acknowledged
  - [ ] Test coverage report included
  - [ ] Performance analysis completed
  - [ ] Review follows the Flutter-specific code review checklist completely

- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) shows correct review status
  - [ ] [Test Case Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md) updated with test review results
  - [ ] Review date, time, and reviewer information recorded
  - [ ] Link to review document included
  - [ ] Major findings and performance notes summarized in the tracking document
  - [ ] Test coverage percentages updated
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-005" and context "Flutter Code Review"

## Next Tasks

- [**Feature Implementation Planning**](../04-implementation/feature-implementation-planning-task.md) - If issues were found, addresses the feedback from the code review
- [**Code Refactoring**](code-refactoring-task.md) - If technical debt or code quality issues were identified
- [**Release Deployment**](../07-deployment/release-deployment-task.md) - If the review passed, proceeds to deployment preparation

- [**Technical Debt Assessment**](../cyclical/technical-debt-assessment-task.md) - If systemic issues were found that affect multiple features

## Related Resources

### Flutter/Dart Specific Resources

- [Flutter Best Practices](https://docs.flutter.dev/development/best-practices) - Official Flutter best practices guide
- [Effective Dart](https://dart.dev/guides/language/effective-dart) - Dart language best practices
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices) - Performance optimization guidelines
- [Flutter Accessibility](https://docs.flutter.dev/development/accessibility-and-localization/accessibility) - Accessibility implementation guide

### Project-Specific Resources

- [Code Review Checklist](/doc/product-docs/checklists/checklists/code-review-checklist.md) - Comprehensive Flutter-specific checklist
- [Feature Implementation Checklist](/doc/product-docs/checklists/checklists/feature-implementation-checklist.md) - Implementation guidelines
- [Architecture Decision Records](/doc/product-docs/technical/architecture/design-docs/adr/) - Architectural context and decisions
- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Feature status and dependencies
- [Test Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md) - Test coverage and status

### Development Tools & Standards

- ../../../../analysis_options.yaml - Project linting rules and code standards
- ../../../../pubspec.yaml - Dependencies and project configuration
- [Task Creation and Improvement Guide](../task-creation-guide.md) - Guide for creating and improving tasks

### Automation & Scripts

- [Automation Usage Guide](../../scripts/AUTOMATION-USAGE-GUIDE.md) - Available automation scripts
- `Update-CodeReviewState.ps1` - Automated state file updates
- Flutter CLI commands for analysis and testing

### Fallback Guidance

If referenced files are missing or incomplete:

1. Use the comprehensive [Code Review Checklist](/doc/product-docs/checklists/checklists/code-review-checklist.md) as the primary guide
2. Refer to official Flutter and Dart documentation for best practices
3. Focus on the Flutter-specific review areas outlined in this task
4. Consult with your human partner for project-specific standards and requirements
