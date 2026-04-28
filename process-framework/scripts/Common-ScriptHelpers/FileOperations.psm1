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

function Assert-LineInFile {
    <#
    .SYNOPSIS
    Asserts that a file contains a pattern at least N times; throws on mismatch.

    .DESCRIPTION
    Read-after-write verification helper. Call this immediately after a script
    writes to a file with a deterministic post-condition. If the expected pattern
    is absent (or appears fewer than MinOccurrences times), the function throws
    with a descriptive error so the failure surfaces at the moment of the bad
    write rather than being buried in a downstream warning or success banner.

    .PARAMETER Path
    Absolute or relative path to the file to inspect. Read with -Raw, so
    multi-line patterns are supported.

    .PARAMETER Pattern
    Regex pattern (default) or literal substring (with -Literal). Matched against
    the entire file content.

    .PARAMETER Literal
    When specified, Pattern is treated as a literal substring instead of a regex.

    .PARAMETER MinOccurrences
    Minimum required match count. Defaults to 1.

    .PARAMETER Context
    Optional caller-supplied context appended to the error message to aid
    diagnosis (e.g., the operation that just completed).

    .EXAMPLE
    Assert-LineInFile -Path "doc/PD-documentation-map.md" -Pattern "PD-INT-001.*workflow"

    .EXAMPLE
    Assert-LineInFile -Path "config.yaml" -Pattern "version: 2.0" -Literal -Context "post-bump"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$Pattern,

        [switch]$Literal,

        [int]$MinOccurrences = 1,

        [string]$Context
    )

    $contextSuffix = if ($Context) { " (context: $Context)" } else { "" }

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Assert-LineInFile: file not found: '$Path'$contextSuffix"
    }

    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ($null -eq $content) { $content = "" }

    if ($Literal) {
        $count = 0
        $idx = 0
        if ($Pattern.Length -gt 0) {
            while (($idx = $content.IndexOf($Pattern, $idx)) -ge 0) {
                $count++
                $idx += $Pattern.Length
            }
        }
        $patternKind = "literal"
    } else {
        try {
            $regexMatches = [regex]::Matches($content, $Pattern)
            $count = $regexMatches.Count
        } catch {
            throw "Assert-LineInFile: invalid regex pattern '$Pattern' for '$Path'$contextSuffix : $($_.Exception.Message)"
        }
        $patternKind = "regex"
    }

    if ($count -lt $MinOccurrences) {
        throw "Assert-LineInFile: $patternKind pattern '$Pattern' found $count time(s) in '$Path', expected at least $MinOccurrences$contextSuffix"
    }
}

function Test-LineInFile {
    <#
    .SYNOPSIS
    Returns $true if a file contains a pattern at least N times; $false otherwise.

    .DESCRIPTION
    Non-throwing companion to Assert-LineInFile. Use this when the caller wants
    to branch on presence/absence without throwing. Same parameters as
    Assert-LineInFile.

    .EXAMPLE
    if (Test-LineInFile -Path "log.txt" -Pattern "ERROR") { Write-Warning "errors present" }
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$Pattern,

        [switch]$Literal,

        [int]$MinOccurrences = 1,

        [string]$Context
    )

    try {
        Assert-LineInFile @PSBoundParameters
        return $true
    } catch {
        return $false
    }
}

# Export functions
$ExportedFunctions = @(
    'Get-RelevantTrackingFiles',
    'Get-StateFileBackup',
    'Assert-LineInFile',
    'Test-LineInFile'
)
Export-ModuleMember -Function $ExportedFunctions

Write-Verbose "FileOperations module loaded with $($ExportedFunctions.Count) functions"
