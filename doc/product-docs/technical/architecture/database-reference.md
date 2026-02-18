---
id: PD-ARC-001
type: Product Documentation
category: Architecture
version: 1.0
created: 2023-06-15
updated: 2023-06-15
---

# Breakout Buddies Database Reference Guide

## Database Overview

Breakout Buddies uses a PostgreSQL database through Supabase with the following key characteristics:
- Relational database structure with well-defined relationships
- Row-level security for data protection
- Optimized for escape room booking application needs

## Core Tables

### Users (`users`)
- Primary user account information
- Profile data, preferences, and gamification stats
- Key fields: `id`, `email`, `display_name`, `level`, `points`, `is_provider`

### Escape Rooms (`escape_rooms`)
- Escape room listings and details
- Key fields: `id`, `provider_id`, `name`, `difficulty`, `min_players`, `max_players`, `price_per_person`, `location`
- Geographic data for location-based searches

### Bookings (`bookings`)
- Reservation information
- Key fields: `id`, `user_id`, `room_id`, `booking_date`, `start_time`, `status`, `total_price`
- Tracks booking lifecycle from creation to completion

### Reviews (`reviews`)
- User feedback on escape rooms
- Key fields: `id`, `user_id`, `room_id`, `rating`, `content`, `is_verified`
- Supports provider responses

### Providers (`providers`)
- Escape room business information
- Key fields: `id`, `user_id`, `company_name`, `booking_system_type`, `commission_rate`
- Links to user accounts with provider privileges

## Supporting Tables

### Categories & Room Categories
- Escape room themes and categories
- Many-to-many relationship between rooms and categories

### Time Slots
- Available booking times for escape rooms
- Supports pricing variations and availability management

### Achievements & User Achievements
- Gamification system components
- Tracks user progress and earned achievements

### Payments & Vouchers
- Financial transaction records
- Discount and promotion management

### Forum Posts & Comments
- Community discussion features
- User-generated content management

### User Friends & Group Bookings
- Social features and group coordination
- Supports collaborative booking planning

## Key Relationships

### One-to-Many
- User → Bookings, Reviews, Forum Posts
- Provider → Escape Rooms
- Escape Room → Media, Time Slots, Bookings, Reviews

### Many-to-Many
- Escape Rooms ↔ Categories
- Users ↔ Achievements
- Users ↔ Users (Friends)
- Group Bookings ↔ Users

## Security Implementation

- Row-level security policies restrict data access
- Sensitive data is encrypted (payment details, API keys)
- Authentication through Supabase Auth
- Regular backups with point-in-time recovery

## Performance Optimizations

- Strategic indexing on frequently queried fields
- Denormalization for performance-critical queries
- Pagination for large result sets
- Caching for frequently accessed data

## Common Query Patterns

### User Authentication & Profiles
- Retrieve user profile with achievements and stats
- Update user preferences and profile information

### Escape Room Discovery
- Search rooms by location, difficulty, availability
- Filter by multiple criteria (price, theme, group size)
- Sort by rating, popularity, or proximity

### Booking Management
- Check availability for specific dates/times
- Create and manage bookings
- Process payments and apply discounts

### Social & Community
- Friend management and group coordination
- Review submission and management
- Forum participation and content moderation

## Database Evolution

- Schema versioning tracks database changes
- Migration scripts handle schema updates
- Testing in staging environment before production deployment
- Regular performance reviews and optimization

## Detailed Table Definitions

### Users
```
users
├── id (UUID, PK)
├── email (String)
├── created_at (Timestamp)
├── updated_at (Timestamp)
├── display_name (String)
├── avatar_url (String)
├── location (String)
├── bio (Text)
├── preferences (JSONB)
├── level (Integer)
├── points (Integer)
├── is_provider (Boolean)
└── last_login (Timestamp)
```

### Escape Rooms
```
escape_rooms
├── id (UUID, PK)
├── provider_id (UUID, FK)
├── name (String)
├── description (Text)
├── short_description (String)
├── difficulty (Integer)
├── min_players (Integer)
├── max_players (Integer)
├── duration_minutes (Integer)
├── price_per_person (Decimal)
├── min_age (Integer)
├── scare_level (Integer)
├── success_rate (Decimal)
├── is_virtual (Boolean)
├── is_active (Boolean)
├── created_at (Timestamp)
├── updated_at (Timestamp)
├── location (Geography)
├── address (String)
├── city (String)
├── postal_code (String)
├── country (String)
├── languages (Array[String])
├── theme (String)
├── release_date (Date)
├── booking_url (String)
└── booking_system (String)
```

### Bookings
```
bookings
├── id (UUID, PK)
├── user_id (UUID, FK)
├── room_id (UUID, FK)
├── booking_date (Date)
├── start_time (Time)
├── end_time (Time)
├── num_players (Integer)
├── total_price (Decimal)
├── status (String)
├── created_at (Timestamp)
├── updated_at (Timestamp)
├── booking_reference (String)
├── notes (Text)
├── is_group_booking (Boolean)
├── payment_status (String)
├── coupon_code (String)
└── discount_amount (Decimal)
```

### Reviews
```
reviews
├── id (UUID, PK)
├── user_id (UUID, FK)
├── room_id (UUID, FK)
├── booking_id (UUID, FK)
├── rating (Integer)
├── content (Text)
├── created_at (Timestamp)
├── updated_at (Timestamp)
├── is_verified (Boolean)
├── is_expert (Boolean)
├── helpful_count (Integer)
├── provider_response (Text)
└── provider_response_date (Timestamp)
```

### Providers
```
providers
├── id (UUID, PK)
├── user_id (UUID, FK)
├── company_name (String)
├── description (Text)
├── logo_url (String)
├── website (String)
├── contact_email (String)
├── contact_phone (String)
├── address (String)
├── city (String)
├── postal_code (String)
├── country (String)
├── is_verified (Boolean)
├── created_at (Timestamp)
├── updated_at (Timestamp)
├── booking_system_type (String)
├── booking_system_api_key (String, Encrypted)
├── commission_rate (Decimal)
└── payment_details (JSONB, Encrypted)
```

---

*This reference guide provides a comprehensive overview of the Breakout Buddies database structure. For implementation questions, refer to the specific table definitions and relationships outlined above.*
