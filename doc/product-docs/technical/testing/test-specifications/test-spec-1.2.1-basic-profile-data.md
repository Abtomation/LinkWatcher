---
id: PD-TST-011
type: Product Documentation
category: Test Specification
version: 1.0
created: 2025-01-27
updated: 2025-01-27
feature_id: 1.2.1
feature_name: Basic Profile Data
tdd_path: /doc/product-docs/technical/architecture/design-docs/tdd/tdd/tdd-1.2.1-basic-profile-data-t1.md
test_tier: 2
---

# Test Specification: Basic Profile Data

## Overview

This document provides comprehensive test specifications for the **Basic Profile Data** feature (ID: 1.2.1), derived from the Technical Design Document located at `/doc/product-docs/technical/architecture/design-docs/tdd/tdd/tdd-1.2.1-basic-profile-data-t1.md`.

**Test Tier**: 2 (Comprehensive - Unit tests, integration tests, and widget tests)
**TDD Reference**: `/doc/product-docs/technical/architecture/design-docs/tdd/tdd/tdd-1.2.1-basic-profile-data-t1.md`
**Created**: 2025-01-27

## Feature Context

### TDD Summary

The Basic Profile Data feature enables users to create and manage their profile information including username, names, email, profile pictures, contact information, and payment methods. The implementation uses Flutter widgets for UI, provider pattern for state management, Supabase for data storage, Supabase Storage for image uploads, and a PCI DSS compliant payment gateway (Stripe) for payment tokenization.

**Key Components**:

- Profile view, edit, and payment management screens with form validation
- Profile data validation (username uniqueness, email validation, format validation)
- Image compression/upload handling via Supabase Storage
- Payment card validation (Luhn algorithm) and tokenization via payment gateway
- Encryption for secure storage of payment tokens and billing addresses
- Repository pattern for data access abstraction

**Data Storage**:

- Extended `users` table with profile fields (username, names, email, profile image, contact info, address)
- New `payment_methods` table with encrypted payment tokens and billing addresses
- RLS policies enforce user-level access control

### Test Complexity Assessment

Based on the feature tier assessment:

- **Tier 1 🔵**: Basic unit tests and key integration scenarios
- **Tier 2 🟠**: Comprehensive unit tests, integration tests, and widget tests
- **Tier 3 🔴**: Full test suite including unit, integration, widget, and end-to-end tests

**Selected Tier**: 2 - This feature requires comprehensive testing due to payment processing (PCI DSS compliance), data validation complexity, image handling, and security requirements (encryption, RLS policies). However, full end-to-end testing (Tier 3) is not required as the feature is relatively straightforward from a user flow perspective.

## Cross-References

### Functional Requirements Reference

> **📋 Primary Documentation**: FDD Creation Task (PF-TSK-010)
> **🔗 Link**: [FDD-1.2.1: Basic Profile Data](/doc/product-docs/functional-design/fdds/fdd-1-2-1-basic-profile-data.md) > **👤 Owner**: FDD Creation Task
>
> **Purpose**: This section provides a brief testing-level perspective on functional requirements. Detailed user stories, use cases, business rules, and acceptance criteria are documented in the FDD.

#### Testing-Level Functional Context

Tests validate all functional requirements including profile viewing/editing, payment method management, username immutability, privacy controls, image upload/compression, and data validation. Business rules such as username uniqueness, email uniqueness, age verification (16+), and payment method default logic are validated through comprehensive test scenarios.

**Acceptance Criteria to Test**:

- Profile CRUD operations (view, edit, save) with all fields
- Username immutability after creation
- Privacy controls for name visibility (default: hidden)
- Image upload with automatic compression (5MB limit)
- Payment method CRUD operations with tokenization
- Default payment method logic (automatic and manual setting)
- All validation rules (username format, email format/uniqueness, age 16+, phone format, card validation)

**Business Rules to Validate**:

- Username uniqueness and format (3-30 chars, alphanumeric + underscores)
- Email uniqueness and format validation
- Age requirement (minimum 16 years old)
- Payment method default logic (at least one default if any exist)
- Cannot delete default payment method without setting another as default first
- Card number validation using Luhn algorithm
- Profile picture format (JPEG, PNG, WebP) and size (5MB with compression)

### API Specification Reference

> **📋 Primary Documentation**: API Design Task (PF-TSK-020)
> **🔗 Link**: [API Specification - Basic Profile Data (PD-API-011)](../../api/specifications/specifications/api-1.2.1-basic-profile-data.md) > **👤 Owner**: API Design Task
>
> **Purpose**: This section provides a brief testing-level perspective on API contracts. Detailed endpoint specifications, request/response schemas, and API patterns are documented in the API Specification.

#### Testing-Level API Context

Tests validate API contract compliance for all profile and payment method endpoints. Mock API responses are based on schemas defined in the API Specification. Integration tests verify correct API error handling patterns, authentication flows, and rate limiting behavior.

**API Contract Testing**:

- Profile endpoints: GET /profile, PUT /profile, POST /profile/image, DELETE /profile/image
- Payment method endpoints: GET /payment-methods, POST /payment-methods, PUT /payment-methods/:id, PUT /payment-methods/:id/set-default, DELETE /payment-methods/:id
- Request/response schema validation for all endpoints
- Error response format validation (standard error structure)

**Integration Testing Requirements**:

- Supabase integration for profile CRUD operations
- Supabase Storage integration for image uploads
- Payment gateway integration for tokenization (Stripe)
- Authentication flow testing (JWT tokens)
- RLS policy enforcement testing
- Rate limiting validation

### Database Schema Reference

> **📋 Primary Documentation**: Database Schema Design Task (PF-TSK-021)
> **🔗 Link**: [Schema Design - Basic Profile Data (PD-SCH-010)](../../database/schemas/1.2.1-basic-profile-data.md) > **👤 Owner**: Database Schema Design Task
>
> **Purpose**: This section provides a brief testing-level perspective on database interactions. Detailed schema definitions, table structures, relationships, and RLS policies are documented in the Database Schema Design.

#### Testing-Level Database Context

Tests validate RLS policies prevent unauthorized data access (users can only access their own profile and payment methods). Database integration tests verify correct data relationships (foreign keys, cascade deletes), constraint enforcement (unique username/email, CHECK constraints), and encryption of sensitive fields (payment tokens, billing addresses).

**Data Validation Testing**:

- Username uniqueness (case-insensitive)
- Email uniqueness (case-insensitive)
- Username format CHECK constraint (3-30 chars, alphanumeric + underscores)
- Age validation CHECK constraint (16+ years)
- Phone number format CHECK constraint
- Card expiry validation CHECK constraint (not in past)
- One default payment method per user (unique partial index)
- Foreign key cascade delete (payment methods deleted when user deleted)

**RLS Policy Testing**:

- Users can only SELECT their own profile data
- Users can only UPDATE their own profile data
- Users can only SELECT their own payment methods
- Users can only INSERT payment methods for themselves
- Users can only UPDATE their own payment methods
- Users can only DELETE their own payment methods
- Cross-user access attempts are blocked

### Technical Design Reference

> **📋 Primary Documentation**: TDD Creation Task (PF-TSK-022)
> **🔗 Link**: [TDD-1.2.1 - Basic Profile Data](../../architecture/design-docs/tdd/tdd/tdd-1.2.1-basic-profile-data-t1.md) > **👤 Owner**: TDD Creation Task
>
> **Purpose**: This section provides a brief testing-level perspective on technical implementation. Detailed component architecture, design patterns, and implementation details are documented in the TDD.

#### Testing-Level Implementation Context

Tests cover all components defined in TDD architecture including profile view/edit screens, payment management screen, validation logic, image compression, and payment tokenization. Mock strategy aligns with repository pattern design from TDD. Unit tests validate business logic implementation including Luhn algorithm, image compression, and encryption/decryption.

**Component Testing Strategy**:

- Widget tests for profile view, profile edit, and payment management screens
- Unit tests for validation logic (username, email, names, phone, birthday, card)
- Unit tests for image compression functionality
- Unit tests for Luhn algorithm card validation
- Integration tests for repository layer (Supabase CRUD operations)
- Integration tests for Supabase Storage (image upload/download)
- Integration tests for payment gateway (tokenization)

**Mock Requirements**:

- Mock Supabase client for database operations
- Mock Supabase Storage for image operations
- Mock payment gateway API for tokenization
- Mock image picker for profile picture selection
- Mock image compression library
- Mock encryption/decryption services

## Test Strategy

### Testing Levels

**Unit Tests** (Tier 2: Comprehensive):

- All validation logic (username, email, names, phone, birthday, card)
- Luhn algorithm implementation
- Image compression logic
- Encryption/decryption logic
- Business logic for default payment method handling
- Data model serialization/deserialization

**Widget Tests** (Tier 2: Comprehensive):

- Profile view screen rendering
- Profile edit screen with form validation
- Payment methods management screen
- Real-time validation feedback
- Loading states and error states
- Privacy toggle functionality

**Integration Tests** (Tier 2: Comprehensive):

- Supabase profile CRUD operations
- Supabase Storage image upload/download
- Payment gateway tokenization
- RLS policy enforcement
- Authentication flow
- End-to-end user flows (profile creation, editing, payment method management)

**Performance Tests** (Tier 2: Key scenarios):

- Profile loading time (< 1 second target)
- Profile update time (< 200ms target)
- Image upload time (< 5 seconds target)
- Payment method operations (< 2-3 seconds target)

**Security Tests** (Tier 2: Comprehensive):

- RLS policy enforcement
- Payment token encryption
- Billing address encryption
- Cross-user access prevention
- Input sanitization (SQL injection, XSS)
- PCI DSS compliance validation

## Test Cases

### 1. Profile Management Tests

#### 1.1 Profile Viewing

**Test Case ID**: TC-1.2.1-001
**Test Name**: View Complete Profile
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has complete profile data

**Test Steps**:

1. Navigate to profile view screen
2. Verify all profile fields are displayed correctly
3. Verify username is displayed as read-only
4. Verify profile image is displayed (or placeholder if none)
5. Verify privacy setting is displayed correctly

**Expected Results**:

- All profile fields display correct data
- Username field is not editable
- Profile loads within 1 second
- Privacy toggle shows correct state

**Acceptance Criteria**: 1-2-1-AC-1

---

**Test Case ID**: TC-1.2.1-002
**Test Name**: View Partial Profile (Mandatory Fields Only)
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has only mandatory fields (username, email)

**Test Steps**:

1. Navigate to profile view screen
2. Verify mandatory fields are displayed
3. Verify optional fields show as empty/placeholder
4. Verify profile completion status is shown

**Expected Results**:

- Username and email are displayed
- Optional fields show appropriate placeholders
- Profile completion indicator shows partial completion
- No errors are displayed

**Acceptance Criteria**: 1-2-1-AC-24

---

#### 1.2 Profile Editing

**Test Case ID**: TC-1.2.1-003
**Test Name**: Edit Profile - Valid Data
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has existing profile

**Test Steps**:

1. Navigate to profile edit screen
2. Update first name to "John"
3. Update last name to "Doe"
4. Update email to "john.doe@example.com"
5. Update phone to "+41791234567"
6. Select birthday (user is 18 years old)
7. Update address fields
8. Tap "Save Changes"

**Expected Results**:

- All fields accept valid input
- Real-time validation shows no errors
- Profile updates successfully within 200ms
- Success confirmation is displayed
- Updated data is reflected in profile view

**Acceptance Criteria**: 1-2-1-AC-3, 1-2-1-AC-5, 1-2-1-AC-8, 1-2-1-AC-9, 1-2-1-AC-10, 1-2-1-AC-22

---

**Test Case ID**: TC-1.2.1-004
**Test Name**: Edit Profile - Username Immutability
**Priority**: High
**Test Type**: Widget Test

**Preconditions**:

- User is authenticated
- User has existing profile with username "testuser"

**Test Steps**:

1. Navigate to profile edit screen
2. Verify username field is displayed as read-only
3. Attempt to tap/click username field
4. Verify field does not become editable

**Expected Results**:

- Username field is grayed out/disabled
- Username field does not respond to tap/click
- Username value cannot be changed
- No edit cursor appears in username field

**Acceptance Criteria**: 1-2-1-AC-2

---

**Test Case ID**: TC-1.2.1-005
**Test Name**: Edit Profile - Invalid Email Format
**Priority**: High
**Test Type**: Widget Test

**Preconditions**:

- User is authenticated
- User is on profile edit screen

**Test Steps**:

1. Enter invalid email "notanemail" in email field
2. Tap outside email field (trigger validation)
3. Observe validation feedback

**Expected Results**:

- Real-time validation error is displayed
- Error message: "Please enter a valid email address"
- Save button is disabled or shows error on tap
- Validation feedback appears within 100ms

**Acceptance Criteria**: 1-2-1-AC-5, 1-2-1-EC-4

---

**Test Case ID**: TC-1.2.1-006
**Test Name**: Edit Profile - Email Already Taken
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- Another user exists with email "taken@example.com"

**Test Steps**:

1. Navigate to profile edit screen
2. Update email to "taken@example.com"
3. Tap "Save Changes"
4. Observe error response

**Expected Results**:

- API returns 409 Conflict status
- Error message: "Email already in use. Please use a different email address"
- Profile is not updated
- User remains on edit screen with error displayed

**Acceptance Criteria**: 1-2-1-AC-18, 1-2-1-EC-3

---

**Test Case ID**: TC-1.2.1-007
**Test Name**: Edit Profile - Invalid Name Characters
**Priority**: Medium
**Test Type**: Widget Test

**Preconditions**:

- User is authenticated
- User is on profile edit screen

**Test Steps**:

1. Enter "John123" in first name field
2. Tap outside field (trigger validation)
3. Observe validation feedback

**Expected Results**:

- Real-time validation error is displayed
- Error message: "Names can only contain letters, spaces, hyphens, and apostrophes"
- Save button is disabled or shows error on tap

**Acceptance Criteria**: 1-2-1-EC-2

---

**Test Case ID**: TC-1.2.1-008
**Test Name**: Edit Profile - Age Under 16
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User is on profile edit screen

**Test Steps**:

1. Select birthday indicating user is 15 years old
2. Tap "Save Changes"
3. Observe error response

**Expected Results**:

- API returns 422 Unprocessable Entity status
- Error message: "You must be at least 16 years old to use this service"
- Profile is not updated
- Birthday field shows error state

**Acceptance Criteria**: 1-2-1-AC-9, 1-2-1-EC-8

---

**Test Case ID**: TC-1.2.1-009
**Test Name**: Edit Profile - Invalid Phone Format
**Priority**: Medium
**Test Type**: Widget Test

**Preconditions**:

- User is authenticated
- User is on profile edit screen

**Test Steps**:

1. Enter "123" in phone number field
2. Tap outside field (trigger validation)
3. Observe validation feedback

**Expected Results**:

- Real-time validation error is displayed
- Error message shows correct format example (E.164)
- Save button is disabled or shows error on tap

**Acceptance Criteria**: 1-2-1-AC-8, 1-2-1-EC-7

---

#### 1.3 Privacy Controls

**Test Case ID**: TC-1.2.1-010
**Test Name**: Toggle Name Visibility - Default Hidden
**Priority**: High
**Test Type**: Widget Test

**Preconditions**:

- User is authenticated
- User is on profile edit screen
- Privacy setting is default (hidden)

**Test Steps**:

1. Verify "Show name to friends" toggle is OFF
2. Toggle switch to ON
3. Tap "Save Changes"
4. Navigate back to profile view
5. Verify privacy setting is saved

**Expected Results**:

- Toggle defaults to OFF (hidden)
- Toggle switches to ON smoothly
- Setting is saved successfully
- Privacy setting persists after save

**Acceptance Criteria**: 1-2-1-AC-4

---

**Test Case ID**: TC-1.2.1-011
**Test Name**: Toggle Name Visibility - Show to Friends
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- Privacy setting is ON (show to friends)

**Test Steps**:

1. Verify database has `show_name_to_friends = TRUE`
2. Toggle switch to OFF
3. Tap "Save Changes"
4. Verify database updated to `show_name_to_friends = FALSE`

**Expected Results**:

- Database reflects privacy setting correctly
- Setting updates within 200ms
- No errors occur during update

**Acceptance Criteria**: 1-2-1-AC-4

---

### 2. Profile Image Tests

#### 2.1 Image Upload

**Test Case ID**: TC-1.2.1-012
**Test Name**: Upload Profile Picture - Valid Image
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has access to camera/gallery
- Test image is 2MB JPEG

**Test Steps**:

1. Tap profile picture area
2. Select "Choose from gallery"
3. Select test image (2MB JPEG)
4. Confirm selection
5. Wait for upload to complete

**Expected Results**:

- Image picker opens successfully
- Image uploads within 5 seconds
- Profile picture updates in UI immediately
- Image URL is stored in database
- Image is accessible via Supabase Storage

**Acceptance Criteria**: 1-2-1-AC-6

---

**Test Case ID**: TC-1.2.1-013
**Test Name**: Upload Profile Picture - Automatic Compression
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- Test image is 8MB JPEG (exceeds 5MB limit)

**Test Steps**:

1. Tap profile picture area
2. Select test image (8MB)
3. Observe compression process
4. Wait for upload to complete
5. Verify uploaded image size

**Expected Results**:

- Image is automatically compressed to under 5MB
- Compression maintains acceptable quality
- Upload completes within 5 seconds
- Compressed image is stored in Supabase Storage

**Acceptance Criteria**: 1-2-1-AC-19

---

**Test Case ID**: TC-1.2.1-014
**Test Name**: Upload Profile Picture - Unsupported Format
**Priority**: Medium
**Test Type**: Widget Test

**Preconditions**:

- User is authenticated
- Test image is BMP format (unsupported)

**Test Steps**:

1. Tap profile picture area
2. Select test image (BMP)
3. Observe error handling

**Expected Results**:

- Cropping/resizing interface opens for format conversion
- User can convert to supported format (JPEG, PNG, WebP)
- Converted image uploads successfully

**Acceptance Criteria**: 1-2-1-AC-19, 1-2-1-EC-5

---

**Test Case ID**: TC-1.2.1-015
**Test Name**: Upload Profile Picture - Compression Failure
**Priority**: Low
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- Test image causes compression failure (corrupted)

**Test Steps**:

1. Tap profile picture area
2. Select corrupted test image
3. Observe error handling

**Expected Results**:

- Error message: "Image compression failed. Please select a different image or skip profile picture"
- Option to select different image
- Option to skip profile picture
- No crash or undefined behavior

**Acceptance Criteria**: 1-2-1-EC-6

---

#### 2.2 Image Deletion

**Test Case ID**: TC-1.2.1-016
**Test Name**: Delete Profile Picture
**Priority**: Medium
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has existing profile picture

**Test Steps**:

1. Navigate to profile edit screen
2. Tap "Remove profile picture" button
3. Confirm deletion
4. Verify profile picture is removed

**Expected Results**:

- Profile picture is deleted from Supabase Storage
- Database field `profile_image_url` is set to NULL
- UI shows placeholder image
- Deletion completes within 200ms

**Acceptance Criteria**: N/A (implied functionality)

---

### 3. Payment Method Tests

#### 3.1 Payment Method Viewing

**Test Case ID**: TC-1.2.1-017
**Test Name**: View Payment Methods - Multiple Methods
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has 3 saved payment methods
- One method is set as default

**Test Steps**:

1. Navigate to payment methods management screen
2. Verify all payment methods are displayed
3. Verify default indicator is shown correctly
4. Verify card numbers are masked (last 4 digits only)

**Expected Results**:

- All 3 payment methods are displayed
- Default method shows "Default" indicator
- Card numbers show only last 4 digits (e.g., "\*\*\*\* 1234")
- Card brands are displayed (Visa, Mastercard, etc.)
- Screen loads within 2 seconds

**Acceptance Criteria**: 1-2-1-AC-11, 1-2-1-AC-12

---

**Test Case ID**: TC-1.2.1-018
**Test Name**: View Payment Methods - No Methods
**Priority**: Medium
**Test Type**: Widget Test

**Preconditions**:

- User is authenticated
- User has no saved payment methods

**Test Steps**:

1. Navigate to payment methods management screen
2. Verify empty state is displayed

**Expected Results**:

- Empty state message: "No payment methods saved"
- "Add Payment Method" button is prominently displayed
- No errors are shown

**Acceptance Criteria**: 1-2-1-AC-11

---

#### 3.2 Payment Method Addition

**Test Case ID**: TC-1.2.1-019
**Test Name**: Add Payment Method - Valid Credit Card
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has no existing payment methods
- Test card: 4242 4242 4242 4242 (Visa test card)

**Test Steps**:

1. Tap "Add Payment Method"
2. Select "Credit Card"
3. Enter card number: 4242 4242 4242 4242
4. Enter expiry: 12/2025
5. Enter CVV: 123
6. Enter billing address
7. Tap "Save"
8. Wait for tokenization and save

**Expected Results**:

- Card number passes Luhn validation
- Payment gateway tokenizes card successfully
- Payment method is saved to database with encrypted token
- Method is automatically set as default (first method)
- Success confirmation is displayed
- Operation completes within 3 seconds

**Acceptance Criteria**: 1-2-1-AC-11, 1-2-1-AC-20, 1-2-1-AC-21

---

**Test Case ID**: TC-1.2.1-020
**Test Name**: Add Payment Method - Invalid Card Number (Luhn)
**Priority**: High
**Test Type**: Unit Test

**Preconditions**:

- User is authenticated
- User is on add payment method screen

**Test Steps**:

1. Enter invalid card number: 1234 5678 9012 3456
2. Tap outside field (trigger validation)
3. Observe validation feedback

**Expected Results**:

- Luhn algorithm validation fails
- Real-time validation error is displayed
- Error message: "Invalid card number"
- Save button is disabled or shows error on tap

**Acceptance Criteria**: 1-2-1-AC-20, 1-2-1-EC-9

---

**Test Case ID**: TC-1.2.1-021
**Test Name**: Add Payment Method - Expired Card
**Priority**: High
**Test Type**: Widget Test

**Preconditions**:

- User is authenticated
- User is on add payment method screen

**Test Steps**:

1. Enter valid card number
2. Enter expiry: 01/2020 (past date)
3. Tap outside field (trigger validation)
4. Observe validation feedback

**Expected Results**:

- Validation error is displayed
- Error message: "Card expiration date is in the past"
- Save button is disabled or shows error on tap

**Acceptance Criteria**: 1-2-1-EC-10

---

**Test Case ID**: TC-1.2.1-022
**Test Name**: Add Payment Method - Tokenization Failure
**Priority**: Medium
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- Payment gateway is configured to fail tokenization

**Test Steps**:

1. Enter valid card details
2. Tap "Save"
3. Observe error handling

**Expected Results**:

- API returns 402 Payment Required status
- Error message: "Payment processing failed. Please try again or use a different card"
- Payment method is not saved
- User remains on add payment method screen

**Acceptance Criteria**: 1-2-1-EC-11

---

**Test Case ID**: TC-1.2.1-023
**Test Name**: Add Payment Method - Second Method Not Default
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has 1 existing payment method (default)

**Test Steps**:

1. Add second payment method
2. Verify new method is saved
3. Verify new method is NOT set as default
4. Verify original method remains default

**Expected Results**:

- Second method is saved successfully
- Second method has `is_default = FALSE`
- First method still has `is_default = TRUE`
- Only one default method exists

**Acceptance Criteria**: 1-2-1-AC-11

---

#### 3.3 Payment Method Editing

**Test Case ID**: TC-1.2.1-024
**Test Name**: Edit Payment Method - Update Expiry Date
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has existing payment method with expiry 12/2025

**Test Steps**:

1. Tap on payment method to edit
2. Update expiry to 06/2026
3. Tap "Save"
4. Verify update is saved

**Expected Results**:

- Expiry date updates successfully
- Database reflects new expiry date
- Card number remains unchanged (cannot be edited)
- Update completes within 2 seconds

**Acceptance Criteria**: 1-2-1-AC-13

---

**Test Case ID**: TC-1.2.1-025
**Test Name**: Edit Payment Method - Update Billing Address
**Priority**: Medium
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has existing payment method

**Test Steps**:

1. Tap on payment method to edit
2. Update billing street address
3. Update billing city
4. Update billing postal code
5. Tap "Save"
6. Verify updates are saved

**Expected Results**:

- Billing address updates successfully
- New address is encrypted at rest
- Database reflects encrypted address
- Update completes within 2 seconds

**Acceptance Criteria**: 1-2-1-AC-13

---

#### 3.4 Default Payment Method

**Test Case ID**: TC-1.2.1-026
**Test Name**: Set Payment Method as Default
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has 2 payment methods
- Method A is default, Method B is not

**Test Steps**:

1. Tap "Set as Default" on Method B
2. Verify Method B becomes default
3. Verify Method A is no longer default
4. Verify only one default exists

**Expected Results**:

- Method B has `is_default = TRUE`
- Method A has `is_default = FALSE`
- Database enforces only one default (unique partial index)
- Update completes within 200ms

**Acceptance Criteria**: 1-2-1-AC-15

---

#### 3.5 Payment Method Deletion

**Test Case ID**: TC-1.2.1-027
**Test Name**: Delete Non-Default Payment Method
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has 2 payment methods
- Method A is default, Method B is not

**Test Steps**:

1. Tap "Delete" on Method B
2. Confirm deletion
3. Verify Method B is deleted
4. Verify Method A remains as default

**Expected Results**:

- Method B is deleted from database
- Method A remains unchanged
- Default status is preserved
- Deletion completes within 200ms

**Acceptance Criteria**: 1-2-1-AC-14

---

**Test Case ID**: TC-1.2.1-028
**Test Name**: Delete Default Payment Method - Auto-Set New Default
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has 2 payment methods
- Method A is default

**Test Steps**:

1. Tap "Delete" on Method A (default)
2. Confirm deletion
3. Verify Method A is deleted
4. Verify Method B is automatically set as default

**Expected Results**:

- Method A is deleted from database
- Method B automatically becomes default (`is_default = TRUE`)
- Response includes new default ID
- Business rule enforced: at least one default if any methods exist

**Acceptance Criteria**: 1-2-1-AC-14, 1-2-1-EC-12

---

**Test Case ID**: TC-1.2.1-029
**Test Name**: Delete Last Payment Method
**Priority**: Medium
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has 1 payment method (default)

**Test Steps**:

1. Tap "Delete" on last payment method
2. Confirm deletion
3. Verify method is deleted
4. Verify empty state is displayed

**Expected Results**:

- Payment method is deleted from database
- No default payment method exists (acceptable when no methods)
- Empty state message is displayed
- User can add new payment method

**Acceptance Criteria**: 1-2-1-AC-14

---

### 4. Security Tests

#### 4.1 RLS Policy Tests

**Test Case ID**: TC-1.2.1-030
**Test Name**: RLS - User Can Only View Own Profile
**Priority**: Critical
**Test Type**: Integration Test

**Preconditions**:

- User A is authenticated
- User B exists with different user_id

**Test Steps**:

1. User A attempts to query User B's profile data
2. Observe database response

**Expected Results**:

- Query returns no data (RLS policy blocks access)
- User A can only see their own profile
- No error is thrown (silent filtering)

**Acceptance Criteria**: Security requirement

---

**Test Case ID**: TC-1.2.1-031
**Test Name**: RLS - User Can Only Update Own Profile
**Priority**: Critical
**Test Type**: Integration Test

**Preconditions**:

- User A is authenticated
- User B exists with different user_id

**Test Steps**:

1. User A attempts to update User B's profile data
2. Observe database response

**Expected Results**:

- Update operation fails (RLS policy blocks)
- User B's data remains unchanged
- API returns 403 Forbidden or no rows affected

**Acceptance Criteria**: Security requirement

---

**Test Case ID**: TC-1.2.1-032
**Test Name**: RLS - User Can Only View Own Payment Methods
**Priority**: Critical
**Test Type**: Integration Test

**Preconditions**:

- User A is authenticated
- User B has payment methods

**Test Steps**:

1. User A attempts to query User B's payment methods
2. Observe database response

**Expected Results**:

- Query returns empty array (RLS policy blocks access)
- User A cannot see User B's payment methods
- No error is thrown (silent filtering)

**Acceptance Criteria**: Security requirement

---

**Test Case ID**: TC-1.2.1-033
**Test Name**: RLS - User Cannot Delete Other User's Payment Methods
**Priority**: Critical
**Test Type**: Integration Test

**Preconditions**:

- User A is authenticated
- User B has payment method with known ID

**Test Steps**:

1. User A attempts to delete User B's payment method by ID
2. Observe database response

**Expected Results**:

- Delete operation fails (RLS policy blocks)
- User B's payment method remains unchanged
- API returns 403 Forbidden or no rows affected

**Acceptance Criteria**: Security requirement

---

#### 4.2 Encryption Tests

**Test Case ID**: TC-1.2.1-034
**Test Name**: Payment Token Encryption at Rest
**Priority**: Critical
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- Payment method is saved

**Test Steps**:

1. Add payment method with tokenization
2. Query database directly to inspect `payment_token` field
3. Verify token is encrypted

**Expected Results**:

- `payment_token` field contains encrypted data (not plaintext)
- Encryption uses AES-256
- Token cannot be read without decryption key

**Acceptance Criteria**: 1-2-1-AC-21

---

**Test Case ID**: TC-1.2.1-035
**Test Name**: Billing Address Encryption at Rest
**Priority**: Critical
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- Payment method with billing address is saved

**Test Steps**:

1. Add payment method with billing address
2. Query database directly to inspect billing address fields
3. Verify addresses are encrypted

**Expected Results**:

- Billing address fields contain encrypted data (not plaintext)
- Encryption uses AES-256
- Addresses cannot be read without decryption key

**Acceptance Criteria**: 1-2-1-AC-21

---

**Test Case ID**: TC-1.2.1-036
**Test Name**: CVV Never Stored
**Priority**: Critical
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated

**Test Steps**:

1. Add payment method with CVV: 123
2. Query database to inspect all payment method fields
3. Verify CVV is not stored anywhere

**Expected Results**:

- CVV is not present in any database field
- CVV is used only for tokenization
- PCI DSS compliance maintained

**Acceptance Criteria**: 1-2-1-AC-21

---

**Test Case ID**: TC-1.2.1-037
**Test Name**: Full Card Number Never Stored
**Priority**: Critical
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated

**Test Steps**:

1. Add payment method with card: 4242 4242 4242 4242
2. Query database to inspect all payment method fields
3. Verify only last 4 digits are stored

**Expected Results**:

- `card_last_4` field contains "4242" only
- Full card number is not stored anywhere
- PCI DSS compliance maintained

**Acceptance Criteria**: 1-2-1-AC-21

---

#### 4.3 Input Validation Security

**Test Case ID**: TC-1.2.1-038
**Test Name**: SQL Injection Prevention - Profile Fields
**Priority**: Critical
**Test Type**: Security Test

**Preconditions**:

- User is authenticated

**Test Steps**:

1. Attempt to inject SQL in first name: "John'; DROP TABLE users; --"
2. Attempt to save profile
3. Verify SQL injection is prevented

**Expected Results**:

- Input is sanitized or parameterized
- SQL injection does not execute
- Database tables remain intact
- Input is either rejected or stored as literal string

**Acceptance Criteria**: Security requirement

---

**Test Case ID**: TC-1.2.1-039
**Test Name**: XSS Prevention - Profile Fields
**Priority**: High
**Test Type**: Security Test

**Preconditions**:

- User is authenticated

**Test Steps**:

1. Enter XSS payload in first name: "<script>alert('XSS')</script>"
2. Save profile
3. View profile in UI
4. Verify XSS does not execute

**Expected Results**:

- Script tags are encoded or sanitized
- XSS payload does not execute in browser
- Output is properly encoded
- No JavaScript alert appears

**Acceptance Criteria**: Security requirement

---

### 5. Performance Tests

**Test Case ID**: TC-1.2.1-040
**Test Name**: Profile Loading Performance
**Priority**: High
**Test Type**: Performance Test

**Preconditions**:

- User is authenticated
- User has complete profile data

**Test Steps**:

1. Navigate to profile view screen
2. Measure time from navigation to full render
3. Repeat 10 times and calculate average

**Expected Results**:

- Average load time < 1 second
- 95th percentile < 1.5 seconds
- No performance degradation over multiple loads

**Acceptance Criteria**: Performance requirement from TDD

---

**Test Case ID**: TC-1.2.1-041
**Test Name**: Profile Update Performance
**Priority**: High
**Test Type**: Performance Test

**Preconditions**:

- User is authenticated
- User is on profile edit screen

**Test Steps**:

1. Update profile fields
2. Tap "Save Changes"
3. Measure time from save to success confirmation
4. Repeat 10 times and calculate average

**Expected Results**:

- Average update time < 200ms
- 95th percentile < 300ms
- No performance degradation over multiple updates

**Acceptance Criteria**: Performance requirement from TDD

---

**Test Case ID**: TC-1.2.1-042
**Test Name**: Image Upload Performance
**Priority**: High
**Test Type**: Performance Test

**Preconditions**:

- User is authenticated
- Test image is 3MB JPEG

**Test Steps**:

1. Select test image for upload
2. Measure time from selection to upload complete
3. Repeat 5 times and calculate average

**Expected Results**:

- Average upload time < 5 seconds
- 95th percentile < 7 seconds
- Compression does not significantly impact time

**Acceptance Criteria**: Performance requirement from TDD

---

**Test Case ID**: TC-1.2.1-043
**Test Name**: Payment Method Operations Performance
**Priority**: High
**Test Type**: Performance Test

**Preconditions**:

- User is authenticated

**Test Steps**:

1. Add payment method and measure time
2. Update payment method and measure time
3. Set default and measure time
4. Delete payment method and measure time
5. Repeat each operation 5 times and calculate averages

**Expected Results**:

- Add payment method: < 3 seconds average
- Update payment method: < 2 seconds average
- Set default: < 200ms average
- Delete payment method: < 200ms average

**Acceptance Criteria**: Performance requirement from TDD

---

### 6. Edge Cases and Error Handling

**Test Case ID**: TC-1.2.1-044
**Test Name**: Network Failure During Profile Update
**Priority**: Medium
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- Network is simulated to fail during update

**Test Steps**:

1. Update profile fields
2. Tap "Save Changes"
3. Simulate network failure
4. Observe error handling

**Expected Results**:

- Error message: "Network error. Please check your connection and try again"
- Profile is not updated
- User can retry operation
- No data corruption occurs

**Acceptance Criteria**: Reliability requirement from TDD

---

**Test Case ID**: TC-1.2.1-045
**Test Name**: Concurrent Profile Updates
**Priority**: Low
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has profile open in two devices/tabs

**Test Steps**:

1. Update first name to "John" in Device A
2. Update first name to "Jane" in Device B simultaneously
3. Save both updates
4. Verify final state

**Expected Results**:

- Last write wins (database handles concurrency)
- No data corruption occurs
- Both devices eventually show consistent data
- No errors are thrown

**Acceptance Criteria**: Data integrity requirement from TDD

---

**Test Case ID**: TC-1.2.1-046
**Test Name**: User Deletion Cascades Payment Methods
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User is authenticated
- User has 3 payment methods

**Test Steps**:

1. Delete user account
2. Verify payment methods are also deleted
3. Verify foreign key cascade works correctly

**Expected Results**:

- User record is deleted
- All 3 payment methods are automatically deleted (CASCADE)
- No orphaned payment method records remain
- Database referential integrity is maintained

**Acceptance Criteria**: Database constraint requirement

---

**Test Case ID**: TC-1.2.1-047
**Test Name**: Duplicate Username Prevention (Case-Insensitive)
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User A exists with username "testuser"
- User B is registering

**Test Steps**:

1. User B attempts to register with username "TestUser" (different case)
2. Observe validation response

**Expected Results**:

- Registration fails
- Error message: "Username already exists. Please choose a different one"
- Case-insensitive uniqueness is enforced
- Suggested alternatives may be provided

**Acceptance Criteria**: 1-2-1-AC-16, 1-2-1-EC-1

---

**Test Case ID**: TC-1.2.1-048
**Test Name**: Duplicate Email Prevention (Case-Insensitive)
**Priority**: High
**Test Type**: Integration Test

**Preconditions**:

- User A exists with email "test@example.com"
- User B is updating profile

**Test Steps**:

1. User B attempts to update email to "Test@Example.com" (different case)
2. Observe validation response

**Expected Results**:

- Update fails
- Error message: "Email already in use. Please use a different email address"
- Case-insensitive uniqueness is enforced

**Acceptance Criteria**: 1-2-1-AC-18, 1-2-1-EC-3

---

## Test Data

### Valid Test Data

**User Profiles**:

```json
{
  "username": "testuser123",
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "phone_number": "+41791234567",
  "birthday": "1990-01-15",
  "gender": "Male",
  "street_address": "123 Main Street",
  "city": "Zurich",
  "postal_code": "8001",
  "country": "Switzerland",
  "show_name_to_friends": false
}
```

**Payment Methods**:

```json
{
  "payment_type": "credit_card",
  "card_number": "4242424242424242",
  "expiry_month": 12,
  "expiry_year": 2025,
  "cvv": "123",
  "billing_street_address": "123 Main Street",
  "billing_city": "Zurich",
  "billing_postal_code": "8001",
  "billing_country": "Switzerland"
}
```

### Invalid Test Data

**Invalid Usernames**:

- "ab" (too short, < 3 chars)
- "this_username_is_way_too_long_for_validation" (too long, > 30 chars)
- "user name" (contains space)
- "user@name" (contains special char)

**Invalid Emails**:

- "notanemail" (missing @)
- "test@" (missing domain)
- "@example.com" (missing local part)

**Invalid Names**:

- "John123" (contains numbers)
- "John@Doe" (contains special chars)

**Invalid Phone Numbers**:

- "123" (too short)
- "abcdefg" (contains letters)

**Invalid Birthdates**:

- "2010-01-01" (under 16 years old)
- "2025-01-01" (future date)

**Invalid Card Numbers**:

- "1234567890123456" (fails Luhn algorithm)
- "4242" (too short)

**Invalid Expiry Dates**:

- Month: 0, 13 (out of range 1-12)
- Year: 2020 (past date)

### Test Images

**Valid Images**:

- 2MB JPEG (within limit, no compression needed)
- 1MB PNG (within limit, no compression needed)
- 500KB WebP (within limit, no compression needed)

**Images Requiring Compression**:

- 8MB JPEG (exceeds 5MB, requires compression)
- 10MB PNG (exceeds 5MB, requires compression)

**Invalid Images**:

- BMP format (unsupported, requires conversion)
- Corrupted JPEG (should trigger error handling)

## Test Environment Setup

### Prerequisites

**Development Environment**:

- Flutter SDK (latest stable)
- Dart SDK (latest stable)
- Android Studio / Xcode for mobile testing
- VS Code with Flutter extensions

**Backend Services**:

- Supabase project with test database
- Supabase Storage bucket for profile images
- Payment gateway test account (Stripe test mode)

**Test Database**:

- Separate test database instance
- Test data seeded with sample users
- RLS policies enabled
- Encryption keys configured

**Mock Services**:

- Mock Supabase client for unit tests
- Mock payment gateway for unit tests
- Mock image picker for widget tests

### Test Data Setup

**Seed Data**:

- 5 test users with varying profile completeness
- 10 test payment methods across users
- 5 test profile images in Supabase Storage

**Test Accounts**:

- User A: Complete profile, 3 payment methods
- User B: Partial profile (mandatory fields only), no payment methods
- User C: Complete profile, 1 payment method
- User D: Profile with privacy settings enabled
- User E: New user (for registration testing)

## Test Execution Plan

### Phase 1: Unit Tests (Week 1)

- Validation logic tests (username, email, names, phone, birthday, card)
- Luhn algorithm tests
- Image compression tests
- Encryption/decryption tests
- Business logic tests (default payment method handling)

**Target**: 80% code coverage for business logic

### Phase 2: Widget Tests (Week 1-2)

- Profile view screen tests
- Profile edit screen tests
- Payment methods management screen tests
- Form validation tests
- Loading and error state tests

**Target**: 70% widget coverage

### Phase 3: Integration Tests (Week 2-3)

- Supabase CRUD operation tests
- Supabase Storage tests
- Payment gateway integration tests
- RLS policy tests
- Authentication flow tests
- End-to-end user flow tests

**Target**: All critical user flows covered

### Phase 4: Security Tests (Week 3)

- RLS policy enforcement tests
- Encryption tests
- Input validation security tests (SQL injection, XSS)
- PCI DSS compliance validation

**Target**: All security requirements validated

### Phase 5: Performance Tests (Week 3-4)

- Profile loading performance
- Profile update performance
- Image upload performance
- Payment method operations performance

**Target**: All performance targets met

## Success Criteria

### Test Coverage Targets

- **Unit Tests**: 80% code coverage for business logic
- **Widget Tests**: 70% widget coverage
- **Integration Tests**: 100% critical user flow coverage
- **Security Tests**: 100% security requirement coverage

### Quality Gates

- All critical and high priority tests must pass
- No critical or high severity bugs in production
- Performance targets met for all operations
- Security requirements validated (PCI DSS, GDPR/FADP)

### Acceptance Criteria Validation

- All 24 acceptance criteria from FDD validated
- All edge cases and error scenarios tested
- All business rules enforced and validated

## Test Reporting

### Test Metrics

- Test execution status (pass/fail/blocked)
- Code coverage percentages
- Performance test results
- Security test results
- Defect density and severity distribution

### Deliverables

- Test execution report
- Code coverage report
- Performance test report
- Security test report
- Defect log with severity and status

## Changelog

### Version 1.0 (2025-01-27)

- Initial test specification for Basic Profile Data feature
- Comprehensive test cases for profile management (viewing, editing, privacy controls)
- Comprehensive test cases for profile image management (upload, compression, deletion)
- Comprehensive test cases for payment method management (CRUD operations, default logic)
- Security test cases (RLS policies, encryption, input validation)
- Performance test cases (loading, updates, image uploads, payment operations)
- Edge cases and error handling test cases
- Test data definitions and test environment setup
- Test execution plan and success criteria
