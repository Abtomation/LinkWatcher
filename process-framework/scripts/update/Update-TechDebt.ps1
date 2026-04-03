#!/usr/bin/env pwsh

<#
.SYNOPSIS
Automates technical debt lifecycle management in the Technical Debt Tracker state file

.DESCRIPTION
This script automates debt item lifecycle management in technical-debt-tracking.md.
Optionally updates the validation tracking file when resolving or adding debt items
tracked in validation (via -ValidationNote and -ValidationIssueId parameters).

Supports three operation modes:
1. Add new debt item: Generates next TD### ID, inserts row into Registry table, optionally
   updates the associated PF-TDI debt item file with the assigned ID
2. Status-only update: Changes Status and Resolution Date columns in the Registry table
3. Completion (Resolved): Moves debt item from Registry to "Recently Resolved" section,
   drops Estimated Effort and Status columns, sets Resolution Date, updates frontmatter date

Registry table columns (11):
  | ID | Description | Dims | Location | Created Date | Priority | Estimated Effort | Status | Resolution Date | Assessment ID | Notes |
  idx: 0     1            2          3          4               5          6                  7        8                 9               10

Recently Resolved table columns (9):
  | ID | Description | Category | Location | Created Date | Priority | Resolution Date | Assessment ID | Notes |
  idx: 0     1            2          3          4               5          6                 7               8

.PARAMETER Add
Switch to add a new debt item. Auto-generates the next TD### ID.

.PARAMETER Description
Description of the technical debt item (required for Add).

.PARAMETER Dims
Dimension abbreviation(s) for the debt item (required for Add). Space-separated if multiple.
Valid values: AC, CQ, ID, DA, EM, SE, PE, OB, UX, DI, TST
See Development Dimensions Guide for definitions.

.PARAMETER Location
Location/path where the debt exists (required for Add). E.g., "linkwatcher/parsers/"

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

.PARAMETER DebtId
The technical debt ID to update (e.g., "TD005"). Required for status updates.

.PARAMETER NewStatus
The new status. Valid values: Open, InProgress, Resolved, Rejected. Required for status updates.
Rejected items are moved to the Recently Resolved section (same as Resolved) with their rejection rationale preserved in the Notes column.

.PARAMETER ResolutionNotes
Description of what was done. Required when NewStatus is Resolved or Rejected.
Appended to the Notes column in the Recently Resolved table.

.PARAMETER PlanLink
Optional markdown link to the refactoring plan (e.g., "[TD006](/doc/refactoring/plans/archive/td006.md)").
When provided, replaces the plain ID in the Recently Resolved table.

.PARAMETER ValidationNote
Optional status text for the validation tracking file's issue tables.
When provided (and NewStatus is Resolved), finds the row whose "Tracked As" column contains
the DebtId and updates Status to "RESOLVED" and Assigned Session to this note.
The validation tracking file is auto-discovered from doc/state-tracking/validation/.
Example: "PD-REF-042 — docstring added documenting precedence order"

.PARAMETER ValidationIssueId
Optional validation issue ID (e.g., "R2-M-005", "OB-R3-004") to link a debt item to a validation tracking row.
On -Add: writes the newly assigned TD### into the "Tracked As" column of the matching issue row.
On Resolve/Reject (with -ValidationNote): searches by this ID in the "Issue ID" column instead of
searching by DebtId in "Tracked As" column. Use this when the validation issue was tracked under a
non-TD ID (e.g., OB-R3-004) that differs from the TD### registry ID.
The validation tracking file is auto-discovered from doc/state-tracking/validation/.

.EXAMPLE
# Add a new debt item
.\Update-TechDebt.ps1 -Add -Description "Missing error handling in parser" -Dims "CQ" -Location "linkwatcher/parsers/" -Priority "Medium" -EstimatedEffort "2 hours"

.EXAMPLE
# Add a new debt item with assessment and debt item links
.\Update-TechDebt.ps1 -Add -Description "Missing Repository Pattern" -Dims "AC" -Location "lib/services/" -Priority "Critical" -EstimatedEffort "1-2 weeks" -AssessmentId "PF-TDA-001" -DebtItemId "PF-TDI-001"

.EXAMPLE
# Mark debt item as in progress
.\Update-TechDebt.ps1 -DebtId "TD005" -NewStatus "InProgress"

.EXAMPLE
# Resolve a debt item
.\Update-TechDebt.ps1 -DebtId "TD011" -NewStatus "Resolved" -ResolutionNotes "Replaced bare except: with except Exception:"

.EXAMPLE
# Reject a debt item (Won't Fix)
.\Update-TechDebt.ps1 -DebtId "TD064" -NewStatus "Rejected" -ResolutionNotes "Rejected: All decisions are module-local and already documented via inline comments."

.EXAMPLE
# Resolve with plan link
.\Update-TechDebt.ps1 -DebtId "TD006" -NewStatus "Resolved" -ResolutionNotes "Extracted public API methods." -PlanLink "[TD006](../../../doc/refactoring/plans/archive/td006-encapsulation-violation-fix.md)"

.EXAMPLE
# Add a new debt item linked to a validation issue (auto-fills "Tracked As" column)
.\Update-TechDebt.ps1 -Add -Description "Missing ADR for decisions" -Dims "AC" -Location "linkwatcher/validator.py" -Priority "Medium" -EstimatedEffort "2 hours" -ValidationIssueId "R2-M-001"

.EXAMPLE
# Resolve with validation tracking update (auto-discovers validation-tracking file)
.\Update-TechDebt.ps1 -DebtId "TD022" -NewStatus "Resolved" -ResolutionNotes "Extracted ReferenceLookup class" -ValidationNote "PD-REF-042 — reduced to 681 LOC"

.EXAMPLE
# Resolve with validation tracking update when issue ID differs from TD ID
.\Update-TechDebt.ps1 -DebtId "TD144" -NewStatus "Resolved" -ResolutionNotes "Added structured logging" -ValidationNote "Session 16 — logging added" -ValidationIssueId "OB-R3-004"

.EXAMPLE
# List valid dimension codes and descriptions
.\Update-TechDebt.ps1 -ListDims

.NOTES
This script is part of the Technical Debt automation system and integrates with:
- Code Refactoring Task (PF-TSK-022)
- Technical Debt Assessment Task (PF-TSK-023)
- Validation Tasks (PF-TSK-031 through PF-TSK-036)
- New-DebtItem.ps1

Updates the following files:
- doc/state-tracking/permanent/technical-debt-tracking.md (always)
- Validation tracking file (auto-discovered, when -ValidationNote or -ValidationIssueId are provided)
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'StatusUpdate')]
param(
    # --- AddNew parameter set ---
    [Parameter(Mandatory = $true, ParameterSetName = 'AddNew')]
    [switch]$Add,

    [Parameter(Mandatory = $true, ParameterSetName = 'AddNew')]
    [string]$Description,

    [Parameter(Mandatory = $true, ParameterSetName = 'AddNew')]
    [ValidateSet("AC", "CQ", "ID", "DA", "EM", "SE", "PE", "OB", "UX", "DI", "TST")]
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

    # --- StatusUpdate parameter set ---
    [Parameter(Mandatory = $true, ParameterSetName = 'StatusUpdate')]
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
    [string]$ValidationIssueId,

    # --- ListDims parameter set ---
    [Parameter(Mandatory = $true, ParameterSetName = 'ListDims')]
    [switch]$ListDims
)

# --- Configuration ---

$dir = $PSScriptRoot
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force

$ProjectRoot = Get-ProjectRoot
$TargetFile = Join-Path -Path $ProjectRoot -ChildPath "doc/state-tracking/permanent/technical-debt-tracking.md"
$ScriptName = "Update-TechDebt.ps1"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

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

    if ($PSCmdlet.ParameterSetName -eq 'StatusUpdate') {
        if ($NewStatus -in @("Resolved", "Rejected") -and -not $ResolutionNotes) {
            Write-Log "ResolutionNotes is required when transitioning to $NewStatus" -Level "ERROR"
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
    Gets the next available TD### ID by scanning content for existing IDs
    #>
    param([string]$Content)

    # Find all existing TD IDs across both registry and resolved sections
    # Matches both plain "| TD014 |" and linked "| [TD014](path) |" formats
    $tdPattern = 'TD(\d{3})'
    $allMatches = [regex]::Matches($Content, $tdPattern)

    $existingIds = @()
    foreach ($m in $allMatches) {
        $numericPart = [int]$m.Groups[1].Value
        if ($numericPart -gt 0) {
            $existingIds += $numericPart
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

    # Build new table row (11 columns: ID, Description, Dims, Location, Created Date, Priority, Estimated Effort, Status, Resolution Date, Assessment ID, Notes)
    $newRow = "| $NewDebtId | $Description | $Dims | $Location | $CurrentDate | $Priority | $EstimatedEffort | Open | - | $assessmentIdValue | $notesValue |"

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

function Update-DebtItemFile {
    <#
    .SYNOPSIS
    Updates a PF-TDI debt item document with the assigned TD### registry ID
    #>
    param(
        [string]$DebtItemId,
        [string]$RegistryId
    )

    $debtItemDir = Join-Path -Path $ProjectRoot -ChildPath "process-framework/assessments/technical-debt/debt-items"
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
        Write-Log "Updated debt item file $DebtItemId with registry ID $RegistryId" -Level "SUCCESS"
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
        Write-Log "Linked $ValidationIssueId → $DebtId in $($TrackingFilePath | Split-Path -Leaf)" -Level "SUCCESS"
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
        Write-Log "Updated $DebtId in $($TrackingFilePath | Split-Path -Leaf): RESOLVED — $ValidationNote" -Level "SUCCESS"
    }
}

# --- Main ---

function Main {
    Write-Log "Starting Technical Debt Update - $ScriptName"

    if ($PSCmdlet.ParameterSetName -eq 'AddNew') {
        Write-Log "Operation: Add new debt item"
        Write-Log "Description: $Description"
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
        # --- Add new debt item ---
        if (-not $PSCmdlet.ShouldProcess($TargetFile, "Add new debt item: $Description")) {
            return
        }

        # Single read-modify-write cycle
        $content = Get-Content $TargetFile -Raw

        # Generate next TD### ID from content
        $newDebtId = Get-NextDebtId -Content $content
        Write-Log "Generated new debt ID: $newDebtId"

        # Insert new row into Registry table
        $content = Add-NewDebtItemContent -Content $content -NewDebtId $newDebtId `
            -Description $Description -Dims $Dims -Location $Location `
            -Priority $Priority -EstimatedEffort $EstimatedEffort `
            -AssessmentId $AssessmentId -Notes $Notes
        if ($null -eq $content) {
            Write-Log "Failed to add new debt item to Registry table" -Level "ERROR"
            exit 1
        }

        # Update frontmatter date
        $content = Update-FrontmatterDate -Content $content

        # Single write
        Set-Content -Path $TargetFile -Value $content -NoNewline

        # Update the debt item file with the assigned registry ID if DebtItemId is provided
        if ($DebtItemId) {
            Update-DebtItemFile -DebtItemId $DebtItemId -RegistryId $newDebtId
        }

        # Link to validation tracking if ValidationIssueId is provided
        if ($ValidationIssueId) {
            $valFile = Find-ValidationTrackingFile
            if ($valFile) {
                Update-ValidationTrackingLink -ValidationIssueId $ValidationIssueId -DebtId $newDebtId -TrackingFilePath $valFile
            }
        }

        Write-Log "Technical debt item added successfully with ID: $newDebtId" -Level "SUCCESS"
        Write-Log "Updated file: $TargetFile"
    }
    else {
        # --- Status update ---

        # Single read-modify-write cycle
        $content = Get-Content $TargetFile -Raw

        $isResolution = $NewStatus -in @("Resolved", "Rejected")

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

        # Write tech debt tracking file (guarded by ShouldProcess for -WhatIf support)
        if ($PSCmdlet.ShouldProcess($TargetFile, "Update $DebtId to $NewStatus")) {
            Set-Content -Path $TargetFile -Value $content -NoNewline
        }

        # Update validation tracking if ValidationNote is provided
        # (has its own ShouldProcess guard internally)
        if ($isResolution -and $ValidationNote) {
            $valFile = Find-ValidationTrackingFile
            if ($valFile) {
                $valParams = @{
                    DebtId           = $DebtId
                    ValidationNote   = $ValidationNote
                    TrackingFilePath = $valFile
                }
                if ($ValidationIssueId) {
                    $valParams['ValidationIssueId'] = $ValidationIssueId
                }
                Update-ValidationTracking @valParams
            }
        }

        Write-Log "Technical debt update completed successfully" -Level "SUCCESS"
        Write-Log "Updated file: $TargetFile"
    }
}

# Execute main function
Main
