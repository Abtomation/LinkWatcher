#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates bug status updates in the Bug Tracking state file

.DESCRIPTION
This script automates bug status transitions in the bug-tracking.md state file,
supporting the complete bug lifecycle from Reported to Closed.

Updates the following file:
- doc/process-framework/state-tracking/permanent/bug-tracking.md

Supports all bug status transitions:
- 🆕 Reported → 🔍 Triaged (Bug Triage Task)
- 🔍 Triaged → 🔧 In Progress (Bug Fixing Task)
- 🔧 In Progress → 🧪 Testing (Bug Fixing Task)
- 🧪 Testing → ✅ Fixed (Bug Fixing Task)
- ✅ Fixed → 🟢 Closed (Bug Verification)
- Any Status → 🔄 Reopened (Bug Verification)

.PARAMETER BugId
The bug ID to update (e.g., "BUG-001")

.PARAMETER NewStatus
The new status for the bug. Valid values:
- "Triaged" (🔍)
- "InProgress" (🔧)
- "Testing" (🧪)
- "Fixed" (✅)
- "Closed" (🟢)
- "Reopened" (🔄)

.PARAMETER Priority
Bug priority (Critical, High, Medium, Low) - used when transitioning to Triaged

.PARAMETER Severity
Bug severity (Critical, High, Medium, Low) - used when transitioning to Triaged



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
.\Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Triaged" -Priority "High" -Severity "Medium"

.EXAMPLE
# Start working on a bug
.\Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "InProgress"

.EXAMPLE
# Mark bug as fixed
.\Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Fixed" -FixDetails "Fixed null pointer exception in user validation" -RootCause "Missing null check" -TestsAdded "Yes" -PullRequestUrl "https://github.com/repo/pull/123"

.EXAMPLE
# Close a verified bug
.\Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Closed" -VerificationNotes "Fix verified in production, no regressions detected"

.EXAMPLE
# Reopen a bug
.\Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Reopened" -ReopenReason "Issue still occurs in edge case scenario"

.NOTES
This script is part of the Bug Management automation system and integrates with:
- Bug Triage Task (PF-TSK-041)
- Bug Fixing Task (PF-TSK-007)
- Bug Verification processes
#>

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
    [ValidateSet("Critical", "High", "Medium", "Low")]
    [string]$Severity,



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

# Configuration
$BugTrackingFile = "doc/process-framework/state-tracking/permanent/bug-tracking.md"
$ScriptName = "Update-BugStatus.ps1"

# Status emoji mapping
$StatusEmojis = @{
    "Reported"   = "🆕"
    "Triaged"    = "🔍"
    "InProgress" = "🔧"
    "Testing"    = "🧪"
    "Fixed"      = "✅"
    "Closed"     = "🟢"
    "Reopened"   = "🔄"
}

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

function Find-BugEntry {
    param([string]$BugId)

    $content = Get-Content $BugTrackingFile -Raw

    # Look for bug entry in table format: | BugId | Title | Status | ...
    $bugPattern = "\|\s*$BugId\s*\|[^\r\n]*"
    $match = [regex]::Match($content, $bugPattern)

    if ($match.Success) {
        return @{
            Found      = $true
            StartIndex = $match.Index
            Length     = $match.Length
            Content    = $match.Value
        }
    }

    return @{ Found = $false }
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

function Update-BugEntry {
    param(
        [string]$BugId,
        [string]$NewStatus,
        [hashtable]$UpdateData
    )

    $bugEntry = Find-BugEntry -BugId $BugId
    if (-not $bugEntry.Found) {
        Write-Log "Bug entry not found: $BugId" -Level "ERROR"
        return $false
    }

    Write-Log "Found bug entry for $BugId"

    # Read current content
    $content = Get-Content $BugTrackingFile -Raw

    # Extract current bug entry (table row)
    $currentEntry = $bugEntry.Content

    # Parse the table row - format: | ID | Title | Status | Priority | Severity | Source | Reported Date | Target Fix Date | Description | Related Feature | Notes |
    $columns = $currentEntry -split '\|' | ForEach-Object { $_.Trim() }

    # Skip empty first element (before first |)
    if ($columns[0] -eq '') {
        $columns = $columns[1..($columns.Length - 1)]
    }

    # Update the columns based on provided data
    $statusEmoji = Get-StatusEmoji -Status $NewStatus

    # Column indices: 0=ID, 1=Title, 2=Status, 3=Priority, 4=Severity, 5=Source, 6=Reported Date, 7=Target Fix Date, 8=Description, 9=Related Feature, 10=Notes
    $columns[2] = "$statusEmoji $NewStatus"  # Status

    if ($UpdateData.Priority) {
        $priorityMap = @{
            "Critical" = "P1"
            "High"     = "P2"
            "Medium"   = "P3"
            "Low"      = "P4"
        }
        $columns[3] = $priorityMap[$UpdateData.Priority]  # Priority
    }

    if ($UpdateData.Severity) {
        $columns[4] = $UpdateData.Severity  # Severity
    }
    # Update notes with additional information
    $notes = $columns[10]  # Notes column is now at index 10
    $currentDate = Get-Date -Format "yyyy-MM-dd"


    # Add status-specific information to notes
    switch ($NewStatus) {
        "Fixed" {
            if ($UpdateData.FixDetails) {
                $notes += "; Fix: $($UpdateData.FixDetails)"
            }
            if ($UpdateData.RootCause) {
                $notes += "; Root Cause: $($UpdateData.RootCause)"
            }
            if ($UpdateData.TestsAdded) {
                $notes += "; Tests Added: $($UpdateData.TestsAdded)"
            }
            if ($UpdateData.PullRequestUrl) {
                $notes += "; PR: $($UpdateData.PullRequestUrl)"
            }
        }
        "Closed" {
            if ($UpdateData.VerificationNotes) {
                $notes += "; Verification: $($UpdateData.VerificationNotes)"
            }
        }
        "Reopened" {
            if ($UpdateData.ReopenReason) {
                $notes += "; Reopen Reason: $($UpdateData.ReopenReason)"
            }
        }
    }

    # Only add update timestamp if it's not already there for today
    if ($notes -notmatch "Updated: $currentDate") {
        $notes += "; Updated: $currentDate"
    }
    $columns[10] = $notes  # Notes column is now at index 10

    # Reconstruct the table row
    $updatedEntry = "| " + ($columns -join " | ") + " |"

    # Replace the old entry with the updated one
    $newContent = $content.Replace($currentEntry, $updatedEntry)

    # Write back to file
    Set-Content -Path $BugTrackingFile -Value $newContent -NoNewline

    Write-Log "Successfully updated bug $BugId to status: $statusEmoji $NewStatus" -Level "SUCCESS"
    return $true
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
    if ($Severity) { $updateData.Severity = $Severity }
    if ($FixDetails) { $updateData.FixDetails = $FixDetails }
    if ($RootCause) { $updateData.RootCause = $RootCause }
    if ($TestsAdded) { $updateData.TestsAdded = $TestsAdded }
    if ($PullRequestUrl) { $updateData.PullRequestUrl = $PullRequestUrl }
    if ($VerificationNotes) { $updateData.VerificationNotes = $VerificationNotes }
    if ($ReopenReason) { $updateData.ReopenReason = $ReopenReason }

    # Validate required parameters for specific status transitions
    switch ($NewStatus) {
        "Triaged" {
            if (-not $Priority -or -not $Severity) {
                Write-Log "Priority and Severity are required when transitioning to Triaged status" -Level "ERROR"
                exit 1
            }
        }
        "InProgress" {
            # No additional validation needed for InProgress status
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

    # Update the bug entry
    if (Update-BugEntry -BugId $BugId -NewStatus $NewStatus -UpdateData $updateData) {
        Write-Log "Bug status update completed successfully" -Level "SUCCESS"
        Write-Log "Updated file: $BugTrackingFile"
        exit 0
    }
    else {
        Write-Log "Bug status update failed" -Level "ERROR"
        exit 1
    }
}

# Execute main function
Main
