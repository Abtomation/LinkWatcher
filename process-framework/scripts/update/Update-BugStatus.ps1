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
- Any Active Status → ❌ Rejected (Bug Fixing Task — not-a-bug, won't-fix, or other rationale per its routing checkpoint)
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
- "Rejected" (❌ Rejected) — not-a-bug, won't-fix, or other rationale per the Bug Fixing routing checkpoint; auto-moves to archive ## Rejected Bugs section (PF-IMP-872), recalculates stats

.PARAMETER FastClose
S-scope quick path: chains NeedsFix → InProgress → Closed in one call.
Requires: Priority, FixDetails, VerificationNotes. Scope defaults to "S" if not specified.
Use this for small bugs that are triaged, fixed, and closed in a single session.

.PARAMETER Priority
Bug priority (Critical, High, Medium, Low). Required when transitioning to NeedsFix and with -FastClose.

.PARAMETER Scope
Bug fix scope (S, M, L) - used to indicate fix complexity and whether a state file is needed



.PARAMETER FixDetails
Details about the fix implementation. Required when transitioning to NeedsReview and with -FastClose.

.PARAMETER RootCause
Root cause analysis - used when transitioning to NeedsReview

.PARAMETER TestsAdded
Regression tests added — "Yes"/"No", or a short free-text summary of the tests added.
Used when transitioning to NeedsReview; rendered into the bug's Notes as "Tests Added: <value>".

.PARAMETER PullRequestUrl
URL to the pull request containing the fix - used when transitioning to NeedsReview

.PARAMETER VerificationNotes
Notes from verification process. Required when transitioning to Closed and with -FastClose;
accepted on any transition, and carried into the bug's Notes as "Verification: <value>" on
whichever one supplied it. The Code Review task uses it on a rejection (-NewStatus InProgress)
to carry the review findings the next Bug Fixing session reads.

.PARAMETER ReopenReason
Reason for reopening the bug. Required when transitioning to Reopened.

.PARAMETER RejectionReason
Rationale for rejecting the bug (not-a-bug, won't-fix, or other). Required when transitioning to Rejected.

.PARAMETER RelatedFeature
Related feature ID or name (e.g., "1.1.1") - used when transitioning to NeedsFix to set the Related Feature column

.PARAMETER Dims
Development dimension abbreviations, space- or comma-separated (e.g., "SE DI" or "SE,DI") - used
when transitioning to NeedsFix. Validated against the 10 documented codes: AC, CQ, ID, DA, EM,
SE, PE, OB, UX, DI (see the Development Dimensions Guide).

.PARAMETER Workflows
Affected user workflows (e.g., "WF-001, WF-003") - used when transitioning to NeedsFix

.PARAMETER TriageNotes
Triage rationale to append to the Notes field - used when transitioning to NeedsFix

.PARAMETER OriginBug
The single bug whose cycle produced this one (e.g. "PD-BUG-127") — the defect-chain link
(PF-PRO-078). Accepted on ANY transition, not just triage: the reporter often does not know the
origin, and the linking session is usually the one that recognises the chain. Validated to exist
as a row in the live tracker or its archive, so a mistyped origin fails loudly rather than
breaking the chain walk it exists to enable. Written to the row's Origin cell and as a dated
Origin entry in the bug's Bug Details block; a tracker whose header predates the column keeps the
block entry and warns once.

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

    # Same -Dims contract as New-BugReport.ps1 (the other bug-tracker writer), pinned by the
    # cross-script drift guard in New-BugReport.Tests.ps1 (PF-IMP-2130).
    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if ([string]::IsNullOrWhiteSpace($_)) { return $true }
        $validDims = @('AC', 'CQ', 'ID', 'DA', 'EM', 'SE', 'PE', 'OB', 'UX', 'DI')
        $invalid = @($_ -split '[\s,]+' | Where-Object { $_ -ne '' -and $_ -notin $validDims })
        if ($invalid) {
            throw "Invalid -Dims code(s): $($invalid -join ', '). Valid codes: $($validDims -join ', '). Use space or comma to separate multiple. See the Development Dimensions Guide."
        }
        return $true
    })]
    [string]$Dims,

    [Parameter(Mandatory = $false)]
    [string]$Workflows,

    [Parameter(Mandatory = $false)]
    [string]$TriageNotes,

    # Defect-chain origin (PF-PRO-078). Same contract as New-BugReport.ps1's parameter of the same
    # name; the shape is validated here and the referenced row's existence once the files are read.
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^(PD-BUG|BUG)-\d+$')]
    [string]$OriginBug,

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

# ---------------------------------------------------------------------------
# Bug Details blocks (PF-IMP-2184 / PF-PRO-073)
#
# Lifecycle prose no longer accumulates in the Notes table cell. A markdown table
# row must occupy exactly ONE line, so a cell has no upper bound: measured at 51,854
# characters (~8,000 words) in APP-001 before this convention, because every reopen /
# re-review bounce appended a fresh full narrative and nothing superseded anything.
# The cell now carries a capped summary plus a pointer; the prose lives in a per-bug
# block under '## Bug Details', where entries wrap freely across lines.
#
# The block travels WITH the row: Move-BugToArchiveContent and Move-BugFromArchiveContent
# each relocate both, remove-and-append, never append-only — an append-only block move
# would leave orphan blocks accreting in the live tracker, i.e. the same unbounded-growth
# defect relocated into a new section, and nothing would catch it (Validate-StateTracking
# skips '#anchor' links and LinkWatcher does not check anchors against headings).
# ---------------------------------------------------------------------------

$BugDetailsHeading = '## Bug Details'
$BugNotesCellCap   = 200

function Get-BugAnchor {
    param([string]$BugId)
    return "#$($BugId.ToLower())"
}

function Format-BugNotesCell {
    # Capped summary + pointer. The pointer is always preserved in full; only the
    # summary is truncated, so a long summary can never cost the row its link.
    param(
        [string]$BugId,
        [string]$Summary
    )
    $pointer = "[details]($(Get-BugAnchor -BugId $BugId))"
    $budget = $BugNotesCellCap - $pointer.Length - 1
    $clean = ($Summary -replace '\s+', ' ').Trim()
    if ($clean.Length -gt $budget) {
        $clean = $clean.Substring(0, [Math]::Max(0, $budget - 1)).TrimEnd() + '…'
    }
    if ([string]::IsNullOrWhiteSpace($clean)) { return $pointer }
    return "$clean $pointer"
}

function Get-BugDetailBlockBounds {
    # Returns @{ Start; End } line indices (inclusive) of the '### <BugId>' block, or
    # $null when the bug has no block. End is the last line BEFORE the next heading.
    param(
        [string[]]$Lines,
        [string]$BugId
    )
    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match "^###\s+$([regex]::Escape($BugId))\s*$") { $start = $i; break }
    }
    if ($start -lt 0) { return $null }

    # A block ends at the next heading OR at a horizontal rule. The rule matters: both
    # shipped templates place a '---' separator immediately after the Bug Details section,
    # and a heading-only scan runs straight past it — appending entries below the rule,
    # outside the block, with no error raised (caught in fixture testing, 2026-09-01).
    $end = $Lines.Count - 1
    for ($j = $start + 1; $j -lt $Lines.Count; $j++) {
        if ($Lines[$j] -match '^#{2,3}\s' -or $Lines[$j].Trim() -match '^(-{3,}|\*{3,}|_{3,})$') { $end = $j - 1; break }
    }
    # Trim trailing blank lines so a moved block never carries growing whitespace.
    while ($end -gt $start -and [string]::IsNullOrWhiteSpace($Lines[$end])) { $end-- }
    return @{ Start = $start; End = $end }
}

function Get-BugDetailBlock {
    # Returns the block text ('### <BugId>' heading through its last content line), or $null.
    param(
        [string]$Content,
        [string]$BugId
    )
    $lines = $Content -split "\r?\n"
    $bounds = Get-BugDetailBlockBounds -Lines $lines -BugId $BugId
    if ($null -eq $bounds) { return $null }
    return (($lines[$bounds.Start..$bounds.End]) -join "`r`n")
}

function Remove-BugDetailBlock {
    # Content with the bug's block excised. Returns the content unchanged when the bug
    # has no block, so callers can treat "no block" as benign rather than as failure.
    param(
        [string]$Content,
        [string]$BugId
    )
    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")
    $bounds = Get-BugDetailBlockBounds -Lines $lines -BugId $BugId
    if ($null -eq $bounds) { return $Content }

    # Also consume the blank line that separated this block from the next, so repeated
    # move cycles cannot grow a run of blank lines in either file.
    $end = $bounds.End
    while (($end + 1) -lt $lines.Count -and [string]::IsNullOrWhiteSpace($lines[$end + 1])) { $end++ }
    if ($end -ge $lines.Count) { $end = $lines.Count - 1 }

    $lines.RemoveRange($bounds.Start, $end - $bounds.Start + 1)

    # Restore the decorative empty-section placeholder when the last block leaves, mirroring the
    # priority tables' "_No <priority> bugs currently active_" rows. Without it a fully-archived
    # tracker shows a bare heading rather than saying so.
    $sectionIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq $BugDetailsHeading) { $sectionIdx = $i; break }
    }
    if ($sectionIdx -ge 0) {
        $hasBlock = $false
        $sectionEnd = $lines.Count
        for ($j = $sectionIdx + 1; $j -lt $lines.Count; $j++) {
            if ($lines[$j] -match '^##\s' -or $lines[$j].Trim() -match '^(-{3,}|\*{3,}|_{3,})$') { $sectionEnd = $j; break }
            if ($lines[$j] -match '^###\s') { $hasBlock = $true; break }
        }
        if (-not $hasBlock) {
            $already = $false
            for ($j = $sectionIdx + 1; $j -lt $sectionEnd; $j++) {
                if ($lines[$j].Trim() -eq '_No active bugs currently._') { $already = $true; break }
            }
            if (-not $already) {
                $at = $sectionEnd
                while ($at -gt $sectionIdx + 1 -and [string]::IsNullOrWhiteSpace($lines[$at - 1])) { $at-- }
                $lines.InsertRange($at, [string[]]@('', '_No active bugs currently._'))
            }
        }
    }
    return ($lines -join "`r`n")
}

function Add-BugDetailSection {
    # Creates the '## Bug Details' section in a file that predates PF-IMP-2184.
    #
    # Why auto-create rather than refuse: a project receives the reworked scripts at a
    # Framework Rollout, but its bug-tracking.md only gains the section when the Mode C
    # migration is applied — a gap that can span days. Refusing would fail EVERY bug
    # transition in that window. Placement mirrors the shipped template: immediately after
    # the Bug Statistics section, which keeps detail prose below the region both writers
    # scan for active-bug counts.
    param([System.Collections.ArrayList]$Lines)

    $statsIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^##\s+Bug Statistics\s*$') { $statsIdx = $i; break }
    }

    $insertAt = $Lines.Count
    if ($statsIdx -ge 0) {
        $insertAt = $Lines.Count
        for ($j = $statsIdx + 1; $j -lt $Lines.Count; $j++) {
            if ($Lines[$j] -match '^##\s' -or $Lines[$j].Trim() -match '^(-{3,}|\*{3,}|_{3,})$') { $insertAt = $j; break }
        }
        while ($insertAt -gt $statsIdx + 1 -and [string]::IsNullOrWhiteSpace($Lines[$insertAt - 1])) { $insertAt-- }
    }

    $Lines.InsertRange($insertAt, [string[]]@('', $BugDetailsHeading))
    Write-ProjectLog "Created '$BugDetailsHeading' section (file predated PF-IMP-2184)" -Level "WARN"
    return $insertAt + 1
}

function Add-BugDetailBlock {
    # Appends a whole block under '## Bug Details', creating that section when the file
    # predates the convention (see Add-BugDetailSection).
    param(
        [string]$Content,
        [string]$BlockText
    )
    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")
    $sectionIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq $BugDetailsHeading) { $sectionIdx = $i; break }
    }
    if ($sectionIdx -lt 0) {
        $sectionIdx = Add-BugDetailSection -Lines $lines
    }

    # Insert at the end of the section (before the next '## ' heading, else EOF).
    $insertAt = $lines.Count
    for ($j = $sectionIdx + 1; $j -lt $lines.Count; $j++) {
        if ($lines[$j] -match '^##\s' -or $lines[$j].Trim() -eq '---') { $insertAt = $j; break }
    }
    while ($insertAt -gt $sectionIdx + 1 -and [string]::IsNullOrWhiteSpace($lines[$insertAt - 1])) { $insertAt-- }

    $block = @('') + ($BlockText -split "\r?\n")
    $lines.InsertRange($insertAt, [string[]]$block)
    return ($lines -join "`r`n")
}

function Add-BugDetailEntry {
    # Appends dated bullet(s) to the bug's block, creating the block when absent.
    # Returns $null on failure so the caller aborts before any file is written.
    param(
        [string]$Content,
        [string]$BugId,
        [string[]]$Entries
    )
    if (-not $Entries -or $Entries.Count -eq 0) { return $Content }

    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")
    $bounds = Get-BugDetailBlockBounds -Lines $lines -BugId $BugId
    if ($null -eq $bounds) {
        $newBlock = (@("### $BugId", '') + $Entries) -join "`r`n"
        return (Add-BugDetailBlock -Content $Content -BlockText $newBlock)
    }
    $lines.InsertRange($bounds.End + 1, [string[]]$Entries)
    return ($lines -join "`r`n")
}

function Move-BugDetailBlock {
    # Relocates a bug's block between the live tracker and the archive: removed from the
    # source, appended to the destination. Mirrors Move-MarkdownTableRow's two-file
    # contract so the row and its block can never end up on opposite sides.
    # Returns @{ SourceContent; DestinationContent } or $null on failure.
    param(
        [string]$SourceContent,
        [string]$DestinationContent,
        [string]$BugId
    )
    $block = Get-BugDetailBlock -Content $SourceContent -BugId $BugId
    if ($null -eq $block) {
        # No block to move (a pre-migration row, or a bug that never gained one).
        # Benign: the row move is still valid, so pass both sides through untouched.
        Write-ProjectLog "No Bug Details block found for $BugId — row moved without one" -Level "WARN"
        return @{ SourceContent = $SourceContent; DestinationContent = $DestinationContent }
    }
    $newDestination = Add-BugDetailBlock -Content $DestinationContent -BlockText $block
    if ($null -eq $newDestination) { return $null }
    $newSource = Remove-BugDetailBlock -Content $SourceContent -BugId $BugId
    return @{ SourceContent = $newSource; DestinationContent = $newDestination }
}

function Test-Prerequisites {
    Write-ProjectLog "Checking prerequisites..."

    if (-not (Test-Path $BugTrackingFile)) {
        Write-ProjectLog "Bug tracking file not found: $BugTrackingFile" -Level "ERROR"
        return $false
    }

    # Archive file (PF-IMP-872): only required for status transitions that touch it
    # (Closed / Rejected / Reopened). Other transitions (NeedsFix / InProgress / NeedsReview)
    # operate only on the live file. Skip the existence check for those.
    $archiveRequired = $false
    if ($FastClose) { $archiveRequired = $true }
    elseif ($NewStatus -in @("Closed", "Rejected", "Reopened")) { $archiveRequired = $true }

    if ($archiveRequired -and -not (Test-Path $ArchiveFile)) {
        Write-ProjectLog "Archive file not found: $ArchiveFile (required for $NewStatus transitions per PF-IMP-872 archive-split). Create from blueprint or pass -ArchiveFile pointing at an existing archive." -Level "ERROR"
        return $false
    }

    # Defect-chain origin (PF-PRO-078): the referenced bug must exist as a row, live or archived.
    # Checked here, before any transformation, so a typo costs no partial write — a chain is only
    # navigable if every link resolves. The archive is consulted whenever it exists, independently
    # of whether THIS transition touches it: an origin is very often an already-closed bug.
    if ($OriginBug) {
        $originPattern = "\|\s*" + [regex]::Escape($OriginBug) + "\s*\|"
        $originFound = (Get-Content $BugTrackingFile -Raw) -match $originPattern
        if (-not $originFound -and (Test-Path $ArchiveFile)) {
            $originFound = (Get-Content $ArchiveFile -Raw) -match $originPattern
        }
        if (-not $originFound) {
            Write-ProjectLog "-OriginBug '$OriginBug' matches no bug row in $BugTrackingFile or its archive. Check the ID: an origin that resolves to nothing breaks the chain walk it exists to enable." -Level "ERROR"
            return $false
        }
    }

    Write-ProjectLog "Prerequisites check passed" -Level "SUCCESS"
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

# --- Header-driven cell addressing (PF-PRO-078) ------------------------------------------------
# The bug row's columns are resolved from the file's own table header rather than from literal
# indices. Two properties this buys: a schema change (the Origin column, and whatever follows it)
# needs no index arithmetic here, and a tracker that has not yet received the column migration
# keeps working — the missing header simply resolves to nothing and its writer warns.

# The pre-Origin schema, used only when a file carries no parsable header (a truncated fixture,
# or content handed in mid-transformation). Never the primary path.
$BaselineBugHeaders = @('ID','Title','Status','Priority','Scope','Reported','Description','Related Feature','Workflows','Dims','Notes')

function Get-BugColumnIndexMap {
    <#
        Maps header name -> cell index, read from the header row that governs the row being
        written. Where several header rows exist (four priority tables live, two sections in the
        archive) the one whose width matches the row is preferred, so a live/archive schema
        mismatch during the migration window resolves each side against its own header instead of
        silently writing one schema's indices into the other's row.
    #>
    param(
        [string]$Content,
        [int]$RowCellCount = 0
    )

    # Selected in one pass, deliberately without a pipeline: piping a collection of header ROWS
    # enumerates it, and the width-matched row comes back wrapped one level deep — every lookup
    # then misses and the caller silently writes nothing (measured 2026-09-04 on this function).
    $headers = $null
    $firstCandidate = $null
    foreach ($line in ($Content -split "\r?\n")) {
        if ($line -notmatch '(?i)^\s*\|\s*ID\s*\|') { continue }
        $cells = @(Split-MarkdownTableRow -Line $line.Trim())
        if ($cells.Count -lt 2) { continue }
        if ($null -eq $firstCandidate) { $firstCandidate = $cells }
        if ($RowCellCount -gt 0 -and $cells.Count -eq $RowCellCount) { $headers = $cells; break }
    }
    # No header of this row's width. A row exactly the baseline width is an unmigrated row in a
    # file whose header has already moved on (live migrated, archive not yet, or the reverse):
    # read it against the baseline rather than truncating the wider header, which would slide
    # Origin onto the Notes cell and overwrite it. Any other width falls back to what is there.
    if ($null -eq $headers -and $RowCellCount -eq $BaselineBugHeaders.Count) { $headers = $BaselineBugHeaders }
    if ($null -eq $headers) { $headers = $firstCandidate }
    if ($null -eq $headers) { $headers = $BaselineBugHeaders }

    $map = @{}
    for ($i = 0; $i -lt $headers.Count; $i++) {
        $name = "$($headers[$i])".Trim()
        # An index past the row's own width would write outside the row; skip rather than throw,
        # so a narrower row keeps every column it does have.
        if ($name -and -not $map.ContainsKey($name) -and ($RowCellCount -le 0 -or $i -lt $RowCellCount)) {
            $map[$name] = $i
        }
    }
    return $map
}

function Set-BugCell {
    # Returns $true when the column exists in this row's schema and the value was written.
    param(
        [hashtable]$Map,
        [object[]]$Cells,
        [string]$Header,
        [string]$Value
    )
    if (-not $Map.ContainsKey($Header)) { return $false }
    $Cells[$Map[$Header]] = $Value
    return $true
}

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
        Write-ProjectLog "Bug entry not found: $BugId" -Level "ERROR"
        return $null
    }

    Write-ProjectLog "Found bug entry for $BugId"
    $currentEntry = $match.Value

    # Parse the table row (see column index mapping at top of script) through the canonical
    # TableOperations helper (PF-IMP-2069): it drops the empty element at BOTH ends and is
    # pipe-escape aware. The former hand-rolled split stripped only the LEADING empty element,
    # so the surviving trailing one became a stray empty cell on every rebuild below — one per
    # invocation, compounding across a bug's lifecycle.
    $parsedColumns = Split-MarkdownTableRow -Line $currentEntry.Trim()
    if ($null -eq $parsedColumns -or @($parsedColumns).Count -lt 11) {
        Write-ProjectLog "Bug entry for $BugId is not a well-formed table row (fewer than the 11 baseline columns): $currentEntry" -Level "ERROR"
        return $null
    }
    $columns = @($parsedColumns)

    # Cells are addressed BY HEADER, not by literal index (PF-PRO-078). The index map this
    # replaced was correct for exactly one schema; the Origin column shifted Notes from [10] to
    # [11], and the same literals would have to be re-derived for every future column. Resolving
    # against the row's own table header also makes a not-yet-migrated 11-column tracker work
    # unchanged — Origin simply resolves to nothing there, which is the tolerance the rollout
    # window needs (a project receives this script before its Mode C migration runs).
    $columnIndex = Get-BugColumnIndexMap -Content $Content -RowCellCount $columns.Count

    # Update status
    $statusEmoji = Get-StatusEmoji -Status $NewStatus
    $displayName = $StatusDisplayNames[$NewStatus]
    [void](Set-BugCell -Map $columnIndex -Cells $columns -Header 'Status' -Value "$statusEmoji $displayName")

    # Update priority if provided
    if ($UpdateData.Priority) {
        [void](Set-BugCell -Map $columnIndex -Cells $columns -Header 'Priority' -Value $UpdateData.Priority)
    }

    # Update scope if provided
    if ($UpdateData.Scope) {
        [void](Set-BugCell -Map $columnIndex -Cells $columns -Header 'Scope' -Value $UpdateData.Scope)
    }

    # Update Related Feature if provided
    if ($UpdateData.RelatedFeature) {
        [void](Set-BugCell -Map $columnIndex -Cells $columns -Header 'Related Feature' -Value $UpdateData.RelatedFeature)
    }

    # Update Workflows if provided
    if ($UpdateData.Workflows) {
        [void](Set-BugCell -Map $columnIndex -Cells $columns -Header 'Workflows' -Value $UpdateData.Workflows)
    }

    # Update Dims if provided
    if ($UpdateData.Dims) {
        [void](Set-BugCell -Map $columnIndex -Cells $columns -Header 'Dims' -Value $UpdateData.Dims)
    }

    # Update Origin if provided (PF-PRO-078). On a tracker without the column the value cannot
    # reach the row — warn once and let the Bug Details entry below carry it, rather than
    # dropping the fact silently or refusing a transition the schema has nothing to do with.
    if ($UpdateData.OriginBug) {
        if (-not (Set-BugCell -Map $columnIndex -Cells $columns -Header 'Origin' -Value $UpdateData.OriginBug)) {
            Write-ProjectLog "Tracker has no Origin column yet — $($UpdateData.OriginBug) recorded in the Bug Details block only (apply the Origin column migration to surface it in the row)" -Level "WARN"
        }
    }

    # Update notes with whatever detail the caller supplied (column [10]).
    #
    # PF-IMP-2069: this was a switch keyed on $NewStatus, with an arm per status naming the
    # fields that status consumes. Anything supplied outside the current status's arm was
    # accepted, carried into $UpdateData, and then silently dropped while the run still logged
    # SUCCESS. Two live losses: -VerificationNotes on the InProgress transition (no arm at all
    # — the exact call code-review-task.md prescribes on rejection, whose summary is the only
    # record of the findings the next Bug Fixing session reads), and -FixDetails / -RootCause /
    # -TestsAdded on the -FastClose path, where -FixDetails is a REQUIRED parameter that never
    # reached the row. An ordered label map applied to what was actually supplied kills the
    # discard class rather than adding a sixth hardcoded arm; order matches the former arms.
    # PF-IMP-2184: the supplied prose now becomes a dated entry in the bug's '## Bug Details'
    # block; the cell keeps only a capped summary plus the pointer to that block. The label map
    # and its order are unchanged — only the destination moved, which is why no task definition
    # and no caller had to change.
    $currentDate = Get-Date -Format "yyyy-MM-dd"

    $noteLabels = [ordered]@{
        # Origin leads: the summary cell shows the LAST label supplied, and a chain link is
        # metadata about the bug rather than the news of this transition — so when it arrives
        # alongside triage or fix prose, that prose stays the headline.
        OriginBug         = "Origin"
        TriageNotes       = "Triage"
        FixDetails        = "Fix"
        RootCause         = "Root Cause"
        TestsAdded        = "Tests Added"
        PullRequestUrl    = "PR"
        VerificationNotes = "Verification"
        ReopenReason      = "Reopen Reason"
        RejectionReason   = "Rejected"
    }

    $detailEntries = @()
    $lastLabel = $null
    $lastValue = $null

    # Rescue an unmigrated cell before overwriting it. A row that predates PF-IMP-2184 still
    # carries its full accreted prose in the cell; the new cell is a capped summary, so writing
    # it directly would DESTROY that prose for every row the migration has not yet converted —
    # and the rollout reaches a project before its Mode C migration does. Preserve it as a
    # legacy entry, which also makes the conversion self-healing per row on first touch.
    $notesIdx = if ($columnIndex.ContainsKey('Notes')) { $columnIndex['Notes'] } else { $columns.Count - 1 }
    $existingCell = $columns[$notesIdx]
    $hasPointer = $existingCell -match '\[details\]\(#'
    $isPlaceholder = [string]::IsNullOrWhiteSpace($existingCell) -or ($existingCell.Trim() -in @('-', '—', 'N/A'))
    if (-not $hasPointer -and -not $isPlaceholder) {
        $legacy = ($existingCell -replace '\s+', ' ').Trim()
        $detailEntries += "- **Pre-$currentDate — Legacy notes**: $legacy"
        Write-ProjectLog "Migrated $BugId's legacy Notes cell into its Bug Details block" -Level "WARN"
    }
    foreach ($noteField in $noteLabels.Keys) {
        if ($UpdateData.$noteField) {
            $label = $noteLabels[$noteField]
            $value = ($UpdateData.$noteField -replace '\s+', ' ').Trim()
            $detailEntries += "- **$currentDate — $label**: $value"
            $lastLabel = $label
            $lastValue = $value
        }
    }

    # Summary reflects the most recent thing that happened, so the table still reads as a
    # status board at a glance. With nothing supplied, the status transition itself is the news.
    $summary = if ($lastLabel) { "$lastLabel`: $lastValue" } else { "$displayName $currentDate" }
    $columns[$notesIdx] = Format-BugNotesCell -BugId $BugId -Summary $summary

    # Reconstruct the table row through the canonical helper (PF-IMP-2069) — the write half of
    # Split-MarkdownTableRow's round-trip contract, so a literal pipe inside caller-supplied
    # note prose is escaped instead of silently becoming an extra cell.
    $updatedEntry = ConvertTo-MarkdownTableRow -Cells $columns
    $result = $Content.Replace($currentEntry, $updatedEntry)

    if ($detailEntries.Count -gt 0) {
        $result = Add-BugDetailEntry -Content $result -BugId $BugId -Entries $detailEntries
        if ($null -eq $result) {
            Write-ProjectLog "Failed to append Bug Details entry for $BugId — nothing written" -Level "ERROR"
            return $null
        }
    }

    Write-ProjectLog "Successfully updated bug $BugId to status: $statusEmoji $displayName" -Level "SUCCESS"
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
        Write-ProjectLog "Could not find bug $BugId in archive (neither ## Closed Bugs nor ## Rejected Bugs)" -Level "ERROR"
        return $null
    }

    # Extract the Priority cell to determine the target live subsection.
    $columns = $bugLine -split '\|' | ForEach-Object { $_.Trim() }
    if ($columns[0] -eq '') { $columns = $columns[1..($columns.Length - 1)] }
    # Priority by header, not by index (PF-PRO-078) — resolved against the ARCHIVE's own header,
    # which can still be the pre-Origin schema while the live file has already migrated.
    $priorityMap = Get-BugColumnIndexMap -Content $ArchiveContent -RowCellCount $columns.Count
    $priorityIdx = if ($priorityMap.ContainsKey('Priority')) { $priorityMap['Priority'] } else { 3 }
    $priorityValue = "$($columns[$priorityIdx])".Trim()

    $targetSubsection = switch ($priorityValue) {
        "Critical" { "### Critical Bugs" }
        "High"     { "### High Priority Bugs" }
        "Medium"   { "### Medium Priority Bugs" }
        "Low"      { "### Low Priority Bugs" }
        default {
            Write-ProjectLog "Unknown priority '$priorityValue' for bug $BugId, defaulting to ### Medium Priority Bugs" -Level "WARN"
            "### Medium Priority Bugs"
        }
    }

    # Header-driven move (PF-PRO-078): each destination column takes the same-named source cell,
    # so neither side's schema is hardcoded here. This replaces an identity mapping over a frozen
    # 11-name list, which THREW whenever the two sides disagreed — exactly the state a project is
    # in between receiving the Origin column and running its migration. A column present on only
    # one side now degrades to an empty cell instead of blocking the transition; the bug's Origin
    # survives in its Bug Details block either way.

    # Use Move-MarkdownTableRow in reverse two-file mode (archive → live).
    # SectionEndPattern '^### ' ensures the destination scan stops at the next priority
    # subsection (not at next `##` which would skip past sibling priority sections).
    $result = Move-MarkdownTableRow `
        -Content $ArchiveContent `
        -DestinationContent $LiveContent `
        -RowIdPattern ([regex]::Escape($BugId)) `
        -SourceSection $sourceArchiveSection `
        -DestinationSection $targetSubsection `
        -HeaderDriven `
        -DefaultCell '' `
        -SectionEndPattern '^### '

    if (-not $result -or $null -eq $result.Content) {
        Write-ProjectLog "Move-MarkdownTableRow failed: archive($sourceArchiveSection) → live($targetSubsection) for $BugId" -Level "ERROR"
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

    # PF-IMP-2184: reopening returns the Bug Details block to the live tracker alongside its
    # row — the mirror of the archive direction, so a reopen/close cycle leaves no copy behind
    # on either side.
    $blockMove = Move-BugDetailBlock `
        -SourceContent $result.Content `
        -DestinationContent ($newLiveLines -join "`r`n") `
        -BugId $BugId
    if ($null -eq $blockMove) {
        Write-ProjectLog "Failed to move Bug Details block for $BugId — aborting before any write" -Level "ERROR"
        return $null
    }

    Write-ProjectLog "Moved bug $BugId from archive ($sourceArchiveSection) to live ($targetSubsection)" -Level "SUCCESS"
    return @{
        LiveContent    = $blockMove.DestinationContent
        ArchiveContent = $blockMove.SourceContent
    }
}

function Move-BugBetweenActiveSectionsContent {
    # PF-IMP-1136 (2026-06-12): consolidated onto the generic Move-MarkdownTableRow
    # (same-file mode), mirroring Move-BugFromArchiveContent. What stays here is the
    # genuinely per-file logic: locating the bug's current priority subsection, the
    # already-in-place early exit, and the decorative-placeholder upkeep on both
    # sides (the generic helper intentionally doesn't know about these markers).
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
        Write-ProjectLog "Unknown target priority '$TargetPriority'" -Level "ERROR"
        return $null
    }

    # Locate the bug's current priority subsection (active sections only — stop
    # before ## Closed Bugs).
    $escapedBugId = [regex]::Escape($BugId)
    $currentSectionHeader = $null
    $scanSection = $null
    foreach ($line in ($Content -split "\r?\n")) {
        if ($line -match '^## Closed Bugs') { break }
        if ($line -match '^### (Critical|High Priority|Medium Priority|Low Priority) Bugs\s*$') {
            $scanSection = "### $($Matches[1]) Bugs"
            continue
        }
        if ($scanSection -and $line -match "^\|\s*$escapedBugId\s*\|") {
            $currentSectionHeader = $scanSection
            break
        }
    }

    if (-not $currentSectionHeader) {
        Write-ProjectLog "Bug $BugId not found in active sections for inter-section move" -Level "ERROR"
        return $null
    }

    # If already in the correct section, no move needed
    if ($currentSectionHeader -eq $targetSectionHeader) {
        Write-ProjectLog "Bug $BugId already in correct section ($targetSectionHeader), no move needed"
        return $Content
    }

    Write-ProjectLog "Moving bug $BugId from '$currentSectionHeader' to '$targetSectionHeader'"

    # Header-driven move (PF-PRO-078): each destination column takes the same-named source cell,
    # so neither side's schema is hardcoded here. This replaces an identity mapping over a frozen
    # 11-name list, which THREW whenever the two sides disagreed — exactly the state a project is
    # in between receiving the Origin column and running its migration. A column present on only
    # one side now degrades to an empty cell instead of blocking the transition; the bug's Origin
    # survives in its Bug Details block either way.

    # Same-file move. SectionEndPattern '^### ' bounds both the source row search
    # and the destination insert scan at the next priority subsection.
    $result = Move-MarkdownTableRow `
        -Content $Content `
        -RowIdPattern $escapedBugId `
        -SourceSection $currentSectionHeader `
        -DestinationSection $targetSectionHeader `
        -HeaderDriven `
        -DefaultCell '' `
        -SectionEndPattern '^### '

    if (-not $result -or $null -eq $result.Content) {
        Write-ProjectLog "Move-MarkdownTableRow failed: $currentSectionHeader -> $targetSectionHeader for $BugId" -Level "ERROR"
        return $null
    }

    $newLines = [System.Collections.ArrayList]@($result.Content -split "\r?\n")

    # Target section: drop its "_No X bugs currently active_" placeholder if present.
    for ($i = 0; $i -lt $newLines.Count; $i++) {
        if ($newLines[$i].Trim() -eq $targetSectionHeader) {
            for ($j = $i + 1; $j -lt $newLines.Count -and -not ($newLines[$j] -match '^### |^## '); $j++) {
                if ($newLines[$j] -match '^\|\s*_No .+ bugs currently') {
                    $newLines.RemoveAt($j)
                    break
                }
            }
            break
        }
    }

    # Source section: if emptied by the move, restore its placeholder after the separator row.
    for ($i = 0; $i -lt $newLines.Count; $i++) {
        if ($newLines[$i].Trim() -eq $currentSectionHeader) {
            $hasDataRows = $false
            $separatorIdx = -1
            for ($j = $i + 1; $j -lt $newLines.Count -and -not ($newLines[$j] -match '^### |^## '); $j++) {
                if ($separatorIdx -eq -1 -and $newLines[$j] -match '^\| -') { $separatorIdx = $j }
                if ($newLines[$j] -match '^\|\s*PD-BUG-') { $hasDataRows = $true; break }
            }
            if (-not $hasDataRows -and $separatorIdx -ge 0) {
                $priorityLabel = if ($currentSectionHeader -match 'Critical') { 'critical' }
                                 elseif ($currentSectionHeader -match 'High') { 'high priority' }
                                 elseif ($currentSectionHeader -match 'Medium') { 'medium priority' }
                                 else { 'low priority' }
                $newLines.Insert($separatorIdx + 1, "| _No $priorityLabel bugs currently active_ |")
            }
            break
        }
    }

    Write-ProjectLog "Moved bug $BugId to $targetSectionHeader" -Level "SUCCESS"
    return ($newLines -join "`r`n")
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
        Write-ProjectLog "Could not find bug $BugId in any live priority subsection" -Level "ERROR"
        return $null
    }

    # Destination section depends on disposition (dual-section archive per PF-IMP-872).
    $destinationSection = if ($Disposition -eq "Closed") { "## Closed Bugs" } else { "## Rejected Bugs" }

    # Header-driven move (PF-PRO-078): each destination column takes the same-named source cell,
    # so neither side's schema is hardcoded here. This replaces an identity mapping over a frozen
    # 11-name list, which THREW whenever the two sides disagreed — exactly the state a project is
    # in between receiving the Origin column and running its migration. A column present on only
    # one side now degrades to an empty cell instead of blocking the transition; the bug's Origin
    # survives in its Bug Details block either way.

    # Two-file Move-MarkdownTableRow: live → archive.
    # SectionEndPattern '^### ' bounds the source-row search to just the matched
    # priority subsection (without it, the search would skim through all 4 subsections).
    $result = Move-MarkdownTableRow `
        -Content $LiveContent `
        -DestinationContent $ArchiveContent `
        -RowIdPattern ([regex]::Escape($BugId)) `
        -SourceSection $sourceSubsection `
        -DestinationSection $destinationSection `
        -HeaderDriven `
        -DefaultCell '' `
        -SectionEndPattern '^### '

    if (-not $result -or $null -eq $result.Content) {
        Write-ProjectLog "Move-MarkdownTableRow failed: live($sourceSubsection) → archive($destinationSection) for $BugId" -Level "ERROR"
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

    # PF-IMP-2184: the bug's Bug Details block travels with its row — removed from live,
    # appended to the archive. Remove-and-append, never append-only: an append-only move
    # would strand the block in the live tracker, re-creating unbounded accretion there.
    $blockMove = Move-BugDetailBlock `
        -SourceContent ($newLiveLines -join "`r`n") `
        -DestinationContent $result.DestinationContent `
        -BugId $BugId
    if ($null -eq $blockMove) {
        Write-ProjectLog "Failed to move Bug Details block for $BugId — aborting before any write" -Level "ERROR"
        return $null
    }

    Write-ProjectLog "Moved bug $BugId from live ($sourceSubsection) to archive ($destinationSection)" -Level "SUCCESS"
    return @{
        LiveContent    = $blockMove.SourceContent
        ArchiveContent = $blockMove.DestinationContent
    }
}

# Defect chains, derived (PF-PRO-078) — never hand-maintained, so the line cannot go stale the way
# the retired All-Triaged line did (PF-IMP-2137). Reads the Origin cells of the ACTIVE rows only:
# the statistics block is computed from the live file, and the archive is not loaded on a filing.
# A chain is therefore reported as its root plus its active descendants; the full depth (closed
# members included) is what Bug Triage walks when it takes the chain decision.
#
# NOTE — deliberate duplication with New-BugReport.ps1, same reason as Get-BugAnchor above:
# the shared home is Common-ScriptHelpers, FWK-FB substrate this workspace may not edit. Both
# copies are pinned identical by a cross-script drift guard in New-BugReport.Tests.ps1.
function Format-OpenChainsValue {
    param([string]$ActiveSection)

    $lines = $ActiveSection -split "\r?\n"

    # Locate ID and Origin by header, never by index: the column position differs between a
    # migrated tracker and one still on the 11-column schema.
    $idIdx = -1
    $originIdx = -1
    foreach ($line in $lines) {
        if ($line -notmatch '(?i)^\|\s*ID\s*\|') { continue }
        $hdr = @(Split-MarkdownTableRow -Line $line.Trim())
        for ($i = 0; $i -lt $hdr.Count; $i++) {
            switch ($hdr[$i].Trim()) {
                'ID'     { $idIdx = $i }
                'Origin' { $originIdx = $i }
            }
        }
        if ($originIdx -ge 0) { break }
    }
    if ($idIdx -lt 0 -or $originIdx -lt 0) { return 'none' }   # tracker predates the column

    $origins = [ordered]@{}
    foreach ($line in $lines) {
        if ($line -notmatch '^\|\s*(PD-BUG-\d+|BUG-\d+)\s*\|') { continue }
        $cells = @(Split-MarkdownTableRow -Line $line.Trim())
        if ($cells.Count -le $originIdx -or $cells.Count -le $idIdx) { continue }
        # A decorative placeholder is not an origin. A column migration fills empty cells with
        # whatever default it was given, and a table-row builder uses an em dash by default, so
        # a run of placeholders would otherwise read as one chain rooted at the placeholder
        # itself (measured while mutation-verifying this function, 2026-09-04).
        $originCell = "$($cells[$originIdx])".Trim()
        if ($originCell -in @('-', [char]0x2014, [char]0x2013, 'N/A', 'n/a')) { $originCell = '' }
        $origins[$cells[$idIdx].Trim()] = $originCell
    }

    $chains = [ordered]@{}
    foreach ($id in @($origins.Keys)) {
        if ([string]::IsNullOrWhiteSpace($origins[$id])) { continue }
        # Walk to the chain root. The walk stops at a bug that is not itself an active row (its
        # origin is unknown here — it is closed or archived), and a $seen guard keeps a corrupt
        # cycle from spinning forever rather than trusting the data to be acyclic.
        $root = $origins[$id]
        $seen = @{ $id = $true }
        while ($origins.Contains($root) -and -not [string]::IsNullOrWhiteSpace($origins[$root]) -and -not $seen.ContainsKey($root)) {
            $seen[$root] = $true
            $root = $origins[$root]
        }
        if (-not $chains.Contains($root)) { $chains[$root] = [System.Collections.ArrayList]::new() }
        [void]$chains[$root].Add($id)
    }
    if ($chains.Count -eq 0) { return 'none' }

    $parts = @()
    foreach ($root in @($chains.Keys)) {
        # The root joins its own member list when it is itself an active row, so the count and
        # the list always agree; a root that is closed or archived is named but not listed.
        $members = @($chains[$root])
        if ($origins.Contains($root)) { $members += $root }
        $members = @($members | Sort-Object { [int]($_ -replace '\D', '') })
        $parts += "$root chain - $($members.Count) active ($($members -join ', '))"
    }
    return ($parts -join '; ')
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
        elseif ($line -match "^### ") { $currentPriority = "" }

        if ($currentPriority -and $line -match "^\|\s*(PD-BUG-\d+)\s*\|") {
            $bugIds[$currentPriority].Add($Matches[1]) | Out-Null
        }
    }

    $totalActive = $bugIds.Critical.Count + $bugIds.High.Count + $bugIds.Medium.Count + $bugIds.Low.Count

    # Build the value side only — the label is carried through from the file by the capture
    # group below, so both live label forms ("- **Critical**:" and the shipped
    # "- **Critical (P1)**:") are written without either being rewritten into the other.
    function Format-StatTail {
        param([System.Collections.ArrayList]$Ids)
        if ($Ids.Count -eq 0) { return "0" }
        return "$($Ids.Count) ($($Ids -join ', '))"
    }

    $prioritySuffix = @{ Critical = "P1"; High = "P2"; Medium = "P3"; Low = "P4" }

    $result = $Content
    $result = [regex]::Replace($result, '(?m)^(- \*\*Total Active Bugs\*\*:)[^\r\n]*', "`${1} $totalActive")

    $unmatched = @()
    foreach ($priority in @("Critical", "High", "Medium", "Low")) {
        $pattern = "(?m)^(- \*\*$priority(?: \($($prioritySuffix[$priority])\))?\*\*:)[^\r\n]*"
        if ([regex]::IsMatch($result, $pattern)) {
            $result = [regex]::Replace($result, $pattern, "`${1} $(Format-StatTail $bugIds[$priority])")
        }
        elseif ([regex]::IsMatch($result, "(?m)^- \*\*$priority")) {
            # A bullet for this priority exists in a label form no pattern recognizes. Writing
            # would be a silent no-op reported as SUCCESS — the mechanism that hid this defect
            # for the life of the repo. Fail loudly instead (PF-IMP-2324).
            $unmatched += $priority
        }
    }

    if ($unmatched.Count -gt 0) {
        Write-ProjectError -Message "Bug statistics not written: the $($unmatched -join ', ') bullet(s) are present but in an unrecognized label form. Expected '- **<Priority>**:' or '- **<Priority> (P#)**:'." -ExitCode 1
    }

    # Open chains (PF-PRO-078), derived on every write. Only where the bullet exists: a tracker
    # that predates the line is not retrofitted here — that is the Origin column migration's job.
    $openChainsPattern = '(?m)^(- \*\*Open chains\*\*:)[^\r\n]*'
    if ([regex]::IsMatch($result, $openChainsPattern)) {
        $activeEnd = $result.IndexOf("## Closed Bugs")
        if ($activeEnd -lt 0) { $activeEnd = $result.IndexOf("## Bug Statistics") }
        $activeForChains = if ($activeEnd -gt 0) { $result.Substring(0, $activeEnd) } else { $result }
        $result = [regex]::Replace($result, $openChainsPattern, "`${1} $(Format-OpenChainsValue -ActiveSection $activeForChains)")
    }

    Write-ProjectLog "Updated bug statistics: $totalActive active ($($bugIds.Critical.Count) Critical, $($bugIds.High.Count) High, $($bugIds.Medium.Count) Medium, $($bugIds.Low.Count) Low)" -Level "SUCCESS"
    return $result
}

function Main {
    # Normalize short-form IDs: BUG-001 → PD-BUG-001
    if ($BugId -match '^BUG-\d+$') {
        $script:BugId = "PD-$BugId"
    }

    Write-ProjectLog "Starting Bug Status Update - $ScriptName"
    Write-ProjectLog "Bug ID: $BugId"

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    # --- FastClose: chain NeedsFix → InProgress → Closed in one call ---
    if ($FastClose) {
        Write-ProjectLog "Mode: FastClose (S-scope quick path)" -Level "INFO"

        # Validate required parameters for FastClose
        if (-not $Priority) {
            Write-ProjectLog "Priority is required for -FastClose" -Level "ERROR"; exit 1
        }
        if (-not $FixDetails) {
            Write-ProjectLog "FixDetails is required for -FastClose" -Level "ERROR"; exit 1
        }
        if (-not $VerificationNotes) {
            Write-ProjectLog "VerificationNotes is required for -FastClose" -Level "ERROR"; exit 1
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
        if ($OriginBug) { $triageData.OriginBug = $OriginBug }
        $content = Update-BugEntryContent -Content $content -BugId $BugId -NewStatus "NeedsFix" -UpdateData $triageData
        if ($null -eq $content) { Write-ProjectLog "FastClose failed at NeedsFix" -Level "ERROR"; exit 1 }
        Write-ProjectLog "FastClose phase 1/3: 🔍 Needs Fix" -Level "SUCCESS"

        # Move to correct priority section (non-fatal if already in correct section)
        $movedContent = Move-BugBetweenActiveSectionsContent -Content $content -BugId $BugId -TargetPriority $Priority
        if ($null -ne $movedContent) { $content = $movedContent }
        else { Write-ProjectLog "Bug already in correct priority section or move skipped" -Level "INFO" }

        # Phase 2: InProgress
        $content = Update-BugEntryContent -Content $content -BugId $BugId -NewStatus "InProgress" -UpdateData @{}
        if ($null -eq $content) { Write-ProjectLog "FastClose failed at InProgress" -Level "ERROR"; exit 1 }
        Write-ProjectLog "FastClose phase 2/3: 🟡 In Progress" -Level "SUCCESS"

        # Phase 3: Closed (with fix details and verification)
        $closeData = @{}
        if ($FixDetails) { $closeData.FixDetails = $FixDetails }
        if ($RootCause) { $closeData.RootCause = $RootCause }
        if ($TestsAdded) { $closeData.TestsAdded = $TestsAdded }
        if ($PullRequestUrl) { $closeData.PullRequestUrl = $PullRequestUrl }
        if ($VerificationNotes) { $closeData.VerificationNotes = $VerificationNotes }
        $content = Update-BugEntryContent -Content $content -BugId $BugId -NewStatus "Closed" -UpdateData $closeData
        if ($null -eq $content) { Write-ProjectLog "FastClose failed at Closed" -Level "ERROR"; exit 1 }
        Write-ProjectLog "FastClose phase 3/3: 🔒 Closed" -Level "SUCCESS"

        # Move to archive ## Closed Bugs section (PF-IMP-872) and recalculate stats
        $moveResult = Move-BugToArchiveContent -LiveContent $content -ArchiveContent $archiveContent -BugId $BugId -Disposition "Closed"
        if ($null -eq $moveResult) { Write-ProjectLog "Failed to move bug to archive ## Closed Bugs" -Level "ERROR"; exit 1 }
        $content = $moveResult.LiveContent
        $archiveContent = $moveResult.ArchiveContent
        $content = Update-BugStatisticsContent -Content $content

        try {
            if ($PSCmdlet.ShouldProcess($BugTrackingFile, "FastClose $BugId (NeedsFix → InProgress → Closed)")) {
                Set-Content -Path $BugTrackingFile -Value $content -NoNewline
                Set-Content -Path $ArchiveFile -Value $archiveContent -NoNewline
                Write-ProjectSummary "$BugId → Closed (FastClose: NeedsFix → InProgress → Closed)"

                # Read-after-write verification: confirm the bug row exists in archive (it moved there)
                if (-not $WhatIfPreference) {
                    $rowPattern = "\|\s*" + [regex]::Escape($BugId) + "\s*\|"
                    # Assert-TableRowInFile, not Assert-LineInFile (PF-IMP-2069): a presence-only
                    # assert passed a row whose cell count had drifted from its header, which is
                    # how the stray-cell defect stayed silent while every run reported SUCCESS.
                    Assert-TableRowInFile -Path $ArchiveFile -Pattern $rowPattern -Context "bug row for $BugId in $ArchiveFile (archive)"
                }

                if ($soakInSoak) {
                    Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
                }
            } else {
                Write-ProjectLog "Dry-run complete — no file changes written" -Level "INFO"
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
    Write-ProjectLog "New Status: $NewStatus"

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
    if ($OriginBug) { $updateData.OriginBug = $OriginBug }

    # Validate required parameters for specific status transitions
    switch ($NewStatus) {
        "NeedsFix" {
            if (-not $Priority) {
                Write-ProjectLog "Priority is required when transitioning to NeedsFix status" -Level "ERROR"
                exit 1
            }
        }
        "InProgress" {
            # No additional validation needed
        }
        "NeedsReview" {
            if (-not $FixDetails) {
                Write-ProjectLog "FixDetails is required when transitioning to NeedsReview status" -Level "ERROR"
                exit 1
            }
        }
        "Closed" {
            if (-not $VerificationNotes) {
                Write-ProjectLog "VerificationNotes is required when transitioning to Closed status" -Level "ERROR"
                exit 1
            }
        }
        "Reopened" {
            if (-not $ReopenReason) {
                Write-ProjectLog "ReopenReason is required when transitioning to Reopened status" -Level "ERROR"
                exit 1
            }
        }
        "Rejected" {
            if (-not $RejectionReason) {
                Write-ProjectLog "RejectionReason is required when transitioning to Rejected status" -Level "ERROR"
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
            Write-ProjectLog "Failed to move bug $BugId from archive to active section" -Level "ERROR"
            exit 1
        }
        $content = $moveResult.LiveContent
        $archiveContent = $moveResult.ArchiveContent
    }

    # Step 1: Update the bug entry (status, notes) in live content
    $content = Update-BugEntryContent -Content $content -BugId $BugId -NewStatus $NewStatus -UpdateData $updateData
    if ($null -eq $content) {
        Write-ProjectLog "Bug status update failed" -Level "ERROR"
        exit 1
    }

    # Step 1b: When priority changes within active sections (e.g., triage), move to correct section
    if ($Priority -and $NewStatus -notin @("Closed", "Rejected", "Reopened")) {
        $content = Move-BugBetweenActiveSectionsContent -Content $content -BugId $BugId -TargetPriority $Priority
        if ($null -eq $content) {
            Write-ProjectLog "Failed to move bug $BugId to $Priority section" -Level "ERROR"
            exit 1
        }
    }

    # Step 2 (Closed / Rejected only): move the now-updated row live → archive.
    # Dual-section routing per PF-IMP-872: Closed → ## Closed Bugs, Rejected → ## Rejected Bugs.
    if ($NewStatus -eq "Closed" -or $NewStatus -eq "Rejected") {
        $moveResult = Move-BugToArchiveContent -LiveContent $content -ArchiveContent $archiveContent -BugId $BugId -Disposition $NewStatus
        if ($null -eq $moveResult) {
            Write-ProjectLog "Failed to move bug $BugId to archive ## $NewStatus Bugs section" -Level "ERROR"
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
            Write-ProjectSummary "$BugId → $NewStatus"

            # Read-after-write verification: confirm the bug row exists where it should be after the move
            if (-not $WhatIfPreference) {
                $rowPattern = "\|\s*" + [regex]::Escape($BugId) + "\s*\|"
                $verifyFile = if ($NewStatus -in @("Closed", "Rejected")) { $ArchiveFile } else { $BugTrackingFile }
                # Header-aware post-condition (PF-IMP-2069) — see the FastClose site above.
                Assert-TableRowInFile -Path $verifyFile -Pattern $rowPattern -Context "bug row for $BugId in $verifyFile"
            }

            if ($soakInSoak) {
                Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
            }
        } else {
            Write-ProjectLog "Dry-run complete — no file changes written" -Level "INFO"
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
