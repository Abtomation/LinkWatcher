#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates bug status updates in the Bug Tracking state file

.DESCRIPTION
This script automates bug status transitions in the ../bug-tracking.md state file,
supporting the complete bug lifecycle from Needs Triage to Closed.

Updates the following file:
- doc/state-tracking/permanent/bug-tracking.md

Supports all bug status transitions:
- 🆕 Needs Triage → 🔍 Needs Fix (Bug Triage Task)
- 🔍 Needs Fix → 🟡 In Progress (Bug Fixing Task)
- 🟡 In Progress → 👀 Needs Review (Bug Fixing Task)
- 👀 Needs Review → 🔒 Closed (Code Review Task)
- Any Active Status → ❌ Rejected (Bug Fixing Task — not-a-bug / won't-fix)
- Any Status → 🔄 Reopened (Bug Triage Task)

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
- "NeedsFix" (🔍 Needs Fix)
- "InProgress" (🟡 In Progress)
- "NeedsReview" (👀 Needs Review)
- "Closed" (🔒 Closed) — auto-moves to Closed section, recalculates stats
- "Reopened" (🔄 Reopened)
- "Rejected" (❌ Rejected) — not-a-bug, auto-moves to Closed section, recalculates stats

.PARAMETER FastClose
S-scope quick path: chains NeedsFix → InProgress → Closed in one call.
Requires: Priority, FixDetails, VerificationNotes. Scope defaults to "S" if not specified.
Use this for small bugs that are triaged, fixed, and closed in a single session.

.PARAMETER Priority
Bug priority (Critical, High, Medium, Low) - used when transitioning to NeedsFix or with -FastClose

.PARAMETER Scope
Bug fix scope (S, M, L) - used to indicate fix complexity and whether a state file is needed



.PARAMETER FixDetails
Details about the fix implementation - used when transitioning to NeedsReview

.PARAMETER RootCause
Root cause analysis - used when transitioning to NeedsReview

.PARAMETER TestsAdded
Whether regression tests were added (Yes/No) - used when transitioning to NeedsReview

.PARAMETER PullRequestUrl
URL to the pull request containing the fix - used when transitioning to NeedsReview

.PARAMETER VerificationNotes
Notes from verification process - used when transitioning to Closed

.PARAMETER ReopenReason
Reason for reopening the bug - used when transitioning to Reopened

.PARAMETER Dims
Development dimension abbreviations (e.g., "SE DI") - used when transitioning to NeedsFix

.PARAMETER Workflows
Affected user workflows (e.g., "WF-001, WF-003") - used when transitioning to NeedsFix

.PARAMETER TriageNotes
Triage rationale to append to the Notes field - used when transitioning to NeedsFix

.PARAMETER UpdateDate
Date of the status update (optional - uses current date if not specified)

.EXAMPLE
# Triage a bug (set to Needs Fix)
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "NeedsFix" -Priority "High" -Scope "S" -Dims "SE DI" -Workflows "WF-001, WF-003" -TriageNotes "Impacts all users on startup; root cause likely in config loader"

.EXAMPLE
# Start working on a bug
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "InProgress"

.EXAMPLE
# Mark bug as ready for code review
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "NeedsReview" -FixDetails "Fixed null pointer exception in user validation" -RootCause "Missing null check" -TestsAdded "Yes" -PullRequestUrl "https:/github.com/repo/pull/123"

.EXAMPLE
# Close a bug after code review verification
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Closed" -VerificationNotes "Code review approved, fix verified, no regressions detected"

.EXAMPLE
# Reopen a bug
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Reopened" -ReopenReason "Issue still occurs in edge case scenario"

.EXAMPLE
# Reject a bug (not-a-bug)
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Rejected" -RejectionReason "Expected behavior per design spec"

.EXAMPLE
# S-scope quick path: triage + fix + close in one call
../Update-BugStatus.ps1 -BugId "BUG-001" -FastClose -Priority "Medium" -Scope "S" -Dims "CQ" -FixDetails "Fixed off-by-one in loop boundary" -RootCause "Loop used < instead of <=" -TestsAdded "Yes" -VerificationNotes "S-scope quick path: human-approved at checkpoint"

.EXAMPLE
# Dry-run to preview changes without modifying the file
# Runs full transformation logic and logs all actions (moves, stats recalc) but skips file write
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "InProgress" -WhatIf

.NOTES
This script is part of the Bug Management automation system and integrates with:
- Bug Triage Task (PF-TSK-041)
- Bug Fixing Task (PF-TSK-007)
- Code Review Task (PF-TSK-005) — verifies bug fixes
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'SingleStatus')]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(BUG|PD-BUG)-\d+$')]
    [string]$BugId,

    [Parameter(Mandatory = $true, ParameterSetName = 'SingleStatus')]
    [ValidateSet("NeedsFix", "InProgress", "NeedsReview", "Closed", "Reopened", "Rejected")]
    [string]$NewStatus,

    [Parameter(Mandatory = $true, ParameterSetName = 'FastClose')]
    [switch]$FastClose,

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
    [string]$RejectionReason,

    [Parameter(Mandatory = $false)]
    [string]$Dims,

    [Parameter(Mandatory = $false)]
    [string]$Workflows,

    [Parameter(Mandatory = $false)]
    [string]$TriageNotes,

    [Parameter(Mandatory = $false)]
    [datetime]$UpdateDate = (Get-Date)
)

# Import the common helpers for Get-ProjectRoot
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

# Configuration - use project-root-relative path for reliability
$ProjectRoot = Get-ProjectRoot
$BugTrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/bug-tracking.md"
$ScriptName = "../Update-BugStatus.ps1"

# Status emoji mapping
$StatusEmojis = @{
    "NeedsTriage"  = "🆕"
    "NeedsFix"     = "🔍"
    "InProgress"   = "🟡"
    "NeedsReview"  = "👀"
    "Closed"       = "🔒"
    "Reopened"     = "🔄"
    "Rejected"     = "❌"
}

# Display name mapping (ValidateSet value → human-readable status text)
$StatusDisplayNames = @{
    "NeedsTriage"  = "Needs Triage"
    "NeedsFix"     = "Needs Fix"
    "InProgress"   = "In Progress"
    "NeedsReview"  = "Needs Review"
    "Closed"       = "Closed"
    "Reopened"     = "Reopened"
    "Rejected"     = "Rejected"
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
#   [8] = Workflows    (affected user workflows, e.g., "WF-001, WF-003")
#   [9] = Dims         (dimension abbreviations, e.g., "SE DI")
#   [10] = Notes

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
    $displayName = $StatusDisplayNames[$NewStatus]
    $columns[2] = "$statusEmoji $displayName"

    # Update priority if provided
    if ($UpdateData.Priority) {
        $priorityMap = @{ "Critical" = "P1"; "High" = "P2"; "Medium" = "P3"; "Low" = "P4" }
        $columns[3] = $priorityMap[$UpdateData.Priority]
    }

    # Update scope if provided
    if ($UpdateData.Scope) {
        $columns[4] = $UpdateData.Scope
    }

    # Update Workflows if provided (column [8])
    if ($UpdateData.Workflows) {
        $columns[8] = $UpdateData.Workflows
    }

    # Update Dims if provided (column [9])
    if ($UpdateData.Dims) {
        $columns[9] = $UpdateData.Dims
    }

    # Update notes with status-specific information (column [10])
    $notes = $columns[10]
    $currentDate = Get-Date -Format "yyyy-MM-dd"

    switch ($NewStatus) {
        "NeedsFix" {
            if ($UpdateData.TriageNotes) { $notes += "; Triage: $($UpdateData.TriageNotes)" }
        }
        "NeedsReview" {
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
        "Rejected" {
            if ($UpdateData.RejectionReason) { $notes += "; Rejected: $($UpdateData.RejectionReason)" }
        }
    }

    if ($notes -notmatch "Updated: $currentDate") {
        $notes += "; Updated: $currentDate"
    }
    $columns[10] = $notes

    # Reconstruct the table row and replace
    $updatedEntry = "| " + ($columns -join " | ") + " |"
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-Log "Successfully updated bug $BugId to status: $statusEmoji $displayName" -Level "SUCCESS"
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
        if ($lines[$i].Trim() -eq $sectionHeader) {
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

function Move-BugBetweenActiveSectionsContent {
    param(
        [string]$Content,
        [string]$BugId,
        [string]$TargetPriority  # "Critical", "High", "Medium", or "Low"
    )

    $priorityToSection = @{
        "Critical" = "### Critical Bugs"
        "High"     = "### High Priority Bugs"
        "Medium"   = "### Medium Priority Bugs"
        "Low"      = "### Low Priority Bugs"
    }

    $targetSectionHeader = $priorityToSection[$TargetPriority]
    if (-not $targetSectionHeader) {
        Write-Log "Unknown target priority '$TargetPriority'" -Level "ERROR"
        return $null
    }

    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    # Find the bug entry line (only in active sections, stop before Closed Bugs)
    $bugLineIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Closed Bugs") { break }
        if ($lines[$i] -match "^\|\s*$BugId\s*\|") {
            $bugLineIndex = $i
            break
        }
    }

    if ($bugLineIndex -eq -1) {
        Write-Log "Bug $BugId not found in active sections for inter-section move" -Level "ERROR"
        return $null
    }

    # Determine current section by scanning backward
    $currentSectionHeader = ""
    for ($i = $bugLineIndex - 1; $i -ge 0; $i--) {
        if ($lines[$i] -match "^### (Critical|High Priority|Medium Priority|Low Priority) Bugs") {
            $currentSectionHeader = $lines[$i]
            break
        }
    }

    # If already in the correct section, no move needed
    if ($currentSectionHeader -eq $targetSectionHeader) {
        Write-Log "Bug $BugId already in correct section ($targetSectionHeader), no move needed"
        return $Content
    }

    Write-Log "Moving bug $BugId from '$currentSectionHeader' to '$targetSectionHeader'"

    $bugLine = $lines[$bugLineIndex]
    $lines.RemoveAt($bugLineIndex)

    # Check if the source section is now empty → add placeholder
    $sourceSectionIndex = -1
    for ($i = [Math]::Min($bugLineIndex - 1, $lines.Count - 1); $i -ge 0; $i--) {
        if ($lines[$i] -match "^### (Critical|High Priority|Medium Priority|Low Priority) Bugs") {
            $sourceSectionIndex = $i
            break
        }
    }

    if ($sourceSectionIndex -ge 0) {
        $hasDataRows = $false
        for ($i = $sourceSectionIndex + 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^(###|##) " -and $i -gt $sourceSectionIndex + 2) { break }
            if ($lines[$i] -match "^\|\s*PD-BUG-") {
                $hasDataRows = $true
                break
            }
        }

        if (-not $hasDataRows) {
            for ($i = $sourceSectionIndex + 1; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "^\| -") {
                    $sectionName = $lines[$sourceSectionIndex]
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

    # Find insertion point in target section: after last PD-BUG row, or after table separator
    $insertAfterIndex = -1
    $targetSectionFound = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq $targetSectionHeader) {
            $targetSectionFound = $true
        }
        if ($targetSectionFound) {
            if ($i -gt 0 -and $lines[$i] -match "^(###|##) " -and $lines[$i] -ne $targetSectionHeader) { break }
            if ($lines[$i] -match "^\|\s*PD-BUG-") { $insertAfterIndex = $i }
            if ($lines[$i] -match "^\| -") { if ($insertAfterIndex -eq -1) { $insertAfterIndex = $i } }
        }
    }

    if ($insertAfterIndex -eq -1) {
        Write-Log "Could not find target section '$targetSectionHeader' for insertion" -Level "ERROR"
        return $null
    }

    # Remove "No X bugs currently active" placeholder if present in target section
    if ($insertAfterIndex + 1 -lt $lines.Count -and $lines[$insertAfterIndex + 1] -match "^\|\s*_No .+ bugs currently") {
        $lines.RemoveAt($insertAfterIndex + 1)
    }

    $lines.Insert($insertAfterIndex + 1, $bugLine)

    Write-Log "Moved bug $BugId to $targetSectionHeader" -Level "SUCCESS"
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

    # Collect active bug IDs by priority section
    $bugIds = @{ Critical = [System.Collections.ArrayList]@(); High = [System.Collections.ArrayList]@(); Medium = [System.Collections.ArrayList]@(); Low = [System.Collections.ArrayList]@() }
    $currentPriority = ""

    foreach ($line in ($Content -split "\r?\n")) {
        if ($line -match "^## Closed Bugs") { break }
        if ($line -match "^## Bug Statistics") { break }

        if ($line -match "^### Critical Bugs") { $currentPriority = "Critical" }
        elseif ($line -match "^### High Priority Bugs") { $currentPriority = "High" }
        elseif ($line -match "^### Medium Priority Bugs") { $currentPriority = "Medium" }
        elseif ($line -match "^### Low Priority Bugs") { $currentPriority = "Low" }

        if ($currentPriority -and $line -match "^\|\s*(PD-BUG-\d+)\s*\|") {
            $bugIds[$currentPriority].Add($Matches[1]) | Out-Null
        }
    }

    $totalActive = $bugIds.Critical.Count + $bugIds.High.Count + $bugIds.Medium.Count + $bugIds.Low.Count

    # Build statistics lines with counts and ID lists
    function Format-StatLine {
        param([string]$Label, [System.Collections.ArrayList]$Ids)
        $count = $Ids.Count
        if ($count -eq 0) { return "- **${Label}**: 0" }
        return "- **${Label}**: $count ($($Ids -join ', '))"
    }

    $result = $Content
    $result = $result -replace '- \*\*Total Active Bugs\*\*:.*', "- **Total Active Bugs**: $totalActive"
    $result = $result -replace '- \*\*Critical \(P1\)\*\*:.*', (Format-StatLine "Critical (P1)" $bugIds.Critical)
    $result = $result -replace '- \*\*High \(P2\)\*\*:.*', (Format-StatLine "High (P2)" $bugIds.High)
    $result = $result -replace '- \*\*Medium \(P3\)\*\*:.*', (Format-StatLine "Medium (P3)" $bugIds.Medium)
    $result = $result -replace '- \*\*Low \(P4\)\*\*:.*', (Format-StatLine "Low (P4)" $bugIds.Low)

    Write-Log "Updated bug statistics: $totalActive active ($($bugIds.Critical.Count) P1, $($bugIds.High.Count) P2, $($bugIds.Medium.Count) P3, $($bugIds.Low.Count) P4)" -Level "SUCCESS"
    return $result
}

function Main {
    # Normalize short-form IDs: BUG-001 → PD-BUG-001
    if ($BugId -match '^BUG-\d+$') {
        $script:BugId = "PD-$BugId"
    }

    Write-Log "Starting Bug Status Update - $ScriptName"
    Write-Log "Bug ID: $BugId"

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    # --- FastClose: chain NeedsFix → InProgress → Closed in one call ---
    if ($FastClose) {
        Write-Log "Mode: FastClose (S-scope quick path)" -Level "INFO"

        # Validate required parameters for FastClose
        if (-not $Priority) {
            Write-Log "Priority is required for -FastClose" -Level "ERROR"; exit 1
        }
        if (-not $FixDetails) {
            Write-Log "FixDetails is required for -FastClose" -Level "ERROR"; exit 1
        }
        if (-not $VerificationNotes) {
            Write-Log "VerificationNotes is required for -FastClose" -Level "ERROR"; exit 1
        }

        $content = Get-Content $BugTrackingFile -Raw

        # Phase 1: NeedsFix (triage)
        $triageData = @{ Priority = $Priority }
        if ($Scope) { $triageData.Scope = $Scope } else { $triageData.Scope = "S" }
        if ($Dims) { $triageData.Dims = $Dims }
        if ($Workflows) { $triageData.Workflows = $Workflows }
        if ($TriageNotes) { $triageData.TriageNotes = $TriageNotes }
        $content = Update-BugEntryContent -Content $content -BugId $BugId -NewStatus "NeedsFix" -UpdateData $triageData
        if ($null -eq $content) { Write-Log "FastClose failed at NeedsFix" -Level "ERROR"; exit 1 }
        Write-Log "FastClose phase 1/3: 🔍 Needs Fix" -Level "SUCCESS"

        # Move to correct priority section (non-fatal if already in correct section)
        $movedContent = Move-BugBetweenActiveSectionsContent -Content $content -BugId $BugId -TargetPriority $Priority
        if ($null -ne $movedContent) { $content = $movedContent }
        else { Write-Log "Bug already in correct priority section or move skipped" -Level "INFO" }

        # Phase 2: InProgress
        $content = Update-BugEntryContent -Content $content -BugId $BugId -NewStatus "InProgress" -UpdateData @{}
        if ($null -eq $content) { Write-Log "FastClose failed at InProgress" -Level "ERROR"; exit 1 }
        Write-Log "FastClose phase 2/3: 🟡 In Progress" -Level "SUCCESS"

        # Phase 3: Closed (with fix details and verification)
        $closeData = @{}
        if ($FixDetails) { $closeData.FixDetails = $FixDetails }
        if ($RootCause) { $closeData.RootCause = $RootCause }
        if ($TestsAdded) { $closeData.TestsAdded = $TestsAdded }
        if ($PullRequestUrl) { $closeData.PullRequestUrl = $PullRequestUrl }
        if ($VerificationNotes) { $closeData.VerificationNotes = $VerificationNotes }
        $content = Update-BugEntryContent -Content $content -BugId $BugId -NewStatus "Closed" -UpdateData $closeData
        if ($null -eq $content) { Write-Log "FastClose failed at Closed" -Level "ERROR"; exit 1 }
        Write-Log "FastClose phase 3/3: 🔒 Closed" -Level "SUCCESS"

        # Move to Closed section and recalculate stats
        $content = Move-BugToClosedSectionContent -Content $content -BugId $BugId
        if ($null -eq $content) { Write-Log "Failed to move bug to Closed section" -Level "ERROR"; exit 1 }
        $content = Update-BugStatisticsContent -Content $content

        if ($PSCmdlet.ShouldProcess($BugTrackingFile, "FastClose $BugId (NeedsFix → InProgress → Closed)")) {
            Set-Content -Path $BugTrackingFile -Value $content -NoNewline
            Write-Log "FastClose completed successfully — bug $BugId closed" -Level "SUCCESS"
            Write-Log "Updated file: $BugTrackingFile"
        } else {
            Write-Log "Dry-run complete — no file changes written" -Level "INFO"
        }
        exit 0
    }

    # --- Standard single-status update ---
    Write-Log "New Status: $NewStatus"

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
    if ($RejectionReason) { $updateData.RejectionReason = $RejectionReason }
    if ($Dims) { $updateData.Dims = $Dims }
    if ($Workflows) { $updateData.Workflows = $Workflows }
    if ($TriageNotes) { $updateData.TriageNotes = $TriageNotes }

    # Validate required parameters for specific status transitions
    switch ($NewStatus) {
        "NeedsFix" {
            if (-not $Priority) {
                Write-Log "Priority is required when transitioning to NeedsFix status" -Level "ERROR"
                exit 1
            }
        }
        "InProgress" {
            # No additional validation needed
        }
        "NeedsReview" {
            if (-not $FixDetails) {
                Write-Log "FixDetails is required when transitioning to NeedsReview status" -Level "ERROR"
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
        "Rejected" {
            if (-not $RejectionReason) {
                Write-Log "RejectionReason is required when transitioning to Rejected status" -Level "ERROR"
                exit 1
            }
        }
    }

    # Single read-modify-write cycle to avoid file locking issues
    # IMP-443: ShouldProcess moved to guard only the file write (line below Set-Content),
    # so -WhatIf runs the full transformation logic and logs what would happen.
    $content = Get-Content $BugTrackingFile -Raw

    # Step 1: Update the bug entry (status, notes)
    $content = Update-BugEntryContent -Content $content -BugId $BugId -NewStatus $NewStatus -UpdateData $updateData
    if ($null -eq $content) {
        Write-Log "Bug status update failed" -Level "ERROR"
        exit 1
    }

    # Step 1b: When priority changes within active sections (e.g., triage), move to correct section
    if ($Priority -and $NewStatus -notin @("Closed", "Rejected", "Reopened")) {
        $content = Move-BugBetweenActiveSectionsContent -Content $content -BugId $BugId -TargetPriority $Priority
        if ($null -eq $content) {
            Write-Log "Failed to move bug $BugId to $Priority section" -Level "ERROR"
            exit 1
        }
    }

    # Step 2: When closing or rejecting, move the row to the Closed Bugs section
    if ($NewStatus -eq "Closed" -or $NewStatus -eq "Rejected") {
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

    # Single write — guarded by ShouldProcess so -WhatIf skips only the file write
    if ($PSCmdlet.ShouldProcess($BugTrackingFile, "Update $BugId to $NewStatus")) {
        Set-Content -Path $BugTrackingFile -Value $content -NoNewline
        Write-Log "Bug status update completed successfully" -Level "SUCCESS"
        Write-Log "Updated file: $BugTrackingFile"
    } else {
        Write-Log "Dry-run complete — no file changes written" -Level "INFO"
    }
    exit 0
}

# Execute main function
Main
