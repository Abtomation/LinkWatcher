#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates state file updates for Feature Implementation Planning Task (PF-TSK-044)

.DESCRIPTION
This script automates the manual state file updates required by the Feature Implementation Task,
addressing the critical bottleneck identified in the Process Improvement Tracking (IMP-067).

Updates the following files:
- ../doc/state-tracking/permanent/feature-tracking.md
- ../doc/test/state-tracking/permanent/test-tracking.md

.PARAMETER FeatureId
The feature ID to update (e.g., "1.2.3")

.PARAMETER Status
The implementation status (e.g., "🟡 In Progress", "🔄 Needs Enhancement", "🟢 Completed")

.PARAMETER StartDate
Implementation start date (optional - uses current date if not specified)

.PARAMETER CompletionDate
Implementation completion date (optional - only for completed features)

.PARAMETER PullRequestUrl
URL to the pull request or commit (optional)

.PARAMETER DesignDeviations
Description of any design deviations with justification (optional)

.PARAMETER NewComponents
Array of new components added during implementation (optional)

.PARAMETER NewDependencies
Array of new dependencies created during implementation (optional)

.PARAMETER DryRun
If specified, shows what would be updated without making changes

.EXAMPLE
.\Update-FeatureImplementationState.ps1 -FeatureId "1.2.3" -Status "🟡 In Progress"

.EXAMPLE
.\Update-FeatureImplementationState.ps1 -FeatureId "1.2.3" -Status "🟢 Completed" -CompletionDate "2025-08-23" -PullRequestUrl "https:/github.com/repo/pull/123"

.EXAMPLE
.\Update-FeatureImplementationState.ps1 -FeatureId "1.2.3" -Status "🔄 Needs Enhancement" -DesignDeviations "Modified authentication flow for better UX" -DryRun

.NOTES
This script addresses Process Improvement items:
- IMP-067: Foundation Feature Implementation state file automation (Critical)
- Manual bottleneck for feature implementation tasks (3 files each, high frequency)

Created: 2025-08-23
Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("🟡 In Progress", "👀 Needs Review", "🔄 Needs Enhancement", "🟢 Completed")]
    [string]$Status,

    [Parameter(Mandatory = $false)]
    [string]$StartDate,

    [Parameter(Mandatory = $false)]
    [string]$CompletionDate,

    [Parameter(Mandatory = $false)]
    [string]$PullRequestUrl,

    [Parameter(Mandatory = $false)]
    [string]$DesignDeviations,

    [Parameter(Mandatory = $false)]
    [string[]]$NewComponents = @(),

    [Parameter(Mandatory = $false)]
    [string[]]$NewDependencies = @(),

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Import required modules with walk-up path resolution
try {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $dir = $scriptDir
    while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
        $dir = Split-Path -Parent $dir
    }
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force
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
    Write-Host "Feature Implementation State Update" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "Feature ID: $FeatureId" -ForegroundColor Cyan
    Write-Host "Status: $Status" -ForegroundColor Cyan

    if ($DryRun) {
        Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
        Write-Host ""
    }

    # Prepare update data
    $timestamp = Get-Date -Format "yyyy-MM-dd"
    $updateData = @{
        FeatureId = $FeatureId
        Status    = $Status
        Timestamp = $timestamp
    }

    # Set dates based on status
    if (-not $StartDate -and $Status -eq "🟡 In Progress") {
        $StartDate = $timestamp
    }

    if ($Status -eq "🟢 Completed" -and -not $CompletionDate) {
        $CompletionDate = $timestamp
    }

    # Build additional updates for feature tracking
    $featureUpdates = @{}

    if ($StartDate) {
        $featureUpdates["Implementation Start"] = $StartDate
    }

    if ($CompletionDate) {
        $featureUpdates["Implementation Completion"] = $CompletionDate
    }

    if ($PullRequestUrl) {
        $featureUpdates["Pull Request"] = $PullRequestUrl
    }

    if ($DesignDeviations) {
        $featureUpdates["Design Deviations"] = $DesignDeviations
    }

    # Create backup of all files before making changes
    if (-not $DryRun) {
        Write-Host "Creating backups..." -ForegroundColor Yellow
        $projectRoot = Get-ProjectRoot
        $filesToBackup = @(
            "doc/state-tracking/permanent/feature-tracking.md",
            "test/state-tracking/permanent/test-tracking.md"
        )

        $backupResult = Get-StateFileBackup -FilePaths $filesToBackup -BackupPrefix "feature-implementation"
        Write-Host "Backup completed: $($backupResult.BackedUpFiles.Count) files backed up" -ForegroundColor Green
    }

    # Update 1: Feature Tracking
    Write-Host ""
    Write-Host "Updating Feature Tracking..." -ForegroundColor Yellow

    $featureResult = Update-FeatureTrackingStatus -FeatureId $FeatureId -Status $Status -StatusColumn "Implementation Status" -AdditionalUpdates $featureUpdates -DryRun:$DryRun

    if ($DryRun) {
        Write-Host "  Would update feature tracking with implementation status" -ForegroundColor Cyan
    }
    else {
        Write-Host "  ✅ Feature tracking updated successfully" -ForegroundColor Green
    }

    # Update 2: Test Tracking (if test status needs updating)
    Write-Host ""
    Write-Host "Updating Test Tracking..." -ForegroundColor Yellow

    $testStatus = switch ($Status) {
        "🟡 In Progress" { "🟡 Implementation In Progress" }
        "🔄 Needs Enhancement" { "🔄 Needs Update" }
        "🟢 Completed" { "✅ Audit Approved" }
    }

    $testResult = Update-TestImplementationStatus -FeatureId $FeatureId -Status $testStatus -DryRun:$DryRun

    if ($DryRun) {
        Write-Host "  Would update test implementation status to: $testStatus" -ForegroundColor Cyan
    }
    else {
        Write-Host "  ✅ Test implementation tracking updated successfully" -ForegroundColor Green
    }

    # Update 3: Component Relationship Index (if new components or dependencies)
    if ($NewComponents.Count -gt 0 -or $NewDependencies.Count -gt 0) {
        Write-Host ""
        Write-Host "Updating Component Relationship Index..." -ForegroundColor Yellow

        if ($DryRun) {
            Write-Host "  Would add new components: $($NewComponents -join ', ')" -ForegroundColor Cyan
            Write-Host "  Would add new dependencies: $($NewDependencies -join ', ')" -ForegroundColor Cyan
        }
        else {
            # Note: This would require more complex implementation to parse and update the component index
            Write-Host "  ⚠️  Component relationship updates require manual review" -ForegroundColor Yellow
            Write-Host "     New Components: $($NewComponents -join ', ')" -ForegroundColor Gray
            Write-Host "     New Dependencies: $($NewDependencies -join ', ')" -ForegroundColor Gray
        }
    }

    # Cross-reference synchronization
    Write-Host ""
    Write-Host "Synchronizing cross-references..." -ForegroundColor Yellow

    $syncResult = Sync-CrossReferencedFiles -FeatureId $FeatureId -SyncType "Feature" -DryRun:$DryRun

    if ($DryRun) {
        Write-Host "  Would synchronize cross-references across tracking files" -ForegroundColor Cyan
    }
    else {
        Write-Host "  ✅ Cross-references synchronized successfully" -ForegroundColor Green
    }

    # Update workflow tracking (Impl Status column derives from feature statuses)
    $workflowScript = Join-Path $PSScriptRoot "Update-WorkflowTracking.ps1"
    if (Test-Path $workflowScript) {
        Write-Host ""
        Write-Host "Updating workflow tracking..." -ForegroundColor Yellow
        if ($DryRun) {
            & $workflowScript -ProjectRoot $projectRoot -WhatIf
        } else {
            & $workflowScript -ProjectRoot $projectRoot
        }
    }

    # Summary
    Write-Host ""
    Write-Host "Feature Implementation State Update Summary" -ForegroundColor Green
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host "Feature ID: $FeatureId" -ForegroundColor White
    Write-Host "New Status: $Status" -ForegroundColor White

    if ($StartDate) {
        Write-Host "Start Date: $StartDate" -ForegroundColor White
    }

    if ($CompletionDate) {
        Write-Host "Completion Date: $CompletionDate" -ForegroundColor White
    }

    if ($PullRequestUrl) {
        Write-Host "Pull Request: $PullRequestUrl" -ForegroundColor White
    }

    if ($DesignDeviations) {
        Write-Host "Design Deviations: $DesignDeviations" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "Files Updated:" -ForegroundColor White
    Write-Host "  ✅ feature-tracking.md" -ForegroundColor Green
    Write-Host "  ✅ test-tracking.md" -ForegroundColor Green

    if ($DryRun) {
        Write-Host ""
        Write-Host "DRY RUN COMPLETED - No actual changes were made" -ForegroundColor Yellow
        Write-Host "Run without -DryRun to apply these changes" -ForegroundColor Yellow
    }
    else {
        Write-Host ""
        Write-Host "✅ Feature implementation state update completed successfully!" -ForegroundColor Green

        # Validation
        Write-Host ""
        Write-Host "Running validation..." -ForegroundColor Yellow
        $validationResult = Validate-StateFileConsistency -FeatureId $FeatureId -ValidationLevel "Basic"

        if ($validationResult.FailedChecks -eq 0) {
            Write-Host "✅ State file consistency validation passed" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️  State file consistency issues detected - please review" -ForegroundColor Yellow
        }
    }

}
catch {
    Write-Error "Feature implementation state update failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "If backups were created, they can be found in:" -ForegroundColor Yellow
    Write-Host "  process-framework-local/state-tracking/backups" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green
