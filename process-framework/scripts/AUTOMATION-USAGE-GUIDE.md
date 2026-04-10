# Process Framework Automation Usage Guide

## Overview

This guide provides instructions for using the new automation scripts that eliminate manual state file update bottlenecks in the Process Framework.

## Available Automation Scripts

### 1. update/Update-FeatureImplementationState.ps1

**Purpose**: Automates state file updates for Feature Implementation Planning Task (PF-TSK-044) and decomposed implementation tasks

**Files Updated**:

- `feature-tracking.md`
- `test-tracking.md`

**Basic Usage**:

```powershell
update\Update-FeatureImplementationState.ps1 -FeatureId "1.2.3" -Status "🟡 In Progress"
```

**Advanced Usage**:

```powershell
update\Update-FeatureImplementationState.ps1 -FeatureId "1.2.3" -Status "✅ Completed" -CompletionDate "2025-08-23" -ImplementationNotes "Added user authentication flow" -TestStatus "✅ Tests Implemented"
```

**Dry Run (Recommended First)**:

```powershell
update\Update-FeatureImplementationState.ps1 -FeatureId "1.2.3" -Status "🟡 In Progress" -DryRun
```

### 2. update/Update-TestFileAuditState.ps1

**Purpose**: Automates state file updates for individual test files during Test Audit Task (PF-TSK-030). Uses file path as identifier (SC-007 compliant).

**Files Updated**:

- `test-tracking.md` (individual test file status)
- `feature-tracking.md` (aggregated feature test status)

**Basic Usage**:

```powershell
update\Update-TestFileAuditState.ps1 -TestFilePath "test/automated/unit/test_service.py" -AuditStatus "Tests Approved"
```

**Advanced Usage**:

```powershell
update\Update-TestFileAuditState.ps1 -TestFilePath "test/automated/unit/test_service.py" -AuditStatus "Needs Update" -AuditorName "John Doe" -MajorFindings @("Missing edge case tests", "Incomplete mock coverage") -TestCasesAudited 15 -PassedTests 13 -FailedTests 2
```

### 3. update/Update-CodeReviewState.ps1

**Purpose**: Automates state file updates for Code Review Task (PF-TSK-005)

**Files Updated**:

- `feature-tracking.md`
- `test-tracking.md`

**Basic Usage**:

```powershell
update\Update-CodeReviewState.ps1 -FeatureId "1.2.3" -ReviewStatus "Completed" -ReviewerName "Jane Smith"
```

**Advanced Usage**:

```powershell
update\Update-CodeReviewState.ps1 -FeatureId "1.2.3" -ReviewStatus "Needs Revision" -ReviewerName "John Doe" -MajorFindings @("Missing error handling", "Inconsistent naming") -SecurityIssues @("SQL injection vulnerability") -CodeQualityScore 6
```

## Common Parameters

### Status Values

**Feature Implementation Status**:

- `🟡 In Progress`
- `✅ Completed`
- `🔄 Needs Update`
- `🔴 Blocked`

**Audit Status**:

- `Audit In Progress`
- `Tests Approved`
- `Needs Update`
- `Audit Failed`

**Review Status**:

- `In Progress`
- `Completed`
- `Needs Revision`
- `Approved with Comments`
- `Rejected`

### Safety Features

**Dry Run Mode**: Always available with `-DryRun` parameter

```powershell
update\Update-FeatureImplementationState.ps1 -FeatureId "1.2.3" -Status "🟡 In Progress" -DryRun
```

**Automatic Backups**: All scripts create backups before making changes

- Backups stored in: `process-framework-local/state-tracking/backups`
- Backup naming: `{script-name}-{timestamp}-{filename}`

**Validation**: All scripts include consistency validation after updates

## Best Practices

### 1. Always Use Dry Run First

```powershell
# Test what will be changed
update\Update-FeatureImplementationState.ps1 -FeatureId "1.2.3" -Status "🟡 In Progress" -DryRun

# Apply changes after reviewing dry run output
update\Update-FeatureImplementationState.ps1 -FeatureId "1.2.3" -Status "🟡 In Progress"
```

### 2. Use Descriptive Feature IDs

- Use semantic versioning: `1.2.3`, `2.1.0`
- Use descriptive names: `AUTH-001`, `UI-REFACTOR-001`
- Be consistent across all tracking files

### 3. Provide Context Information

```powershell
update\Update-FeatureImplementationState.ps1 -FeatureId "AUTH-001" -Status "✅ Completed" -ImplementationNotes "Implemented OAuth2 integration with Google and GitHub providers" -TestStatus "✅ Tests Implemented"
```

### 4. Review Script Output

- Scripts provide detailed summaries of changes made
- Check for any warnings or validation issues
- Verify cross-reference synchronization completed successfully

## Troubleshooting

### Common Issues

**1. Module Import Warnings**

`Import-Module` warnings should not be ignored — they indicate a fixable issue in the module code.

| Warning Message | Cause | Fix |
|----------------|-------|-----|
| "include unapproved verbs" | A function uses a verb not in PowerShell's approved list | Rename the function to use an approved verb (run `Get-Verb` for the full list) |
| "command name conflicts" | Two modules export a function with the same name | Use `-Prefix` on `Import-Module` or rename one function |
| Other warnings | Various module-level issues | Investigate and fix the root cause in the module |

> **Rule**: Do not suppress warnings with `-WarningAction SilentlyContinue` — fix the source instead.

**2. Dependency Check Failures**

```
Required dependencies not met. Please ensure Common-ScriptHelpers.psm1 is properly loaded.
```

- Ensure you're running the script from the correct directory
- Verify `Common-ScriptHelpers.psm1` exists in the same directory

**3. File Not Found Errors**

- Verify the feature ID exists in the target tracking files
- Check that tracking files exist at expected locations
- Use dry run mode to see what files would be updated

### Recovery from Issues

**1. Restore from Backup**

```powershell
# Backups are automatically created before changes
# Check backup directory: process-framework-local/state-tracking/backups
# Manually restore files if needed
```

**2. Validation Failures**

- Scripts include built-in validation
- Review validation output for specific issues
- Use dry run mode to test fixes

## Integration with Process Framework Tasks

### PF-TSK-044: Feature Implementation Planning

```powershell
# Start implementation
update\Update-FeatureImplementationState.ps1 -FeatureId "NEW-FEATURE" -Status "🟡 In Progress"

# Complete implementation
update\Update-FeatureImplementationState.ps1 -FeatureId "NEW-FEATURE" -Status "✅ Completed" -TestStatus "✅ Tests Implemented"
```

### PF-TSK-030: Test Audit

```powershell
# Start audit for individual test file
update\Update-TestFileAuditState.ps1 -TestFilePath "test/automated/unit/test_example.py" -AuditStatus "Audit In Progress" -AuditorName "Your Name"

# Complete audit
update\Update-TestFileAuditState.ps1 -TestFilePath "test/automated/unit/test_example.py" -AuditStatus "Tests Approved" -TestCasesAudited 20 -PassedTests 18 -FailedTests 2
```

### PF-TSK-005: Code Review

```powershell
# Complete review
update\Update-CodeReviewState.ps1 -FeatureId "FEATURE-ID" -ReviewStatus "Completed" -ReviewerName "Reviewer Name" -CodeQualityScore 8
```

### PF-TSK-031, 032, 033, 034: Validation Tasks

```powershell
# Start individual validation
update\Update-ValidationReportState.ps1 -ValidationId "VAL-031-001" -ValidationStatus "Validation In Progress" -ValidatorName "AI Agent"

# Complete validation with findings
update\Update-ValidationReportState.ps1 -ValidationId "VAL-031-001" -ValidationStatus "Validation Completed" -ValidatorName "AI Agent" -ValidationScore 8 -ValidationFindings @("Minor issues found", "Overall good quality")

# Batch validation processing
.\Start-BatchValidation.ps1 -ValidationType "Architectural" -FeatureIds @("0.2.1", "0.2.2", "0.2.3") -ValidatorName "AI Agent"
```

### Batch Processing Workflows

```powershell
# Batch audit for feature category
.\Start-BatchAudit.ps1 -FeatureIds @("1.2.1", "1.2.2", "1.2.3") -AuditorName "AI Agent" -FeatureCategory "Authentication"

# Sprint completion update
update\Update-BatchFeatureStatus.ps1 -FeatureIds @("2.1.1", "2.1.2", "2.1.3") -Status "🟢 Completed" -UpdateType "Sprint" -SprintId "Sprint-2025-08"

# Release preparation
update\Update-BatchFeatureStatus.ps1 -FeatureIds @("1.1.1", "1.1.2", "1.1.3") -Status "🟢 Completed" -UpdateType "Release" -ReleaseVersion "v1.1.0"
```

### 4. update/Update-ValidationReportState.ps1

**Purpose**: Automates state file updates for Validation Tasks (PF-TSK-031, 032, 033, 034)

**Files Updated**:

- `validation-tracking.md`
- `PF-documentation-map.md`
- `feature-tracking.md` (cross-references)

**Basic Usage**:

```powershell
update\Update-ValidationReportState.ps1 -ValidationId "VAL-031-001" -ValidationStatus "Validation In Progress" -ValidatorName "AI Agent"
```

**Advanced Usage**:

```powershell
update\Update-ValidationReportState.ps1 -ValidationId "VAL-031-001" -ValidationStatus "Validation Completed" -ValidatorName "AI Agent" -ValidationScore 8 -ValidationFindings @("Minor pattern inconsistencies", "Good overall architecture") -FeatureId "0.2.1"
```

### 5. Start-BatchValidation.ps1

**Purpose**: Processes multiple features for validation in batch operations

**Basic Usage**:

```powershell
.\Start-BatchValidation.ps1 -ValidationType "Architectural" -FeatureIds @("0.2.1", "0.2.2", "0.2.3") -ValidatorName "AI Agent"
```

**Advanced Usage**:

```powershell
.\Start-BatchValidation.ps1 -ValidationType "CodeQuality" -FeatureIds @("0.2.4", "0.2.5") -ValidatorName "AI Agent" -BatchSize 2 -ContinueOnError -DryRun
```

### 6. Start-BatchAudit.ps1

**Purpose**: Processes multiple test files for audit in batch operations

**Basic Usage**:

```powershell
.\Start-BatchAudit.ps1 -FeatureIds @("1.2.1", "1.2.2", "1.2.3") -AuditorName "AI Agent" -FeatureCategory "Authentication"
```

**Advanced Usage**:

```powershell
.\Start-BatchAudit.ps1 -FeatureIds @("0.2.1", "0.2.2", "0.2.3", "0.2.4") -AuditorName "AI Agent" -FeatureCategory "Foundation" -DetailedReporting -ContinueOnError
```

### 7. update/Update-BatchFeatureStatus.ps1

**Purpose**: Updates multiple features simultaneously across all tracking files

**Basic Usage**:

```powershell
update\Update-BatchFeatureStatus.ps1 -FeatureIds @("1.2.1", "1.2.2", "1.2.3") -Status "🟢 Completed" -UpdateType "StatusOnly"
```

**Advanced Usage**:

```powershell
update\Update-BatchFeatureStatus.ps1 -FeatureIds @("2.1.1", "2.1.2", "2.1.3") -Status "🟢 Completed" -UpdateType "Sprint" -SprintId "Sprint-2025-08" -UpdateNotes "Sprint 8 completion" -Force
```

### 8. Start-AutomationMenu.ps1

**Purpose**: Interactive menu system for script selection and execution

**Basic Usage**:

```powershell
.\Start-AutomationMenu.ps1
```

**Advanced Usage**:

```powershell
.\Start-AutomationMenu.ps1 -ShowAdvanced -DryRun
```

## Advanced Features

### Interactive Menu System

The `Start-AutomationMenu.ps1` provides a user-friendly interface for script selection with guided parameter input and validation.

### Batch Operations

The underlying infrastructure supports batch operations through `Update-MultipleTrackingFiles` function, with dedicated batch processing scripts for validation, auditing, and status updates.

### Cross-Reference Synchronization

All scripts automatically synchronize cross-references between tracking files to maintain consistency.

### Conflict Resolution

Scripts include conflict detection and resolution for concurrent updates.

### Performance Monitoring

Built-in performance monitoring tracks execution times, success rates, and system health metrics.

## Support and Feedback

For issues or enhancement requests:

1. Check this guide for common solutions
2. Review script output for specific error messages
3. Use dry run mode to diagnose issues
4. Create feedback forms following Process Framework guidelines

---

**Created**: 2025-08-23
**Updated**: 2025-08-23
**Version**: 1.2 (Phase 3B - Workflow Integration & User Experience)
**Related Implementation**: ~~Automation Enhancement Phase 3A~~ *(state files archived)* | ~~Phase 3B Implementation~~ *(state files archived)*
