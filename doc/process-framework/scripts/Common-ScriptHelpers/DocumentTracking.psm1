# DocumentTracking.psm1
# Document tracking operations and file management
# Extracted from StateFileManagement.psm1 as part of module decomposition
#
# VERSION 1.0 - EXTRACTED MODULE
# This module contains document-specific tracking operations

<#
.SYNOPSIS
Document tracking operations and file management for PowerShell scripts

.DESCRIPTION
This module provides specialized functionality for document tracking:
- Updating multiple tracking files when new documents are created
- Managing document metadata and cross-references
- Handling different document types (TestSpecification, ADR, ValidationReport, etc.)

This is a focused module extracted from StateFileManagement.psm1 to improve
maintainability and reduce complexity.

.NOTES
Version: 1.0 (Extracted Module)
Created: 2025-08-30
Extracted From: StateFileManagement.psm1
Dependencies: Get-ProjectRoot, Get-ProjectTimestamp, Update-FeatureTrackingStatus, Get-RelevantTrackingFiles
#>

# Configure UTF-8 encoding for consistent Unicode support
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'

function Update-DocumentTrackingFiles {
    <#
    .SYNOPSIS
    Updates multiple tracking files when a new document is created (Test Specifications, ADRs, etc.)

    .PARAMETER DocumentId
    The ID of the document being created (e.g., PF-TSP-013)

    .PARAMETER DocumentType
    The type of document (TestSpecification, ADR, ValidationReport, etc.)

    .PARAMETER DocumentPath
    Path to the created document

    .PARAMETER Metadata
    Hashtable containing document metadata (feature_id, feature_name, etc.)

    .PARAMETER DryRun
    If specified, shows what would be updated without making changes

    .EXAMPLE
    $metadata = @{ "feature_id" = "1.2.3"; "feature_name" = "user-auth"; "tdd_path" = "path/to/tdd.md" }
    Update-DocumentTrackingFiles -DocumentId "PF-TSP-013" -DocumentType "TestSpecification" -DocumentPath "test/specs/test-spec-1-2-3-user-auth.md" -Metadata $metadata
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DocumentId,

        [Parameter(Mandatory=$true)]
        [string]$DocumentType,

        [Parameter(Mandatory=$true)]
        [string]$DocumentPath,

        [Parameter(Mandatory=$false)]
        [hashtable]$Metadata = @{},

        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )

    try {
        $projectRoot = Get-ProjectRoot
        $timestamp = Get-ProjectTimestamp -Format "Date"
        $results = @()

        Write-Verbose "Updating tracking files for $DocumentType document: $DocumentId"

        switch ($DocumentType) {
            "TestSpecification" {
                # Extract required metadata
                $featureId = $Metadata["feature_id"]
                $featureName = $Metadata["feature_name"]
                $tddPath = $Metadata["tdd_path"]

                if (-not $featureId) {
                    throw "feature_id is required in metadata for TestSpecification documents"
                }

                # Test Specification Creation Task should ONLY update feature-tracking.md
                # The Test Implementation Task will handle test-implementation-tracking.md and test-registry.yaml

                # Update feature-tracking.md
                try {
                    if ($DryRun) {
                        $specsCreatedStatus = "📋 Specs Created"
                        Write-Host "DRY RUN: Would update feature-tracking.md" -ForegroundColor Yellow
                        Write-Host "  Feature ID: $featureId" -ForegroundColor Cyan
                        Write-Host "  Test Status: $specsCreatedStatus" -ForegroundColor Cyan
                        Write-Host "  Test Spec Link: $DocumentPath" -ForegroundColor Cyan
                    } else {
                        # Calculate relative path from feature-tracking.md to the test specification
                        $featureTrackingPath = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md"
                        $featureTrackingDir = Split-Path $featureTrackingPath -Parent
                        $relativePath = [System.IO.Path]::GetRelativePath($featureTrackingDir, $DocumentPath)
                        $relativePath = $relativePath -replace '\\', '/'  # Convert to forward slashes for markdown

                        $specsCreatedStatus = "📋 Specs Created"
                        $additionalUpdates = @{
                            "Test Status" = $specsCreatedStatus
                            "Test Spec" = "[$DocumentId]($relativePath)"
                        }

                        $notes = "Test specification created: $DocumentId ($timestamp)"

                        Update-FeatureTrackingStatus -FeatureId $featureId -Status $specsCreatedStatus -StatusColumn "Test Status" -AdditionalUpdates $additionalUpdates -Notes $notes
                        Write-Verbose "Updated feature-tracking.md"
                    }

                    $results += @{
                        File = "feature-tracking.md"
                        Success = $true
                        Message = "Updated test status and added specification link"
                    }
                } catch {
                    $results += @{
                        File = "feature-tracking.md"
                        Success = $false
                        Message = "Failed to update: $($_.Exception.Message)"
                    }
                    Write-Warning "Failed to update feature-tracking.md: $($_.Exception.Message)"
                }
            }

            "ADR" {
                # Extract required metadata
                $title = $Metadata["title"]
                $status = $Metadata["status"]
                $description = $Metadata["description"]
                $relatedFeatureId = $Metadata["related_feature_id"]
                $impactLevel = $Metadata["impact_level"]

                if (-not $title) {
                    throw "title is required in metadata for ADR documents"
                }

                # Update architecture-tracking.md
                try {
                    if ($DryRun) {
                        Write-Host "DRY RUN: Would update architecture-tracking.md" -ForegroundColor Yellow
                        Write-Host "  ADR ID: $DocumentId" -ForegroundColor Cyan
                        Write-Host "  Title: $title" -ForegroundColor Cyan
                        Write-Host "  Status: $status" -ForegroundColor Cyan
                    } else {
                        $archTrackingPath = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/architecture-tracking.md"

                        if (Test-Path $archTrackingPath) {
                            # Calculate relative path from architecture-tracking.md to the ADR
                            $archTrackingDir = Split-Path $archTrackingPath -Parent
                            $relativePath = [System.IO.Path]::GetRelativePath($archTrackingDir, $DocumentPath)
                            $relativePath = $relativePath -replace '\\', '/'  # Convert to forward slashes for markdown

                            # Read the architecture tracking file
                            $content = Get-Content -Path $archTrackingPath -Raw -Encoding UTF8

                            # Create backup
                            $backupPath = Get-StateFileBackup -FilePath $archTrackingPath
                            Write-Verbose "Created backup: $backupPath"

                            # Add new ADR entry to the table
                            $statusEmoji = switch ($status) {
                                "Accepted" { "✅" }
                                "Proposed" { "🟡" }
                                "Rejected" { "❌" }
                                "Deprecated" { "⚠️" }
                                default { "🟡" }
                            }

                            $newEntry = "| [$DocumentId]($relativePath) | $title | $statusEmoji $status | $($impactLevel -or 'High') | $($relatedFeatureId -or 'TBD') |"

                            # Find the ADR table and add the entry
                            $lines = $content -split '\r?\n'
                            $updatedLines = @()
                            $addedEntry = $false

                            for ($i = 0; $i -lt $lines.Count; $i++) {
                                $line = $lines[$i]

                                # Look for the table header
                                if ($line -match "^\|\s*ADR ID\s*\|\s*Title\s*\|\s*Status\s*\|\s*Impact Level\s*\|\s*Related Features\s*\|$") {
                                    $updatedLines += $line

                                    # Add separator line if it exists
                                    if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -match "^\|[-\s:|]+$") {
                                        $i++
                                        $updatedLines += $lines[$i]
                                    }

                                    # Add the new entry
                                    $updatedLines += $newEntry
                                    $addedEntry = $true
                                    continue
                                }

                                $updatedLines += $line
                            }

                            if ($addedEntry) {
                                # Write back to file
                                $updatedContent = $updatedLines -join "`n"
                                Set-Content -Path $archTrackingPath -Value $updatedContent -Encoding UTF8
                                Write-Verbose "Updated architecture-tracking.md with ADR: $DocumentId"
                            } else {
                                Write-Warning "Could not find ADR table in architecture-tracking.md"
                            }
                        } else {
                            Write-Warning "Architecture tracking file not found: $archTrackingPath"
                        }
                    }

                    $results += @{
                        File = "architecture-tracking.md"
                        Success = $true
                        Message = "Updated with new ADR entry"
                    }
                } catch {
                    $results += @{
                        File = "architecture-tracking.md"
                        Success = $false
                        Message = "Failed to update: $($_.Exception.Message)"
                    }
                    Write-Warning "Failed to update architecture-tracking.md: $($_.Exception.Message)"
                }

                # Update feature-tracking.md if this ADR is related to specific features
                if ($relatedFeatureId -and $relatedFeatureId -ne "" -and $relatedFeatureId -ne "TBD") {
                    try {
                        if ($DryRun) {
                            Write-Host "DRY RUN: Would update feature-tracking.md for feature $relatedFeatureId" -ForegroundColor Yellow
                        } else {
                            $featureTrackingPath = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md"

                            if (Test-Path $featureTrackingPath) {
                                # Calculate relative path from feature-tracking.md to the ADR
                                $featureTrackingDir = Split-Path $featureTrackingPath -Parent
                                $relativePath = [System.IO.Path]::GetRelativePath($featureTrackingDir, $DocumentPath)
                                $relativePath = $relativePath -replace '\\', '/'  # Convert to forward slashes for markdown

                                # Update the feature with ADR link
                                $additionalUpdates = @{
                                    "ADR" = "[$DocumentId]($relativePath)"
                                }

                                $notes = "ADR created: $DocumentId - $title ($timestamp)"

                                Update-FeatureTrackingStatus -FeatureId $relatedFeatureId -Status "📋 ADR Created" -StatusColumn "Status" -AdditionalUpdates $additionalUpdates -Notes $notes
                                Write-Verbose "Updated feature-tracking.md for feature: $relatedFeatureId"
                            }
                        }

                        $results += @{
                            File = "feature-tracking.md"
                            Success = $true
                            Message = "Updated ADR link for feature $relatedFeatureId"
                        }
                    } catch {
                        $results += @{
                            File = "feature-tracking.md"
                            Success = $false
                            Message = "Failed to update: $($_.Exception.Message)"
                        }
                        Write-Warning "Failed to update feature-tracking.md: $($_.Exception.Message)"
                    }
                } else {
                    Write-Verbose "No related feature ID provided - skipping feature-tracking.md update"
                }
            }

            "ValidationReport" {
                # Extract required metadata
                $validationType = $Metadata["validation_type"]
                $validationScope = $Metadata["validation_scope"]
                $relatedFeatureId = $Metadata["related_feature_id"]

                # Update validation tracking files
                try {
                    if ($DryRun) {
                        Write-Host "DRY RUN: Would update validation tracking files" -ForegroundColor Yellow
                        Write-Host "  Document ID: $DocumentId" -ForegroundColor Cyan
                        Write-Host "  Validation Type: $validationType" -ForegroundColor Cyan
                        Write-Host "  Scope: $validationScope" -ForegroundColor Cyan
                    } else {
                        # Get relevant tracking files for validation reports
                        $trackingFiles = Get-RelevantTrackingFiles -DocumentType "ValidationReport" -DocumentId $DocumentId -Metadata $Metadata

                        foreach ($trackingFile in $trackingFiles) {
                            $trackingPath = $trackingFile.Path

                            if (Test-Path $trackingPath) {
                                # Calculate relative path
                                $trackingDir = Split-Path $trackingPath -Parent
                                $relativePath = [System.IO.Path]::GetRelativePath($trackingDir, $DocumentPath)
                                $relativePath = $relativePath -replace '\\', '/'

                                # Update the tracking file with validation report link
                                $content = Get-Content -Path $trackingPath -Raw -Encoding UTF8

                                # Create backup
                                $backupPath = Get-StateFileBackup -FilePath $trackingPath
                                Write-Verbose "Created backup: $backupPath"

                                # Add validation report entry (simplified approach)
                                $newEntry = "`n- [$DocumentId]($relativePath) - $validationType validation ($timestamp)"
                                $updatedContent = $content + $newEntry

                                Set-Content -Path $trackingPath -Value $updatedContent -Encoding UTF8
                                Write-Verbose "Updated validation tracking: $trackingPath"
                            }
                        }
                    }

                    $results += @{
                        File = "validation-tracking.md"
                        Success = $true
                        Message = "Updated with validation report entry"
                    }
                } catch {
                    $results += @{
                        File = "validation-tracking.md"
                        Success = $false
                        Message = "Failed to update: $($_.Exception.Message)"
                    }
                    Write-Warning "Failed to update validation tracking: $($_.Exception.Message)"
                }
            }

            default {
                Write-Warning "Document type '$DocumentType' not yet supported by Update-DocumentTrackingFiles"
                return @()
            }
        }

        # Summary
        if ($DryRun) {
            Write-Host ""
            Write-Host "DRY RUN SUMMARY:" -ForegroundColor Yellow
            foreach ($result in $results) {
                $status = if ($result.Success) { "✅" } else { "❌" }
                Write-Host "  $status $($result.File): $($result.Message)" -ForegroundColor Cyan
            }
        } else {
            $successCount = ($results | Where-Object { $_.Success }).Count
            $totalCount = $results.Count
            Write-Verbose "📊 Tracking files updated: $successCount/$totalCount successful"

            foreach ($result in $results) {
                if (-not $result.Success) {
                    Write-Warning "❌ $($result.File): $($result.Message)"
                }
            }
        }

        return $results
    }
    catch {
        Write-Error "Failed to update document tracking files: $($_.Exception.Message)"
        throw
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Update-DocumentTrackingFiles'
)

Write-Verbose "DocumentTracking module loaded with 1 function"
