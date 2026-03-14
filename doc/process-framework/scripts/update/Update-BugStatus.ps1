#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates bug status updates in the Bug Tracking state file

.DESCRIPTION
This script automates bug status transitions in the ../bug-tracking.md state file,
supporting the complete bug lifecycle from Reported to Closed.

Updates the following file:
- ../doc/process-framework/state-tracking/permanent/bug-tracking.md

Supports all bug status transitions:
- 🆕 Reported → 🔍 Triaged (Bug Triage Task)
- 🔍 Triaged → 🟡 In Progress (Bug Fixing Task)
- 🟡 In Progress → 🧪 Testing (Bug Fixing Task)
- 🧪 Testing → ✅ Fixed (Bug Fixing Task)
- ✅ Fixed → 🔒 Closed (Bug Verification)
- Any Status → 🔄 Reopened (Bug Verification)

When transitioning to Closed:
- Automatically moves the bug entry from its active priority table to the Closed Bugs section
- Recalculates Bug Statistics (active counts by priority)

When transitioning to Reopened:
- Automatically moves the bug entry from the Closed Bugs section back to the appropriate active priority table
- Recalculates Bug Statistics (active counts by priority)

.PARAMETER BugId
The bug ID to update (e.g., "BUG-001")

.PARAMETER NewStatus
The new status for the bug. Valid values:
- "Triaged" (🔍)
- "InProgress" (🟡)
- "Testing" (🧪)
- "Fixed" (✅)
- "Closed" (🔒) — auto-moves to Closed section, recalculates stats
- "Reopened" (🔄)

.PARAMETER Priority
Bug priority (Critical, High, Medium, Low) - used when transitioning to Triaged

.PARAMETER Scope
Bug fix scope (S, M, L) - used to indicate fix complexity and whether a state file is needed



.PARAMETER FixDetails
Details about the fix implementation - used when transitioning to Fixed

.PARAMETER RootCause
Root cause analysis - used when transitioning to Fixed

.PARAMETER TestsAdded
Whether regression tests were added (Yes/No) - used when transitioning to Fixed

.PARAMETER PullRequestUrl
URL to the pull request containing the fix - used when transitioning to Fixed

.PARAMETER VerificationNotes
Notes from verification process - used when transitioning to Closed

.PARAMETER ReopenReason
Reason for reopening the bug - used when transitioning to Reopened

.PARAMETER UpdateDate
Date of the status update (optional - uses current date if not specified)

.EXAMPLE
# Triage a bug
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Triaged" -Priority "High" -Scope "S"

.EXAMPLE
# Start working on a bug
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "InProgress"

.EXAMPLE
# Mark bug as fixed
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Fixed" -FixDetails "Fixed null pointer exception in user validation" -RootCause "Missing null check" -TestsAdded "Yes" -PullRequestUrl "https://github.com/repo/pull/123"

.EXAMPLE
# Close a verified bug
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Closed" -VerificationNotes "Fix verified in production, no regressions detected"

.EXAMPLE
# Reopen a bug
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Reopened" -ReopenReason "Issue still occurs in edge case scenario"

.EXAMPLE
# Dry-run to preview changes without modifying the file
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "InProgress" -WhatIf

.NOTES
This script is part of the Bug Management automation system and integrates with:
- Bug Triage Task (PF-TSK-041)
- Bug Fixing Task (PF-TSK-007)
- Bug Verification processes
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$BugId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Triaged", "InProgress", "Testing", "Fixed", "Closed", "Reopened")]
    [string]$NewStatus,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Critical", "High", "Medium", "Low")]
    [string]$Priority,

    [Parameter(Mandatory = $false)]
    [ValidateSet("S", "M", "L")]
    [string]$Scope,

    [Parameter(Mandatory = $false)]
    [string]$FixDetails,

    [Parameter(Mandatory = $false)]
    [string]$RootCause,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Yes", "No")]
    [string]$TestsAdded,

    [Parameter(Mandatory = $false)]
    [string]$PullRequestUrl,

    [Parameter(Mandatory = $false)]
    [string]$VerificationNotes,

    [Parameter(Mandatory = $false)]
    [string]$ReopenReason,

    [Parameter(Mandatory = $false)]
    [datetime]$UpdateDate = (Get-Date)
)

# Import the common helpers for Get-ProjectRoot
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "Common-ScriptHelpers.psm1") -Force

# Configuration - use project-root-relative path for reliability
$ProjectRoot = Get-ProjectRoot
$BugTrackingFile = Join-Path -Path $ProjectRoot -ChildPath "../doc/process-framework/state-tracking/permanent/bug-tracking.md"
$ScriptName = "../Update-BugStatus.ps1"

# Status emoji mapping
$StatusEmojis = @{
    "Reported"   = "🆕"
    "Triaged"    = "🔍"
    "InProgress" = "🟡"
    "Testing"    = "🧪"
    "Fixed"      = "✅"
    "Closed"     = "🔒"
    "Reopened"   = "🔄"
}

# Column index mapping for bug-tracking.md table rows
# After splitting on '|' and trimming the empty leading element:
#   [0] = ID           (e.g., PD-BUG-001)
#   [1] = Title
#   [2] = Status       (emoji + status text)
#   [3] = Priority     (P1/P2/P3/P4)
#   [4] = Scope        (S/M/L)
#   [5] = Reported     (date)
#   [6] = Description
#   [7] = Related Feature
#   [8] = Notes

# Priority emoji mapping
$PriorityEmojis = @{
    "Critical" = "🔴"
    "High"     = "🟠"
    "Medium"   = "🟡"
    "Low"      = "🟢"
}

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

    if (-not (Test-Path $BugTrackingFile)) {
        Write-Log "Bug tracking file not found: $BugTrackingFile" -Level "ERROR"
        return $false
    }

    Write-Log "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

function Get-StatusEmoji {
    param([string]$Status)
    return $StatusEmojis[$Status]
}

function Get-PriorityEmoji {
    param([string]$Priority)
    if ($Priority) {
        return $PriorityEmojis[$Priority]
    }
    return ""
}

# All content-transformation functions take a content string and return modified content.
# This enables a single read-modify-write cycle in Main, avoiding file locking issues.

function Update-BugEntryContent {
    param(
        [string]$Content,
        [string]$BugId,
        [string]$NewStatus,
        [hashtable]$UpdateData
    )

    # Find bug entry in content
    $bugPattern = "\|\s*$BugId\s*\|[^\r\n]*"
    $match = [regex]::Match($Content, $bugPattern)

    if (-not $match.Success) {
        Write-Log "Bug entry not found: $BugId" -Level "ERROR"
        return $null
    }

    Write-Log "Found bug entry for $BugId"
    $currentEntry = $match.Value

    # Parse the table row (see column index mapping at top of script)
    $columns = $currentEntry -split '\|' | ForEach-Object { $_.Trim() }

    # Skip empty first element (before first |)
    if ($columns[0] -eq '') {
        $columns = $columns[1..($columns.Length - 1)]
    }

    # Update status
    $statusEmoji = Get-StatusEmoji -Status $NewStatus
    $columns[2] = "$statusEmoji $NewStatus"

    # Update priority if provided
    if ($UpdateData.Priority) {
        $priorityMap = @{ "Critical" = "P1"; "High" = "P2"; "Medium" = "P3"; "Low" = "P4" }
        $columns[3] = $priorityMap[$UpdateData.Priority]
    }

    # Update scope if provided
    if ($UpdateData.Scope) {
        $columns[4] = $UpdateData.Scope
    }

    # Update notes with status-specific information
    $notes = $columns[8]
    $currentDate = Get-Date -Format "yyyy-MM-dd"

    switch ($NewStatus) {
        "Fixed" {
            if ($UpdateData.FixDetails) { $notes += "; Fix: $($UpdateData.FixDetails)" }
            if ($UpdateData.RootCause) { $notes += "; Root Cause: $($UpdateData.RootCause)" }
            if ($UpdateData.TestsAdded) { $notes += "; Tests Added: $($UpdateData.TestsAdded)" }
            if ($UpdateData.PullRequestUrl) { $notes += "; PR: $($UpdateData.PullRequestUrl)" }
        }
        "Closed" {
            if ($UpdateData.VerificationNotes) { $notes += "; Verification: $($UpdateData.VerificationNotes)" }
        }
        "Reopened" {
            if ($UpdateData.ReopenReason) { $notes += "; Reopen Reason: $($UpdateData.ReopenReason)" }
        }
    }

    if ($notes -notmatch "Updated: $currentDate") {
        $notes += "; Updated: $currentDate"
    }
    $columns[8] = $notes

    # Reconstruct the table row and replace
    $updatedEntry = "| " + ($columns -join " | ") + " |"
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-Log "Successfully updated bug $BugId to status: $statusEmoji $NewStatus" -Level "SUCCESS"
    return $result
}

function Move-BugFromClosedToActiveSectionContent {
    param(
        [string]$Content,
        [string]$BugId
    )

    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # Find the bug entry line within the Closed Bugs section
    $bugLineIndex = -1
    $inClosedSection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Closed Bugs") { $inClosedSection = $true }
        if ($lines[$i] -match "^## Bug Statistics") { break }
        if ($inClosedSection -and $lines[$i] -match "^\|\s*$BugId\s*\|") {
            $bugLineIndex = $i
            break
        }
    }

    if ($bugLineIndex -eq -1) {
        Write-Log "Could not find bug $BugId in Closed Bugs section" -Level "ERROR"
        return $null
    }

    $bugLine = $lines[$bugLineIndex]
    $lines.RemoveAt($bugLineIndex)

    # Determine target priority section from the bug's Priority column (column index 3)
    $columns = $bugLine -split '\|' | ForEach-Object { $_.Trim() }
    if ($columns[0] -eq '') { $columns = $columns[1..($columns.Length - 1)] }
    $priorityValue = $columns[3].Trim()

    $sectionHeader = switch ($priorityValue) {
        "P1" { "### Critical Bugs" }
        "P2" { "### High Priority Bugs" }
        "P3" { "### Medium Priority Bugs" }
        "P4" { "### Low Priority Bugs" }
        default {
            Write-Log "Unknown priority '$priorityValue' for bug $BugId, defaulting to Medium" -Level "WARN"
            "### Medium Priority Bugs"
        }
    }

    # Find insertion point: after the last PD-BUG row (or table separator) in the target section
    $insertAfterIndex = -1
    $targetSectionFound = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "../^/Q$sectionHeader/E" -or $lines[$i] -eq $sectionHeader) {
            $targetSectionFound = $true
        }
        if ($targetSectionFound) {
            # Stop at the next section header
            if ($i -gt 0 -and $lines[$i] -match "^(###|##) " -and $lines[$i] -ne $sectionHeader) { break }
            if ($lines[$i] -match "^\|\s*PD-BUG-") { $insertAfterIndex = $i }
            if ($lines[$i] -match "^\| -") { if ($insertAfterIndex -eq -1) { $insertAfterIndex = $i } }
        }
    }

    if ($insertAfterIndex -eq -1) {
        Write-Log "Could not find target section '$sectionHeader' for reinsertion" -Level "ERROR"
        return $null
    }

    # Remove "No X bugs currently active" placeholder if present
    if ($insertAfterIndex + 1 -lt $lines.Count -and $lines[$insertAfterIndex + 1] -match "^\|\s*_No .+ bugs currently") {
        $lines.RemoveAt($insertAfterIndex + 1)
    }

    $lines.Insert($insertAfterIndex + 1, $bugLine)

    Write-Log "Moved bug $BugId from Closed section to $sectionHeader" -Level "SUCCESS"
    return ($lines -join "`r`n")
}

function Move-BugToClosedSectionContent {
    param(
        [string]$Content,
        [string]$BugId
    )

    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # Find the bug entry line
    $bugLineIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^\|\s*$BugId\s*\|") {
            $bugLineIndex = $i
            break
        }
    }

    if ($bugLineIndex -eq -1) {
        Write-Log "Could not find bug entry line for $BugId to move" -Level "ERROR"
        return $null
    }

    $bugLine = $lines[$bugLineIndex]
    $lines.RemoveAt($bugLineIndex)

    # Check if the priority section is now empty (no remaining PD-BUG rows)
    $sectionHeaderIndex = -1
    for ($i = [Math]::Min($bugLineIndex - 1, $lines.Count - 1); $i -ge 0; $i--) {
        if ($lines[$i] -match "^### (Critical|High Priority|Medium Priority|Low Priority) Bugs") {
            $sectionHeaderIndex = $i
            break
        }
    }

    if ($sectionHeaderIndex -ge 0) {
        $hasDataRows = $false
        for ($i = $sectionHeaderIndex + 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^(###|##) " -and $i -gt $sectionHeaderIndex + 2) { break }
            if ($lines[$i] -match "^\|\s*PD-BUG-") {
                $hasDataRows = $true
                break
            }
        }

        if (-not $hasDataRows) {
            # Add placeholder after the table separator line
            for ($i = $sectionHeaderIndex + 1; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "^\| -") {
                    $sectionName = $lines[$sectionHeaderIndex]
                    $priorityLabel = if ($sectionName -match "Critical") { "critical" }
                                     elseif ($sectionName -match "High") { "high priority" }
                                     elseif ($sectionName -match "Medium") { "medium priority" }
                                     else { "low priority" }
                    $lines.Insert($i + 1, "| _No $priorityLabel bugs currently active_ |")
                    break
                }
            }
        }
    }

    # Find insertion point: after the last PD-BUG row in the Closed Bugs section
    $insertAfterIndex = -1
    $inClosedSection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Closed Bugs") { $inClosedSection = $true }
        if ($inClosedSection) {
            if ($lines[$i] -match "^\|\s*PD-BUG-") { $insertAfterIndex = $i }
            if ($lines[$i] -match "^\s*</details>") { break }
        }
    }

    # If no PD-BUG rows in Closed section, insert after the table separator line
    if ($insertAfterIndex -eq -1) {
        $inClosedSection = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^## Closed Bugs") { $inClosedSection = $true }
            if ($inClosedSection -and $lines[$i] -match "^\| -") {
                $insertAfterIndex = $i
                break
            }
        }
    }

    if ($insertAfterIndex -eq -1) {
        Write-Log "Could not find insertion point in Closed Bugs section" -Level "ERROR"
        return $null
    }

    $lines.Insert($insertAfterIndex + 1, $bugLine)

    Write-Log "Moved bug $BugId to Closed Bugs section" -Level "SUCCESS"
    return ($lines -join "`r`n")
}

function Update-BugStatisticsContent {
    param([string]$Content)

    # Count active bugs by priority section
    $counts = @{ Critical = 0; High = 0; Medium = 0; Low = 0 }
    $currentPriority = ""

    foreach ($line in ($Content -split "\r?\n")) {
        if ($line -match "^## Closed Bugs") { break }
        if ($line -match "^## Bug Statistics") { break }

        if ($line -match "^### Critical Bugs") { $currentPriority = "Critical" }
        elseif ($line -match "^### High Priority Bugs") { $currentPriority = "High" }
        elseif ($line -match "^### Medium Priority Bugs") { $currentPriority = "Medium" }
        elseif ($line -match "^### Low Priority Bugs") { $currentPriority = "Low" }

        if ($currentPriority -and $line -match "^\|\s*PD-BUG-") {
            $counts[$currentPriority]++
        }
    }

    $totalActive = $counts.Critical + $counts.High + $counts.Medium + $counts.Low

    # Update statistics using regex replacement
    $result = $Content
    $result = $result -replace '(?<=\*\*Total Active Bugs\*\*:\s*)\d+', $totalActive.ToString()
    $result = $result -replace '(?<=\*\*Critical \(P1\)\*\*:\s*)\d+', $counts.Critical.ToString()
    $result = $result -replace '(?<=\*\*High \(P2\)\*\*:\s*)\d+', $counts.High.ToString()
    $result = $result -replace '(?<=\*\*Medium \(P3\)\*\*:\s*)\d+', $counts.Medium.ToString()
    $result = $result -replace '(?<=\*\*Low \(P4\)\*\*:\s*)\d+', $counts.Low.ToString()

    Write-Log "Updated bug statistics: $totalActive active ($($counts.Critical) P1, $($counts.High) P2, $($counts.Medium) P3, $($counts.Low) P4)" -Level "SUCCESS"
    return $result
}

function Main {
    Write-Log "Starting Bug Status Update - $ScriptName"
    Write-Log "Bug ID: $BugId"
    Write-Log "New Status: $NewStatus"

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    # Prepare update data
    $updateData = @{}
    if ($Priority) { $updateData.Priority = $Priority }
    if ($Scope) { $updateData.Scope = $Scope }
    if ($FixDetails) { $updateData.FixDetails = $FixDetails }
    if ($RootCause) { $updateData.RootCause = $RootCause }
    if ($TestsAdded) { $updateData.TestsAdded = $TestsAdded }
    if ($PullRequestUrl) { $updateData.PullRequestUrl = $PullRequestUrl }
    if ($VerificationNotes) { $updateData.VerificationNotes = $VerificationNotes }
    if ($ReopenReason) { $updateData.ReopenReason = $ReopenReason }

    # Validate required parameters for specific status transitions
    switch ($NewStatus) {
        "Triaged" {
            if (-not $Priority) {
                Write-Log "Priority is required when transitioning to Triaged status" -Level "ERROR"
                exit 1
            }
        }
        "InProgress" {
            # No additional validation needed
        }
        "Fixed" {
            if (-not $FixDetails) {
                Write-Log "FixDetails is required when transitioning to Fixed status" -Level "ERROR"
                exit 1
            }
        }
        "Closed" {
            if (-not $VerificationNotes) {
                Write-Log "VerificationNotes is required when transitioning to Closed status" -Level "ERROR"
                exit 1
            }
        }
        "Reopened" {
            if (-not $ReopenReason) {
                Write-Log "ReopenReason is required when transitioning to Reopened status" -Level "ERROR"
                exit 1
            }
        }
    }

    if (-not $PSCmdlet.ShouldProcess($BugTrackingFile, "Update $BugId to $NewStatus")) {
        return
    }

    # Single read-modify-write cycle to avoid file locking issues
    $content = Get-Content $BugTrackingFile -Raw

    # Step 1: Update the bug entry (status, notes)
    $content = Update-BugEntryContent -Content $content -BugId $BugId -NewStatus $NewStatus -UpdateData $updateData
    if ($null -eq $content) {
        Write-Log "Bug status update failed" -Level "ERROR"
        exit 1
    }

    # Step 2: When closing, move the row to the Closed Bugs section
    if ($NewStatus -eq "Closed") {
        $content = Move-BugToClosedSectionContent -Content $content -BugId $BugId
        if ($null -eq $content) {
            Write-Log "Failed to move bug $BugId to Closed section" -Level "ERROR"
            exit 1
        }
    }

    # Step 2b: When reopening, move the row from Closed section back to active priority table
    if ($NewStatus -eq "Reopened") {
        $content = Move-BugFromClosedToActiveSectionContent -Content $content -BugId $BugId
        if ($null -eq $content) {
            Write-Log "Failed to move bug $BugId from Closed to active section" -Level "ERROR"
            exit 1
        }
    }

    # Step 3: Recalculate statistics
    $content = Update-BugStatisticsContent -Content $content

    # Single write
    Set-Content -Path $BugTrackingFile -Value $content -NoNewline

    Write-Log "Bug status update completed successfully" -Level "SUCCESS"
    Write-Log "Updated file: $BugTrackingFile"
    exit 0
}

# Execute main function
Main
