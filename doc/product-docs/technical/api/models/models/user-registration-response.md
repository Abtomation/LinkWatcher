---
id: PD-API-014
type: Process Framework
category: API Data Model
version: 1.0
created: 2025-08-25
updated: 2025-08-25
related_endpoints: POST /auth/v1/signup
api_version: v1
feature_id: 1.1.1
---
# User Registration Response - API Data Model

## Overview

**Purpose**: Data model for user registration response returned by the Supabase Auth API
**Context**: Response data structure for successful email and password user registration (Feature 1.1.1)
**API Version**: v1

## Data Model Definition

### Core Structure

```json
{
  "access_token": {
    "type": "string",
    "required": true,
    "description": "JWT access token for authenticated API requests"
  },
  "token_type": {
    "type": "string",
    "required": true,
    "description": "Token type, always 'bearer'"
  },
  "expires_in": {
    "type": "integer",
    "required": true,
    "description": "Token expiration time in seconds"
  },
  "expires_at": {
    "type": "integer",
    "required": true,
    "description": "Unix timestamp when token expires"
  },
  "refresh_token": {
    "type": "string",
    "required": true,
    "description": "Token for refreshing the access token"
  },
  "user": {
    "type": "object",
    "required": true,
    "description": "User account information"
  }
}
```

### Field Definitions

| Field Name | Type | Required | Description | Validation Rules |
|------------|------|----------|-------------|------------------|
| access_token | string | Yes | JWT access token for authenticated API requests | Valid JWT format, signed with server key |
| token_type | string | Yes | Token type identifier | Always "bearer" |
| expires_in | integer | Yes | Token expiration time in seconds | Positive integer, typically 3600 (1 hour) |
| expires_at | integer | Yes | Unix timestamp when token expires | Valid Unix timestamp |
| refresh_token | string | Yes | Token for refreshing the access token | Secure random string, base64 encoded |
| user | object | Yes | User account information | Valid User object structure |

### User Object Structure

```json
{
  "id": {
    "type": "string",
    "required": true,
    "description": "Unique user identifier (UUID)"
  },
  "email": {
    "type": "string",
    "required": true,
    "description": "User's email address"
  },
  "email_confirmed_at": {
    "type": "string|null",
    "required": false,
    "description": "Timestamp when email was confirmed (null if unverified)"
  },
  "confirmed_at": {
    "type": "string|null",
    "required": false,
    "description": "Timestamp when account was confirmed (null if unverified)"
  },
  "created_at": {
    "type": "string",
    "required": true,
    "description": "Account creation timestamp"
  },
  "updated_at": {
    "type": "string",
    "required": true,
    "description": "Last account update timestamp"
  }
}
```

### Example Data

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjkzMTI3MDU2LCJzdWIiOiI1NTBlODQwMC1lMjliLTQxZDQtYTcxNi00NDY2NTU0NDAwMDAiLCJlbWFpbCI6ImpvaG4uZG9lQGV4YW1wbGUuY29tIiwicGhvbmUiOiIiLCJhcHBfbWV0YWRhdGEiOnsicHJvdmlkZXIiOiJlbWFpbCIsInByb3ZpZGVycyI6WyJlbWFpbCJdfSwidXNlcl9tZXRhZGF0YSI6e30sInJvbGUiOiJhdXRoZW50aWNhdGVkIn0.example_signature",
  "token_type": "bearer",
  "expires_in": 3600,
  "expires_at": 1693127056,
  "refresh_token": "v1.M2YwMDAwMDAwMDAwMDAwMA.example_refresh_token",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "john.doe@example.com",
    "email_confirmed_at": null,
    "confirmed_at": null,
    "created_at": "2025-08-25T19:37:34.123456Z",
    "updated_at": "2025-08-25T19:37:34.123456Z"
  }
}
```

## Validation Rules

### Required Fields
- **access_token**: Must be a valid JWT token
- **token_type**: Must be "bearer"
- **expires_in**: Must be a positive integer
- **expires_at**: Must be a valid Unix timestamp
- **refresh_token**: Must be a non-empty string
- **user**: Must be a valid User object

### Optional Fields
- **user.email_confirmed_at**: Null for new registrations, timestamp when verified
- **user.confirmed_at**: Null for new registrations, timestamp when account confirmed

### Data Constraints
- **String Fields**:
  - `access_token`: JWT format, typically 200-500 characters
  - `token_type`: Exactly "bearer"
  - `refresh_token`: Base64 encoded string, variable length
  - `user.id`: UUID format (36 characters with hyphens)
  - `user.email`: Valid email format, max 254 characters
- **Integer Fields**:
  - `expires_in`: Positive integer, typically 3600 seconds
  - `expires_at`: Valid Unix timestamp (10 digits)
- **Date Fields**:
  - All timestamps in ISO 8601 format with timezone (UTC)
  - Format: "YYYY-MM-DDTHH:mm:ss.ffffffZ"

## Relationships

### Parent Models
- None - this is a root-level response model

### Child Models
- **User Object**: Nested user account information
- **JWT Token**: Contains encoded user claims and permissions

### Related Models
- [User Registration Request](../../../user-registration-request.md): Request model that generates this response
- [Authentication Token](../../../authentication-token.md): Detailed JWT token structure
- [User Profile](../../../user-profile.md): Extended user profile information

## Usage Examples

### Successful Registration Response
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjkzMTI3MDU2LCJzdWIiOiI1NTBlODQwMC1lMjliLTQxZDQtYTcxNi00NDY2NTU0NDAwMDAiLCJlbWFpbCI6ImFsaWNlLnNtaXRoQGV4YW1wbGUuY29tIiwicGhvbmUiOiIiLCJhcHBfbWV0YWRhdGEiOnsicHJvdmlkZXIiOiJlbWFpbCIsInByb3ZpZGVycyI6WyJlbWFpbCJdfSwidXNlcl9tZXRhZGF0YSI6e30sInJvbGUiOiJhdXRoZW50aWNhdGVkIn0.example_signature",
  "token_type": "bearer",
  "expires_in": 3600,
  "expires_at": 1693127056,
  "refresh_token": "v1.M2YwMDAwMDAwMDAwMDAwMA.alice_refresh_token",
  "user": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "email": "alice.smith@example.com",
    "email_confirmed_at": null,
    "confirmed_at": null,
    "created_at": "2025-08-25T20:15:30.123456Z",
    "updated_at": "2025-08-25T20:15:30.123456Z"
  }
}
```

### Response After Email Verification
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.updated_token_with_verified_email.signature",
  "token_type": "bearer",
  "expires_in": 3600,
  "expires_at": 1693130656,
  "refresh_token": "v1.M2YwMDAwMDAwMDAwMDAwMA.updated_refresh_token",
  "user": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "email": "alice.smith@example.com",
    "email_confirmed_at": "2025-08-25T20:45:12.123456Z",
    "confirmed_at": "2025-08-25T20:45:12.123456Z",
    "created_at": "2025-08-25T20:15:30.123456Z",
    "updated_at": "2025-08-25T20:45:12.123456Z"
  }
}
```

## Serialization Notes

### JSON Serialization
- Standard JSON serialization with UTF-8 encoding
- All timestamps serialized in ISO 8601 format with UTC timezone
- JWT tokens serialized as base64-encoded strings
- Null values explicitly included for optional fields

### Data Transformation
- Unix timestamps converted to ISO 8601 strings for user-facing fields
- JWT tokens remain in encoded format for security
- User ID generated as UUID v4 format
- Email addresses normalized to lowercase

### Null Handling
- `email_confirmed_at` and `confirmed_at` are null for unverified accounts
- Other fields are never null in successful responses
- Null values are explicitly serialized (not omitted)

## Security Considerations

### Token Security
- Access tokens contain sensitive user information and permissions
- Refresh tokens should be stored securely and rotated regularly
- Tokens should be transmitted over HTTPS only
- Client applications should not log or expose token contents

### User Data Security
- User ID is a UUID to prevent enumeration attacks
- Email addresses are included but should be handled with privacy considerations
- Timestamps provide audit trail for security monitoring
- No sensitive data (passwords, personal info) included in response

### Token Validation
- Access tokens must be validated on each API request
- Expired tokens should be rejected with appropriate error messages
- Refresh tokens should be used to obtain new access tokens
- Token signatures must be verified using server's secret key

## Versioning

### Current Version
- **Version**: v1.0
- **Changes**: Initial version for email and password registration response

### Migration Notes
- No migration required for initial version
- Future versions may add additional user metadata fields
- Token structure follows Supabase Auth standards for compatibility

### Backward Compatibility
- Current version is the baseline - no backward compatibility concerns
- Future versions will maintain core token and user structure
- Additional fields may be added but existing fields will remain stable

## Related Documentation

### API Specifications
- [User Registration API](../../../../specifications/specifications/user-registration-api.md): Complete API specification including this data model

### Implementation Notes
- [SupabaseService](../../../../../../../lib/services/supabase_service.dart): Flutter service implementation for handling responses
- [AuthProvider](../../../../../../../lib/services/auth_provider.dart): Authentication state management using this response

### Testing
- [User Registration Tests](../../../../../../../test/unit/services/supabase_service_test.dart): Unit tests for registration response handling
- [Authentication Tests](../../../../../../../test/unit/services/auth_provider_test.dart): Tests for token and user data processing

## Performance Considerations

### Response Size
- Typical response size: 800-1200 bytes
- JWT tokens are the largest component (400-600 bytes)
- Minimal impact on network performance
- Efficient JSON parsing for mobile applications

### Token Processing
- JWT token validation requires cryptographic operations
- Token expiration checking is lightweight
- Refresh token operations require server round-trip
- User object processing is minimal overhead

### Caching Behavior
- Access tokens should not be cached beyond expiration time
- User information can be cached with appropriate invalidation
- Refresh tokens should be stored securely (encrypted storage)
- Response should not be cached by HTTP intermediaries

## Error Handling

### Validation Errors
- Malformed JWT tokens result in authentication errors
- Invalid user data triggers data integrity errors
- Missing required fields cause serialization errors
- Timestamp format errors result in parsing failures

### Token Errors
- Expired tokens return 401 Unauthorized
- Invalid signatures return 403 Forbidden
- Malformed tokens return 400 Bad Request
- Missing tokens return 401 Unauthorized

### Common Success Variations
```json
// New user (unverified email)
{
  "user": {
    "email_confirmed_at": null,
    "confirmed_at": null
  }
}

// Verified user (after email confirmation)
{
  "user": {
    "email_confirmed_at": "2025-08-25T20:45:12.123456Z",
    "confirmed_at": "2025-08-25T20:45:12.123456Z"
  }
}
```
