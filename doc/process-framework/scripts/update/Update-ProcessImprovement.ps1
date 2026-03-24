#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates improvement status updates in the Process Improvement Tracking state file

.DESCRIPTION
This script automates improvement lifecycle transitions in process-improvement-tracking.md.

Updates the following file:
- doc/process-framework/state-tracking/permanent/process-improvement-tracking.md

Supports two operation modes:
1. Status-only update: Changes Status and Last Updated columns in the Current table
2. Completion: Moves improvement from Current to Completed section, updates summary count,
   adds Update History entry, and updates frontmatter date

When transitioning to Completed or Rejected:
- Removes the row from "Current Improvement Opportunities"
- Adds a reformatted row to "Completed Improvements" (inside <details> block)
- Updates the <summary> item count
- Adds an Update History entry
- Updates frontmatter updated date

.PARAMETER ImprovementId
The improvement ID to update (e.g., "IMP-063")

.PARAMETER NewStatus
The new status. Valid values: Identified, Prioritized, InProgress, Completed, Deferred, Rejected

.PARAMETER Impact
Impact level (HIGH, MEDIUM, LOW). Required when NewStatus is Completed or Rejected.

.PARAMETER ValidationNotes
Description of what was done. Required when NewStatus is Completed or Rejected.

.PARAMETER UpdateHistoryNote
Custom note for the Update History table. Auto-generated if not provided.

.PARAMETER UpdatedBy
Who performed the update (default: "AI Agent (PF-TSK-009)")

.EXAMPLE
# Mark improvement as in progress
Update-ProcessImprovement.ps1 -ImprovementId "IMP-063" -NewStatus "InProgress"

.EXAMPLE
# Complete an improvement
Update-ProcessImprovement.ps1 -ImprovementId "IMP-063" -NewStatus "Completed" -Impact "MEDIUM" -ValidationNotes "Created Update-ProcessImprovement.ps1 script."

.EXAMPLE
# Reject an improvement
Update-ProcessImprovement.ps1 -ImprovementId "IMP-061" -NewStatus "Rejected" -Impact "—" -ValidationNotes "Evaluated and determined not beneficial."

.EXAMPLE
# Defer an improvement
Update-ProcessImprovement.ps1 -ImprovementId "IMP-037" -NewStatus "Deferred"

.NOTES
This script is part of the Process Improvement automation system and integrates with:
- Process Improvement Task (PF-TSK-009)
- Tools Review Task (PF-TSK-010)
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(IMP|PF-IMP)-\d+$')]
    [string]$ImprovementId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Identified", "Prioritized", "InProgress", "Completed", "Deferred", "Rejected")]
    [string]$NewStatus,

    [Parameter(Mandatory = $false)]
    [ValidateSet("HIGH", "MEDIUM", "LOW", "—")]
    [string]$Impact,

    [Parameter(Mandatory = $false)]
    [string]$ValidationNotes,

    [Parameter(Mandatory = $false)]
    [string]$UpdateHistoryNote,

    [Parameter(Mandatory = $false)]
    [string]$UpdatedBy = "AI Agent (PF-TSK-009)"
)

# Import the common helpers for Get-ProjectRoot
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Configuration
$ProjectRoot = Get-ProjectRoot
$TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/process-framework/state-tracking/permanent/process-improvement-tracking.md"
$ScriptName = "Update-ProcessImprovement.ps1"
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
        Write-Log "Tracking file not found: $TrackingFile" -Level "ERROR"
        return $false
    }

    # Validate required parameters for completion/rejection
    if ($NewStatus -in @("Completed", "Rejected")) {
        if (-not $Impact) {
            Write-Log "Impact is required when transitioning to $NewStatus" -Level "ERROR"
            return $false
        }
        if (-not $ValidationNotes) {
            Write-Log "ValidationNotes is required when transitioning to $NewStatus" -Level "ERROR"
            return $false
        }
    }

    Write-Log "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

# --- Content-transformation functions ---
# Each takes a $Content string and returns modified $Content string.
# This enables a single read-modify-write cycle in Main.

function Update-StatusInPlace {
    param(
        [string]$Content,
        [string]$ImprovementId,
        [string]$NewStatus
    )

    # Find the improvement row in the Current table
    $pattern = "\|\s*$ImprovementId\s*\|[^\r\n]*"
    $match = [regex]::Match($Content, $pattern)

    if (-not $match.Success) {
        Write-Log "Improvement entry not found in Current table: $ImprovementId" -Level "ERROR"
        return $null
    }

    $currentEntry = $match.Value
    Write-Log "Found improvement entry for $ImprovementId"

    # Parse columns: | ID | Source | Description | Priority | Status | Last Updated | Notes |
    $columns = $currentEntry -split '\|' | ForEach-Object { $_.Trim() }
    if ($columns[0] -eq '') { $columns = $columns[1..($columns.Length - 1)] }
    # Remove trailing empty element
    if ($columns[-1] -eq '') { $columns = $columns[0..($columns.Length - 2)] }

    # Update Status (index 4) and Last Updated (index 5)
    $columns[4] = $NewStatus
    $columns[5] = $CurrentDate

    $updatedEntry = "| " + ($columns -join " | ") + " |"
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-Log "Updated $ImprovementId status to: $NewStatus" -Level "SUCCESS"
    return $result
}

function Move-ToCompletedSection {
    param(
        [string]$Content,
        [string]$ImprovementId,
        [string]$Impact,
        [string]$ValidationNotes
    )

    # Use the generic Move-MarkdownTableRow helper from TableOperations.psm1
    # Source table: | ID | Source | Description | Priority | Status | Last Updated | Notes |
    # Dest table:   | ID | Description | Completed Date | Impact | Validation Notes |
    $columnMapping = [ordered]@{
        "ID"               = "ID"
        "Description"      = "Description"
        "Completed Date"   = "Completed Date"
        "Impact"           = "Impact"
        "Validation Notes" = "Validation Notes"
    }
    $additionalColumns = [ordered]@{
        "Completed Date"   = $CurrentDate
        "Impact"           = $Impact
        "Validation Notes" = $ValidationNotes
    }

    $result = Move-MarkdownTableRow `
        -Content $Content `
        -RowIdPattern ([regex]::Escape($ImprovementId)) `
        -SourceSection "## Current Improvement Opportunities" `
        -DestinationSection "## Completed Improvements" `
        -ColumnMapping $columnMapping `
        -AdditionalColumns $additionalColumns

    if ($null -eq $result.Content) {
        Write-Log "Failed to move $ImprovementId to Completed section" -Level "ERROR"
        if ($result.SourceRow) {
            Write-Log "Source row found but insertion failed. Check destination section." -Level "ERROR"
        }
        return $null
    }

    Write-Log "Removed $ImprovementId from Current Improvement Opportunities"
    Write-Log "Added $ImprovementId to Completed Improvements section" -Level "SUCCESS"
    return $result.Content
}

function Update-SummaryCount {
    param([string]$Content)

    # Count IMP- rows in the Completed section
    $count = 0
    $inCompletedSection = $false
    foreach ($line in ($Content -split "\r?\n")) {
        if ($line -match "^## Completed Improvements") { $inCompletedSection = $true }
        if ($inCompletedSection -and $line -match "^\s*</details>") { break }
        if ($inCompletedSection -and $line -match "^\|\s*IMP-\d+") { $count++ }
    }

    # Update the <summary> tag: "Show completed improvements (N items)"
    $result = $Content -replace '(?<=Show completed improvements \()\d+(?= items?\))', $count.ToString()

    Write-Log "Updated summary count to $count items" -Level "SUCCESS"
    return $result
}

function Update-HistorySummaryCount {
    param([string]$Content)

    # Count data rows in the Update History section
    $count = 0
    $inHistorySection = $false
    foreach ($line in ($Content -split "\r?\n")) {
        if ($line -match "^## Update History") { $inHistorySection = $true }
        if ($inHistorySection -and $line -match "^\s*</details>") { break }
        if ($inHistorySection -and $line -match "^\|\s*\d{4}-" ) { $count++ }
    }

    # Update the <summary> tag: "Show update history (N entries)"
    $result = $Content -replace '(?<=Show update history \()\d+(?= entries?\))', $count.ToString()

    Write-Log "Updated history summary count to $count entries" -Level "SUCCESS"
    return $result
}

function Add-UpdateHistoryEntry {
    param(
        [string]$Content,
        [string]$ImprovementId,
        [string]$HistoryNote,
        [string]$UpdatedBy
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

    # If no data rows, insert after the separator
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

# --- Main ---

function Main {
    # Normalize short-form IDs: IMP-063 → PF-IMP-063
    if ($ImprovementId -match '^IMP-\d+$') {
        $script:ImprovementId = "PF-$ImprovementId"
    }

    Write-Log "Starting Process Improvement Update - $ScriptName"
    Write-Log "Improvement ID: $ImprovementId"
    Write-Log "New Status: $NewStatus"

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    $isCompletion = $NewStatus -in @("Completed", "Rejected")

    # Generate default history note if not provided
    if (-not $UpdateHistoryNote) {
        if ($isCompletion) {
            $statusLabel = if ($NewStatus -eq "Rejected") { "Rejected" } else { "Completed" }
            $UpdateHistoryNote = "$statusLabel $ImprovementId`: $ValidationNotes"
        }
        else {
            $UpdateHistoryNote = "Updated $ImprovementId status to $NewStatus"
        }
    }

    if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Update $ImprovementId to $NewStatus")) {
        return
    }

    # Single read-modify-write cycle
    $content = Get-Content $TrackingFile -Raw

    if ($isCompletion) {
        # Step 1: Move row from Current to Completed
        $content = Move-ToCompletedSection -Content $content -ImprovementId $ImprovementId -Impact $Impact -ValidationNotes $ValidationNotes
        if ($null -eq $content) {
            Write-Log "Failed to move $ImprovementId to Completed section" -Level "ERROR"
            exit 1
        }

        # Step 2: Update summary count
        $content = Update-SummaryCount -Content $content
    }
    else {
        # Status-only update in Current table
        $content = Update-StatusInPlace -Content $content -ImprovementId $ImprovementId -NewStatus $NewStatus
        if ($null -eq $content) {
            Write-Log "Failed to update $ImprovementId status" -Level "ERROR"
            exit 1
        }
    }

    # Step 3: Add Update History entry
    $content = Add-UpdateHistoryEntry -Content $content -ImprovementId $ImprovementId -HistoryNote $UpdateHistoryNote -UpdatedBy $UpdatedBy
    if ($null -eq $content) {
        Write-Log "Failed to add Update History entry" -Level "ERROR"
        exit 1
    }

    # Step 3b: Update history summary count
    $content = Update-HistorySummaryCount -Content $content

    # Step 4: Update frontmatter date
    $content = Update-FrontmatterDate -Content $content

    # Single write
    Set-Content -Path $TrackingFile -Value $content -NoNewline

    Write-Log "Process improvement update completed successfully" -Level "SUCCESS"
    Write-Log "Updated file: $TrackingFile"
}

# Execute main function
Main
