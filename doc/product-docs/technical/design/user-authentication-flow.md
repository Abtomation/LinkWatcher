---
id: PD-DES-002
type: Product Documentation
category: Design
version: 1.2
created: 2025-05-20
updated: 2025-08-03
---

# User Authentication Flow

## Overview

This document describes the design for the user authentication flow in the BreakoutBuddies application, including registration, login, password reset, and email verification. It provides a comprehensive technical specification for implementing secure and user-friendly authentication features.

### Scope

This design covers:
- User registration with email and password
- Social login integration (Google, Apple, Facebook)
- Email verification
- Password reset functionality
- Authentication state management
- Protected routes

This design does not cover:
- Provider authentication (covered in a separate design document)
- User profile management (covered in a separate design document)
- Role-based access control (covered in a separate design document)

### Related Features
- User Profile Management
- Provider Authentication
- Settings Management
- User Onboarding Flow (handles first-time user setup after social login)
- Profile Completion Feature (handles missing user information after social login)

## Requirements

### Functional Requirements

1. Users must be able to register with email and password
2. Users must be able to log in with email and password
3. Users must be able to log in with social accounts (Google, Apple, Facebook)
4. Users must be able to reset their password
5. Users must be able to verify their email address
6. Users must be automatically logged in after registration
7. Users must remain logged in until they explicitly log out
8. Users must be redirected to protected routes after login
9. Users must be redirected to login when accessing protected routes while not authenticated
10. System must detect and handle account linking when social login email matches existing account
11. Users must explicitly grant permission before linking social accounts to existing accounts
12. Users must be able to link multiple social accounts to a single user account
13. System must collect minimal information from social providers (name, email, profile picture only)
14. System must reject social login attempts without email addresses
15. New social login users must be directed to onboarding flow
16. Returning social login users must be redirected directly to dashboard

## Quality Attribute Requirements

Based on [System Quality Attributes](/doc/product-docs/technical/architecture/quality-attributes.md), the User Authentication Flow must meet the following quality targets:

### Performance Requirements

#### Authentication Response Times
- **Login Process**: < 1 second for successful authentication
- **Registration**: < 2 seconds for account creation
- **Social Login**: < 2 seconds for OAuth provider integration
- **Password Reset**: < 3 seconds for reset email delivery

#### User Interface Performance
- **Form Validation**: < 100ms for real-time input validation
- **Button Feedback**: < 100ms visual feedback for user actions
- **Navigation**: < 150ms for transitions between authentication screens
- **Loading States**: Visible within 50ms of user action

#### Mobile App Performance
- **Authentication State Loading**: < 500ms to determine user authentication status
- **Session Restoration**: < 1 second to restore authenticated session on app restart
- **Memory Usage**: < 50MB additional memory for authentication components
- **Network Optimization**: Minimal data usage for authentication operations

### Security Requirements

#### Authentication Security
- **Password Strength**: Minimum 8 characters with complexity requirements (uppercase, number, special character)
- **Account Lockout**: 5 failed attempts trigger temporary lockout (15 minutes)
- **Session Security**: Secure session tokens with appropriate expiration (24 hours for mobile, 8 hours for web)
- **Social Login Security**: Secure OAuth implementation with proper scope management (email, profile only)

#### Data Protection
- **Encryption in Transit**: TLS 1.3 for all authentication API communications
- **Token Security**: JWT tokens with secure signing and validation
- **Personal Data**: GDPR-compliant handling of user authentication data
- **Account Linking**: Secure verification before linking social accounts to existing accounts

#### Input Validation & Security
- **Input Sanitization**: All authentication inputs validated and sanitized
- **SQL Injection Prevention**: Parameterized queries through Supabase ORM
- **Rate Limiting**: Maximum 10 authentication attempts per IP per minute
- **CSRF Protection**: Anti-CSRF tokens for authentication state changes

### Reliability Requirements

#### Authentication Availability
- **Core Authentication**: 99.95% uptime for login/logout services
- **Social Login**: 99.9% uptime for OAuth provider integration
- **Account Recovery**: 99.9% uptime for password reset functionality
- **Session Management**: 99.95% uptime for session validation

#### Error Handling & Recovery
- **Graceful Degradation**: Authentication works with reduced functionality when social providers are unavailable
- **Error Messages**: User-friendly error messages with actionable guidance
- **Automatic Recovery**: Automatic retry for transient authentication failures
- **Session Recovery**: Graceful handling of expired sessions with re-authentication prompts

#### Data Integrity
- **Account Consistency**: ACID compliance for user account creation and updates
- **Audit Trail**: Comprehensive logging of authentication events for security monitoring
- **Data Validation**: Multi-layer validation of authentication data
- **Recovery Procedures**: Clear recovery paths for authentication failures

### Usability Requirements

#### User Experience
- **Intuitive Flow**: Clear, step-by-step authentication process
- **Clear Messaging**: User-friendly error messages and success confirmations
- **Progress Indicators**: Visual feedback during authentication operations
- **Account Linking**: Clear explanation and consent flow for social account linking

#### Accessibility
- **WCAG 2.1 AA Compliance**: Full accessibility compliance for authentication screens
- **Screen Reader Support**: Proper semantic markup and ARIA labels for form elements
- **Keyboard Navigation**: Complete keyboard accessibility for all authentication flows
- **High Contrast**: Support for high contrast mode and custom color schemes

#### Mobile Optimization
- **Touch Targets**: Minimum 44px touch targets for all interactive elements
- **Responsive Design**: Optimal experience across all device sizes and orientations
- **Biometric Integration**: Support for device biometric authentication where available
- **Offline Capability**: Authentication state persistence and limited offline functionality

### Constraints

1. Authentication must use Supabase Auth
2. Social login must comply with platform guidelines
3. Email verification must use Supabase's email templates
4. Password reset must use Supabase's password reset flow

## Architecture

### Component Diagram

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│  Auth Screens   │────▶│  Auth Service   │────▶│  Supabase Auth  │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│  Auth Providers │◀───▶│  User Service   │◀───▶│  Supabase DB    │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │
        │
        ▼
┌─────────────────┐
│                 │
│  App Router     │
│                 │
└─────────────────┘
```

### Data Flow

#### Registration Flow

1. User enters email, password, and other required information
2. Client validates input
3. Client calls Supabase Auth to create a new user
4. Supabase sends a verification email to the user
5. Client creates a user profile in the database
6. Client updates authentication state
7. Client redirects to the home screen or onboarding flow

#### Login Flow

1. User enters email and password or selects a social login option
2. Client validates input
3. Client calls Supabase Auth to authenticate the user
4. For social login: Client checks if email matches existing account
5. If email match found: Client prompts user for account linking permission
6. If linking approved: Client links social account to existing user account
7. If linking declined: Client creates separate social account
8. Client updates authentication state
9. For new users: Client redirects to onboarding flow
10. For returning users: Client redirects to dashboard or originally requested protected route

#### Password Reset Flow

1. User requests a password reset
2. Client calls Supabase Auth to send a password reset email
3. User clicks the link in the email
4. User is directed to a password reset screen
5. User enters a new password
6. Client calls Supabase Auth to update the password
7. Client redirects to the login screen

### State Management

Authentication state will be managed using Riverpod providers:

1. `authStateProvider`: Streams the current authentication state from Supabase
2. `currentUserProvider`: Provides the current user information
3. `authControllerProvider`: Provides methods for authentication operations

## Detailed Design

### Models

```dart
// User model
class User {
  final String id;
  final String email;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime lastSignInAt;
  final List<SocialAccount> linkedSocialAccounts;
  final bool isFirstTimeUser;

  User({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.createdAt,
    required this.lastSignInAt,
    this.linkedSocialAccounts = const [],
    this.isFirstTimeUser = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      emailVerified: json['email_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      lastSignInAt: json['last_sign_in_at'] != null
        ? DateTime.parse(json['last_sign_in_at'])
        : DateTime.now(),
      linkedSocialAccounts: (json['linked_social_accounts'] as List<dynamic>?)
          ?.map((account) => SocialAccount.fromJson(account))
          .toList() ?? [],
      isFirstTimeUser: json['is_first_time_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'email_verified': emailVerified,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in_at': lastSignInAt.toIso8601String(),
      'linked_social_accounts': linkedSocialAccounts.map((account) => account.toJson()).toList(),
      'is_first_time_user': isFirstTimeUser,
    };
  }
}

// Social account model for account linking
class SocialAccount {
  final String provider; // 'google', 'apple', 'facebook'
  final String providerId;
  final String? displayName;
  final String? profilePictureUrl;
  final DateTime linkedAt;

  SocialAccount({
    required this.provider,
    required this.providerId,
    this.displayName,
    this.profilePictureUrl,
    required this.linkedAt,
  });

  factory SocialAccount.fromJson(Map<String, dynamic> json) {
    return SocialAccount(
      provider: json['provider'],
      providerId: json['provider_id'],
      displayName: json['display_name'],
      profilePictureUrl: json['profile_picture_url'],
      linkedAt: DateTime.parse(json['linked_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'provider_id': providerId,
      'display_name': displayName,
      'profile_picture_url': profilePictureUrl,
      'linked_at': linkedAt.toIso8601String(),
    };
  }
}

// Account linking request model
class AccountLinkingRequest {
  final String existingUserId;
  final String socialProvider;
  final String socialProviderId;
  final String email;
  final String? displayName;
  final String? profilePictureUrl;

  AccountLinkingRequest({
    required this.existingUserId,
    required this.socialProvider,
    required this.socialProviderId,
    required this.email,
    this.displayName,
    this.profilePictureUrl,
  });
}

// Authentication state model
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final AccountLinkingRequest? pendingAccountLinking;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.pendingAccountLinking,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    AccountLinkingRequest? pendingAccountLinking,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pendingAccountLinking: pendingAccountLinking ?? this.pendingAccountLinking,
    );
  }

  static AuthState initial() {
    return AuthState(
      user: null,
      isLoading: true,
      error: null,
      pendingAccountLinking: null,
    );
  }
}

// Social login result model
class SocialLoginResult {
  final SocialLoginResultType type;
  final User? user;
  final AccountLinkingRequest? accountLinkingRequest;

  SocialLoginResult({
    required this.type,
    this.user,
    this.accountLinkingRequest,
  });
}

enum SocialLoginResultType {
  firstTimeUser,
  returningUser,
  accountLinkingRequired,
}

// Social login exception model
class SocialLoginException implements Exception {
  final String provider;
  final String message;
  final SocialLoginErrorType type;

  SocialLoginException({
    required this.provider,
    required this.message,
    required this.type,
  });

  @override
  String toString() => 'SocialLoginException($provider): $message';
}

enum SocialLoginErrorType {
  authenticationFailed,
  networkError,
  missingEmail,
  invalidUserData,
  providerUnavailable,
  userCancelled,
  permissionDenied,
}
```

### Services

```dart
// Authentication service
class AuthService {
  final SupabaseClient _supabaseClient;

  AuthService(this._supabaseClient);

  Stream<User?> authStateChanges() {
    return _supabaseClient.auth.onAuthStateChange.map((event) {
      final session = event.session;
      if (session == null) {
        return null;
      }
      return User.fromJson(session.user.toJson());
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _supabaseClient.auth.signUp(
      email: email,
      password: password,
    );

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  Future<SocialLoginResult> signInWithGoogle() async {
    try {
      final response = await _supabaseClient.auth.signInWithOAuth(
        Provider.google,
      );

      if (response.error != null) {
        throw SocialLoginException(
          provider: 'google',
          message: response.error!.message,
          type: SocialLoginErrorType.authenticationFailed,
        );
      }

      return await _processSocialLoginResult('google', response);
    } catch (e) {
      if (e is SocialLoginException) rethrow;
      throw SocialLoginException(
        provider: 'google',
        message: e.toString(),
        type: SocialLoginErrorType.networkError,
      );
    }
  }

  Future<SocialLoginResult> signInWithApple() async {
    try {
      final response = await _supabaseClient.auth.signInWithOAuth(
        Provider.apple,
      );

      if (response.error != null) {
        throw SocialLoginException(
          provider: 'apple',
          message: response.error!.message,
          type: SocialLoginErrorType.authenticationFailed,
        );
      }

      return await _processSocialLoginResult('apple', response);
    } catch (e) {
      if (e is SocialLoginException) rethrow;
      throw SocialLoginException(
        provider: 'apple',
        message: e.toString(),
        type: SocialLoginErrorType.networkError,
      );
    }
  }

  Future<SocialLoginResult> signInWithFacebook() async {
    try {
      final response = await _supabaseClient.auth.signInWithOAuth(
        Provider.facebook,
      );

      if (response.error != null) {
        throw SocialLoginException(
          provider: 'facebook',
          message: response.error!.message,
          type: SocialLoginErrorType.authenticationFailed,
        );
      }

      return await _processSocialLoginResult('facebook', response);
    } catch (e) {
      if (e is SocialLoginException) rethrow;
      throw SocialLoginException(
        provider: 'facebook',
        message: e.toString(),
        type: SocialLoginErrorType.networkError,
      );
    }
  }

  Future<SocialLoginResult> _processSocialLoginResult(
    String provider,
    AuthResponse response
  ) async {
    final user = response.user;
    if (user == null) {
      throw SocialLoginException(
        provider: provider,
        message: 'No user data received from provider',
        type: SocialLoginErrorType.invalidUserData,
      );
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw SocialLoginException(
        provider: provider,
        message: 'Email address is required but not provided by social provider',
        type: SocialLoginErrorType.missingEmail,
      );
    }

    // Check if this is a new user or existing user
    final existingUser = await _checkExistingUserByEmail(email);

    if (existingUser != null && existingUser.id != user.id) {
      // Email matches existing account - account linking required
      return SocialLoginResult(
        type: SocialLoginResultType.accountLinkingRequired,
        user: null,
        accountLinkingRequest: AccountLinkingRequest(
          existingUserId: existingUser.id,
          socialProvider: provider,
          socialProviderId: user.id,
          email: email,
          displayName: user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
          profilePictureUrl: user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
        ),
      );
    }

    // Check if this is first time login
    final isFirstTime = await _isFirstTimeUser(user.id);

    return SocialLoginResult(
      type: isFirstTime
        ? SocialLoginResultType.firstTimeUser
        : SocialLoginResultType.returningUser,
      user: User.fromJson({
        ...user.toJson(),
        'is_first_time_user': isFirstTime,
      }),
      accountLinkingRequest: null,
    );
  }

  Future<User?> _checkExistingUserByEmail(String email) async {
    // Implementation to check if user exists with this email
    // This would query the user_profiles table
    return null; // Placeholder
  }

  Future<bool> _isFirstTimeUser(String userId) async {
    // Implementation to check if this is user's first login
    // This would check user_profiles table for existing profile
    return false; // Placeholder
  }

  Future<bool> linkSocialAccount(AccountLinkingRequest request) async {
    try {
      // Link the social account to the existing user
      final response = await _supabaseClient
        .from('user_social_accounts')
        .insert({
          'user_id': request.existingUserId,
          'provider': request.socialProvider,
          'provider_id': request.socialProviderId,
          'display_name': request.displayName,
          'profile_picture_url': request.profilePictureUrl,
          'linked_at': DateTime.now().toIso8601String(),
        });

      return response.error == null;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    final response = await _supabaseClient.auth.signOut();

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  Future<void> resetPassword({required String email}) async {
    final response = await _supabaseClient.auth.resetPasswordForEmail(
      email,
    );

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  Future<void> updatePassword({required String password}) async {
    final response = await _supabaseClient.auth.updateUser(
      UserAttributes(password: password),
    );

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }
}
```

### Repositories

```dart
// User repository
class UserRepository {
  final SupabaseClient _supabaseClient;

  UserRepository(this._supabaseClient);

  Future<void> createUserProfile({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    final response = await _supabaseClient
      .from('user_profiles')
      .insert({
        'user_id': userId,
        'email': email,
        'display_name': displayName ?? email.split('@').first,
        'created_at': DateTime.now().toIso8601String(),
      });

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _supabaseClient
      .from('user_profiles')
      .select()
      .eq('user_id', userId)
      .single();

    if (response.error != null) {
      if (response.error!.message.contains('No rows found')) {
        return null;
      }
      throw Exception(response.error!.message);
    }

    return response.data;
  }
}
```

### State Management Implementation

```dart
// Auth state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier(this._authService) : super(AuthState.initial()) {
    _initialize();
  }

  void _initialize() {
    _authSubscription = _authService.authStateChanges().listen(
      (user) {
        state = state.copyWith(
          user: user,
          isLoading: false,
        );
      },
      onError: (error) {
        state = state.copyWith(
          error: error.toString(),
          isLoading: false,
        );
      },
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.signIn(
        email: email,
        password: password,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signInWithGoogle();
      await _handleSocialLoginResult(result);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signInWithApple();
      await _handleSocialLoginResult(result);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signInWithFacebook() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signInWithFacebook();
      await _handleSocialLoginResult(result);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _handleSocialLoginResult(SocialLoginResult result) async {
    switch (result.type) {
      case SocialLoginResultType.firstTimeUser:
        state = state.copyWith(
          user: result.user,
          isLoading: false,
        );
        // Navigation to onboarding flow handled by UI layer
        break;

      case SocialLoginResultType.returningUser:
        state = state.copyWith(
          user: result.user,
          isLoading: false,
        );
        // Navigation to dashboard handled by UI layer
        break;

      case SocialLoginResultType.accountLinkingRequired:
        state = state.copyWith(
          isLoading: false,
          pendingAccountLinking: result.accountLinkingRequest,
        );
        // Account linking dialog handled by UI layer
        break;
    }
  }

  Future<void> approveAccountLinking() async {
    final linkingRequest = state.pendingAccountLinking;
    if (linkingRequest == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final success = await _authService.linkSocialAccount(linkingRequest);
      if (success) {
        // Refresh user data to include linked account
        state = state.copyWith(
          isLoading: false,
          pendingAccountLinking: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to link social account',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void declineAccountLinking() {
    state = state.copyWith(
      pendingAccountLinking: null,
    );
    // Proceed with separate social account creation
    // This would trigger a new social login flow
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.signOut();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
```

## Database Schema Requirements

### User Social Accounts Table
```sql
CREATE TABLE user_social_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  provider VARCHAR(50) NOT NULL, -- 'google', 'apple', 'facebook'
  provider_id VARCHAR(255) NOT NULL,
  display_name VARCHAR(255),
  profile_picture_url TEXT,
  linked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(provider, provider_id),
  UNIQUE(user_id, provider)
);
```

### User Profiles Table Updates
```sql
-- Add columns to existing user_profiles table
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS is_first_time_user BOOLEAN DEFAULT true;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS profile_completion_required BOOLEAN DEFAULT false;
```

### Indexes for Performance
```sql
CREATE INDEX idx_user_social_accounts_user_id ON user_social_accounts(user_id);
CREATE INDEX idx_user_social_accounts_provider ON user_social_accounts(provider);
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
```

## Security Considerations

1. **Password Security**:
   - Passwords are never stored in plain text
   - Supabase handles password hashing and salting
   - Minimum password length of 6 characters is enforced

2. **Authentication Tokens**:
   - JWT tokens are used for authentication
   - Tokens are stored securely using secure storage
   - Tokens have an expiration time

3. **Social Login Security**:
   - OAuth 2.0 is used for social login
   - No passwords are stored for social login users
   - Platform-specific security guidelines are followed
   - Social account linking requires explicit user consent
   - Minimal data collection from social providers (name, email, profile picture only)

4. **Email Verification**:
   - Email verification is required for new accounts
   - Verification links expire after 24 hours
   - Email verification status is tracked in the user model

5. **Account Linking Security**:
   - Account linking requires explicit user permission
   - Email verification is required before linking accounts
   - Audit trail maintained for all account linking activities
   - Users can unlink social accounts at any time

## Testing Strategy

1. **Unit Tests**:
   - Test authentication services in isolation
   - Test state management logic
   - Test form validation
   - Test account linking logic
   - Test social login result processing
   - Test error handling for social login exceptions

2. **Integration Tests**:
   - Test authentication flow end-to-end
   - Test error handling and edge cases
   - Test persistence of authentication state
   - Test social login with account linking scenarios
   - Test first-time vs returning user flows
   - Test social account linking and unlinking

3. **UI Tests**:
   - Test login and registration screens
   - Test form validation feedback
   - Test loading states and error messages
   - Test social login buttons and flows
   - Test account linking permission dialogs
   - Test error messages for social login failures
   - Test navigation to onboarding vs dashboard

4. **Social Login Specific Tests**:
   - Test OAuth flow with each provider (Google, Apple, Facebook)
   - Test handling of missing email from social provider
   - Test account linking permission flow
   - Test multiple social accounts linked to one user
   - Test social login cancellation scenarios
   - Test provider unavailability handling

## Implementation Plan

1. **Phase 1**: Basic Authentication
   - Implement email/password registration and login
   - Implement authentication state management
   - Implement protected routes

2. **Phase 2**: Social Login Foundation
   - Implement basic social login options (Google, Apple, Facebook)
   - Implement social login error handling
   - Implement email verification
   - Implement password reset flow

3. **Phase 3**: Account Linking & User Experience
   - Implement account linking detection and permission flow
   - Implement multiple social account support
   - Implement first-time user vs returning user logic
   - Implement integration with onboarding and profile completion flows

4. **Phase 4**: Security & Performance Enhancements
   - Implement token refresh mechanism
   - Implement session management
   - Implement security logging
   - Implement social account unlinking functionality
   - Add comprehensive error tracking and analytics

## Quality Attribute Implementation

### Performance Implementation

#### Optimized Authentication Service
```dart
class OptimizedAuthService extends AuthService {
  final PerformanceMonitor _performanceMonitor;
  final CacheManager _cacheManager;

  OptimizedAuthService(
    SupabaseClient supabaseClient,
    this._performanceMonitor,
    this._cacheManager,
  ) : super(supabaseClient);

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      await super.signIn(email: email, password: password);

      _performanceMonitor.recordOperation(
        'authentication_login',
        stopwatch.elapsedMilliseconds,
        true,
      );
    } catch (e) {
      _performanceMonitor.recordOperation(
        'authentication_login',
        stopwatch.elapsedMilliseconds,
        false,
      );
      rethrow;
    }
  }

  @override
  Future<SocialLoginResult> signInWithGoogle() async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await super.signInWithGoogle();

      _performanceMonitor.recordOperation(
        'social_login_google',
        stopwatch.elapsedMilliseconds,
        true,
      );

      return result;
    } catch (e) {
      _performanceMonitor.recordOperation(
        'social_login_google',
        stopwatch.elapsedMilliseconds,
        false,
      );
      rethrow;
    }
  }
}
```

#### Real-time Form Validation
```dart
class OptimizedFormValidator {
  static const int validationDebounceMs = 100;
  Timer? _debounceTimer;

  void validateEmailWithDebounce(
    String email,
    Function(ValidationResult) onResult,
  ) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: validationDebounceMs),
      () {
        final stopwatch = Stopwatch()..start();
        final result = _validateEmail(email);

        // Ensure validation completes within 100ms target
        assert(stopwatch.elapsedMilliseconds < 100);

        onResult(result);
      },
    );
  }

  ValidationResult _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return ValidationResult(
      isValid: emailRegex.hasMatch(email),
      message: emailRegex.hasMatch(email) ? null : 'Invalid email format',
    );
  }
}
```

### Security Implementation

#### Enhanced Authentication Security
```dart
class SecureAuthService extends OptimizedAuthService {
  final SecurityAuditLogger _auditLogger;
  final RateLimiter _rateLimiter;
  final Map<String, int> _failedAttempts = {};

  SecureAuthService(
    SupabaseClient supabaseClient,
    PerformanceMonitor performanceMonitor,
    CacheManager cacheManager,
    this._auditLogger,
    this._rateLimiter,
  ) : super(supabaseClient, performanceMonitor, cacheManager);

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    // Rate limiting check
    if (!_rateLimiter.canProceed('auth_attempt_$email')) {
      _auditLogger.logSecurityEvent(SecurityEvent(
        type: SecurityEventType.rateLimitExceeded,
        email: _maskEmail(email),
        timestamp: DateTime.now(),
        metadata: {'action': 'login_attempt'},
      ));
      throw AuthException('Too many login attempts. Please try again later.');
    }

    // Account lockout check
    final failedCount = _failedAttempts[email] ?? 0;
    if (failedCount >= 5) {
      _auditLogger.logSecurityEvent(SecurityEvent(
        type: SecurityEventType.accountLocked,
        email: _maskEmail(email),
        timestamp: DateTime.now(),
        metadata: {'failed_attempts': failedCount},
      ));
      throw AuthException('Account temporarily locked due to multiple failed attempts.');
    }

    try {
      await super.signIn(email: email, password: password);

      // Reset failed attempts on successful login
      _failedAttempts.remove(email);

      _auditLogger.logSecurityEvent(SecurityEvent(
        type: SecurityEventType.loginSuccess,
        email: _maskEmail(email),
        timestamp: DateTime.now(),
        metadata: {'action': 'login_success'},
      ));
    } catch (e) {
      // Increment failed attempts
      _failedAttempts[email] = failedCount + 1;

      _auditLogger.logSecurityEvent(SecurityEvent(
        type: SecurityEventType.loginFailure,
        email: _maskEmail(email),
        timestamp: DateTime.now(),
        metadata: {
          'action': 'login_failure',
          'error': e.toString(),
          'failed_attempts': _failedAttempts[email],
        },
      ));
      rethrow;
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '[INVALID_EMAIL]';

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) return '${username}@${domain}';

    return '${username.substring(0, 2)}***@${domain}';
  }
}
```

#### Social Login Security
```dart
class SecureSocialLoginHandler {
  final SecurityValidator _validator;

  SecureSocialLoginHandler(this._validator);

  Future<SocialLoginResult> processSecureSocialLogin(
    String provider,
    Map<String, dynamic> userData,
  ) async {
    // Validate required data
    if (!_validator.validateSocialLoginData(userData)) {
      throw SocialLoginException(
        provider: provider,
        message: 'Invalid or insufficient user data from provider',
        type: SocialLoginErrorType.invalidUserData,
      );
    }

    // Ensure email is present
    final email = userData['email'] as String?;
    if (email == null || email.isEmpty) {
      throw SocialLoginException(
        provider: provider,
        message: 'Email address is required but not provided',
        type: SocialLoginErrorType.missingEmail,
      );
    }

    // Validate email format
    if (!_validator.isValidEmail(email)) {
      throw SocialLoginException(
        provider: provider,
        message: 'Invalid email format from social provider',
        type: SocialLoginErrorType.invalidUserData,
      );
    }

    // Sanitize user data
    final sanitizedData = _validator.sanitizeSocialLoginData(userData);

    return _processSocialLoginWithSanitizedData(provider, sanitizedData);
  }
}
```

### Reliability Implementation

#### Resilient Authentication State Management
```dart
class ResilientAuthNotifier extends AuthNotifier {
  final ConnectivityService _connectivityService;
  final LocalStorageService _localStorage;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int maxRetries = 3;

  ResilientAuthNotifier(
    AuthService authService,
    this._connectivityService,
    this._localStorage,
  ) : super(authService);

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _executeWithRetry(() async {
      await super.signIn(email: email, password: password);
    });
  }

  Future<void> _executeWithRetry(Future<void> Function() operation) async {
    _retryCount = 0;

    while (_retryCount < maxRetries) {
      try {
        await operation();
        _retryCount = 0; // Reset on success
        return;
      } catch (e) {
        _retryCount++;

        if (_retryCount >= maxRetries) {
          state = state.copyWith(
            isLoading: false,
            error: 'Authentication failed after multiple attempts. Please check your connection and try again.',
          );
          rethrow;
        }

        // Check connectivity before retry
        if (!await _connectivityService.hasConnection()) {
          state = state.copyWith(
            isLoading: false,
            error: 'No internet connection. Please check your connection and try again.',
          );
          return;
        }

        // Exponential backoff
        final delayMs = 1000 * (1 << (_retryCount - 1)); // 1s, 2s, 4s
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  @override
  void _initialize() {
    // Try to restore authentication state from local storage
    _restoreAuthenticationState();

    super._initialize();

    // Monitor connectivity changes
    _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected && state.error != null) {
        // Retry authentication when connection is restored
        _retryLastOperation();
      }
    });
  }

  Future<void> _restoreAuthenticationState() async {
    try {
      final cachedUser = await _localStorage.getCachedUser();
      if (cachedUser != null) {
        state = state.copyWith(
          user: cachedUser,
          isLoading: false,
        );
      }
    } catch (e) {
      // Ignore cache restoration errors
    }
  }

  void _retryLastOperation() {
    // Implementation for retrying the last failed operation
    // This would store the last operation context and retry it
  }
}
```

### Usability Implementation

#### Accessible Authentication UI
```dart
class AccessibleAuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sign In',
          semanticsLabel: 'Sign In to Breakout Buddies',
        ),
      ),
      body: Semantics(
        label: 'Authentication form',
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Email field with accessibility
              Semantics(
                label: 'Email address input field',
                hint: 'Enter your email address',
                textField: true,
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    errorText: _emailError,
                    prefixIcon: Icon(
                      Icons.email,
                      semanticLabel: 'Email icon',
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: _validateEmailRealTime,
                ),
              ),

              SizedBox(height: 16),

              // Password field with accessibility
              Semantics(
                label: 'Password input field',
                hint: 'Enter your password',
                textField: true,
                obscured: true,
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    errorText: _passwordError,
                    prefixIcon: Icon(
                      Icons.lock,
                      semanticLabel: 'Password icon',
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        semanticLabel: _obscurePassword ? 'Show password' : 'Hide password',
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onChanged: _validatePasswordRealTime,
                ),
              ),

              SizedBox(height: 24),

              // Sign in button with proper touch target
              SizedBox(
                width: double.infinity,
                height: 48, // Minimum 44px touch target
                child: ElevatedButton(
                  onPressed: _isFormValid ? _signIn : null,
                  child: _isLoading
                    ? Semantics(
                        label: 'Signing in, please wait',
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          semanticsLabel: 'Loading',
                        ),
                      )
                    : Text(
                        'Sign In',
                        semanticsLabel: 'Sign in button',
                      ),
                ),
              ),

              SizedBox(height: 16),

              // Social login buttons with proper spacing and touch targets
              _buildSocialLoginButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        Text(
          'Or sign in with',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialButton(
              'Google',
              Icons.g_mobiledata,
              _signInWithGoogle,
              'Sign in with Google',
            ),
            _buildSocialButton(
              'Apple',
              Icons.apple,
              _signInWithApple,
              'Sign in with Apple',
            ),
            _buildSocialButton(
              'Facebook',
              Icons.facebook,
              _signInWithFacebook,
              'Sign in with Facebook',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    String provider,
    IconData icon,
    VoidCallback onPressed,
    String semanticsLabel,
  ) {
    return SizedBox(
      width: 60,
      height: 48, // Minimum touch target
      child: Semantics(
        label: semanticsLabel,
        button: true,
        child: IconButton(
          icon: Icon(icon, size: 24),
          onPressed: onPressed,
          tooltip: semanticsLabel,
        ),
      ),
    );
  }
}
```

## Related Documentation

- [Product: ADR-0001: State Management with Riverpod](/doc/product-docs/technical/architecture/design-docs/adr/adr/adr-001-state-management-with-riverpod.md)
- [Product: ADR-0002: Backend Services with Supabase](/doc/product-docs/technical/architecture/design-docs/adr/adr/adr-002-backend-services-with-supabase.md)
- [Product: Project Structure](/doc/product-docs/technical/architecture/project-structure.md)

---

*This document is part of the Product Documentation and provides the technical design for the user authentication flow in the BreakoutBuddies application.*
