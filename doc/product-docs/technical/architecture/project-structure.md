---
id: PD-ARC-002
type: Product Documentation
category: Architecture
version: 1.0
created: 2023-06-15
updated: 2025-06-13
---

# Breakout Buddies - Project Structure

This document outlines the directory structure and organization of the BreakoutBuddies Flutter application. It provides a comprehensive overview of how the codebase is organized, both at a high level and for specific features.

## Core Directories

```
lib/
├── main.dart                  # App entry point
├── app/                       # App-wide configurations
│   ├── app_router.dart        # Centralized routing
│   ├── app_theme.dart         # Theme configuration
│   ├── app_providers.dart     # Provider setup
│   └── app_config.dart        # Environment-specific config
├── constants/                 # App-wide constants
│   ├── env.dart               # Environment variables
│   ├── api_paths.dart         # API endpoints
│   ├── app_colors.dart        # Color constants
│   ├── app_strings.dart       # String constants
│   └── app_dimensions.dart    # Size constants
├── models/                    # Data models
│   ├── user/                  # User-related models
│   ├── escape_room/           # Escape room models
│   ├── booking/               # Booking models
│   ├── review/                # Review models
│   ├── payment/               # Payment models
│   ├── achievement/           # Achievement models
│   ├── provider/              # Provider models
│   ├── voucher/               # Voucher models
│   ├── credit/                # Credit system models
│   ├── affiliate/             # Affiliate program models
│   ├── support/               # Support system models
│   └── emergency/             # Emergency contact models
├── services/                  # Business logic & API services
│   ├── auth/                  # Authentication services
│   ├── user/                  # User profile services
│   ├── escape_room/           # Escape room services
│   ├── booking/               # Booking services
│   ├── payment/               # Payment services
│   ├── review/                # Review services
│   ├── gamification/          # Gamification services
│   ├── provider/              # Provider services
│   ├── recommendation/        # AI recommendation services
│   ├── map/                   # Map integration services
│   ├── calendar/              # Calendar integration services
│   ├── analytics/             # Analytics services
│   ├── voucher/               # Voucher management services
│   ├── credit/                # Credit system services
│   ├── affiliate/             # Affiliate program services
│   ├── support/               # Support system services
│   ├── emergency/             # Emergency contact services
│   ├── admin/                 # Admin & moderation services
│   └── integrations/          # Third-party integrations
│       ├── bookeo/            # Bookeo API integration
│       ├── resova/            # Resova API integration
│       ├── xola/              # Xola API integration
│       ├── simplybook/        # SimplyBook.me integration
│       ├── google_maps/       # Google Maps API
│       ├── apple_maps/        # Apple Maps API
│       ├── google_calendar/   # Google Calendar API
│       ├── apple_calendar/    # Apple Calendar API
│       └── social_auth/       # Social authentication
├── repositories/              # Data repositories
│   ├── user_repository.dart
│   ├── escape_room_repository.dart
│   ├── booking_repository.dart
│   ├── review_repository.dart
│   ├── payment_repository.dart
│   ├── provider_repository.dart
│   ├── voucher_repository.dart
│   ├── credit_repository.dart
│   ├── affiliate_repository.dart
│   ├── support_repository.dart
│   ├── emergency_repository.dart
│   └── admin_repository.dart
├── screens/                   # UI screens
│   ├── auth/                  # Authentication screens
│   ├── user/                  # User profile screens
│   ├── escape_room/           # Escape room screens
│   ├── booking/               # Booking screens
│   ├── payment/               # Payment screens
│   ├── review/                # Review screens
│   ├── community/             # Community & forum screens
│   ├── provider/              # Provider portal screens
│   ├── map/                   # Map screens
│   ├── settings/              # Settings screens
│   ├── voucher/               # Voucher screens
│   ├── credit/                # Credit management screens
│   ├── affiliate/             # Affiliate program screens
│   ├── support/               # Support screens
│   ├── emergency/             # Emergency contact screens
│   └── admin/                 # Admin panel screens
├── widgets/                   # Reusable widgets
│   ├── common/                # Common widgets
│   ├── auth/                  # Auth-related widgets
│   ├── user/                  # User-related widgets
│   ├── escape_room/           # Escape room widgets
│   ├── booking/               # Booking widgets
│   ├── payment/               # Payment widgets
│   ├── review/                # Review widgets
│   ├── community/             # Community widgets
│   ├── provider/              # Provider widgets
│   ├── map/                   # Map widgets
│   ├── voucher/               # Voucher widgets
│   ├── credit/                # Credit system widgets
│   ├── affiliate/             # Affiliate program widgets
│   ├── support/               # Support widgets
│   ├── emergency/             # Emergency contact widgets
│   └── admin/                 # Admin panel widgets
├── utils/                     # Utility functions
│   ├── validators.dart        # Form validation
│   ├── formatters.dart        # Data formatting
│   ├── extensions/            # Extension methods
│   ├── helpers/               # Helper functions
│   ├── analytics_helper.dart  # Analytics helper
│   ├── qr_code_helper.dart    # QR code generation
│   ├── encryption_helper.dart # Data encryption utilities
│   └── localization_helper.dart # Localization utilities
└── state/                     # State management
    ├── providers/             # Riverpod providers
    ├── notifiers/             # State notifiers
    └── states/                # State classes
```

## Other Top-Level Directories

```
android/                     # Android native project files
build/                       # Build output directory
data/                        # Data files and database schemas
doc/                         # Documentation source files
docker/                      # Docker configuration files
docs/                        # Generated documentation and reports
env/                         # Environment configuration files
integration_test/            # Integration tests
ios/                         # iOS native project files
link_fix_backups/            # Backup files for link fixes
node_modules/                # Node.js dependencies
scripts/                     # Project scripts and utilities
supabase/                    # Supabase backend configuration
test/                        # Unit and widget tests
web/                         # Web platform files
```

## Feature-Specific Structure

### 1. User Accounts & Authentication

#### Features

**Registration & Login:**
- 🟡 Email + password registration (In Progress)
- 📝 Social login integration (TDD Created)
- ⬜ Email validation & confirmation (Not Started)
- 📝 Password reset functionality (TDD Created)

**User Profile:**
- ⬜ Basic profile data (name, picture, location) (Not Started)
- ⬜ User level & status system (Not Started)
- ⬜ Friends management (Not Started)
- ⬜ Gallery of completed rooms (Not Started)
- ⬜ Sharing options (Not Started)
- ⬜ Personal statistics & achievements (Not Started)

```
lib/
├── models/user/
│   ├── user_model.dart
│   ├── user_profile_model.dart
│   ├── user_stats_model.dart
│   └── friend_model.dart
├── services/auth/
│   ├── auth_service.dart
│   ├── social_auth_service.dart
│   └── password_reset_service.dart
├── services/user/
│   ├── user_profile_service.dart
│   ├── friends_service.dart
│   └── user_gallery_service.dart
├── screens/auth/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── forgot_password_screen.dart
│   └── email_verification_screen.dart
├── screens/user/
│   ├── profile_screen.dart
│   ├── edit_profile_screen.dart
│   ├── friends_screen.dart
│   ├── gallery_screen.dart
│   └── achievements_screen.dart
├── widgets/auth/
│   ├── login_form.dart
│   ├── register_form.dart
│   └── social_login_buttons.dart
└── widgets/user/
    ├── profile_header.dart
    ├── stats_card.dart
    ├── friends_list.dart
    ├── gallery_grid.dart
    └── achievement_card.dart
```

### 2. User Experience & Community

#### Features

**Gamification:**
- ⬜ Points & leveling system (Not Started)
- ⬜ Badges / achievements (Not Started)
- ⬜ Credits system for achievements (Not Started)
- ⬜ Leaderboards (global, national, friends) (Not Started)
- ⬜ Monthly challenges (Not Started)
- 📝 Design unlocks through progression (TDD Created)

**Forum & Reviews:**
- ⬜ Forum posts with image upload (Not Started)
- ⬜ Structured review system (Not Started)
- ⬜ Expert review highlighting (Not Started)
- ⬜ Review reminder emails (Not Started)

```
lib/
├── models/achievement/
│   ├── achievement_model.dart
│   ├── badge_model.dart
│   └── leaderboard_model.dart
├── models/review/
│   ├── review_model.dart
│   └── forum_post_model.dart
├── services/gamification/
│   ├── points_service.dart
│   ├── achievements_service.dart
│   ├── badges_service.dart
│   └── leaderboard_service.dart
├── services/review/
│   ├── review_service.dart
│   ├── forum_service.dart
│   └── review_reminder_service.dart
├── screens/community/
│   ├── forum_screen.dart
│   ├── create_post_screen.dart
│   ├── post_detail_screen.dart
│   ├── leaderboard_screen.dart
│   └── challenges_screen.dart
├── screens/review/
│   ├── create_review_screen.dart
│   ├── review_detail_screen.dart
│   └── my_reviews_screen.dart
└── widgets/community/
    ├── forum_post_card.dart
    ├── review_card.dart
    ├── leaderboard_item.dart
    ├── badge_display.dart
    └── challenge_card.dart
```

### 3. Search & Navigation

#### Features

**Filter Options:**
- ⬜ Difficulty filters (Not Started)
- ⬜ Group size filters (Not Started)
- ⬜ Age restriction filters (Not Started)
- ⬜ Location/radius search (Not Started)
- ⬜ Scare level filters (Not Started)
- ⬜ Date & time range filters (Not Started)
- ⬜ Price filters (Not Started)
- ⬜ Type filters (VR/urban/local) (Not Started)
- ⬜ Duration filters (Not Started)
- ⬜ Success rate filters (Not Started)
- ⬜ Language filters (Not Started)
- ⬜ Review-based filters (Not Started)
- ⬜ Theme/category filters (Not Started)
- ⬜ Release date filters (Not Started)

**Map Integration:**
- ⬜ Google Maps integration (Not Started)
- ⬜ Apple Maps integration (Not Started)
- ⬜ Location-based search (Not Started)

```
lib/
├── models/escape_room/
│   ├── escape_room_model.dart
│   ├── room_category_model.dart
│   └── search_filter_model.dart
├── services/escape_room/
│   ├── escape_room_service.dart
│   ├── search_service.dart
│   └── filter_service.dart
├── services/map/
│   ├── map_service.dart
│   ├── google_maps_service.dart
│   └── apple_maps_service.dart
├── screens/escape_room/
│   ├── search_screen.dart
│   ├── filter_screen.dart
│   ├── room_list_screen.dart
│   ├── room_detail_screen.dart
│   └── category_screen.dart
├── screens/map/
│   ├── map_screen.dart
│   └── location_search_screen.dart
└── widgets/escape_room/
    ├── search_bar.dart
    ├── filter_panel.dart
    ├── room_card.dart
    ├── category_card.dart
    └── difficulty_indicator.dart
```

### 4. Booking & Checkout

#### Features

**Booking Process:**
- ⬜ Time slot selection (Not Started)
- ⬜ In-app booking (Not Started)
- ⬜ Calendar export (Google, Apple) (Not Started)
- ⬜ Last-minute deals (Not Started)
- ⬜ Joinable open slots (Not Started)
- ⬜ Group booking with friends (Not Started)
- ⬜ Coupon application (Not Started)
- ⬜ Display of restrictions (min participants, age) (Not Started)

**Group Planning Assistant:**
- ⬜ Chat-like planning tool (Not Started)
- ⬜ Poll feature for date coordination (Not Started)
- ⬜ Group chat integration (Not Started)

**Payment Methods:**
- ⬜ Credit card integration (Not Started)
- ⬜ PayPal integration (Not Started)
- ⬜ TWINT integration (Not Started)
- ⬜ Apple Pay / Google Pay integration (Not Started)
- ⬜ Credit balance usage (Not Started)
- ⬜ Split payment functionality (Not Started)

```
lib/
├── models/booking/
│   ├── booking_model.dart
│   ├── time_slot_model.dart
│   ├── group_booking_model.dart
│   └── coupon_model.dart
├── models/payment/
│   ├── payment_model.dart
│   ├── payment_method_model.dart
│   └── split_payment_model.dart
├── services/booking/
│   ├── booking_service.dart
│   ├── time_slot_service.dart
│   ├── group_planning_service.dart
│   └── calendar_export_service.dart
├── services/payment/
│   ├── payment_service.dart
│   ├── payment_method_service.dart
│   └── split_payment_service.dart
├── screens/booking/
│   ├── booking_screen.dart
│   ├── time_slot_selection_screen.dart
│   ├── group_planning_screen.dart
│   ├── booking_confirmation_screen.dart
│   └── my_bookings_screen.dart
├── screens/payment/
│   ├── payment_screen.dart
│   ├── payment_method_screen.dart
│   ├── split_payment_screen.dart
│   └── payment_confirmation_screen.dart
└── widgets/booking/
    ├── time_slot_picker.dart
    ├── group_planner.dart
    ├── coupon_input.dart
    ├── booking_summary.dart
    └── calendar_export_button.dart
```

### 5. Monetization & Affiliation

#### Features

**Revenue Model:**
- ⬜ Booking fee implementation (Not Started)
- ⬜ Margin-based visibility system (Not Started)
- ⬜ Premium placements for providers (Not Started)

**Affiliate & Referral Program:**
- ⬜ User referral system (Not Started)
- ⬜ Provider referral system (Not Started)
- ⬜ QR code generation for onboarding (Not Started)

```
lib/
├── models/affiliate/
│   ├── affiliate_model.dart
│   ├── referral_model.dart
│   └── qr_code_model.dart
├── models/credit/
│   └── credit_model.dart
├── services/affiliate/
│   ├── affiliate_service.dart
│   ├── referral_service.dart
│   └── qr_code_service.dart
├── services/credit/
│   └── credit_service.dart
├── screens/affiliate/
│   ├── affiliate_dashboard_screen.dart
│   └── referral_screen.dart
├── screens/credit/
│   └── credit_history_screen.dart
├── widgets/affiliate/
│   ├── affiliate_stats_card.dart
│   ├── referral_code_card.dart
│   └── qr_code_generator.dart
└── widgets/credit/
    └── credit_balance_card.dart
```

### 6. Provider Portal

#### Features

**Account & Room Management:**
- ⬜ Manual room creation (Not Started)
- ⬜ Automatic room import (OpenAI API) (Not Started)
- ⬜ Image/video upload (Not Started)
- ⬜ Booking tool connection (Not Started)
- ⬜ Slot/price/discount management (Not Started)
- ⬜ Emergency contact & support (Not Started)
- ⬜ Group photo upload to user galleries (Not Started)

**Provider Statistics:**
- ⬜ Revenue tracking (Not Started)
- ⬜ Customer return rate analysis (Not Started)
- ⬜ Room popularity metrics (Not Started)
- ⬜ Feedback analysis (Not Started)

**Review Management:**
- ⬜ Quick reply templates (Not Started)
- ⬜ AI suggestions for replies (Not Started)
- ⬜ Negative review alerts (Not Started)

```
lib/
├── models/provider/
│   ├── provider_model.dart
│   ├── provider_room_model.dart
│   └── provider_stats_model.dart
├── services/provider/
│   ├── provider_service.dart
│   ├── room_management_service.dart
│   ├── provider_stats_service.dart
│   └── review_management_service.dart
├── screens/provider/
│   ├── provider_dashboard_screen.dart
│   ├── room_management_screen.dart
│   ├── create_room_screen.dart
│   ├── edit_room_screen.dart
│   ├── provider_stats_screen.dart
│   └── review_management_screen.dart
└── widgets/provider/
    ├── provider_stats_card.dart
    ├── room_management_card.dart
    ├── review_response_card.dart
    └── ai_suggestion_card.dart
```

### 7. Interfaces & Backend

#### Features

**Booking Systems (API Integration):**
- ⬜ Bookeo integration (Not Started)
- ⬜ Resova integration (Not Started)
- ⬜ Xola integration (Not Started)
- ⬜ SimplyBook.me integration (Not Started)
- ⬜ Other booking systems integration (Not Started)

**Calendar:**
- ⬜ iCal integration (Not Started)
- ⬜ Google Calendar integration (Not Started)
- ⬜ Apple Calendar integration (Not Started)

**Maps:**
- ⬜ Google Maps API integration (Not Started)
- ⬜ Apple Maps API integration (Not Started)
- ⬜ Location request handling (Not Started)

```
lib/
├── services/booking/
│   ├── booking_api_service.dart
│   ├── bookeo_service.dart
│   ├── resova_service.dart
│   ├── xola_service.dart
│   └── simplybook_service.dart
├── services/calendar/
│   ├── calendar_service.dart
│   ├── ical_service.dart
│   ├── google_calendar_service.dart
│   └── apple_calendar_service.dart
└── services/map/
    ├── google_maps_api_service.dart
    ├── apple_maps_api_service.dart
    └── location_service.dart
```

### 8. Recommendation Engine (AI)

#### Features

**For End Users:**
- ⬜ Gameplay behavior-based recommendations (Not Started)
- ⬜ Review-based recommendations (Not Started)
- ⬜ Category preference-based recommendations (Not Started)
- ⬜ Location-based recommendations (Not Started)

**For Providers:**
- ⬜ Improvement suggestions based on reviews (Not Started)
- ⬜ Improvement suggestions based on success rates (Not Started)
- ⬜ Improvement suggestions based on demand patterns (Not Started)

```
lib/
├── services/recommendation/
│   ├── user_recommendation_service.dart
│   ├── provider_recommendation_service.dart
│   └── ai_service.dart
├── screens/escape_room/
│   └── recommended_rooms_screen.dart
└── widgets/escape_room/
    └── recommendation_card.dart
```

### 9. Vouchers & Credit

#### Features

- ⬜ Voucher purchase system (Not Started)
- ⬜ Voucher redemption system (Not Started)
- ⬜ Credit usage during checkout (Not Started)
- ⬜ Affiliate rewards credit system (Not Started)

```
lib/
├── models/voucher/
│   └── voucher_model.dart
├── models/credit/
│   └── credit_transaction_model.dart
├── services/voucher/
│   └── voucher_service.dart
├── services/credit/
│   └── credit_transaction_service.dart
├── screens/voucher/
│   ├── voucher_screen.dart
│   ├── purchase_voucher_screen.dart
│   └── redeem_voucher_screen.dart
├── widgets/voucher/
│   └── voucher_card.dart
└── widgets/credit/
    └── credit_transaction_card.dart
```

### 10. Technical & Legal Requirements

#### Features

**Frontend:**
- ⬜ Web app optimization (Not Started)
- ⬜ Mobile optimization (Not Started)
- ⬜ Multilingual support (DE, EN, FR, IT) (Not Started)
- ⬜ Responsive design (Not Started)
- ⬜ Provider/user role distinction (Not Started)
- 📝 Loading state informational content (TDD Created)

**Backend & Admin:**
- ⬜ Provider account activation (Not Started)
- ⬜ Active room monitoring (Not Started)
- ⬜ Review moderation (Not Started)
- ⬜ GDPR compliance (Not Started)

**App as Progressive Web App (PWA):**
- ⬜ PWA configuration (Not Started)

```
lib/
├── app/
│   ├── localization/
│   │   ├── app_localizations.dart
│   │   ├── en_strings.dart
│   │   ├── de_strings.dart
│   │   ├── fr_strings.dart
│   │   └── it_strings.dart
│   └── pwa/
│       └── pwa_config.dart
├── services/
│   └── admin/
│       ├── moderation_service.dart
│       ├── monitoring_service.dart
│       └── gdpr_service.dart
└── screens/settings/
    ├── language_settings_screen.dart
    ├── privacy_settings_screen.dart
    └── data_deletion_screen.dart
```

### 11. Support & Emergencies

#### Features

- ⬜ Support form for users (Not Started)
- ⬜ Support form for providers (Not Started)
- ⬜ Emergency contact system (Not Started)
- ⬜ Emergency protocols (Not Started)
- ⬜ FAQ section (Not Started)
- ⬜ Optional AI-powered support (Not Started)

```
lib/
├── services/support/
│   ├── support_service.dart
│   ├── emergency_service.dart
│   └── faq_service.dart
├── screens/support/
│   ├── support_screen.dart
│   ├── faq_screen.dart
│   └── emergency_contact_screen.dart
└── widgets/support/
    ├── support_form.dart
    ├── faq_item.dart
    └── emergency_contact_card.dart
```

## Architecture Principles

The project structure follows these key architectural principles:

1. **Feature-based organization**: Code is organized by feature to improve maintainability and discoverability.
2. **Separation of concerns**: UI, business logic, and data access are kept separate.
3. **Dependency injection**: Services and repositories are injected where needed using Riverpod.
4. **Reusable components**: Common widgets and utilities are shared across features.
5. **Consistent naming**: Files and directories follow consistent naming conventions.

## Related Documentation

- [Product: ADR-0001: State Management with Riverpod](design-docs/adr/adr/adr-001-state-management-with-riverpod.md)
- [Product: ADR-0002: Backend Services with Supabase](design-docs/adr/adr/adr-002-backend-services-with-supabase.md)

---

*This document is part of the Product Documentation and provides an overview of the BreakoutBuddies project structure.*
