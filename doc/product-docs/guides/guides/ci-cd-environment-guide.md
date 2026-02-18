---
id: PD-GDE-002
type: Product Documentation
category: Guide
version: 1.0
created: 2025-06-10
updated: 2025-06-10
---

# CI/CD and Environment Configuration Guide

This guide explains how to use the CI/CD pipeline and environment configuration system in the Breakout Buddies project.

## Table of Contents

1. [CI/CD Pipeline](#ci-cd-pipeline)
2. [Environment Configuration](#environment-configuration)
3. [Switching Between Environments](#switching-between-environments)
4. [Adding Secrets to GitHub](#adding-secrets-to-github)
5. [Troubleshooting](#troubleshooting)

## CI/CD Pipeline

The project uses GitHub Actions for continuous integration and deployment. There are two main workflows:

### CI Workflow (`.github<!-- /workflows/ci.yml - File not found -->`)

This workflow runs on every push to the `main` and `develop` branches, as well as on pull requests to these branches. It performs the following tasks:

1. **Test and Analyze**: Runs Flutter analysis and tests
2. **Build Android APK**: Builds an Android APK for testing
3. **Build iOS**: Builds an iOS app for testing (without code signing)

### CD Workflow (`.github<!-- <!-- /workflows/cd.yml - File not found --> - File not found -->`)

This workflow runs when a tag starting with `v` is pushed to the repository (e.g., `v1.0.0`). It performs the following tasks:

1. **Build Web App**: Builds the web app and uploads the artifacts
2. **Deploy Web App**: Deploys the web app to Vercel
3. **Deploy Android to Play Store**: Builds and uploads an Android app bundle to the Play Store

For detailed information on the release process, including how to trigger this workflow, see the [Release Process Guide](../../ci-cd/release-process.md).

#### Vercel Hosting Configuration

This project uses Vercel for web app hosting due to its:
- Generous build minute allocation (6,000 minutes/month on free tier)
- Excellent developer experience and deployment previews
- Global CDN with good performance
- EU regions for GDPR compliance
- Seamless integration with GitHub Actions

While the CD workflow is designed to support multiple hosting providers, we've selected Vercel as our primary provider. The workflow is configured to use Vercel by default, but can be modified if needed in the future.

To configure the hosting provider:

1. **Use GitHub Variables** (already set to `vercel`):
   - If you need to check: Go to your GitHub repository
   - Navigate to Settings > Secrets and variables > Actions > Variables
   - The variable `HOSTING_PROVIDER` should be set to `vercel`

2. **Edit the Workflow File** (if needed):
   - Alternatively, you can directly edit the `.github/workflows/cd.yml` file
   - Ensure the `HOSTING_PROVIDER` environment variable at the top of the file is set to `vercel`

## Environment Configuration

The project uses a configuration system to handle different environments (development, testing, production). The configuration files are located in the `lib/config` directory:

- `app_config.dart`: Base configuration class
- `dev_config.dart`: Development environment configuration
- `test_config.dart`: Testing environment configuration
- `prod_config.dart`: Production environment configuration
- `config_manager.dart`: Manager class for switching between environments

### Configuration Values

Each environment has its own configuration values:

| Configuration | Development | Testing | Production |
|---------------|-------------|---------|------------|
| Supabase URL | http://localhost:8000 | https://test-instance.supabase.co | https://ynpizhhrphzvhemqddvu.supabase.co |
| Logging | Enabled | Enabled | Disabled |

## Switching Between Environments

### Using VS Code

The project includes VS Code launch configurations for each environment. To switch between environments:

1. Open the Run and Debug panel in VS Code (Ctrl+Shift+D)
2. Select the environment from the dropdown at the top:
   - Development
   - Testing
   - Production
3. Click the Run button or press F5

### Using Command Line

You can also switch between environments using the command line:

```bash
# Run in development mode (default)
flutter run

# Run in testing mode
flutter run --dart-define=ENVIRONMENT=testing

# Run in production mode
flutter run --dart-define=ENVIRONMENT=production

# Build for production
flutter build apk --dart-define=ENVIRONMENT=production
```

### How It Works

The environment is set using the `--dart-define=ENVIRONMENT=value` flag. In `main.dart`, this value is read using `String.fromEnvironment('ENVIRONMENT', defaultValue: 'development')` and used to set the appropriate configuration.

## Adding Secrets to GitHub

For the CD workflow to work properly, you need to add the following secrets to your GitHub repository:

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Add the required secrets:

### Required Secrets

#### Common Secrets
- `PLAY_STORE_SERVICE_ACCOUNT_JSON`: Play Store service account JSON for Android deployment
- `SUPABASE_TEST_URL`: URL for the test Supabase instance
- `SUPABASE_TEST_ANON_KEY`: Anonymous key for the test Supabase instance
- `SUPABASE_PROD_URL`: URL for the production Supabase instance
- `SUPABASE_PROD_ANON_KEY`: Anonymous key for the production Supabase instance

#### Vercel Hosting Secrets
- `VERCEL_TOKEN`: Authentication token for Vercel
- `VERCEL_ORG_ID`: ID of your Vercel organization
- `VERCEL_PROJECT_ID`: ID of your Vercel project

### Setting Up Vercel Secrets

To obtain the required Vercel secrets:

1. **Create a Vercel Account** (if you don't have one):
   - Go to [vercel.com](https://vercel.com) and sign up
   - Create a new organization or use an existing one

2. **Create a New Project**:
   - Go to the Vercel dashboard
   - Click "Add New" > "Project"
   - Import your GitHub repository
   - Configure the project settings (Framework preset: Other)
   - Set the build command to: `cd build/web && find . -type f -name "*.js" -exec gzip -9 {} \; -exec mv {}.gz {} \;`
   - Set the output directory to: `build/web`

3. **Get Your Vercel Token**:
   - Go to your Vercel account settings
   - Navigate to "Tokens"
   - Create a new token with "Full Account" scope
   - Copy the token value (this will be your `VERCEL_TOKEN`)

4. **Get Organization and Project IDs**:
   - Run this command with your token:
     ```
     curl -H "Authorization: Bearer YOUR_VERCEL_TOKEN" https://api.vercel.com/v9/projects
     ```
   - From the response, find your project and note:
     - `orgId` (this will be your `VERCEL_ORG_ID`)
     - `id` (this will be your `VERCEL_PROJECT_ID`)

5. **Add Secrets to GitHub**:
   - Add the three Vercel secrets to your GitHub repository's secrets

### Optional: Other Hosting Providers

While we're using Vercel as our primary hosting provider, the CD workflow supports other providers if needed in the future. The secrets for these providers are documented below for reference:

<details>
<summary>Other Hosting Provider Secrets (Click to expand)</summary>

#### Firebase Hosting Secrets
- `FIREBASE_SERVICE_ACCOUNT`: Firebase service account JSON for web deployment

#### Netlify Hosting Secrets
- `NETLIFY_AUTH_TOKEN`: Authentication token for Netlify
- `NETLIFY_SITE_ID`: ID of your Netlify site

#### AWS Hosting Secrets
- `AWS_S3_BUCKET`: Name of your S3 bucket
- `AWS_ACCESS_KEY_ID`: AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key

#### Azure Hosting Secrets
- `AZURE_STATIC_WEB_APPS_API_TOKEN`: API token for Azure Static Web Apps

#### Custom Server Hosting Secrets
- `SSH_PRIVATE_KEY`: SSH private key for server access
- `SSH_KNOWN_HOSTS`: SSH known hosts file content
- `SSH_USER`: SSH username
- `SSH_HOST`: SSH host (server address)
- `SSH_PATH`: Path on the server to deploy to
</details>

## Troubleshooting

### CI Pipeline Failures

If the CI pipeline fails, check the following:

1. **Test Failures**: Look at the test logs to see which tests are failing
2. **Build Failures**: Check the build logs for errors
3. **Missing Secrets**: Ensure all required secrets are added to GitHub

### Environment Configuration Issues

If you're having issues with the environment configuration:

1. **Check the Current Environment**: Add a print statement to see which environment is being used:
   ```dart
   print('Current environment: ${ConfigManager.config.environment}');
   ```

2. **Verify Supabase Connection**: Check if Supabase is connecting properly:
   ```dart
   print('Supabase URL: ${ConfigManager.config.supabaseUrl}');
   ```

3. **Reset to Default**: If all else fails, you can reset to the development environment:
   ```dart
   ConfigManager.setEnvironment(Environment.development);
   ```

### Deployment Issues

If deployment fails:

1. **Vercel Deployment Issues**:
   - Check that all Vercel secrets are correctly configured in GitHub
   - Verify your Vercel token hasn't expired
   - Ensure the project exists in your Vercel account
   - Check Vercel build logs for specific error messages
   - Verify that your Flutter web build is compatible with Vercel's hosting

2. **Play Store Deployment Issues**:
   - Verify Play Store listing is ready for the app
   - Ensure the Play Store service account has the correct permissions
   - Check that the app version in `pubspec.yaml` is incremented properly

3. **General Deployment Troubleshooting**:
   - Check GitHub Actions logs for detailed error information
   - Verify all required secrets are correctly added to GitHub
   - Test the build locally before deploying

## Related Documentation

- [Release Process Guide](../../ci-cd/release-process.md): Detailed information on the release process
- [Testing Guide](testing-guide.md): Information on testing procedures
- [Development Guide](../../development/processes/development-guide.md): Guide for development processes

## GitHub Actions Workflow Files

The CI/CD pipeline is defined in the following GitHub Actions workflow files:

- [CI Workflow](/.github/workflows/ci.yml): Continuous integration workflow
- [CD Workflow](/.github/workflows/cd.yml): Continuous deployment workflow
- [Release Automation Workflow](/.github/workflows/release-automation.yml): Workflow for automating releases

## Documentation Change Log

| Date       | Author        | Changes                                      |
|------------|---------------|----------------------------------------------|
| 2025-04-28 | CI/CD Team    | Initial documentation created                |
| 2025-05-24 | AI Assistant  | Added links to related documentation and workflow files |
