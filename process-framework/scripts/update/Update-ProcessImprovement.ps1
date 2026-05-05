#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates improvement status updates in the Process Improvement Tracking state file

.DESCRIPTION
This script automates improvement lifecycle transitions in process-improvement-tracking.md.

Updates the following file:
- process-framework-local/state-tracking/permanent/process-improvement-tracking.md

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

PARAMETER REQUIREMENTS BY STATUS:
  Status                Required Parameters
  ----------            -------------------
  NeedsPrioritization   (none beyond ImprovementId, NewStatus)
  NeedsImplementation   (none beyond ImprovementId, NewStatus)
  InProgress            (none beyond ImprovementId, NewStatus)
  Deferred              (none beyond ImprovementId, NewStatus)
  Delegated             (none beyond ImprovementId, NewStatus)
  Completed             -Impact (HIGH|MEDIUM|LOW), -ValidationNotes (description of what was done)
  Rejected              -ValidationNotes (rejection rationale); -Impact optional (defaults to "—")
  Active                pilots only — IMP must be in Active Pilots section
  Resolved              pilots only — IMP must be in Active Pilots section; -Impact (HIGH|MEDIUM|LOW), -ValidationNotes (decision summary; required for Active→Resolved transition, optional for re-invocation/migration); triggers concept doc archive and moves pilot row to Completed Improvements (PF-IMP-729)

.PARAMETER ImprovementId
The improvement ID to update (e.g., "IMP-063" for regular IMPs, or PF-IMP-NNN for pilots)

.PARAMETER NewStatus
The new status. Valid values: NeedsPrioritization, NeedsImplementation, InProgress, Completed, Deferred, Delegated, Rejected (regular IMP statuses); Active, Resolved (pilot-only statuses, see PF-PRO-030).

.PARAMETER Impact
Impact level. Valid values: HIGH, MEDIUM, LOW, "—" (em-dash placeholder).
- Required when NewStatus is Completed (use HIGH/MEDIUM/LOW).
- Optional when NewStatus is Rejected — defaults to "—" if omitted (the canonical no-impact placeholder for rejected items).

.PARAMETER ValidationNotes
Description of what was done or rationale for the lifecycle transition.
Required when NewStatus is Completed or Rejected.
Optional for other statuses — when provided, the Update History entry is
enriched with the rationale (formatted as "<Status> <ID>: <notes>").

BASH GOTCHA: When invoking from bash, use single-quoted -ValidationNotes
(e.g., -ValidationNotes 'text with `code` references') because bash interprets
backticks inside double-quoted strings as command substitution, silently truncating
literal-code spans like `[string]$Param` to empty before pwsh receives the argument.
The script will report success but store corrupted notes. PowerShell-native
invocation is unaffected.

.PARAMETER UpdateHistoryNote
Custom note for the Update History table. Auto-generated if not provided.

.PARAMETER UpdatedBy
Who performed the update (default: "AI Agent (PF-TSK-009)")

.EXAMPLE
# Mark improvement as needing implementation (after prioritization)
Update-ProcessImprovement.ps1 -ImprovementId "IMP-063" -NewStatus "NeedsImplementation"

.EXAMPLE
# Mark improvement as in progress
Update-ProcessImprovement.ps1 -ImprovementId "IMP-063" -NewStatus "InProgress"

.EXAMPLE
# Complete an improvement
Update-ProcessImprovement.ps1 -ImprovementId "IMP-063" -NewStatus "Completed" -Impact "MEDIUM" -ValidationNotes "Created Update-ProcessImprovement.ps1 script."

.EXAMPLE
# Reject an improvement (Impact defaults to "—")
Update-ProcessImprovement.ps1 -ImprovementId "IMP-061" -NewStatus "Rejected" -ValidationNotes "Evaluated and determined not beneficial."

.EXAMPLE
# Defer an improvement
Update-ProcessImprovement.ps1 -ImprovementId "IMP-037" -NewStatus "Deferred"

.EXAMPLE
# Defer an improvement and capture the deferral rationale in the Update History entry
Update-ProcessImprovement.ps1 -ImprovementId "IMP-037" -NewStatus "Deferred" -ValidationNotes "Deferred until BUG-100 is resolved (blocking on parser refactor)."

.EXAMPLE
# Resolve a pilot (PF-PRO-030 lifecycle): records decision, archives the linked concept doc, and moves the row to Completed Improvements
Update-ProcessImprovement.ps1 -ImprovementId "PF-IMP-688" -NewStatus "Resolved" -Impact "MEDIUM" -ValidationNotes "Soak pilot proven; broader rollout filed as PF-IMP-700"

.NOTES
This script is part of the Process Improvement automation system and integrates with:
- Process Improvement Task (PF-TSK-009)
- Tools Review Task (PF-TSK-010)

Output behavior: Default output is one summary line per invocation (the operation
outcome, e.g. "PF-IMP-697 → InProgress"), plus one extra line per side-effect
(concept-doc archive on pilot Resolved). WARN and ERROR messages always pass
through. Pass -Verbose to restore the full play-by-play log (banner, parameter
echoes, prereq narration, per-step transformer messages) for debugging.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(IMP|PF-IMP)-\d+$')]
    [string]$ImprovementId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("NeedsPrioritization", "NeedsImplementation", "InProgress", "Completed", "Deferred", "Delegated", "Rejected", "Active", "Resolved")]
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
# Temporarily silence $VerbosePreference around the import so -Verbose callers see
# only this script's own Write-Verbose output, not the helper module's internal
# Write-Verbose chatter (and its cascaded sub-module Import-Module messages).
$prevVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
$VerbosePreference = $prevVerbosePreference

# Configuration
$ProjectRoot = Get-ProjectRoot
$TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "process-framework-local/state-tracking/permanent/process-improvement-tracking.md"
$ScriptName = "Update-ProcessImprovement.ps1"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

# Soak verification (PF-PRO-028 — see process-framework/state-tracking/permanent/script-soak-tracking.md)
$soakScriptId = "process-framework/scripts/update/Update-ProcessImprovement.ps1"
$soakInSoak   = Test-ScriptInSoak -ScriptId $soakScriptId -ScriptPath $PSCommandPath

# Display name mapping (ValidateSet value → human-readable status text in tracking file)
$StatusDisplayNames = @{
    "NeedsPrioritization" = "Needs Prioritization"
    "NeedsImplementation" = "Needs Implementation"
    "InProgress"          = "In Progress"
    "Completed"           = "Completed"
    "Deferred"            = "Deferred"
    "Delegated"           = "Delegated"
    "Rejected"            = "Rejected"
    "Active"              = "Active"
    "Resolved"            = "Resolved"
}

# Pilot-only statuses (PF-PRO-030)
$PilotStatuses = @("Active", "Resolved")

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

    if (-not (Test-Path $TrackingFile)) {
        Write-Log "Tracking file not found: $TrackingFile" -Level "ERROR"
        return $false
    }

    # Validate required parameters for completion/rejection
    if ($NewStatus -in @("Completed", "Rejected")) {
        if (-not $ValidationNotes) {
            Write-Log "ValidationNotes is required when transitioning to $NewStatus" -Level "ERROR"
            return $false
        }
        if ($NewStatus -eq "Completed" -and -not $Impact) {
            Write-Log "Impact is required when transitioning to Completed (use HIGH/MEDIUM/LOW)" -Level "ERROR"
            return $false
        }
        # For Rejected: auto-default Impact to "—" (canonical no-impact placeholder for rejected items)
        if ($NewStatus -eq "Rejected" -and -not $Impact) {
            $script:Impact = "—"
            Write-Log "Auto-defaulted Impact to '—' for Rejected status" -Level "INFO"
        }
    }

    # Validate required parameters for pilot resolution (PF-PRO-030, PF-IMP-729)
    # -Impact required (parallel to Completed). -ValidationNotes optional: required for fresh Active→Resolved
    # transitions (decision summary) but allowed to be empty for re-invocation/migration of already-resolved pilots
    # whose Notes column already contains the resolution narrative.
    if ($NewStatus -eq "Resolved" -and -not $Impact) {
        Write-Log "Impact is required when transitioning a pilot to Resolved (use HIGH/MEDIUM/LOW)" -Level "ERROR"
        return $false
    }

    Write-Log "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

# --- Pilot helpers (PF-PRO-030) ---

function Test-ImprovementLocation {
    # Returns "ActivePilots", "Current", "Completed", or "NotFound"
    param(
        [string]$Content,
        [string]$ImprovementId
    )
    $sections = [ordered]@{
        "ActivePilots" = "## Active Pilots"
        "Current"      = "## Current Improvement Opportunities"
        "Completed"    = "## Completed Improvements"
    }

    foreach ($key in $sections.Keys) {
        $rows = ConvertFrom-MarkdownTable -Content $Content -Section $sections[$key]
        if ($rows | Where-Object { $_.ID -eq $ImprovementId }) {
            return $key
        }
    }
    return "NotFound"
}

function Update-PilotStatusInPlace {
    param(
        [string]$Content,
        [string]$ImprovementId,
        [string]$NewStatus,
        [string]$Notes  # On Resolved: appended to Notes column with date prefix
    )

    $rows = ConvertFrom-MarkdownTable -Content $Content -Section "## Active Pilots" -IncludeRawLine
    $row = $rows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $row) {
        Write-Log "Pilot $ImprovementId not found in Active Pilots section" -Level "ERROR"
        return $null
    }

    $currentEntry = $row._RawLine
    Write-Log "Found pilot entry for $ImprovementId"

    # Pilot schema: | ID | Source | Started | Adopters | Success Criteria | Decision Trigger | Status | Notes |
    # Indices:        0    1        2          3          4                   5                   6        7
    $columns = Split-MarkdownTableRow $currentEntry
    if ($null -eq $columns -or $columns.Count -ne 8) {
        $actualCount = if ($null -eq $columns) { 0 } else { $columns.Count }
        Write-Log "Malformed pilot row for $ImprovementId`: expected 8 columns, found $actualCount." -Level "ERROR"
        Write-Log "Raw row: $currentEntry" -Level "ERROR"
        return $null
    }

    $displayName = $StatusDisplayNames[$NewStatus]
    $columns[6] = $displayName

    # On Resolved: append decision notes to Notes column (preserving any existing)
    if ($NewStatus -eq "Resolved" -and $Notes) {
        $existingNotes = $columns[7].Trim()
        $resolvedNote = "Resolved ${CurrentDate}: $Notes"
        if ($existingNotes -and $existingNotes -ne "") {
            $columns[7] = "$existingNotes; $resolvedNote"
        } else {
            $columns[7] = $resolvedNote
        }
    }

    $updatedEntry = ConvertTo-MarkdownTableRow -Cells $columns
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-Log "Updated pilot $ImprovementId status to: $displayName" -Level "SUCCESS"
    return $result
}

function Get-ConceptIdFromPilotRow {
    param(
        [string]$Content,
        [string]$ImprovementId
    )
    $rows = ConvertFrom-MarkdownTable -Content $Content -Section "## Active Pilots"
    $row = $rows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $row) { return $null }

    # Source column format: "PF-PRO-NNN / PF-TSK-NNN" — extract concept ID
    if ($row.Source -match 'PF-PRO-\d+') {
        return $matches[0]
    }
    return $null
}

function Move-ConceptToArchive {
    param([string]$ConceptId)

    $proposalsDir = Join-Path $ProjectRoot "process-framework-local/proposals"
    if (-not (Test-Path $proposalsDir)) {
        Write-Log "Proposals directory not found: $proposalsDir" -Level "WARN"
        return $false
    }

    # Find concept file by frontmatter id
    $sourcePath = $null
    Get-ChildItem -Path $proposalsDir -Filter "*.md" -File | ForEach-Object {
        if ($null -ne $sourcePath) { return }
        $fileContent = Get-Content -Path $_.FullName -Raw -Encoding UTF8
        if ($fileContent -match "(?m)^id:\s*$([regex]::Escape($ConceptId))\s*$") {
            $sourcePath = $_.FullName
        }
    }

    if (-not $sourcePath) {
        Write-Log "Concept $ConceptId not found in $proposalsDir (may already be archived). Skipping concept archive." -Level "WARN"
        return $true
    }

    $oldDir = Join-Path $proposalsDir "old"
    if (-not (Test-Path $oldDir)) {
        New-Item -ItemType Directory -Path $oldDir -Force | Out-Null
    }

    $destPath = Join-Path $oldDir (Split-Path $sourcePath -Leaf)
    if (Test-Path $destPath) {
        Write-Log "Concept $ConceptId already exists at archive destination: $destPath. Manual cleanup required." -Level "WARN"
        return $false
    }

    if ($PSCmdlet.ShouldProcess($sourcePath, "Move concept $ConceptId to proposals/old/")) {
        Move-Item -Path $sourcePath -Destination $destPath -Force
        Write-SummaryLine "Archived concept $ConceptId to $destPath"
    }
    return $true
}

function Move-PilotToCompletedSection {
    # PF-IMP-729: Mirrors Move-ToCompletedSection for pilot rows. Transforms 8-column
    # Active Pilots schema into 5-column Completed Improvements schema.
    # Source: | ID | Source | Started | Adopters | Success Criteria | Decision Trigger | Status | Notes |
    # Dest:   | ID | Description                                                          | Completed Date | Impact | Validation Notes |
    param(
        [string]$Content,
        [string]$ImprovementId,
        [string]$Impact
    )

    # Read pilot row to extract source columns for transformation
    $rows = ConvertFrom-MarkdownTable -Content $Content -Section "## Active Pilots"
    $row = $rows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
    if (-not $row) {
        Write-Log "Pilot $ImprovementId not found in Active Pilots section for move" -Level "ERROR"
        return $null
    }

    # Build composite description preserving Source, Adopters, and Started date
    $description = "Pilot: $($row.Source) — adopters: $($row.Adopters) (started $($row.Started))"
    $validationNotes = $row.Notes

    # Minimal mapping (ID only); remaining columns supplied via AdditionalColumns,
    # which Move-MarkdownTableRow appends in order after mapped columns.
    $columnMapping = [ordered]@{
        "ID" = "ID"
    }
    $additionalColumns = [ordered]@{
        "Description"      = $description
        "Completed Date"   = $CurrentDate
        "Impact"           = $Impact
        "Validation Notes" = $validationNotes
    }

    $result = Move-MarkdownTableRow `
        -Content $Content `
        -RowIdPattern ([regex]::Escape($ImprovementId)) `
        -SourceSection "## Active Pilots" `
        -DestinationSection "## Completed Improvements" `
        -ColumnMapping $columnMapping `
        -AdditionalColumns $additionalColumns

    if ($null -eq $result.Content) {
        Write-Log "Failed to move pilot $ImprovementId to Completed Improvements section" -Level "ERROR"
        return $null
    }

    Write-Log "Removed $ImprovementId from Active Pilots"
    Write-Log "Added $ImprovementId to Completed Improvements section" -Level "SUCCESS"
    return $result.Content
}

# --- Content-transformation functions ---
# Each takes a $Content string and returns modified $Content string.
# This enables a single read-modify-write cycle in Main.

function Test-IsInCompletedSection {
    param(
        [string]$Content,
        [string]$ImprovementId
    )
    $rows = ConvertFrom-MarkdownTable -Content $Content -Section "## Completed Improvements"
    return [bool]($rows | Where-Object { $_.ID -eq $ImprovementId })
}

function Update-StatusInPlace {
    param(
        [string]$Content,
        [string]$ImprovementId,
        [string]$NewStatus
    )

    # Find the improvement row in the Current Improvement Opportunities section.
    # Section-scoped lookup prevents false matches in the Completed section,
    # where the same ID appears with a different 5-column schema (PF-IMP-629).
    $rows = ConvertFrom-MarkdownTable -Content $Content -Section "## Current Improvement Opportunities" -IncludeRawLine
    $row = $rows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1

    if (-not $row) {
        if (Test-IsInCompletedSection -Content $Content -ImprovementId $ImprovementId) {
            Write-Log "Improvement $ImprovementId is already in the Completed Improvements section. To reopen it, manually move the row back to 'Current Improvement Opportunities' first." -Level "ERROR"
            return $null
        }
        Write-Log "Improvement entry not found in Current table: $ImprovementId" -Level "ERROR"
        return $null
    }

    $currentEntry = $row._RawLine
    Write-Log "Found improvement entry for $ImprovementId"

    # Parse columns: | ID | Source | Description | Priority | Status | Last Updated | Notes |
    $columns = Split-MarkdownTableRow $currentEntry
    if ($null -eq $columns -or $columns.Count -ne 7) {
        $actualCount = if ($null -eq $columns) { 0 } else { $columns.Count }
        Write-Log "Malformed table row for $ImprovementId`: expected 7 columns, found $actualCount. Check for unescaped pipe characters in cell content. Escape literal pipes as '\|' (preferred — markdown table escape, supported by Split-MarkdownTableRow per PF-IMP-603) or '&#124;' (HTML-entity fallback)." -Level "ERROR"
        Write-Log "Raw row: $currentEntry" -Level "ERROR"
        return $null
    }

    # Update Status (index 4) and Last Updated (index 5)
    $displayName = $StatusDisplayNames[$NewStatus]
    $columns[4] = $displayName
    $columns[5] = $CurrentDate

    $updatedEntry = ConvertTo-MarkdownTableRow -Cells $columns
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-Log "Updated $ImprovementId status to: $displayName" -Level "SUCCESS"
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
        if (-not $result.SourceRow -and (Test-IsInCompletedSection -Content $Content -ImprovementId $ImprovementId)) {
            Write-Log "Improvement $ImprovementId is already in the Completed Improvements section. The completion transition has already been applied — no action needed." -Level "ERROR"
            return $null
        }
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
        if ($inCompletedSection -and $line -match "^\|\s*(PF-)?IMP-\d+") { $count++ }
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
    $isPilotStatus = $NewStatus -in $PilotStatuses

    # Detect which section the IMP lives in (read once, reuse for routing)
    $content = Get-Content $TrackingFile -Raw
    $location = Test-ImprovementLocation -Content $content -ImprovementId $ImprovementId
    Write-Log "Located $ImprovementId in section: $location"

    # Validate status / location compatibility
    if ($isPilotStatus) {
        if ($location -ne "ActivePilots") {
            Write-Log "Pilot status '$NewStatus' is only valid for IMPs in the Active Pilots section. $ImprovementId is in: $location" -Level "ERROR"
            exit 1
        }
    } else {
        if ($location -eq "ActivePilots") {
            Write-Log "Status '$NewStatus' is not valid for pilots. Use Active or Resolved for IMPs in the Active Pilots section." -Level "ERROR"
            exit 1
        }
        if ($location -eq "NotFound") {
            Write-Log "$ImprovementId not found in any section of $TrackingFile" -Level "ERROR"
            exit 1
        }
    }

    # Generate default history note if not provided
    if (-not $UpdateHistoryNote) {
        if ($isCompletion) {
            $statusLabel = if ($NewStatus -eq "Rejected") { "Rejected" } else { "Completed" }
            $UpdateHistoryNote = "$statusLabel $ImprovementId`: $ValidationNotes"
        }
        elseif ($NewStatus -eq "Resolved") {
            # Empty -ValidationNotes signals the migration path (already-resolved pilot whose
            # Notes column already contains the resolution narrative — see PF-IMP-729).
            if ($ValidationNotes) {
                $UpdateHistoryNote = "Resolved pilot $ImprovementId`: $ValidationNotes"
            } else {
                $UpdateHistoryNote = "Migrated resolved pilot $ImprovementId to Completed Improvements"
            }
        }
        elseif ($NewStatus -eq "Active" -and $location -eq "ActivePilots") {
            $UpdateHistoryNote = if ($ValidationNotes) { "Reactivated pilot ${ImprovementId}: $ValidationNotes" } else { "Set pilot $ImprovementId status to Active" }
        }
        elseif ($ValidationNotes) {
            # Non-completion status with rationale — mirror Completed/Rejected format in Update History (PF-IMP-625)
            $UpdateHistoryNote = "$($StatusDisplayNames[$NewStatus]) ${ImprovementId}: $ValidationNotes"
        }
        else {
            $UpdateHistoryNote = "Updated $ImprovementId status to $($StatusDisplayNames[$NewStatus])"
        }
    }

    if (-not $PSCmdlet.ShouldProcess($TrackingFile, "Update $ImprovementId to $NewStatus")) {
        return
    }

    # --- Pilot path (PF-PRO-030) ---
    if ($isPilotStatus) {
        # Detect already-Resolved migration path (PF-IMP-729): if pilot is already in Resolved
        # status and Resolved is requested again, skip the in-place update + notes append (would
        # otherwise create a duplicate "Resolved YYYY-MM-DD: ..." entry in Notes) — just do the move.
        $alreadyResolved = $false
        if ($NewStatus -eq "Resolved") {
            $existingPilotRows = ConvertFrom-MarkdownTable -Content $content -Section "## Active Pilots"
            $existingRow = $existingPilotRows | Where-Object { $_.ID -eq $ImprovementId } | Select-Object -First 1
            if ($existingRow -and $existingRow.Status -eq "Resolved") {
                $alreadyResolved = $true
                Write-Log "Pilot $ImprovementId already in Resolved status — skipping in-place update (migration path)" -Level "INFO"
            }
        }

        if (-not $alreadyResolved) {
            # Update pilot status in place (appends "Resolved YYYY-MM-DD: ..." to Notes if applicable)
            $content = Update-PilotStatusInPlace -Content $content -ImprovementId $ImprovementId -NewStatus $NewStatus -Notes $ValidationNotes
            if ($null -eq $content) { exit 1 }
        }

        # On Resolved: extract concept ID and move pilot row to Completed Improvements (PF-IMP-729)
        $conceptId = $null
        if ($NewStatus -eq "Resolved") {
            $conceptId = Get-ConceptIdFromPilotRow -Content $content -ImprovementId $ImprovementId
            if (-not $conceptId) {
                Write-Log "Could not extract concept ID from pilot row Source column. Manual concept archive may be required." -Level "WARN"
            }

            # Move pilot row from Active Pilots to Completed Improvements
            $content = Move-PilotToCompletedSection -Content $content -ImprovementId $ImprovementId -Impact $Impact
            if ($null -eq $content) { exit 1 }

            # Update Completed summary count to reflect the new entry
            $content = Update-SummaryCount -Content $content
        }

        # Add Update History entry
        $content = Add-UpdateHistoryEntry -Content $content -ImprovementId $ImprovementId -HistoryNote $UpdateHistoryNote -UpdatedBy $UpdatedBy
        if ($null -eq $content) {
            Write-Log "Failed to add Update History entry" -Level "ERROR"
            exit 1
        }

        # Update history summary count
        $content = Update-HistorySummaryCount -Content $content

        # Update frontmatter date
        $content = Update-FrontmatterDate -Content $content

        # Write tracking file (retry-on-IOException absorbs LinkWatcher contention — PF-IMP-718)
        Invoke-FileWriteWithRetry -Context (Split-Path $TrackingFile -Leaf) -ScriptBlock {
            Set-Content -Path $TrackingFile -Value $content -NoNewline
        }

        # Read-after-write verification: confirm the row exists in tracking file
        # (in Completed for Resolved, still in Active Pilots for Active)
        if (-not $WhatIfPreference) {
            $rowPattern = "\|\s*" + [regex]::Escape($ImprovementId) + "\s*\|"
            Assert-LineInFile -Path $TrackingFile -Pattern $rowPattern -Context "row for $ImprovementId in $TrackingFile"
        }

        # Archive concept doc on Resolved (after tracking file is written, so a failure here doesn't leave inconsistent state)
        if ($NewStatus -eq "Resolved" -and $conceptId) {
            $archived = Move-ConceptToArchive -ConceptId $conceptId
            if (-not $archived) {
                Write-Log "Concept archive step had issues — manual review required" -Level "WARN"
            }
        }

        $pilotDisplay = $StatusDisplayNames[$NewStatus]
        if ($NewStatus -eq "Resolved") {
            Write-SummaryLine "$ImprovementId pilot → $pilotDisplay (moved to Completed Improvements)"
        } else {
            Write-SummaryLine "$ImprovementId pilot → $pilotDisplay"
        }
        return
    }

    # --- Regular IMP path (existing behavior) ---
    if ($isCompletion) {
        # Step 1: Move row from Current to Completed
        $content = Move-ToCompletedSection -Content $content -ImprovementId $ImprovementId -Impact $Impact -ValidationNotes $ValidationNotes
        if ($null -eq $content) { exit 1 }

        # Step 2: Update summary count
        $content = Update-SummaryCount -Content $content
    }
    else {
        # Status-only update in Current table
        $content = Update-StatusInPlace -Content $content -ImprovementId $ImprovementId -NewStatus $NewStatus
        if ($null -eq $content) { exit 1 }
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

    # Single write (retry-on-IOException absorbs LinkWatcher contention — PF-IMP-718)
    Invoke-FileWriteWithRetry -Context (Split-Path $TrackingFile -Leaf) -ScriptBlock {
        Set-Content -Path $TrackingFile -Value $content -NoNewline
    }

    # Read-after-write verification: confirm the IMP row exists in tracking file
    if (-not $WhatIfPreference) {
        $rowPattern = "\|\s*" + [regex]::Escape($ImprovementId) + "\s*\|"
        Assert-LineInFile -Path $TrackingFile -Pattern $rowPattern -Context "IMP row for $ImprovementId in $TrackingFile"
    }

    $outcome = if ($isCompletion) { "$($StatusDisplayNames[$NewStatus]) (moved to Completed Improvements)" } else { $StatusDisplayNames[$NewStatus] }
    Write-SummaryLine "$ImprovementId → $outcome"
}

# Execute main function
try {
    Main
    if ($soakInSoak) {
        Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome success
    }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -ScriptId $soakScriptId -Outcome failure -Notes $soakErrMsg
    }
    Write-ProjectError -Message "Process Improvement update failed: $($_.Exception.Message)" -ExitCode 1
}
