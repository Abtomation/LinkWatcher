#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates technical debt status updates in the Technical Debt Tracker state file

.DESCRIPTION
This script automates debt item lifecycle transitions in technical-debt-tracking.md.

Updates the following file:
- doc/process-framework/state-tracking/permanent/technical-debt-tracking.md

Supports two operation modes:
1. Status-only update: Changes Status and Resolution Date columns in the Registry table
2. Completion (Resolved): Moves debt item from Registry to "Recently Resolved" section,
   drops Estimated Effort and Status columns, sets Resolution Date, updates frontmatter date

Registry table columns (11):
  | ID | Description | Category | Location | Created Date | Priority | Estimated Effort | Status | Resolution Date | Assessment ID | Notes |
  idx: 0     1            2          3          4               5          6                  7        8                 9               10

Recently Resolved table columns (9):
  | ID | Description | Category | Location | Created Date | Priority | Resolution Date | Assessment ID | Notes |
  idx: 0     1            2          3          4               5          6                 7               8

.PARAMETER DebtId
The technical debt ID to update (e.g., "TD005")

.PARAMETER NewStatus
The new status. Valid values: Open, InProgress, Resolved

.PARAMETER ResolutionNotes
Description of what was done. Required when NewStatus is Resolved.
Appended to the Notes column in the Recently Resolved table.

.PARAMETER PlanLink
Optional markdown link to the refactoring plan (e.g., "[TD006](../../refactoring/plans/td006.md)").
When provided, replaces the plain ID in the Recently Resolved table.

.EXAMPLE
# Mark debt item as in progress
.\Update-TechDebt.ps1 -DebtId "TD005" -NewStatus "InProgress"

.EXAMPLE
# Resolve a debt item
.\Update-TechDebt.ps1 -DebtId "TD011" -NewStatus "Resolved" -ResolutionNotes "Replaced bare except: with except Exception:"

.EXAMPLE
# Resolve with plan link
.\Update-TechDebt.ps1 -DebtId "TD006" -NewStatus "Resolved" -ResolutionNotes "Extracted public API methods." -PlanLink "[TD006](../../refactoring/plans/td006-encapsulation-violation-fix.md)"

.NOTES
This script is part of the Technical Debt automation system and integrates with:
- Code Refactoring Task (PF-TSK-022)
- Technical Debt Assessment Task (PF-TSK-023)
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^TD\d+$')]
    [string]$DebtId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Open", "InProgress", "Resolved")]
    [string]$NewStatus,

    [Parameter(Mandatory = $false)]
    [string]$ResolutionNotes,

    [Parameter(Mandatory = $false)]
    [string]$PlanLink
)

# --- Configuration ---

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../Common-ScriptHelpers.psm1") -Force

$ProjectRoot = Get-ProjectRoot
$TargetFile = Join-Path -Path $ProjectRoot -ChildPath "doc/process-framework/state-tracking/permanent/technical-debt-tracking.md"
$ScriptName = "Update-TechDebt.ps1"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

# --- Shared utilities ---

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

    if (-not (Test-Path $TargetFile)) {
        Write-Log "Target file not found: $TargetFile" -Level "ERROR"
        return $false
    }

    if ($NewStatus -eq "Resolved" -and -not $ResolutionNotes) {
        Write-Log "ResolutionNotes is required when transitioning to Resolved" -Level "ERROR"
        return $false
    }

    Write-Log "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

# --- Content-transformer functions ---
# Each takes a $Content string and returns modified $Content string.
# Return $null to signal an error.

function Update-StatusInPlace {
    param(
        [string]$Content,
        [string]$DebtId,
        [string]$NewStatus
    )

    # Find the debt item row in the Registry table
    # Match rows starting with | TD### or | [TD###] (linked IDs)
    $pattern = "\|\s*(?:\[)?$DebtId(?:\][^\|]*)?\s*\|[^\r\n]*"
    $match = [regex]::Match($Content, $pattern)

    if (-not $match.Success) {
        Write-Log "Debt item not found in Registry table: $DebtId" -Level "ERROR"
        return $null
    }

    $currentEntry = $match.Value
    Write-Log "Found debt item entry for $DebtId"

    # Parse columns (11 columns in Registry table)
    # | ID | Description | Category | Location | Created Date | Priority | Estimated Effort | Status | Resolution Date | Assessment ID | Notes |
    $columns = $currentEntry -split '\|' | ForEach-Object { $_.Trim() }
    if ($columns[0] -eq '') { $columns = $columns[1..($columns.Length - 1)] }
    if ($columns[-1] -eq '') { $columns = $columns[0..($columns.Length - 2)] }

    # Column indices: 7 = Status
    $columns[7] = $NewStatus

    $updatedEntry = "| " + ($columns -join " | ") + " |"
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-Log "Updated $DebtId status to: $NewStatus" -Level "SUCCESS"
    return $result
}

function Move-ToResolvedSection {
    param(
        [string]$Content,
        [string]$DebtId,
        [string]$ResolutionNotes,
        [string]$PlanLink
    )

    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # Find the debt item row in the Registry table (## Technical Debt Registry section)
    $rowIndex = -1
    $inRegistrySection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Technical Debt Registry") { $inRegistrySection = $true }
        if ($lines[$i] -match "^## Recently Resolved") { break }
        if ($inRegistrySection -and $lines[$i] -match "^\|\s*(?:\[)?$DebtId(?:\]|\s*\|)") {
            $rowIndex = $i
            break
        }
    }

    if ($rowIndex -eq -1) {
        Write-Log "Could not find $DebtId in Registry table" -Level "ERROR"
        return $null
    }

    # Parse the row columns (11 columns)
    # | ID | Description | Category | Location | Created Date | Priority | Estimated Effort | Status | Resolution Date | Assessment ID | Notes |
    $row = $lines[$rowIndex]
    $columns = $row -split '\|' | ForEach-Object { $_.Trim() }
    if ($columns[0] -eq '') { $columns = $columns[1..($columns.Length - 1)] }
    if ($columns[-1] -eq '') { $columns = $columns[0..($columns.Length - 2)] }

    # Extract fields for the Resolved table (9 columns)
    # Drop: Estimated Effort (idx 6), Status (idx 7)
    # Set: Resolution Date (was idx 8) to current date
    $idValue = if ($PlanLink) { $PlanLink } else { $columns[0] }
    $description = $columns[1]
    $category = $columns[2]
    $location = $columns[3]
    $createdDate = $columns[4]
    $priority = $columns[5]
    $resolutionDate = $CurrentDate
    $assessmentId = $columns[9]
    $notes = $columns[10]

    # Append resolution notes to existing notes
    if ($ResolutionNotes) {
        if ($notes -and $notes -ne '-') {
            $notes = "$notes $ResolutionNotes"
        }
        else {
            $notes = $ResolutionNotes
        }
    }

    # Remove the row from Registry table
    $lines.RemoveAt($rowIndex)
    Write-Log "Removed $DebtId from Technical Debt Registry"

    # Build the Resolved table row (9 columns)
    # | ID | Description | Category | Location | Created Date | Priority | Resolution Date | Assessment ID | Notes |
    $resolvedRow = "| $idValue | $description | $category | $location | $createdDate | $priority | $resolutionDate | $assessmentId | $notes |"

    # Find insertion point: after the last data row in "Recently Resolved" section
    $insertAfterIndex = -1
    $inResolvedSection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Recently Resolved") { $inResolvedSection = $true }
        if ($inResolvedSection -and $lines[$i] -match "^## (?!Recently Resolved)") { break }
        if ($inResolvedSection -and $lines[$i] -match "^\|\s*(?:\[)?TD\d+") { $insertAfterIndex = $i }
    }

    # If no TD rows in Resolved section, insert after the table separator
    if ($insertAfterIndex -eq -1) {
        $inResolvedSection = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^## Recently Resolved") { $inResolvedSection = $true }
            if ($inResolvedSection -and $lines[$i] -match "^\|\s*-") {
                $insertAfterIndex = $i
                break
            }
        }
    }

    if ($insertAfterIndex -eq -1) {
        Write-Log "Could not find insertion point in Recently Resolved section" -Level "ERROR"
        return $null
    }

    $lines.Insert($insertAfterIndex + 1, $resolvedRow)
    Write-Log "Added $DebtId to Recently Resolved section" -Level "SUCCESS"

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
    Write-Log "Starting Technical Debt Update - $ScriptName"
    Write-Log "Debt ID: $DebtId"
    Write-Log "New Status: $NewStatus"

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    if (-not $PSCmdlet.ShouldProcess($TargetFile, "Update $DebtId to $NewStatus")) {
        return
    }

    # Single read-modify-write cycle
    $content = Get-Content $TargetFile -Raw

    $isResolution = $NewStatus -eq "Resolved"

    if ($isResolution) {
        # Move row from Registry to Recently Resolved
        $content = Move-ToResolvedSection -Content $content -DebtId $DebtId -ResolutionNotes $ResolutionNotes -PlanLink $PlanLink
        if ($null -eq $content) {
            Write-Log "Failed to move $DebtId to Recently Resolved section" -Level "ERROR"
            exit 1
        }
    }
    else {
        # Status-only update in Registry table
        $content = Update-StatusInPlace -Content $content -DebtId $DebtId -NewStatus $NewStatus
        if ($null -eq $content) {
            Write-Log "Failed to update $DebtId status" -Level "ERROR"
            exit 1
        }
    }

    # Update frontmatter date
    $content = Update-FrontmatterDate -Content $content

    # Single write
    Set-Content -Path $TargetFile -Value $content -NoNewline

    Write-Log "Technical debt update completed successfully" -Level "SUCCESS"
    Write-Log "Updated file: $TargetFile"
}

# Execute main function
Main
