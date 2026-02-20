---
id: PF-GDE-040
type: Document
category: General
version: 2.0
created: 2025-08-03
updated: 2026-02-20
guide_description: Comprehensive guide for using the Integration & Testing task effectively
guide_status: Active
guide_title: Integration & Testing Usage Guide
change_notes: "v2.0 - Reworked for PF-TSK-053 (absorbed PF-TSK-029), made tech-agnostic"
---

# Integration & Testing Usage Guide

## Overview

This guide provides step-by-step instructions for using the Integration & Testing task (PF-TSK-053) to implement comprehensive test suites and validate integration after feature implementation. It covers the complete workflow from preparation through finalization, including automation tools, bug discovery, and quality validation.

## When to Use

Use this guide when you need to:

- Implement tests for a feature after implementation is complete
- Fill test gaps identified from Test Specifications and TDDs
- Validate end-to-end workflows and component integration
- Create comprehensive test coverage across all required test types
- Discover and report bugs during testing

> **Note**: If Test Specifications exist, they serve as the checklist for required test scenarios. If they don't exist, derive test requirements from the TDD's testing section.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Step-by-Step Instructions](#step-by-step-instructions)
4. [Examples](#examples)
5. [Troubleshooting](#troubleshooting)
6. [Related Resources](#related-resources)

## Prerequisites

Before you begin, ensure you have:

- **Completed Feature Implementation** - All implementation layers (data, state, UI) are complete
- **Test Specification Document** (if exists) - A completed test specification for the feature (in `/test/specifications/feature-specs/`)
- **Technical Design Document** - The TDD with testing requirements section
- **Test Infrastructure** - Access to existing test directories, mock services, and test helpers
- **Project Configuration** - `project-config.json` defines valid test types for the project language

## Background

The Integration & Testing task is the single post-implementation testing task in the process framework. It consolidates test creation (formerly PF-TSK-029) with integration verification into one cohesive workflow. The task uses `New-TestFile.ps1` for automated test file creation with proper ID assignment and state tracking, and includes systematic bug discovery with `New-BugReport.ps1`.

## Step-by-Step Instructions

### Phase 1: Preparation

#### 1. Review Test Specification (if exists)

1. Open the test specification document for your feature (located in `/test/specifications/feature-specs/`)
2. Study the test requirements and structure to understand what needs to be implemented
3. Identify which test types are required based on the specification

**Expected Result:** Clear understanding of test requirements and categories needed

#### 2. Review TDD Test Requirements

1. Read the testing section from the TDD to understand required test scenarios
2. Note acceptance criteria and coverage thresholds
3. Identify integration points and component boundaries

**Expected Result:** Complete list of required test scenarios from design documentation

#### 3. Analyze Implementation Code

1. Review all implemented feature code to understand integration points
2. Identify component boundaries and potential failure scenarios
3. Map out mock/stub requirements and test data needs

**Expected Result:** Clear understanding of what needs testing and how components interact

#### 4. Plan Test Strategy

1. Determine which test types are needed (check `project-config.json` for valid types — e.g., Python: Unit/Integration/Parser/Performance; Dart: Unit/Integration/Widget/E2E)
2. Map test types to specification requirements
3. Prioritize tests by risk (critical paths first)

**Expected Result:** Test strategy with prioritized test plan

### Phase 2: Execution

#### 5. Create Test Files

Use the `New-TestFile.ps1` script to generate test files for each required category:

```powershell
# Create test files using automation script (generates PD-TST-[SEQUENCE] IDs)
cd doc/process-framework/scripts/file-creation
.\New-TestFile.ps1 -TestName "FeatureName" -TestType "Unit" -FeatureId "X.Y.Z" -ComponentName "ComponentName"
.\New-TestFile.ps1 -TestName "FeatureName" -TestType "Integration" -FeatureId "X.Y.Z" -ComponentName "ComponentName"

# Script automatically:
# - Generates unique PD-TST ID
# - Creates test file from template with proper structure
# - Updates test-implementation-tracking.md with file links and status
# - Updates test-registry.yaml with test file metadata
# - Updates feature-tracking.md with test implementation progress
```

**Expected Result:** Test files created with proper structure, IDs, and state tracking

#### 6. Implement Unit Tests

- Test individual functions/methods with various inputs and edge cases
- Test error handling and validation logic
- Test state transitions and side effects
- Achieve minimum 80% code coverage for business logic

#### 7. Implement Component Tests

- Test component behavior with different state inputs
- Test user interactions and event handling
- Test error states and boundary conditions

#### 8. Implement Integration Tests

- Set up test environment with mock backends/services
- Test complete workflows across component boundaries
- Verify layer integration and data flow
- Test error propagation across layers

#### 9. Implement Additional Test Types

Implement any remaining test types required by the specification and project language.

#### 10. Create Test Mocks and Stubs

- Mock external services, databases, and APIs
- Create test data fixtures and factories
- Set up dependency injection overrides for testing

#### 11. Verify Test Coverage

- Run the project's configured coverage tool
- Review coverage report for gaps in critical paths
- Ensure coverage meets project thresholds (typically 80%+ for business logic)

**Expected Result:** Comprehensive test suite covering all specification requirements with adequate coverage

### Phase 3: Finalization

#### 12. Run Test Suite and Validate

1. Execute all implemented tests to verify they pass
2. Confirm test coverage meets project thresholds
3. Validate error scenarios are properly tested

#### 13. Bug Discovery

Systematically identify and document any bugs found during testing:

- **Implementation Bugs**: Logic errors, edge case failures
- **Integration Problems**: Issues when testing component interactions
- **Data Handling Bugs**: Validation, transformation, or persistence issues
- **Performance Issues**: Slow operations or memory leaks
- **Error Handling Gaps**: Missing or inadequate error handling

If bugs are found, use `New-BugReport.ps1`:

```powershell
Set-Location "<project-root>/doc/process-framework/scripts/file-creation"
.\New-BugReport.ps1 -Title "Description" -Description "Details" -DiscoveredBy "Test Implementation" -Severity "High" -Component "ComponentName" -Environment "Development" -Evidence "Test case reference"
```

#### 14. Update Test Status and Validate Tracking

1. Update test implementation status to reflect completion
2. Run validation scripts:
   ```powershell
   doc/process-framework/scripts/Validate-TestTracking.ps1
   ```
3. Update Feature Implementation State File (if applicable) with test metrics

**Expected Result:** All state tracking files updated and validated

## Examples

### Example: Creating Tests for a Parser Feature (Python)

```powershell
# Create test files for Parser Framework feature
cd doc/process-framework/scripts/file-creation
.\New-TestFile.ps1 -TestName "ParserFramework" -TestType "Unit" -FeatureId "2.1.1" -ComponentName "BaseParser"
.\New-TestFile.ps1 -TestName "ParserFramework" -TestType "Integration" -FeatureId "2.1.1" -ComponentName "ParserRegistry"
```

**Unit Test Example (Python):**

```python
# test/unit/test_parser_framework.py
class TestBaseParser:
    def test_should_parse_valid_input(self):
        parser = BaseParser()
        result = parser.parse("valid input")
        assert result is not None

    def test_should_handle_empty_input(self):
        parser = BaseParser()
        result = parser.parse("")
        assert result == []
```

**Integration Test Example (Python):**

```python
# test/integration/test_parser_framework_integration.py
class TestParserRegistryIntegration:
    def test_should_dispatch_to_correct_parser(self):
        registry = ParserRegistry()
        result = registry.parse_file("test.md")
        assert isinstance(result, list)
```

## Troubleshooting

### Test files not created properly

**Symptom:** Script fails or files appear in wrong location

**Solution:** Ensure you're running from the correct directory and `project-config.json` exists with valid test type definitions. Check that the feature ID matches a known feature.

### Tests fail during execution

**Symptom:** Test failures when running test suite

**Solution:** Review test specification requirements and verify mock services are properly configured. Check that all dependencies are installed for the project.

### Test coverage insufficient

**Symptom:** Coverage below threshold after implementing all specified tests

**Solution:** Review test specification and TDD to identify missing test scenarios. Focus on critical paths and edge cases. Use the project's coverage tool to identify uncovered lines.

### Validation script reports errors

**Symptom:** `Validate-TestTracking.ps1` reports inconsistencies

**Solution:** Ensure all test files were created via `New-TestFile.ps1` (not manually). Check that test-registry.yaml entries match files on disk. Verify feature IDs are consistent across tracking files.

## Related Resources

- [Integration & Testing Task Definition](../../tasks/04-implementation/integration-and-testing.md) - Complete task definition (PF-TSK-053)
- [Test Specification Creation Task](../../tasks/03-testing/test-specification-creation-task.md) - For creating test specifications before implementation
- [Test Audit Task](../../tasks/03-testing/test-audit-task.md) - Quality assessment of test implementations
- [Test Implementation Tracking](../../state-tracking/permanent/test-implementation-tracking.md) - Track progress
- [Test Registry](/test/test-registry.yaml) - Central registry of test files with IDs and metadata
- [Test File Creation Guide](test-file-creation-guide.md) - Guide for customizing test file templates
- [Bug Reporting Guide](bug-reporting-guide.md) - Standardized procedures for reporting bugs
- [Cross-Cutting Test Specification Template](../../templates/templates/cross-cutting-test-specification-template.md) - Template for cross-feature test specs
- [Development Guide](/doc/product-docs/guides/guides/development-guide.md) - Testing standards and practices
