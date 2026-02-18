---
id: PD-API-015
type: Process Framework
category: API Data Models Registry
version: 1.1
created: 2025-08-25
updated: 2025-01-27
---

# API Data Models Registry

## Purpose

This registry provides a centralized index of all API data models in the BreakoutBuddies project, enabling:

- **Discoverability**: Find existing models before creating new ones
- **Reusability**: Identify models that can be shared across features
- **Maintenance**: Track all data model dependencies and relationships
- **Documentation**: Ensure no data models are orphaned or forgotten

## How to Use This Registry

### For Feature Development

1. **Before creating new models**: Check this registry to see if suitable models already exist
2. **When implementing features**: Reference related models to understand data relationships
3. **During API design**: Use this registry to maintain consistency across endpoints

### For Maintenance

1. **When updating models**: Check "Used By Features" to understand impact
2. **During refactoring**: Use relationships to identify cascading changes
3. **For documentation reviews**: Ensure all models are properly linked and current

## Data Models Index

### Authentication & User Management

| Model Name                                                  | File                            | API Version | Used By Features       | Related Models                                                | Status      |
| ----------------------------------------------------------- | ------------------------------- | ----------- | ---------------------- | ------------------------------------------------------------- | ----------- |
| [User Registration Request](user-registration-request.md)   | `user-registration-request.md`  | v1          | 1.1.1                  | User Registration Response, User Profile                      | ✅ Complete |
| [User Registration Response](user-registration-response.md) | `user-registration-response.md` | v1          | 1.1.1, 1.1.3 (planned) | User Registration Request, Authentication Token, User Profile | ✅ Complete |

### User Profile & Account Data

| Model Name           | File                                                                                         | API Version | Used By Features       | Related Models                             | Status      |
| -------------------- | -------------------------------------------------------------------------------------------- | ----------- | ---------------------- | ------------------------------------------ | ----------- |
| User Profile         | [PD-API-011](../specifications/specifications/api-1.2.1-basic-profile-data.md#userprofile)   | v1          | 1.2.1                  | User Registration Response, Payment Method | ✅ Complete |
| Payment Method       | [PD-API-011](../specifications/specifications/api-1.2.1-basic-profile-data.md#paymentmethod) | v1          | 1.2.1, 4.2.1 (planned) | User Profile, Booking Response             | ✅ Complete |
| Authentication Token | `authentication-token.md`                                                                    | v1          | 1.1.1, 1.1.2, 1.1.4    | User Registration Response                 | 🔄 Planned  |

### Escape Room Data

| Model Name  | File             | API Version | Used By Features       | Related Models                     | Status     |
| ----------- | ---------------- | ----------- | ---------------------- | ---------------------------------- | ---------- |
| Escape Room | `escape-room.md` | v1          | 3.1.1, 3.2.1 (planned) | Provider, Category, Search Filters | 🔄 Planned |
| Provider    | `provider.md`    | v1          | 6.1.1 (planned)        | Escape Room                        | 🔄 Planned |
| Category    | `category.md`    | v1          | 3.1.1 (planned)        | Escape Room                        | 🔄 Planned |

### Search & Discovery

| Model Name     | File                | API Version | Used By Features       | Related Models              | Status     |
| -------------- | ------------------- | ----------- | ---------------------- | --------------------------- | ---------- |
| Search Filters | `search-filters.md` | v1          | 3.1.1, 3.2.1 (planned) | Escape Room, Category       | 🔄 Planned |
| Search Results | `search-results.md` | v1          | 3.1.1 (planned)        | Escape Room, Search Filters | 🔄 Planned |

### Booking & Payments

| Model Name       | File                                                                                         | API Version | Used By Features       | Related Models                            | Status      |
| ---------------- | -------------------------------------------------------------------------------------------- | ----------- | ---------------------- | ----------------------------------------- | ----------- |
| Booking Request  | `booking-request.md`                                                                         | v1          | 4.1.1 (planned)        | Escape Room, User Profile, Payment Method | 🔄 Planned  |
| Booking Response | `booking-response.md`                                                                        | v1          | 4.1.1 (planned)        | Booking Request, Payment Method           | 🔄 Planned  |
| Payment Method   | [PD-API-011](../specifications/specifications/api-1.2.1-basic-profile-data.md#paymentmethod) | v1          | 1.2.1, 4.2.1 (planned) | User Profile, Booking Response            | ✅ Complete |

## Model Relationships Map

```
User Registration Request ──→ User Registration Response
                                      │
                                      ├──→ Authentication Token
                                      └──→ User Profile
                                              │
                                              ├──→ Payment Method ──→ Booking Response
                                              │
                                              └──→ Booking Request ──→ Booking Response
                                                                           │
                                                                           └──→ Payment Method

Escape Room ←──→ Provider
     │
     ├──→ Category
     ├──→ Search Filters ──→ Search Results
     └──→ Booking Request
```

## Status Legend

| Symbol | Status       | Description                                 |
| ------ | ------------ | ------------------------------------------- |
| ✅     | Complete     | Model is fully documented and ready for use |
| 🔄     | Planned      | Model is identified but not yet created     |
| 🟡     | In Progress  | Model is being developed                    |
| 🔄     | Needs Update | Model exists but requires updates           |
| ❌     | Deprecated   | Model is no longer used                     |

## Reusability Guidelines

### High Reusability Models

These models are designed to be shared across multiple features:

- **User Registration Response**: Used by login, registration, and profile features
- **Authentication Token**: Used by all authenticated endpoints
- **User Profile**: Referenced by social features, bookings, and preferences (Feature 1.2.1)
- **Payment Method**: Used by profile management and booking/payment flows (Feature 1.2.1, 4.2.1)

### Feature-Specific Models

These models are typically used by single features:

- **User Registration Request**: Specific to registration flow
- **Search Filters**: Specific to search functionality
- **Booking Request**: Specific to booking flow

### When to Create New vs. Reuse

- **Reuse existing models** when:
  - Data structure is identical or very similar (>80% overlap)
  - Validation rules are compatible
  - API version matches
- **Create new models** when:
  - Data structure differs significantly
  - Different validation requirements
  - Different API version needed

## Maintenance Procedures

### Adding New Models

1. Create the model document using the standard template
2. Add entry to appropriate section in this registry
3. Update the relationships map if applicable
4. Link from relevant feature tracking entries

### Updating Existing Models

1. Update the model document
2. Check "Used By Features" column for impact assessment
3. Update related models if necessary
4. Update version number and changelog

### Deprecating Models

1. Mark status as ❌ Deprecated
2. Add deprecation notice to model document
3. Update all referencing features
4. Plan migration timeline

## Related Documentation

- [API Specifications Registry](../specifications/README.md): Index of all API endpoint specifications
- [Feature Tracking](../../../../process-framework/state-tracking/permanent/feature-tracking.md): Main feature implementation tracking
- [API Design Guide](../../../../process-framework/guides/guides/api-design-guide.md): Guidelines for API design consistency

---

**Last Updated**: 2025-10-16
**Next Review**: When new user profile or payment features are planned
**Maintainer**: Development Team

## Changelog

### 2025-10-16

- Added User Profile model from Feature 1.2.1 (PD-API-011)
- Added Payment Method model from Feature 1.2.1 (PD-API-011)
- Updated model relationships map to include Payment Method
- Updated high reusability models section

### 2025-08-25

- Initial registry creation
- Added User Registration models from Feature 1.1.1
