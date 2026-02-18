---
id: PD-API-011
type: Product Documentation
category: API Specification
version: 1.0
created: 2025-01-27
updated: 2025-01-27
feature_id: 1.2.1
feature_name: Basic Profile Data
---

# Basic Profile Data API

## Overview

This API provides endpoints for managing user profile data and payment methods in the Breakout Buddies platform. It enables users to view, create, update, and manage their personal information including username, names, email, profile pictures, contact information, and payment methods.

- **API Type**: REST API
- **Base URL**: `/api/v1/profile`
- **Version**: 1.0
- **Authentication**: JWT Bearer Token (Supabase Auth)

## Authentication

All endpoints require authentication using JWT Bearer tokens provided by Supabase Auth.

**Required Headers**:

```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Token Validation**:

- Tokens are validated against Supabase Auth service
- Expired tokens return `401 Unauthorized`
- Invalid tokens return `401 Unauthorized`
- Missing tokens return `401 Unauthorized`

**User Context**:

- All operations are scoped to the authenticated user
- User ID is extracted from JWT token
- Cross-user access is prevented by RLS policies

## Endpoints

### Profile Management

#### GET /profile

**Description**: Retrieves the authenticated user's complete profile information including personal data and privacy settings.

**Parameters**: None

**Request Body**: None

**Response**:

```json
{
  "status": "success",
  "data": {
    "user_id": "uuid",
    "username": "string",
    "first_name": "string",
    "last_name": "string",
    "show_name_to_friends": boolean,
    "email": "string",
    "profile_image_url": "string|null",
    "gender": "Male|Female|Other|Prefer not to say|null",
    "phone_number": "string|null",
    "birthday": "YYYY-MM-DD|null",
    "street_address": "string|null",
    "city": "string|null",
    "postal_code": "string|null",
    "country": "string|null",
    "created_at": "ISO8601 timestamp",
    "updated_at": "ISO8601 timestamp"
  }
}
```

**Status Codes**:

- `200 OK`: Profile retrieved successfully
- `401 Unauthorized`: Authentication required or invalid token
- `404 Not Found`: User profile not found
- `500 Internal Server Error`: Server error

**Performance Target**: < 1 second response time

---

#### PUT /profile

**Description**: Updates the authenticated user's profile information. Username cannot be changed. All fields except username are optional.

**Parameters**: None

**Request Body**:

```json
{
  "first_name": "string",
  "last_name": "string",
  "show_name_to_friends": boolean,
  "email": "string",
  "gender": "Male|Female|Other|Prefer not to say|null",
  "phone_number": "string|null",
  "birthday": "YYYY-MM-DD|null",
  "street_address": "string|null",
  "city": "string|null",
  "postal_code": "string|null",
  "country": "string|null"
}
```

**Validation Rules**:

- `first_name`: Required, 1-50 characters, letters/spaces/hyphens/apostrophes only
- `last_name`: Required, 1-50 characters, letters/spaces/hyphens/apostrophes only
- `show_name_to_friends`: Boolean, defaults to false
- `email`: Required, valid email format, must be unique across all users
- `gender`: Optional, must be one of: "Male", "Female", "Other", "Prefer not to say"
- `phone_number`: Optional, valid international format (E.164)
- `birthday`: Optional, valid date, user must be at least 16 years old
- `street_address`: Optional, max 200 characters
- `city`: Optional, max 100 characters
- `postal_code`: Optional, max 20 characters
- `country`: Optional, max 100 characters

**Response**:

```json
{
  "status": "success",
  "data": {
    "user_id": "uuid",
    "username": "string",
    "first_name": "string",
    "last_name": "string",
    "show_name_to_friends": boolean,
    "email": "string",
    "profile_image_url": "string|null",
    "gender": "Male|Female|Other|Prefer not to say|null",
    "phone_number": "string|null",
    "birthday": "YYYY-MM-DD|null",
    "street_address": "string|null",
    "city": "string|null",
    "postal_code": "string|null",
    "country": "string|null",
    "updated_at": "ISO8601 timestamp"
  }
}
```

**Status Codes**:

- `200 OK`: Profile updated successfully
- `400 Bad Request`: Invalid input data or validation failure
- `401 Unauthorized`: Authentication required or invalid token
- `409 Conflict`: Email already in use by another user
- `422 Unprocessable Entity`: Age validation failed (under 16 years old)
- `500 Internal Server Error`: Server error

**Performance Target**: < 200ms response time

---

#### POST /profile/image

**Description**: Uploads a new profile picture for the authenticated user. Images are automatically compressed if they exceed 5MB.

**Parameters**: None

**Request Body**: `multipart/form-data`

```
image: File (JPEG, PNG, or WebP format)
```

**Validation Rules**:

- File format: JPEG, PNG, or WebP only
- Maximum file size: 5MB (before compression)
- Automatic compression applied if size exceeds 5MB
- Images stored in Supabase Storage with secure access

**Response**:

```json
{
  "status": "success",
  "data": {
    "profile_image_url": "string",
    "uploaded_at": "ISO8601 timestamp"
  }
}
```

**Status Codes**:

- `200 OK`: Image uploaded successfully
- `400 Bad Request`: Invalid file format or corrupted file
- `401 Unauthorized`: Authentication required or invalid token
- `413 Payload Too Large`: File exceeds maximum size after compression
- `500 Internal Server Error`: Server error or storage failure

**Performance Target**: < 5 seconds response time (including compression)

---

#### DELETE /profile/image

**Description**: Removes the authenticated user's profile picture and sets it to null.

**Parameters**: None

**Request Body**: None

**Response**:

```json
{
  "status": "success",
  "message": "Profile image deleted successfully"
}
```

**Status Codes**:

- `200 OK`: Image deleted successfully
- `401 Unauthorized`: Authentication required or invalid token
- `404 Not Found`: No profile image to delete
- `500 Internal Server Error`: Server error or storage failure

**Performance Target**: < 200ms response time

---

### Payment Methods Management

#### GET /profile/payment-methods

**Description**: Retrieves all payment methods for the authenticated user. Payment tokens and billing addresses are returned in encrypted form.

**Parameters**: None

**Request Body**: None

**Response**:

```json
{
  "status": "success",
  "data": [
    {
      "payment_method_id": "uuid",
      "user_id": "uuid",
      "payment_type": "credit_card|debit_card|paypal",
      "card_last_4": "string|null",
      "card_brand": "visa|mastercard|amex|discover|null",
      "expiry_month": "integer|null",
      "expiry_year": "integer|null",
      "billing_city": "string (encrypted)|null",
      "billing_country": "string (encrypted)|null",
      "is_default": boolean,
      "created_at": "ISO8601 timestamp",
      "updated_at": "ISO8601 timestamp"
    }
  ]
}
```

**Status Codes**:

- `200 OK`: Payment methods retrieved successfully (empty array if none)
- `401 Unauthorized`: Authentication required or invalid token
- `500 Internal Server Error`: Server error

**Performance Target**: < 2 seconds response time

---

#### POST /profile/payment-methods

**Description**: Adds a new payment method for the authenticated user. Card data is tokenized via payment gateway before storage. If this is the first payment method, it is automatically set as default.

**Parameters**: None

**Request Body**:

```json
{
  "payment_type": "credit_card|debit_card|paypal",
  "card_number": "string",
  "expiry_month": integer,
  "expiry_year": integer,
  "cvv": "string",
  "billing_street_address": "string",
  "billing_city": "string",
  "billing_postal_code": "string",
  "billing_country": "string"
}
```

**Validation Rules**:

- `payment_type`: Required, must be "credit_card", "debit_card", or "paypal"
- `card_number`: Required for card types, validated using Luhn algorithm
- `expiry_month`: Required for card types, 1-12
- `expiry_year`: Required for card types, must not be in the past
- `cvv`: Required for card types, 3-4 digits
- `billing_street_address`: Required, max 200 characters
- `billing_city`: Required, max 100 characters
- `billing_postal_code`: Required, max 20 characters
- `billing_country`: Required, max 100 characters

**Security**:

- Card number is sent directly to payment gateway for tokenization
- Only payment token is stored in database (never full card number)
- CVV is never stored (used only for tokenization)
- Billing address is encrypted at rest using AES-256

**Response**:

```json
{
  "status": "success",
  "data": {
    "payment_method_id": "uuid",
    "payment_type": "credit_card|debit_card|paypal",
    "card_last_4": "string",
    "card_brand": "visa|mastercard|amex|discover",
    "expiry_month": integer,
    "expiry_year": integer,
    "is_default": boolean,
    "created_at": "ISO8601 timestamp"
  }
}
```

**Status Codes**:

- `201 Created`: Payment method added successfully
- `400 Bad Request`: Invalid input data or validation failure
- `401 Unauthorized`: Authentication required or invalid token
- `402 Payment Required`: Payment gateway tokenization failed
- `422 Unprocessable Entity`: Card validation failed (Luhn algorithm)
- `500 Internal Server Error`: Server error

**Performance Target**: < 3 seconds response time (including tokenization)

---

#### PUT /profile/payment-methods/:id

**Description**: Updates an existing payment method's details (expiry date and billing address). Card number cannot be changed.

**Parameters**:

- `id` (UUID, required): Payment method ID

**Request Body**:

```json
{
  "expiry_month": integer,
  "expiry_year": integer,
  "billing_street_address": "string",
  "billing_city": "string",
  "billing_postal_code": "string",
  "billing_country": "string"
}
```

**Validation Rules**:

- `expiry_month`: Optional, 1-12
- `expiry_year`: Optional, must not be in the past
- `billing_street_address`: Optional, max 200 characters
- `billing_city`: Optional, max 100 characters
- `billing_postal_code`: Optional, max 20 characters
- `billing_country`: Optional, max 100 characters

**Response**:

```json
{
  "status": "success",
  "data": {
    "payment_method_id": "uuid",
    "payment_type": "credit_card|debit_card|paypal",
    "card_last_4": "string",
    "card_brand": "visa|mastercard|amex|discover",
    "expiry_month": integer,
    "expiry_year": integer,
    "is_default": boolean,
    "updated_at": "ISO8601 timestamp"
  }
}
```

**Status Codes**:

- `200 OK`: Payment method updated successfully
- `400 Bad Request`: Invalid input data or validation failure
- `401 Unauthorized`: Authentication required or invalid token
- `403 Forbidden`: Payment method belongs to another user
- `404 Not Found`: Payment method not found
- `500 Internal Server Error`: Server error

**Performance Target**: < 2 seconds response time

---

#### PUT /profile/payment-methods/:id/set-default

**Description**: Sets the specified payment method as the default for future transactions.

**Parameters**:

- `id` (UUID, required): Payment method ID

**Request Body**: None

**Response**:

```json
{
  "status": "success",
  "message": "Payment method set as default",
  "data": {
    "payment_method_id": "uuid",
    "is_default": true
  }
}
```

**Status Codes**:

- `200 OK`: Default payment method updated successfully
- `401 Unauthorized`: Authentication required or invalid token
- `403 Forbidden`: Payment method belongs to another user
- `404 Not Found`: Payment method not found
- `500 Internal Server Error`: Server error

**Performance Target**: < 200ms response time

---

#### DELETE /profile/payment-methods/:id

**Description**: Deletes a payment method. If the deleted method was the default and other methods exist, the next method in the list becomes the default.

**Parameters**:

- `id` (UUID, required): Payment method ID

**Request Body**: None

**Response**:

```json
{
  "status": "success",
  "message": "Payment method deleted successfully",
  "data": {
    "new_default_id": "uuid|null"
  }
}
```

**Status Codes**:

- `200 OK`: Payment method deleted successfully
- `401 Unauthorized`: Authentication required or invalid token
- `403 Forbidden`: Payment method belongs to another user
- `404 Not Found`: Payment method not found
- `500 Internal Server Error`: Server error

**Performance Target**: < 200ms response time

---

## Data Models

### UserProfile

```json
{
  "user_id": "uuid",
  "username": "string",
  "first_name": "string",
  "last_name": "string",
  "show_name_to_friends": boolean,
  "email": "string",
  "profile_image_url": "string|null",
  "gender": "Male|Female|Other|Prefer not to say|null",
  "phone_number": "string|null",
  "birthday": "YYYY-MM-DD|null",
  "street_address": "string|null",
  "city": "string|null",
  "postal_code": "string|null",
  "country": "string|null",
  "created_at": "ISO8601 timestamp",
  "updated_at": "ISO8601 timestamp"
}
```

**Field Descriptions**:

- `user_id`: Unique identifier for the user (UUID from Supabase Auth)
- `username`: Unique username (3-30 characters, alphanumeric + underscores, immutable)
- `first_name`: User's first name (1-50 characters)
- `last_name`: User's last name (1-50 characters)
- `show_name_to_friends`: Privacy setting for name visibility (default: false)
- `email`: User's email address (unique, validated format)
- `profile_image_url`: URL to profile picture in Supabase Storage (nullable)
- `gender`: User's gender selection (nullable)
- `phone_number`: International phone number in E.164 format (nullable)
- `birthday`: User's date of birth in YYYY-MM-DD format (nullable, must be 16+ years old)
- `street_address`: Street address (nullable)
- `city`: City name (nullable)
- `postal_code`: Postal/ZIP code (nullable)
- `country`: Country name (nullable)
- `created_at`: Profile creation timestamp
- `updated_at`: Last profile update timestamp

---

### PaymentMethod

```json
{
  "payment_method_id": "uuid",
  "user_id": "uuid",
  "payment_type": "credit_card|debit_card|paypal",
  "payment_token": "string (encrypted)",
  "card_last_4": "string|null",
  "card_brand": "visa|mastercard|amex|discover|null",
  "expiry_month": "integer|null",
  "expiry_year": "integer|null",
  "billing_street_address": "string (encrypted)|null",
  "billing_city": "string (encrypted)|null",
  "billing_postal_code": "string (encrypted)|null",
  "billing_country": "string (encrypted)|null",
  "is_default": boolean,
  "created_at": "ISO8601 timestamp",
  "updated_at": "ISO8601 timestamp"
}
```

**Field Descriptions**:

- `payment_method_id`: Unique identifier for the payment method (UUID)
- `user_id`: Foreign key to user (UUID)
- `payment_type`: Type of payment method
- `payment_token`: Encrypted token from payment gateway (never exposed in API)
- `card_last_4`: Last 4 digits of card number for display (nullable)
- `card_brand`: Card brand/network (nullable)
- `expiry_month`: Card expiration month 1-12 (nullable)
- `expiry_year`: Card expiration year YYYY (nullable)
- `billing_street_address`: Encrypted billing street address (nullable)
- `billing_city`: Encrypted billing city (nullable)
- `billing_postal_code`: Encrypted billing postal code (nullable)
- `billing_country`: Encrypted billing country (nullable)
- `is_default`: Whether this is the default payment method
- `created_at`: Payment method creation timestamp
- `updated_at`: Last payment method update timestamp

**Security Notes**:

- `payment_token` is encrypted at rest using AES-256 and never exposed in API responses
- Billing address fields are encrypted at rest using AES-256
- Full card numbers are never stored (PCI DSS compliance)
- CVV codes are never stored

---

## Database Schema Reference

> **📋 Primary Documentation**: Database Schema Design Task (PF-TSK-021)
> **🔗 Link**: [Schema Design - Basic Profile Data (PD-SCH-010)](../../database/schemas/1.2.1-basic-profile-data.md) > **👤 Owner**: Database Schema Design Task
>
> **Purpose**: This section provides a brief API-level perspective on database interactions. Detailed schema definitions, table structures, relationships, constraints, and RLS policies are documented in the Database Schema Design task.

### API-Level Database Interaction Notes

**Data Access Patterns**:

- API accesses `users` table for profile data (extended with profile fields)
- API accesses `payment_methods` table for payment method data
- All operations use authenticated user context from JWT token
- RLS policies enforce user-level access control (users can only access their own data)

**API-Level Data Requirements**:

- Profile endpoints require read/write access to user's own profile record
- Payment method endpoints require read/write access to user's own payment methods
- Foreign key relationship from `payment_methods.user_id` to `users.id` with CASCADE delete
- Unique constraints on username and email enforced at database level

**Security Policy Integration**:

- API respects RLS policies that restrict access to user's own data
- Authentication context (user_id from JWT) is used for all database queries
- Database-level encryption for payment tokens and billing addresses
- Case-insensitive uniqueness checks for username and email

---

## Service Implementation Reference

> **📋 Primary Documentation**: TDD Creation Task (PF-TSK-022)
> **🔗 Link**: [TDD-1.2.1 - Basic Profile Data](../../../technical/architecture/design-docs/tdd/tdd/tdd-1.2.1-basic-profile-data-t1.md) > **👤 Owner**: TDD Creation Task
>
> **Purpose**: This section provides a brief API-level perspective on service implementation. Detailed service architecture, component design, implementation patterns, and technical decisions are documented in the TDD.

### API-Level Implementation Notes

**Service Integration Approach**:

- API implemented as REST endpoints in Flutter service layer using Supabase client
- Profile image uploads handled through Supabase Storage with automatic compression
- Payment tokenization handled through payment gateway API (Stripe or similar)
- Encryption/decryption for payment data handled at application layer

**Implementation Architecture**:

- Repository pattern for data access abstraction
- Service layer handles business logic and validation
- Provider pattern for state management in Flutter UI
- Automatic image compression using Flutter image processing libraries

---

## Testing Reference

> **📋 Primary Documentation**: Test Specification Creation Task (PF-TSK-012)
> **🔗 Link**: [Test Specification - Basic Profile Data (PD-TST-011)](../../testing/test-specifications/test-spec-1.2.1-basic-profile-data.md) > **👤 Owner**: Test Specification Creation Task
>
> **Purpose**: This section provides a brief API-level perspective on testing concerns. Comprehensive test plans, test cases, test data, and testing procedures are documented in the Test Specification task.

### API-Level Testing Considerations

**Contract Testing Requirements**:

- All endpoints require contract testing against API specification
- Request/response schema validation for all endpoints
- Authentication flow testing with valid and invalid tokens
- Validation error response format testing

**Integration Testing Requirements**:

- Supabase integration testing for profile CRUD operations
- Supabase Storage integration testing for image uploads
- Payment gateway integration testing for tokenization
- RLS policy testing to verify access control

**Performance Testing Requirements**:

- Load testing for profile retrieval (< 1 second target)
- Load testing for profile updates (< 200ms target)
- Image upload performance testing (< 5 seconds target)
- Payment method operations performance testing (< 2-3 seconds target)
- Rate limiting validation for all endpoints

---

## Error Handling

Standard error response format:

```json
{
  "status": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {
      "field": "field_name",
      "reason": "Specific reason for error"
    }
  }
}
```

### Common Error Codes

**Authentication Errors**:

- `AUTH_REQUIRED`: Authentication token is missing
- `AUTH_INVALID`: Authentication token is invalid or expired
- `AUTH_EXPIRED`: Authentication token has expired

**Validation Errors**:

- `VALIDATION_FAILED`: Input validation failed
- `EMAIL_INVALID`: Email format is invalid
- `EMAIL_TAKEN`: Email is already in use
- `USERNAME_INVALID`: Username format is invalid
- `USERNAME_TAKEN`: Username is already in use
- `AGE_INVALID`: User must be at least 16 years old
- `PHONE_INVALID`: Phone number format is invalid
- `CARD_INVALID`: Card number validation failed (Luhn algorithm)
- `CARD_EXPIRED`: Card expiration date is in the past

**Resource Errors**:

- `PROFILE_NOT_FOUND`: User profile not found
- `PAYMENT_METHOD_NOT_FOUND`: Payment method not found
- `IMAGE_NOT_FOUND`: Profile image not found

**Permission Errors**:

- `ACCESS_DENIED`: User does not have permission to access this resource
- `PAYMENT_METHOD_ACCESS_DENIED`: Payment method belongs to another user

**File Upload Errors**:

- `FILE_TOO_LARGE`: File exceeds maximum size limit
- `FILE_FORMAT_INVALID`: File format is not supported
- `FILE_CORRUPTED`: File is corrupted or cannot be processed
- `STORAGE_ERROR`: Error uploading file to storage

**Payment Errors**:

- `TOKENIZATION_FAILED`: Payment gateway tokenization failed
- `PAYMENT_GATEWAY_ERROR`: Error communicating with payment gateway

**Server Errors**:

- `INTERNAL_ERROR`: Internal server error
- `DATABASE_ERROR`: Database operation failed
- `SERVICE_UNAVAILABLE`: Service is temporarily unavailable

---

## Rate Limiting

To prevent abuse, the following rate limits are applied:

**Profile Endpoints**:

- `GET /profile`: 100 requests per minute per user
- `PUT /profile`: 10 requests per minute per user
- `POST /profile/image`: 5 requests per minute per user
- `DELETE /profile/image`: 5 requests per minute per user

**Payment Method Endpoints**:

- `GET /profile/payment-methods`: 50 requests per minute per user
- `POST /profile/payment-methods`: 5 requests per minute per user
- `PUT /profile/payment-methods/:id`: 10 requests per minute per user
- `PUT /profile/payment-methods/:id/set-default`: 10 requests per minute per user
- `DELETE /profile/payment-methods/:id`: 5 requests per minute per user

**Rate Limit Response**:

```json
{
  "status": "error",
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later.",
    "details": {
      "retry_after": 60
    }
  }
}
```

**Status Code**: `429 Too Many Requests`

---

## Security Considerations

### PCI DSS Compliance

- **Never store full card numbers**: Only last 4 digits stored for display
- **Never store CVV codes**: Used only for tokenization, never persisted
- **Tokenization**: Card data sent directly to payment gateway, only token stored
- **Encryption**: Payment tokens and billing addresses encrypted at rest (AES-256)
- **Secure transmission**: All API communication over HTTPS/TLS 1.3
- **Access controls**: Strict user-level access control via RLS policies
- **Audit logging**: All payment method operations logged for compliance

### Data Privacy (GDPR/FADP)

- **Age verification**: Minimum age 16 years enforced via validation
- **Data minimization**: Only necessary data collected
- **Privacy by design**: Name visibility defaults to hidden
- **User control**: Users can update or delete their data
- **Secure storage**: Personal data protected by encryption and access controls

### Input Validation

- **Server-side validation**: All inputs validated on server (never trust client)
- **SQL injection prevention**: Parameterized queries via Supabase ORM
- **XSS prevention**: Output encoding for all user-generated content
- **File upload validation**: File type and size validation for images
- **Email validation**: Format and uniqueness validation
- **Phone validation**: International format validation (E.164)
- **Card validation**: Luhn algorithm validation before tokenization

---

## Changelog

### Version 1.0 (2025-01-27)

- Initial API specification for Basic Profile Data feature
- Profile management endpoints (GET, PUT, image upload/delete)
- Payment methods management endpoints (CRUD operations)
- Authentication and authorization requirements
- Data models and validation rules
- Error handling and rate limiting specifications
- Security considerations (PCI DSS, GDPR/FADP compliance)
