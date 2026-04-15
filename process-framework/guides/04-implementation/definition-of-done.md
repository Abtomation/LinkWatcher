---
id: PF-MTH-001
type: Process Framework
category: Methodology
version: 1.0
created: 2023-06-15
updated: 2025-05-29
---

# Definition of Done (DoD)

This document defines the criteria that must be met before a feature or task can be considered complete in the project. As a solo developer, this serves as a personal quality checklist to maintain consistent standards across the codebase.

For detailed testing procedures, see the project's testing documentation.

## Core Requirements

For **any** code change or feature to be considered complete, it must meet these fundamental requirements:

- [ ] All code follows the project's style guide and naming conventions
- [ ] Code is properly commented where necessary (complex logic, non-obvious decisions)
- [ ] All new code has appropriate test coverage (unit, widget, integration as applicable)
- [ ] All tests pass successfully
- [ ] No linter warnings or errors remain
- [ ] Code has been manually tested on at least one physical device
- [ ] Changes have been committed with clear, descriptive commit messages

## Feature-Specific Requirements

When implementing a **new feature**, these additional criteria must be met:

- [ ] Feature meets all requirements specified in the feature description
- [ ] Feature works correctly across different screen sizes (responsive design)
- [ ] Feature has appropriate error handling for all edge cases
- [ ] Feature has appropriate loading states implemented
- [ ] Feature has been tested with slow network conditions
- [ ] All user-facing text is properly extracted to string constants (for future localization)
- [ ] Feature is accessible (appropriate contrast, semantic labels for screen readers, etc.)
- [ ] Feature has been manually tested with various inputs including edge cases
- [ ] Feature has been added to the feature tracking document with status updated to "Completed" 🟢
- [ ] Screenshots or recordings of the feature have been captured for documentation

## UI Component Requirements

For **new UI components**, these specific criteria apply:

- [ ] Component is reusable and properly parameterized
- [ ] Component works correctly with the app's theme
- [ ] Component has appropriate animations/transitions if applicable
- [ ] Component has been tested on both light and dark themes
- [ ] Component has been tested with different text sizes (accessibility)
- [ ] Component has appropriate documentation in code

## Data Model Requirements

When creating or modifying **data models**, ensure:

- [ ] Model has appropriate validation
- [ ] Model has proper serialization/deserialization methods
- [ ] Model has unit tests covering all methods and edge cases
- [ ] Model documentation is complete and up-to-date
- [ ] Database schema changes (if any) are properly implemented and tested

## API Integration Requirements

For features involving **API integration**:

- [ ] All API calls have appropriate error handling
- [ ] API responses are properly parsed and validated
- [ ] API calls have timeout handling
- [ ] API integration has been tested with mock data
- [ ] API integration has been tested with actual backend
- [ ] API documentation is up-to-date

## Performance Requirements

To ensure good performance:

- [ ] Feature does not cause noticeable latency degradation in core operations (scan, move handling, validation)
- [ ] Feature does not cause excessive memory usage (RSS stays within resource bounds)
- [ ] No regression in Operation benchmarks (verified via Performance Baseline Capture if hot-path code changed)
- [ ] If feature modifies a parser, database, updater, or handler subsystem: relevant Component benchmarks pass
- [ ] If feature affects scaling characteristics: Scale tests pass at expected thresholds
- [ ] Performance test tracking updated if new tests were added (see [Performance Test Tracking](/test/state-tracking/permanent/performance-test-tracking.md))
- [ ] Newly created performance tests have passed [Test Audit (PF-TSK-030)](/process-framework/tasks/03-testing/test-audit-task.md) with `-TestType Performance` before baseline capture (`🔍 Audit Approved` in Audit Status column)
- [ ] Newly created E2E test cases have passed [Test Audit (PF-TSK-030)](/process-framework/tasks/03-testing/test-audit-task.md) with `-TestType E2E` before execution (`🔍 Audit Approved` in Audit Status column)

## Security Requirements

For security-sensitive features:

- [ ] All user inputs are properly validated and sanitized
- [ ] Sensitive data is properly protected (not logged, properly encrypted if stored)
- [ ] Authentication and authorization are properly implemented
- [ ] Security best practices are followed

## Documentation Requirements

Documentation must be updated:

- [ ] Documentation tier reviewed and adjusted if needed (see [Process: Documentation Tier Assessment Guide](../01-planning/assessment-guide.md))
- [ ] Technical design document updated according to the (potentially adjusted) documentation tier
- [ ] Feature tracking document updated with current status and documentation tier
- [ ] README updated (if applicable)
- [ ] API documentation updated (if applicable)
- [ ] Any new configuration options documented

## Personal Review Process

As a solo developer, conduct a self-review:

1. Take a break after completing implementation (at least a few hours, ideally a day)
2. Review the code with fresh eyes, looking for:
   - Logic errors
   - Edge cases not handled
   - Opportunities for refactoring
   - Consistency with existing code
3. Run through the feature as if you were a user
4. Check against this Definition of Done document

## Technical Debt Considerations

If any technical debt is intentionally created:

- [ ] Technical debt has been documented in the code with a `// TODO:` comment
- [ ] Technical debt has been added to the technical debt tracking document
- [ ] A plan or timeline for addressing the technical debt has been created

## Final Verification

Before considering a feature truly done:

- [ ] Manually verify the feature works end-to-end
- [ ] Ensure the feature integrates properly with existing functionality
- [ ] Verify that the feature doesn't break any existing functionality

---

*This document is part of the Process Framework and defines the criteria for considering work complete.*
