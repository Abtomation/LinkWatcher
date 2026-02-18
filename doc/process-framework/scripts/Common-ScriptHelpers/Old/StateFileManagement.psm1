# StateFileManagement.psm1
# State file operations and tracking file management
# Provides markdown table updates, batch processing, and state file utilities

<#
.SYNOPSIS
State file operations and tracking file management for PowerShell scripts

.DESCRIPTION
This module provides functionality for:
- Markdown table updates and manipulation
- Batch processing of multiple tracking files
- State file backup and restoration
- Tracking file relevance determination

.NOTES
Version: 3.0 (Modularized from Common-ScriptHelpers v2.0)
Created: 2025-08-26
#>

# Import dependencies
$scriptPath = Split-Path -Parent $PSScriptRoot
$coreModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers/Core.psm1"
$outputModule = Join-Path -Path $scriptPath -ChildPath "Common-ScriptHelpers/OutputFormatting.psm1"

if (Test-Path $coreModule) { Import-Module $coreModule -Force }
if (Test-Path $outputModule) { Import-Module $outputModule -Force }

function Update-MarkdownTable {
    <#
    .SYNOPSIS
    Updates a markdown table with new values for a specific feature ID

    .PARAMETER Content
    The full content of the markdown file

    .PARAMETER FeatureId
    The feature ID to locate and update

    .PARAMETER StatusColumn
    The column name to update with the status

    .PARAMETER Status
    The new status value

    .PARAMETER AdditionalUpdates
    Hashtable of additional column updates (column name -> value)

    .PARAMETER Notes
    Additional notes to append to the Notes column

    .EXAMPLE
    $updatedContent = Update-MarkdownTable -Content $content -FeatureId "1.2.3" -StatusColumn "Status" -Status "🟢 Completed"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$StatusColumn,

        [Parameter(Mandatory=$true)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalUpdates = @{},

        [Parameter(Mandatory=$false)]
        [string]$Notes
    )

    $lines = $Content -split '\r?\n'
    $updatedLines = @()
    $inTable = $false
    $headerLine = ""
    $separatorLine = ""
    $columnIndices = @{}

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Detect table start (header line with pipes)
        if ($line -match '^\|.*\|$' -and -not $inTable) {
            $inTable = $true
            $headerLine = $line

            # Parse column headers properly, preserving empty cells
            $rawHeaders = $headerLine -split '\|'
            # Remove first and last empty elements (before first | and after last |)
            if ($rawHeaders.Count -gt 2) {
                $rawHeaders = $rawHeaders[1..($rawHeaders.Count-2)]
            }
            # Trim whitespace but preserve structure
            $headers = $rawHeaders | ForEach-Object { $_.Trim() }

            for ($j = 0; $j -lt $headers.Count; $j++) {
                if ($headers[$j] -ne '') {
                    $columnIndices[$headers[$j]] = $j
                }
            }

            $updatedLines += $line
            continue
        }

        # Skip separator line
        if ($inTable -and $line -match '^\|[-\s:]+\|$') {
            $separatorLine = $line
            $updatedLines += $line
            continue
        }

        # Process table rows
        if ($inTable -and $line -match '^\|.*\|$') {
            # Parse columns properly, preserving empty cells
            $rawColumns = $line -split '\|'
            # Remove first and last empty elements (before first | and after last |)
            if ($rawColumns.Count -gt 2) {
                $rawColumns = $rawColumns[1..($rawColumns.Count-2)]
            }
            # Trim whitespace but preserve empty cells
            $columns = $rawColumns | ForEach-Object { $_.Trim() }

            # Check if this row contains our feature ID
            if ($columns.Count -gt 0 -and $columns[0] -eq $FeatureId) {
                # Ensure we have exactly the right number of columns to match the header
                $headerCount = $columnIndices.Count
                while ($columns.Count -lt $headerCount) {
                    $columns += ""
                }
                # Trim excess columns if any
                if ($columns.Count -gt $headerCount) {
                    $columns = $columns[0..($headerCount-1)]
                }

                # Update the specified columns
                if ($columnIndices.ContainsKey($StatusColumn)) {
                    $statusIndex = $columnIndices[$StatusColumn]
                    if ($statusIndex -lt $columns.Count) {
                        $columns[$statusIndex] = $Status
                    }
                }

                # Apply additional updates
                foreach ($columnName in $AdditionalUpdates.Keys) {
                    if ($columnIndices.ContainsKey($columnName)) {
                        $updateIndex = $columnIndices[$columnName]
                        if ($updateIndex -lt $columns.Count) {
                            $columns[$updateIndex] = $AdditionalUpdates[$columnName]
                        }
                    }
                }

                # Add notes if specified and Notes column exists
                if ($Notes -and $columnIndices.ContainsKey("Notes")) {
                    $notesIndex = $columnIndices["Notes"]
                    if ($notesIndex -lt $columns.Count) {
                        $existingNotes = $columns[$notesIndex]
                        if ($existingNotes -and $existingNotes -ne "-" -and $existingNotes -ne "") {
                            $columns[$notesIndex] = "$existingNotes; $Notes"
                        } else {
                            $columns[$notesIndex] = $Notes
                        }
                    }
                }

                # Reconstruct the line
                $updatedLine = "| " + ($columns -join " | ") + " |"
                $updatedLines += $updatedLine
            } else {
                $updatedLines += $line
            }
        }
        # End of table detection
        elseif ($inTable -and $line -notmatch '^\|.*\|$') {
            $inTable = $false
            $updatedLines += $line
        }
        else {
            $updatedLines += $line
        }
    }

    return $updatedLines -join "`n"
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
        [string]$Notes
    )

    $results = @()

    foreach ($trackingFile in $TrackingFiles) {
        $filePath = $trackingFile.Path
        $fileType = $trackingFile.Type
        $isRequired = $trackingFile.Required

        try {
            if (-not (Test-Path $filePath)) {
                if ($isRequired) {
                    throw "Required tracking file not found: $filePath"
                } else {
                    Write-Warning "Optional tracking file not found: $filePath"
                    $results += @{
                        Path = $filePath
                        Type = $fileType
                        Success = $false
                        Message = "File not found (optional)"
                    }
                    continue
                }
            }

            # Read current content
            $content = Get-Content -Path $filePath -Raw -Encoding UTF8

            # Update the content
            $updatedContent = Update-MarkdownTable -Content $content -FeatureId $FeatureId -StatusColumn $StatusColumn -Status $Status -AdditionalUpdates $AdditionalUpdates -Notes $Notes

            # Write back to file
            Set-Content -Path $filePath -Value $updatedContent -Encoding UTF8

            Write-Verbose "Updated tracking file: $filePath"
            $results += @{
                Path = $filePath
                Type = $fileType
                Success = $true
                Message = "Successfully updated"
            }
        }
        catch {
            $errorMessage = "Failed to update $filePath`: $($_.Exception.Message)"
            if ($isRequired) {
                throw $errorMessage
            } else {
                Write-Warning $errorMessage
                $results += @{
                    Path = $filePath
                    Type = $fileType
                    Success = $false
                    Message = $errorMessage
                }
            }
        }
    }

    return $results
}

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

        # Create backup
        $backupPath = "$featureTrackingPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $featureTrackingPath $backupPath

        # Parse and update the table content
        $updatedContent = Update-MarkdownTable -Content $content -FeatureId $FeatureId -StatusColumn $StatusColumn -Status $Status -AdditionalUpdates $AdditionalUpdates -Notes $Notes

        # Update metadata
        $updatedContent = $updatedContent -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $(Get-ProjectTimestamp -Format 'Date')"

        # Save updated content
        Set-Content $featureTrackingPath $updatedContent -Encoding UTF8

        Write-ProjectSuccess "Updated feature tracking for $FeatureId"
        return $updateInfo
    }
    catch {
        Write-ProjectError "Failed to update feature tracking for $FeatureId`: $($_.Exception.Message)"
        throw
    }
}

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
                        $featureTrackingDir = Split-Path (Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/feature-tracking.md") -Parent
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

                        # Calculate relative path from architecture-tracking.md to the ADR
                        $archTrackingDir = Split-Path $archTrackingPath -Parent
                        $relativePath = [System.IO.Path]::GetRelativePath($archTrackingDir, $DocumentPath)
                        $relativePath = $relativePath -replace '\\', '/'  # Convert to forward slashes for markdown

                        # Read the architecture tracking file
                        $content = Get-Content -Path $archTrackingPath -Raw -Encoding UTF8

                        # Find the ADR Index section and add the new entry
                        $lines = $content -split '\r?\n'
                        $updatedLines = @()
                        $inAdrSection = $false
                        $addedEntry = $false

                        for ($i = 0; $i -lt $lines.Count; $i++) {
                            $line = $lines[$i]

                            # Detect ADR Index section
                            if ($line -match "## Architectural Decision Records \(ADR\) Index") {
                                $inAdrSection = $true
                                $updatedLines += $line
                                continue
                            }

                            # If we're in the ADR section and find the table header
                            if ($inAdrSection -and $line -match "^\|\s*ADR ID\s*\|\s*Title\s*\|\s*Status\s*\|\s*Impact Level\s*\|\s*Related Features\s*\|$") {
                                $updatedLines += $line

                                # Look for and add the separator line
                                if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -match "^\|[-\s:|]+$") {
                                    $i++
                                    $updatedLines += $lines[$i]

                                    # Add the new ADR entry after the separator
                                    $statusEmoji = switch ($status) {
                                        "Accepted" { "✅" }
                                        "Proposed" { "🟡" }
                                        "Rejected" { "❌" }
                                        "Deprecated" { "⚠️" }
                                        default { "🟡" }
                                    }

                                    $newEntry = "| [$DocumentId]($relativePath) | $title | $statusEmoji $status | $($impactLevel -or 'High') | $($relatedFeatureId -or 'TBD') |"
                                    $updatedLines += $newEntry
                                    $addedEntry = $true
                                }
                                continue
                            }

                            # End of ADR section detection
                            if ($inAdrSection -and $line -match "^##" -and $line -notmatch "## Architectural Decision Records") {
                                $inAdrSection = $false
                            }

                            $updatedLines += $line
                        }

                        if ($addedEntry) {
                            # Write back to file
                            $updatedContent = $updatedLines -join "`n"
                            Set-Content -Path $archTrackingPath -Value $updatedContent -Encoding UTF8
                            Write-Verbose "Updated architecture-tracking.md with ADR: $DocumentId"
                        } else {
                            Write-Warning "Could not find ADR Index table in architecture-tracking.md"
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

                            # Calculate relative path from feature-tracking.md to the ADR
                            $featureTrackingDir = Split-Path $featureTrackingPath -Parent
                            $relativePath = [System.IO.Path]::GetRelativePath($featureTrackingDir, $DocumentPath)
                            $relativePath = $relativePath -replace '\\', '/'  # Convert to forward slashes for markdown

                            # Read the feature tracking file
                            $content = Get-Content -Path $featureTrackingPath -Raw -Encoding UTF8

                            # Find the feature row and update the ADR column
                            $lines = $content -split '\r?\n'
                            $updatedLines = @()
                            $featureUpdated = $false

                            for ($i = 0; $i -lt $lines.Count; $i++) {
                                $line = $lines[$i]

                                # Look for the feature row - match exact feature ID in the first data column
                                # Split first to check the exact column content
                                $testColumns = $line -split '\|' | ForEach-Object { $_.Trim() }
                                if ($testColumns.Count -gt 1 -and $testColumns[1] -eq $relatedFeatureId) {
                                    # Split the line into columns
                                    $columns = $line -split '\|' | ForEach-Object { $_.Trim() }

                                    # For architecture features (0.X), ADR is column 6 (0-based index)
                                    # Table: | ID | Feature | Status | Priority | Doc Tier | ADR | Tech Design | Arch Context | Test Status | Test Spec | Dependencies | Notes |
                                    # Index:  0   1        2        3         4        5      6            7             8            9         10            11        12
                                    # Note: Index 0, 10, 13 are empty due to table formatting
                                    if ($relatedFeatureId -match "^0\.") {
                                        # Architecture feature - ADR column is index 6
                                        if ($columns.Count -gt 6) {
                                            $currentAdr = $columns[6]
                                            if ($currentAdr -eq "N/A" -or $currentAdr -eq "TBD" -or [string]::IsNullOrWhiteSpace($currentAdr)) {
                                                $columns[6] = "[$DocumentId]($relativePath)"
                                            } else {
                                                # Append to existing ADRs
                                                $columns[6] = "$currentAdr, [$DocumentId]($relativePath)"
                                            }
                                            # Reconstruct the line properly, filtering out empty columns at the beginning and end
                                            $nonEmptyColumns = @()
                                            $startIndex = 0
                                            $endIndex = $columns.Count - 1

                                            # Find first non-empty column
                                            for ($k = 0; $k -lt $columns.Count; $k++) {
                                                if (-not [string]::IsNullOrWhiteSpace($columns[$k])) {
                                                    $startIndex = $k
                                                    break
                                                }
                                            }

                                            # Find last non-empty column
                                            for ($k = $columns.Count - 1; $k -ge 0; $k--) {
                                                if (-not [string]::IsNullOrWhiteSpace($columns[$k])) {
                                                    $endIndex = $k
                                                    break
                                                }
                                            }

                                            # Extract the meaningful columns (should be 12 columns for architecture features)
                                            $meaningfulColumns = $columns[$startIndex..$endIndex]

                                            # Ensure we have exactly 12 columns for architecture features
                                            while ($meaningfulColumns.Count -lt 12) {
                                                $meaningfulColumns += ""
                                            }
                                            if ($meaningfulColumns.Count -gt 12) {
                                                $meaningfulColumns = $meaningfulColumns[0..11]
                                            }

                                            $updatedLine = "| " + ($meaningfulColumns -join " | ") + " |"
                                            $updatedLines += $updatedLine
                                            $featureUpdated = $true
                                              Write-Verbose "Updated feature $relatedFeatureId with ADR: $DocumentId"
                                        } else {
                                            $updatedLines += $line
                                            Write-Warning "Feature row for $relatedFeatureId doesn't have enough columns for ADR update"
                                        }
                                    } else {
                                        # Regular feature - would need different column mapping
                                        $updatedLines += $line
                                        Write-Verbose "Regular feature ADR updates not yet implemented for feature: $relatedFeatureId"
                                    }
                                } else {
                                    $updatedLines += $line
                                }
                            }

                            if ($featureUpdated) {
                                # Write back to file
                                $updatedContent = $updatedLines -join "`n"
                                Set-Content -Path $featureTrackingPath -Value $updatedContent -Encoding UTF8
                                Write-Verbose "Updated feature-tracking.md for feature: $relatedFeatureId"
                            } else {
                                Write-Warning "Could not find feature $relatedFeatureId in feature-tracking.md"
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

                # Update documentation-map.md with new ADR
                try {
                    Write-Verbose "DocumentPath parameter: '$DocumentPath'"
                    if ([string]::IsNullOrEmpty($DocumentPath)) {
                        Write-Warning "DocumentPath is null or empty - cannot update documentation-map.md"
                        $results += @{
                            File = "documentation-map.md"
                            Success = $false
                            Message = "DocumentPath parameter is null or empty"
                        }
                        return
                    }

                    $docMapPath = Join-Path $projectRoot "doc/process-framework/documentation-map.md"
                    if (Test-Path $docMapPath) {
                        $docMapContent = Get-Content -Path $docMapPath -Raw
                        $lines = $docMapContent -split "`n"

                        # Find the appropriate ADR section based on document ID pattern
                        $sectionToUpdate = "Infrastructure & Tooling ADRs"  # Default section

                        # Determine section based on document ID pattern
                        if ($DocumentId -match "^ADR-\d+$") {
                            $sectionToUpdate = "Core Architecture ADRs"
                        } elseif ($DocumentId -match "^SF-ADR-\d+$") {
                            $sectionToUpdate = "Security Framework ADRs"
                        } elseif ($DocumentId -match "^PD-ADR-\d+$") {
                            $sectionToUpdate = "Infrastructure & Tooling ADRs"
                        }

                        # Find the section and add the new ADR
                        $sectionFound = $false
                        $insertIndex = -1

                        for ($i = 0; $i -lt $lines.Count; $i++) {
                            if ($lines[$i] -match "#### $sectionToUpdate") {
                                $sectionFound = $true
                                # Find the next section or end of ADRs to insert before
                                for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                                    if ($lines[$j] -match "^#### " -or $lines[$j] -match "^## ") {
                                        $insertIndex = $j
                                        break
                                    }
                                }
                                if ($insertIndex -eq -1) {
                                    # If no next section found, insert at end of file
                                    $insertIndex = $lines.Count
                                }
                                break
                            }
                        }

                        if ($sectionFound) {
                            # Create the new ADR entry - calculate relative path from documentation-map.md
                            $docMapDir = Split-Path $docMapPath -Parent
                            $docMapRelativePath = [System.IO.Path]::GetRelativePath($docMapDir, $DocumentPath).Replace('\', '/')
                            $adrTitle = $title
                            $adrDescription = if ($description) { " - $description" } else { "" }
                            $newAdrEntry = "- [$DocumentId`: $adrTitle]($docMapRelativePath)$adrDescription"

                            # Insert the new entry (before the next section)
                            $updatedLines = @()
                            $updatedLines += $lines[0..($insertIndex-1)]
                            $updatedLines += $newAdrEntry
                            $updatedLines += $lines[$insertIndex..($lines.Count-1)]

                            # Write back to file
                            $updatedContent = $updatedLines -join "`n"
                            Set-Content -Path $docMapPath -Value $updatedContent -Encoding UTF8
                            Write-Verbose "Updated documentation-map.md with new ADR: $DocumentId"

                            $results += @{
                                File = "documentation-map.md"
                                Success = $true
                                Message = "Added ADR entry to $sectionToUpdate section"
                            }
                        } else {
                            Write-Warning "Could not find section '$sectionToUpdate' in documentation-map.md"
                            $results += @{
                                File = "documentation-map.md"
                                Success = $false
                                Message = "Section '$sectionToUpdate' not found"
                            }
                        }
                    } else {
                        Write-Warning "documentation-map.md not found at: $docMapPath"
                        $results += @{
                            File = "documentation-map.md"
                            Success = $false
                            Message = "File not found"
                        }
                    }
                } catch {
                    $results += @{
                        File = "documentation-map.md"
                        Success = $false
                        Message = "Failed to update: $($_.Exception.Message)"
                    }
                    Write-Warning "Failed to update documentation-map.md: $($_.Exception.Message)"
                }

                Write-Verbose "ADR tracking completed"
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
            Write-Host "📊 Tracking files updated: $successCount/$totalCount successful" -ForegroundColor Green

            foreach ($result in $results) {
                if (-not $result.Success) {
                    Write-Warning "❌ $($result.File): $($result.Message)"
                }
            }
        }

        return $results
    }
    catch {
        Write-ProjectError "Failed to update document tracking files: $($_.Exception.Message)"
        throw
    }
}

function Add-TestTrackingEntry {
    <#
    .SYNOPSIS
    Adds a new feature entry to test-implementation-tracking.md

    .DESCRIPTION
    Creates a new row in the test-implementation-tracking.md file for a feature that doesn't exist yet.
    Determines the appropriate section based on the feature ID and adds the entry there.

    .PARAMETER FeatureId
    The feature ID to add (e.g., "99.1.3", "1.2.3")

    .PARAMETER TestFileId
    The test file ID (e.g., "PD-TST-069")

    .PARAMETER TestFile
    The test file path and link

    .PARAMETER Status
    The initial implementation status

    .PARAMETER TestType
    The type of test (Unit, Widget, Integration, E2E)

    .PARAMETER ComponentName
    The name of the component being tested

    .PARAMETER DryRun
    If specified, shows what would be added without making changes

    .EXAMPLE
    Add-TestTrackingEntry -FeatureId "99.1.3" -TestFileId "PD-TST-069" -TestFile "[PD-TST-069](../../../test/unit/test.dart)" -Status "🟡 Implementation In Progress" -TestType "Unit" -ComponentName "AuthService"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$TestFileId,

        [Parameter(Mandatory=$true)]
        [string]$TestFile,

        [Parameter(Mandatory=$true)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [string]$TestType = "",

        [Parameter(Mandatory=$false)]
        [string]$ComponentName = "",

        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )

    try {
        $projectRoot = Get-ProjectRoot
        $timestamp = Get-ProjectTimestamp -Format "Date"
        $testTrackingPath = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/test-implementation-tracking.md"

        if (-not (Test-Path $testTrackingPath)) {
            throw "Test implementation tracking file not found: $testTrackingPath"
        }

        # Read current content
        $content = Get-Content $testTrackingPath -Raw -Encoding UTF8

        # Determine the appropriate section based on feature ID
        $sectionTitle = Get-TestTrackingSectionTitle -FeatureId $FeatureId
        $sectionNumber = Get-TestTrackingSectionNumber -FeatureId $FeatureId

        # Create the new table row
        $notes = "$TestType test for $ComponentName component - created for live testing"
        if ($TestType -eq "" -or $ComponentName -eq "") {
            $notes = "Test file created: $TestFileId ($timestamp)"
        }

        $newRow = "| $TestFileId | $FeatureId | $TestFile | $Status | 0 | $timestamp | $notes |"

        if ($DryRun) {
            Write-Host "DRY RUN: Would add new entry to test-implementation-tracking.md" -ForegroundColor Yellow
            Write-Host "  Section: $sectionNumber. $sectionTitle" -ForegroundColor Cyan
            Write-Host "  Row: $newRow" -ForegroundColor Cyan
            return $true
        }

        # Find the section and add the entry
        $lines = $content -split '\r?\n'
        $updatedLines = @()
        $sectionFound = $false
        $entryAdded = $false

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]

            # Look for the section header (escape special regex characters)
            $escapedSectionTitle = [regex]::Escape($sectionTitle)
            if ($line -match "^## $sectionNumber\.\s+$escapedSectionTitle") {
                $sectionFound = $true
                $updatedLines += $line
                continue
            }

            # If we're in the right section, look for the table
            if ($sectionFound -and $line -match '^\| Test File ID \| Feature ID \|') {
                $updatedLines += $line

                # Add the separator line
                if ($i + 1 -lt $lines.Count) {
                    $updatedLines += $lines[$i + 1]  # Add separator line
                    $i++  # Skip the separator line in the main loop
                }

                # Check if this is an empty table (next line contains "No test files created yet")
                if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -match '\*No test files created yet\*') {
                    # Replace the "No test files" line with our new entry
                    $i++  # Skip the "No test files" line
                    $updatedLines += $newRow
                } else {
                    # Add to existing table - just add the new row
                    $updatedLines += $newRow
                }
                $entryAdded = $true
                $sectionFound = $false  # Reset to prevent adding to other sections
                continue
            }

            # Check if we've moved to a different section (reset sectionFound)
            if ($sectionFound -and $line -match '^## \d+\.') {
                $sectionFound = $false
            }

            $updatedLines += $line
        }

        if (-not $entryAdded) {
            # Section doesn't exist, create it
            $updatedLines = Add-TestTrackingSection -Lines $updatedLines -SectionNumber $sectionNumber -SectionTitle $sectionTitle -NewRow $newRow
            $entryAdded = $true
        }

        # Update the file's updated timestamp
        $updatedContent = ($updatedLines -join "`r`n") -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $timestamp"

        # Save updated content
        Set-Content $testTrackingPath $updatedContent -Encoding UTF8

        Write-Verbose "Added new entry to test-implementation-tracking.md: $TestFileId for feature $FeatureId"
        return $true

    } catch {
        Write-Error "Failed to add test tracking entry: $($_.Exception.Message)"
        return $false
    }
}

function Get-TestTrackingSectionTitle {
    <#
    .SYNOPSIS
    Determines the appropriate section title for a feature ID in test-implementation-tracking.md
    #>
    param([string]$FeatureId)

    # Parse feature ID to determine section
    if ($FeatureId -match '^99\.') {
        return "Test Features (Development & Testing)"
    } elseif ($FeatureId -match '^0\.') {
        return "System Architecture & Foundation Tests"
    } elseif ($FeatureId -match '^1\.') {
        return "User Authentication & Registration Tests"
    } else {
        return "Other Tests"
    }
}

function Get-TestTrackingSectionNumber {
    <#
    .SYNOPSIS
    Determines the appropriate section number for a feature ID in test-implementation-tracking.md
    #>
    param([string]$FeatureId)

    # Parse feature ID to determine section number
    if ($FeatureId -match '^99\.') {
        return "99"
    } elseif ($FeatureId -match '^0\.') {
        return "0"
    } elseif ($FeatureId -match '^1\.') {
        return "1"
    } else {
        return "12"  # Default "Other" section
    }
}

function Add-TestTrackingSection {
    <#
    .SYNOPSIS
    Adds a new section to test-implementation-tracking.md if it doesn't exist
    #>
    param(
        [string[]]$Lines,
        [string]$SectionNumber,
        [string]$SectionTitle,
        [string]$NewRow
    )

    # Find the correct insertion point based on section numbering
    $insertIndex = -1
    $targetSectionNumber = [int]$SectionNumber

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]

        # Look for section headers
        if ($line -match '^## (\d+)\.') {
            $currentSectionNumber = [int]$matches[1]

            # If we find a section with a higher number, insert before it
            if ($currentSectionNumber -gt $targetSectionNumber) {
                $insertIndex = $i
                break
            }
        }

        # If we reach the end of sections (Process Instructions, etc.), insert before them
        if ($line -match '^## Process Instructions' -or $line -match '^# Process Instructions') {
            $insertIndex = $i
            break
        }
    }

    if ($insertIndex -eq -1) {
        $insertIndex = $Lines.Count
    }

    # Create the new section
    $newSection = @(
        "",
        "## $SectionNumber. $SectionTitle",
        "",
        "| Test File ID | Feature ID | Test File | Implementation Status | Test Cases Count | Last Updated | Notes |",
        "|--------------|------------|-----------|----------------------|------------------|--------------|-------|",
        $NewRow,
        ""
    )

    # Insert the new section
    $result = @()
    $result += $Lines[0..($insertIndex-1)]
    $result += $newSection
    $result += $Lines[$insertIndex..($Lines.Count-1)]

    return $result
}

function Update-TestImplementationStatus {
    <#
    .SYNOPSIS
    Updates test implementation tracking files for a specific feature

    .PARAMETER FeatureId
    The feature ID to update

    .PARAMETER Status
    The new test implementation status

    .PARAMETER AdditionalUpdates
    Hashtable of additional column updates (column name -> value)

    .PARAMETER Notes
    Additional notes to append

    .PARAMETER DryRun
    If specified, shows what would be updated without making changes

    .EXAMPLE
    $additionalUpdates = @{
        "Test File" = "[PD-TST-001](test/unit/example_test.dart)"
        "Test Cases Count" = "15"
    }
    Update-TestImplementationStatus -FeatureId "1.2.3" -Status "🟡 Implementation In Progress" -AdditionalUpdates $additionalUpdates
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalUpdates = @{},

        [Parameter(Mandatory=$false)]
        [string]$Notes,

        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )

    try {
        $projectRoot = Get-ProjectRoot
        $timestamp = Get-ProjectTimestamp -Format "Date"
        $results = @()

        Write-Verbose "Updating test implementation status for feature: $FeatureId"

        # 1. Update test-implementation-tracking.md
        $testTrackingPath = Join-Path $projectRoot "doc/process-framework/state-tracking/permanent/test-implementation-tracking.md"
        if (Test-Path $testTrackingPath) {
            try {
                if ($DryRun) {
                    Write-Host "DRY RUN: Would update test-implementation-tracking.md" -ForegroundColor Yellow
                    Write-Host "  Feature ID: $FeatureId" -ForegroundColor Cyan
                    Write-Host "  Status: $Status" -ForegroundColor Cyan
                    if ($AdditionalUpdates.Count -gt 0) {
                        Write-Host "  Additional Updates:" -ForegroundColor Cyan
                        foreach ($key in $AdditionalUpdates.Keys) {
                            Write-Host "    $key = $($AdditionalUpdates[$key])" -ForegroundColor Cyan
                        }
                    }
                } else {
                    # For new test files, always add them to the tracking file
                    if ($AdditionalUpdates.ContainsKey("Test File ID")) {
                        Write-Verbose "Adding new test file to test-implementation-tracking.md"

                        # Extract information from AdditionalUpdates to create the entry
                        $testFileId = $AdditionalUpdates["Test File ID"]
                        $testFile = if ($AdditionalUpdates.ContainsKey("Test File")) { $AdditionalUpdates["Test File"] } else { "[Unknown](unknown)" }
                        $testType = if ($AdditionalUpdates.ContainsKey("Test Type")) { $AdditionalUpdates["Test Type"] } else { "" }
                        $componentName = if ($AdditionalUpdates.ContainsKey("Component Name")) { $AdditionalUpdates["Component Name"] } else { "" }

                        # Create the new entry
                        $addResult = Add-TestTrackingEntry -FeatureId $FeatureId -TestFileId $testFileId -TestFile $testFile -Status $Status -TestType $testType -ComponentName $componentName -DryRun:$false

                        if ($addResult) {
                            Write-Verbose "Successfully added new entry for test file $testFileId"
                        } else {
                            Write-Warning "Failed to add new entry for test file $testFileId"
                        }
                    } else {
                        # This is an update to an existing entry, use the regular update method
                        Write-Verbose "Updating existing test file in test-implementation-tracking.md"

                        # Read current content
                        $content = Get-Content $testTrackingPath -Raw -Encoding UTF8

                    # Update the table using the existing Update-MarkdownTable function
                        $updatedContent = Update-MarkdownTable -Content $content -FeatureId $FeatureId -StatusColumn "Implementation Status" -Status $Status -AdditionalUpdates $AdditionalUpdates -Notes $Notes

                        # Update the file's updated timestamp
                        $updatedContent = $updatedContent -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $timestamp"

                        # Save updated content
                        Set-Content $testTrackingPath $updatedContent -Encoding UTF8
                        Write-Verbose "Updated test-implementation-tracking.md"
                    }
                }

                $results += @{
                    File = "test-implementation-tracking.md"
                    Success = $true
                    Message = "Updated test implementation status to: $Status"
                }
            } catch {
                $results += @{
                    File = "test-implementation-tracking.md"
                    Success = $false
                    Message = "Failed to update: $($_.Exception.Message)"
                }
                Write-Warning "Failed to update test-implementation-tracking.md: $($_.Exception.Message)"
            }
        }

        # 2. Update test-registry.yaml
        $testRegistryPath = Join-Path $projectRoot "test/test-registry.yaml"
        if (Test-Path $testRegistryPath) {
            try {
                if ($DryRun) {
                    Write-Host "DRY RUN: Would update test-registry.yaml" -ForegroundColor Yellow
                    Write-Host "  Update test files for feature: $FeatureId" -ForegroundColor Cyan
                    Write-Host "  Status: $Status" -ForegroundColor Cyan
                } else {
                    # Read YAML content (basic text processing since we don't have YAML parser)
                    $yamlContent = Get-Content $testRegistryPath -Raw -Encoding UTF8

                    # Find test entries for this feature and update status
                    $lines = $yamlContent -split '\r?\n'
                    $updatedLines = @()
                    $inTestFile = $false
                    $currentFeatureId = ""
                    $updated = $false

                    for ($i = 0; $i -lt $lines.Count; $i++) {
                        $line = $lines[$i]

                        # Detect start of test file entry
                        if ($line -match '^\s*-\s+id:\s+') {
                            $inTestFile = $true
                            $currentFeatureId = ""
                        }

                        # Extract feature ID
                        if ($inTestFile -and $line -match '^\s+featureId:\s+"([^"]+)"') {
                            $currentFeatureId = $matches[1]
                        }

                        # Update status if this is our feature
                        if ($inTestFile -and $currentFeatureId -eq $FeatureId -and $line -match '^\s+status:\s+') {
                            $updatedLines += "    status: `"$Status`""
                            $updated = $true
                        }
                        # Update testCasesCount if provided in AdditionalUpdates
                        elseif ($inTestFile -and $currentFeatureId -eq $FeatureId -and $line -match '^\s+testCasesCount:\s+' -and $AdditionalUpdates.ContainsKey("Test Cases Count")) {
                            $testCasesCount = $AdditionalUpdates["Test Cases Count"]
                            $updatedLines += "    testCasesCount: $testCasesCount"
                        }
                        # Update updated timestamp if this is our feature
                        elseif ($inTestFile -and $currentFeatureId -eq $FeatureId -and $line -match '^\s+updated:\s+') {
                            $updatedLines += "    updated: `"$timestamp`""
                        }
                        else {
                            $updatedLines += $line
                        }

                        # Reset when we hit a new entry or end
                        if ($line -match '^\s*-\s+id:' -and $i -gt 0) {
                            $inTestFile = $true
                            $currentFeatureId = ""
                        } elseif ($line -match '^[a-zA-Z]' -and -not ($line -match '^\s*#')) {
                            $inTestFile = $false
                        }
                    }

                    # Save updated YAML
                    $updatedYaml = $updatedLines -join "`n"
                    Set-Content $testRegistryPath $updatedYaml -Encoding UTF8
                    Write-Verbose "Updated test-registry.yaml"
                }

                $results += @{
                    File = "test-registry.yaml"
                    Success = $true
                    Message = "Updated test registry status for feature $FeatureId"
                }
            } catch {
                $results += @{
                    File = "test-registry.yaml"
                    Success = $false
                    Message = "Failed to update: $($_.Exception.Message)"
                }
                Write-Warning "Failed to update test-registry.yaml: $($_.Exception.Message)"
            }
        }

        # 3. Update feature-tracking.md (Test Status column)
        try {
            if ($DryRun) {
                Write-Host "DRY RUN: Would update feature-tracking.md" -ForegroundColor Yellow
                Write-Host "  Feature ID: $FeatureId" -ForegroundColor Cyan
                Write-Host "  Test Status: $Status" -ForegroundColor Cyan
            } else {
                # Map test implementation status to feature tracking test status
                # Use pattern matching to avoid Unicode comparison issues
                $featureTestStatus = $Status
                $specCreated = "📝 Specs Created"
                $inProgress = "🟡 In Progress"
                $readyForAudit = "🔄 Ready for Audit"
                $completed = "✅ Completed"
                $approved = "✅ Approved"
                $failing = "🔴 Failing"
                $blocked = "⛔ Blocked"
                $needsUpdate = "🔄 Needs Update"

                if ($Status -like "*Specification Created*") { $featureTestStatus = $specCreated }
                elseif ($Status -like "*Implementation In Progress*") { $featureTestStatus = $inProgress }
                elseif ($Status -like "*Ready for Validation*") { $featureTestStatus = $readyForAudit }
                elseif ($Status -like "*Tests Implemented*") { $featureTestStatus = $completed }
                elseif ($Status -like "*Tests Approved with Dependencies*") { $featureTestStatus = $approved }
                elseif ($Status -like "*Tests Failing*") { $featureTestStatus = $failing }
                elseif ($Status -like "*Implementation Blocked*") { $featureTestStatus = $blocked }
                elseif ($Status -like "*Needs Update*") { $featureTestStatus = $needsUpdate }

                $featureAdditionalUpdates = @{
                    "Test Status" = $featureTestStatus
                }

                $featureNotes = if ($Notes) { $Notes } else { "Test implementation status updated: $Status ($timestamp)" }

                Update-FeatureTrackingStatus -FeatureId $FeatureId -Status $featureTestStatus -StatusColumn "Test Status" -AdditionalUpdates $featureAdditionalUpdates -Notes $featureNotes
                Write-Verbose "Updated feature-tracking.md"
            }

            $results += @{
                File = "feature-tracking.md"
                Success = $true
                Message = "Updated feature test status"
            }
        } catch {
            $results += @{
                File = "feature-tracking.md"
                Success = $false
                Message = "Failed to update: $($_.Exception.Message)"
            }
            Write-Warning "Failed to update feature-tracking.md: $($_.Exception.Message)"
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
            Write-Host "📊 Test implementation tracking updated: $successCount/$totalCount successful" -ForegroundColor Green

            foreach ($result in $results) {
                if (-not $result.Success) {
                    Write-Warning "❌ $($result.File): $($result.Message)"
                }
            }
        }

        return $results
    }
    catch {
        Write-ProjectError "Failed to update test implementation status: $($_.Exception.Message)"
        throw
    }
}

function Add-TestRegistryEntry {
    <#
    .SYNOPSIS
    Adds a new test file entry to test-registry.yaml

    .DESCRIPTION
    Creates a new test file entry in the test-registry.yaml file with proper formatting and metadata.
    Automatically generates the next available PD-TST ID and inserts the entry in the correct location.

    .PARAMETER FeatureId
    The feature ID this test belongs to (e.g., "0.2.5", "1.1.1")

    .PARAMETER FileName
    The test file name (e.g., "example_test.dart")

    .PARAMETER FilePath
    The relative path to the test file from project root (e.g., "test/unit/example_test.dart")

    .PARAMETER TestType
    The type of test (Unit, Widget, Integration, E2E)

    .PARAMETER ComponentName
    The name of the component being tested

    .PARAMETER SpecificationPath
    Optional path to the test specification file

    .PARAMETER Description
    Description of what the test covers

    .PARAMETER DryRun
    If specified, shows what would be added without making changes

    .EXAMPLE
    Add-TestRegistryEntry -FeatureId "0.2.5" -FileName "logger_test.dart" -FilePath "test/unit/logger_test.dart" -TestType "Unit" -ComponentName "Logger" -Description "Unit tests for Logger service"

    .RETURNS
    Returns the generated PD-TST ID if successful, null if failed
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$true)]
        [string]$FileName,

        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [string]$TestType,

        [Parameter(Mandatory=$true)]
        [string]$ComponentName,

        [Parameter(Mandatory=$false)]
        [string]$SpecificationPath = $null,

        [Parameter(Mandatory=$false)]
        [string]$Description = "",

        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )

    try {
        $projectRoot = Get-ProjectRoot
        $testRegistryPath = Join-Path $projectRoot "test/test-registry.yaml"
        $timestamp = Get-ProjectTimestamp -Format "Date"

        if (-not (Test-Path $testRegistryPath)) {
            throw "Test registry file not found: $testRegistryPath"
        }

        # Read current content
        $content = Get-Content $testRegistryPath -Raw -Encoding UTF8
        $lines = $content -split '\r?\n'

        # Find the highest existing PD-TST ID to generate the next one
        $maxId = 0
        foreach ($line in $lines) {
            if ($line -match '^\s*-\s+id:\s+PD-TST-(\d+)') {
                $currentId = [int]$matches[1]
                if ($currentId -gt $maxId) {
                    $maxId = $currentId
                }
            }
        }

        $newId = $maxId + 1
        $testFileId = "PD-TST-{0:D3}" -f $newId

        # Generate description if not provided
        if ([string]::IsNullOrEmpty($Description)) {
            $Description = "$TestType tests for $ComponentName component"
        }

        # Create the new entry
        $newEntry = @"
  - id: $testFileId
    featureId: "$FeatureId"
    fileName: "$FileName"
    filePath: "$FilePath"
    testType: "$TestType"
    componentName: "$ComponentName"
"@

        if (-not [string]::IsNullOrEmpty($SpecificationPath)) {
            $newEntry += "`n    specificationPath: `"$SpecificationPath`""
        } else {
            $newEntry += "`n    specificationPath: null"
        }

        $newEntry += @"

    description: "$Description"
    created: "$timestamp"
    updated: "$timestamp"
    status: "🟡 Implementation In Progress"
    testCasesCount: 0
"@

        if ($DryRun) {
            Write-Host "DRY RUN: Would add new entry to test-registry.yaml" -ForegroundColor Yellow
            Write-Host "  Test ID: $testFileId" -ForegroundColor Cyan
            Write-Host "  Feature ID: $FeatureId" -ForegroundColor Cyan
            Write-Host "  File: $FileName" -ForegroundColor Cyan
            Write-Host "  Path: $FilePath" -ForegroundColor Cyan
            Write-Host "  Type: $TestType" -ForegroundColor Cyan
            Write-Host "  Component: $ComponentName" -ForegroundColor Cyan
            Write-Host "  Entry:" -ForegroundColor Cyan
            Write-Host $newEntry -ForegroundColor Gray
            return $testFileId
        }

        # Since metadata sections were removed, we can append to the end
        # Just add the new entry at the end of the file
        $updatedLines = @()
        $updatedLines += $lines

        # Remove any trailing empty lines
        while ($updatedLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($updatedLines[-1])) {
            $updatedLines = $updatedLines[0..($updatedLines.Count-2)]
        }

        # Add blank line before new entry
        $updatedLines += ""
        $updatedLines += $newEntry -split '\r?\n'

        # Save the updated content
        $updatedContent = $updatedLines -join "`n"
        Set-Content $testRegistryPath $updatedContent -Encoding UTF8

        Write-Verbose "Added new test registry entry: $testFileId"
        return $testFileId
    }
    catch {
        Write-ProjectError "Failed to add test registry entry: $($_.Exception.Message)"
        throw
    }
}

function Update-FeatureTrackingStatusWithAppend {
    <#
    .SYNOPSIS
    Updates feature tracking status with the ability to append to existing column content

    .PARAMETER FeatureId
    The feature ID to update

    .PARAMETER Status
    The new status (e.g., "🟡 In Progress", "🟢 Completed", "🔄 Needs Revision")

    .PARAMETER StatusColumn
    The column to update (e.g., "Status", "Test Status", "Implementation Status")

    .PARAMETER AdditionalUpdates
    Hashtable of additional column updates (column name -> value)

    .PARAMETER AppendUpdates
    Hashtable of column updates that should be appended with " • " separator (column name -> value)

    .PARAMETER Notes
    Additional notes to append to the Notes column

    .PARAMETER DryRun
    If specified, shows what would be updated without making changes

    .EXAMPLE
    $appendUpdates = @{ "API Design" = "[PD-MDL-001](path/to/model.md)" }
    Update-FeatureTrackingStatusWithAppend -FeatureId "1.2.3" -Status "📋 API Design Created" -AppendUpdates $appendUpdates
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$false)]
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
            Write-Host "DRY RUN: Would update feature $FeatureId in $featureTrackingPath" -ForegroundColor Yellow
            if ($Status) {
                Write-Host "  $StatusColumn`: $Status" -ForegroundColor Cyan
            }
            foreach ($key in $AdditionalUpdates.Keys) {
                Write-Host "  $key`: $($AdditionalUpdates[$key])" -ForegroundColor Cyan
            }
            foreach ($key in $AppendUpdates.Keys) {
                Write-Host "  $key` (append): $($AppendUpdates[$key])" -ForegroundColor Cyan
            }
            if ($Notes) {
                Write-Host "  Notes: $Notes" -ForegroundColor Cyan
            }
            return $updateInfo
        }

        # Update the feature tracking file with robust table parsing
        Write-Verbose "Updating feature $FeatureId with status: $Status"

        # Create backup
        $backupPath = "$featureTrackingPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $featureTrackingPath $backupPath

        # Parse and update the table content with append support
        $updatedContent = Update-MarkdownTableWithAppend -Content $content -FeatureId $FeatureId -StatusColumn $StatusColumn -Status $Status -AdditionalUpdates $AdditionalUpdates -AppendUpdates $AppendUpdates -Notes $Notes

        # Update metadata
        $updatedContent = $updatedContent -replace "updated: \d{4}-\d{2}-\d{2}", "updated: $(Get-ProjectTimestamp -Format 'Date')"

        # Save updated content
        Set-Content $featureTrackingPath $updatedContent -Encoding UTF8

        Write-ProjectSuccess "Updated feature tracking for $FeatureId"
        return $updateInfo
    }
    catch {
        Write-ProjectError "Failed to update feature tracking for $FeatureId`: $($_.Exception.Message)"
        throw
    }
}

function Update-MarkdownTableWithAppend {
    <#
    .SYNOPSIS
    Updates a markdown table with new values for a specific feature ID, with support for appending to existing content

    .PARAMETER Content
    The full content of the markdown file

    .PARAMETER FeatureId
    The feature ID to locate and update

    .PARAMETER StatusColumn
    The column name to update with the status

    .PARAMETER Status
    The new status value

    .PARAMETER AdditionalUpdates
    Hashtable of additional column updates (column name -> value) - replaces existing content

    .PARAMETER AppendUpdates
    Hashtable of column updates that should be appended with " • " separator (column name -> value)

    .PARAMETER Notes
    Additional notes to append to the Notes column

    .EXAMPLE
    $appendUpdates = @{ "API Design" = "[PD-MDL-001](path/to/model.md)" }
    $updatedContent = Update-MarkdownTableWithAppend -Content $content -FeatureId "1.2.3" -StatusColumn "Status" -Status "🟢 Completed" -AppendUpdates $appendUpdates
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,

        [Parameter(Mandatory=$true)]
        [string]$FeatureId,

        [Parameter(Mandatory=$false)]
        [string]$StatusColumn,

        [Parameter(Mandatory=$false)]
        [string]$Status,

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalUpdates = @{},

        [Parameter(Mandatory=$false)]
        [hashtable]$AppendUpdates = @{},

        [Parameter(Mandatory=$false)]
        [string]$Notes
    )

    $lines = $Content -split '\r?\n'
    $updatedLines = @()
    $inTable = $false
    $headerLine = ""
    $separatorLine = ""
    $columnIndices = @{}

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Detect table start (header line with pipes)
        if ($line -match '^\|.*\|$' -and -not $inTable) {
            $inTable = $true
            $headerLine = $line

            # Parse column headers properly, preserving empty cells
            $rawHeaders = $headerLine -split '\|'
            # Remove first and last empty elements (before first | and after last |)
            if ($rawHeaders.Count -gt 2) {
                $rawHeaders = $rawHeaders[1..($rawHeaders.Count-2)]
            }
            # Trim whitespace but preserve structure
            $headers = $rawHeaders | ForEach-Object { $_.Trim() }

            for ($j = 0; $j -lt $headers.Count; $j++) {
                if ($headers[$j] -ne '') {
                    $columnIndices[$headers[$j]] = $j
                }
            }

            $updatedLines += $line
            continue
        }

        # Skip separator line
        if ($inTable -and $line -match '^\|[-\s:]+\|$') {
            $separatorLine = $line
            $updatedLines += $line
            continue
        }

        # Process table rows
        if ($inTable -and $line -match '^\|.*\|$') {
            # Parse columns properly, preserving empty cells
            $rawColumns = $line -split '\|'
            # Remove first and last empty elements (before first | and after last |)
            if ($rawColumns.Count -gt 2) {
                $rawColumns = $rawColumns[1..($rawColumns.Count-2)]
            }
            # Trim whitespace but preserve empty cells
            $columns = $rawColumns | ForEach-Object { $_.Trim() }

            # Check if this row contains our feature ID
            if ($columns.Count -gt 0 -and $columns[0] -eq $FeatureId) {
                # Ensure we have exactly the right number of columns to match the header
                $headerCount = $columnIndices.Count
                while ($columns.Count -lt $headerCount) {
                    $columns += ""
                }
                # Trim excess columns if any
                if ($columns.Count -gt $headerCount) {
                    $columns = $columns[0..($headerCount-1)]
                }

                # Update the status column if specified
                if ($Status -and $StatusColumn -and $columnIndices.ContainsKey($StatusColumn)) {
                    $statusIndex = $columnIndices[$StatusColumn]
                    if ($statusIndex -lt $columns.Count) {
                        $columns[$statusIndex] = $Status
                    }
                }

                # Apply regular updates (replace existing content)
                foreach ($columnName in $AdditionalUpdates.Keys) {
                    if ($columnIndices.ContainsKey($columnName)) {
                        $updateIndex = $columnIndices[$columnName]
                        if ($updateIndex -lt $columns.Count) {
                            $columns[$updateIndex] = $AdditionalUpdates[$columnName]
                        }
                    }
                }

                # Apply append updates (append with " • " separator)
                foreach ($columnName in $AppendUpdates.Keys) {
                    if ($columnIndices.ContainsKey($columnName)) {
                        $updateIndex = $columnIndices[$columnName]
                        if ($updateIndex -lt $columns.Count) {
                            $existingContent = $columns[$updateIndex]
                            $newContent = $AppendUpdates[$columnName]

                            # Handle different existing content scenarios
                            if ([string]::IsNullOrWhiteSpace($existingContent) -or $existingContent -eq "-" -or $existingContent -eq "No" -or $existingContent -eq "Yes") {
                                # Replace "Yes", "No", "-", or empty content entirely
                                $columns[$updateIndex] = $newContent
                            } else {
                                # Append with " • " separator
                                $columns[$updateIndex] = "$existingContent • $newContent"
                            }
                        }
                    }
                }

                # Add notes if specified and Notes column exists
                if ($Notes -and $columnIndices.ContainsKey("Notes")) {
                    $notesIndex = $columnIndices["Notes"]
                    if ($notesIndex -lt $columns.Count) {
                        $existingNotes = $columns[$notesIndex]
                        if ($existingNotes -and $existingNotes -ne "-" -and $existingNotes -ne "") {
                            $columns[$notesIndex] = "$existingNotes; $Notes"
                        } else {
                            $columns[$notesIndex] = $Notes
                        }
                    }
                }

                # Reconstruct the line
                $updatedLine = "| " + ($columns -join " | ") + " |"
                $updatedLines += $updatedLine
            } else {
                $updatedLines += $line
            }
        }
        # End of table detection
        elseif ($inTable -and $line -notmatch '^\|.*\|$' -and $line.Trim() -ne '') {
            $inTable = $false
            $updatedLines += $line
        }
        else {
            $updatedLines += $line
        }
    }

    return $updatedLines -join "`n"
}

# Export functions
Export-ModuleMember -Function @(
    'Update-MarkdownTable',
    'Update-MultipleTrackingFiles',
    'Get-RelevantTrackingFiles',
    'Get-StateFileBackup',
    'Update-FeatureTrackingStatus',
    'Update-FeatureTrackingStatusWithAppend',
    'Update-MarkdownTableWithAppend',
    'Update-DocumentTrackingFiles',
    'Update-TestImplementationStatus',
    'Add-TestRegistryEntry'
)
