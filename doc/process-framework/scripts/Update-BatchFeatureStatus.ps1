#!/usr/bin/env pwsh

<#
.SYNOPSIS
Updates multiple features simultaneously across all tracking files

.DESCRIPTION
This script enables bulk status updates for multiple features across all tracking files,
addressing IMP-052 (Automated status synchronization across tracking files). Provides
atomic transactions with rollback capabilities for safe batch operations.

Use cases:
- Sprint completion updates
- Milestone status changes
- Bulk feature transitions
- Release preparation updates
- Cross-team synchronization

Updates the following files atomically:
- doc/process-framework/state-tracking/permanent/feature-tracking.md
- doc/process-framework/state-tracking/permanent/test-implementation-tracking.md
- doc/product-docs/technical/architecture/component-relationship-index.md
- Additional tracking files as needed

.PARAMETER FeatureIds
Array of feature IDs to update (e.g., @("1.2.1", "1.2.2", "1.2.3"))

.PARAMETER Status
The new status to apply to all features:
- "🟡 In Progress"
- "🔄 Needs Revision"
- "🟢 Completed"
- "🔴 Blocked"
- "⏸️ On Hold"

.PARAMETER UpdateType
Type of batch update:
- "StatusOnly" - Update only the status field
- "Milestone" - Update status and milestone information
- "Sprint" - Update status and sprint completion data
- "Release" - Update status and release preparation data
- "Full" - Update all relevant fields

.PARAMETER MilestoneId
Milestone identifier for milestone updates (optional)

.PARAMETER SprintId
Sprint identifier for sprint updates (optional)

.PARAMETER ReleaseVersion
Release version for release updates (optional)

.PARAMETER UpdateDate
Date for the updates (optional - uses current date if not specified)

.PARAMETER UpdateNotes
Notes to add to all updated features (optional)

.PARAMETER DryRun
If specified, shows what would be updated without making changes

.PARAMETER Force
If specified, bypasses confirmation prompts for bulk operations

.PARAMETER ContinueOnError
If specified, continues processing remaining features if one fails

.EXAMPLE
.\Update-BatchFeatureStatus.ps1 -FeatureIds @("1.2.1", "1.2.2", "1.2.3") -Status "🟢 Completed" -UpdateType "StatusOnly"

.EXAMPLE
.\Update-BatchFeatureStatus.ps1 -FeatureIds @("2.1.1", "2.1.2", "2.1.3") -Status "🟢 Completed" -UpdateType "Sprint" -SprintId "Sprint-2025-08" -UpdateNotes "Sprint 8 completion"

.EXAMPLE
.\Update-BatchFeatureStatus.ps1 -FeatureIds @("1.1.1", "1.1.2", "1.1.3", "1.1.4") -Status "🟢 Completed" -UpdateType "Release" -ReleaseVersion "v1.1.0" -DryRun

.EXAMPLE
.\Update-BatchFeatureStatus.ps1 -FeatureIds @("3.1.1", "3.1.2") -Status "🔴 Blocked" -UpdateType "Full" -UpdateNotes "Blocked pending API changes" -Force

.NOTES
Version: 1.0
Created: 2025-08-23
Part of: Process Framework Automation Phase 3A
Addresses: IMP-052 (Automated status synchronization across tracking files)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$FeatureIds,

    [Parameter(Mandatory = $true)]
    [ValidateSet("🟡 In Progress", "🧪 Testing", "👀 Ready for Review", "🔄 Needs Revision", "🟢 Completed", "🔴 Blocked", "⏸️ On Hold")]
    [string]$Status,

    [Parameter(Mandatory = $true)]
    [ValidateSet("StatusOnly", "Milestone", "Sprint", "Release", "Full")]
    [string]$UpdateType,

    [Parameter(Mandatory = $false)]
    [string]$MilestoneId,

    [Parameter(Mandatory = $false)]
    [string]$SprintId,

    [Parameter(Mandatory = $false)]
    [string]$ReleaseVersion,

    [Parameter(Mandatory = $false)]
    [string]$UpdateDate,

    [Parameter(Mandatory = $false)]
    [string]$UpdateNotes,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$ContinueOnError
)

# Import required modules
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$scriptDir\Common-ScriptHelpers.psm1" -Force

# Initialize script with dependency validation
if (-not (Test-ScriptDependencies -RequiredModules @("Common-ScriptHelpers"))) {
    Write-Error "Required dependencies not met. Please ensure Common-ScriptHelpers.psm1 is properly loaded."
    exit 1
}

# Set default values
if (-not $UpdateDate) {
    $UpdateDate = Get-Date -Format "yyyy-MM-dd"
}

# Validate update type parameters
switch ($UpdateType) {
    "Milestone" {
        if (-not $MilestoneId) {
            Write-Error "MilestoneId is required for Milestone update type"
            exit 1
        }
    }
    "Sprint" {
        if (-not $SprintId) {
            Write-Error "SprintId is required for Sprint update type"
            exit 1
        }
    }
    "Release" {
        if (-not $ReleaseVersion) {
            Write-Error "ReleaseVersion is required for Release update type"
            exit 1
        }
    }
}

$batchId = "BATCH-UPDATE-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "🚀 Starting Batch Feature Status Update" -ForegroundColor Green
Write-Host "   Features to Update: $($FeatureIds.Count)" -ForegroundColor Cyan
Write-Host "   New Status: $Status" -ForegroundColor Cyan
Write-Host "   Update Type: $UpdateType" -ForegroundColor Cyan
Write-Host "   Batch ID: $batchId" -ForegroundColor Cyan
if ($MilestoneId) { Write-Host "   Milestone: $MilestoneId" -ForegroundColor Cyan }
if ($SprintId) { Write-Host "   Sprint: $SprintId" -ForegroundColor Cyan }
if ($ReleaseVersion) { Write-Host "   Release: $ReleaseVersion" -ForegroundColor Cyan }
if ($DryRun) {
    Write-Host "   🔍 DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
}

# Get project root and define file paths
$projectRoot = Get-ProjectRoot
$trackingFiles = @(
    Join-Path $projectRoot "doc\process-framework\state-tracking\permanent\feature-tracking.md",
    Join-Path $projectRoot "doc\process-framework\state-tracking\permanent\test-implementation-tracking.md",
    Join-Path $projectRoot "doc\product-docs\technical\architecture\component-relationship-index.md"
)

# Confirmation prompt for bulk operations (unless Force is specified)
if (-not $Force -and -not $DryRun) {
    Write-Host "⚠️ You are about to update $($FeatureIds.Count) features with status '$Status'" -ForegroundColor Yellow
    Write-Host "   This will modify $($trackingFiles.Count) tracking files" -ForegroundColor Yellow
    $confirmation = Read-Host "Do you want to continue? (y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "❌ Operation cancelled by user" -ForegroundColor Red
        exit 0
    }
}

# Create comprehensive backup before making changes
if (-not $DryRun) {
    Write-Host "📦 Creating comprehensive backup..." -ForegroundColor Blue
    $backupInfo = Get-StateFileBackup -FilePaths $trackingFiles -BackupReason "BatchFeatureUpdate-$batchId"
    Write-Host "   Backups created: $($backupInfo.BackupDirectory)" -ForegroundColor Green
}

# Initialize batch tracking
$batchResults = @{
    BatchId = $batchId
    UpdateType = $UpdateType
    Status = $Status
    StartTime = Get-Date
    TotalFeatures = $FeatureIds.Count
    ProcessedFeatures = @()
    FailedFeatures = @()
    FilesModified = @()
    RollbackInfo = $null
}

try {
    # Prepare update data for each feature
    $updateOperations = @()

    foreach ($featureId in $FeatureIds) {
        Write-Host "📋 Preparing update for Feature: $featureId" -ForegroundColor Cyan

        # Build update data based on update type
        $updateData = @{
            FeatureId = $featureId
            Status = $Status
            UpdateDate = $UpdateDate
            UpdateType = $UpdateType
        }

        # Add type-specific data
        switch ($UpdateType) {
            "Milestone" {
                $updateData.MilestoneId = $MilestoneId
                $updateData.MilestoneDate = $UpdateDate
            }
            "Sprint" {
                $updateData.SprintId = $SprintId
                $updateData.SprintCompletionDate = $UpdateDate
            }
            "Release" {
                $updateData.ReleaseVersion = $ReleaseVersion
                $updateData.ReleaseDate = $UpdateDate
            }
            "Full" {
                if ($MilestoneId) { $updateData.MilestoneId = $MilestoneId }
                if ($SprintId) { $updateData.SprintId = $SprintId }
                if ($ReleaseVersion) { $updateData.ReleaseVersion = $ReleaseVersion }
            }
        }

        if ($UpdateNotes) {
            $updateData.UpdateNotes = $UpdateNotes
        }

        $updateOperations += $updateData
    }

    if ($DryRun) {
        Write-Host "🔍 DRY RUN - Would update the following:" -ForegroundColor Yellow
        foreach ($operation in $updateOperations) {
            Write-Host "   📄 Feature: $($operation.FeatureId)" -ForegroundColor Cyan
            Write-Host "      Status: $($operation.Status)" -ForegroundColor Gray
            Write-Host "      Type: $($operation.UpdateType)" -ForegroundColor Gray
            if ($operation.MilestoneId) { Write-Host "      Milestone: $($operation.MilestoneId)" -ForegroundColor Gray }
            if ($operation.SprintId) { Write-Host "      Sprint: $($operation.SprintId)" -ForegroundColor Gray }
            if ($operation.ReleaseVersion) { Write-Host "      Release: $($operation.ReleaseVersion)" -ForegroundColor Gray }
        }

        Write-Host "🔍 DRY RUN - Would modify files:" -ForegroundColor Yellow
        foreach ($file in $trackingFiles) {
            Write-Host "   📄 $file" -ForegroundColor Cyan
        }
    } else {
        # Perform atomic batch update
        Write-Host "🔄 Executing atomic batch update..." -ForegroundColor Blue

        # Use the Update-MultipleTrackingFiles function for atomic operations
        $batchUpdateResult = Update-MultipleTrackingFiles -UpdateOperations $updateOperations -FilePaths $trackingFiles -BatchId $batchId

        if ($batchUpdateResult.Success) {
            $batchResults.ProcessedFeatures = $updateOperations
            $batchResults.FilesModified = $batchUpdateResult.ModifiedFiles

            Write-Host "✅ Batch update completed successfully!" -ForegroundColor Green

            # Synchronize cross-references
            Write-Host "🔄 Synchronizing cross-references..." -ForegroundColor Blue
            Sync-CrossReferencedFiles -FilePaths $trackingFiles

            # Validate consistency
            Write-Host "✅ Validating file consistency..." -ForegroundColor Blue
            $validationResult = Validate-StateFileConsistency -FilePaths $trackingFiles

            if ($validationResult.IsValid) {
                Write-Host "✅ All files updated successfully and are consistent!" -ForegroundColor Green
            } else {
                Write-Warning "⚠️ Consistency validation found issues:"
                $validationResult.Issues | ForEach-Object { Write-Warning "   $_" }
            }

        } else {
            throw "Batch update failed: $($batchUpdateResult.Error)"
        }
    }

    # Generate final summary
    $batchResults.EndTime = Get-Date
    $batchResults.Duration = $batchResults.EndTime - $batchResults.StartTime
    $batchResults.Summary = @{
        TotalFeatures = $batchResults.TotalFeatures
        ProcessedSuccessfully = $batchResults.ProcessedFeatures.Count
        Failed = $batchResults.FailedFeatures.Count
        SuccessRate = if ($batchResults.TotalFeatures -gt 0) { [Math]::Round(($batchResults.ProcessedFeatures.Count / $batchResults.TotalFeatures) * 100, 2) } else { 0 }
        Duration = $batchResults.Duration.ToString("hh\:mm\:ss")
        FilesModified = $batchResults.FilesModified.Count
    }

    # Save batch results
    if (-not $DryRun) {
        $resultsPath = Join-Path $projectRoot "doc\process-framework\state-tracking\temporary\batch-update-results-$batchId.json"
        $batchResults | ConvertTo-Json -Depth 10 | Set-Content -Path $resultsPath -Encoding UTF8
        Write-Host "📊 Batch results saved: $resultsPath" -ForegroundColor Blue
    }

    # Display comprehensive summary
    Write-Host "🎉 Batch Feature Status Update Completed!" -ForegroundColor Green
    Write-Host "   📊 Summary:" -ForegroundColor Cyan
    Write-Host "      Total Features: $($batchResults.Summary.TotalFeatures)" -ForegroundColor Gray
    Write-Host "      Processed Successfully: $($batchResults.Summary.ProcessedSuccessfully)" -ForegroundColor Gray
    Write-Host "      Failed: $($batchResults.Summary.Failed)" -ForegroundColor Gray
    Write-Host "      Success Rate: $($batchResults.Summary.SuccessRate)%" -ForegroundColor Gray
    Write-Host "      Duration: $($batchResults.Summary.Duration)" -ForegroundColor Gray
    Write-Host "      Files Modified: $($batchResults.Summary.FilesModified)" -ForegroundColor Gray

    if ($batchResults.FailedFeatures.Count -gt 0) {
        Write-Host "   ⚠️ Failed Features:" -ForegroundColor Yellow
        foreach ($failed in $batchResults.FailedFeatures) {
            Write-Host "      - $($failed.FeatureId): $($failed.Error)" -ForegroundColor Red
        }
    }

} catch {
    Write-Error "❌ Batch feature status update failed: $($_.Exception.Message)"

    # Attempt rollback if not in dry run mode
    if (-not $DryRun -and $backupInfo) {
        Write-Host "🔄 Attempting to restore from backup..." -ForegroundColor Yellow
        try {
            # Restore from backup (implementation would depend on backup structure)
            foreach ($file in $trackingFiles) {
                $backupFile = Join-Path $backupInfo.BackupDirectory (Split-Path $file -Leaf)
                if (Test-Path $backupFile) {
                    Copy-Item $backupFile $file -Force
                    Write-Host "   ✅ Restored: $(Split-Path $file -Leaf)" -ForegroundColor Green
                }
            }
            Write-Host "🔄 Rollback completed successfully" -ForegroundColor Green
        } catch {
            Write-Error "❌ Rollback failed: $($_.Exception.Message)"
            Write-Host "📦 Manual restoration may be required from: $($backupInfo.BackupDirectory)" -ForegroundColor Yellow
        }
    }

    # Save partial results if any processing was done
    if (-not $DryRun -and ($batchResults.ProcessedFeatures.Count -gt 0 -or $batchResults.FailedFeatures.Count -gt 0)) {
        $batchResults.EndTime = Get-Date
        $batchResults.Duration = $batchResults.EndTime - $batchResults.StartTime
        $batchResults.Status = "FAILED"

        $resultsPath = Join-Path $projectRoot "doc\process-framework\state-tracking\temporary\batch-update-results-$batchId-FAILED.json"
        $batchResults | ConvertTo-Json -Depth 10 | Set-Content -Path $resultsPath -Encoding UTF8
        Write-Host "📊 Partial batch results saved: $resultsPath" -ForegroundColor Yellow
    }

    exit 1
}
