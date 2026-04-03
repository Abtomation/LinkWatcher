#!/usr/bin/env pwsh

<#
.SYNOPSIS
Updates feature request status in the Feature Request Tracking state file

.DESCRIPTION
This script automates feature request lifecycle transitions in feature-request-tracking.md.

Used by Feature Request Evaluation (PF-TSK-067) to classify and close requests, and
can also be used to defer or reject requests.

Supports two operation modes:
1. Completion: Sets Classification and Feature columns, moves row from Active to Completed
   section, updates summary count, adds Update History entry, updates frontmatter date
2. Status-only update: Changes Status column (for Deferred/Rejected transitions)

For enhancements, also updates feature-tracking.md to set the target feature's status
to "Needs Revision" with a link to the Enhancement State Tracking File.

.PARAMETER RequestId
The feature request ID to update (e.g., "PD-FRQ-001")

.PARAMETER Classification
The classification result: "NewFeature" or "Enhancement"

.PARAMETER FeatureId
The target feature ID (e.g., "6.1.1" for enhancements, or "2.1.2" for new features)

.PARAMETER NewStatus
The new status. Valid values: Completed, Deferred, Rejected

.PARAMETER Notes
Additional notes to add to the Notes column (e.g., Enhancement State File link)

.PARAMETER FeatureName
Name of the new feature (new feature classification only). When provided with -Classification
"NewFeature", the script invokes New-FeatureImplementationState.ps1 to create the feature
state file and link it in feature-tracking.md.

.PARAMETER EnhancementStateFile
Path or link to the Enhancement State Tracking File (enhancement classification only).
When provided, feature-tracking.md is updated to set the target feature to "Needs Revision"
with a link to this file.

.PARAMETER UpdatedBy
Who performed the update (default: "AI Agent (PF-TSK-067)")

.EXAMPLE
# Classify as enhancement and complete
Update-FeatureRequest.ps1 -RequestId "PD-FRQ-001" -Classification "Enhancement" -FeatureId "6.1.1" -NewStatus "Completed" -EnhancementStateFile "Enhancement State File: [PF-STA-066](../temporary/enhancement-6-1-1-comment-filtering.md)" -Notes "Enhancement State File created"

.EXAMPLE
# Classify as new feature and complete (also creates feature state file)
Update-FeatureRequest.ps1 -RequestId "PD-FRQ-003" -Classification "NewFeature" -FeatureId "2.1.2" -FeatureName "TOML File Support" -NewStatus "Completed" -Notes "Added as feature 2.1.2 in feature-tracking.md"

.EXAMPLE
# Defer a request
Update-FeatureRequest.ps1 -RequestId "PD-FRQ-002" -NewStatus "Deferred" -Notes "Postponed until v3.0"

.EXAMPLE
# Reject a request
Update-FeatureRequest.ps1 -RequestId "PD-FRQ-004" -NewStatus "Rejected" -Notes "Out of scope for this project"

.NOTES
This script integrates with:
- Feature Request Evaluation (PF-TSK-067) — primary consumer
- Feature Tracking (feature-tracking.md) — updated for enhancement classifications
- Feature Enhancement (PF-TSK-068) — downstream consumer of enhancement state files
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^PD-FRQ-\d+$')]
    [string]$RequestId,

    [Parameter(Mandatory = $false)]
    [ValidateSet("NewFeature", "Enhancement")]
    [string]$Classification,

    [Parameter(Mandatory = $false)]
    [string]$FeatureId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Completed", "Deferred", "Rejected")]
    [string]$NewStatus,

    [Parameter(Mandatory = $false)]
    [string]$FeatureName = "",

    [Parameter(Mandatory = $false)]
    [string]$Notes = "",

    [Parameter(Mandatory = $false)]
    [string]$EnhancementStateFile = "",

    [Parameter(Mandatory = $false)]
    [string]$UpdatedBy = "AI Agent (PF-TSK-067)"
)

# Import the common helpers
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Configuration
$ProjectRoot = Get-ProjectRoot
$TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/feature-request-tracking.md"
$FeatureTrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/feature-tracking.md"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

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

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."

    if (-not (Test-Path $TrackingFile)) {
        Write-Log "Feature request tracking file not found: $TrackingFile" -Level "ERROR"
        return $false
    }

    # Validate required parameters for completion
    if ($NewStatus -eq "Completed") {
        if (-not $Classification) {
            Write-Log "Classification is required when completing a feature request" -Level "ERROR"
            return $false
        }
        if (-not $FeatureId) {
            Write-Log "FeatureId is required when completing a feature request" -Level "ERROR"
            return $false
        }
    }

    # Validate enhancement-specific parameters
    if ($Classification -eq "Enhancement" -and $EnhancementStateFile -and -not (Test-Path $FeatureTrackingFile)) {
        Write-Log "Feature tracking file not found: $FeatureTrackingFile" -Level "ERROR"
        return $false
    }

    Write-Log "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

# --- Content-transformation functions ---

function Update-RequestRow {
    param(
        [string]$Content,
        [string]$RequestId,
        [string]$Classification,
        [string]$FeatureId,
        [string]$Notes
    )

    # Find the request row in the Active table
    $pattern = "\|\s*$([regex]::Escape($RequestId))\s*\|[^\r\n]*"
    $match = [regex]::Match($Content, $pattern)

    if (-not $match.Success) {
        Write-Log "Feature request not found in Active table: $RequestId" -Level "ERROR"
        return $null
    }

    $currentEntry = $match.Value
    Write-Log "Found feature request entry for $RequestId"

    # Parse columns: | ID | Source | Description | Feature | Classification | Status | Last Updated | Notes |
    $columns = $currentEntry -split '\|' | ForEach-Object { $_.Trim() }
    if ($columns[0] -eq '') { $columns = $columns[1..($columns.Length - 1)] }
    if ($columns[-1] -eq '') { $columns = $columns[0..($columns.Length - 2)] }

    # Update columns
    if ($Classification) {
        $classLabel = if ($Classification -eq "NewFeature") { "New Feature" } else { "Enhancement" }
        $columns[4] = $classLabel
    }
    if ($FeatureId) {
        $columns[3] = $FeatureId
    }
    if ($Notes) {
        # Append to existing notes
        if ($columns[7] -and $columns[7] -ne "—") {
            $columns[7] = "$($columns[7]). $Notes"
        } else {
            $columns[7] = $Notes
        }
    }

    $updatedEntry = "| " + ($columns -join " | ") + " |"
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-Log "Updated $RequestId columns" -Level "SUCCESS"
    return $result
}

function Move-ToCompletedSection {
    param(
        [string]$Content,
        [string]$RequestId
    )

    # Source table: | ID | Source | Description | Feature | Classification | Status | Last Updated | Notes |
    # Dest table:   | ID | Source | Description | Feature | Classification | Completed Date | Notes |
    $columnMapping = [ordered]@{
        "ID"             = "ID"
        "Source"         = "Source"
        "Description"    = "Description"
        "Feature"        = "Feature"
        "Classification" = "Classification"
        "Completed Date" = "Completed Date"
        "Notes"          = "Notes"
    }
    $additionalColumns = [ordered]@{
        "Completed Date" = $CurrentDate
    }

    $result = Move-MarkdownTableRow `
        -Content $Content `
        -RowIdPattern ([regex]::Escape($RequestId)) `
        -SourceSection "## Active Feature Requests" `
        -DestinationSection "## Completed Requests" `
        -ColumnMapping $columnMapping `
        -AdditionalColumns $additionalColumns

    if ($null -eq $result.Content) {
        Write-Log "Failed to move $RequestId to Completed section" -Level "ERROR"
        return $null
    }

    Write-Log "Moved $RequestId to Completed Requests section" -Level "SUCCESS"
    return $result.Content
}

function Update-SummaryCount {
    param([string]$Content)

    $count = 0
    $inCompletedSection = $false
    foreach ($line in ($Content -split "\r?\n")) {
        if ($line -match "^## Completed Requests") { $inCompletedSection = $true }
        if ($inCompletedSection -and $line -match "^\s*</details>") { break }
        if ($inCompletedSection -and $line -match "^\|\s*PD-FRQ-\d+") { $count++ }
    }

    $result = $Content -replace '(?<=Show completed requests \()\d+(?= items?\))', $count.ToString()

    Write-Log "Updated completed summary count to $count items" -Level "SUCCESS"
    return $result
}

function Update-HistorySummaryCount {
    param([string]$Content)

    $count = 0
    $inHistorySection = $false
    foreach ($line in ($Content -split "\r?\n")) {
        if ($line -match "^## Update History") { $inHistorySection = $true }
        if ($inHistorySection -and $line -match "^\s*</details>") { break }
        if ($inHistorySection -and $line -match "^\|\s*\d{4}-") { $count++ }
    }

    $result = $Content -replace '(?<=Show update history \()\d+(?= entries?\))', $count.ToString()

    Write-Log "Updated history summary count to $count entries" -Level "SUCCESS"
    return $result
}

function Add-UpdateHistoryEntry {
    param(
        [string]$Content,
        [string]$HistoryNote,
        [string]$UpdatedBy
    )

    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

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

    $historyRow = "| $CurrentDate | $HistoryNote | $UpdatedBy |"
    $lines.Insert($insertAfterIndex + 1, $historyRow)

    Write-Log "Added Update History entry" -Level "SUCCESS"
    return ($lines -join "`r`n")
}

function Update-FrontmatterDate {
    param([string]$Content)

    $result = $Content -replace '(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate
    Write-Log "Updated frontmatter date to $CurrentDate" -Level "SUCCESS"
    return $result
}

function Update-FeatureTrackingForEnhancement {
    param(
        [string]$FeatureId,
        [string]$EnhancementStateFile
    )

    Write-Log "Updating feature-tracking.md for enhancement of feature $FeatureId..."

    $ftContent = Get-Content $FeatureTrackingFile -Raw

    # Find the feature row and update Status column to "🔄 Needs Revision"
    # The feature ID might be wrapped in a link: [6.1.1](path)
    $featurePattern = "\|[^\n]*(?:\[$([regex]::Escape($FeatureId))\]|$([regex]::Escape($FeatureId)))[^\n]*\|"
    $ftMatch = [regex]::Match($ftContent, $featurePattern)

    if (-not $ftMatch.Success) {
        Write-Log "Feature $FeatureId not found in feature-tracking.md" -Level "WARN"
        Write-Log "You will need to manually update feature-tracking.md" -Level "WARN"
        return
    }

    # Use Update-MarkdownTable to set status
    $ftContent = Update-MarkdownTable `
        -Content $ftContent `
        -FeatureId $FeatureId `
        -StatusColumn "Status" `
        -Status "🔄 Needs Revision" `
        -Notes $EnhancementStateFile

    if ($ftContent) {
        # Update frontmatter date
        $ftContent = $ftContent -replace '(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate

        Set-Content -Path $FeatureTrackingFile -Value $ftContent -NoNewline
        Write-Log "Updated feature $FeatureId to 'Needs Revision' in feature-tracking.md" -Level "SUCCESS"
    } else {
        Write-Log "Failed to update feature-tracking.md — update manually" -Level "WARN"
    }
}

# --- Main ---

function Main {
    Write-Log "Starting Feature Request Update"
    Write-Log "Request ID: $RequestId"
    Write-Log "New Status: $NewStatus"
    if ($Classification) { Write-Log "Classification: $Classification" }
    if ($FeatureId) { Write-Log "Feature ID: $FeatureId" }

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Update $RequestId to $NewStatus")) {
        return
    }

    # Single read-modify-write cycle for feature-request-tracking.md
    $content = Get-Content $TrackingFile -Raw

    $isCompletion = $NewStatus -eq "Completed"
    $isDeferReject = $NewStatus -in @("Deferred", "Rejected")

    if ($isCompletion) {
        # Step 1: Update Classification, Feature, and Notes columns
        $content = Update-RequestRow -Content $content -RequestId $RequestId -Classification $Classification -FeatureId $FeatureId -Notes $Notes
        if ($null -eq $content) { exit 1 }

        # Step 2: Move row from Active to Completed
        $content = Move-ToCompletedSection -Content $content -RequestId $RequestId
        if ($null -eq $content) { exit 1 }

        # Step 3: Update summary count
        $content = Update-SummaryCount -Content $content
    }
    elseif ($isDeferReject) {
        # For Deferred/Rejected: update status in-place and add notes
        $pattern = "\|\s*$([regex]::Escape($RequestId))\s*\|[^\r\n]*"
        $match = [regex]::Match($content, $pattern)

        if (-not $match.Success) {
            Write-Log "Feature request not found in Active table: $RequestId" -Level "ERROR"
            exit 1
        }

        $currentEntry = $match.Value
        $columns = $currentEntry -split '\|' | ForEach-Object { $_.Trim() }
        if ($columns[0] -eq '') { $columns = $columns[1..($columns.Length - 1)] }
        if ($columns[-1] -eq '') { $columns = $columns[0..($columns.Length - 2)] }

        $columns[5] = $NewStatus
        $columns[6] = $CurrentDate
        if ($Notes) {
            if ($columns[7] -and $columns[7] -ne "—") {
                $columns[7] = "$($columns[7]). $Notes"
            } else {
                $columns[7] = $Notes
            }
        }

        $updatedEntry = "| " + ($columns -join " | ") + " |"
        $content = $content.Replace($currentEntry, $updatedEntry)
        Write-Log "Updated $RequestId status to $NewStatus" -Level "SUCCESS"
    }

    # Step 4: Add Update History entry
    $classLabel = if ($Classification -eq "NewFeature") { "New Feature" } elseif ($Classification -eq "Enhancement") { "Enhancement" } else { "" }
    $historyNote = switch ($NewStatus) {
        "Completed" { "Classified $RequestId as $classLabel (feature $FeatureId) — $NewStatus" }
        "Deferred"  { "Deferred $RequestId`: $Notes" }
        "Rejected"  { "Rejected $RequestId`: $Notes" }
    }

    $content = Add-UpdateHistoryEntry -Content $content -HistoryNote $historyNote -UpdatedBy $UpdatedBy
    if ($null -eq $content) { exit 1 }

    # Step 5: Update history summary count
    $content = Update-HistorySummaryCount -Content $content

    # Step 6: Update frontmatter date
    $content = Update-FrontmatterDate -Content $content

    # Single write
    Set-Content -Path $TrackingFile -Value $content -NoNewline

    Write-Log "Feature request tracking file updated successfully" -Level "SUCCESS"

    # Step 7: For enhancements, also update feature-tracking.md
    if ($isCompletion -and $Classification -eq "Enhancement" -and $EnhancementStateFile) {
        Update-FeatureTrackingForEnhancement -FeatureId $FeatureId -EnhancementStateFile $EnhancementStateFile
    }

    # Step 8: For new features, create feature implementation state file
    if ($isCompletion -and $Classification -eq "NewFeature" -and $FeatureName) {
        $stateScript = Join-Path -Path $ProjectRoot -ChildPath "process-framework/scripts/file-creation/04-implementation/New-FeatureImplementationState.ps1"
        if (Test-Path $stateScript) {
            Write-Log "Creating feature implementation state file for $FeatureId ($FeatureName)..."
            try {
                & $stateScript -FeatureName $FeatureName -FeatureId $FeatureId -Description $Notes -Confirm:$false
                Write-Log "Feature implementation state file created and linked in feature-tracking.md" -Level "SUCCESS"
            }
            catch {
                Write-Log "Failed to create feature state file: $($_.Exception.Message)" -Level "WARN"
                Write-Log "Create it manually using New-FeatureImplementationState.ps1" -Level "WARN"
            }
        } else {
            Write-Log "New-FeatureImplementationState.ps1 not found at: $stateScript" -Level "WARN"
            Write-Log "Create the feature state file manually" -Level "WARN"
        }
    }

    # Summary
    Write-Log ""
    Write-Log "Feature request update completed:" -Level "SUCCESS"
    Write-Log "  Request: $RequestId → $NewStatus"
    if ($Classification) { Write-Log "  Classification: $classLabel" }
    if ($FeatureId) { Write-Log "  Feature: $FeatureId" }
    if ($FeatureName) { Write-Log "  Feature Name: $FeatureName" }
}

# Execute main function
Main
