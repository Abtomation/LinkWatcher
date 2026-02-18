---
id: PD-GDE-006
type: Product Documentation
category: Guide
version: 1.0
created: 2025-06-10
updated: 2025-06-10
---

# Breakout Buddies - Test Environment Guide

This document provides instructions for setting up and using the test environment for the Breakout Buddies app.

## Test Environment Setup

### 1. Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- A test Supabase project (separate from production)

#### 1.1. Create test database

Setting up a test environment for your project involves creating a separate instance of your application and database that mimics your production environment. Here are the general steps to set up a test environment:

##### 1.1.1. Create a Separate Database:
In your database management system (like Supabase), create a new database specifically for testing purposes. This ensures that your test data does not interfere with your production data.
Done breakoutbuddy_QA

##### 1.1.2. Clone Your Production Database Schema:
If you have an existing production database, you can clone its schema to your test database. This can usually be done using SQL commands or database management tools

##### 1.1.3. Set Up Environment Variables:
Create a separate configuration file or environment variables for your test environment. This should include database connection strings, API keys, and any other configuration settings that differ from production.

##### 1.1.4. Seed Test Data:
Populate your test database with sample data that reflects the types of data you expect in production. This can help you test your application more effectively.

##### 1.1.5. Configure Your Application:
Modify your application to point to the test database and use the test environment variables. Ensure that any API calls or external services are also set to use test configurations.

##### 1.1.6. Implement Testing Frameworks:
Set up testing frameworks (like Jest, Mocha, etc.) for unit and integration tests. Write tests that cover the functionality of your application.

##### 1.1.7. Run Tests:
Execute your tests to ensure that everything works as expected in the test environment. Make adjustments as necessary based on test results.

##### 1.1.8. Automate Testing:
Consider using Continuous Integration (CI) tools to automate the testing process. This can help you run tests automatically whenever changes are made to the codebase.

##### 1.1.9. Monitor and Maintain:
Regularly update your test environment to reflect changes in your production environment. This includes updating the schema, seeding new test data, and ensuring that tests remain relevant.

### 2. Configuration

1. Create a `.env.test` file in the project root with the following variables:
   ```
   SUPABASE_URL=your_test_supabase_url
   SUPABASE_ANON_KEY=your_test_supabase_anon_key
   TEST_MODE=true
   MOCK_SERVICES=true
   ```

2. Set up your test Supabase project:
   - Create a new project in Supabase specifically for testing
   - Set up the same tables and functions as your production environment
   - Add test data as needed

### 3. Install Dependencies

Run the following command to install all required dependencies:
```
flutter pub get
```

## Running Tests

### Unit Tests

Unit tests verify individual components in isolation:

```
flutter test test/unit
```

### Widget Tests

Widget tests verify UI components:

```
flutter test test/widget
```

### Integration Tests

Integration tests verify end-to-end functionality:

```
flutter test integration_test
```

### Running All Tests

To run all tests at once, use the provided script:

```
../../development/guides/scripts/run_tests.bat
```

## Test Structure

The test directory is organized as follows:

```
test/
├── unit/               # Unit tests for services, repositories, etc.
├── widget/             # Widget tests for UI components
├── integration/        # Integration tests for feature flows
├── mocks/              # Mock implementations for testing
└── test_helpers/       # Helper utilities for testing

integration_test/       # End-to-end tests
```

## Writing Tests

### Unit Tests

Unit tests should focus on testing a single unit of functionality:

```dart
test('signInWithEmailAndPassword should return a user on success', () async {
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
});
```

### Widget Tests

Widget tests should verify UI components and interactions:

```dart
testWidgets('LoginScreen shows email and password fields', (WidgetTester tester) async {
  // Build the LoginScreen widget
  await tester.pumpWidget(
    MaterialApp(
      home: LoginScreen(),
    ),
  );

  // Verify that the email and password fields are present
  expect(find.byType(TextFormField), findsNWidgets(2));
  expect(find.text('Email'), findsOneWidget);
  expect(find.text('Password'), findsOneWidget);
});
```

### Integration Tests

Integration tests should verify end-to-end functionality:

```dart
testWidgets('Verify login flow', (WidgetTester tester) async {
  // Load app widget
  app.main();
  await tester.pumpAndSettle();

  // Verify that we are on the login screen
  expect(find.text('Welcome Back'), findsOneWidget);

  // Enter email and password
  await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'password123');

  // Tap the login button
  await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
  await tester.pumpAndSettle();

  // Verify successful login
  expect(find.text('Home'), findsOneWidget);
});
```

## Mocking Dependencies

Use the provided mock classes in the `test/mocks` directory to mock dependencies:

```dart
final mockSupabaseService = SupabaseTestHelper.getMockSupabaseService();
```

## Continuous Integration

For CI/CD pipelines, use the following commands:

```
flutter test --coverage
```

This will generate a coverage report in the `coverage` directory.

## Best Practices

1. **Test Isolation**: Each test should be independent and not rely on the state from other tests.
2. **Mock External Dependencies**: Always mock external services like Supabase.
3. **Test Edge Cases**: Include tests for error conditions and edge cases.
4. **Keep Tests Fast**: Unit and widget tests should run quickly.
5. **Descriptive Test Names**: Use clear, descriptive names for test methods.
6. **Follow AAA Pattern**: Arrange, Act, Assert for clear test structure.
7. **Update Tests with Code**: When code changes, update the corresponding tests.

## Related Documentation

- [Testing Guide](testing-guide.md) - Comprehensive guide for testing the application
- [Supabase Local Setup Guide](../../development/guides/supabase-local-setup.md) - Guide for setting up Supabase locally for testing
- [CI/CD Environment Guide](ci-cd-environment-guide.md) - Information about the CI/CD environment
