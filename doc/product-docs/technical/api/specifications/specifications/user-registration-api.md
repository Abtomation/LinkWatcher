---
id: PD-API-012
type: API Specification
category: API Specification
version: 1.0
created: 2025-08-25
updated: 2025-08-25
api_type: REST
api_name: User Registration API
feature_id: 1.1.1
---

# User Registration API

## Overview

API endpoints for email and password user registration functionality, providing secure account creation with email verification and comprehensive validation.

- **API Type**: REST
- **Base URL**: `{SUPABASE_URL}/auth/v1` (Supabase Auth API)
- **Version**: 1.0
- **Authentication**: JWT Bearer tokens for authenticated endpoints, public access for registration
- **Feature ID**: 1.1.1

## Authentication

This API uses Supabase's built-in authentication system:

- **Authentication Type**: JWT Bearer tokens
- **Public Endpoints**: Registration endpoint is publicly accessible
- **Protected Endpoints**: User profile and session management require valid JWT tokens
- **Token Format**: `Authorization: Bearer <jwt_token>`
- **Token Validation**: Automatic validation by Supabase Auth middleware

## Endpoints

### User Registration

#### POST /signup

**Description**: Creates a new user account with email and password, sends email verification

**Parameters**: None

**Request Body**:

```json
{
  "email": "user@example.com",
  "password": "SecurePassword123"
}
```

**Response** (Success):

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "expires_at": 1693123456,
  "refresh_token": "v1.M2YwMDAwMDAwMDAwMDAwMA.refresh_token_here",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "aud": "authenticated",
    "role": "authenticated",
    "email": "user@example.com",
    "email_confirmed_at": null,
    "phone": null,
    "confirmed_at": null,
    "last_sign_in_at": null,
    "app_metadata": {
      "provider": "email",
      "providers": ["email"]
    },
    "user_metadata": {},
    "identities": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "identity_data": {
          "email": "user@example.com"
        },
        "provider": "email",
        "last_sign_in_at": "2025-08-25T19:37:34.123456Z",
        "created_at": "2025-08-25T19:37:34.123456Z",
        "updated_at": "2025-08-25T19:37:34.123456Z"
      }
    ],
    "created_at": "2025-08-25T19:37:34.123456Z",
    "updated_at": "2025-08-25T19:37:34.123456Z"
  }
}
```

**Status Codes**:

> **📋 Canonical Status Codes**: This API uses the canonical status codes defined in the [Response Status Catalog](../shared/response-status-catalog.json).
> See: `apis.user-registration.endpoints["/auth/v1/signup"].scenarios`

- `200 OK`: User successfully created, verification email sent
- `400 Bad Request`: Invalid email format, weak password, or missing required fields
- `409 Conflict`: Email already registered
- `429 Too Many Requests`: Rate limit exceeded (5 attempts per hour per IP)
- `500 Internal Server Error`: Server error or email service failure

### Email Verification Status

#### GET /user

**Description**: Retrieves current user information including email verification status

**Parameters**: None

**Headers**:

- `Authorization: Bearer <jwt_token>` (required)

**Response** (Success):

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "aud": "authenticated",
  "role": "authenticated",
  "email": "user@example.com",
  "email_confirmed_at": "2025-08-25T19:45:12.123456Z",
  "phone": null,
  "confirmed_at": "2025-08-25T19:45:12.123456Z",
  "last_sign_in_at": "2025-08-25T19:37:34.123456Z",
  "app_metadata": {
    "provider": "email",
    "providers": ["email"]
  },
  "user_metadata": {},
  "identities": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "identity_data": {
        "email": "user@example.com"
      },
      "provider": "email",
      "last_sign_in_at": "2025-08-25T19:37:34.123456Z",
      "created_at": "2025-08-25T19:37:34.123456Z",
      "updated_at": "2025-08-25T19:37:34.123456Z"
    }
  ],
  "created_at": "2025-08-25T19:37:34.123456Z",
  "updated_at": "2025-08-25T19:37:34.123456Z"
}
```

**Status Codes**:

> **📋 Canonical Status Codes**: See [Response Status Catalog](../shared/response-status-catalog.json) for complete status code definitions.

- `200 OK`: User information retrieved successfully
- `401 Unauthorized`: Invalid or expired JWT token
- `500 Internal Server Error`: Server error

### Resend Verification Email

#### POST /resend

**Description**: Resends email verification to the user's registered email address

**Parameters**: None

**Request Body**:

```json
{
  "email": "user@example.com"
}
```

**Response** (Success):

```json
{
  "message": "Verification email sent successfully"
}
```

**Status Codes**:

> **📋 Canonical Status Codes**: This API uses the canonical status codes defined in the [Response Status Catalog](../shared/response-status-catalog.json).
> See: `apis.user-registration.endpoints["/auth/v1/resend"].scenarios`

- `200 OK`: Verification email sent successfully
- `400 Bad Request`: Invalid email format or missing email field
- `404 Not Found`: Email address not found in system
- `429 Too Many Requests`: Rate limit exceeded for resend requests
- `500 Internal Server Error`: Email service failure

## Data Models

### User Registration Request

```json
{
  "email": "string",
  "password": "string"
}
```

**Field Descriptions**:

- `email`: Valid email address (required, must be unique)
- `password`: Password string (required, minimum 8 characters, must contain uppercase, lowercase, and number)

### User Registration Response

```json
{
  "access_token": "string",
  "token_type": "bearer",
  "expires_in": "integer",
  "expires_at": "integer",
  "refresh_token": "string",
  "user": {
    "id": "string",
    "email": "string",
    "email_confirmed_at": "string|null",
    "confirmed_at": "string|null",
    "created_at": "string",
    "updated_at": "string"
  }
}
```

**Field Descriptions**:

- `access_token`: JWT token for authenticated requests
- `token_type`: Always "bearer"
- `expires_in`: Token expiration time in seconds
- `expires_at`: Unix timestamp of token expiration
- `refresh_token`: Token for refreshing access token
- `user.id`: Unique user identifier (UUID)
- `user.email`: User's email address
- `user.email_confirmed_at`: Timestamp of email confirmation (null if unverified)
- `user.confirmed_at`: Timestamp of account confirmation (null if unverified)
- `user.created_at`: Account creation timestamp
- `user.updated_at`: Last account update timestamp

### Email Verification Request

```json
{
  "email": "string"
}
```

**Field Descriptions**:

- `email`: Email address to resend verification to (required)

## Error Handling

Standard Supabase Auth error response format:

```json
{
  "error": "error_code",
  "error_description": "Human readable error message"
}
```

### Common Error Codes

- `invalid_request`: Malformed request or missing required parameters
- `invalid_grant`: Invalid email/password combination
- `user_already_registered`: Email address already exists in system
- `weak_password`: Password does not meet strength requirements
- `invalid_email`: Email format is invalid
- `rate_limit_exceeded`: Too many requests from this IP address
- `email_not_confirmed`: Account exists but email not verified
- `signup_disabled`: User registration is currently disabled

## Rate Limiting

- **Registration Rate Limit**: 5 attempts per IP address per hour
- **Resend Email Rate Limit**: 3 attempts per email address per hour
- **Rate Limit Headers**:
  - `X-RateLimit-Limit`: Maximum requests allowed
  - `X-RateLimit-Remaining`: Remaining requests in current window
  - `X-RateLimit-Reset`: Unix timestamp when rate limit resets
- **Rate Limit Exceeded Behavior**: Returns 429 status with retry-after header

## Validation Rules

### Email Validation

- Must contain valid email format (RFC 5322 compliant)
- Must be unique across all user accounts
- Maximum length: 254 characters
- Case-insensitive matching for uniqueness

### Password Validation

- Minimum length: 8 characters
- Must contain at least one uppercase letter (A-Z)
- Must contain at least one lowercase letter (a-z)
- Must contain at least one number (0-9)
- Maximum length: 128 characters
- No common passwords or dictionary words

## Examples

### Example 1: Successful User Registration

Request:

```bash
curl -X POST "{SUPABASE_URL}/auth/v1/signup" \
  -H "Content-Type: application/json" \
  -H "apikey: {SUPABASE_ANON_KEY}" \
  -d '{
    "email": "john.doe@example.com",
    "password": "SecurePass123"
  }'
```

Response:

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

### Example 2: Registration with Existing Email

Request:

```bash
curl -X POST "{SUPABASE_URL}/auth/v1/signup" \
  -H "Content-Type: application/json" \
  -H "apikey: {SUPABASE_ANON_KEY}" \
  -d '{
    "email": "existing@example.com",
    "password": "SecurePass123"
  }'
```

Response:

```json
{
  "error": "user_already_registered",
  "error_description": "A user with this email address has already been registered"
}
```

### Example 3: Registration with Weak Password

Request:

```bash
curl -X POST "{SUPABASE_URL}/auth/v1/signup" \
  -H "Content-Type: application/json" \
  -H "apikey: {SUPABASE_ANON_KEY}" \
  -d '{
    "email": "newuser@example.com",
    "password": "weak"
  }'
```

Response:

```json
{
  "error": "weak_password",
  "error_description": "Password must be at least 8 characters long and contain uppercase, lowercase, and numeric characters"
}
```

### Example 4: Resend Verification Email

Request:

```bash
curl -X POST "{SUPABASE_URL}/auth/v1/resend" \
  -H "Content-Type: application/json" \
  -H "apikey: {SUPABASE_ANON_KEY}" \
  -d '{
    "email": "john.doe@example.com"
  }'
```

Response:

```json
{
  "message": "Verification email sent successfully"
}
```

## Security Considerations

- **Password Security**: Passwords are hashed using bcrypt with salt before storage
- **Email Verification**: Users must verify email before gaining full platform access
- **Rate Limiting**: Prevents brute force attacks and spam registrations
- **CSRF Protection**: All endpoints include CSRF token validation
- **Input Sanitization**: All input is sanitized to prevent injection attacks
- **Token Security**: JWT tokens include appropriate expiration times and are signed with secure keys

## Related APIs

- [User Authentication API](user-authentication-api.md): Login, logout, and session management
- [Password Reset API](password-reset-api.md): Password recovery functionality
- [User Profile API](user-profile-api.md): User profile management and updates

## Changelog

- **v1.0** (2025-08-25): Initial API specification for email and password registration functionality
