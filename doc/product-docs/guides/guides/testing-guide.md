---
id: PD-GDE-003
type: Product Documentation
category: Guide
version: 1.0
created: 2025-06-10
updated: 2025-06-10
---

# BreakoutBuddies Testing Guide

This document outlines the testing procedures for the BreakoutBuddies application, covering both local development testing with Supabase and the various testing approaches available in the project.

## Table of Contents

1. [Setting Up the Local Testing Environment](#setting-up-the-local-testing-environment)
2. [Running the Local Supabase Instance](#running-the-local-supabase-instance)
3. [Testing Approaches](#testing-approaches)
   - [Unit Tests](#unit-tests)
   - [Widget Tests](#widget-tests)
   - [Integration Tests](#integration-tests)
4. [Mocking Dependencies](#mocking-dependencies)
5. [Continuous Integration](#continuous-integration)
6. [Switching Between Development and Production](#switching-between-development-and-production)

## Setting Up the Local Testing Environment

Before running tests, ensure you have the following prerequisites installed:

- Flutter SDK (latest stable version)
- Dart SDK
- Docker Desktop
- Git

Clone the repository and install dependencies:

```bash
git clone https://github.com/your-username/breakoutbuddies.git
cd breakoutbuddies
flutter pub get
```

## Running the Local Supabase Instance

The application uses Supabase for backend services. For local development and testing, we use a Docker-based local Supabase instance.

For detailed instructions on setting up and using the local Supabase instance, please refer to the [Supabase Local Setup Guide](../../development/guides/supabase-local-setup.md).

Here's a quick summary of the key steps:

1. Start the Supabase services using Docker Compose:
   ```bash
   cd c:/Users/ronny/VS_Code/BreakoutBuddies/breakoutbuddies
   docker-compose up -d
   ```

2. Verify that the services are running:
   ```bash
   docker ps
   ```

3. Access Supabase Studio at [http://localhost:3000](http://localhost:3000)

For troubleshooting and more detailed instructions, see the <!-- [Common Issues and Troubleshooting](../../development/guides/supabase-local-setup.md#common-issues-and-troubleshooting) - File not found --> section in the Supabase Local Setup Guide.

## Testing Approaches

The project uses three main types of tests:

### Unit Tests

Unit tests focus on testing individual components in isolation, such as services, providers, and utility functions.

To run all unit tests:

```bash
flutter test test/unit/
```

To run a specific unit test:

```bash
flutter test ../../development/guides/test/development/guides/test/unit/supabase_service_test.dart
```

Example unit test for the Supabase service:

```dart
// ../../development/guides/test/unit/supabase_service_test.dart
import 'package:flutter_test<!-- <!-- <!-- /flutter_test.dart - File not found --> - File not found --> - File not found -->';
import 'package:mockito<!-- <!-- /mockito.dart - File not found --> - File not found -->';
import 'package:breakoutbuddies/services/supabase_service.dart';
import '../../development/development/guides/test/mocks/mock_supabase_service.dart';

void main() {
  late MockSupabaseService mockSupabaseService;

  setUp(() {
    mockSupabaseService = SupabaseTestHelper.getMockSupabaseService();
  });

  group('SupabaseService Authentication Tests', () {
    test(
      'signInWithEmailAndPassword should return a user on success',
      () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';

        // Act
        final response = await mockSupabaseService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(response.user, isNotNull);
        expect(response.user!.id, 'test-user-id');
      },
    );
  });
}
```

### Widget Tests

Widget tests focus on testing individual widgets and their interactions.

To run all widget tests:

```bash
flutter test test/widget/
```

To run a specific widget test:

```bash
flutter test ../../development/guides/test/development/guides/test/widget/login_screen_test.dart
```

Example widget test:

```dart
// ../../development/guides/test/widget/login_screen_test.dart
import 'package:flutter<!-- <!-- /material.dart - File not found --> - File not found -->';
import 'package:flutter_test/flutter_test.dart';
import 'package:breakoutbuddies/screens/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen has email and password fields', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Verify that our login screen has email and password fields
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
```

### Integration Tests

Integration tests focus on testing the interaction between multiple components or the entire app.

To run integration tests:

```bash
flutter test ../../development/guides/integration_test/development/guides/integration_test/app_test.dart
```

Example integration test:

```dart
// ../../development/guides/integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test<!-- /integration_test.dart - File not found -->';
import 'package:breakoutbuddies/lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('tap on login button, verify navigation to login page',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify that we're on the home screen
      expect(find.text('Welcome to Breakout Buddies'), findsOneWidget);

      // Tap on the login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Verify that we're on the login screen
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
```

## Mocking Dependencies

The project uses Mockito for mocking dependencies in tests. Mock implementations are available in the `test/mocks/` directory.

Example of a mock implementation:

```dart
// ../../development/guides/test/mocks/mock_supabase_service.dart
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter<!-- /supabase_flutter.dart - File not found -->';
import 'package:breakoutbuddies/services/supabase_service.dart';
import 'package:test<!-- /test.dart - File not found -->';

// This class will be used to generate a mock with Mockito
abstract class SupabaseServiceBase {
  SupabaseClient get client;
  User? get currentUser;
  bool get isAuthenticated;
  // ... other methods
}

// Generate the mock class
class MockSupabaseService extends Mock implements SupabaseServiceBase {
  @override
  bool get isAuthenticated => false;

  @override
  User? get currentUser => null;

  // ... other method implementations
}

// Create a test helper to set up the mock with common behaviors
class SupabaseTestHelper {
  static MockSupabaseService getMockSupabaseService() {
    return MockSupabaseService();
  }
}
```

## Continuous Integration

The project uses GitHub Actions for continuous integration. The CI pipeline runs all tests on every push and pull request.

The CI configuration is defined in `.github<!-- /workflows/flutter.yml - File not found -->`.

## Switching Between Development and Production

The application uses environment constants to switch between development and production environments. These constants are defined in `lib/lib/constants/env.dart`.

For local development and testing, use the local Supabase instance:

```dart
/// Environment constants for the application
class Env {
  /// Supabase URL - Local development URL
  static const String supabaseUrl = 'http://localhost:8000';

  /// Supabase Anon Key - Local development anon key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

  /// Production Supabase URL (uncomment when deploying to production)
  // static const String supabaseUrl = 'https://ynpizhhrphzvhemqddvu.supabase.co';

  /// Production Supabase Anon Key (uncomment when deploying to production)
  // static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
}
```

For production, uncomment the production URLs and comment out the local development URLs:

```dart
/// Environment constants for the application
class Env {
  /// Supabase URL - Local development URL
  // static const String supabaseUrl = 'http://localhost:8000';

  /// Supabase Anon Key - Local development anon key
  // static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

  /// Production Supabase URL
  static const String supabaseUrl = 'https://ynpizhhrphzvhemqddvu.supabase.co';

  /// Production Supabase Anon Key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
}
```

---

## Related Documentation

This testing guide is part of the overall <!-- [Feature Implementation Process](../../development/processes/development-guide.md#1-feature-implementation-process) - File not found -->. For additional information, refer to the following documents:

- [Testing Checklist](../../checklists/checklists/testing-checklist.md): A comprehensive checklist for testing implementations
- [Definition of Done](../../../process-framework/methodologies/definition-of-done.md): Criteria for when a feature is considered complete
- [CI/CD Environment Guide](ci-cd-environment-guide.md): Information on the CI/CD pipeline and automated testing
- [Feature Implementation Checklist](../../checklists/checklists/feature-implementation-checklist.md): Comprehensive checklist for implementing new features

This testing guide should help you get started with testing the BreakoutBuddies application. If you have any questions or encounter any issues, please refer to the project documentation or contact the development team.
