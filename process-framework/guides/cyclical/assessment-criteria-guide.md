---
id: PF-GDE-022
type: Process Framework
category: Guide
version: 1.0
created: 2025-07-24
updated: 2025-07-24
guide_description: Detailed criteria for identifying technical debt
---
# Assessment Criteria Guide

## Overview

This guide provides detailed criteria for systematically identifying technical debt in your project. It defines what constitutes technical debt, provides specific indicators to look for, and establishes consistent evaluation standards across different categories of debt.

## When to Use

Use this guide when:
- Conducting technical debt assessments
- Training team members on debt identification
- Reviewing code for potential debt items
- Establishing consistent evaluation standards
- Validating debt items identified by automated tools

> **🚨 CRITICAL**: Focus on debt that impacts business value, not just code aesthetics. Every identified debt item should have a clear business justification for remediation.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Debt Categories and Criteria](#debt-categories-and-criteria)
4. [Assessment Methodology](#assessment-methodology)
5. [Examples](#examples)
6. [Troubleshooting](#troubleshooting)
7. [Related Resources](#related-resources)

## Prerequisites

Before using this guide, ensure you have:

- **Language expertise**: Understanding of your project's development patterns and best practices
- **Codebase familiarity**: Knowledge of the project's application architecture
- **Business context**: Understanding of user requirements and business priorities
- **Quality metrics access**: Ability to run code analysis tools and access quality metrics

## Background

Technical debt represents the implied cost of additional rework caused by choosing an easy solution now instead of using a better approach that would take longer. Not all suboptimal code is technical debt - it becomes debt when:

1. **It impedes future development** or maintenance
2. **It creates ongoing costs** (performance, security, maintenance)
3. **It was a conscious trade-off** or has become outdated
4. **Remediation would provide measurable value**

The assessment focuses on identifying debt that meets these criteria and can be addressed within reasonable effort.

## Debt Categories and Criteria

### 1. Code Quality Debt

**Definition**: Code that is difficult to understand, maintain, or extend due to poor structure or practices.

#### Identification Criteria:

**High Priority Indicators:**
- **Cyclomatic complexity > 10**: Methods with excessive branching logic
- **Code duplication > 50 lines**: Repeated code blocks that should be abstracted
- **Method length > 100 lines**: Functions that do too many things
- **Class size > 500 lines**: Classes with too many responsibilities

**Medium Priority Indicators:**
- **Poor naming conventions**: Variables/methods with unclear or misleading names
- **Magic numbers/strings**: Hard-coded values without explanation
- **Commented-out code**: Dead code that should be removed
- **Inconsistent formatting**: Code that doesn't follow project style guidelines

**Project-Specific Indicators:**
```python
# HIGH PRIORITY: Complex method with too many responsibilities
def process_request(self, request):
    # 150+ lines mixing validation, business logic, and formatting
    # Should be decomposed into smaller, focused methods
    pass

# MEDIUM PRIORITY: Poor state management
class RequestHandler:
    # Mutable shared state, no clear ownership
    _global_cache = {}
```

### 2. Architecture Debt

**Definition**: Structural issues that make the system harder to understand, modify, or extend.

#### Identification Criteria:

**High Priority Indicators:**
- **Tight coupling**: Classes that depend heavily on concrete implementations
- **Missing abstractions**: Repeated patterns that should be abstracted
- **Circular dependencies**: Components that depend on each other cyclically
- **God objects**: Classes that know too much or do too many things

**Medium Priority Indicators:**
- **Inconsistent patterns**: Different approaches to solving similar problems
- **Missing interfaces**: Direct dependencies on concrete classes
- **Poor separation of concerns**: Business logic mixed with UI or data access
- **Outdated architectural patterns**: Using deprecated or superseded approaches

**Project-Specific Indicators:**
```python
# HIGH PRIORITY: Business logic in presentation layer
class UserProfileView:
    def render(self):
        # Direct API calls, data processing in render method
        user_data = ApiService.get_user_data()  # Anti-pattern
        return self._format_output(user_data)

# MEDIUM PRIORITY: Inconsistent patterns
# Some modules use Repository pattern, others access DB directly
```

### 3. Performance Debt

**Definition**: Code that causes unnecessary performance degradation or resource consumption.

#### Identification Criteria:

**High Priority Indicators:**
- **Memory leaks**: Objects not properly disposed, listeners not removed
- **Inefficient algorithms**: O(n²) where O(n) is possible
- **Unnecessary rebuilds**: Widgets rebuilding more than needed
- **Blocking operations**: Synchronous operations on main thread

**Medium Priority Indicators:**
- **Large bundle sizes**: Unused dependencies or assets
- **Inefficient data structures**: Wrong data structure for the use case
- **Excessive network calls**: Multiple calls where one would suffice
- **Unoptimized images**: Large images not properly sized or compressed

**Project-Specific Indicators:**
```python
# HIGH PRIORITY: Resource leak
class DataProcessor:
    def start(self):
        self._connection = database.connect()
        self._subscription = event_bus.subscribe(self._handler)
        # Missing cleanup method - resource leak

# MEDIUM PRIORITY: Inefficient data processing
def render_items(items):
    results = []
    for item in items:
        results.append(expensive_transform(item))  # Processing on every render
    return results
```

### 4. Security Debt

**Definition**: Code that introduces security vulnerabilities or fails to follow security best practices.

#### Identification Criteria:

**High Priority Indicators:**
- **Outdated dependencies**: Libraries with known security vulnerabilities
- **Hardcoded secrets**: API keys, passwords, or tokens in source code
- **Insufficient input validation**: User input not properly sanitized
- **Weak authentication**: Insecure authentication or authorization patterns

**Medium Priority Indicators:**
- **Missing HTTPS**: HTTP connections where HTTPS should be used
- **Excessive permissions**: Requesting more permissions than needed
- **Insecure storage**: Sensitive data stored without encryption
- **Missing security headers**: Web deployment without proper security headers

**Project-Specific Indicators:**
```python
# HIGH PRIORITY: Hardcoded API key
class ApiService:
    API_KEY = 'sk-1234567890abcdef'  # Security risk

# MEDIUM PRIORITY: Insecure storage
config['user_token'] = token  # Should be encrypted, not stored in plaintext
```

### 5. Testing Debt

**Definition**: Insufficient or poor-quality tests that reduce confidence in code changes.

#### Identification Criteria:

**High Priority Indicators:**
- **Critical paths untested**: Core business logic without tests
- **Low test coverage**: <70% coverage on important modules
- **Flaky tests**: Tests that pass/fail inconsistently
- **No integration tests**: Missing end-to-end testing

**Medium Priority Indicators:**
- **Outdated test data**: Tests using obsolete data or scenarios
- **Poor test organization**: Tests that are hard to understand or maintain
- **Missing edge case tests**: Only happy path testing
- **Slow test suite**: Tests that take too long to run

**Project-Specific Indicators:**
```python
# HIGH PRIORITY: Missing tests for critical functionality
# No tests for authentication flow, data processing pipeline, etc.

# MEDIUM PRIORITY: Poor test structure
def test_everything():
    # 100+ lines of test code without helper methods
    # Multiple assertions testing different things
    pass
```

### 6. Documentation Debt

**Definition**: Missing, outdated, or poor-quality documentation that impedes development.

#### Identification Criteria:

**High Priority Indicators:**
- **Missing API documentation**: Public methods without documentation
- **Outdated architecture docs**: Documentation that doesn't match current implementation
- **No setup instructions**: Missing or incorrect development setup guide
- **Undocumented business rules**: Complex logic without explanation

**Medium Priority Indicators:**
- **Missing code comments**: Complex algorithms without explanation
- **Outdated README**: Project documentation that's out of date
- **No troubleshooting guide**: Missing guidance for common issues
- **Inconsistent documentation style**: Different formats and levels of detail

## Assessment Methodology

### 1. Systematic Code Review

1. **Automated Analysis**:
   ```bash
   # Run static analysis / linter
   # (Use your project's linting tool, e.g., flake8, pylint, eslint)
   lint .

   # Check for outdated packages
   # (Use your project's dependency tool, e.g., pip list --outdated, npm outdated)
   pip list --outdated

   # Run type checking
   # (Use your project's type checker, e.g., mypy, tsc)
   mypy src/
   ```

2. **Manual Review Process**:
   - Review recent commits for patterns
   - Examine high-change-frequency files
   - Look for TODO/FIXME comments
   - Check error logs and bug reports

### 2. Impact Assessment

For each identified debt item, evaluate:

**Business Impact:**
- **User Experience**: Does it affect user satisfaction or functionality?
- **Development Velocity**: Does it slow down feature development?
- **Maintenance Cost**: Does it increase ongoing maintenance effort?
- **Risk Level**: Could it cause system failures or security issues?

**Technical Impact:**
- **Code Quality**: Does it make the code harder to understand or modify?
- **Performance**: Does it cause measurable performance degradation?
- **Scalability**: Does it limit the system's ability to handle growth?
- **Integration**: Does it complicate integration with other systems?

### 3. Effort Estimation

Estimate remediation effort considering:

**Complexity Factors:**
- **Scope of changes**: How many files/components affected?
- **Dependencies**: What other systems or components are involved?
- **Testing requirements**: How much testing is needed?
- **Risk level**: How likely are unintended consequences?

**Resource Requirements:**
- **Skill level**: What expertise is required?
- **Team coordination**: How many people need to be involved?
- **Timeline**: How long will it realistically take?

## Examples

### Example 1: Code Quality Assessment

**Scenario**: Reviewing the user authentication module for code quality debt.

**Analysis Process:**
```python
# Found in services/auth_service.py
class AuthService:
    # 300+ lines - too large
    def authenticate_user(self, email, password,
            remember_me=False, device_id=None, metadata=None):

        # Complex method with multiple responsibilities
        if not email:  # Poor validation
            return None
        if not password or len(password) < 8:
            return None

        # 50+ lines of authentication logic
        # Mixed with logging, caching, and output formatting

        return user
```

**Debt Items Identified:**
1. **Large class**: 300+ lines violates single responsibility principle
2. **Complex method**: Authentication method does too many things
3. **Poor error handling**: Silent failures instead of proper error reporting
4. **Mixed concerns**: Authentication mixed with caching and output formatting

**Priority Assessment:**
- **Impact**: High (affects core functionality and development velocity)
- **Effort**: Medium (requires refactoring but no architectural changes)
- **Priority**: High Priority

### Example 2: Performance Assessment

**Scenario**: Analyzing the product listing endpoint for performance issues.

**Analysis Process:**
```python
# Found in views/product_list_view.py
class ProductListView:
    def render(self, request):
        # API called on every request with no caching
        products = ApiService.get_all_products()

        results = []
        for product in products:
            results.append({
                "data": product,
                "computed": process_product_data(product),  # Heavy computation per item
            })
        return results
```

**Debt Items Identified:**
1. **Unnecessary API calls**: API called on every request with no caching
2. **Inefficient list processing**: Processing all items without pagination or lazy loading
3. **Heavy computation per request**: Data processing during response generation
4. **Missing caching**: No caching of product data

**Priority Assessment:**
- **Impact**: High (poor performance, high server load)
- **Effort**: Low (can be fixed with caching and pagination)
- **Priority**: Critical Priority (Quick Win)

## Troubleshooting

### Difficulty Distinguishing Debt from Design Choices

**Symptom:** Uncertainty about whether code issues constitute technical debt

**Cause:** Lack of clear criteria or business context

**Solution:**
1. Apply the "impediment test": Does this slow down future development?
2. Consider the "cost test": Is there ongoing maintenance cost?
3. Evaluate business impact: Does this affect user experience or business goals?
4. When in doubt, discuss with team members and stakeholders

### Overwhelming Number of Potential Debt Items

**Symptom:** Assessment identifies too many issues to be actionable

**Cause:** Too broad scope or insufficient filtering

**Solution:**
1. Focus on high-impact items first
2. Group related issues into larger initiatives
3. Set realistic capacity limits for each assessment cycle
4. Use automated tools to filter out low-priority issues

### Inconsistent Assessment Results

**Symptom:** Different team members identify different debt items or priorities

**Cause:** Subjective interpretation of criteria

**Solution:**
1. Conduct calibration sessions with examples
2. Use pair assessment for complex items
3. Document specific examples of each debt category
4. Regular team discussions to align on standards

## Related Resources

- [Technical Debt Assessment Task Usage Guide](technical-debt-assessment-task-usage-guide.md) - Complete assessment process
- [Prioritization Guide](prioritization-guide.md) - How to prioritize identified debt
- Your project's style guide and best practices documentation
