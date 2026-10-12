#!/usr/bin/env pwsh

<#
.SYNOPSIS
Updates a technical exploration in the Technical Exploration Tracking state file — a lifecycle transition, or a notes-only annotation of an open exploration.

.DESCRIPTION
This script automates exploration lifecycle transitions in technical-exploration-tracking.md.

Used by the Technical Exploration task (PF-TSK-093) to start a spike, link its findings
document, and resolve (or abandon) the row.

Supports four operation modes:
1. InProgress: Sets Status to 🔬 In Progress in place — the row stays in the Active table
   while research runs (the findings document carries the running log across sessions)
2. Resolved: Sets the Findings Doc link, moves the row from Active to the collapsed
   "Resolved Explorations" section with Outcome = ✅ Resolved, recounts, adds an Update
   History entry, updates the frontmatter date
3. Abandoned: Same terminal move, with Outcome = ❌ Abandoned — keeps terminal rows out of the
   active queue (sibling precedent: Update-FeatureRequest.ps1's Rejected path, PF-IMP-1220)
4. Notes-only annotation (-AppendNotes): Appends to the Notes column of an exploration still in
   the Active table, leaving Status untouched. Appends (never overwrites) and is idempotent —
   re-running with the same text is a no-op. Mirrors Update-FeatureRequest.ps1 -AppendNotes.

Status values are supplied as plain words and rendered to the tracker's emoji legend values —
the framework convention (Update-FeatureRequest.ps1, Update-TechDebt.ps1), which keeps emoji off
the command line where shell encoding can mangle them.

Every row is written by column name through the shared table helpers: a literal pipe in cell text
is escaped, a line break is refused, and a column the table lacks fails the run before anything
is written.

.PARAMETER ExplorationId
The exploration ID to update (e.g., "PD-EXP-001")

.PARAMETER NewStatus
The new status. Valid values: InProgress, Resolved, Abandoned
(rendered as 🔬 In Progress / ✅ Resolved / ❌ Abandoned in the tracker)

.PARAMETER FindingsDoc
The findings document reference for the Findings Doc column — a PD-TEC ID (e.g. "PD-TEC-003") or
a full markdown link. Required when resolving: a resolved exploration without its findings
document is a dead end for the downstream task that reads it.

.PARAMETER Notes
Additional notes to append to the Notes column. Leading and trailing whitespace is trimmed (as for
-FindingsDoc and -AppendNotes), so a value read with (Get-Content <file> -Raw) keeps no trailing
newline.

.PARAMETER AppendNotes
Text to append to the Notes column of an exploration still in the Active table, with no status
change (NotesEdit mode — mutually exclusive with -NewStatus). Idempotent.

.PARAMETER UpdatedBy
Who performed the update (default: "AI Agent (PF-TSK-093)")

.PARAMETER TrackingFile
Override for the tracking file path (sandbox test entry point). Defaults to the project's
doc/state-tracking/permanent/technical-exploration-tracking.md via Resolve-DocPath.

.EXAMPLE
# Start research on a queued exploration
Update-Exploration.ps1 -ExplorationId "PD-EXP-001" -NewStatus "InProgress"

.EXAMPLE
# Resolve an exploration, linking its findings document
Update-Exploration.ps1 -ExplorationId "PD-EXP-001" -NewStatus "Resolved" -FindingsDoc "PD-TEC-003" -Notes "Recommendation: adopt Option B"

.EXAMPLE
# Abandon an exploration that is no longer needed
Update-Exploration.ps1 -ExplorationId "PD-EXP-002" -NewStatus "Abandoned" -Notes "Feature dropped from scope"

.EXAMPLE
# Annotate a still-open exploration mid-research (no status change)
Update-Exploration.ps1 -ExplorationId "PD-EXP-001" -AppendNotes "Vendor confirmed the API supports split capture"

.NOTES
This script integrates with:
- Technical Exploration (PF-TSK-093) — primary consumer
- New-Exploration.ps1 — files the rows this script advances
- New-TechnicalDoc.ps1 — produces the PD-TEC findings document linked here

Clearing a blocked feature's 🔬 Needs Technical Exploration status in feature-tracking.md is
NOT this script's job — the task does that via Update-BatchFeatureStatus.ps1, since only the
agent knows which pipeline status the feature returns to.

Output behavior: Default output is one summary line per invocation. WARN and ERROR messages
always pass through. Pass -Verbose for the full play-by-play log.
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Lifecycle')]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^PD-EXP-\d+$')]
    [string]$ExplorationId,

    [Parameter(Mandatory = $true, ParameterSetName = 'Lifecycle')]
    [ValidateSet("InProgress", "Resolved", "Abandoned")]
    [string]$NewStatus,

    [Parameter(Mandatory = $false, ParameterSetName = 'Lifecycle')]
    [string]$FindingsDoc = "",

    [Parameter(Mandatory = $false, ParameterSetName = 'Lifecycle')]
    [string]$Notes = "",

    # --- NotesEdit parameter set ---
    [Parameter(Mandatory = $true, ParameterSetName = 'NotesEdit')]
    [ValidateNotNullOrEmpty()]
    [string]$AppendNotes,

    [Parameter(Mandatory = $false)]
    [string]$UpdatedBy = "AI Agent (PF-TSK-093)",

    [Parameter(Mandatory = $false)]
    [string]$TrackingFile = ""
)

# Import the common helpers
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

# Soak verification (PF-PRO-028 v2.0 Pattern A; caller-aware no-arg form)
Register-SoakScript
$soakInSoak = Test-ScriptInSoak

# Configuration
# project_id-aware path routing via Resolve-DocPath (PF-IMP-871): a hardcoded `doc/...` breaks in
# appdev (PRJ-000), where doc template material lives at blueprint/doc/...
if (-not $TrackingFile) {
    $TrackingFile = Resolve-DocPath -Subpath "state-tracking/permanent/technical-exploration-tracking.md"
}
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

# Map CLI parameter values to the tracker's emoji legend values
$StatusDisplayMap = @{
    "InProgress" = "🔬 In Progress"
    "Resolved"   = "✅ Resolved"
    "Abandoned"  = "❌ Abandoned"
}

$ActiveSection   = "## Active Explorations"
$ResolvedSection = "## Resolved Explorations"

# A value read with (Get-Content <file> -Raw), the Script Development Quick Reference's recipe for
# quote-heavy prose, keeps the file's trailing newline, which splits the table row it lands in
# (PF-IMP-2350). Cells are trimmed on read, so trimming here loses nothing.
$Notes = $Notes.Trim()
$FindingsDoc = $FindingsDoc.Trim()
if ($AppendNotes) { $AppendNotes = $AppendNotes.Trim() }

function Test-Prerequisites {
    Write-ProjectLog "Checking prerequisites..."

    if (-not (Test-Path $TrackingFile)) {
        Write-ProjectLog "Technical exploration tracking file not found: $TrackingFile" -Level "ERROR"
        return $false
    }

    # A resolved exploration whose findings doc is unlinked strands the downstream task that
    # reads it — the whole point of the row is to hand off the research.
    if ($NewStatus -eq "Resolved" -and -not $FindingsDoc) {
        Write-ProjectLog "FindingsDoc is required when resolving an exploration (the downstream task reads it). Create it with New-TechnicalDoc.ps1 first." -Level "ERROR"
        return $false
    }

    Write-ProjectLog "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

# --- Content-transformation functions ---

function Join-ExplorationNote {
    # Append $New to an existing Notes-column value with a normalized separator, so a prior value
    # already ending in '.' does not produce a '..' double period (PF-IMP-1046). Empty or
    # placeholder ('—') existing values are replaced outright (no leading separator).
    param([string]$Existing, [string]$New)
    if ($Existing -and $Existing -ne "—") {
        return "$($Existing.TrimEnd('.', ' ')). $New"
    }
    return $New
}

function Get-StoredCellText {
    # The form a value takes once written into a cell: ConvertTo-MarkdownTableRow escapes a literal
    # pipe as '\|'. Comparisons against a stored cell must use this form, not the raw input.
    param([string]$Text)
    return $Text -replace '(?<!\\)\|', '\|'
}

function Get-ActiveExplorationRow {
    # Locates an exploration in the Active table: its raw line, 1-based line number and the table's
    # header — everything Set-ActiveExplorationCells needs. $null (logged) when it is not there.
    param([string]$Content, [string]$ExplorationId)

    $row = ConvertFrom-MarkdownTable -Content $Content -Section $ActiveSection -IncludeRawLine -IncludeLineNumber |
        Where-Object { $_.ID -eq $ExplorationId } | Select-Object -First 1

    if (-not $row) {
        Write-ProjectLog "Exploration not found in the Active table: $ExplorationId" -Level "ERROR"
        return $null
    }
    return [pscustomobject]@{
        Line       = $row._RawLine
        LineNumber = $row._LineNumber
        Headers    = @(Get-MarkdownTableHeaders -Content $Content -SectionHeading $ActiveSection)
    }
}

function Set-ActiveExplorationCells {
    # Rewrites cells of one Active row by column NAME (PF-IMP-2350). Set-MarkdownTableCell escapes
    # pipes, refuses a line break, and throws on a column the header lacks — before anything is
    # written, so a value the table cannot hold is never silently dropped; Set-MarkdownTableRow
    # replaces only that line. $AppendNote is joined onto the existing Notes cell.
    param(
        [string]$Content,
        [object]$Row,
        [hashtable]$Updates = @{},
        [string]$AppendNote = ""
    )

    $cells = $Updates.Clone()
    if ($AppendNote) {
        $existing = Get-MarkdownTableCell -Line $Row.Line -Headers $Row.Headers -Header 'Notes'
        $cells['Notes'] = Join-ExplorationNote -Existing $existing -New $AppendNote
    }

    $newLine = Set-MarkdownTableCell -Line $Row.Line -Headers $Row.Headers -Updates $cells
    return Set-MarkdownTableRow -Content $Content -LineNumber $Row.LineNumber -NewRow $newLine -ExpectedRow $Row.Line
}

function Add-ExplorationNote {
    # NotesEdit mode: appends to the Notes column of an exploration still in the Active table.
    # Returns @{ Content; Changed } — Changed is $false when the text is already present
    # (idempotent no-op), $null on failure.
    param([string]$Content, [string]$ExplorationId, [string]$Note)

    $row = Get-ActiveExplorationRow -Content $Content -ExplorationId $ExplorationId
    if (-not $row) {
        Write-ProjectLog "Notes can only be appended to an open (Active) exploration" -Level "ERROR"
        return $null
    }

    $existing = Get-MarkdownTableCell -Line $row.Line -Headers $row.Headers -Header 'Notes'
    if ($null -eq $existing) {
        Write-ProjectLog "Active Explorations table has no 'Notes' column" -Level "ERROR"
        return $null
    }

    # A literal substring test against the stored form: -like would read a markdown link's
    # brackets as a wildcard character class and throw, or miss the match (PF-IMP-2350).
    if ($existing.Contains((Get-StoredCellText $Note))) {
        Write-ProjectLog "Notes for $ExplorationId already contain this text — nothing to append" -Level "WARN"
        return [pscustomobject]@{ Content = $Content; Changed = $false }
    }

    $result = Set-ActiveExplorationCells -Content $Content -Row $row -Updates @{ 'Last Updated' = $CurrentDate } -AppendNote $Note

    Write-ProjectLog "Appended notes to $ExplorationId" -Level "SUCCESS"
    return [pscustomobject]@{ Content = $result; Changed = $true }
}

function Move-ToResolvedSection {
    param([string]$Content, [string]$ExplorationId, [string]$Outcome)

    # Source table: | ID | Source | Description | Related Feature | Priority | Status | Findings Doc | Last Updated | Notes |
    # Dest table:   | ID | Source | Description | Related Feature | Outcome | Findings Doc | Resolved Date | Notes |
    # Priority/Status/Last Updated are dropped on the move; Outcome carries the terminal
    # disposition (the dest table has no Status column) and Resolved Date the closure date.
    $columnMapping = [ordered]@{
        "ID"              = "ID"
        "Source"          = "Source"
        "Description"     = "Description"
        "Related Feature" = "Related Feature"
        "Outcome"         = "Outcome"
        "Findings Doc"    = "Findings Doc"
        "Resolved Date"   = "Resolved Date"
        "Notes"           = "Notes"
    }
    $additionalColumns = [ordered]@{
        "Outcome"       = $Outcome
        "Resolved Date" = $CurrentDate
    }

    $result = Move-MarkdownTableRow `
        -Content $Content `
        -RowIdPattern ([regex]::Escape($ExplorationId)) `
        -SourceSection $ActiveSection `
        -DestinationSection $ResolvedSection `
        -ColumnMapping $columnMapping `
        -AdditionalColumns $additionalColumns

    if ($null -eq $result.Content) {
        Write-ProjectLog "Failed to move $ExplorationId to the Resolved section" -Level "ERROR"
        return $null
    }

    Write-ProjectLog "Moved $ExplorationId to Resolved Explorations as $Outcome" -Level "SUCCESS"
    return $result.Content
}

function Update-SummaryCount {
    param([string]$Content)

    $count = 0
    $inResolvedSection = $false
    foreach ($line in ($Content -split "\r?\n")) {
        if ($line -match "^## Resolved Explorations") { $inResolvedSection = $true }
        if ($inResolvedSection -and $line -match "^\s*</details>") { break }
        if ($inResolvedSection -and $line -match "^\|\s*PD-EXP-\d+") { $count++ }
    }

    $result = $Content -replace '(?<=Show resolved explorations \()\d+(?= items?\))', $count.ToString()

    Write-ProjectLog "Updated resolved summary count to $count items" -Level "SUCCESS"
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

    Write-ProjectLog "Updated history summary count to $count entries" -Level "SUCCESS"
    return $result
}

function Add-UpdateHistoryEntry {
    param([string]$Content, [string]$HistoryNote, [string]$UpdatedBy)

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
        Write-ProjectLog "Could not find Update History table" -Level "ERROR"
        return $null
    }

    # Built from the table's own header, so a pipe in the note is escaped rather than splitting
    # the row into extra cells (PF-IMP-2350).
    $historyRow = New-HeaderDrivenTableRow -Content $Content -SectionHeading "## Update History" -ValueMap @{
        'Date' = $CurrentDate; 'Action' = $HistoryNote; 'Updated By' = $UpdatedBy
    }
    $lines.Insert($insertAfterIndex + 1, $historyRow)

    Write-ProjectLog "Added Update History entry" -Level "SUCCESS"
    return ($lines -join "`r`n")
}

# --- Main ---

function Main {
    $isNotesEdit = $PSCmdlet.ParameterSetName -eq 'NotesEdit'

    Write-ProjectLog "Starting Technical Exploration Update"
    Write-ProjectLog "Exploration ID: $ExplorationId"
    if ($isNotesEdit) { Write-ProjectLog "Mode: notes-only append (no status change)" }
    else { Write-ProjectLog "New Status: $NewStatus" }

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    $intent = if ($isNotesEdit) { "Append notes to $ExplorationId" } else { "Update $ExplorationId to $NewStatus" }
    if (-not $PSCmdlet.ShouldProcess($TrackingFile, $intent)) {
        return
    }

    # Single read-modify-write cycle
    $content = Get-Content $TrackingFile -Raw

    if ($isNotesEdit) {
        $edit = Add-ExplorationNote -Content $content -ExplorationId $ExplorationId -Note $AppendNotes
        if ($null -eq $edit) { exit 1 }

        if (-not $edit.Changed) {
            Write-ProjectSummary "$ExplorationId → notes unchanged (text already present)"
            return
        }

        $content = $edit.Content
        $content = Add-UpdateHistoryEntry -Content $content -HistoryNote "Annotated $ExplorationId`: $AppendNotes" -UpdatedBy $UpdatedBy
        if ($null -eq $content) { exit 1 }
        $content = Update-HistorySummaryCount -Content $content
        $content = Update-FrontmatterDate -Content $content

        Set-Content -Path $TrackingFile -Value $content -NoNewline

        # Read-after-write verification (PF-PRO-077 / PF-IMP-2126). This is the notes-only run's
        # ONLY write — the row edit, the Update History entry, the history recount and the
        # frontmatter date all land in this one Set-Content. Assert-TableRowInFile, not
        # Assert-LineInFile: it re-reads the row against its header — a backstop behind
        # Set-MarkdownTableCell's pre-write shape check. The note is APPENDED to whatever the Notes
        # cell already held, so it is matched as a suffix of its cell, in its stored escaped form.
        if (-not $WhatIfPreference) {
            $notesRowPattern = "^\|\s*" + [regex]::Escape($ExplorationId) + "\s*\|.*" + [regex]::Escape((Get-StoredCellText $AppendNotes)) + "\s*\|"
            Assert-TableRowInFile -Path $TrackingFile -Pattern $notesRowPattern -Context "$ExplorationId notes appended in $TrackingFile"
        }

        Write-ProjectLog "Technical exploration tracking file updated successfully" -Level "SUCCESS"
        Write-ProjectSummary "$ExplorationId → notes appended"
        return
    }

    $DisplayStatus = $StatusDisplayMap[$NewStatus]
    $isTerminal = $NewStatus -in @("Resolved", "Abandoned")

    if ($NewStatus -eq "InProgress") {
        # Research is running — the row stays in the Active table; update in place.
        $row = Get-ActiveExplorationRow -Content $content -ExplorationId $ExplorationId
        if (-not $row) { exit 1 }

        $updates = @{ 'Status' = $DisplayStatus; 'Last Updated' = $CurrentDate }
        if ($FindingsDoc) { $updates['Findings Doc'] = $FindingsDoc }
        $content = Set-ActiveExplorationCells -Content $content -Row $row -Updates $updates -AppendNote $Notes
        Write-ProjectLog "Updated $ExplorationId status to $DisplayStatus" -Level "SUCCESS"
    }
    elseif ($isTerminal) {
        # Terminal rows leave the active queue for the collapsed archive (PF-IMP-1220 pattern).
        # Set Findings Doc / Notes on the row FIRST so the move carries the final values.
        $row = Get-ActiveExplorationRow -Content $content -ExplorationId $ExplorationId
        if (-not $row) { exit 1 }

        $updates = @{}
        if ($FindingsDoc) { $updates['Findings Doc'] = $FindingsDoc }
        $content = Set-ActiveExplorationCells -Content $content -Row $row -Updates $updates -AppendNote $Notes

        $content = Move-ToResolvedSection -Content $content -ExplorationId $ExplorationId -Outcome $DisplayStatus
        if ($null -eq $content) { exit 1 }

        $content = Update-SummaryCount -Content $content
    }

    # Update History entry
    $historyNote = switch ($NewStatus) {
        "InProgress" { "Started research on $ExplorationId" }
        "Resolved"   { "Resolved $ExplorationId — findings: $FindingsDoc" }
        "Abandoned"  { if ($Notes) { "Abandoned ${ExplorationId}: $Notes" } else { "Abandoned $ExplorationId" } }
    }

    $content = Add-UpdateHistoryEntry -Content $content -HistoryNote $historyNote -UpdatedBy $UpdatedBy
    if ($null -eq $content) { exit 1 }

    $content = Update-HistorySummaryCount -Content $content
    $content = Update-FrontmatterDate -Content $content

    # Single write
    Set-Content -Path $TrackingFile -Value $content -NoNewline

    # Read-after-write verification (PF-PRO-077 / PF-IMP-2126), placed after the run's LAST (and
    # only) write — the row rewrite, the terminal move, the archive recount, the Update History
    # entry and the frontmatter date all land in this one Set-Content — so a false throw can fail
    # the run but never leave a half-updated file. Assert-TableRowInFile, not Assert-LineInFile: it
    # re-reads the row against the header of the table it now sits in — a backstop behind
    # Set-MarkdownTableCell (which throws before writing on a missing column or a drifted row) and
    # the move's own shape gate. One call per written value keeps the check independent of column
    # order; values are matched in their stored, pipe-escaped form.
    if (-not $WhatIfPreference) {
        # Terminal: the row has MOVED under '## Resolved Explorations' (no Status column), where
        # the move wrote Outcome and Resolved Date. In place: Status and Last Updated. Either way
        # the two values are the display status and today's date.
        $verifyValues = @($DisplayStatus, $CurrentDate)
        if ($FindingsDoc) { $verifyValues += $FindingsDoc }

        foreach ($value in $verifyValues) {
            $rowPattern = "^\|\s*" + [regex]::Escape($ExplorationId) + "\s*\|(?:[^|]*\|)*\s*" + [regex]::Escape((Get-StoredCellText $value)) + "\s*\|"
            Assert-TableRowInFile -Path $TrackingFile -Pattern $rowPattern -Context "$ExplorationId → '$value' in $TrackingFile"
        }

        # -Notes is APPENDED to whatever the Notes cell already held (Join-ExplorationNote), so it
        # is matched as a suffix of its cell rather than as a whole cell.
        if ($Notes) {
            $notesRowPattern = "^\|\s*" + [regex]::Escape($ExplorationId) + "\s*\|.*" + [regex]::Escape((Get-StoredCellText $Notes)) + "\s*\|"
            Assert-TableRowInFile -Path $TrackingFile -Pattern $notesRowPattern -Context "$ExplorationId notes appended in $TrackingFile"
        }
    }

    Write-ProjectLog "Technical exploration tracking file updated successfully" -Level "SUCCESS"

    # Summary line. The resolve path carries the block-clearing reminder INTO the summary rather
    # than emitting it via Write-ProjectLog: INFO-level logging is default-quiet (routed to
    # Write-Verbose), so a caller without -Verbose would never see the one prompt that tells them
    # a blocked feature is still sitting at 🔬 Needs Technical Exploration.
    $summary = "$ExplorationId → $DisplayStatus"
    if ($FindingsDoc) { $summary += " (findings: $FindingsDoc)" }
    if ($NewStatus -eq "Resolved") {
        $summary += ". Next: if a feature was blocked on this exploration, return it from 🔬 Needs Technical Exploration to its pipeline status via Update-BatchFeatureStatus.ps1"
    }
    Write-ProjectSummary $summary
}

# Execute main function with soak-verification wrapper (PF-PRO-028 v2.0)
try {
    Main
    if ($soakInSoak) { Confirm-SoakInvocation -Outcome success }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -Outcome failure -Notes $soakErrMsg
    }
    Write-ProjectError -Message "Technical exploration update failed: $($_.Exception.Message)" -ExitCode 1
}
