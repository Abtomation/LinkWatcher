---
id: PF-GDE-027
type: Document
category: General
version: 1.0
created: 2025-07-27
updated: 2025-07-27
guide_description: Guide for customizing test file templates
guide_status: Active
related_tasks: PF-TSK-012
related_script: New-TestFile.ps1
guide_title: Test File Creation Guide
---

# Test File Creation Guide

## Overview

This guide provides comprehensive instructions for creating and customizing test files using the New-TestFile.ps1 script and the appropriate test file template. It helps you create properly structured test files with appropriate test types, imports, and scaffolding for unit, integration, and end-to-end testing.

## When to Use

Use this guide when you need to:

- Create new test files for components, services, or features
- Generate properly structured test scaffolding with correct imports and setup
- Ensure consistent test file organization across different test types (Unit, Integration, E2E)
- Set up test files that integrate with the project's testing framework and helpers
- Create test files that follow the project's testing standards and patterns
- Generate test files based on existing Test Specifications

> **🚨 CRITICAL**: Always use the New-TestFile.ps1 script to create test files - never create them manually. This ensures proper ID assignment, correct directory placement, and integration with the testing framework.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Template Structure Analysis](#template-structure-analysis) _(Optional - for template customization guides)_
4. [Customization Decision Points](#customization-decision-points) _(Optional - for template customization guides)_
5. [Step-by-Step Instructions](#step-by-step-instructions)
6. [Quality Assurance](#quality-assurance) _(Optional - for template customization guides)_
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)
9. [Related Resources](#related-resources)

## Prerequisites

Before you begin, ensure you have:

- Access to PowerShell and the New-TestFile.ps1 script in `test/`
- Understanding of the project's testing framework and test types (Unit, Integration, E2E)
- Familiarity with the component or feature you're creating tests for
- Access to existing Test Specifications for the component (if available)
- Knowledge of the project's testing patterns and helper functions
- Understanding of the project's directory structure for different test types

## Background

Testing in the project follows a structured approach with different test types serving specific purposes. The New-TestFile.ps1 script automates the creation of properly configured test files that integrate with the project's testing infrastructure.

### Test Types

The project supports several test types, each with specific purposes and directory structures:

- **Unit Tests** (`test/unit/` or `tests/unit/`): Test individual functions, methods, and classes in isolation
- **Integration Tests** (`test/integration/` or `tests/integration/`): Test interactions between multiple components or services
- **End-to-End Tests** (`test/e2e/` or `tests/e2e/`): Test complete user workflows across the entire application

### Test File Structure

Each generated test file includes:

- **Proper imports**: Test framework, component imports, and project-specific test helpers
- **Test environment setup**: Initialization and cleanup procedures using TestEnvSetup
- **Test scaffolding**: Group structure with setup/teardown methods
- **Placeholder test cases**: Template test methods following Arrange-Act-Assert pattern
- **Helper sections**: Areas for test-specific helper functions and mock classes

### Integration with Test Specifications

Test files are designed to implement test cases defined in Test Specifications, providing a clear path from behavioral requirements to executable tests. The template includes TODO comments that guide developers to implement specific test cases based on their Test Specification documents.

## Template Structure Analysis

The test file template provides a comprehensive structure for test files. Understanding each section helps you customize the template effectively for different testing scenarios:

### Metadata Header Section

- **Document ID**: Automatically assigned (PF-TST-XXX format)
- **Test Metadata**: Captures test name, type, and component being tested
- **Purpose**: Enables tracking and identification of test files within the framework

### Import Section

**Standard imports included**:

- The project's core test framework (e.g., pytest, unittest, jest)
- Mocking/stubbing libraries for isolating dependencies

**Customizable imports**:

- **Component imports**: TODO section for importing the component under test
- **Test helpers**: Import for test setup utilities and project-specific helpers
- **Mock imports**: Placeholder for test-specific mock classes

### Main Test Group Structure

**Purpose**: Organizes all tests for a specific component or feature
**Key elements**:

- **Group name**: Uses test name and type for clear identification
- **Setup methods**: setUpAll, setUp for test initialization
- **Teardown methods**: tearDown, tearDownAll for cleanup
- **Test environment integration**: Uses TestEnvSetup for consistent environment

### Test Case Templates

**Structure**: Follows Arrange-Act-Assert pattern
**Included templates**:

- **Happy path test**: Template for testing expected behavior
- **Error handling test**: Template for testing edge cases and error conditions
- **Placeholder sections**: TODO comments guide implementation

### Helper and Mock Sections

**Helper functions area**: Space for test-specific utility functions
**Mock classes area**: Space for test-specific mock implementations
**Purpose**: Keeps test-related code organized and reusable within the test file

### Customization Points

**Critical areas requiring customization**:

- Component imports based on what's being tested
- Test case implementation based on Test Specifications
- Mock setup for dependencies
- Helper functions for complex test scenarios

## Customization Decision Points

When creating and customizing test files, you'll face several critical decisions that impact the effectiveness of your testing:

### Test Type Selection Decision

**Decision**: Which test type should be used for this component?
**Options**:

- **Unit**: For testing individual functions, services, or business logic in isolation
- **Integration**: For testing interactions between multiple components or services
- **Component**: For testing components and their interactions at a higher level than unit tests
- **E2E**: For testing complete user workflows across the application
  **Impact**: Determines directory placement, available testing utilities, and test scope

### Component Naming Decision

**Decision**: How should the component being tested be identified?
**Criteria**:

- Use the exact class name for unit tests (e.g., "AuthenticationService")
- Use descriptive names for integration tests (e.g., "UserLoginFlow")
- Use feature names for E2E tests (e.g., "OrderProcess")
  **Impact**: Affects imports, test organization, and maintainability

### Test Scope Decision

**Decision**: What level of testing detail is appropriate?
**Criteria**:

- **Focused**: Test specific methods or behaviors in isolation
- **Comprehensive**: Test multiple related behaviors and edge cases
- **Integration-focused**: Test component interactions and data flow
  **Impact**: Determines number of test cases and complexity of setup

### Mock Strategy Decision

**Decision**: What dependencies should be mocked vs. real?
**Guidelines**:

- **Mock external services**: APIs, databases, file systems
- **Mock complex dependencies**: Other services or components not under test
- **Use real objects**: Simple data classes, value objects
- **Consider test doubles**: Stubs, spies, or fakes for specific scenarios
  **Impact**: Affects test isolation, reliability, and execution speed

### Test Data Strategy Decision

**Decision**: How should test data be managed?
**Options**:

- **Inline data**: Simple test data defined within test methods
- **Test fixtures**: Reusable test data defined in helper functions
- **External files**: JSON or other data files for complex scenarios
- **Generated data**: Dynamically created test data using builders or factories
  **Impact**: Affects test maintainability and data consistency

## Step-by-Step Instructions

### 1. Analyze Testing Requirements

1. **Identify the component or feature to test**:

   - Determine the specific class, component, service, or feature requiring tests
   - Review existing Test Specifications if available
   - Understand the component's dependencies and interactions

2. **Select appropriate test type**:

   - **Unit**: For isolated business logic, services, or utility functions
   - **Integration**: For component interactions or data flow testing
   - **Component**: For testing components and their interactions at a higher level
   - **E2E**: For complete user workflows and application features

3. **Gather component information**:
   - Component name (exact class or module name)
   - Dependencies that need mocking
   - Expected behaviors to test
   - Error conditions and edge cases

**Expected Result:** Clear understanding of what needs to be tested and which test type is appropriate

### 2. Create Test File Using New-TestFile.ps1

1. **Navigate to the project root directory**:

   ```powershell
   cd your project root
   ```

2. **Execute the New-TestFile.ps1 script**:

   ```powershell
   # Basic unit test
   doc/process-framework/scripts/file-creation/03-testing/New-TestFile.ps1 -TestName "AuthenticationService" -TestType "Unit"

   # Component test with component name
   doc/process-framework/scripts/file-creation/03-testing/New-TestFile.ps1 -TestName "LinkUpdater" -TestType "Component" -ComponentName "LinkUpdater" -OpenInEditor

   # Integration test
   doc/process-framework/scripts/file-creation/03-testing/New-TestFile.ps1 -TestName "UserLoginFlow" -TestType "Integration" -ComponentName "Authentication" -OpenInEditor

   # End-to-end test
   doc/process-framework/scripts/file-creation/03-testing/New-TestFile.ps1 -TestName "BookingProcess" -TestType "E2E" -ComponentName "BookingFlow"

   # Critical priority test (foundation component — must pass before release)
   doc/process-framework/scripts/file-creation/03-testing/New-TestFile.ps1 -TestName "CoreService" -TestType "Unit" -ComponentName "CoreService" -Priority "Critical" -FeatureId "0.1.1"

   # Extended priority test (performance — not release-blocking)
   doc/process-framework/scripts/file-creation/03-testing/New-TestFile.ps1 -TestName "LargeProjectBenchmark" -TestType "Performance" -Priority "Extended"
   ```

   **Priority guidelines** (`-Priority` parameter, default: Standard):
   - **Critical**: Foundation features, core data models, parsers — must pass before any release
   - **Standard**: Normal test coverage — integration tests, non-critical unit tests (default)
   - **Extended**: Performance benchmarks, stress tests, edge cases — not release-blocking

3. **Verify test file creation**:
   - Check the success message for the assigned ID (PF-TST-XXX)
   - Note the file path in the appropriate test directory
   - Confirm the basic template structure was applied

**Expected Result:** New test file created in the correct directory with proper template structure and metadata

### 3. Customize Imports and Setup

1. **Add component imports**:

   ```python
   # Replace TODO comment with actual imports
   from services.authentication_service import AuthenticationService
   from models.user import User
   ```

2. **Add test-specific imports**:

   ```python
   # Add mock imports
   from unittest.mock import Mock, patch
   from test_helpers.mock_database import MockDatabase

   # Add test data imports if needed
   from test_data.user_test_data import UserTestData
   ```

3. **Configure test setup**:

   ```python
   def setUp(self):
       # Initialize mocks
       self.mock_database = MockDatabase()
       self.mock_api_client = Mock()

       # Set up test data
       self.test_user = UserTestData.valid_user()
   ```

**Expected Result:** Test file with proper imports and setup configuration for the specific component being tested

### 4. Implement Test Cases

1. **Replace placeholder test cases** with actual implementations:

   ```python
   def test_authenticate_user_with_valid_credentials(self):
       # Arrange
       self.mock_api_client.login.return_value = {
           "success": True, "token": "valid_token"
       }

       # Act
       result = self.auth_service.login("user@example.com", "password")

       # Assert
       assert result.is_success is True
       assert result.token == "valid_token"
   ```

2. **Add error handling tests**:

   ```python
   def test_handle_invalid_credentials_gracefully(self):
       # Arrange
       self.mock_api_client.login.side_effect = AuthException("Invalid credentials")

       # Act & Assert
       with pytest.raises(AuthException):
           self.auth_service.login("invalid@example.com", "wrong")
   ```

3. **Implement edge case tests** based on Test Specifications:
   - Boundary conditions (empty strings, null values)
   - Network failures and timeouts
   - State transitions and lifecycle events

**Expected Result:** Comprehensive test cases that validate component behavior according to specifications

### Validation and Testing

After completing the test file customization:

1. **Validate Test Structure**:

   - Ensure all imports resolve correctly
   - Verify test setup and teardown methods are properly configured
   - Check that mock objects are correctly initialized
   - Confirm test cases follow Arrange-Act-Assert pattern

2. **Run Tests to Verify Functionality**:

   ```bash
   # Run specific test file (adapt command to your test runner)
   pytest test/automated/unit/test_authentication_service.py

   # Run all tests of a specific type
   pytest tests/unit/
   pytest tests/integration/
   ```

3. **Integration Testing**:
   - Verify tests work with project's testing infrastructure
   - Check that TestEnvSetup integration functions correctly
   - Ensure mock services integrate properly with test helpers
   - Validate test file follows project testing conventions

## Examples

### Example 1: Unit Test for Authentication Service

Creating a unit test for the AuthenticationService class:

```powershell
# Navigate to project root
cd your project root

# Create unit test file
doc/process-framework/scripts/file-creation/03-testing/New-TestFile.ps1 -TestName "AuthenticationService" -TestType "Unit" -ComponentName "AuthenticationService" -OpenInEditor
```

**Customization approach:**

- **Imports**: Add AuthenticationService, User model, and mock dependencies
- **Setup**: Initialize MockApiClient, MockSecureStorage for dependency injection
- **Test cases**: Login success, login failure, token validation, logout functionality
- **Mocks**: Mock external API calls and secure storage operations

**Result:** Comprehensive unit test file testing authentication business logic in isolation

### Example 2: Component Test for Link Updater

Creating a component test for the LinkUpdater module:

```powershell
# Create component test file
doc/process-framework/scripts/file-creation/03-testing/New-TestFile.ps1 -TestName "LinkUpdater" -TestType "Component" -ComponentName "LinkUpdater" -OpenInEditor
```

**Customization approach:**

- **Imports**: Add LinkUpdater module, file system utilities, and component testing utilities
- **Setup**: Initialize mock file system, create temporary test directories
- **Test cases**: Link detection, path calculation, atomic file updates, dry-run mode
- **Component interactions**: File reading, path resolution, backup creation, error handling

**Result:** Complete component test validating link update behavior and file interactions

## Troubleshooting

### Test File Not Created in Expected Directory

**Symptom:** Script reports success but test file cannot be found in the expected test directory

**Cause:** Incorrect test type parameter or directory structure issues

**Solution:**

1. Verify the test type parameter is one of: Unit, Integration, Component, E2E
2. Check that the target directory exists (test/unit/, test/integration/, test/component/, test/e2e/)
3. Ensure you're running the script from the project root directory
4. Verify PowerShell execution policy allows script execution

### Import Errors After Test File Creation

**Symptom:** Test file shows import errors or cannot find referenced components

**Cause:** Incorrect import paths or missing component files

**Solution:**

1. Verify the component being tested actually exists at the expected path
2. Check the import path syntax matches the project's package structure
3. Ensure all dependencies are properly added to your project's dependency file
4. Update import paths to match the actual file locations in the project
5. Add missing test helper imports from the test_helpers directory

### Tests Fail to Run Due to Setup Issues

**Symptom:** Tests fail during setup phase or TestEnvSetup initialization fails

**Cause:** Missing test environment configuration or dependency issues

**Solution:**

1. Ensure TestEnvSetup class exists in test_helpers directory
2. Verify all mock dependencies are properly initialized in setUp method
3. Check that test database or external service mocks are configured
4. Review test environment configuration for missing dependencies
5. Ensure the test framework is properly configured in the project's dependency file

## Related Resources

- [Test Specification Creation Task (PF-TSK-012)](../../tasks/03-testing/test-specification-creation-task.md) - The task that uses this guide
- [New-TestFile.ps1 Script](../../scripts/file-creation/03-testing/New-TestFile.ps1) - Script for creating test files
- Test File Template - Template customized by this guide (create language-appropriate template per project-config.json)
- [Test Specification Creation Guide](test-specification-creation-guide.md) - Guide for creating test specifications
- Your project's testing framework documentation
- Your project's mocking framework documentation
- [Project Test Structure](../../../../test/) - Existing test organization and patterns
- [Guide Creation Best Practices Guide (PF-GDE-024)](../support/guide-creation-best-practices-guide.md) - Best practices for guide creation

<!--
TEMPLATE USAGE GUIDANCE:

ENHANCED METADATA:
- related_script: Include if this guide helps customize templates created by a specific script
- related_tasks: Include task IDs that this guide supports (comma-separated)
- These fields enhance traceability and make guides easier to discover and maintain

TEMPLATE CUSTOMIZATION GUIDE SECTIONS:
For guides that help customize templates created by scripts, use these optional sections:
- Template Structure Analysis: Break down the template structure and explain each section
- Customization Decision Points: Guide users through key customization decisions
- Validation and Testing: Include within Step-by-Step Instructions for testing procedures
- Quality Assurance: Provide comprehensive QA guidance with checklists and validation criteria

GENERAL GUIDE SECTIONS:
All guides use the standard sections: Overview, When to Use, Prerequisites, Background,
Step-by-Step Instructions, Examples, Troubleshooting, Related Resources
-->
