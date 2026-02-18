#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates state file updates for Code Review Task (PF-TSK-006)

.DESCRIPTION
This script automates the manual state file updates required by the Code Review Task,
addressing the manual bottleneck for frequent development workflow updates.

Updates the following files:
- doc/process-framework/state-tracking/permanent/feature-tracking.md
- doc/process-framework/state-tracking/permanent/test-implementation-tracking.md

.PARAMETER FeatureId
The feature ID being reviewed (e.g., "1.2.3")

.PARAMETER ReviewStatus
The code review status (e.g., "Completed", "Needs Revision", "In Progress")

.PARAMETER ReviewDate
Date of the code review completion (optional - uses current date if not specified)

.PARAMETER ReviewerName
Name of the person who conducted the review

.PARAMETER ReviewDocumentPath
Path to the review document or report (optional)

.PARAMETER MajorFindings
Array of major findings from the code review (optional)

.PARAMETER TestStatusUpdate
Update to test status based on review findings (optional)

.PARAMETER SecurityIssues
Array of security issues identified (optional)

.PARAMETER PerformanceIssues
Array of performance issues identified (optional)

.PARAMETER CodeQualityScore
Code quality score from the review (1-10 scale, optional)

.PARAMETER DryRun
If specified, shows what would be updated without making changes

.EXAMPLE
.\Update-CodeReviewState.ps1 -FeatureId "1.2.3" -ReviewStatus "Completed" -ReviewerName "Jane Smith"

.EXAMPLE
.\Update-CodeReviewState.ps1 -FeatureId "1.2.3" -ReviewStatus "Needs Revision" -ReviewerName "John Doe" -MajorFindings @("Missing error handling", "Inconsistent naming") -DryRun

.EXAMPLE
.\Update-CodeReviewState.ps1 -FeatureId "1.2.3" -ReviewStatus "Completed" -ReviewerName "Alice Johnson" -CodeQualityScore 8 -ReviewDocumentPath "doc/reviews/review-1.2.3-feature.md"

.NOTES
This script addresses Process Improvement items:
- Manual bottleneck for PF-TSK-006 (2 files, frequent in development workflow)
- Improves efficiency for high-frequency code review updates

Created: 2025-08-23
Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureId,

    [Parameter(Mandatory=$true)]
    [ValidateSet("In Progress", "Completed", "Needs Revision", "Approved with Comments", "Rejected")]
    [string]$ReviewStatus,

    [Parameter(Mandatory=$true)]
    [string]$ReviewerName,

    [Parameter(Mandatory=$false)]
    [string]$ReviewDate,

    [Parameter(Mandatory=$false)]
    [string]$ReviewDocumentPath,

    [Parameter(Mandatory=$false)]
    [string[]]$MajorFindings = @(),

    [Parameter(Mandatory=$false)]
    [ValidateSet("No Change", "✅ Tests Implemented", "🔄 Needs Update", "🔴 Tests Failing")]
    [string]$TestStatusUpdate = "No Change",

    [Parameter(Mandatory=$false)]
    [string[]]$SecurityIssues = @(),

    [Parameter(Mandatory=$false)]
    [string[]]$PerformanceIssues = @(),

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 10)]
    [int]$CodeQualityScore,

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
    "Get-StateFileBackup"
)

if (-not $dependencyCheck.AllDependenciesMet) {
    Write-Error "Required dependencies not met. Please ensure Common-ScriptHelpers.psm1 is properly loaded."
    exit 1
}

# Main execution
try {
    Write-Host "Code Review State Update" -ForegroundColor Green
    Write-Host "========================" -ForegroundColor Green
    Write-Host "Feature ID: $FeatureId" -ForegroundColor Cyan
    Write-Host "Review Status: $ReviewStatus" -ForegroundColor Cyan
    Write-Host "Reviewer: $ReviewerName" -ForegroundColor Cyan

    if ($DryRun) {
        Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
        Write-Host ""
    }

    # Prepare update data
    $timestamp = Get-Date -Format "yyyy-MM-dd"
    if (-not $ReviewDate) {
        $ReviewDate = $timestamp
    }

    # Validate review document path if provided
    if ($ReviewDocumentPath) {
        $projectRoot = Get-ProjectRoot
        $fullDocumentPath = if ([System.IO.Path]::IsPathRooted($ReviewDocumentPath)) {
            $ReviewDocumentPath
        } else {
            Join-Path $projectRoot $ReviewDocumentPath
        }

        if (-not $DryRun -and -not (Test-Path $fullDocumentPath)) {
            Write-Warning "Review document not found at: $fullDocumentPath"
            Write-Host "Continuing with state updates..." -ForegroundColor Yellow
        }
    }

    # Create backup of all files before making changes
    if (-not $DryRun) {
        Write-Host "Creating backups..." -ForegroundColor Yellow
        $filesToBackup = @(
            "doc/process-framework/state-tracking/permanent/feature-tracking.md",
            "doc/process-framework/state-tracking/permanent/test-implementation-tracking.md"
        )

        $backupResult = Get-StateFileBackup -FilePaths $filesToBackup -BackupPrefix "code-review"
        Write-Host "Backup completed: $($backupResult.BackedUpFiles.Count) files backed up" -ForegroundColor Green
    }

    # Update 1: Feature Tracking
    Write-Host ""
    Write-Host "Updating Feature Tracking..." -ForegroundColor Yellow

    # Build additional updates for feature tracking
    $featureUpdates = @{
        "Review Date" = $ReviewDate
        "Reviewer" = $ReviewerName
        "Last Updated" = $timestamp
    }

    if ($ReviewDocumentPath) {
        $featureUpdates["Review Document"] = $ReviewDocumentPath
    }

    if ($CodeQualityScore) {
        $featureUpdates["Code Quality Score"] = "$CodeQualityScore/10"
    }

    # Combine all findings into a summary
    $allFindings = @()
    if ($MajorFindings.Count -gt 0) {
        $allFindings += $MajorFindings
    }
    if ($SecurityIssues.Count -gt 0) {
        $allFindings += $SecurityIssues | ForEach-Object { "Security: $_" }
    }
    if ($PerformanceIssues.Count -gt 0) {
        $allFindings += $PerformanceIssues | ForEach-Object { "Performance: $_" }
    }

    if ($allFindings.Count -gt 0) {
        $featureUpdates["Review Findings"] = $allFindings -join "; "
    }

    # Map review status to feature code review status
    $featureReviewStatus = switch ($ReviewStatus) {
        "In Progress" { "🔍 Review In Progress" }
        "Completed" { "✅ Review Completed" }
        "Needs Revision" { "🔄 Needs Revision" }
        "Approved with Comments" { "✅ Approved with Comments" }
        "Rejected" { "🔴 Review Rejected" }
    }

    $featureResult = Update-FeatureTrackingStatus -FeatureId $FeatureId -Status $featureReviewStatus -StatusColumn "Code Review" -AdditionalUpdates $featureUpdates -DryRun:$DryRun

    if ($DryRun) {
        Write-Host "  Would update feature tracking code review status to: $featureReviewStatus" -ForegroundColor Cyan
        foreach ($key in $featureUpdates.Keys) {
            Write-Host "    $key`: $($featureUpdates[$key])" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✅ Feature tracking updated successfully" -ForegroundColor Green
    }

    # Update 2: Test Implementation Tracking (if test status needs updating)
    if ($TestStatusUpdate -ne "No Change") {
        Write-Host ""
        Write-Host "Updating Test Implementation Tracking..." -ForegroundColor Yellow

        $testUpdates = @{
            "Review Impact" = "Updated based on code review findings"
            "Last Updated" = $timestamp
        }

        if ($ReviewerName) {
            $testUpdates["Reviewed By"] = $ReviewerName
        }

        # Add test-specific findings
        $testFindings = @()
        if ($MajorFindings.Count -gt 0) {
            $testRelatedFindings = $MajorFindings | Where-Object { $_ -match "test|mock|coverage|assertion" }
            if ($testRelatedFindings) {
                $testFindings += $testRelatedFindings
            }
        }

        if ($testFindings.Count -gt 0) {
            $testUpdates["Test Review Findings"] = $testFindings -join "; "
        }

        $testResult = Update-TestImplementationStatus -FeatureId $FeatureId -Status $TestStatusUpdate -AdditionalUpdates $testUpdates -DryRun:$DryRun

        if ($DryRun) {
            Write-Host "  Would update test implementation status to: $TestStatusUpdate" -ForegroundColor Cyan
            foreach ($key in $testUpdates.Keys) {
                Write-Host "    $key`: $($testUpdates[$key])" -ForegroundColor Gray
            }
        } else {
            Write-Host "  ✅ Test implementation tracking updated successfully" -ForegroundColor Green
        }
    } else {
        Write-Host ""
        Write-Host "Test Implementation Tracking: No changes requested" -ForegroundColor Gray
    }

    # Cross-reference synchronization
    Write-Host ""
    Write-Host "Synchronizing cross-references..." -ForegroundColor Yellow

    $syncResult = Sync-CrossReferencedFiles -FeatureId $FeatureId -SyncType "Feature" -DryRun:$DryRun

    if ($DryRun) {
        Write-Host "  Would synchronize cross-references across tracking files" -ForegroundColor Cyan
    } else {
        Write-Host "  ✅ Cross-references synchronized successfully" -ForegroundColor Green
    }

    # Summary
    Write-Host ""
    Write-Host "Code Review State Update Summary" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host "Feature ID: $FeatureId" -ForegroundColor White
    Write-Host "Review Status: $ReviewStatus" -ForegroundColor White
    Write-Host "Reviewer: $ReviewerName" -ForegroundColor White
    Write-Host "Review Date: $ReviewDate" -ForegroundColor White

    if ($ReviewDocumentPath) {
        Write-Host "Review Document: $ReviewDocumentPath" -ForegroundColor White
    }

    if ($CodeQualityScore) {
        Write-Host "Code Quality Score: $CodeQualityScore/10" -ForegroundColor White
    }

    if ($MajorFindings.Count -gt 0) {
        Write-Host "Major Findings:" -ForegroundColor White
        foreach ($finding in $MajorFindings) {
            Write-Host "  - $finding" -ForegroundColor Gray
        }
    }

    if ($SecurityIssues.Count -gt 0) {
        Write-Host "Security Issues:" -ForegroundColor Red
        foreach ($issue in $SecurityIssues) {
            Write-Host "  - $issue" -ForegroundColor Gray
        }
    }

    if ($PerformanceIssues.Count -gt 0) {
        Write-Host "Performance Issues:" -ForegroundColor Yellow
        foreach ($issue in $PerformanceIssues) {
            Write-Host "  - $issue" -ForegroundColor Gray
        }
    }

    if ($TestStatusUpdate -ne "No Change") {
        Write-Host "Test Status Update: $TestStatusUpdate" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "Files Updated:" -ForegroundColor White
    Write-Host "  ✅ feature-tracking.md" -ForegroundColor Green
    if ($TestStatusUpdate -ne "No Change") {
        Write-Host "  ✅ test-implementation-tracking.md" -ForegroundColor Green
    } else {
        Write-Host "  ➖ test-implementation-tracking.md (no changes requested)" -ForegroundColor Gray
    }

    if ($DryRun) {
        Write-Host ""
        Write-Host "DRY RUN COMPLETED - No actual changes were made" -ForegroundColor Yellow
        Write-Host "Run without -DryRun to apply these changes" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "✅ Code review state update completed successfully!" -ForegroundColor Green

        # Validation
        Write-Host ""
        Write-Host "Running validation..." -ForegroundColor Yellow
        $validationResult = Validate-StateFileConsistency -FeatureId $FeatureId -ValidationLevel "Basic"

        if ($validationResult.FailedChecks -eq 0) {
            Write-Host "✅ State file consistency validation passed" -ForegroundColor Green
        } else {
            Write-Host "⚠️  State file consistency issues detected - please review" -ForegroundColor Yellow
        }

        # Next steps guidance
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Yellow
        if ($ReviewStatus -eq "Needs Revision") {
            Write-Host "  1. Address the identified issues in the code" -ForegroundColor Gray
            Write-Host "  2. Update implementation based on review feedback" -ForegroundColor Gray
            Write-Host "  3. Request follow-up review when ready" -ForegroundColor Gray
        } elseif ($ReviewStatus -eq "Completed" -or $ReviewStatus -eq "Approved with Comments") {
            Write-Host "  1. Code review is complete and approved" -ForegroundColor Gray
            Write-Host "  2. Consider proceeding to deployment preparation" -ForegroundColor Gray
            if ($ReviewStatus -eq "Approved with Comments") {
                Write-Host "  3. Address minor comments in future iterations" -ForegroundColor Gray
            }
        } elseif ($ReviewStatus -eq "Rejected") {
            Write-Host "  1. Review the rejection reasons carefully" -ForegroundColor Gray
            Write-Host "  2. Consider significant refactoring or redesign" -ForegroundColor Gray
            Write-Host "  3. Discuss with reviewer before proceeding" -ForegroundColor Gray
        }

        if ($SecurityIssues.Count -gt 0) {
            Write-Host ""
            Write-Host "⚠️  SECURITY ISSUES IDENTIFIED - Address immediately!" -ForegroundColor Red
        }

        if ($PerformanceIssues.Count -gt 0) {
            Write-Host ""
            Write-Host "⚠️  Performance issues identified - Consider optimization" -ForegroundColor Yellow
        }
    }

}
catch {
    Write-Error "Code review state update failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "If backups were created, they can be found in:" -ForegroundColor Yellow
    Write-Host "  doc/process-framework/state-tracking/backups/" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
