---
id: PF-GDE-031
type: Document
category: General
version: 1.1
created: 2025-07-27
updated: 2025-01-27
guide_status: Active
related_tasks: PF-TSK-020
guide_description: Guide for customizing API specification templates
guide_title: API Specification Creation Guide
related_script: New-APISpecification.ps1
change_notes: "v1.1 - Added Separation of Concerns section for IMP-097/IMP-098"
---

# API Specification Creation Guide

## Overview

This guide provides comprehensive instructions for creating and customizing API Specification documents using the New-APISpecification.ps1 script and api-specification-template-template.md. It helps you define complete API contracts, endpoint specifications, and documentation for the BreakoutBuddies project.

## When to Use

Use this guide when you need to:

- Define comprehensive API contracts and endpoint specifications
- Document REST, GraphQL, or other API types with complete details
- Create API specifications for new services or major API changes
- Establish authentication, error handling, and data model standards
- Generate developer-friendly API documentation for internal and external use
- Support API design reviews and implementation planning

> **🚨 CRITICAL**: Always use the New-APISpecification.ps1 script to create API specifications - never create them manually. This ensures proper ID assignment, metadata integration, and framework compatibility. API specifications must align with the project's API design standards and data models.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Template Structure Analysis](#template-structure-analysis) _(Optional - for template customization guides)_
4. [Customization Decision Points](#customization-decision-points) _(Optional - for template customization guides)_
5. [Separation of Concerns and Cross-Referencing](#separation-of-concerns-and-cross-referencing)
6. [Step-by-Step Instructions](#step-by-step-instructions)
7. [Quality Assurance](#quality-assurance) _(Optional - for template customization guides)_
8. [Examples](#examples)
9. [Troubleshooting](#troubleshooting)
10. [Related Resources](#related-resources)

## Prerequisites

Before you begin, ensure you have:

- Access to PowerShell and the New-APISpecification.ps1 script in `doc/product-docs/technical/api/specifications/`
- Understanding of API design principles and RESTful service patterns
- Knowledge of the project's authentication and authorization requirements
- Familiarity with JSON schema and API documentation standards
- Access to the API Design Task (PF-TSK-020) documentation
- Understanding of the project's data models and service architecture

## Background

API Specifications serve as comprehensive contracts that define how client applications interact with backend services in the BreakoutBuddies project. They establish the foundation for consistent API design, implementation, and consumption.

### Purpose of API Specifications

- **Contract Definition**: Establish clear agreements between API providers and consumers
- **Implementation Guidance**: Provide detailed specifications for developers implementing APIs
- **Documentation Standards**: Create comprehensive reference documentation for API users
- **Design Consistency**: Ensure consistent patterns across all project APIs
- **Integration Support**: Enable smooth integration between different system components

### Framework Integration

API Specifications work in conjunction with API Data Models to provide complete API documentation. They reference data models for request/response structures and integrate with the broader system architecture documentation.

## Template Structure Analysis

The API Specification template (api-specification-template-template.md) provides a comprehensive structure for documenting complete API contracts:

### Core Template Sections

**Required sections:**

- **Overview**: API name, description, type, base URL, version, and authentication method
- **Authentication**: Detailed authentication mechanism documentation
- **Endpoints**: Complete endpoint definitions with HTTP methods, parameters, and responses
- **Data Models**: Referenced data structures used in requests and responses
- **Error Handling**: Standard error response formats and status codes

**Important sections:**

- **Status Codes**: Comprehensive HTTP status code documentation for all endpoints
- **Request/Response Examples**: Realistic JSON examples for each endpoint
- **Field Descriptions**: Detailed explanations of all data fields

**Optional sections:**

- **Rate Limiting**: API usage limits and throttling policies
- **Versioning**: API version management and migration strategies
- **Security Considerations**: Additional security requirements and best practices

### Section Interdependencies

- **Overview** establishes the foundation for all other sections
- **Authentication** details are referenced throughout endpoint definitions
- **Data Models** are used by **Endpoints** for request/response specifications
- **Error Handling** patterns apply consistently across all endpoints
- **Examples** demonstrate the practical application of all specifications

## Customization Decision Points

When creating API specifications, you must make several key decisions that impact the API's design and implementation:

### API Type and Architecture Decision

**Decision**: REST vs. GraphQL vs. gRPC vs. Service Interface
**Criteria**:

- REST for standard CRUD operations and resource-based APIs
- GraphQL for complex data querying and flexible client requirements
- gRPC for high-performance internal service communication
- Service Interface for abstract service contracts
  **Impact**: Determines endpoint structure, data exchange patterns, and client implementation approaches

### Authentication Strategy Decision

**Decision**: JWT vs. API Key vs. OAuth vs. Session-based authentication
**Criteria**:

- JWT for stateless, scalable authentication with token-based access
- API Key for simple service-to-service authentication
- OAuth for third-party integrations and delegated authorization
- Session-based for traditional web application authentication
  **Impact**: Affects security implementation, client integration complexity, and scalability considerations

### Error Handling Granularity Decision

**Decision**: Simple HTTP status codes vs. detailed error response objects
**Criteria**:

- Simple approach for straightforward APIs with basic error scenarios
- Detailed approach for complex business logic with specific error conditions
- Consider client debugging needs and error recovery requirements
  **Impact**: Determines error response structure, client error handling complexity, and debugging capabilities

### Documentation Detail Level Decision

**Decision**: Minimal specification vs. comprehensive documentation
**Criteria**:

- Minimal for internal APIs with well-known usage patterns
- Comprehensive for public APIs or complex integration scenarios
- Consider developer experience and onboarding requirements
  **Impact**: Affects implementation time, maintenance overhead, and developer adoption success

## Separation of Concerns and Cross-Referencing

> **📋 Detailed Guidance**: See [Task Transition Guide - Information Flow Section](task-transition-guide.md#information-flow-and-separation-of-concerns)

API Specifications focus exclusively on **API-level concerns**: endpoint specifications, request/response contracts, authentication patterns, and service integration protocols. This section helps you understand what to document in detail vs. what to reference from other tasks.

### What API Specifications Own

**✅ Document in detail in API Specifications:**

- API endpoint specifications (paths, methods, parameters)
- Request/response schemas and data contracts
- API authentication and authorization patterns
- API error handling and status codes
- API versioning strategy
- Service integration patterns and communication protocols
- Rate limiting and throttling policies
- API-level validation rules

### What Other Tasks Own

**❌ Reference briefly, document in detail elsewhere:**

- **Database schema details** → Database Schema Design (PF-TSK-021)
  - Table structures, relationships, constraints
  - RLS policies and database-level security
  - Migration strategies and data transformations
- **Service implementation details** → TDD (PF-TSK-022)
  - Component architecture and design patterns
  - Service layer implementation
  - Business logic and algorithms
- **Functional requirements** → FDD (PF-TSK-010)
  - User stories and use cases
  - Business rules and workflows
  - Feature specifications
- **Comprehensive test plans** → Test Specification (PF-TSK-012)
  - Detailed test cases and test data
  - Testing procedures and acceptance criteria
  - Test environment setup

### Cross-Reference Standards

When creating API specifications, use the following format for cross-references:

**Standard Format:**

```markdown
> **📋 Primary Documentation**: [Task Name] ([Task ID])
> **🔗 Link**: [Document Title - Document ID] > **👤 Owner**: [Task Name]
>
> **Purpose**: [Brief explanation of what's documented elsewhere]
```

**Brief Summary Guidelines:**

- Keep summaries to 2-5 sentences
- Focus on API-level perspective
- Avoid duplicating detailed specifications
- Link to the authoritative source

### Decision Framework: When to Document vs. Reference

Use this decision tree when deciding what to include in API specifications:

1. **Is it about API contracts, endpoints, or request/response formats?**

   - ✅ YES → Document in detail in API Specification
   - ❌ NO → Continue to question 2

2. **Is it about database schema, tables, or RLS policies?**

   - ✅ YES → Brief summary + reference to Database Schema Design
   - ❌ NO → Continue to question 3

3. **Is it about service implementation, architecture, or business logic?**

   - ✅ YES → Brief summary + reference to TDD
   - ❌ NO → Continue to question 4

4. **Is it about comprehensive test cases or testing procedures?**

   - ✅ YES → Brief summary + reference to Test Specification
   - ❌ NO → Continue to question 5

5. **Is it about functional requirements or user workflows?**
   - ✅ YES → Brief summary + reference to FDD
   - ❌ NO → Document in API Specification if relevant to API design

### Common Pitfalls to Avoid

**❌ Anti-Pattern 1: Duplicating Database Schema**

- **Problem**: Copying table structures, relationships, and constraints into API specification
- **Solution**: Provide brief data access pattern summary + link to Database Schema Design

**❌ Anti-Pattern 2: Documenting Service Implementation**

- **Problem**: Including detailed component architecture, design patterns, or business logic
- **Solution**: Provide brief implementation approach + link to TDD

**❌ Anti-Pattern 3: Creating Comprehensive Test Plans**

- **Problem**: Documenting detailed test cases, test data, and testing procedures
- **Solution**: Provide brief testing considerations + link to Test Specification

**❌ Anti-Pattern 4: Repeating Functional Requirements**

- **Problem**: Copying user stories, use cases, and business rules from FDD
- **Solution**: Reference FDD for functional context, focus on API contracts

**❌ Anti-Pattern 5: Over-Documenting Validation Rules**

- **Problem**: Duplicating database constraints and business validation rules
- **Solution**: Document API-level validation only, reference schema for database constraints

## Step-by-Step Instructions

### 1. Plan API Architecture and Gather Requirements

1. **Review the service requirements and API design**:

   - Understand the business logic and data flow requirements
   - Identify the API endpoints needed and their relationships
   - Determine authentication and authorization requirements

2. **Review shared resources**:

   - **Check Response Status Catalog**: Review [Response Status Catalog](/doc/product-docs/technical/api/specifications/shared/response-status-catalog.json) to identify existing status codes for similar scenarios
   - **Review API Specifications Directory**: Read the [API Specifications README](/doc/product-docs/technical/api/specifications/README.md) for guidance on shared resources and workflow
   - Identify status codes that can be reused for your API endpoints

3. **Gather API specification parameters**:
   - **API Name**: Descriptive name for the API (e.g., "User Authentication API", "Booking Management API")
   - **API Description**: Brief explanation of the API's purpose and functionality
   - **API Type**: Type of API (REST, GraphQL, gRPC, Service Interface)

**Expected Result:** Complete understanding of the API requirements, shared resources, and parameters needed for specification creation

### 2. Create API Specification Using New-APISpecification.ps1

1. **Navigate to the API specifications directory**:

   ```powershell
   cd c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\product-docs\technical\api\specifications
   ```

2. **Execute the New-APISpecification.ps1 script**:

   ```powershell
   # Basic API specification creation
   .\New-APISpecification.ps1 -APIName "User Authentication API" -APIDescription "Handles user login, registration, and session management"

   # With specific API type
   .\New-APISpecification.ps1 -APIName "Booking Management API" -APIDescription "Manages escape room bookings and reservations" -APIType "REST" -OpenInEditor
   ```

**Expected Result:** New API specification file created with proper ID, metadata, and template structure

### 3. Update Response Status Catalog

Before customizing your API specification, add your API's status codes to the Response Status Catalog to ensure consistency across all internal APIs.

1. **Open the Response Status Catalog**:

   ```powershell
   # Open in your editor
   code c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\product-docs\technical\api\specifications\shared\response-status-catalog.json
   ```

2. **Add your API entry**:

   - Add a new entry under the `apis` object with your API name (use kebab-case, e.g., `user-registration`, `booking-management`)
   - For each endpoint, document:
     - The endpoint path (e.g., `/auth/v1/signup`)
     - The HTTP method (e.g., `POST`, `GET`)
     - All scenarios with status codes and descriptions

3. **Follow naming conventions**:

   - Use consistent scenario names: `success`, `invalid_request`, `not_found`, `unauthorized`, `forbidden`, `rate_limited`, `server_error`
   - Provide clear, specific descriptions explaining when each status code is returned
   - Include relevant context (e.g., rate limits, validation rules)

4. **Update metadata**:

   - Increment the `version` field (e.g., from `1.0.0` to `1.1.0` for new API, or `1.0.1` for minor updates)
   - Update the `last_updated` field to the current date (format: `YYYY-MM-DD`)

**Example Entry**:

```json
{
  "apis": {
    "your-api-name": {
      "endpoints": {
        "/api/v1/resource": {
          "method": "POST",
          "scenarios": {
            "success": {
              "status": 201,
              "description": "Resource created successfully"
            },
            "invalid_request": {
              "status": 400,
              "description": "Invalid input data or missing required fields"
            },
            "unauthorized": {
              "status": 401,
              "description": "Missing or invalid authentication token"
            },
            "server_error": {
              "status": 500,
              "description": "Internal server error"
            }
          }
        }
      }
    }
  }
}
```

**Expected Result:** Response Status Catalog updated with your API's canonical status codes, ready to be referenced in your API specification

### 4. Customize API Specification Content

1. **Complete the Overview and Authentication sections**:

   - Provide clear API description and purpose statement
   - Specify the base URL and API version information
   - Document the authentication mechanism with detailed requirements
   - Include any necessary authentication headers or parameters

2. **Define comprehensive endpoint specifications**:

   - Document each endpoint with HTTP method, path, and description
   - Specify all parameters (path, query, header) with types and requirements
   - Define request body schemas with realistic examples
   - Document response formats for success and error scenarios
   - **Reference the Response Status Catalog** for HTTP status codes:
     - Add a note at the beginning of your Status Codes section referencing the catalog
     - Use the canonical status codes defined in the catalog
     - Link to the specific API entry in the catalog (e.g., `apis.user-registration.endpoints["/auth/v1/signup"].scenarios`)
     - Include the status code descriptions from the catalog in your specification

3. **Create detailed data models and error handling**:

   - Reference or define data models used in requests and responses
   - Establish consistent error response formats
   - Document standard error codes and their meanings
   - Provide comprehensive field descriptions for all data structures

4. **Add practical examples and usage scenarios**:

   - Include realistic request/response examples for each endpoint
   - Demonstrate common usage patterns and workflows
   - Show error scenarios with appropriate error responses
   - Provide code snippets or integration examples where helpful

5. **Complete cross-reference sections** (see [Separation of Concerns](#separation-of-concerns-and-cross-referencing)):
   - **Database Schema Reference**: Provide brief API-level database interaction notes
     - Document data access patterns (which tables/schemas accessed)
     - Note API-level data requirements (relationships, filtering)
     - Describe security policy integration (how API respects RLS policies)
     - Link to Database Schema Design document
   - **Service Implementation Reference**: Provide brief API-level implementation notes
     - Document service integration approach (how API integrates with backend)
     - Note implementation architecture (high-level patterns)
     - Link to TDD document
   - **Testing Reference**: Provide brief API-level testing considerations
     - Document contract testing requirements (API contract validation)
     - Note integration testing requirements (service integration, auth testing)
     - Note performance testing requirements (load testing, rate limiting)
     - Link to Test Specification document

**Expected Result:** Complete API specification with comprehensive endpoint definitions, data models, practical examples, and proper cross-references

### Validation and Testing

1. **Validate API specification completeness**:

   - Verify that all endpoints are documented with complete parameter definitions
   - Check that request/response examples are realistic and match the schema definitions
   - Ensure authentication requirements are clearly specified and consistent
   - Confirm that error handling covers all relevant scenarios

2. **Test specification accuracy**:

   - Review endpoint definitions against actual or planned API implementation
   - Validate that data models align with related API Data Model documents
   - Check that HTTP status codes and error responses are appropriate
   - Ensure that examples can be used for actual API testing

3. **Review integration and consistency**:

   - Confirm the specification integrates with related API documentation
   - Verify that authentication patterns are consistent across all endpoints
   - Check that data models reference existing or planned data structures
   - Ensure naming conventions align with project standards

4. **Validate framework integration**:
   - Check that metadata fields are properly completed
   - Verify that the document follows project API documentation standards
   - Ensure compatibility with existing API specifications and patterns

## Quality Assurance

Comprehensive quality assurance ensures API specifications meet project standards and serve development teams effectively:

### Self-Review Checklist

- [ ] API overview clearly explains purpose and functionality
- [ ] All endpoints are documented with complete parameter definitions
- [ ] Authentication requirements are clearly specified and consistent
- [ ] Request/response examples are realistic and match schema definitions
- [ ] Error handling covers all relevant scenarios with appropriate status codes
- [ ] Data models are properly referenced or defined
- [ ] Cross-references and links are correct and accessible

### Validation Criteria

- **Functional validation**: API specification can be used for actual implementation
- **Content validation**: Endpoint definitions and examples are accurate and complete
- **Integration validation**: Specification integrates properly with related API documentation
- **Standards validation**: Follows project API documentation conventions
- **Usability validation**: Developers can understand and implement the API effectively

### Integration Testing Procedures

- **Implementation Alignment**: Verify specification matches actual or planned API implementation
- **Data Model Integration**: Check that referenced data models exist and are correctly linked
- **Documentation Consistency**: Ensure consistency with existing API specifications and patterns
- **Developer Review**: Validate that the specification provides sufficient detail for implementation

## Examples

### Example 1: User Authentication API Specification

Creating a comprehensive API specification for user authentication in the BreakoutBuddies application:

```powershell
# Navigate to API specifications directory
cd c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\product-docs\technical\api\specifications

# Create user authentication API specification
.\New-APISpecification.ps1 -APIName "User Authentication API" -APIDescription "Handles user login, registration, session management, and password reset functionality" -APIType "REST" -OpenInEditor
```

**Customization approach:**

- **Overview**: Define base URL, version (v1), and JWT authentication method
- **Authentication**: Document JWT token requirements, header format, and token validation
- **Endpoints**: Include POST /auth/login, POST /auth/register, POST /auth/refresh, POST /auth/logout, POST /auth/reset-password
- **Data Models**: Reference User Profile and Authentication Request data models
- **Error Handling**: Define standard error responses for authentication failures, validation errors, and server errors

**Result:** Complete API specification with detailed endpoint definitions, authentication requirements, and comprehensive error handling

### Example 2: Booking Management API Specification

Creating an API specification for escape room booking functionality:

```powershell
# Create booking management API specification
.\New-APISpecification.ps1 -APIName "Booking Management API" -APIDescription "Manages escape room bookings, reservations, and availability" -APIType "REST"
```

**Customization approach:**

- **Overview**: Define RESTful resource-based API structure with JWT authentication
- **Endpoints**: Include GET /bookings, POST /bookings, GET /bookings/{id}, PUT /bookings/{id}, DELETE /bookings/{id}, GET /availability
- **Data Models**: Reference Booking, Room, and User data models with detailed field definitions
- **Status Codes**: Comprehensive coverage including 200 OK, 201 Created, 400 Bad Request, 401 Unauthorized, 404 Not Found, 409 Conflict
- **Examples**: Realistic booking scenarios with complete request/response JSON

**Result:** Production-ready API specification that developers can use for implementation and testing

## Troubleshooting

### Script Execution Fails with Path Error

**Symptom:** New-APISpecification.ps1 script fails with "Cannot find common helpers" error

**Cause:** Script cannot locate the Common-ScriptHelpers.psm1 module due to incorrect path resolution

**Solution:**

1. Verify you're running the script from the correct directory: `doc/product-docs/technical/api/specifications/`
2. Check that the Common-ScriptHelpers.psm1 file exists at `doc/process-framework/scripts/Common-ScriptHelpers.psm1`
3. Ensure PowerShell execution policy allows script execution: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### API Specification Too Complex or Overwhelming

**Symptom:** Generated API specification template becomes difficult to manage with too many endpoints or complex data structures

**Cause:** Attempting to document multiple related APIs or overly complex service interfaces in a single specification

**Solution:**

1. Break complex APIs into separate, focused specifications (e.g., separate Authentication API from User Management API)
2. Use the Related Resources section to link related API specifications
3. Consider creating separate specifications for different API versions
4. Focus each specification on a single business domain or service responsibility

### Inconsistent Data Model References

**Symptom:** API specification references data models that don't exist or have inconsistent field definitions

**Cause:** Disconnect between API specification and actual data model documentation

**Solution:**

1. Create API Data Models first using the New-APIDataModel.ps1 script before referencing them
2. Coordinate with the API Data Model Creation Guide to ensure consistency
3. Use the Related Resources section to link to the actual data model documents
4. Review existing API data models to ensure field definitions match the specification requirements

## Related Resources

- [API Design Task (PF-TSK-020)](../../tasks/02-design/api-design-task.md) - The task that uses this guide
- [New-APISpecification.ps1 Script](../../scripts/file-creation/New-APISpecification.ps1) - Script for creating API specifications
- [API Specification Template](../../templates/templates/api-specification-template-template.md) - Template customized by this guide
- [API Data Model Creation Guide (PF-GDE-030)](api-data-model-creation-guide.md) - Guide for creating related data models
- [Guide Creation Best Practices Guide (PF-GDE-024)](guide-creation-best-practices-guide.md) - Best practices for guide creation
- [OpenAPI Specification](https://swagger.io/specification/) - External resource for API specification standards
- [REST API Design Best Practices](https://restfulapi.net/) - External resource for RESTful API design principles

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
