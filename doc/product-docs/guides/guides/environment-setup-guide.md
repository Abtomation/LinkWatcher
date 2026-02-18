---
id: PD-GDE-004
type: Product Documentation
category: Guide
version: 1.0
created: 2025-06-10
updated: 2025-06-10
---

# BreakoutBuddies Environment Setup

This document explains how to run and build the BreakoutBuddies app in different environments.

## Environment Types

The app supports three environments:

1. **Development** - For local development with mock services
2. **Testing** - For QA and testing with staging services
3. **Production** - For production releases with live services

## Running in Development Mode

### Using VS Code

1. Open the project in VS Code
2. Select the "Development (Mock Auth)" launch configuration
3. Press F5 or click the "Run" button

### Using Command Line

```bash
flutter run --dart-define=ENVIRONMENT=development --dart-define=DEVELOPMENT_MODE=true --dart-define=USE_MOCK_AUTH=true
```

## Building for Production

### Using Build Scripts

#### Windows
```
../../development/guides/scripts/build_production.bat
```

#### macOS/Linux
```
chmod +x ../../development/guides/scripts/scripts/build_production.sh
../../development/guides/scripts/build_production.sh
```

### Manual Build Command

```bash
flutter build apk --release --dart-define=ENVIRONMENT=production --dart-define=DEVELOPMENT_MODE=false --dart-define=USE_MOCK_AUTH=false
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| ENVIRONMENT | Sets the app environment (development, testing, production) | development |
| DEVELOPMENT_MODE | Enables development-only features | true |
| USE_MOCK_AUTH | Uses mock authentication instead of Supabase | true |

## Development Features

When running in development mode (`DEVELOPMENT_MODE=true`), the following features are available:

1. **Development Login** - A simplified login that bypasses Supabase authentication
2. **Direct Dashboard Access** - Skip login and go directly to the dashboard
3. **Development UI Elements** - Orange buttons and banners indicating development mode

These features are completely removed from production builds.

## Authentication

In development mode with `USE_MOCK_AUTH=true`, the app uses a mock authentication service that:

1. Always succeeds login attempts
2. Provides a mock user profile
3. Doesn't require a working Supabase auth service

In production mode, the app uses the real Supabase authentication service.
