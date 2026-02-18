# FileOperations.psm1
# File system operations and backup functions
# Extracted from StateFileManagement.psm1 as part of module decomposition
#
# VERSION 1.0 - EXTRACTED MODULE
# This module contains file operations with minimal external dependencies

<#
.SYNOPSIS
File system operations and backup functions for PowerShell scripts

.DESCRIPTION
This module provides specialized functionality for file operations:
- Determining relevant tracking files for different document types
- Creating backup copies of state files before modification
- File path resolution and validation

This is a focused module extracted from StateFileManagement.psm1 to improve
maintainability and reduce complexity.

.NOTES
Version: 1.0 (Extracted Module)
Created: 2025-08-30
Extracted From: StateFileManagement.psm1
Dependencies: Get-ProjectRoot, Get-ProjectTimestamp, Test-ProjectPath (from other modules)
#>

# Configure UTF-8 encoding for consistent Unicode support
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'

function Get-RelevantTrackingFiles {
    <#
    .SYNOPSIS
    Gets the list of tracking files that should be updated for a given document type

    .PARAMETER DocumentType
    The type of document being created (TestSpecification, ValidationReport, ADR, etc.)

    .PARAMETER DocumentId
    The ID of the document being created

    .PARAMETER Metadata
    Additional metadata that might affect which tracking files are relevant

    .EXAMPLE
    $trackingFiles = Get-RelevantTrackingFiles -DocumentType "TestSpecification" -DocumentId "PF-TSP-013"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DocumentType,

        [Parameter(Mandatory=$false)]
        [string]$DocumentId,

        [Parameter(Mandatory=$false)]
        [hashtable]$Metadata = @{}
    )

    $projectRoot = Get-ProjectRoot
    $trackingFiles = @()

    switch ($DocumentType) {
        "TestSpecification" {
            $trackingFiles += @(
                @{
                    Path = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/test-implementation-tracking.md"
                    Type = "TestImplementation"
                    Required = $true
                }
            )
        }
        "ValidationReport" {
            $trackingFiles += @(
                @{
                    Path = Join-Path $projectRoot "doc/process-framework/state-tracking/temporary/foundational-validation-tracking-round2.md"
                    Type = "ValidationTracking"
                    Required = $true
                }
            )
        }
        "FeatureImplementation" {
            $trackingFiles += @(
                @{
                    Path = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md"
                    Type = "FeatureTracking"
                    Required = $true
                }
            )
        }
        "CodeReview" {
            $trackingFiles += @(
                @{
                    Path = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/code-review-tracking.md"
                    Type = "CodeReviewTracking"
                    Required = $true
                }
            )
        }
        "BugFix" {
            $trackingFiles += @(
                @{
                    Path = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/bug-fix-tracking.md"
                    Type = "BugFixTracking"
                    Required = $true
                }
            )
        }
        "TestAudit" {
            $trackingFiles += @(
                @{
                    Path = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/test-audit-tracking.md"
                    Type = "TestAuditTracking"
                    Required = $true
                }
            )
        }
        default {
            Write-Verbose "No specific tracking files defined for document type: $DocumentType"
        }
    }

    return $trackingFiles
}

function Get-StateFileBackup {
    <#
    .SYNOPSIS
    Creates a backup of a state file before modification

    .PARAMETER FilePath
    Path to the state file to backup

    .PARAMETER BackupDirectory
    Directory to store backups (optional, defaults to same directory with timestamp)

    .EXAMPLE
    $backupPath = Get-StateFileBackup -FilePath "feature-tracking.md"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$false)]
        [string]$BackupDirectory
    )

    if (-not (Test-Path $FilePath)) {
        throw "File not found for backup: $FilePath"
    }

    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $fileExtension = [System.IO.Path]::GetExtension($FilePath)
    $timestamp = Get-ProjectTimestamp -Format "FileTimestamp"

    if ($BackupDirectory) {
        Test-ProjectPath -Path $BackupDirectory -CreateIfMissing -PathType Directory | Out-Null
        $backupPath = Join-Path $BackupDirectory "$fileName-backup-$timestamp$fileExtension"
    } else {
        $directory = Split-Path -Parent $FilePath
        $backupPath = Join-Path $directory "$fileName-backup-$timestamp$fileExtension"
    }

    try {
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Verbose "Created backup: $backupPath"
        return $backupPath
    }
    catch {
        throw "Failed to create backup of $FilePath`: $($_.Exception.Message)"
    }
}

function Get-TrackingFilesByFeatureType {
    <#
    .SYNOPSIS
    Gets tracking files relevant for a specific feature type based on feature ID pattern

    .PARAMETER FeatureId
    The feature ID to determine tracking file relevance

    .EXAMPLE
    $trackingFiles = Get-TrackingFilesByFeatureType -FeatureId "1.1.1"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureId
    )

    $projectRoot = Get-ProjectRoot
    $trackingFiles = @()

    # Architecture features (0.x.x pattern)
    if ($FeatureId -match '^0\.\d+\.\d+$') {
        $trackingFiles += @(
            @{
                Path = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md"
                Type = "ArchitectureFeature"
                Required = $true
                Section = "Architecture"
            }
        )
    }
    # Standard features (non-0.x.x pattern)
    else {
        $trackingFiles += @(
            @{
                Path = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md"
                Type = "StandardFeature"
                Required = $true
                Section = "Standard"
            }
        )
    }

    return $trackingFiles
}

# Export functions
Export-ModuleMember -Function @(
    'Get-RelevantTrackingFiles',
    'Get-StateFileBackup',
    'Get-TrackingFilesByFeatureType'
)

Write-Verbose "FileOperations module loaded with 3 functions"
