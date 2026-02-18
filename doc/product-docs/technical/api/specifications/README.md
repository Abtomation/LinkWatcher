# API Specifications Directory

## Overview

This directory contains all API specifications and shared resources for the BreakoutBuddies project. All APIs documented here are **internal-only** and designed exclusively for use within the BreakoutBuddies application ecosystem.

## 🔒 API Scope

**IMPORTANT**: All BreakoutBuddies APIs are internal APIs:

- **Internal Use Only**: These APIs are not public-facing and are designed exclusively for internal application components
- **No External Access**: APIs are not intended for third-party integrations or external consumers
- **Security Model**: Authentication and authorization are designed for internal service-to-service communication
- **Documentation Audience**: API documentation is intended for internal development teams only

## Directory Structure

```
specifications/
├── README.md                          # This file - directory overview and usage guide
├── specifications/                    # Individual API specification documents
│   └── user-registration-api.md      # Example: User Registration API specification
├── shared/                            # Shared resources used across all APIs
│   └── response-status-catalog.json  # Canonical HTTP status codes for all APIs
└── New-APISpecification.ps1          # Script for creating new API specifications
```

## Shared Resources

### Response Status Catalog

**Location**: `shared/response-status-catalog.json`

The Response Status Catalog is the **single source of truth** for HTTP status codes used across all BreakoutBuddies internal APIs. It provides:

- **Canonical Status Codes**: Standardized HTTP status codes for common scenarios
- **Consistent Responses**: Ensures all APIs return the same status codes for similar situations
- **API-Specific Scenarios**: Documents status codes for each API endpoint
- **Descriptive Context**: Includes descriptions explaining when each status code is used

#### Purpose

The catalog ensures consistency across all internal APIs by:

1. **Preventing Status Code Drift**: All APIs reference the same canonical definitions
2. **Improving Developer Experience**: Developers know what status codes to expect
3. **Simplifying Testing**: Test cases can reference standard status codes
4. **Facilitating Documentation**: API specifications reference the catalog instead of duplicating information

#### Structure

The catalog is organized by API and endpoint:

```json
{
  "metadata": {
    "description": "Canonical HTTP status codes for BreakoutBuddies internal APIs",
    "version": "1.0.0",
    "last_updated": "2025-08-25"
  },
  "apis": {
    "api-name": {
      "endpoints": {
        "/endpoint/path": {
          "method": "HTTP_METHOD",
          "scenarios": {
            "scenario_name": {
              "status": 200,
              "description": "Description of when this status is returned"
            }
          }
        }
      }
    }
  }
}
```

#### Usage in API Specifications

When creating or updating API specifications:

1. **Reference the Catalog**: Check `response-status-catalog.json` for existing status code definitions
2. **Use Canonical Codes**: Use the status codes defined in the catalog for your endpoints
3. **Add New Scenarios**: If your API has unique scenarios, add them to the catalog first
4. **Link in Documentation**: Reference the catalog in your API specification's Status Codes section

**Example Reference in API Specification**:

```markdown
## Status Codes

This API uses the canonical status codes defined in the [Response Status Catalog](../shared/response-status-catalog.json).

### POST /auth/v1/signup

See: `apis.user-registration.endpoints["/auth/v1/signup"].scenarios` in the Response Status Catalog.

- `200 OK`: User successfully created, verification email sent
- `400 Bad Request`: Invalid email format, weak password, or missing required fields
- `409 Conflict`: Email already registered
- `429 Too Many Requests`: Rate limit exceeded (5 attempts per hour per IP)
- `500 Internal Server Error`: Server error or email service failure
```

#### Maintaining the Catalog

When adding new APIs or endpoints:

1. **Update the Catalog First**: Add your API's status codes to `response-status-catalog.json`
2. **Follow Existing Patterns**: Use consistent scenario naming (e.g., `success`, `invalid_request`, `not_found`)
3. **Provide Clear Descriptions**: Explain when each status code is returned
4. **Update Metadata**: Increment the version and update the `last_updated` timestamp
5. **Document in API Spec**: Reference the catalog in your API specification

## Creating New API Specifications

To create a new API specification, use the `New-APISpecification.ps1` script:

```powershell
# Navigate to the specifications directory
cd c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\product-docs\technical\api\specifications

# Create a new API specification
.\New-APISpecification.ps1 -APIName "Your API Name" -APIDescription "Brief description of your API"

# With specific API type and auto-open in editor
.\New-APISpecification.ps1 -APIName "Your API Name" -APIDescription "Brief description" -APIType "REST" -OpenInEditor
```

**Important**: Always use the script to create API specifications - never create them manually. This ensures proper ID assignment, metadata integration, and framework compatibility.

## API Specification Workflow

Follow this workflow when working with API specifications:

1. **Plan API Architecture**: Review requirements and design the API structure
2. **Check Response Status Catalog**: Review existing status codes for similar scenarios
3. **Update Catalog**: Add your API's status codes to `response-status-catalog.json`
4. **Create Specification**: Use `New-APISpecification.ps1` to generate the specification document
5. **Complete Documentation**: Fill in all sections of the API specification
6. **Reference Catalog**: Link to the Response Status Catalog in your status codes section
7. **Review and Validate**: Ensure consistency with other APIs and the catalog

## Related Resources

- **API Design Task**: [PF-TSK-020](../../../process-framework/tasks/02-design/api-design-task.md)
- **API Specification Creation Guide**: [PF-GDE-031](../../../process-framework/guides/guides/api-specification-creation-guide.md)
- **API Data Model Creation Guide**: [PF-GDE-032](../../../process-framework/guides/guides/api-data-model-creation-guide.md)
- **Main API Documentation**: [API README](../README.md)

## Questions or Issues?

If you have questions about API specifications or the Response Status Catalog:

1. Review the [API Specification Creation Guide](../../../process-framework/guides/guides/api-specification-creation-guide.md)
2. Check existing API specifications in the `specifications/` directory for examples
3. Consult the [API Design Task](../../../process-framework/tasks/02-design/api-design-task.md) documentation
4. Reach out to the API Platform Team (listed in the Response Status Catalog metadata)
