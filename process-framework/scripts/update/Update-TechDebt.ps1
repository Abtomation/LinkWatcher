#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates technical debt lifecycle management in the Technical Debt Tracker state file

.DESCRIPTION
This script automates debt item lifecycle management in technical-debt-tracking.md.
Optionally updates the validation tracking file when resolving or adding debt items
tracked in validation (via -ValidationNote and -ValidationIssueId parameters).

Updates the following files (defaults; override with -TrackingFile / -ArchiveFile):
- doc/state-tracking/permanent/technical-debt-tracking.md (live Registry only since archive-split)
- doc/state-tracking/permanent/archive/technical-debt-tracking-archive.md (## Resolved + ## Rejected;
  archive-split 2026-05-26 per PF-IMP-873)

Supports five operation modes:
1. Add new debt item: Generates next TD### ID, inserts row into Registry table, optionally
   updates the associated PF-TDI debt item file with the assigned ID
2. Batch add (-BatchFile): Reads a JSON array of debt items, validates all items upfront,
   then adds them sequentially. Same per-item side-effects as single -Add. Eliminates
   per-call overhead when registering multiple items in one session (PF-TSK-066 Step 11
   commonly produces 5-15 debt items per feature). See -BatchFile parameter for JSON shape.
3. Status-only update: Changes Status and Resolution Date columns in the Registry table
4. Completion (Resolved/Rejected): Moves debt item from Registry (in TrackingFile) to archive
   ## Resolved (Resolved) or ## Rejected (Rejected) section (in ArchiveFile, PF-IMP-873),
   drops Estimated Effort and Status columns, sets Resolution Date, updates frontmatter date
5. In-place edit of open item: Replaces the Description and/or Notes column on a TD item
   still in the Registry table (-EditDescription / -EditNotes), without changing status.
   Use case: a refactoring resolves a sub-item of another open TD without resolving the whole TD.

Registry table columns (read from live header at runtime):
  | ID | Description | Dims | Location | Created Date | Priority | Estimated Effort | Status | Resolution Date | Assessment ID | Workflows | Notes |

Archive ## Resolved / ## Rejected table columns (read from archive header at runtime):
  | ID | Description | Category | Location | Created Date | Priority | Resolution Date | Assessment ID | Notes |

Column lookups are header-driven via Split-MarkdownTableRow / ConvertTo-MarkdownTableRow / Move-MarkdownTableRow
from TableOperations.psm1 — no hardcoded indices. Schema additions to either table will not silently corrupt
data. See PF-IMP-006 for the original index-hardcoding defects this replaces.

.PARAMETER Add
Switch to add a new debt item. Auto-generates the next TD### ID.

.PARAMETER Description
Description of the technical debt item (required for Add).

.PARAMETER Dims
Dimension abbreviation(s) for the debt item (required for Add). Multi-value supported:
separate codes with whitespace or comma (e.g., "CQ", "CQ DA", "CQ, DA").
Valid values: AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI, TST, AIC
See Development Dimensions Guide for definitions.

.PARAMETER Location
Location/path where the debt exists (required for Add). E.g., "src/linkwatcher/parsers"

.PARAMETER Priority
Priority level (required for Add). Valid values: Critical, High, Medium, Low

.PARAMETER EstimatedEffort
Estimated effort to resolve (required for Add). E.g., "2 hours", "1 week"

.PARAMETER AssessmentId
ID of the assessment that identified this debt (optional for Add). E.g., "PF-TDA-001", "PF-VAL-042"

.PARAMETER DebtItemId
ID of the individual debt item document (optional for Add). E.g., "PF-TDI-001".
When provided, updates the debt item file with the assigned TD### registry ID.

.PARAMETER Notes
Additional notes about the debt item (optional for Add).

.PARAMETER BatchFile
Path to a JSON file containing an array of debt items to add. Each array element is a
JSON object with the same fields as the single -Add parameter set:

  Required: Description, Dims, Location, Priority, EstimatedEffort
  Optional: AssessmentId, DebtItemId, Notes, ValidationIssueId (string or array of strings)

All items are validated upfront. If any item fails validation, the script exits with
exit code 1 and a descriptive error referring to the failing item index — no items are
added in that case. On success, items are added sequentially with auto-generated TD###
IDs; per-item side-effects (Update-DebtItemFile when DebtItemId is set;
Update-ValidationTrackingLink when ValidationIssueId is set) match single -Add behavior.

Example JSON:
  [
    {
      "Description": "Missing error handling in parser",
      "Dims": "CQ",
      "Location": "src/linkwatcher/parsers",
      "Priority": "Medium",
      "EstimatedEffort": "2 hours",
      "AssessmentId": "PF-TDA-001",
      "Notes": "Catch-all bare except blocks observed."
    },
    {
      "Description": "Logging missing across parser layer",
      "Dims": "CQ OB",
      "Location": "src/linkwatcher/parsers",
      "Priority": "Medium",
      "EstimatedEffort": "4 hours"
    }
  ]

.PARAMETER Section
Target section for updates. Currently only "Resolved" is supported.
When set to "Resolved", updates notes on items already in the archive (## Resolved or ## Rejected
section in -ArchiveFile, per PF-IMP-873). Use with -ResolvedDebtId and -UpdateNotes.

.PARAMETER ResolvedDebtId
The technical debt ID to update in the archive (e.g., "TD011"). Searched against both ## Resolved
and ## Rejected sections — the operation is meaningful for either disposition.
Required when -Section "Resolved" is used.

.PARAMETER UpdateNotes
Text to append to the Notes column of the archived debt item.
Required when -Section "Resolved" is used.

.PARAMETER DebtId
The technical debt ID to update (e.g., "TD005"). Required for status updates.

.PARAMETER NewStatus
The new status. Valid values: Open, InProgress, Resolved, Rejected. Required for status updates.
Resolved items move to archive ## Resolved; Rejected items move to archive ## Rejected (PF-IMP-873
dual-section archive). Rejected items preserve their rejection rationale in the Notes column.

.PARAMETER ResolutionNotes
Description of what was done. Required when NewStatus is Resolved or Rejected.
Appended to the Notes column in the archive table (## Resolved for Resolved, ## Rejected for Rejected).

.PARAMETER PlanLink
Optional reference to the refactoring plan. Accepts either:
  - A complete markdown link with DebtId as link text: "[TD006](path/to/plan.md)"
  - A bare path (auto-wrapped with DebtId): "path/to/plan.md"
When provided, the ID column in the archive table becomes a clickable link to the plan.

⚠️ Windows + bash MSYS path-mangling hazard:
Paths starting with a leading slash (/doc/...) are silently rewritten by MSYS
to absolute Git-installation paths (e.g., "C:/Program Files/Git/doc/...") before
PowerShell sees them. ALWAYS use a relative path WITHOUT a leading slash:
  ✅ "doc/refactoring/plans/foo.md"
  ❌ "/doc/refactoring/plans/foo.md"     (MSYS mangles this)
The script detects the mangled prefix at runtime and rejects, but using the
relative form from the start avoids the failed call.

Invalid formats are rejected: mismatched TD ID, no path separator, or MSYS-mangled paths containing "Program Files/Git".

.PARAMETER ValidationNote
Optional status text for the validation tracking file's issue tables.
When provided (and NewStatus is Resolved), finds the row whose "Tracked As" column contains
the DebtId and updates Status to "RESOLVED" and Assigned Session to this note.
The validation tracking file is auto-discovered from doc/state-tracking/validation/.
Example: "PD-REF-042 — docstring added documenting precedence order"

.PARAMETER ValidationIssueId
Optional validation issue ID(s) (e.g., "R2-M-005", "OB-R3-004") to link a debt item to validation tracking row(s).
Accepts a single string or an array of strings for secondary findings resolved by the same fix.
On -Add: writes the newly assigned TD### into the "Tracked As" column of each matching issue row.
On Resolve/Reject (with -ValidationNote): searches by each ID in the "Issue ID" column instead of
searching by DebtId in "Tracked As" column. Use this when the validation issue was tracked under a
non-TD ID (e.g., OB-R3-004) that differs from the TD### registry ID.
The validation tracking file is auto-discovered from doc/state-tracking/validation/.

.PARAMETER EditDescription
Replaces the Description column of an open TD item in the Registry table (OpenEdit mode).
Pass the full new value — the existing Description is overwritten, not appended to.
Use when a refactoring partially scopes another open TD (e.g., a sub-item is resolved
bundled with a different fix) and the description needs to be trimmed or amended without
resolving the whole TD. For items already in the archive (## Resolved or ## Rejected), use
-Section "Resolved" -ResolvedDebtId -UpdateNotes instead.

.PARAMETER EditNotes
Replaces the Notes column of an open TD item in the Registry table (OpenEdit mode).
Pass the full new value — the existing Notes is overwritten, not appended to. To append,
pass "<old> <new>" yourself. For items already in the archive, use the ResolvedUpdate
parameter set (-Section "Resolved" -ResolvedDebtId -UpdateNotes), which appends.

.EXAMPLE
# Add a new debt item
Update-TechDebt.ps1 -Add -Description "Missing error handling in parser" -Dims "CQ" -Location "src/linkwatcher/parsers" -Priority "Medium" -EstimatedEffort "2 hours"

.EXAMPLE
# Add a new debt item with assessment and debt item links
Update-TechDebt.ps1 -Add -Description "Missing Repository Pattern" -Dims "AC" -Location "lib/services/" -Priority "Critical" -EstimatedEffort "1-2 weeks" -AssessmentId "PF-TDA-001" -DebtItemId "PF-TDI-001"

.EXAMPLE
# Add a debt item spanning multiple dimensions (whitespace or comma-separated)
Update-TechDebt.ps1 -Add -Description "Logging missing across parser layer" -Dims "CQ OB" -Location "src/linkwatcher/parsers" -Priority "Medium" -EstimatedEffort "4 hours"

.EXAMPLE
# Batch-add multiple debt items from a JSON file (eliminates per-call overhead during PF-TSK-066 Step 11)
Update-TechDebt.ps1 -BatchFile "doc/state-tracking/temporary/td-batch.json"

.EXAMPLE
# Mark debt item as in progress
Update-TechDebt.ps1 -DebtId "TD005" -NewStatus "InProgress"

.EXAMPLE
# Resolve a debt item
Update-TechDebt.ps1 -DebtId "TD011" -NewStatus "Resolved" -ResolutionNotes "Replaced bare except: with except Exception:"

.EXAMPLE
# Reject a debt item (Won't Fix)
Update-TechDebt.ps1 -DebtId "TD064" -NewStatus "Rejected" -ResolutionNotes "Rejected: All decisions are module-local and already documented via inline comments."

.EXAMPLE
# Resolve with plan link
Update-TechDebt.ps1 -DebtId "TD006" -NewStatus "Resolved" -ResolutionNotes "Extracted public API methods." -PlanLink "[TD006](../../../doc/refactoring/plans/archive/td006-encapsulation-violation-fix.md)"

.EXAMPLE
# Resolve with bare path (auto-wrapped with DebtId)
Update-TechDebt.ps1 -DebtId "TD006" -NewStatus "Resolved" -ResolutionNotes "Extracted." -PlanLink "doc/refactoring/plans/archive/td006-encapsulation-violation-fix.md"

.EXAMPLE
# Add a new debt item linked to a validation issue (auto-fills "Tracked As" column)
Update-TechDebt.ps1 -Add -Description "Missing ADR for decisions" -Dims "AC" -Location "src/linkwatcher/validator.py" -Priority "Medium" -EstimatedEffort "2 hours" -ValidationIssueId "R2-M-001"

.EXAMPLE
# Resolve with validation tracking update (auto-discovers validation-tracking file)
Update-TechDebt.ps1 -DebtId "TD022" -NewStatus "Resolved" -ResolutionNotes "Extracted ReferenceLookup class" -ValidationNote "PD-REF-042 — reduced to 681 LOC"

.EXAMPLE
# Resolve with validation tracking update when issue ID differs from TD ID
Update-TechDebt.ps1 -DebtId "TD144" -NewStatus "Resolved" -ResolutionNotes "Added structured logging" -ValidationNote "Session 16 — logging added" -ValidationIssueId "OB-R3-004"

.EXAMPLE
# Resolve with primary and secondary validation issue IDs (one fix resolves multiple findings)
Update-TechDebt.ps1 -DebtId "TD188" -NewStatus "Resolved" -ResolutionNotes "Updated FDD FR-3" -ValidationNote "PD-REF-175 — FR-3 rewritten" -ValidationIssueId "R4-DA-M02","R4-DA-L04"

.EXAMPLE
# Update notes on an already-resolved item
Update-TechDebt.ps1 -Section "Resolved" -ResolvedDebtId "TD011" -UpdateNotes "Plan link: [TD011](../archive/td011.md)"

.EXAMPLE
# Edit description of an open debt item (e.g., trim a sub-item resolved bundled with another TD)
Update-TechDebt.ps1 -DebtId "TD249" -EditDescription "Tighten 3 useless tolerances in test_large_projects.py: PH-001 move, PH-002 scan, PH-002 move."

.EXAMPLE
# Edit notes of an open debt item (replaces — pass full new value)
Update-TechDebt.ps1 -DebtId "TD249" -EditNotes "PH-008 sub-item resolved bundled with TD247 (PD-REF-217)."

.EXAMPLE
# Edit both description and notes in one call
Update-TechDebt.ps1 -DebtId "TD249" -EditDescription "Tighten 3 PH-tolerances..." -EditNotes "PH-008 sub-item resolved by TD247."

.EXAMPLE
# List valid dimension codes and descriptions
Update-TechDebt.ps1 -ListDims

.NOTES
This script is part of the Technical Debt automation system and integrates with:
- Code Refactoring Task (PF-TSK-022)
- Technical Debt Assessment Task (PF-TSK-023)
- Validation Tasks (PF-TSK-031 through PF-TSK-036)
- New-DebtItem.ps1

Updates the following files:
- doc/state-tracking/permanent/technical-debt-tracking.md (always)
- Validation tracking file (auto-discovered, when -ValidationNote or -ValidationIssueId are provided)

Output behavior: Default output is one summary line per invocation (the operation
outcome, e.g. "TD123 → Resolved (moved to archive)"), plus one extra line
per side-effect file write (validation-tracking link/update, debt item file update).
WARN and ERROR messages always pass through. Pass -Verbose to restore the full
play-by-play log (banner, parameter echoes, prereq narration, per-step transformer
messages) for debugging.
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'StatusUpdate')]
param(
    # --- AddNew parameter set ---
    [Parameter(Mandatory = $true, ParameterSetName = 'AddNew')]
    [switch]$Add,

    [Parameter(Mandatory = $true, ParameterSetName = 'AddNew')]
    [string]$Description,

    [Parameter(Mandatory = $true, ParameterSetName = 'AddNew')]
    [ValidateScript({
        $validDims = @("AC", "CQ", "ID", "DA", "EM", "SE", "PE", "OB", "UX", "DI", "TST", "AIC")
        $tokens = $_ -split '[\s,]+' | Where-Object { $_ -ne '' }
        if ($tokens.Count -eq 0) {
            throw "-Dims cannot be empty. Provide one or more codes (e.g., 'CQ' or 'CQ DA'). Valid: $($validDims -join ', ')"
        }
        $invalid = $tokens | Where-Object { $_ -notin $validDims }
        if ($invalid) {
            throw "Invalid -Dims code(s): $($invalid -join ', '). Valid codes: $($validDims -join ', '). Use space or comma to separate multiple."
        }
        return $true
    })]
    [string]$Dims,

    [Parameter(Mandatory = $true, ParameterSetName = 'AddNew')]
    [string]$Location,

    [Parameter(Mandatory = $true, ParameterSetName = 'AddNew')]
    [ValidateSet("Critical", "High", "Medium", "Low")]
    [string]$Priority,

    [Parameter(Mandatory = $true, ParameterSetName = 'AddNew')]
    [string]$EstimatedEffort,

    [Parameter(Mandatory = $false, ParameterSetName = 'AddNew')]
    [string]$AssessmentId,

    [Parameter(Mandatory = $false, ParameterSetName = 'AddNew')]
    [string]$DebtItemId,

    [Parameter(Mandatory = $false, ParameterSetName = 'AddNew')]
    [string]$Notes,

    # --- StatusUpdate / OpenEdit parameter sets ---
    [Parameter(Mandatory = $true, ParameterSetName = 'StatusUpdate')]
    [Parameter(Mandatory = $true, ParameterSetName = 'OpenEdit')]
    [ValidatePattern('^TD\d+$')]
    [string]$DebtId,

    [Parameter(Mandatory = $true, ParameterSetName = 'StatusUpdate')]
    [ValidateSet("Open", "InProgress", "Resolved", "Rejected")]
    [string]$NewStatus,

    [Parameter(Mandatory = $false, ParameterSetName = 'StatusUpdate')]
    [string]$ResolutionNotes,

    [Parameter(Mandatory = $false, ParameterSetName = 'StatusUpdate')]
    [string]$PlanLink,

    [Parameter(Mandatory = $false, ParameterSetName = 'StatusUpdate')]
    [string]$ValidationNote,

    [Parameter(Mandatory = $false, ParameterSetName = 'AddNew')]
    [Parameter(Mandatory = $false, ParameterSetName = 'StatusUpdate')]
    [string[]]$ValidationIssueId,

    # --- OpenEdit parameter set ---
    [Parameter(Mandatory = $false, ParameterSetName = 'OpenEdit')]
    [string]$EditDescription,

    [Parameter(Mandatory = $false, ParameterSetName = 'OpenEdit')]
    [string]$EditNotes,

    # --- ResolvedUpdate parameter set ---
    [Parameter(Mandatory = $true, ParameterSetName = 'ResolvedUpdate')]
    [ValidateSet("Resolved")]
    [string]$Section,

    [Parameter(Mandatory = $true, ParameterSetName = 'ResolvedUpdate')]
    [ValidatePattern('^TD\d+$')]
    [string]$ResolvedDebtId,

    [Parameter(Mandatory = $true, ParameterSetName = 'ResolvedUpdate')]
    [string]$UpdateNotes,

    # --- Batch parameter set (PF-IMP-012) ---
    [Parameter(Mandatory = $true, ParameterSetName = 'Batch')]
    [ValidateScript({ Test-Path $_ })]
    [string]$BatchFile,

    # --- ListDims parameter set ---
    [Parameter(Mandatory = $true, ParameterSetName = 'ListDims')]
    [switch]$ListDims,

    # --- File paths (all parameter sets) ---
    [Parameter(Mandatory = $false)]
    [string]$TrackingFile,

    # Archive-split (2026-05-26 per PF-IMP-873): sibling archive file holding
    # ## Resolved and ## Rejected sections. Default sits in an `archive/` subdir
    # next to -TrackingFile, mirroring Update-ProcessImprovement.ps1's -ArchiveFile
    # resolution.
    [Parameter(Mandatory = $false)]
    [string]$ArchiveFile
)

# --- Configuration ---

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

$ProjectRoot = Get-ProjectRoot
if (-not $TrackingFile) {
    $TrackingFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/technical-debt-tracking.md"
}
$TargetFile = $TrackingFile

# Archive-split (2026-05-26, PF-IMP-873): default ArchiveFile sits in an `archive/`
# subdir next to -TrackingFile. Mirrors Update-ProcessImprovement.ps1's pattern.
if (-not $ArchiveFile) {
    $trackingDir = Split-Path -Parent $TargetFile
    $ArchiveFile = Join-Path -Path $trackingDir -ChildPath "archive/technical-debt-tracking-archive.md"
}

$ScriptName = "Update-TechDebt.ps1"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

# Soak verification (PF-PRO-028 — see process-framework-central/state-tracking/permanent/script-soak-tracking.md; v2.1 normalized ScriptId per PF-PRO-032)
$soakScriptId = "scripts/update/Update-TechDebt.ps1"
$soakInSoak   = Test-ScriptInSoak -ScriptId $soakScriptId -ScriptPath $PSCommandPath

# --- ListDims handler (early exit) ---

if ($ListDims) {
    Write-Host "`nValid dimension codes for -Dims parameter:`n"
    Write-Host "  AC  — Architectural Consistency"
    Write-Host "  CQ  — Code Quality"
    Write-Host "  ID  — Integration Dependencies"
    Write-Host "  DA  — Documentation Alignment"
    Write-Host "  EM  — Extensibility & Maintainability"
    Write-Host "  SE  — Security & Data Protection"
    Write-Host "  PE  — Performance & Scalability"
    Write-Host "  OB  — Observability"
    Write-Host "  UX  — Accessibility / UX Compliance"
    Write-Host "  DI  — Data Integrity"
    Write-Host "  TST — Testing"
    Write-Host ""
    return
}

# --- Shared utilities ---

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

function Get-SectionHeaders {
    # Returns the column header array of the first markdown table inside the named ## section.
    # Empty array if section or table not found. Used to drive header-name → cell-index lookups
    # so column additions to either tracking table don't silently corrupt data (PF-IMP-006).
    param([Parameter(Mandatory)][string]$Content, [Parameter(Mandatory)][string]$Section)
    $lines = $Content -split "\r?\n"
    $inSection = $false
    foreach ($line in $lines) {
        if ($line -match "^$([regex]::Escape($Section))\s*$") { $inSection = $true; continue }
        if ($inSection -and $line -match '^## ') { break }
        if ($inSection -and $line -match '^\|.*\|$' -and $line -notmatch '^\|[\s\-:|]+\|$') {
            return Split-MarkdownTableRow $line
        }
    }
    return @()
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."

    if (-not (Test-Path $TargetFile)) {
        Write-Log "Target file not found: $TargetFile" -Level "ERROR"
        return $false
    }

    # Archive file (PF-IMP-873): required when the operation touches it.
    # Resolved / Rejected status moves and ResolvedUpdate edits read+write the archive.
    # AddNew, OpenEdit, and other StatusUpdates (Open / InProgress) don't touch the archive.
    $archiveRequired = $false
    if ($PSCmdlet.ParameterSetName -eq 'ResolvedUpdate') { $archiveRequired = $true }
    elseif ($PSCmdlet.ParameterSetName -eq 'StatusUpdate' -and $NewStatus -in @("Resolved", "Rejected")) { $archiveRequired = $true }

    if ($archiveRequired -and -not (Test-Path $ArchiveFile)) {
        Write-Log "Archive file not found: $ArchiveFile (required for Resolved/Rejected transitions per PF-IMP-873 archive-split). Create from blueprint or pass -ArchiveFile pointing at an existing archive." -Level "ERROR"
        return $false
    }

    if ($PSCmdlet.ParameterSetName -eq 'StatusUpdate') {
        if ($NewStatus -in @("Resolved", "Rejected") -and -not $ResolutionNotes) {
            Write-Log "ResolutionNotes is required when transitioning to $NewStatus" -Level "ERROR"
            return $false
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'OpenEdit') {
        if (-not $EditDescription -and -not $EditNotes) {
            Write-Log "At least one of -EditDescription or -EditNotes is required for OpenEdit mode" -Level "ERROR"
            return $false
        }
    }

    Write-Log "Prerequisites check passed" -Level "SUCCESS"
    return $true
}

# --- Content-transformer functions ---
# Each takes a $Content string and returns modified $Content string.
# Return $null to signal an error.

function Get-NextDebtId {
    <#
    .SYNOPSIS
    Gets the next available TD### ID by scanning content for existing IDs.

    PF-IMP-873 (2026-05-26): post-archive-split, the live file holds only Registry rows
    (Open / InProgress). Resolved/Rejected rows live in the archive. To avoid collisions,
    scan both files when -ArchiveContent is provided.
    #>
    param(
        [string]$Content,
        [string]$ArchiveContent
    )

    # Find all existing TD IDs across both live and archive content.
    # Matches both plain "| TD014 |" and linked "| [TD014](path) |" formats
    $tdPattern = 'TD(\d+)'
    $existingIds = @()

    foreach ($source in @($Content, $ArchiveContent)) {
        if (-not $source) { continue }
        $allMatches = [regex]::Matches($source, $tdPattern)
        foreach ($m in $allMatches) {
            $numericPart = [int]$m.Groups[1].Value
            if ($numericPart -gt 0) {
                $existingIds += $numericPart
            }
        }
    }

    # Find the highest number and increment
    if ($existingIds.Count -gt 0) {
        $maxId = ($existingIds | Sort-Object -Unique | Measure-Object -Maximum).Maximum
        $nextId = [int]$maxId + 1
    }
    else {
        $nextId = 1
    }

    $formattedId = "TD" + $nextId.ToString().PadLeft(3, '0')
    return $formattedId
}

function Add-NewDebtItemContent {
    <#
    .SYNOPSIS
    Content transformer that inserts a new debt item row into the Registry table
    #>
    param(
        [string]$Content,
        [string]$NewDebtId,
        [string]$Description,
        [string]$Dims,
        [string]$Location,
        [string]$Priority,
        [string]$EstimatedEffort,
        [string]$AssessmentId,
        [string]$Notes
    )

    $assessmentIdValue = if ($AssessmentId) { $AssessmentId } else { "-" }
    $notesValue = if ($Notes) { $Notes } else { "-" }

    # Build new table row using header-driven cell ordering (PF-IMP-006 — no hardcoded column count).
    # Unknown columns get '-' so future schema additions don't break the script.
    $registryHeaders = Get-SectionHeaders -Content $Content -Section "## Technical Debt Registry"
    if ($registryHeaders.Count -eq 0) {
        Write-Log "Could not parse Registry table header — cannot build new row" -Level "ERROR"
        return $null
    }
    $valueMap = @{
        'ID'               = $NewDebtId
        'Description'      = $Description
        'Dims'             = $Dims
        'Location'         = $Location
        'Created Date'     = $CurrentDate
        'Priority'         = $Priority
        'Estimated Effort' = $EstimatedEffort
        'Status'           = 'Open'
        'Resolution Date'  = '-'
        'Assessment ID'    = $assessmentIdValue
        'Workflows'        = '-'
        'Notes'            = $notesValue
    }
    $cells = @($registryHeaders | ForEach-Object { if ($valueMap.ContainsKey($_)) { $valueMap[$_] } else { '-' } })
    $newRow = ConvertTo-MarkdownTableRow -Cells $cells

    # Find the end of the Registry table
    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")
    $registryTableEnd = -1
    $foundRegistryHeading = $false
    $foundTableRows = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '## Technical Debt Registry') {
            $foundRegistryHeading = $true
            continue
        }

        if ($foundRegistryHeading -and $line -match '^\|.*\|$') {
            $foundTableRows = $true
            continue
        }

        # Once we've seen table rows, a non-table line means end of table
        if ($foundTableRows -and $line -notmatch '^\|.*\|$') {
            $registryTableEnd = $i
            break
        }
    }

    if ($registryTableEnd -eq -1) {
        Write-Log "Could not find end of Technical Debt Registry table" -Level "ERROR"
        return $null
    }

    # Insert the new row before the table end
    $lines.Insert($registryTableEnd, $newRow)

    Write-Log "Added new debt item $NewDebtId to Registry table" -Level "SUCCESS"
    return ($lines -join "`r`n")
}

function Add-OneDebtItem {
    <#
    .SYNOPSIS
    Adds one technical debt item to the registry, performing all per-item side-effects.

    .DESCRIPTION
    Encapsulates the read → mutate → write → verify → side-effects cycle for a single
    debt item. Used by both single-shot -Add mode and -BatchFile mode (PF-IMP-012) so
    the two modes share one code path and can never drift apart.

    Returns the assigned TD### ID on success, or $null on failure.
    #>
    param(
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][string]$Dims,
        [Parameter(Mandatory)][string]$Location,
        [Parameter(Mandatory)][string]$Priority,
        [Parameter(Mandatory)][string]$EstimatedEffort,
        [string]$AssessmentId = "",
        [string]$DebtItemId = "",
        [string]$Notes = "",
        [string[]]$ValidationIssueId = @()
    )

    $content = Get-Content $TargetFile -Raw
    # PF-IMP-873: read archive content too so Get-NextDebtId doesn't reuse
    # IDs that exist only in the archive after the split.
    $archiveContent = if (Test-Path $ArchiveFile) { Get-Content $ArchiveFile -Raw } else { $null }

    $newDebtId = Get-NextDebtId -Content $content -ArchiveContent $archiveContent
    Write-Log "Generated new debt ID: $newDebtId"

    $content = Add-NewDebtItemContent -Content $content -NewDebtId $newDebtId `
        -Description $Description -Dims $Dims -Location $Location `
        -Priority $Priority -EstimatedEffort $EstimatedEffort `
        -AssessmentId $AssessmentId -Notes $Notes
    if ($null -eq $content) {
        Write-Log "Failed to add new debt item to Registry table" -Level "ERROR"
        return $null
    }

    $content = Update-FrontmatterDate -Content $content
    Set-Content -Path $TargetFile -Value $content -NoNewline

    if (-not $WhatIfPreference) {
        # Link-aware pattern (PF-IMP-006): matches both `| TD006 |` and `| [TD006](path) |`
        $rowPattern = "\|\s*\[?" + [regex]::Escape($newDebtId) + "\b"
        Assert-LineInFile -Path $TargetFile -Pattern $rowPattern -Context "registry row for $newDebtId in $TargetFile"
    }

    if ($DebtItemId) {
        Update-DebtItemFile -DebtItemId $DebtItemId -RegistryId $newDebtId
    }

    if ($ValidationIssueId -and $ValidationIssueId.Count -gt 0) {
        $valFile = Find-ValidationTrackingFile
        if ($valFile) {
            foreach ($issueId in $ValidationIssueId) {
                Update-ValidationTrackingLink -ValidationIssueId $issueId -DebtId $newDebtId -TrackingFilePath $valFile
            }
        }
    }

    $descPreview = if ($Description.Length -gt 60) { $Description.Substring(0, 57) + "..." } else { $Description }
    Write-SummaryLine "$newDebtId added → $descPreview"

    return $newDebtId
}

function Update-DebtItemFile {
    <#
    .SYNOPSIS
    Updates a PF-TDI debt item document with the assigned TD### registry ID
    #>
    param(
        [string]$DebtItemId,
        [string]$RegistryId
    )

    $debtItemDir = Join-Path -Path (Get-ProcessFrameworkPath) -ChildPath "assessments/technical-debt/debt-items"
    $debtItemPattern = "*$DebtItemId*.md"
    $debtItemFiles = Get-ChildItem -Path $debtItemDir -Filter $debtItemPattern -ErrorAction SilentlyContinue

    if ($debtItemFiles.Count -eq 0) {
        Write-Log "Debt item file not found for ID: $DebtItemId" -Level "WARN"
        return
    }

    $debtItemFile = $debtItemFiles[0].FullName
    $content = Get-Content $debtItemFile -Raw

    # Update the Registry Integration section
    $updatedContent = $content -replace 'Registry Status: Not Added', 'Registry Status: Added'
    $updatedContent = $updatedContent -replace 'Registry ID: TBD', "Registry ID: $RegistryId"

    if ($PSCmdlet.ShouldProcess($debtItemFile, "Update debt item file with registry ID $RegistryId")) {
        Set-Content -Path $debtItemFile -Value $updatedContent -NoNewline
        Write-SummaryLine "Updated debt item file $DebtItemId with registry ID $RegistryId"
    }
}

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

    # Parse columns and update Status by header name (PF-IMP-006 — no hardcoded indices).
    $registryHeaders = Get-SectionHeaders -Content $Content -Section "## Technical Debt Registry"
    $statusIdx = [Array]::IndexOf($registryHeaders, 'Status')
    if ($statusIdx -lt 0) {
        Write-Log "Registry table missing 'Status' column" -Level "ERROR"
        return $null
    }
    $columns = Split-MarkdownTableRow $currentEntry
    $columns[$statusIdx] = $NewStatus
    $updatedEntry = ConvertTo-MarkdownTableRow -Cells $columns
    $result = $Content.Replace($currentEntry, $updatedEntry)

    Write-Log "Updated $DebtId status to: $NewStatus" -Level "SUCCESS"
    return $result
}

function Update-RegistryItem {
    <#
    .SYNOPSIS
    Replaces the Description and/or Notes column of an open debt item in the Registry table.
    Section-restricted to ## Technical Debt Registry (will not match resolved items).
    Returns $null if the item is not found in the Registry.
    #>
    param(
        [string]$Content,
        [string]$DebtId,
        [string]$EditDescription,
        [string]$EditNotes
    )

    $lines = [System.Collections.ArrayList]@($Content -split "\r?\n")

    $rowIndex = -1
    $inRegistrySection = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## Technical Debt Registry") { $inRegistrySection = $true; continue }
        # PF-IMP-873: post-archive-split, the live file has no "## Recently Resolved" section.
        # Stop scanning when we leave the Registry section by hitting any subsequent ## heading.
        if ($inRegistrySection -and $lines[$i] -match "^## ") { break }
        if ($inRegistrySection -and $lines[$i] -match "^\|\s*(?:\[)?$DebtId(?:\]|\s*\|)") {
            $rowIndex = $i
            break
        }
    }

    if ($rowIndex -eq -1) {
        Write-Log "Could not find $DebtId in ## Technical Debt Registry. For items in the archive (## Resolved or ## Rejected), use -Section 'Resolved' -ResolvedDebtId $DebtId -UpdateNotes." -Level "ERROR"
        return $null
    }

    # Update columns by header name (PF-IMP-006 — fixes -EditNotes silently writing to Workflows
    # column when the live Registry header has 12 columns instead of the historical 11).
    $registryHeaders = Get-SectionHeaders -Content ($lines -join "`r`n") -Section "## Technical Debt Registry"
    $row = $lines[$rowIndex]
    $columns = Split-MarkdownTableRow $row

    $changes = @()
    if ($EditDescription) {
        $idx = [Array]::IndexOf($registryHeaders, 'Description')
        if ($idx -lt 0) { Write-Log "Registry table missing 'Description' column" -Level "ERROR"; return $null }
        $columns[$idx] = $EditDescription
        $changes += 'Description'
    }
    if ($EditNotes) {
        $idx = [Array]::IndexOf($registryHeaders, 'Notes')
        if ($idx -lt 0) { Write-Log "Registry table missing 'Notes' column" -Level "ERROR"; return $null }
        $columns[$idx] = $EditNotes
        $changes += 'Notes'
    }

    $updatedRow = ConvertTo-MarkdownTableRow -Cells $columns
    $lines[$rowIndex] = $updatedRow

    Write-Log "Updated $DebtId in Registry: $($changes -join ' + ') replaced" -Level "SUCCESS"
    return ($lines -join "`r`n")
}

function Move-ToArchiveSection {
    # PF-IMP-873 (2026-05-26): two-file archive-split successor to Move-ToResolvedSection.
    # Source = $Content (live ## Technical Debt Registry); destination = $ArchiveContent
    # (## Resolved for status=Resolved, ## Rejected for status=Rejected).
    # Returns @{ Content; ArchiveContent } or $null on failure.
    #
    # Historical note (PF-IMP-006): refactored to use Move-MarkdownTableRow with header-driven
    # column mapping. Earlier implementations hardcoded $columns[10]=Notes, which silently
    # moved the Workflows value into the destination Notes column when the live Registry header
    # grew to 12 columns. Mapping is now by name — schema additions in either table can no
    # longer corrupt the move.
    param(
        [string]$Content,
        [string]$ArchiveContent,
        [string]$DebtId,
        [string]$ResolutionNotes,
        [string]$PlanLink,
        [Parameter(Mandatory)][ValidateSet("Resolved", "Rejected")]
        [string]$Disposition
    )

    # Read source row first (need original Notes to compute appended-notes value).
    # ConvertFrom-MarkdownTable scoped to ## Technical Debt Registry — keeps the
    # "use Resolved/Rejected path" hint accurate when the ID is in the wrong section.
    $registryRows = ConvertFrom-MarkdownTable -Content $Content -Section "## Technical Debt Registry"
    $sourceRow = $registryRows | Where-Object { (Get-MarkdownLinkText $_.ID) -eq $DebtId } | Select-Object -First 1
    if (-not $sourceRow) {
        Write-Log "Could not find $DebtId in Registry table" -Level "ERROR"
        return $null
    }

    # Validate and normalize PlanLink (PF-IMP-620: prevent silent ID-column corruption).
    # Accept either a complete markdown link [<DebtId>](path) or a bare path (auto-wrapped).
    if ($PlanLink) {
        # MSYS path-mangling guard routed through Common-ScriptHelpers (PF-IMP-767 helper extraction).
        if (Test-MSYSPathMangled -Path $PlanLink -ParameterName 'PlanLink') {
            return $null
        }
        if ($PlanLink -match "^\[$DebtId\]\(.+\)$") {
            $idValue = $PlanLink
        }
        elseif ($PlanLink -notmatch '^\[' -and $PlanLink -match '[/\\]') {
            $idValue = "[$DebtId]($PlanLink)"
        }
        else {
            Write-Log "PlanLink format invalid: '$PlanLink'. Expected either '[$DebtId](path/to/plan.md)' or a bare path 'path/to/plan.md'." -Level "ERROR"
            return $null
        }
    }
    else {
        $idValue = $DebtId
    }

    # Append resolution notes to existing notes (preserves original Notes).
    $existingNotes = $sourceRow.Notes
    $finalNotes = if ($ResolutionNotes) {
        if ($existingNotes -and $existingNotes -ne '-') { "$existingNotes $ResolutionNotes" } else { $ResolutionNotes }
    } else {
        $existingNotes
    }

    # Destination section depends on disposition (dual-section archive per PF-IMP-873).
    $destinationSection = if ($Disposition -eq "Resolved") { "## Resolved" } else { "## Rejected" }

    # Column mapping: live Registry → archive section. The archive's Resolved and Rejected
    # tables share the same column shape so one mapping works for both.
    $columnMapping = [ordered]@{
        'ID'              = 'ID'
        'Description'     = 'Description'
        'Category'        = 'Dims'
        'Location'        = 'Location'
        'Created Date'    = 'Created Date'
        'Priority'        = 'Priority'
        'Resolution Date' = 'Resolution Date'
        'Assessment ID'   = 'Assessment ID'
        'Notes'           = 'Notes'
    }
    $additionalColumns = [ordered]@{
        'ID'              = $idValue
        'Resolution Date' = $CurrentDate
        'Notes'           = $finalNotes
    }
    # Pattern matches both bare `TD006` and link-wrapped `[TD006](path)` first-cell forms.
    $rowIdPattern = "\[?$DebtId\]?(?:\(.*?\))?"

    # Two-file Move-MarkdownTableRow: live → archive.
    $moveResult = Move-MarkdownTableRow `
        -Content $Content `
        -DestinationContent $ArchiveContent `
        -RowIdPattern $rowIdPattern `
        -SourceSection '## Technical Debt Registry' `
        -DestinationSection $destinationSection `
        -ColumnMapping $columnMapping `
        -AdditionalColumns $additionalColumns `
        -SectionEndPattern '^## '

    if ($null -eq $moveResult.Content) {
        Write-Log "Failed to move $DebtId to archive $destinationSection section" -Level "ERROR"
        return $null
    }

    Write-Log "Moved $DebtId from Registry to archive ($destinationSection)" -Level "SUCCESS"
    return @{
        Content        = $moveResult.Content
        ArchiveContent = $moveResult.DestinationContent
    }
}

function Find-ValidationTrackingFile {
    <#
    .SYNOPSIS
    Auto-discovers the active validation tracking file from the standard directory.
    Returns $null if not found.
    #>
    $valDir = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/validation"
    if (-not (Test-Path $valDir)) {
        Write-Log "Validation tracking directory not found: $valDir" -Level "WARN"
        return $null
    }

    # Find validation-tracking*.md files excluding archive directory
    $valFiles = Get-ChildItem -Path $valDir -Filter "validation-tracking*.md" -File -ErrorAction SilentlyContinue
    if ($valFiles.Count -eq 0) {
        Write-Log "No validation tracking file found in $valDir" -Level "WARN"
        return $null
    }

    # If multiple files, pick the one with the highest number suffix
    $selected = $valFiles | Sort-Object Name -Descending | Select-Object -First 1
    Write-Log "Auto-discovered validation tracking file: $($selected.Name)"
    return $selected.FullName
}

function Update-ValidationTrackingLink {
    <#
    .SYNOPSIS
    Writes a TD### ID into the "Tracked As" column of a validation issue row.
    Used when adding new debt items linked to validation issues.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ValidationIssueId,
        [string]$DebtId,
        [string]$TrackingFilePath
    )

    $content = Get-Content $TrackingFilePath -Raw
    $lines = [System.Collections.ArrayList]@($content -split "\r?\n")

    # Find the row matching the validation issue ID in Critical Issues Tracking section
    # Table columns: | Issue ID | Feature | Validation Type | Severity | Description | Status | Tracked As | Assigned Session |
    $inCriticalSection = $false
    $rowIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '## Critical Issues Tracking') { $inCriticalSection = $true; continue }
        if ($inCriticalSection -and $lines[$i] -match '^## (?!Critical Issues Tracking)') { break }
        if ($inCriticalSection -and $lines[$i] -match "^\|\s*$ValidationIssueId\s*\|") {
            $rowIndex = $i
            break
        }
    }

    if ($rowIndex -eq -1) {
        Write-Log "$ValidationIssueId not found in validation tracking Critical Issues Tracking — skipping" -Level "WARN"
        return
    }

    # Parse the row and update the "Tracked As" column (index 6)
    $row = $lines[$rowIndex]
    $columns = $row -split '\|' | ForEach-Object { $_.Trim() }
    if ($columns[0] -eq '') { $columns = $columns[1..($columns.Length - 1)] }
    if ($columns[-1] -eq '') { $columns = $columns[0..($columns.Length - 2)] }

    $columns[6] = $DebtId
    $updatedRow = "| " + ($columns -join " | ") + " |"
    $lines[$rowIndex] = $updatedRow

    $updatedContent = ($lines -join "`r`n")
    $updatedContent = $updatedContent -replace '(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate

    if ($PSCmdlet.ShouldProcess($TrackingFilePath, "Link $ValidationIssueId to $DebtId in Tracked As column")) {
        Set-Content -Path $TrackingFilePath -Value $updatedContent -NoNewline
        Write-SummaryLine "Linked $ValidationIssueId → $DebtId in $($TrackingFilePath | Split-Path -Leaf)"
    }
}

function Update-ValidationTracking {
    <#
    .SYNOPSIS
    Updates a validation issue row when resolving a linked tech debt item.
    Searches by ValidationIssueId in the "Issue ID" column (preferred) or by DebtId
    in the "Tracked As" column (fallback), then sets Status to RESOLVED
    and Assigned Session to the provided note.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$DebtId,
        [string]$ValidationNote,
        [string]$TrackingFilePath,
        [string]$ValidationIssueId
    )

    $content = Get-Content $TrackingFilePath -Raw
    $lines = [System.Collections.ArrayList]@($content -split "\r?\n")

    # Find the row in Critical Issues Tracking:
    # - If ValidationIssueId is provided, match on Issue ID column (index 0)
    # - Otherwise, fall back to searching "Tracked As" column for DebtId
    # Table columns: | Issue ID | Feature | Validation Type | Severity | Description | Status | Tracked As | Assigned Session |
    $inCriticalSection = $false
    $rowIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '## Critical Issues Tracking') { $inCriticalSection = $true; continue }
        if ($inCriticalSection -and $lines[$i] -match '^## (?!Critical Issues Tracking)') { break }
        if ($ValidationIssueId) {
            # Match on Issue ID column (first column after leading pipe)
            if ($inCriticalSection -and $lines[$i] -match "^\|\s*$([regex]::Escape($ValidationIssueId))\s*\|") {
                $rowIndex = $i
                break
            }
        } else {
            # Fall back to matching DebtId anywhere in the row (Tracked As column)
            if ($inCriticalSection -and $lines[$i] -match "^\|.*\b$DebtId\b.*\|") {
                $rowIndex = $i
                break
            }
        }
    }

    if ($rowIndex -eq -1) {
        $searchDesc = if ($ValidationIssueId) { "$ValidationIssueId in Issue ID column" } else { "$DebtId in Tracked As column" }
        Write-Log "$searchDesc not found in validation tracking — skipping" -Level "WARN"
        return
    }

    # Parse the row and update Status (index 5) and Assigned Session (index 7)
    $row = $lines[$rowIndex]
    $columns = $row -split '\|' | ForEach-Object { $_.Trim() }
    if ($columns[0] -eq '') { $columns = $columns[1..($columns.Length - 1)] }
    if ($columns[-1] -eq '') { $columns = $columns[0..($columns.Length - 2)] }

    $columns[5] = "RESOLVED"
    $columns[7] = $ValidationNote
    $updatedRow = "| " + ($columns -join " | ") + " |"
    $lines[$rowIndex] = $updatedRow

    # Update frontmatter date
    $updatedContent = ($lines -join "`r`n")
    $updatedContent = $updatedContent -replace '(?<=^updated:\s*)\d{4}-\d{2}-\d{2}', $CurrentDate

    if ($PSCmdlet.ShouldProcess($TrackingFilePath, "Update $DebtId status to RESOLVED with note '$ValidationNote'")) {
        Set-Content -Path $TrackingFilePath -Value $updatedContent -NoNewline
        Write-SummaryLine "Updated $DebtId in $($TrackingFilePath | Split-Path -Leaf): RESOLVED — $ValidationNote"
    }
}

function Update-ResolvedNotes {
    <#
    .SYNOPSIS
    Updates the Notes column of a debt item that has been archived (post-PF-IMP-873).

    Scans BOTH ## Resolved and ## Rejected sections in the archive — the operation
    is meaningful for either disposition (a follow-up note on a rejected item is just
    as valid as a follow-up note on a resolved item).
    #>
    param(
        [string]$ArchiveContent,
        [string]$DebtId,
        [string]$UpdateNotes
    )

    $lines = [System.Collections.ArrayList]@($ArchiveContent -split "\r?\n")

    # Find the debt item row in either archive section (Resolved or Rejected).
    $rowIndex = -1
    $hostSection = $null
    $currentSection = $null
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## (Resolved|Rejected)\s*$') {
            $currentSection = "## $($Matches[1])"
            continue
        }
        if ($currentSection -and $lines[$i] -match "^\|\s*(?:\[)?$DebtId(?:\]|\s*\|)") {
            $rowIndex = $i
            $hostSection = $currentSection
            break
        }
    }

    if ($rowIndex -eq -1) {
        Write-Log "Could not find $DebtId in archive (neither ## Resolved nor ## Rejected)" -Level "ERROR"
        return $null
    }

    # Update the Notes column by header name (PF-IMP-006 — header-driven for resilience).
    $archiveHeaders = Get-SectionHeaders -Content ($lines -join "`r`n") -Section $hostSection
    $notesIdx = [Array]::IndexOf($archiveHeaders, 'Notes')
    if ($notesIdx -lt 0) {
        Write-Log "Archive table ($hostSection) missing 'Notes' column" -Level "ERROR"
        return $null
    }
    $row = $lines[$rowIndex]
    $columns = Split-MarkdownTableRow $row
    $currentNotes = $columns[$notesIdx]
    if ($currentNotes -and $currentNotes -ne '-') {
        $columns[$notesIdx] = "$currentNotes $UpdateNotes"
    }
    else {
        $columns[$notesIdx] = $UpdateNotes
    }

    $updatedRow = ConvertTo-MarkdownTableRow -Cells $columns
    $lines[$rowIndex] = $updatedRow

    Write-Log "Updated notes for $DebtId in archive $hostSection section" -Level "SUCCESS"
    return ($lines -join "`r`n")
}

# --- Main ---

function Main {
    Write-Log "Starting Technical Debt Update - $ScriptName"

    if ($PSCmdlet.ParameterSetName -eq 'AddNew') {
        Write-Log "Operation: Add new debt item"
        Write-Log "Description: $Description"
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Batch') {
        Write-Log "Operation: Batch add debt items from $BatchFile"
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'ResolvedUpdate') {
        Write-Log "Operation: Update resolved item notes"
        Write-Log "Debt ID: $ResolvedDebtId"
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'OpenEdit') {
        Write-Log "Operation: In-place edit of open debt item"
        Write-Log "Debt ID: $DebtId"
    }
    else {
        Write-Log "Operation: Status update"
        Write-Log "Debt ID: $DebtId"
        Write-Log "New Status: $NewStatus"
    }

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    if ($PSCmdlet.ParameterSetName -eq 'AddNew') {
        # --- Add new debt item (single) ---
        if (-not $PSCmdlet.ShouldProcess($TargetFile, "Add new debt item: $Description")) {
            return
        }
        $valIds = if ($ValidationIssueId) { $ValidationIssueId } else { @() }
        $newId = Add-OneDebtItem `
            -Description $Description -Dims $Dims -Location $Location `
            -Priority $Priority -EstimatedEffort $EstimatedEffort `
            -AssessmentId $AssessmentId -DebtItemId $DebtItemId `
            -Notes $Notes -ValidationIssueId $valIds
        if (-not $newId) { exit 1 }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Batch') {
        # --- Batch add debt items from JSON file (PF-IMP-012) ---
        try {
            $jsonContent = Get-Content -Path $BatchFile -Raw -Encoding UTF8
            $items = $jsonContent | ConvertFrom-Json
        }
        catch {
            Write-ProjectError -Message "Failed to parse batch file '$BatchFile': $($_.Exception.Message)" -ExitCode 1
        }

        # Coerce single-object JSON to array of one (defensive — IMP shape says array but be lenient)
        if ($items -isnot [System.Array]) {
            $items = @($items)
        }

        if ($items.Count -eq 0) {
            Write-Host "Batch file contained no items — nothing to add." -ForegroundColor Yellow
            return
        }

        Write-Host "Batch mode: processing $($items.Count) debt item(s) from $BatchFile" -ForegroundColor Magenta

        # Validate every item upfront. No state mutation if any item fails.
        $validDimsList    = @("AC", "CQ", "ID", "DA", "EM", "SE", "PE", "OB", "UX", "DI", "TST", "AIC")
        $validPriorities  = @("Critical", "High", "Medium", "Low")
        for ($idx = 0; $idx -lt $items.Count; $idx++) {
            $item = $items[$idx]
            $errors = @()
            if (-not $item.Description)      { $errors += "missing Description" }
            if (-not $item.Location)         { $errors += "missing Location" }
            if (-not $item.EstimatedEffort)  { $errors += "missing EstimatedEffort" }
            if (-not $item.Dims) {
                $errors += "missing Dims"
            } else {
                $tokens = $item.Dims -split '[\s,]+' | Where-Object { $_ -ne '' }
                $invalidDims = @($tokens | Where-Object { $_ -notin $validDimsList })
                if ($invalidDims.Count -gt 0) {
                    $errors += "invalid Dims code(s) [$($invalidDims -join ', ')] (valid: $($validDimsList -join ', '))"
                }
            }
            if (-not $item.Priority) {
                $errors += "missing Priority"
            } elseif ($item.Priority -notin $validPriorities) {
                $errors += "invalid Priority '$($item.Priority)' (must be one of: $($validPriorities -join ', '))"
            }
            if ($errors.Count -gt 0) {
                Write-ProjectError -Message "Batch item [$idx]: $($errors -join '; ') — no items added" -ExitCode 1
            }
        }

        if (-not $PSCmdlet.ShouldProcess($TargetFile, "Add $($items.Count) debt item(s) from batch file")) {
            return
        }

        $created = @()
        foreach ($item in $items) {
            # JSON arrays of strings deserialize as arrays; single string deserializes as string.
            # Normalize ValidationIssueId to a string array to satisfy Add-OneDebtItem's signature.
            $valIds = @()
            if ($item.ValidationIssueId) {
                if ($item.ValidationIssueId -is [System.Array]) { $valIds = @($item.ValidationIssueId) }
                else { $valIds = @($item.ValidationIssueId) }
            }
            $newId = Add-OneDebtItem `
                -Description $item.Description -Dims $item.Dims -Location $item.Location `
                -Priority $item.Priority -EstimatedEffort $item.EstimatedEffort `
                -AssessmentId $(if ($item.AssessmentId) { $item.AssessmentId } else { "" }) `
                -DebtItemId $(if ($item.DebtItemId) { $item.DebtItemId } else { "" }) `
                -Notes $(if ($item.Notes) { $item.Notes } else { "" }) `
                -ValidationIssueId $valIds
            if ($newId) { $created += $newId }
        }

        Write-Host "========================================" -ForegroundColor Magenta
        Write-SummaryLine "Batch complete: $($created.Count)/$($items.Count) debt items added"
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'ResolvedUpdate') {
        # --- Update notes on archived item (PF-IMP-873: archive-split) ---
        # Reads/writes the archive file directly; the live tracking file is untouched
        # except for its frontmatter date.
        $archiveContent = Get-Content $ArchiveFile -Raw

        $archiveContent = Update-ResolvedNotes -ArchiveContent $archiveContent -DebtId $ResolvedDebtId -UpdateNotes $UpdateNotes
        if ($null -eq $archiveContent) {
            Write-Log "Failed to update notes for $ResolvedDebtId in archive" -Level "ERROR"
            exit 1
        }

        # Bump frontmatter date on both files: archive (changed content) and live (audit trail
        # that the tracking ecosystem touched today, matching the PI-tracking pattern).
        $archiveContent = Update-FrontmatterDate -Content $archiveContent
        $content = Get-Content $TargetFile -Raw
        $content = Update-FrontmatterDate -Content $content

        if ($PSCmdlet.ShouldProcess($ArchiveFile, "Update notes for $ResolvedDebtId in archive")) {
            Set-Content -Path $ArchiveFile -Value $archiveContent -NoNewline
            Set-Content -Path $TargetFile -Value $content -NoNewline

            # Read-after-write verification: confirm the row exists in archive
            if (-not $WhatIfPreference) {
                # Link-aware pattern (PF-IMP-006): matches both `| TD006 |` and `| [TD006](path) |`
                $rowPattern = "\|\s*\[?" + [regex]::Escape($ResolvedDebtId) + "\b"
                Assert-LineInFile -Path $ArchiveFile -Pattern $rowPattern -Context "archived row for $ResolvedDebtId in $ArchiveFile"
            }

            Write-SummaryLine "$ResolvedDebtId notes appended in archive"
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'OpenEdit') {
        # --- In-place edit of Description and/or Notes for an open Registry item ---
        $content = Get-Content $TargetFile -Raw

        $content = Update-RegistryItem -Content $content -DebtId $DebtId -EditDescription $EditDescription -EditNotes $EditNotes
        if ($null -eq $content) {
            Write-Log "Failed to edit $DebtId in Registry" -Level "ERROR"
            exit 1
        }

        $content = Update-FrontmatterDate -Content $content

        $changedFields = @()
        if ($EditDescription) { $changedFields += 'Description' }
        if ($EditNotes)       { $changedFields += 'Notes' }
        $changeSummary = $changedFields -join '+'

        if ($PSCmdlet.ShouldProcess($TargetFile, "Edit $changeSummary for $DebtId in Registry")) {
            Set-Content -Path $TargetFile -Value $content -NoNewline

            # Read-after-write verification: confirm the debt row still exists in Registry
            if (-not $WhatIfPreference) {
                # Link-aware pattern (PF-IMP-006): matches both `| TD006 |` and `| [TD006](path) |`
                $rowPattern = "\|\s*\[?" + [regex]::Escape($DebtId) + "\b"
                Assert-LineInFile -Path $TargetFile -Pattern $rowPattern -Context "registry row for $DebtId in $TargetFile"
            }

            Write-SummaryLine "$DebtId → $changeSummary edited in Registry"
        }
    }
    else {
        # --- Status update ---

        # Read live; archive only when needed (PF-IMP-873: two-file mode for Resolved/Rejected).
        $content = Get-Content $TargetFile -Raw
        $isResolution = $NewStatus -in @("Resolved", "Rejected")
        $archiveContent = $null
        if ($isResolution) {
            $archiveContent = Get-Content $ArchiveFile -Raw
        }

        if ($isResolution) {
            # Move row from live Registry to archive ## Resolved or ## Rejected (PF-IMP-873)
            $moveResult = Move-ToArchiveSection -Content $content -ArchiveContent $archiveContent -DebtId $DebtId -ResolutionNotes $ResolutionNotes -PlanLink $PlanLink -Disposition $NewStatus
            if ($null -eq $moveResult) {
                Write-Log "Failed to move $DebtId to archive ## $NewStatus section" -Level "ERROR"
                exit 1
            }
            $content = $moveResult.Content
            $archiveContent = $moveResult.ArchiveContent
        }
        else {
            # Status-only update in Registry table
            $content = Update-StatusInPlace -Content $content -DebtId $DebtId -NewStatus $NewStatus
            if ($null -eq $content) {
                Write-Log "Failed to update $DebtId status" -Level "ERROR"
                exit 1
            }
        }

        # Update frontmatter date on both files (when applicable)
        $content = Update-FrontmatterDate -Content $content
        if ($isResolution) {
            $archiveContent = Update-FrontmatterDate -Content $archiveContent
        }

        # Write tech debt tracking file(s) (guarded by ShouldProcess for -WhatIf support)
        $wroteFile = $false
        if ($PSCmdlet.ShouldProcess($TargetFile, "Update $DebtId to $NewStatus")) {
            Set-Content -Path $TargetFile -Value $content -NoNewline
            if ($isResolution) {
                Set-Content -Path $ArchiveFile -Value $archiveContent -NoNewline
            }
            $wroteFile = $true

            # Read-after-write verification: confirm the debt row exists where it should be
            if (-not $WhatIfPreference) {
                # Link-aware pattern (PF-IMP-006): matches both `| TD006 |` and `| [TD006](path) |`
                $rowPattern = "\|\s*\[?" + [regex]::Escape($DebtId) + "\b"
                $verifyFile = if ($isResolution) { $ArchiveFile } else { $TargetFile }
                Assert-LineInFile -Path $verifyFile -Pattern $rowPattern -Context "debt row for $DebtId in $verifyFile"
            }
        }

        # Update validation tracking if ValidationNote is provided
        # (has its own ShouldProcess guard internally)
        if ($isResolution -and $ValidationNote) {
            $valFile = Find-ValidationTrackingFile
            if ($valFile) {
                if ($ValidationIssueId) {
                    # Loop over each validation issue ID (supports secondary findings)
                    foreach ($issueId in $ValidationIssueId) {
                        $valParams = @{
                            DebtId           = $DebtId
                            ValidationNote   = $ValidationNote
                            TrackingFilePath = $valFile
                            ValidationIssueId = $issueId
                        }
                        Update-ValidationTracking @valParams
                    }
                } else {
                    $valParams = @{
                        DebtId           = $DebtId
                        ValidationNote   = $ValidationNote
                        TrackingFilePath = $valFile
                    }
                    Update-ValidationTracking @valParams
                }
            }
        }

        if ($wroteFile) {
            $outcome = if ($isResolution) { "$NewStatus (moved to archive)" } else { $NewStatus }
            Write-SummaryLine "$DebtId → $outcome"
        }
    }
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
    Write-ProjectError -Message "Tech Debt update failed: $($_.Exception.Message)" -ExitCode 1
}
