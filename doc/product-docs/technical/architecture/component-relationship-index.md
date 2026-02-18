---
id: PD-ARC-003
type: Product Documentation
category: Architecture
version: 1.0
created: 2025-07-13
updated: 2025-07-13
---

# Component Relationship Index

This document provides a comprehensive overview of how components in the Breakout Buddies Flutter application interact with each other. It serves as a navigation guide for developers to understand dependencies, data flow, and architectural relationships.

## 📋 Quick Navigation

- [Core Architecture](#core-architecture)
- [Layer Dependencies](#layer-dependencies)
- [Feature Component Maps](#feature-component-maps)
- [Cross-Cutting Concerns](#cross-cutting-concerns)
- [External Dependencies](#external-dependencies)
- [Data Flow Patterns](#data-flow-patterns)

## Core Architecture

### 🏗️ Architectural Layers

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Screens   │  │   Widgets   │  │   Themes    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    State Management                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Providers  │  │  Notifiers  │  │   States    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Services   │  │ Repositories│  │   Models    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Supabase   │  │ Local Cache │  │ External APIs│       │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## Layer Dependencies

### 🔄 Dependency Flow

| Layer | Depends On | Provides To | Key Components |
|-------|------------|-------------|----------------|
| **UI Layer** | State Management, Utils | User Interface | `screens/`, `widgets/` |
| **State Management** | Business Logic, Models | UI Layer | `state/providers/`, `state/notifiers/` |
| **Business Logic** | Data Layer, Models | State Management | `services/`, `repositories/` |
| **Data Layer** | External APIs | Business Logic | `SupabaseService`, API clients |

### 📦 Core Components

#### Configuration & Setup
```
main.dart
├── ConfigManager (config/)
│   ├── DevConfig
│   ├── TestConfig
│   └── ProdConfig
├── SupabaseService (services/)
├── GoRouter (routing)
└── ProviderScope (Riverpod)
```

#### Authentication Flow
```
AuthenticationFlow
├── LoginScreen (screens/auth/)
│   ├── SupabaseService.signInWithEmailAndPassword()
│   └── GoRouter.go('/dashboard')
├── RegisterScreen (screens/auth/)
│   ├── SupabaseService.signUpWithEmailAndPassword()
│   └── EmailVerificationScreen
├── ForgotPasswordScreen (screens/auth/)
│   └── SupabaseService.resetPassword()
└── DevLoginScreen (screens/auth/) [Development Only]
```

## Feature Component Maps

### 🔐 Authentication Components

#### Current Implementation
```
Authentication System
├── Services
│   ├── SupabaseService (lib/services/supabase_service.dart)
│   │   ├── signInWithEmailAndPassword()
│   │   ├── signUpWithEmailAndPassword()
│   │   ├── signOut()
│   │   └── resetPassword()
│   └── AuthProvider (lib/services/auth_provider.dart) [Riverpod]
├── Screens
│   ├── LoginScreen (lib/screens/auth/login_screen.dart)
│   ├── RegisterScreen (lib/screens/auth/register_screen.dart)
│   ├── ForgotPasswordScreen (lib/screens/auth/forgot_password_screen.dart)
│   └── DevLoginScreen (lib/screens/auth/dev_login_screen.dart)
├── Models
│   └── [To be implemented: User, AuthState models]
└── Widgets
    └── [To be implemented: Auth form widgets]
```

#### Planned Extensions
```
Future Authentication Features
├── Social Authentication
│   ├── GoogleAuthService
│   ├── AppleAuthService
│   └── FacebookAuthService
├── Email Verification
│   ├── EmailVerificationScreen
│   └── EmailVerificationService
└── Two-Factor Authentication
    ├── TwoFactorScreen
    └── TwoFactorService
```

### 🏠 Navigation & Routing

#### Current Router Configuration
```
GoRouter Configuration
├── Routes
│   ├── '/' → HomeScreen
│   ├── '/login' → LoginScreen
│   ├── '/register' → RegisterScreen
│   ├── '/forgot-password' → ForgotPasswordScreen
│   ├── '/dashboard' → DashboardScreen
│   └── '/dev-login' → DevLoginScreen [Development Only]
├── Guards
│   └── [To be implemented: Authentication guards]
└── Middleware
    └── [To be implemented: Route middleware]
```

### 🎯 Core Services Architecture

#### Data Services
```
Data Services Layer
├── SupabaseService (Primary Backend)
│   ├── Authentication Methods
│   ├── Generic CRUD Operations
│   │   ├── fetchData()
│   │   ├── insertData()
│   │   ├── updateData()
│   │   └── deleteData()
│   └── Real-time Subscriptions
├── Repository Pattern [Planned]
│   ├── UserRepository
│   ├── EscapeRoomRepository
│   ├── BookingRepository
│   └── ReviewRepository
└── Cache Layer [Planned]
    ├── LocalStorageService
    └── CacheManager
```

### 🎨 UI Component Hierarchy

#### Screen Structure
```
Screen Components
├── HomeScreen (lib/screens/home_screen.dart)
├── DashboardScreen (lib/screens/dashboard_screen.dart)
└── Auth Screens
    ├── LoginScreen
    │   ├── Form Validation
    │   ├── Loading States
    │   └── Error Handling
    ├── RegisterScreen
    │   ├── Form Validation
    │   ├── Password Strength
    │   └── Terms Acceptance
    └── ForgotPasswordScreen
        ├── Email Validation
        └── Success Confirmation
```

## Cross-Cutting Concerns

### 🔧 Utilities & Helpers

#### Current Utilities
```
Utils Layer
├── EnvironmentValidator (lib/utils/environment_validator.dart)
├── Constants
│   └── Environment Variables (lib/constants/env.dart)
└── Configuration
    ├── AppConfig (lib/config/app_config.dart)
    ├── ConfigManager (lib/config/config_manager.dart)
    ├── DevConfig (lib/config/dev_config.dart)
    ├── TestConfig (lib/config/test_config.dart)
    └── ProdConfig (lib/config/prod_config.dart)
```

#### Planned Utilities
```
Future Utilities
├── Validators (lib/utils/validators.dart)
├── Formatters (lib/utils/formatters.dart)
├── Extensions (lib/utils/extensions/)
├── Helpers (lib/utils/helpers/)
├── Analytics Helper (lib/utils/analytics_helper.dart)
├── QR Code Helper (lib/utils/qr_code_helper.dart)
├── Encryption Helper (lib/utils/encryption_helper.dart)
└── Localization Helper (lib/utils/localization_helper.dart)
```

### 🔄 State Management

#### Riverpod Architecture
```
State Management (Riverpod)
├── Providers (lib/state/providers/)
│   ├── AuthProvider
│   ├── UserProvider
│   ├── EscapeRoomProvider
│   └── BookingProvider
├── Notifiers (lib/state/notifiers/)
│   ├── AuthNotifier
│   ├── UserNotifier
│   └── BookingNotifier
└── States (lib/state/states/)
    ├── AuthState
    ├── UserState
    └── BookingState
```

## External Dependencies

### 📡 Backend Services

#### Supabase Integration
```
Supabase Services
├── Authentication
│   ├── Email/Password Auth
│   ├── Social Auth [Planned]
│   └── Session Management
├── Database
│   ├── User Profiles
│   ├── Escape Room Data
│   ├── Bookings
│   └── Reviews
├── Storage
│   ├── User Profile Images
│   ├── Room Images
│   └── Review Images
└── Real-time
    ├── Live Chat [Planned]
    ├── Booking Updates
    └── Notifications
```

#### Third-Party Integrations [Planned]
```
External APIs
├── Booking Systems
│   ├── Bookeo API
│   ├── Resova API
│   ├── Xola API
│   └── SimplyBook.me API
├── Maps & Location
│   ├── Google Maps API
│   └── Apple Maps API
├── Calendar Integration
│   ├── Google Calendar API
│   └── Apple Calendar API
├── Payment Processing
│   ├── Stripe
│   ├── PayPal
│   └── TWINT
└── Social Features
    ├── Google Auth
    ├── Apple Auth
    └── Facebook Auth
```

### 📱 Flutter Dependencies

#### Core Dependencies
```
Flutter Dependencies
├── State Management
│   └── flutter_riverpod: ^2.4.10
├── Routing
│   └── go_router: ^13.2.0
├── Backend
│   ├── supabase_flutter: ^2.8.4
│   └── supabase: ^2.6.3
├── UI Components
│   ├── flutter_svg: ^2.0.10+1
│   └── cached_network_image: ^3.3.1
├── Configuration
│   └── dotenv: ^4.2.0
└── Testing
    ├── mockito: ^5.4.4
    ├── build_runner: ^2.4.8
    ├── golden_toolkit: ^0.15.0
    └── riverpod_test: ^0.1.3
```

## Data Flow Patterns

### 🔄 Typical Data Flow

#### Authentication Flow
```
User Action → Screen → Service → Backend → Response
     ↓           ↓        ↓         ↓         ↓
1. Tap Login → LoginScreen → SupabaseService → Supabase → AuthResponse
2. Update UI ← StateNotifier ← Repository ← Service ← Response
3. Navigate → GoRouter.go('/dashboard')
```

#### CRUD Operations Flow
```
User Action → UI → State → Service → Repository → Backend
     ↓         ↓     ↓       ↓          ↓           ↓
1. Create → Form → Provider → Service → Repository → Supabase
2. Read → Screen → Provider → Service → Repository → Supabase
3. Update → Form → Provider → Service → Repository → Supabase
4. Delete → Action → Provider → Service → Repository → Supabase
```

### 📊 State Propagation

#### Riverpod State Flow
```
State Changes
├── User Input
│   └── Widget calls Provider method
├── Provider Processing
│   ├── Calls Service layer
│   ├── Updates internal state
│   └── Notifies listeners
├── UI Updates
│   ├── Widgets rebuild automatically
│   ├── Loading states shown
│   └── Error states handled
└── Side Effects
    ├── Navigation changes
    ├── Snackbar notifications
    └── Cache updates
```

## 🔍 Component Lookup Guide

### Finding Components by Feature

| Feature | Screens | Services | Models | Widgets |
|---------|---------|----------|---------|---------|
| **Authentication** | `screens/auth/` | `services/auth/` | `models/user/` | `widgets/auth/` |
| **User Profile** | `screens/user/` | `services/user/` | `models/user/` | `widgets/user/` |
| **Escape Rooms** | `screens/escape_room/` | `services/escape_room/` | `models/escape_room/` | `widgets/escape_room/` |
| **Bookings** | `screens/booking/` | `services/booking/` | `models/booking/` | `widgets/booking/` |
| **Reviews** | `screens/review/` | `services/review/` | `models/review/` | `widgets/review/` |
| **Payments** | `screens/payment/` | `services/payment/` | `models/payment/` | `widgets/payment/` |

### Finding Components by Type

| Component Type | Location | Purpose |
|----------------|----------|---------|
| **Configuration** | `lib/config/` | Environment-specific settings |
| **Constants** | `lib/constants/` | App-wide constants and enums |
| **Services** | `lib/services/` | Business logic and API interactions |
| **Repositories** | `lib/repositories/` | Data access layer abstraction |
| **Models** | `lib/models/` | Data structures and entities |
| **Screens** | `lib/screens/` | Full-screen UI components |
| **Widgets** | `lib/widgets/` | Reusable UI components |
| **Utils** | `lib/utils/` | Helper functions and utilities |
| **State** | `lib/state/` | Riverpod providers and state management |

## 🚀 Development Guidelines

### Adding New Components

1. **Follow the established directory structure**
2. **Use the repository pattern for data access**
3. **Implement proper error handling**
4. **Add appropriate tests**
5. **Update this index when adding major components**

### Component Naming Conventions

- **Screens**: `[Feature][Purpose]Screen` (e.g., `LoginScreen`, `EscapeRoomDetailScreen`)
- **Services**: `[Feature]Service` (e.g., `AuthService`, `BookingService`)
- **Models**: `[Entity]Model` (e.g., `UserModel`, `EscapeRoomModel`)
- **Widgets**: `[Purpose][Widget]` (e.g., `LoginForm`, `RoomCard`)
- **Providers**: `[Feature]Provider` (e.g., `authProvider`, `userProvider`)

### Testing Strategy

- **Unit Tests**: `test/unit/` - Test individual components
- **Widget Tests**: `test/widget/` - Test UI components
- **Integration Tests**: `integration_test/` - Test complete workflows
- **Mocks**: `test/mocks/` - Mock external dependencies

---

## 📚 Related Documentation

- [Project Structure](project-structure.md) - Detailed directory structure
- [Database Reference](database-reference.md) - Database schema and relationships
- [Development Guide](/doc/product-docs/guides/guides/development-guide.md) - Development standards and practices
- [API Documentation](/doc/product-docs/technical/api/README.md) - API reference and usage

---

*This document is automatically updated when major architectural changes are made. Last updated: 2025-07-13*
