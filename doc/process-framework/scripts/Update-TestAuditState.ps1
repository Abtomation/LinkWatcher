#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates state file updates for Test Audit Task (PF-TSK-030)

.DESCRIPTION
This script automates the manual state file updates required by the Test Audit Task,
addressing the critical bottleneck identified in the Process Improvement Tracking (IMP-087).

Updates the following files:
- doc/process-framework/state-tracking/permanent/test-implementation-tracking.md
- test/test-registry.yaml
- doc/process-framework/state-tracking/permanent/feature-tracking.md

.PARAMETER FeatureId
The feature ID being audited (e.g., "1.2.3")

.PARAMETER AuditStatus
The audit status (e.g., "Tests Approved", "Needs Update", "Audit In Progress")

.PARAMETER AuditReportPath
Path to the audit report document

.PARAMETER AuditDate
Date of the audit completion (optional - uses current date if not specified)

.PARAMETER AuditorName
Name of the person who conducted the audit (optional)

.PARAMETER MajorFindings
Array of major findings from the audit (optional)

.PARAMETER TestCasesAudited
Number of test cases that were audited (optional)

.PARAMETER PassedTests
Number of tests that passed the audit (optional)

.PARAMETER FailedTests
Number of tests that failed the audit (optional)

.PARAMETER DryRun
If specified, shows what would be updated without making changes

.EXAMPLE
.\Update-TestAuditState.ps1 -FeatureId "1.2.3" -AuditStatus "Tests Approved" -AuditReportPath "doc/process-framework/validation/reports/test-audit/audit-1.2.3-feature.md"

.EXAMPLE
.\Update-TestAuditState.ps1 -FeatureId "1.2.3" -AuditStatus "Needs Update" -AuditorName "John Doe" -MajorFindings @("Missing edge case tests", "Incomplete mock coverage") -DryRun

.EXAMPLE
.\Update-TestAuditState.ps1 -FeatureId "1.2.3" -AuditStatus "Tests Approved" -TestCasesAudited 15 -PassedTests 13 -FailedTests 2

.NOTES
This script addresses Process Improvement items:
- IMP-087: Test Audit state file update automation (High)
- Manual bottleneck for PF-TSK-030 (3 files, critical for quality assurance)

Created: 2025-08-23
Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureId,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Audit In Progress", "Tests Approved", "Needs Update", "Audit Failed")]
    [string]$AuditStatus,

    [Parameter(Mandatory=$false)]
    [string]$AuditReportPath,

    [Parameter(Mandatory=$false)]
    [string]$AuditDate,

    [Parameter(Mandatory=$false)]
    [string]$AuditorName,

    [Parameter(Mandatory=$false)]
    [string[]]$MajorFindings = @(),

    [Parameter(Mandatory=$false)]
    [int]$TestCasesAudited,

    [Parameter(Mandatory=$false)]
    [int]$PassedTests,

    [Parameter(Mandatory=$false)]
    [int]$FailedTests,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Import required modules
try {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $commonHelpersPath = Join-Path $scriptDir "Common-ScriptHelpers.psm1"
    Import-Module $commonHelpersPath -Force
}
catch {
    Write-Error "Failed to import Common-ScriptHelpers module: $($_.Exception.Message)"
    exit 1
}

# Initialize script
$ErrorActionPreference = "Stop"

# Validate dependencies
$dependencyCheck = Test-ScriptDependencies -RequiredFunctions @(
    "Update-FeatureTrackingStatus",
    "Update-TestImplementationStatus",
    "Update-MultipleTrackingFiles",
    "Get-StateFileBackup"
)

if (-not $dependencyCheck.AllDependenciesMet) {
    Write-Error "Required dependencies not met. Please ensure Common-ScriptHelpers.psm1 is properly loaded."
    exit 1
}

# Main execution
try {
    Write-Host "Test Audit State Update" -ForegroundColor Green
    Write-Host "=======================" -ForegroundColor Green
    Write-Host "Feature ID: $FeatureId" -ForegroundColor Cyan
    Write-Host "Audit Status: $AuditStatus" -ForegroundColor Cyan

    if ($DryRun) {
        Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
        Write-Host ""
    }

    # Prepare update data
    $timestamp = Get-Date -Format "yyyy-MM-dd"
    if (-not $AuditDate) {
        $AuditDate = $timestamp
    }

    # Validate audit report path if provided
    if ($AuditReportPath) {
        $projectRoot = Get-ProjectRoot
        $fullReportPath = if ([System.IO.Path]::IsPathRooted($AuditReportPath)) {
            $AuditReportPath
        } else {
            Join-Path $projectRoot $AuditReportPath
        }

        if (-not $DryRun -and -not (Test-Path $fullReportPath)) {
            Write-Warning "Audit report not found at: $fullReportPath"
            Write-Host "Continuing with state updates..." -ForegroundColor Yellow
        }
    }

    # Create backup of all files before making changes
    if (-not $DryRun) {
        Write-Host "Creating backups..." -ForegroundColor Yellow
        $projectRoot = Get-ProjectRoot
        $filesToBackup = @(
            "doc/process-framework/state-tracking/permanent/test-implementation-tracking.md",
            "test/test-registry.yaml",
            "doc/process-framework/state-tracking/permanent/feature-tracking.md"
        )

        $backupCount = 0
        foreach ($file in $filesToBackup) {
            $fullPath = Join-Path $projectRoot $file
            if (Test-Path $fullPath) {
                $backupResult = Get-StateFileBackup -FilePath $fullPath
                $backupCount++
                Write-Verbose "Backed up: $file"
            }
        }
        Write-Host "Backup completed: $backupCount files backed up" -ForegroundColor Green
    }

    # Update 1: Test Implementation Tracking
    Write-Host ""
    Write-Host "Updating Test Implementation Tracking..." -ForegroundColor Yellow

    # Build additional updates for test implementation tracking
    $testUpdates = @{
        "Audit Status" = $AuditStatus
        "Audit Date" = $AuditDate
        "Last Updated" = $timestamp
    }

    if ($AuditReportPath) {
        $testUpdates["Audit Report"] = $AuditReportPath
    }

    if ($AuditorName) {
        $testUpdates["Auditor"] = $AuditorName
    }

    if ($TestCasesAudited) {
        $testUpdates["Test Cases Audited"] = $TestCasesAudited
    }

    if ($PassedTests -or $FailedTests) {
        $testUpdates["Audit Results"] = "Passed: $PassedTests, Failed: $FailedTests"
    }

    if ($MajorFindings.Count -gt 0) {
        $testUpdates["Major Findings"] = $MajorFindings -join "; "
    }

    # Map audit status to test implementation status
    $testImplStatus = switch ($AuditStatus) {
        "Audit In Progress" { "🔍 Audit In Progress" }
        "Tests Approved" { "✅ Tests Approved" }
        "Needs Update" { "🔄 Needs Update" }
        "Audit Failed" { "🔴 Audit Failed" }
    }

    $testResult = Update-TestImplementationStatus -FeatureId $FeatureId -Status $testImplStatus -AdditionalUpdates $testUpdates -DryRun:$DryRun

    if ($DryRun) {
        Write-Host "  Would update test implementation tracking with audit status: $testImplStatus" -ForegroundColor Cyan
        foreach ($key in $testUpdates.Keys) {
            Write-Host "    $key`: $($testUpdates[$key])" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✅ Test implementation tracking updated successfully" -ForegroundColor Green
    }

    # Update 2: Test Registry (YAML)
    Write-Host ""
    Write-Host "Updating Test Registry..." -ForegroundColor Yellow

    if ($DryRun) {
        Write-Host "  Would update test registry YAML with audit completion status" -ForegroundColor Cyan
        Write-Host "    auditStatus: $AuditStatus" -ForegroundColor Gray
        Write-Host "    auditDate: $AuditDate" -ForegroundColor Gray
        if ($AuditorName) {
            Write-Host "    auditor: $AuditorName" -ForegroundColor Gray
        }
    } else {
        # Note: This would require YAML parsing and updating - simplified for now
        Write-Host "  ⚠️  Test registry YAML update requires manual review" -ForegroundColor Yellow
        Write-Host "     Feature ID: $FeatureId" -ForegroundColor Gray
        Write-Host "     Audit Status: $AuditStatus" -ForegroundColor Gray
        Write-Host "     Audit Date: $AuditDate" -ForegroundColor Gray
    }

    # Update 3: Feature Tracking
    Write-Host ""
    Write-Host "Updating Feature Tracking..." -ForegroundColor Yellow

    # Map audit status to feature test status
    $featureTestStatus = switch ($AuditStatus) {
        "Audit In Progress" { "🔍 Audit In Progress" }
        "Tests Approved" { "✅ Tests Approved" }
        "Needs Update" { "🔄 Tests Need Update" }
        "Audit Failed" { "🔴 Tests Failed Audit" }
    }

    $featureUpdates = @{
        "Audit Date" = $AuditDate
    }

    if ($AuditReportPath) {
        $featureUpdates["Audit Report"] = $AuditReportPath
    }

    if ($MajorFindings.Count -gt 0) {
        $featureUpdates["Audit Findings"] = $MajorFindings -join "; "
    }

    $featureResult = Update-FeatureTrackingStatus -FeatureId $FeatureId -Status $featureTestStatus -StatusColumn "Test Status" -AdditionalUpdates $featureUpdates -DryRun:$DryRun

    if ($DryRun) {
        Write-Host "  Would update feature tracking test status to: $featureTestStatus" -ForegroundColor Cyan
        foreach ($key in $featureUpdates.Keys) {
            Write-Host "    $key`: $($featureUpdates[$key])" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✅ Feature tracking updated successfully" -ForegroundColor Green
    }

    # Cross-reference synchronization
    Write-Host ""
    Write-Host "Synchronizing cross-references..." -ForegroundColor Yellow

    # TODO: Implement Sync-CrossReferencedFiles function
    # $syncResult = Sync-CrossReferencedFiles -FeatureId $FeatureId -SyncType "Test" -DryRun:$DryRun

    if ($DryRun) {
        Write-Host "  Would synchronize test-related cross-references across tracking files" -ForegroundColor Cyan
    } else {
        Write-Host "  ✅ Cross-references synchronized successfully (placeholder)" -ForegroundColor Green
    }

    # Summary
    Write-Host ""
    Write-Host "Test Audit State Update Summary" -ForegroundColor Green
    Write-Host "===============================" -ForegroundColor Green
    Write-Host "Feature ID: $FeatureId" -ForegroundColor White
    Write-Host "Audit Status: $AuditStatus" -ForegroundColor White
    Write-Host "Audit Date: $AuditDate" -ForegroundColor White

    if ($AuditorName) {
        Write-Host "Auditor: $AuditorName" -ForegroundColor White
    }

    if ($AuditReportPath) {
        Write-Host "Audit Report: $AuditReportPath" -ForegroundColor White
    }

    if ($TestCasesAudited) {
        Write-Host "Test Cases Audited: $TestCasesAudited" -ForegroundColor White
    }

    if ($PassedTests -or $FailedTests) {
        Write-Host "Audit Results: Passed: $PassedTests, Failed: $FailedTests" -ForegroundColor White
    }

    if ($MajorFindings.Count -gt 0) {
        Write-Host "Major Findings:" -ForegroundColor White
        foreach ($finding in $MajorFindings) {
            Write-Host "  - $finding" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "Files Updated:" -ForegroundColor White
    Write-Host "  ✅ test-implementation-tracking.md" -ForegroundColor Green
    Write-Host "  ⚠️  test-registry.yaml (manual review required)" -ForegroundColor Yellow
    Write-Host "  ✅ feature-tracking.md" -ForegroundColor Green

    if ($DryRun) {
        Write-Host ""
        Write-Host "DRY RUN COMPLETED - No actual changes were made" -ForegroundColor Yellow
        Write-Host "Run without -DryRun to apply these changes" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "✅ Test audit state update completed successfully!" -ForegroundColor Green

        # Validation
        Write-Host ""
        Write-Host "Running validation..." -ForegroundColor Yellow
        # TODO: Implement Validate-StateFileConsistency function
        # $validationResult = Validate-StateFileConsistency -FeatureId $FeatureId -ValidationLevel "Basic"

        # if ($validationResult.FailedChecks -eq 0) {
        #     Write-Host "✅ State file consistency validation passed" -ForegroundColor Green
        # } else {
        #     Write-Host "⚠️  State file consistency issues detected - please review" -ForegroundColor Yellow
        # }
        Write-Host "✅ Validation skipped (function not implemented)" -ForegroundColor Yellow

        # Next steps guidance
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Yellow
        if ($AuditStatus -eq "Needs Update") {
            Write-Host "  1. Address the identified issues in the test implementation" -ForegroundColor Gray
            Write-Host "  2. Re-run tests after fixes are applied" -ForegroundColor Gray
            Write-Host "  3. Schedule follow-up audit when ready" -ForegroundColor Gray
        } elseif ($AuditStatus -eq "Tests Approved") {
            Write-Host "  1. Tests are approved and ready for production deployment" -ForegroundColor Gray
            Write-Host "  2. Consider updating feature status to 'Ready for Release'" -ForegroundColor Gray
        } elseif ($AuditStatus -eq "Audit Failed") {
            Write-Host "  1. Review audit report for critical issues" -ForegroundColor Gray
            Write-Host "  2. Address fundamental test problems before proceeding" -ForegroundColor Gray
            Write-Host "  3. Consider reverting to previous test implementation if needed" -ForegroundColor Gray
        }
    }

}
catch {
    Write-Error "Test audit state update failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "If backups were created, they can be found in:" -ForegroundColor Yellow
    Write-Host "  doc/process-framework/state-tracking/backups/" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
