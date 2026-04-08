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
    $trackingFiles = Get-RelevantTrackingFiles -DocumentType "TestSpecification" -DocumentId "TE-TSP-013"
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
                    Path = Join-Path $projectRoot "doc/state-tracking/permanent/test-tracking.md"
                    Type = "TestImplementation"
                    Required = $true
                }
            )
        }
        "ValidationReport" {
            $trackingFiles += @(
                @{
                    Path = Join-Path $projectRoot "doc/state-tracking/validation/archive/validation-tracking-1.md"
                    Type = "ValidationTracking"
                    Required = $true
                }
            )
        }
        "FeatureImplementation" {
            $trackingFiles += @(
                @{
                    Path = Join-Path $projectRoot "doc/state-tracking/permanent/feature-tracking.md"
                    Type = "FeatureTracking"
                    Required = $true
                }
            )
        }
        "CodeReview" {
            $trackingFiles += @(
                @{
                    Path = Join-Path $projectRoot "process-framework-local/state-tracking/permanent/code-review-tracking.md"
                    Type = "CodeReviewTracking"
                    Required = $true
                }
            )
        }
        "BugFix" {
            $trackingFiles += @(
                @{
                    Path = Join-Path $projectRoot "process-framework-local/state-tracking/permanent/bug-fix-tracking.md"
                    Type = "BugFixTracking"
                    Required = $true
                }
            )
        }
        "TestAudit" {
            $trackingFiles += @(
                @{
                    Path = Join-Path $projectRoot "process-framework-local/state-tracking/permanent/test-audit-tracking.md"
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

    # Automatic backups disabled — state files are tracked by git,
    # making file-level backups redundant and cluttering the directory.
    Write-Verbose "Backup skipped (automatic backups disabled): $FilePath"
    return $null
}

# Export functions
Export-ModuleMember -Function @(
    'Get-RelevantTrackingFiles',
    'Get-StateFileBackup'
)

Write-Verbose "FileOperations module loaded with 3 functions"
