# FeatureTracking.psm1
# Feature tracking operations and status management
# Extracted from StateFileManagement.psm1 as part of module decomposition
#
# VERSION 1.0 - EXTRACTED MODULE
# This module contains feature-specific tracking operations

<#
.SYNOPSIS
Feature tracking operations and status management for PowerShell scripts

.DESCRIPTION
This module provides specialized functionality for feature tracking:
- Updating feature tracking status with standardized status, dates, and links
- Batch processing of multiple tracking files for features
- Feature-specific file operations and status management

This is a focused module extracted from StateFileManagement.psm1 to improve
maintainability and reduce complexity.

.NOTES
Version: 1.0 (Extracted Module)
Created: 2025-08-30
Extracted From: StateFileManagement.psm1
Dependencies: Get-ProjectRoot, Get-ProjectTimestamp, Update-MarkdownTable, Get-TrackingFilesByFeatureType
#>

# Configure UTF-8 encoding for consistent Unicode support
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'

function Update-FeatureTrackingStatus {
    <#
    .SYNOPSIS
    Updates feature tracking status with standardized status, dates, and links

    .PARAMETER FeatureId
    The feature ID to update

    .PARAMETER Status
    The new status (e.g., "🟡 In Progress", "🟢 Completed", "🔄 Needs Revision")

    .PARAMETER StatusColumn
    The column to update (e.g., "Status", "Test Status", "Implementation Status")

    .PARAMETER AdditionalUpdates
    Hashtable of additional column updates (column name -> value)

    .PARAMETER Notes
    Additional notes to append to the Notes column

    .PARAMETER DryRun
    If specified, shows what would be updated without making changes

    .EXAMPLE
    Update-FeatureTrackingStatus -FeatureId "1.2.3" -Status "🟢 Completed" -StatusColumn "Implementation Status"

    .EXAMPLE
    $updates = @{ "Test Status" = "✅ Tests Implemented"; "Code Review" = "Completed" }
    Update-FeatureTrackingStatus -FeatureId "1.2.3" -Status "🟢 Completed" -AdditionalUpdates $updates
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [string]$StatusColumn = "Status",

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalUpdates = @{},

        [Parameter(Mandatory=$false)]
        [string]$Notes,

        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )

    try {
        $projectRoot = Get-ProjectRoot
        $featureTrackingPath = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md"

        if (-not (Test-Path $featureTrackingPath)) {
            throw "Feature tracking file not found: $featureTrackingPath"
        }

        $content = Get-Content $featureTrackingPath -Raw
        $timestamp = Get-ProjectTimestamp -Format "DateTime"

        # Build update information
        $updateInfo = @{
            FeatureId = $FeatureId
            Status = $Status
            StatusColumn = $StatusColumn
            AdditionalUpdates = $AdditionalUpdates
            Notes = $Notes
            Timestamp = $timestamp
        }

        if ($DryRun) {
            Write-Host "DRY RUN: Would update feature $FeatureId in $featureTrackingPath" -ForegroundColor Yellow
            Write-Host "  $StatusColumn`: $Status" -ForegroundColor Cyan
            foreach ($key in $AdditionalUpdates.Keys) {
                Write-Host "  $key`: $($AdditionalUpdates[$key])" -ForegroundColor Cyan
            }
            if ($Notes) {
                Write-Host "  Notes: $Notes" -ForegroundColor Cyan
            }
            return $updateInfo
        }

        # Update the feature tracking file with robust table parsing
        Write-Verbose "Updating feature $FeatureId with status: $Status"

        # Create backup using the extracted backup function
        $backupPath = Get-StateFileBackup -FilePath $featureTrackingPath
        Write-Verbose "Created backup: $backupPath"

        # Parse and update the table content using extracted function
        $updatedContent = Update-MarkdownTable -Content $content -FeatureId $FeatureId -StatusColumn $StatusColumn -Status $Status -AdditionalUpdates $AdditionalUpdates -Notes $Notes

        # Update metadata
        $updatedContent = $updatedContent -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $(Get-ProjectTimestamp -Format 'Date')"

        # Save updated content
        Set-Content $featureTrackingPath $updatedContent -Encoding UTF8

        Write-Verbose "Updated feature tracking for $FeatureId"
        return $updateInfo
    }
    catch {
        Write-Error "Failed to update feature tracking for $FeatureId`: $($_.Exception.Message)"
        throw
    }
}

function Update-FeatureTrackingStatusWithAppend {
    <#
    .SYNOPSIS
    Updates feature tracking status with appending behavior for notes and links

    .PARAMETER FeatureId
    The feature ID to update

    .PARAMETER Status
    The new status value

    .PARAMETER StatusColumn
    The column to update (defaults to "Status")

    .PARAMETER AdditionalUpdates
    Hashtable of additional column updates (replaces existing values)

    .PARAMETER AppendUpdates
    Hashtable of column updates that should be appended to existing values

    .PARAMETER Notes
    Notes to append to existing notes

    .PARAMETER DryRun
    If specified, shows what would be updated without making changes

    .EXAMPLE
    $appendUpdates = @{ "API Design" = "[New Design](link)" }
    Update-FeatureTrackingStatusWithAppend -FeatureId "1.2.3" -Status "🟢 Complete" -AppendUpdates $appendUpdates -Notes "Added new design"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [string]$StatusColumn = "Status",

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalUpdates = @{},

        [Parameter(Mandatory=$false)]
        [hashtable]$AppendUpdates = @{},

        [Parameter(Mandatory=$false)]
        [string]$Notes,

        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )

    try {
        $projectRoot = Get-ProjectRoot
        $featureTrackingPath = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md"

        if (-not (Test-Path $featureTrackingPath)) {
            throw "Feature tracking file not found: $featureTrackingPath"
        }

        $content = Get-Content $featureTrackingPath -Raw
        $timestamp = Get-ProjectTimestamp -Format "DateTime"

        # Build update information
        $updateInfo = @{
            FeatureId = $FeatureId
            Status = $Status
            StatusColumn = $StatusColumn
            AdditionalUpdates = $AdditionalUpdates
            AppendUpdates = $AppendUpdates
            Notes = $Notes
            Timestamp = $timestamp
        }

        if ($DryRun) {
            Write-Host "DRY RUN: Would update feature $FeatureId with append behavior" -ForegroundColor Yellow
            Write-Host "  $StatusColumn`: $Status" -ForegroundColor Cyan
            foreach ($key in $AdditionalUpdates.Keys) {
                Write-Host "  $key (replace)`: $($AdditionalUpdates[$key])" -ForegroundColor Cyan
            }
            foreach ($key in $AppendUpdates.Keys) {
                Write-Host "  $key (append)`: $($AppendUpdates[$key])" -ForegroundColor Yellow
            }
            if ($Notes) {
                Write-Host "  Notes (append): $Notes" -ForegroundColor Yellow
            }
            return $updateInfo
        }

        # Update the feature tracking file with append behavior
        Write-Verbose "Updating feature $FeatureId with append behavior"

        # Create backup
        $backupPath = Get-StateFileBackup -FilePath $featureTrackingPath
        Write-Verbose "Created backup: $backupPath"

        # Use the append-capable function from TableOperations
        $updatedContent = Update-MarkdownTableWithAppend -Content $content -FeatureId $FeatureId -StatusColumn $StatusColumn -Status $Status -AdditionalUpdates $AdditionalUpdates -AppendUpdates $AppendUpdates -Notes $Notes

        # Update metadata
        $updatedContent = $updatedContent -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $(Get-ProjectTimestamp -Format 'Date')"

        # Save updated content
        Set-Content $featureTrackingPath $updatedContent -Encoding UTF8

        Write-Verbose "Updated feature tracking for $FeatureId with append behavior"
        return $updateInfo
    }
    catch {
        Write-Error "Failed to update feature tracking for $FeatureId`: $($_.Exception.Message)"
        throw
    }
}

function Update-MultipleTrackingFiles {
    <#
    .SYNOPSIS
    Updates multiple tracking files with the same information

    .PARAMETER TrackingFiles
    Array of tracking file information (Path, Type, Required)

    .PARAMETER FeatureId
    The feature ID to update

    .PARAMETER StatusColumn
    The column name to update

    .PARAMETER Status
    The new status value

    .PARAMETER AdditionalUpdates
    Hashtable of additional updates

    .PARAMETER Notes
    Notes to add

    .PARAMETER DryRun
    If specified, shows what would be updated without making changes

    .EXAMPLE
    $trackingFiles = @(
        @{ Path = "feature-tracking.md"; Type = "Feature"; Required = $true },
        @{ Path = "test-tracking.md"; Type = "Test"; Required = $false }
    )
    Update-MultipleTrackingFiles -TrackingFiles $trackingFiles -FeatureId "1.2.3" -StatusColumn "Status" -Status "🟢 Completed"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$TrackingFiles,

        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$StatusColumn,

        [Parameter(Mandatory=$true)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalUpdates = @{},

        [Parameter(Mandatory=$false)]
        [string]$Notes,

        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )

    $results = @()

    foreach ($trackingFile in $TrackingFiles) {
        $filePath = $trackingFile.Path
        $fileType = $trackingFile.Type
        $isRequired = $trackingFile.Required

        Write-Verbose "Processing tracking file: $filePath (Type: $fileType, Required: $isRequired)"

        if (-not (Test-Path $filePath)) {
            if ($isRequired) {
                Write-Error "Required tracking file not found: $filePath"
                $results += @{
                    FilePath = $filePath
                    FileType = $fileType
                    Success = $false
                    Error = "Required file not found"
                    FeatureId = $FeatureId
                    DryRun = $DryRun.IsPresent
                }
                continue
            } else {
                Write-Warning "Optional tracking file not found: $filePath"
                $results += @{
                    FilePath = $filePath
                    FileType = $fileType
                    Success = $false
                    Error = "Optional file not found"
                    FeatureId = $FeatureId
                    DryRun = $DryRun.IsPresent
                }
                continue
            }
        }

        try {
            if (-not $DryRun) {
                # Create backup
                $backupPath = Get-StateFileBackup -FilePath $filePath
                Write-Verbose "Created backup: $backupPath"
            }

            # Read current content
            $content = Get-Content -Path $filePath -Raw -Encoding UTF8

            # Update the table
            $updatedContent = Update-MarkdownTable -Content $content -FeatureId $FeatureId -StatusColumn $StatusColumn -Status $Status -AdditionalUpdates $AdditionalUpdates -Notes $Notes

            if (-not $DryRun) {
                # Write updated content
                Set-Content -Path $filePath -Value $updatedContent -Encoding UTF8
                Write-Verbose "Updated tracking file: $filePath"
            } else {
                Write-Host "DRY RUN: Would update $filePath" -ForegroundColor Yellow
                Write-Host "  Feature ID: $FeatureId" -ForegroundColor Cyan
                Write-Host "  $StatusColumn`: $Status" -ForegroundColor Cyan
            }

            $results += @{
                FilePath = $filePath
                FileType = $fileType
                Success = $true
                FeatureId = $FeatureId
                Status = $Status
                DryRun = $DryRun.IsPresent
            }

        } catch {
            Write-Error "Failed to update tracking file $filePath`: $($_.Exception.Message)"
            $results += @{
                FilePath = $filePath
                FileType = $fileType
                Success = $false
                Error = $_.Exception.Message
                FeatureId = $FeatureId
                DryRun = $DryRun.IsPresent
            }
        }
    }

    return $results
}

# Export functions
Export-ModuleMember -Function @(
    'Update-FeatureTrackingStatus',
    'Update-FeatureTrackingStatusWithAppend',
    'Update-MultipleTrackingFiles'
)

Write-Verbose "FeatureTracking module loaded with 3 functions"
