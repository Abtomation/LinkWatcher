#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates bug status updates in the Bug Tracking state file

.DESCRIPTION
This script automates bug status transitions in the bug-tracking.md state file,
supporting the complete bug lifecycle from Needs Triage to Closed.

Updates the following files (defaults; override with -TrackingFile / -ArchiveFile):
- doc/state-tracking/permanent/bug-tracking.md (live sections: 4 priority subsections + Bug Statistics)
- doc/state-tracking/permanent/archive/bug-tracking-archive.md (## Closed Bugs + ## Rejected Bugs;
  archive-split 2026-05-26 per PF-IMP-872)

Supports all bug status transitions:
- 🆕 Needs Triage → 🔍 Needs Fix (Bug Triage Task)
- 🔍 Needs Fix → 🟡 In Progress (Bug Fixing Task)
- 🟡 In Progress → 👀 Needs Review (Bug Fixing Task)
- 👀 Needs Review → 🔒 Closed (Code Review Task)
- Any Active Status → ❌ Rejected (Bug Fixing Task — not-a-bug, won't-fix, or other rationale per Step 11)
- Any Status → 🔄 Reopened (Bug Triage Task)

When transitioning to Closed:
- Moves the bug entry from its active priority table to ## Closed Bugs in the archive file
- Recalculates Bug Statistics (active counts by priority)

When transitioning to Rejected (PF-IMP-872):
- Moves the bug entry from its active priority table to ## Rejected Bugs in the archive file
  (separate section from Closed — kept distinct for trend analysis: "decided not to fix" vs "fixed")
- Recalculates Bug Statistics (active counts by priority)

When transitioning to Reopened:
- Searches BOTH archive sections (## Closed Bugs and ## Rejected Bugs) for the row
- Moves it back to the appropriate active priority table in the live file
- Recalculates Bug Statistics (active counts by priority)

.PARAMETER BugId
The bug ID to update (e.g., "BUG-001")

.PARAMETER NewStatus
The new status for the bug. Valid values:
- "NeedsFix" (🔍 Needs Fix)
- "InProgress" (🟡 In Progress)
- "NeedsReview" (👀 Needs Review)
- "Closed" (🔒 Closed) — auto-moves to archive ## Closed Bugs section (PF-IMP-872), recalculates stats
- "Reopened" (🔄 Reopened) — auto-moves from archive (## Closed Bugs or ## Rejected Bugs) back to active priority section
- "Rejected" (❌ Rejected) — not-a-bug, won't-fix, or other rationale per Bug Fixing Step 11; auto-moves to archive ## Rejected Bugs section (PF-IMP-872), recalculates stats

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

.PARAMETER RelatedFeature
Related feature ID or name (e.g., "1.1.1") - used when transitioning to NeedsFix to set the Related Feature column

.PARAMETER Dims
Development dimension abbreviations (e.g., "SE DI") - used when transitioning to NeedsFix

.PARAMETER Workflows
Affected user workflows (e.g., "WF-001, WF-003") - used when transitioning to NeedsFix

.PARAMETER TriageNotes
Triage rationale to append to the Notes field - used when transitioning to NeedsFix

.PARAMETER TrackingFile
Path to the live bug-tracking.md file (override default for tests / non-standard layouts).
Default: doc/state-tracking/permanent/bug-tracking.md under Get-ProjectRoot.

.PARAMETER ArchiveFile
Path to the sibling archive file containing ## Closed Bugs and ## Rejected Bugs sections
(archive-split 2026-05-26 per PF-IMP-872). Defaults to `archive/bug-tracking-archive.md`
relative to the directory of -TrackingFile, mirroring the Update-ProcessImprovement.ps1 pattern.

.PARAMETER UpdateDate
Date of the status update (optional - uses current date if not specified)

.EXAMPLE
# Triage a bug (set to Needs Fix)
../Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "NeedsFix" -Priority "High" -Scope "S" -RelatedFeature "1.1.1" -Dims "SE DI" -Workflows "WF-001, WF-003" -TriageNotes "Impacts all users on startup; root cause likely in config loader"

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

Output behavior: Default output is one summary line per invocation (the outcome,
e.g. "BUG-042 → Closed"). WARN and ERROR messages always pass through.
Pass -Verbose to restore the full play-by-play log for debugging.
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
    [string]$RelatedFeature,

    [Parameter(Mandatory = $false)]
    [string]$Dims,

    [Parameter(Mandatory = $false)]
    [string]$Workflows,

    [Parameter(Mandatory = $false)]
    [string]$TriageNotes,

    [Parameter(Mandatory = $false)]
    [datetime]$UpdateDate = (Get-Date),

    [Parameter(Mandatory = $false)]
    [string]$TrackingFile,

    # Archive-split (2026-05-26 per PF-IMP-872): sibling archive file holding
    # ## Closed Bugs and ## Rejected Bugs sections. Default sits in an `archive/`
    # subdir next to -TrackingFile, mirroring Update-ProcessImprovement.ps1's
    # -ArchiveFile resolution. Callers passing a custom -TrackingFile get an
    # archive path computed relative to it.
    [Parameter(Mandatory = $false)]
    [string]$ArchiveFile
)

# Import the common helpers for Get-ProjectRoot
$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
# Temporarily silence $VerbosePreference around the import so -Verbose callers see
# only this script's own Write-Verbose output, not the helper module's internal chatter.
$prevVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
$VerbosePreference = $prevVerbosePreference

# Configuration - use project-root-relative path for reliability
$ProjectRoot = Get-ProjectRoot
if (-not $TrackingFile) {
    $TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/bug-tracking.md"
}
$BugTrackingFile = $TrackingFile

# Archive-split (2026-05-26, PF-IMP-872): default ArchiveFile sits in an `archive/`
# subdir next to -TrackingFile. Mirrors the Update-ProcessImprovement.ps1 pattern.
if (-not $ArchiveFile) {
    $trackingDir = Split-Path -Parent $BugTrackingFile
    $ArchiveFile = Join-Path -Path $trackingDir -ChildPath "archive/bug-tracking-archive.md"
}

$ScriptName = "../Update-BugStatus.ps1"

# Soak verification (PF-PRO-028 — see process-framework-central/state-tracking/permanent/script-soak-tracking.md; v2.1 normalized ScriptId per PF-PRO-032)
$soakScriptId = "scripts/update/Update-BugStatus.ps1"
$soakInSoak   = Test-ScriptInSoak -ScriptId $soakScriptId -ScriptPath $PSCommandPath

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
#   [3] = Priority     (Critical/High/Medium/Low)
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
    # Default-quiet logger. INFO/SUCCESS go to Write-Verbose (visible only with -Verbose).
    # WARN/ERROR are always emitted to host. The single per-invocation summary line
    # is emitted directly via Write-SummaryLine, bypassing this gate.
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    switch ($Level) {
        "ERROR"   { Write-Host $line -ForegroundColor Red }
        "WARN"    { Write-Host $line -ForegroundColor Yellow }
        default   { Write-Verbose $line }
    }
}

function Write-SummaryLine {
    # One-line visible outcome per invocation. Bypasses Write-Log's default-quiet gate.
    param([string]$Message, [string]$Level = "SUCCESS")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR"   { "Red" }
        "WARN"    { "Yellow" }
        default   { "Green" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."

    if (-not (Test-Path $BugTrackingFile)) {
        Write-Log "Bug tracking file not found: $BugTrackingFile" -Level "ERROR"
        return $false
    }

    # Archive file (PF-IMP-872): only required for status transitions that touch it
    # (Closed / Rejected / Reopened). Other transitions (NeedsFix / InProgress / NeedsReview)
    # operate only on the live file. Skip the existence check for those.
    $archiveRequired = $false
    if ($FastClose) { $archiveRequired = $true }
    elseif ($NewStatus -in @("Closed", "Rejected", "Reopened")) { $archiveRequired = $true }

    if ($archiveRequired -and -not (Test-Path $ArchiveFile)) {
        Write-Log "Archive file not found: $ArchiveFile (required for $NewStatus transitions per PF-IMP-872 archive-split). Create from blueprint or pass -ArchiveFile pointing at an existing archive." -Level "ERROR"
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
        $columns[3] = $UpdateData.Priority
    }

    # Update scope if provided
    if ($UpdateData.Scope) {
        $columns[4] = $UpdateData.Scope
    }

    # Update Related Feature if provided (column [7])
    if ($UpdateData.RelatedFeature) {
        $columns[7] = $UpdateData.RelatedFeature
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

function Move-BugFromArchiveContent {
    # PF-IMP-872 (2026-05-26): two-file Reopened path. Source = $ArchiveContent
    # (## Closed Bugs OR ## Rejected Bugs); destination = $LiveContent (the bug's
    # priority-appropriate subsection). Returns @{ LiveContent; ArchiveContent }
    # or $null on failure.
    param(
        [string]$LiveContent,
        [string]$ArchiveContent,
        [string]$BugId
    )

    # Locate the row in the archive — scan both ## Closed Bugs and ## Rejected Bugs
    # to discover which section holds it AND extract its Priority cell to determine
    # the target live subsection.
    $archiveLines = $ArchiveContent -split "\r?\n"
    $bugLine = $null
    $sourceArchiveSection = $null
    $currentArchiveSection = $null
    foreach ($line in $archiveLines) {
        if ($line -match '^## (Closed Bugs|Rejected Bugs)\s*$') {
            $currentArchiveSection = "## $($Matches[1])"
            continue
        }
        if ($currentArchiveSection -and $line -match "^\|\s*$BugId\s*\|") {
            $bugLine = $line
            $sourceArchiveSection = $currentArchiveSection
            break
        }
    }

    if (-not $bugLine) {
        Write-Log "Could not find bug $BugId in archive (neither ## Closed Bugs nor ## Rejected Bugs)" -Level "ERROR"
        return $null
    }

    # Extract Priority column (index 3) to determine target live subsection.
    $columns = $bugLine -split '\|' | ForEach-Object { $_.Trim() }
    if ($columns[0] -eq '') { $columns = $columns[1..($columns.Length - 1)] }
    $priorityValue = $columns[3].Trim()

    $targetSubsection = switch ($priorityValue) {
        "Critical" { "### Critical Bugs" }
        "High"     { "### High Priority Bugs" }
        "Medium"   { "### Medium Priority Bugs" }
        "Low"      { "### Low Priority Bugs" }
        default {
            Write-Log "Unknown priority '$priorityValue' for bug $BugId, defaulting to ### Medium Priority Bugs" -Level "WARN"
            "### Medium Priority Bugs"
        }
    }

    # Build ColumnMapping identity (live and archive tables share the same 11-column schema)
    $bugHeaders = @('ID','Title','Status','Priority','Scope','Reported','Description','Related Feature','Workflows','Dims','Notes')
    $columnMapping = [ordered]@{}
    foreach ($h in $bugHeaders) { $columnMapping[$h] = $h }

    # Use Move-MarkdownTableRow in reverse two-file mode (archive → live).
    # SectionEndPattern '^### ' ensures the destination scan stops at the next priority
    # subsection (not at next `##` which would skip past sibling priority sections).
    $result = Move-MarkdownTableRow `
        -Content $ArchiveContent `
        -DestinationContent $LiveContent `
        -RowIdPattern ([regex]::Escape($BugId)) `
        -SourceSection $sourceArchiveSection `
        -DestinationSection $targetSubsection `
        -ColumnMapping $columnMapping `
        -SectionEndPattern '^### '

    if (-not $result -or $null -eq $result.Content) {
        Write-Log "Move-MarkdownTableRow failed: archive($sourceArchiveSection) → live($targetSubsection) for $BugId" -Level "ERROR"
        return $null
    }

    # Remove "No X bugs currently active" placeholder if the target subsection had one
    # (Move-MarkdownTableRow doesn't know about these decorative-empty markers).
    $newLiveLines = [System.Collections.ArrayList]@($result.DestinationContent -split "\r?\n")
    for ($i = 0; $i -lt $newLiveLines.Count; $i++) {
        if ($newLiveLines[$i].Trim() -eq $targetSubsection) {
            for ($j = $i + 1; $j -lt $newLiveLines.Count -and -not ($newLiveLines[$j] -match '^### |^## '); $j++) {
                if ($newLiveLines[$j] -match "^\|\s*_No .+ bugs currently") {
                    $newLiveLines.RemoveAt($j)
                    break
                }
            }
            break
        }
    }

    Write-Log "Moved bug $BugId from archive ($sourceArchiveSection) to live ($targetSubsection)" -Level "SUCCESS"
    return @{
        LiveContent    = ($newLiveLines -join "`r`n")
        ArchiveContent = $result.Content
    }
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

function Move-BugToArchiveContent {
    # PF-IMP-872 (2026-05-26): two-file archive path for Closed / Rejected.
    # Source = $LiveContent (one of the 4 priority subsections); destination =
    # $ArchiveContent (## Closed Bugs for Closed, ## Rejected Bugs for Rejected).
    # Returns @{ LiveContent; ArchiveContent } or $null on failure.
    param(
        [string]$LiveContent,
        [string]$ArchiveContent,
        [string]$BugId,
        [Parameter(Mandatory)][ValidateSet("Closed", "Rejected")]
        [string]$Disposition
    )

    # Discover which priority subsection holds the bug in live content.
    # We do this manually rather than scanning blindly with Move-MarkdownTableRow,
    # because the row could be in any of the 4 priority subsections.
    $liveLines = $LiveContent -split "\r?\n"
    $sourceSubsection = $null
    $currentSubsection = $null
    foreach ($line in $liveLines) {
        if ($line -match '^### (Critical|High Priority|Medium Priority|Low Priority) Bugs\s*$') {
            $currentSubsection = "### $($Matches[1]) Bugs"
            continue
        }
        if ($line -match '^## (?!#)') {
            # Left the Bug Registry section — stop scanning
            if ($currentSubsection) { $currentSubsection = $null }
        }
        if ($currentSubsection -and $line -match "^\|\s*$BugId\s*\|") {
            $sourceSubsection = $currentSubsection
            break
        }
    }

    if (-not $sourceSubsection) {
        Write-Log "Could not find bug $BugId in any live priority subsection" -Level "ERROR"
        return $null
    }

    # Destination section depends on disposition (dual-section archive per PF-IMP-872).
    $destinationSection = if ($Disposition -eq "Closed") { "## Closed Bugs" } else { "## Rejected Bugs" }

    # Build ColumnMapping identity (live priority tables and archive sections share schema)
    $bugHeaders = @('ID','Title','Status','Priority','Scope','Reported','Description','Related Feature','Workflows','Dims','Notes')
    $columnMapping = [ordered]@{}
    foreach ($h in $bugHeaders) { $columnMapping[$h] = $h }

    # Two-file Move-MarkdownTableRow: live → archive.
    # SectionEndPattern '^### ' bounds the source-row search to just the matched
    # priority subsection (without it, the search would skim through all 4 subsections).
    $result = Move-MarkdownTableRow `
        -Content $LiveContent `
        -DestinationContent $ArchiveContent `
        -RowIdPattern ([regex]::Escape($BugId)) `
        -SourceSection $sourceSubsection `
        -DestinationSection $destinationSection `
        -ColumnMapping $columnMapping `
        -SectionEndPattern '^### '

    if (-not $result -or $null -eq $result.Content) {
        Write-Log "Move-MarkdownTableRow failed: live($sourceSubsection) → archive($destinationSection) for $BugId" -Level "ERROR"
        return $null
    }

    # Add "_No X bugs currently active_" placeholder if the source subsection is now empty.
    $newLiveLines = [System.Collections.ArrayList]@($result.Content -split "\r?\n")
    for ($i = 0; $i -lt $newLiveLines.Count; $i++) {
        if ($newLiveLines[$i].Trim() -eq $sourceSubsection) {
            $hasDataRows = $false
            $separatorIdx = -1
            for ($j = $i + 1; $j -lt $newLiveLines.Count -and -not ($newLiveLines[$j] -match '^### |^## '); $j++) {
                if ($newLiveLines[$j] -match "^\|\s*PD-BUG-") { $hasDataRows = $true; break }
                if ($newLiveLines[$j] -match '^\|\s*[-\s:|]+\s*\|') { $separatorIdx = $j }
            }
            if (-not $hasDataRows -and $separatorIdx -ge 0) {
                $priorityLabel = if ($sourceSubsection -match 'Critical') { 'critical' }
                                 elseif ($sourceSubsection -match 'High') { 'high priority' }
                                 elseif ($sourceSubsection -match 'Medium') { 'medium priority' }
                                 else { 'low priority' }
                $newLiveLines.Insert($separatorIdx + 1, "| _No $priorityLabel bugs currently active_ |")
            }
            break
        }
    }

    Write-Log "Moved bug $BugId from live ($sourceSubsection) to archive ($destinationSection)" -Level "SUCCESS"
    return @{
        LiveContent    = ($newLiveLines -join "`r`n")
        ArchiveContent = $result.DestinationContent
    }
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
    $result = $result -replace '- \*\*Critical\*\*:.*', (Format-StatLine "Critical" $bugIds.Critical)
    $result = $result -replace '- \*\*High\*\*:.*', (Format-StatLine "High" $bugIds.High)
    $result = $result -replace '- \*\*Medium\*\*:.*', (Format-StatLine "Medium" $bugIds.Medium)
    $result = $result -replace '- \*\*Low\*\*:.*', (Format-StatLine "Low" $bugIds.Low)

    Write-Log "Updated bug statistics: $totalActive active ($($bugIds.Critical.Count) Critical, $($bugIds.High.Count) High, $($bugIds.Medium.Count) Medium, $($bugIds.Low.Count) Low)" -Level "SUCCESS"
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

        # Two-file mode (PF-IMP-872): load both live and archive content.
        $content = Get-Content $BugTrackingFile -Raw
        $archiveContent = Get-Content $ArchiveFile -Raw

        # Phase 1: NeedsFix (triage)
        $triageData = @{ Priority = $Priority }
        if ($Scope) { $triageData.Scope = $Scope } else { $triageData.Scope = "S" }
        if ($RelatedFeature) { $triageData.RelatedFeature = $RelatedFeature }
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

        # Move to archive ## Closed Bugs section (PF-IMP-872) and recalculate stats
        $moveResult = Move-BugToArchiveContent -LiveContent $content -ArchiveContent $archiveContent -BugId $BugId -Disposition "Closed"
        if ($null -eq $moveResult) { Write-Log "Failed to move bug to archive ## Closed Bugs" -Level "ERROR"; exit 1 }
        $content = $moveResult.LiveContent
        $archiveContent = $moveResult.ArchiveContent
        $content = Update-BugStatisticsContent -Content $content

        try {
            if ($PSCmdlet.ShouldProcess($BugTrackingFile, "FastClose $BugId (NeedsFix → InProgress → Closed)")) {
                Set-Content -Path $BugTrackingFile -Value $content -NoNewline
                Set-Content -Path $ArchiveFile -Value $archiveContent -NoNewline
                Write-SummaryLine "$BugId → Closed (FastClose: NeedsFix → InProgress → Closed)"

                # Read-after-write verification: confirm the bug row exists in archive (it moved there)
                if (-not $WhatIfPreference) {
                    $rowPattern = "\|\s*" + [regex]::Escape($BugId) + "\s*\|"
                    Assert-LineInFile -Path $ArchiveFile -Pattern $rowPattern -Context "bug row for $BugId in $ArchiveFile (archive)"
                }

                if ($soakInSoak) {
                    Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
                }
            } else {
                Write-Log "Dry-run complete — no file changes written" -Level "INFO"
            }
        }
        catch {
            if ($soakInSoak) {
                $soakErrMsg = $_.Exception.Message
                if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
                Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome failure -Notes $soakErrMsg
            }
            Write-ProjectError -Message "FastClose failed: $($_.Exception.Message)" -ExitCode 1
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
    if ($RelatedFeature) { $updateData.RelatedFeature = $RelatedFeature }
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
    # PF-IMP-872 (2026-05-26): two-file mode. Archive content loaded only when the
    # transition touches it (Closed / Rejected / Reopened).
    $content = Get-Content $BugTrackingFile -Raw
    $archiveContent = $null
    $touchesArchive = $NewStatus -in @("Closed", "Rejected", "Reopened")
    if ($touchesArchive) {
        $archiveContent = Get-Content $ArchiveFile -Raw
    }

    # Step 0 (Reopened only): move the row archive → live BEFORE updating the row.
    # The row currently lives in archive; subsequent Update-BugEntryContent must
    # find it in live.
    if ($NewStatus -eq "Reopened") {
        $moveResult = Move-BugFromArchiveContent -LiveContent $content -ArchiveContent $archiveContent -BugId $BugId
        if ($null -eq $moveResult) {
            Write-Log "Failed to move bug $BugId from archive to active section" -Level "ERROR"
            exit 1
        }
        $content = $moveResult.LiveContent
        $archiveContent = $moveResult.ArchiveContent
    }

    # Step 1: Update the bug entry (status, notes) in live content
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

    # Step 2 (Closed / Rejected only): move the now-updated row live → archive.
    # Dual-section routing per PF-IMP-872: Closed → ## Closed Bugs, Rejected → ## Rejected Bugs.
    if ($NewStatus -eq "Closed" -or $NewStatus -eq "Rejected") {
        $moveResult = Move-BugToArchiveContent -LiveContent $content -ArchiveContent $archiveContent -BugId $BugId -Disposition $NewStatus
        if ($null -eq $moveResult) {
            Write-Log "Failed to move bug $BugId to archive ## $NewStatus Bugs section" -Level "ERROR"
            exit 1
        }
        $content = $moveResult.LiveContent
        $archiveContent = $moveResult.ArchiveContent
    }

    # Step 3: Recalculate statistics (live only)
    $content = Update-BugStatisticsContent -Content $content

    # Write — guarded by ShouldProcess so -WhatIf skips only the file writes
    try {
        if ($PSCmdlet.ShouldProcess($BugTrackingFile, "Update $BugId to $NewStatus")) {
            Set-Content -Path $BugTrackingFile -Value $content -NoNewline
            if ($touchesArchive) {
                Set-Content -Path $ArchiveFile -Value $archiveContent -NoNewline
            }
            Write-SummaryLine "$BugId → $NewStatus"

            # Read-after-write verification: confirm the bug row exists where it should be after the move
            if (-not $WhatIfPreference) {
                $rowPattern = "\|\s*" + [regex]::Escape($BugId) + "\s*\|"
                $verifyFile = if ($NewStatus -in @("Closed", "Rejected")) { $ArchiveFile } else { $BugTrackingFile }
                Assert-LineInFile -Path $verifyFile -Pattern $rowPattern -Context "bug row for $BugId in $verifyFile"
            }

            if ($soakInSoak) {
                Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
            }
        } else {
            Write-Log "Dry-run complete — no file changes written" -Level "INFO"
        }
    }
    catch {
        if ($soakInSoak) {
            $soakErrMsg = $_.Exception.Message
            if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
            Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome failure -Notes $soakErrMsg
        }
        Write-ProjectError -Message "Bug status update failed: $($_.Exception.Message)" -ExitCode 1
    }
    exit 0
}

# Execute main function
Main
