#!/usr/bin/env pwsh

<#
.SYNOPSIS
Moves a feature from active tracking to the Archived Features section in feature-tracking.md

.DESCRIPTION
This script automates feature archival by:
1. Removing the feature row from its active category table
2. Adding a reformatted row to the "Archived Features" section
3. Updating the archived features summary count
4. Updating the Progress Summary (via Update-FeatureTrackingSummary)
5. Adding an Update History entry
6. Updating frontmatter date

Uses the Move-MarkdownTableRow helper from TableOperations.psm1 for the row move.

.PARAMETER FeatureId
The feature ID to archive (e.g., "4.1.1")

.PARAMETER Rationale
Why the feature is being archived (e.g., "Generalized into framework (PF-PRO-009)")

.PARAMETER Replacement
Markdown link(s) to replacement documentation (e.g., "[Testing Setup Guide](path/to/guide.md)")

.PARAMETER ArchiveDate
Date of archival (optional — defaults to current date in yyyy-MM-dd format)

.PARAMETER DryRun
If specified, shows what would be changed without modifying any files

.EXAMPLE
.\Archive-Feature.ps1 -FeatureId "4.1.1" -Rationale "Generalized into framework" -Replacement "[Testing Setup Guide](path)" -Confirm:$false

.EXAMPLE
.\Archive-Feature.ps1 -FeatureId "4.1.1" -Rationale "Generalized into framework" -Replacement "[Guide](path)" -DryRun

.NOTES
Addresses: PF-IMP-178 (separate archived features from active features table)
Created: 2026-03-24
Version: 1.0
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$FeatureId,

    [Parameter(Mandatory = $true)]
    [string]$Rationale,

    [Parameter(Mandatory = $true)]
    [string]$Replacement,

    [Parameter(Mandatory = $false)]
    [string]$ArchiveDate,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Configuration
$ProjectRoot = Get-ProjectRoot
$TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/product-docs/state-tracking/permanent/feature-tracking.md"
$CurrentDate = if ($ArchiveDate) { $ArchiveDate } else { Get-Date -Format "yyyy-MM-dd" }

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )
}

function Update-ArchivedSummaryCount {
    param([string]$Content)

    # Count data rows in the Archived Features section
    $count = 0
    $inArchivedSection = $false
    foreach ($line in ($Content -split "\r?\n")) {
        if ($line -match "^## Archived Features") { $inArchivedSection = $true }
        if ($inArchivedSection -and $line -match "^\s*</details>") { break }
        if ($inArchivedSection -and $line -match "^\|\s*\[?\d+\.\d+\.\d+") { $count++ }
    }

    # Update the <summary> tag
    $result = $Content -replace '(?<=Show archived features \()\d+(?= items?\))', $count.ToString()

    Write-Log "Updated archived features summary count to $count items" -Level "SUCCESS"
    return $result
}

function Add-UpdateHistoryEntry {
    param(
        [string]$Content,
        [string]$FeatureId,
        [string]$Rationale
    )

    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # Find the Update History table — insert after the last data row
    $insertAfterIndex = -1
    $inHistorySection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Update History") { $inHistorySection = $true }
        if ($inHistorySection -and $lines[$i] -match "^\|[^-]" -and $lines[$i] -notmatch "^\|\s*Date") {
            $insertAfterIndex = $i
        }
    }

    if ($insertAfterIndex -eq -1) {
        $inHistorySection = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^## Update History") { $inHistorySection = $true }
            if ($inHistorySection -and $lines[$i] -match "^\|\s*-") {
                $insertAfterIndex = $i
                break
            }
        }
    }

    if ($insertAfterIndex -eq -1) {
        Write-Log "Could not find Update History table" -Level "ERROR"
        return $null
    }

    $historyRow = "| $CurrentDate | Archived feature ${FeatureId}: $Rationale | [Archive-Feature.ps1](../../../process-framework/scripts/update/Archive-Feature.ps1) |"
    $lines.Insert($insertAfterIndex + 1, $historyRow)

    Write-Log "Added Update History entry" -Level "SUCCESS"
    return ($lines -join "`r`n")
}

function Remove-EmptyCategorySection {
    <#
    .SYNOPSIS
    Removes a <details> category section if it contains no feature data rows (only header + separator).
    Only targets sections within "## Feature Categories" that contain a feature table (ID | Feature | Status header).
    Also removes the corresponding ToC entry.
    Returns the modified content, or the original content if the section still has data.
    #>
    param(
        [string]$Content,
        [string]$FeatureId
    )

    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # Find the "## Feature Categories" section boundaries
    $featureCategoriesStart = -1
    $featureCategoriesEnd = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## Feature Categories') { $featureCategoriesStart = $i }
        elseif ($featureCategoriesStart -ge 0 -and $lines[$i] -match '^## ' -and $i -ne $featureCategoriesStart) {
            $featureCategoriesEnd = $i
            break
        }
    }

    if ($featureCategoriesStart -eq -1) {
        Write-Log "No '## Feature Categories' section found" -Level "INFO"
        return $Content
    }
    if ($featureCategoriesEnd -eq -1) { $featureCategoriesEnd = $lines.Count }

    # Search for empty <details> blocks only within Feature Categories
    $blockStart = -1
    $blockEnd = -1
    $sectionTitle = $null

    for ($i = $featureCategoriesStart; $i -lt $featureCategoriesEnd; $i++) {
        if ($lines[$i] -match '^\s*<details>') {
            $candidateStart = $i
            $candidateEnd = -1
            $hasDataRow = $false
            $hasFeatureTable = $false
            $candidateTitle = $null

            for ($j = $i + 1; $j -lt $featureCategoriesEnd; $j++) {
                if ($lines[$j] -match '<summary><strong>(.+?)</strong></summary>') {
                    $candidateTitle = $matches[1]
                }
                # Detect feature table header (must have ID and Feature columns)
                if ($lines[$j] -match '^\|\s*ID\s*\|.*Feature') {
                    $hasFeatureTable = $true
                }
                if ($lines[$j] -match '^\|\s*\[?\d+\.\d+\.\d+') {
                    $hasDataRow = $true
                }
                if ($lines[$j] -match '^\s*</details>') {
                    $candidateEnd = $j
                    break
                }
            }

            if ($candidateEnd -ne -1 -and $hasFeatureTable -and -not $hasDataRow) {
                $blockStart = $candidateStart
                $blockEnd = $candidateEnd
                $sectionTitle = $candidateTitle
                break
            }
        }
    }

    if ($blockStart -eq -1) {
        Write-Log "No empty category section found to remove" -Level "INFO"
        return $Content
    }

    # Remove the block (including any blank line after </details>)
    $removeEnd = $blockEnd
    if ($removeEnd + 1 -lt $lines.Count -and $lines[$removeEnd + 1].Trim() -eq '') {
        $removeEnd++
    }
    $lines.RemoveRange($blockStart, $removeEnd - $blockStart + 1)
    Write-Log "Removed empty category section: $sectionTitle" -Level "SUCCESS"

    # Remove the corresponding ToC entry
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*-\s*\[' -and $lines[$i] -match [regex]::Escape($sectionTitle)) {
            $lines.RemoveAt($i)
            Write-Log "Removed ToC entry for: $sectionTitle" -Level "SUCCESS"
            break
        }
    }

    return ($lines -join "`r`n")
}

# --- Main ---

function Main {
    Write-Log "Starting Feature Archival - Archive-Feature.ps1"
    Write-Log "Feature ID: $FeatureId"
    Write-Log "Rationale: $Rationale"

    if (-not (Test-Path $TrackingFile)) {
        Write-Log "Feature tracking file not found: $TrackingFile" -Level "ERROR"
        exit 1
    }

    if ($DryRun) {
        Write-Log "DRY RUN MODE - No files will be modified" -Level "WARN"
    }

    if (-not $DryRun -and -not $PSCmdlet.ShouldProcess($TrackingFile, "Archive feature $FeatureId")) {
        return
    }

    $content = Get-Content $TrackingFile -Raw

    # Step 1: Move row from active table to Archived Features section
    # The source section varies by feature category — search across all category sections
    # by using "## Feature Categories" as a broad source section
    $columnMapping = [ordered]@{
        "ID"           = "ID"
        "Feature"      = "Feature"
        "Archive Date" = "Archive Date"
        "Rationale"    = "Rationale"
        "Replacement"  = "Replacement"
    }
    $additionalColumns = [ordered]@{
        "Archive Date" = $CurrentDate
        "Rationale"    = $Rationale
        "Replacement"  = $Replacement
    }

    $result = Move-MarkdownTableRow `
        -Content $content `
        -RowIdPattern ([regex]::Escape($FeatureId)) `
        -SourceSection "## Feature Categories" `
        -DestinationSection "## Archived Features" `
        -ColumnMapping $columnMapping `
        -AdditionalColumns $additionalColumns `
        -SectionEndPattern '^## Archived Features'

    if ($null -eq $result.Content) {
        Write-Log "Failed to move feature $FeatureId to Archived Features section" -Level "ERROR"
        if ($result.SourceRow) {
            Write-Log "Source row was found but insertion failed. Check destination section exists." -Level "ERROR"
        }
        exit 1
    }

    $content = $result.Content
    Write-Log "Moved feature $FeatureId from active table to Archived Features" -Level "SUCCESS"
    Write-Log "  Source row: $($result.SourceRow)" -Level "INFO"
    Write-Log "  Destination row: $($result.DestinationRow)" -Level "INFO"

    # Step 2: Remove empty category section if the archived feature was the last one
    $content = Remove-EmptyCategorySection -Content $content -FeatureId $FeatureId

    if ($DryRun) {
        Write-Log "DRY RUN complete. No files modified." -Level "WARN"
        return
    }

    # Step 3: Update archived features summary count
    $content = Update-ArchivedSummaryCount -Content $content

    # Step 4: Recalculate Progress Summary
    $content = Update-FeatureTrackingSummary -Content $content
    Write-Log "Recalculated Progress Summary" -Level "SUCCESS"

    # Step 5: Add Update History entry
    $content = Add-UpdateHistoryEntry -Content $content -FeatureId $FeatureId -Rationale $Rationale
    if ($null -eq $content) {
        Write-Log "Failed to add Update History entry" -Level "ERROR"
        exit 1
    }

    # Step 6: Update frontmatter date
    $content = $content -replace '(?m)(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate
    Write-Log "Updated frontmatter date to $CurrentDate" -Level "SUCCESS"

    # Write
    Set-Content -Path $TrackingFile -Value $content -NoNewline
    Write-Log "Feature archival completed successfully" -Level "SUCCESS"
    Write-Log "Updated file: $TrackingFile"
}

Main
