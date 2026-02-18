---
id: PD-ERD-010
type: Technical Documentation
category: Database Diagram
version: 1.0
created: 2025-01-27
updated: 2025-01-27
feature_id: 1.2.1
schema_id: PD-SCH-010
---

# Basic Profile Data - Entity Relationship Diagram

## Overview

This document provides the Entity-Relationship Diagram (ERD) for the Basic Profile Data feature (1.2.1), showing the data model for user profiles and payment methods.

**Related Documents**:

- [Schema Design: Basic Profile Data](../schemas/basic-profile-data.md)
- [FDD-1.2.1: Basic Profile Data](/doc/product-docs/functional-design/fdds/fdd-1-2-1-basic-profile-data.md)
- [TDD-1.2.1: Basic Profile Data](/doc/product-docs/technical/architecture/design-docs/tdd/tdd/tdd-1.2.1-basic-profile-data-t1.md)

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              auth.users (Supabase Auth)                      │
│─────────────────────────────────────────────────────────────────────────────│
│ PK  id                    UUID                                               │
│     email                 TEXT                                               │
│     encrypted_password    TEXT                                               │
│     email_confirmed_at    TIMESTAMP WITH TIME ZONE                           │
│     created_at            TIMESTAMP WITH TIME ZONE                           │
│     updated_at            TIMESTAMP WITH TIME ZONE                           │
│     ... (other Supabase auth fields)                                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        │ 1
                                        │
                                        │ references (ON DELETE CASCADE)
                                        │
                                        │ 1
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                   profiles                                   │
│─────────────────────────────────────────────────────────────────────────────│
│ PK  id                    UUID (references auth.users.id)                    │
│ UK  username              VARCHAR(30)  NOT NULL  [idx_profiles_username]     │
│ UK  email                 TEXT         NOT NULL  [idx_profiles_email]        │
│     first_name            VARCHAR(100) NOT NULL                              │
│     last_name             VARCHAR(100) NOT NULL                              │
│     show_name_to_friends  BOOLEAN      NOT NULL  DEFAULT FALSE               │
│     profile_image_url     TEXT         NULL                                  │
│     gender                VARCHAR(50)  NULL                                  │
│     phone_number          VARCHAR(20)  NULL                                  │
│     birthday              DATE         NULL      [idx_profiles_birthday]     │
│     street_address        VARCHAR(255) NULL                                  │
│     city                  VARCHAR(100) NULL                                  │
│     postal_code           VARCHAR(20)  NULL                                  │
│     country               VARCHAR(100) NULL                                  │
│     created_at            TIMESTAMP WITH TIME ZONE  NOT NULL                 │
│     updated_at            TIMESTAMP WITH TIME ZONE  NOT NULL                 │
│─────────────────────────────────────────────────────────────────────────────│
│ Constraints:                                                                 │
│   • username: 3-30 chars, alphanumeric + underscores                         │
│   • phone_number: International format validation                            │
│   • birthday: Must be 16+ years old                                          │
│─────────────────────────────────────────────────────────────────────────────│
│ Indexes:                                                                     │
│   • idx_profiles_username (UNIQUE, case-insensitive)                         │
│   • idx_profiles_email (UNIQUE, case-insensitive)                            │
│   • idx_profiles_birthday (partial, WHERE birthday IS NOT NULL)              │
│─────────────────────────────────────────────────────────────────────────────│
│ RLS Policies:                                                                │
│   • SELECT: Public (all users can view all profiles)                         │
│   • INSERT: Users can only insert their own profile                          │
│   • UPDATE: Users can only update their own profile                          │
│   • DELETE: Users can only delete their own profile                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        │ 1
                                        │
                                        │
                                        │
                                        │ *
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              payment_methods                                 │
│─────────────────────────────────────────────────────────────────────────────│
│ PK  id                       UUID                                            │
│ FK  user_id                  UUID  NOT NULL  [idx_payment_methods_user_id]   │
│     payment_type             VARCHAR(20)  NOT NULL                           │
│     payment_token            TEXT         NOT NULL  🔒 ENCRYPTED             │
│     card_last_4              VARCHAR(4)   NULL                               │
│     card_brand               VARCHAR(20)  NULL                               │
│     expiry_month             INTEGER      NULL                               │
│     expiry_year              INTEGER      NULL                               │
│     billing_street_address   TEXT         NULL     🔒 ENCRYPTED              │
│     billing_city             TEXT         NULL     🔒 ENCRYPTED              │
│     billing_postal_code      TEXT         NULL     🔒 ENCRYPTED              │
│     billing_country          TEXT         NULL     🔒 ENCRYPTED              │
│     is_default               BOOLEAN      NOT NULL  DEFAULT FALSE            │
│     is_active                BOOLEAN      NOT NULL  DEFAULT TRUE             │
│     created_at               TIMESTAMP WITH TIME ZONE  NOT NULL              │
│     updated_at               TIMESTAMP WITH TIME ZONE  NOT NULL              │
│─────────────────────────────────────────────────────────────────────────────│
│ Foreign Keys:                                                                │
│   • user_id → auth.users.id (ON DELETE CASCADE)                              │
│─────────────────────────────────────────────────────────────────────────────│
│ Constraints:                                                                 │
│   • payment_type: IN ('card', 'paypal', 'bank_transfer')                     │
│   • card_last_4: Exactly 4 digits                                            │
│   • expiry_month: 1-12 range                                                 │
│   • expiry_year: Not in the past                                             │
│   • Only one default payment method per user (enforced by unique index)      │
│─────────────────────────────────────────────────────────────────────────────│
│ Indexes:                                                                     │
│   • idx_payment_methods_user_id (partial, WHERE is_active = TRUE)            │
│   • idx_payment_methods_user_default (UNIQUE partial, WHERE is_default       │
│     = TRUE AND is_active = TRUE)                                             │
│   • idx_payment_methods_created_at (DESC)                                    │
│─────────────────────────────────────────────────────────────────────────────│
│ RLS Policies:                                                                │
│   • SELECT: Users can only view their own payment methods                    │
│   • INSERT: Users can only insert their own payment methods                  │
│   • UPDATE: Users can only update their own payment methods                  │
│   • DELETE: Users can only delete their own payment methods                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Relationship Details

### auth.users → profiles (1:1)

- **Type**: One-to-One (mandatory)
- **Relationship**: Each Supabase auth user has exactly one profile
- **Foreign Key**: `profiles.id` REFERENCES `auth.users.id` ON DELETE CASCADE
- **Cascade Behavior**: When a user is deleted from auth.users, their profile is automatically deleted
- **Business Rule**: Profile must be created during user registration

### profiles → payment_methods (1:\*)

- **Type**: One-to-Many (optional)
- **Relationship**: Each user can have zero or more payment methods
- **Foreign Key**: `payment_methods.user_id` REFERENCES `auth.users.id` ON DELETE CASCADE
- **Cascade Behavior**: When a user is deleted, all their payment methods are automatically deleted
- **Business Rules**:
  - A user can have multiple payment methods
  - Only one payment method can be marked as default per user
  - Payment methods can be soft-deleted (is_active = FALSE) to maintain transaction history

## Data Flow

### User Profile Creation Flow

```
User Registration
       │
       ▼
Create auth.users record (Supabase Auth)
       │
       ▼
Create profiles record
       │
       ├─ Set username (immutable)
       ├─ Set email (from auth.users)
       ├─ Set first_name, last_name
       └─ Set show_name_to_friends = FALSE (default)
       │
       ▼
Profile Created ✓
```

### Payment Method Addition Flow

```
User Adds Payment Method
       │
       ▼
Validate Card Details (Luhn algorithm)
       │
       ▼
Tokenize via Payment Gateway API
       │
       ▼
Encrypt payment_token (AES-256)
       │
       ▼
Encrypt billing address fields (AES-256)
       │
       ▼
Create payment_methods record
       │
       ├─ Store payment_token (encrypted)
       ├─ Store card_last_4 (plain text)
       ├─ Store card_brand, expiry_month, expiry_year
       ├─ Store billing address (encrypted)
       └─ Set is_default (if first payment method)
       │
       ▼
Payment Method Added ✓
```

## Security Considerations

### Encryption

- **🔒 Encrypted Fields** (AES-256):
  - `payment_methods.payment_token`
  - `payment_methods.billing_street_address`
  - `payment_methods.billing_city`
  - `payment_methods.billing_postal_code`
  - `payment_methods.billing_country`

### Row Level Security (RLS)

- **profiles table**: Public read access for social features, users can only modify their own profile
- **payment_methods table**: Complete isolation - users can only access their own payment methods

### PCI DSS Compliance

- **Never store**: Full card numbers, CVV codes
- **Store only**: Tokenized payment references, last 4 digits, card brand, expiry date
- **Encryption**: All sensitive payment data encrypted at rest

## Performance Characteristics

### Expected Query Performance

| Operation                   | Target | Index Used                       |
| --------------------------- | ------ | -------------------------------- |
| Profile lookup by ID        | <50ms  | Primary key                      |
| Username availability check | <50ms  | idx_profiles_username            |
| Email lookup                | <50ms  | idx_profiles_email               |
| Load user's payment methods | <200ms | idx_payment_methods_user_id      |
| Get default payment method  | <100ms | idx_payment_methods_user_default |

### Scalability Considerations

- **profiles table**: Expected to grow linearly with user base (1:1 ratio)
- **payment_methods table**: Expected to grow at ~2-3x user base (average 2-3 payment methods per user)
- **Index overhead**: Minimal - all indexes are necessary for query performance
- **Storage overhead**: Encryption adds ~30% storage overhead for encrypted fields

## Migration Notes

### Applied Migrations

1. **add_basic_profile_fields** (Applied: 2025-01-27)

   - Extended profiles table with 14 new fields
   - Added CHECK constraints for validation
   - Created performance indexes
   - Added automatic timestamp trigger

2. **create_payment_methods_table** (Applied: 2025-01-27)

   - Created payment_methods table
   - Added validation constraints
   - Created performance indexes
   - Enabled RLS with policies

3. **add_profiles_rls_policies** (Applied: 2025-01-27)
   - Enabled RLS on profiles table
   - Created access policies

### Rollback Considerations

- All migrations include rollback procedures
- Foreign key constraints prevent orphaned records
- Soft delete (is_active) on payment_methods preserves transaction history

## Future Enhancements

### Potential Schema Extensions

1. **Address Validation**: Add state/province fields for better international support
2. **Payment Method Metadata**: Add fields for payment gateway-specific metadata
3. **Profile Verification**: Add fields for identity verification status
4. **Multi-Currency Support**: Add preferred currency field to profiles
5. **Payment History**: Create separate table for payment transaction history

### Performance Optimizations

1. **Partitioning**: Consider partitioning payment_methods table by user_id if table grows very large
2. **Archival**: Implement archival strategy for inactive payment methods
3. **Caching**: Implement application-level caching for frequently accessed profiles

---

_This ERD is part of the Basic Profile Data feature (1.2.1) and represents the implemented database schema in Supabase._
