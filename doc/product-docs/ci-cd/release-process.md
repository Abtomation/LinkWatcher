---
id: PD-CIC-003
type: Documentation
version: 1.0
created: 2023-06-15
updated: 2023-06-15
---

# Release Process Guide

This document outlines the release process for BreakoutBuddies, which is now automated using GitHub Actions.

## Automated Release Process

The release process is automated using the Release Automation workflow in GitHub Actions. This workflow:

1. Bumps the version number in `pubspec.yaml` and platform-specific files
2. Generates a changelog from commit messages
3. Creates a pull request for the release

### Prerequisites

Before starting a release:

1. Ensure all features for the release are merged into the `develop` branch
2. Make sure all tests are passing on the `develop` branch (see [Testing Guide](../guides/guides/testing-guide.md))
3. Verify that the app is working as expected according to the [Definition of Done](../../process-framework/methodologies/definition-of-done.md)

### Starting a Release

To start a new release:

1. Go to the "Actions" tab in the GitHub repository
2. Select the "Release Automation" workflow (see [CI/CD Environment Guide](../guides/guides/ci-cd-environment-guide.md) for details)
3. Click "Run workflow"
4. Configure the workflow:
   - **Version type**: Choose from `patch` (0.0.x), `minor` (0.x.0), or `major` (x.0.0)
   - **Base branch**: Usually `develop` (the branch to create the release from)
5. Click "Run workflow" to start the process

### Review and Merge the Release PR

Once the workflow completes:

1. A pull request will be created from a branch named `prepare-release-x.y.z` to the base branch
2. Review the changes in the PR:
   - Version bump in `pubspec.yaml`
   - Updated changelog
   - Version updates in platform-specific files
3. Complete the checklist in the PR description
4. Merge the PR into the base branch (usually `develop`)

### Create the Release

After merging the PR:

1. Create a PR from `develop` to `main` (if not already done)
2. After merging to `main`, create and push a tag:
   ```bash
   git checkout main
   git pull
   git tag vX.Y.Z  # Use the actual version number
   git push origin vX.Y.Z
   ```
3. This tag will trigger the CD workflow, which will:
   - Build the app for all platforms
   - Deploy to app stores and web hosting
   - Run automated deployment verification tests (see <!-- [CI/CD Environment Guide](../guides/guides/ci-cd-environment-guide.md#deployment-verification) - File not found -->)

## Manual Release Process (Fallback)

If you need to perform a release manually:

1. Update the version in `pubspec.yaml`
2. Update the changelog
3. Update version in platform-specific files:
   - Android: `android<!-- /app/build.gradle - File not found -->`
   - iOS: `ios/ios/Runner/Info.plist`
4. Commit the changes:
   ```bash
   git commit -m "chore: prepare release X.Y.Z"
   ```
5. Create a tag:
   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

## Release Checklist

Before finalizing a release:

- [ ] All features for the release are complete and tested according to the [Testing Checklist](../checklists/checklists/testing-checklist.md)
- [ ] All tests are passing in the CI pipeline (see [CI/CD Environment Guide](../guides/guides/ci-cd-environment-guide.md))
- [ ] The app has been tested on all target platforms
- [ ] Release notes are prepared for app stores
- [ ] Marketing materials are ready (if applicable)
- [ ] Support team is briefed on new features and changes

## Post-Release Tasks

After a successful release:

1. Monitor app performance and crash reports
2. Address any critical issues with hotfixes if needed
3. Update documentation to reflect new features
4. Plan the next release cycle

## Release Cadence

- **Patch releases** (0.0.x): As needed for bug fixes
- **Minor releases** (0.x.0): Every 2-4 weeks for new features
- **Major releases** (x.0.0): Every 3-6 months for significant changes

## Related Documentation

- [Development Guide](../guides/guides/development-guide.md)
- [CI/CD Environment Guide](../guides/guides/ci-cd-environment-guide.md)
- [Testing Guide](../guides/guides/testing-guide.md)
- [Testing Checklist](../checklists/checklists/testing-checklist.md)
- [Definition of Done](../../process-framework/methodologies/definition-of-done.md)
