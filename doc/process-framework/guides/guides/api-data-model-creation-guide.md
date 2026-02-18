---
id: PF-GDE-030
type: Document
category: General
version: 1.0
created: 2025-07-27
updated: 2025-07-27
guide_title: API Data Model Creation Guide
guide_status: Active
related_script: New-APIDataModel.ps1
related_tasks: PF-TSK-020
guide_description: Guide for customizing API data model templates
---
# API Data Model Creation Guide

## Overview

This guide provides comprehensive instructions for creating and customizing API Data Model documents using the New-APIDataModel.ps1 script and api-data-model-template-template.md. It helps you define standardized data structures, validation rules, and documentation for API endpoints in the BreakoutBuddies project.

## When to Use

Use this guide when you need to:
- Define API request and response data structures
- Create data transfer objects (DTOs) for API endpoints
- Document data validation rules and constraints
- Establish data model relationships and dependencies
- Define data transformation and serialization requirements
- Create comprehensive API data documentation for development teams

> **🚨 CRITICAL**: Always use the New-APIDataModel.ps1 script to create API data models - never create them manually. This ensures proper ID assignment, metadata integration, and framework compatibility. API data models must align with the project's API design standards.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Template Structure Analysis](#template-structure-analysis) *(Optional - for template customization guides)*
4. [Customization Decision Points](#customization-decision-points) *(Optional - for template customization guides)*
5. [Step-by-Step Instructions](#step-by-step-instructions)
6. [Quality Assurance](#quality-assurance) *(Optional - for template customization guides)*
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)
9. [Related Resources](#related-resources)

## Prerequisites

Before you begin, ensure you have:

- Access to PowerShell and the New-APIDataModel.ps1 script in `doc/product-docs/technical/api/models/`
- Understanding of the API design patterns and data structure requirements
- Familiarity with JSON data formats and API endpoint specifications
- Knowledge of the project's API versioning strategy
- Access to the API Design Task (PF-TSK-020) documentation
- Understanding of data validation and serialization concepts

## Background

API Data Models serve as the foundation for consistent data exchange between client applications and the BreakoutBuddies backend services. They define the structure, validation rules, and documentation for data that flows through API endpoints.

### Purpose of API Data Models
- **Data Structure Definition**: Establish clear contracts for request and response data
- **Validation Standards**: Define field requirements, data types, and constraints
- **Documentation**: Provide comprehensive reference for developers using the API
- **Versioning Support**: Enable controlled evolution of data structures over time
- **Integration Guidance**: Support consistent implementation across different platforms

### Framework Integration
API Data Models integrate with the broader API design process by providing detailed specifications that complement API endpoint definitions and support comprehensive API documentation.

## Template Structure Analysis

The API Data Model template (api-data-model-template-template.md) provides a comprehensive structure for documenting data models:

### Core Template Sections
**Required sections:**
- **Overview**: Purpose, context, and API version information
- **Data Model Definition**: Core structure, field definitions, and example data
- **Validation Rules**: Required fields, optional fields, and data constraints
- **Usage Examples**: Request and response examples with realistic data

**Important sections:**
- **Relationships**: Parent, child, and related model connections
- **Serialization Notes**: JSON handling, transformation rules, and null handling
- **Versioning**: Current version, changes, and migration considerations
- **Related Documentation**: Links to API specifications and implementation notes

**Optional sections:**
- **Performance Considerations**: Performance implications of the data model
- **Security Notes**: Security considerations for sensitive data
- **Caching Behavior**: How the model behaves in caching scenarios

### Section Interdependencies
- **Data Model Definition** drives the **Validation Rules** and **Usage Examples**
- **Relationships** section connects to other API data models in the system
- **Versioning** information supports **Migration Notes** and backward compatibility
- **Related Documentation** links provide context from API specifications

## Customization Decision Points

When creating API data models, you must make several key decisions that impact the model's effectiveness and integration:

### Data Structure Complexity Decision
**Decision**: Simple flat structure vs. nested object hierarchy
**Criteria**:
- Simple structures for basic CRUD operations
- Nested structures for complex domain objects with relationships
**Impact**: Affects validation complexity, serialization performance, and client implementation

### Field Requirement Strategy
**Decision**: Which fields should be required vs. optional
**Criteria**:
- Business logic requirements and data integrity needs
- Backward compatibility considerations for API evolution
- Client application flexibility requirements
**Impact**: Determines validation rules and error handling complexity

### Validation Granularity Decision
**Decision**: Basic type validation vs. comprehensive business rule validation
**Criteria**:
- Data quality requirements and business constraints
- Performance considerations for validation processing
- Error message clarity and debugging needs
**Impact**: Affects model documentation detail and implementation complexity

### Versioning Strategy Decision
**Decision**: How to handle model evolution and backward compatibility
**Criteria**:
- API versioning strategy and client update cycles
- Breaking vs. non-breaking change requirements
- Migration complexity and rollback considerations
**Impact**: Determines versioning documentation and migration planning needs

## Step-by-Step Instructions

### 1. Analyze API Requirements and Plan Data Model Structure

1. **Review the API endpoint specifications**:
   - Understand the data flow requirements for request and response
   - Identify the core data entities and their relationships
   - Note any existing data models that this model should integrate with

2. **Gather data model parameters**:
   - **Model Name**: Descriptive name for the data structure (e.g., "User Profile", "Authentication Request")
   - **Model Description**: Brief explanation of what the data model represents
   - **API Version**: Version of the API this model applies to (e.g., "v1", "v2.1")
   - **Related Endpoints**: List of API endpoints that will use this data model

3. **Plan the data structure complexity**:
   - Determine if a simple flat structure or nested hierarchy is needed
   - Identify required vs. optional fields based on business requirements
   - Consider validation rules and data constraints

**Expected Result:** Complete understanding of the data model requirements and parameters needed for creation

### 2. Create API Data Model Using New-APIDataModel.ps1

1. **Navigate to the API models directory**:
   ```powershell
   cd c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\product-docs\technical\api\models
   ```

2. **Execute the New-APIDataModel.ps1 script**:
   ```powershell
   # Basic API data model creation
   .\New-APIDataModel.ps1 -ModelName "User Profile" -ModelDescription "User account profile information" -ApiVersion "v1"

   # With related endpoints specified
   .\New-APIDataModel.ps1 -ModelName "Authentication Request" -ModelDescription "Login request data structure" -ApiVersion "v1" -RelatedEndpoints "/auth/login,/auth/refresh" -OpenInEditor
   ```

3. **Verify data model creation**:
   - Check the success message for the assigned ID (PD-API-XXX)
   - Note the file path in the API models directory
   - Confirm the basic template structure and metadata

**Expected Result:** New API data model file created with proper ID, metadata, and template structure

### 3. Customize Data Model Definition and Validation Rules

1. **Complete the Overview section**:
   - Provide clear purpose statement for the data model
   - Specify the context where this model is used
   - Confirm the API version information

2. **Define the core data structure**:
   - Create the JSON schema definition with field types and requirements
   - Build the field definitions table with validation rules
   - Provide realistic example data that developers can understand

3. **Specify comprehensive validation rules**:
   - List all required fields and their constraints
   - Define optional fields with default values
   - Document data constraints for strings, numbers, dates, and arrays

4. **Document relationships and dependencies**:
   - Identify parent models that contain this model
   - List child models that are nested within this model
   - Note related models and their relationship types

**Expected Result:** Comprehensive data model definition with clear structure, validation rules, and relationship documentation

### Validation and Testing

1. **Validate data model structure**:
   - Verify that all field definitions are complete and accurate
   - Check that validation rules are consistent with business requirements
   - Ensure example data matches the defined structure and constraints

2. **Test integration with API specifications**:
   - Confirm the data model aligns with related API endpoint definitions
   - Verify that request/response examples are realistic and usable
   - Check that relationships with other data models are correctly documented

3. **Review documentation completeness**:
   - Ensure all required sections are filled with meaningful content
   - Verify that links to related documentation are correct and accessible
   - Confirm that versioning information is accurate and up-to-date

4. **Validate framework integration**:
   - Check that metadata fields are properly completed
   - Verify that the document follows project naming and structure conventions
   - Ensure compatibility with existing API documentation standards

## Quality Assurance

Comprehensive quality assurance ensures API data models meet project standards and serve development teams effectively:

### Self-Review Checklist
- [ ] Data model structure is complete and accurately defined
- [ ] All field definitions include proper types, requirements, and descriptions
- [ ] Validation rules are comprehensive and align with business requirements
- [ ] Example data is realistic and demonstrates proper usage
- [ ] Relationships with other models are correctly documented
- [ ] Versioning information is accurate and complete
- [ ] Cross-references and links are correct and accessible

### Validation Criteria
- **Functional validation**: Data model structure works with API implementations
- **Content validation**: Field definitions and validation rules are accurate
- **Integration validation**: Model integrates properly with related API specifications
- **Standards validation**: Follows project API documentation conventions
- **Usability validation**: Developers can understand and implement the model effectively

### Integration Testing Procedures
- **API Specification Integration**: Verify the data model aligns with related API endpoint definitions
- **Development Team Review**: Confirm the model provides sufficient detail for implementation
- **Cross-Model Validation**: Check relationships and dependencies with other data models
- **Documentation Consistency**: Ensure consistency with existing API documentation standards
- **Version Compatibility**: Validate backward compatibility and migration considerations

## Examples

### Example 1: User Profile Data Model

Creating a comprehensive user profile data model for the BreakoutBuddies application:

```powershell
# Navigate to API models directory
cd c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\product-docs\technical\api\models

# Create user profile data model
.\New-APIDataModel.ps1 -ModelName "User Profile" -ModelDescription "User account profile information including preferences and settings" -ApiVersion "v1" -RelatedEndpoints "/users/profile,/users/update-profile" -OpenInEditor
```

**Customization approach:**
- **Data Structure**: Include user ID, personal information, preferences, and account settings
- **Validation Rules**: Email format validation, required fields for registration, optional preference fields
- **Relationships**: Link to authentication models and booking history models
- **Examples**: Provide realistic user data that demonstrates all field types

**Result:** Complete user profile data model with comprehensive field definitions and validation rules

### Example 2: Authentication Request Data Model

Creating a secure authentication request model:

```powershell
# Create authentication request data model
.\New-APIDataModel.ps1 -ModelName "Authentication Request" -ModelDescription "Login request data structure with security validation" -ApiVersion "v1" -RelatedEndpoints "/auth/login,/auth/refresh,/auth/logout"
```

**Customization approach:**
- **Data Structure**: Email/username, password, optional remember-me flag, device information
- **Validation Rules**: Strong password requirements, email format validation, device ID constraints
- **Security Notes**: Document sensitive field handling and encryption requirements
- **Versioning**: Plan for future authentication method additions (OAuth, 2FA)

**Result:** Secure authentication data model with comprehensive security considerations and validation

## Troubleshooting

### Script Execution Fails with Path Error

**Symptom:** New-APIDataModel.ps1 script fails with "Cannot find common helpers" error

**Cause:** Script cannot locate the Common-ScriptHelpers.psm1 module due to incorrect path resolution

**Solution:**
1. Verify you're running the script from the correct directory: `doc/product-docs/technical/api/models/`
2. Check that the Common-ScriptHelpers.psm1 file exists at `doc/process-framework/scripts/Common-ScriptHelpers.psm1`
3. Ensure PowerShell execution policy allows script execution: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Data Model Structure Too Complex

**Symptom:** Generated data model template becomes overwhelming with too many nested structures

**Cause:** Attempting to document overly complex data relationships in a single model

**Solution:**
1. Break complex structures into separate, related data models
2. Use the relationships section to document connections between models
3. Create parent models for high-level structures and child models for detailed components
4. Consider creating separate models for request and response data if they differ significantly

### Validation Rules Inconsistent with API Implementation

**Symptom:** Data model validation rules don't match actual API endpoint behavior

**Cause:** Disconnect between documented model and implemented API validation

**Solution:**
1. Review the actual API endpoint implementation and validation logic
2. Coordinate with development team to align model documentation with implementation
3. Update validation rules to match implemented constraints
4. Consider creating separate models for different API versions if validation differs

## Related Resources

- [API Design Task (PF-TSK-020)](../../tasks/02-design/api-design-task.md) - The task that uses this guide
- [New-APIDataModel.ps1 Script](../../scripts/file-creation/New-APIDataModel.ps1) - Script for creating API data models
- [API Data Model Template](../../templates/templates/api-data-model-template-template.md) - Template customized by this guide
- [API Specification Creation Guide](api-specification-creation-guide.md) - Guide for creating API endpoint specifications
- [Guide Creation Best Practices Guide (PF-GDE-024)](guide-creation-best-practices-guide.md) - Best practices for guide creation
- [JSON Schema Documentation](https://json-schema.org/) - External resource for JSON schema standards
- [API Documentation Best Practices](https://swagger.io/resources/articles/best-practices-in-api-documentation/) - External resource for API documentation

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
