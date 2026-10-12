#!/usr/bin/env pwsh

<#
.SYNOPSIS
Atomically updates validation tracking state files after a validation session.

.DESCRIPTION
Updates a validation tracking file in a single atomic read-modify-write cycle,
eliminating the manual Read-Edit-Write cycle that caused concurrent access issues
during parallel validation sessions (IMP-449).

Updates three sections of the tracking file:
1. Feature-by-Feature Progress — marks features as validated with date and report link
2. Validation Reports Registry — adds the report's entry to the dimension section, or fills
   in the entry that already exists (e.g. the placeholder New-ValidationReport.ps1 writes)
3. Overall Progress — recalculates Items Validated from the feature cells and derives
   Reports Generated from the registry, never incrementing either

Also recalculates per-feature Overall Status and updates frontmatter date.

.PARAMETER TrackingFile
Path to the validation tracking state file (e.g., doc/state-tracking/validation/validation-tracking-4.md).
Can be absolute or relative to the project root.

.PARAMETER Dimension
The validation dimension being reported.

.PARAMETER FeatureIds
Array of feature IDs covered by this validation report.

.PARAMETER ReportId
The validation report ID (e.g., "PD-VAL-083").

.PARAMETER ReportPath
Path to the validation report file, relative to project root with leading slash
(e.g., "/doc/validation/reports/architectural-consistency/PD-VAL-083-report.md").

.PARAMETER Score
Dimension score string (e.g., "2.88/3.0"). Optional.

.PARAMETER ReportStatus
Report pass/fail status. Defaults to "PASS".

.PARAMETER Issues
Issue summary string (e.g., "0 High, 1 Medium, 3 Low"). Optional.

.PARAMETER Actions
Action summary for the registry table. Optional.

.PARAMETER Date
Validation date in YYYY-MM-DD format. Defaults to today.

.EXAMPLE
Update-ValidationReportState.ps1 -TrackingFile "doc/state-tracking/validation/validation-tracking-4.md" `
    -Dimension "Architectural Consistency" -FeatureIds @("0.1.1","0.1.2","0.1.3","1.1.1") `
    -ReportId "PD-VAL-083" -ReportPath "/doc/validation/reports/architectural-consistency/PD-VAL-083-report.md" `
    -Score "2.88/3.0" -Issues "0 High, 0 Medium, 3 Low" -Actions "No immediate actions required"

.EXAMPLE
# Preview changes without modifying the file
Update-ValidationReportState.ps1 -TrackingFile "doc/state-tracking/validation/validation-tracking-4.md" `
    -Dimension "Code Quality & Standards" -FeatureIds @("2.1.1","2.2.1","3.1.1","6.1.1") `
    -ReportId "PD-VAL-084" -ReportPath "/doc/validation/reports/code-quality/PD-VAL-084-report.md" `
    -WhatIf

.NOTES
Version: 2.1
Created: 2025-08-23
Rewritten: 2026-04-10
Updated: 2026-09-28 (PF-IMP-2352: registry upsert, derived Reports Generated, anchored matching)
Addresses: IMP-449 (Concurrent access during parallel validation sessions)
Pattern: Single read-modify-write cycle following Update-ProcessImprovement.ps1

Output behavior: Default output is one summary line per invocation (the outcome,
e.g. "PD-VAL-084 → 4 features × Code Quality & Standards"). WARN and ERROR messages
always pass through. Pass -Verbose to restore the full play-by-play log.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$TrackingFile,

    [Parameter(Mandatory)]
    [ValidateSet(
        "Architectural Consistency",
        "Code Quality & Standards",
        "Integration & Dependencies",
        "Documentation Alignment",
        "Extensibility & Maintainability",
        "AI Agent Continuity",
        "Security & Data Protection",
        "Performance & Scalability",
        "Observability",
        "Accessibility / UX Compliance",
        "Data Integrity"
    )]
    [string]$Dimension,

    [Parameter(Mandatory)]
    [string[]]$FeatureIds,

    [Parameter(Mandatory)]
    [string]$ReportId,

    [Parameter(Mandatory)]
    [string]$ReportPath,

    [string]$Score,
    [string]$ReportStatus = "PASS",
    [string]$Issues,
    [string]$Actions,
    [string]$Date
)

# --- Module import ---
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$dir = $scriptDir
while ($dir -and !(Test-Path (Join-Path $dir "Common-ScriptHelpers.psm1"))) {
    $dir = Split-Path -Parent $dir
}
if ($dir) {
    # Temporarily silence $VerbosePreference around the import so -Verbose callers see
    # only this script's own Write-Verbose output, not the helper module's internal chatter.
    $prevVerbosePreference = $VerbosePreference
    $VerbosePreference = 'SilentlyContinue'
    Import-Module (Join-Path $dir "Common-ScriptHelpers.psm1") -Force -Verbose:$false
    $VerbosePreference = $prevVerbosePreference
}

# Soak verification (PF-PRO-028 v2.0 Pattern A; caller-aware no-arg form)
Register-SoakScript
$soakInSoak = Test-ScriptInSoak

# Soak-verification wrapper begins (PF-PRO-028 v2.0)
try {

# --- Configuration ---
$ScriptName = "Update-ValidationReportState.ps1"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

if (-not $Date) { $Date = $CurrentDate }

# Resolve tracking file path
if (Get-Command Get-ProjectRoot -ErrorAction SilentlyContinue) {
    $ProjectRoot = Get-ProjectRoot
} else {
    $ProjectRoot = (Get-Location).Path
}

if ([System.IO.Path]::IsPathRooted($TrackingFile)) {
    $ResolvedTrackingFile = $TrackingFile
} else {
    $ResolvedTrackingFile = Join-Path $ProjectRoot $TrackingFile
}

# Dimension-to-column-header mapping
$DimensionColumnHeaders = @{
    "Architectural Consistency"       = "Arch"
    "Code Quality & Standards"        = "Quality"
    "Integration & Dependencies"      = "Integration"
    "Documentation Alignment"         = "Docs"
    "Extensibility & Maintainability" = "Extensibility"
    "AI Agent Continuity"             = "AI Continuity"
    "Security & Data Protection"      = "Security"
    "Performance & Scalability"       = "Performance"
    "Observability"                   = "Observability"
    "Accessibility / UX Compliance"   = "Accessibility"
    "Data Integrity"                  = "Data Integrity"
}

# A Feature-by-Feature cell counts as validated when it carries a dated report link. The
# overwrite decision, the Items Validated count and the per-feature roll-up all use this one
# definition.
$ValidatedCellPattern = '^\[?\d{4}-\d{2}-\d{2}'

# --- Prerequisites ---
function Test-Prerequisites {
    if (-not (Test-Path $ResolvedTrackingFile)) {
        Write-ProjectLog -Level "ERROR" -Message "Tracking file not found: $ResolvedTrackingFile"
        return $false
    }
    return $true
}

# --- Row-location helpers ---

function Test-TargetFeature {
    # True when a Feature-by-Feature row's Feature cell names one of -FeatureIds. Anchored at the
    # start of the cell (after any link or emphasis punctuation) and bounded after the ID, so
    # 0.1.1 matches neither 10.1.1 nor 0.1.10.
    param([string]$FeatureCell)
    foreach ($fid in $FeatureIds) {
        if ($FeatureCell -match ('^\W*' + [regex]::Escape($fid) + '(?!\.?\d)')) { return $true }
    }
    return $false
}

function Find-ProgressRow {
    # Locates the Overall Progress table and this dimension's row in it, or returns $null. The
    # row is matched on its first cell — the dimension name, optionally numbered
    # ("1. Architectural Consistency") — not as a substring anywhere in the line.
    param([string[]]$Lines)
    $headerIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\|\s*Validation Type\s*\|' -and $Lines[$i] -match '\|\s*(Items Validated|Reports Generated)\s*\|') {
            $headerIdx = $i
            break
        }
    }
    if ($headerIdx -eq -1) { return $null }

    $headers = Split-MarkdownTableRow -Line $Lines[$headerIdx].Trim()
    $dimPattern = '^(?:\d+\.\s*)?' + [regex]::Escape($Dimension) + '$'
    for ($i = $headerIdx + 2; $i -lt $Lines.Count; $i++) {
        $cells = Split-MarkdownTableRow -Line $Lines[$i].Trim()
        if ($null -eq $cells) { break }
        if ($cells.Count -gt 0 -and $cells[0] -match $dimPattern) {
            return @{ RowIdx = $i; Headers = $headers }
        }
    }
    return $null
}

function Find-RegistryTable {
    # Locates this dimension's registry table ("### [N.] <Dimension> Validation Reports"), or
    # returns $null. FirstRow..End-1 are its data rows; End is where a new row is inserted.
    param([string[]]$Lines)
    $dimPattern = [regex]::Escape($Dimension)
    $sectionIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match "^###\s+\d*\.?\s*$dimPattern\s+Validation Reports") {
            $sectionIdx = $i
            break
        }
    }
    if ($sectionIdx -eq -1) { return $null }

    $headerIdx = -1
    for ($i = $sectionIdx + 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\|\s*Report ID\s*\|') {
            $headerIdx = $i
            break
        }
        if ($Lines[$i] -match '^#') { break }  # Hit the next section
    }
    if ($headerIdx -eq -1) { return $null }

    $end = $headerIdx + 2
    for ($i = $headerIdx + 2; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\|') { $end = $i + 1 } else { break }
    }
    return @{
        SectionIdx = $sectionIdx
        Headers    = Split-MarkdownTableRow -Line $Lines[$headerIdx].Trim()
        FirstRow   = $headerIdx + 2
        End        = $end
    }
}

# --- Transformation Functions ---
# Each takes a lines array and returns a modified lines array.

function Update-FeatureByFeatureCells {
    param([string[]]$Lines)

    $columnHeader = $DimensionColumnHeaders[$Dimension]
    $cellValue = "[$Date]($ReportPath)"
    # PF-PRO-077 / PF-IMP-2126: collect the Feature cells this run actually writes, so the
    # post-write assertion covers exactly those rows. Rows skipped as N/A or already-set were
    # never written and must not be asserted.
    $updatedCells = [System.Collections.Generic.List[string]]::new()

    # Find the Feature-by-Feature table header
    $headerIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\|\s*Feature\s*\|' -and $Lines[$i] -match 'Overall') {
            $headerIdx = $i
            break
        }
    }

    if ($headerIdx -eq -1) {
        Write-ProjectLog -Level "WARN" -Message "Could not find Feature-by-Feature Progress table"
        return @{ Lines = $Lines; UpdatedFeatureCells = $updatedCells; CellValue = $cellValue }
    }

    # Parse column headers to find target column index
    $headers = $Lines[$headerIdx] -split '\|' | ForEach-Object { $_.Trim() }
    # After split: [0]="" [1]="Feature" [2]="Arch" ... [N]="Overall" [N+1]=""
    $columnIdx = -1
    for ($c = 0; $c -lt $headers.Count; $c++) {
        if ($headers[$c] -eq $columnHeader) {
            $columnIdx = $c
            break
        }
    }

    if ($columnIdx -eq -1) {
        Write-ProjectLog -Level "WARN" -Message "Could not find column '$columnHeader' in Feature-by-Feature table"
        return @{ Lines = $Lines; UpdatedFeatureCells = $updatedCells; CellValue = $cellValue }
    }

    # Update feature rows (start after header + separator)
    for ($i = $headerIdx + 2; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        if ($line -notmatch '^\|') { break }

        $cells = $line -split '\|'
        $featureCell = $cells[1].Trim()

        if ((Test-TargetFeature -FeatureCell $featureCell) -and $columnIdx -lt $cells.Count) {
            $currentValue = $cells[$columnIdx].Trim()

            if ($currentValue -eq 'N/A' -or $currentValue -eq '') {
                Write-ProjectLog -Level "INFO" -Message "Skipped: $featureCell [$columnHeader] is not applicable"
            } elseif ($currentValue -match $ValidatedCellPattern) {
                Write-ProjectLog -Level "INFO" -Message "Skipped: $featureCell [$columnHeader] already validated: $currentValue"
            } else {
                # Every other state awaits this report — Pending, In Progress, Failed, Needs
                # Re-validation, with or without its label text. Only the validated and
                # not-applicable states are recognised, so no legend glyph can be missed.
                $cells[$columnIdx] = " $cellValue "
                $Lines[$i] = $cells -join '|'
                $updatedCells.Add($featureCell)
                Write-ProjectLog -Level "SUCCESS" -Message "Updated: $featureCell [$columnHeader] -> $cellValue"
            }
        }
    }

    # PF-PRO-077: returns the lines plus what was written, for the post-write assertion.
    return @{ Lines = $Lines; UpdatedFeatureCells = $updatedCells; CellValue = $cellValue }
}

function Update-OverallProgress {
    param([string[]]$Lines)

    $columnHeader = $DimensionColumnHeaders[$Dimension]

    # First, gather validated counts from Feature-by-Feature table
    $fbfHeaderIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\|\s*Feature\s*\|' -and $Lines[$i] -match 'Overall') {
            $fbfHeaderIdx = $i
            break
        }
    }

    if ($fbfHeaderIdx -eq -1) { return $Lines }

    # Find column index in Feature-by-Feature table
    $fbfHeaders = $Lines[$fbfHeaderIdx] -split '\|' | ForEach-Object { $_.Trim() }
    $fbfColumnIdx = -1
    for ($c = 0; $c -lt $fbfHeaders.Count; $c++) {
        if ($fbfHeaders[$c] -eq $columnHeader) {
            $fbfColumnIdx = $c
            break
        }
    }

    if ($fbfColumnIdx -eq -1) { return $Lines }

    # Count validated and total applicable from Feature-by-Feature column
    $totalApplicable = 0
    $totalValidated = 0
    for ($i = $fbfHeaderIdx + 2; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -notmatch '^\|') { break }
        $cells = $Lines[$i] -split '\|'
        if ($fbfColumnIdx -lt $cells.Count) {
            $cellValue = $cells[$fbfColumnIdx].Trim()
            if ($cellValue -ne 'N/A' -and $cellValue -ne '') {
                $totalApplicable++
                if ($cellValue -match $ValidatedCellPattern) {
                    $totalValidated++
                }
            }
        }
    }

    # Update this dimension's Overall Progress row, addressing its cells by header name.
    # Reports Generated is not touched here — Update-ReportsGenerated derives it separately.
    $progress = Find-ProgressRow -Lines $Lines
    if (-not $progress) {
        Write-ProjectLog -Level "WARN" -Message "Could not find the Overall Progress row for '$Dimension'"
        return $Lines
    }

    $updates = @{ 'Items Validated' = "$totalValidated/$totalApplicable" }
    if ($totalValidated -ge $totalApplicable) {
        $updates['Status'] = 'COMPLETED'
        $updates['Next Session'] = '—'
    } else {
        $updates['Status'] = 'IN_PROGRESS'
    }
    $Lines[$progress.RowIdx] = Set-MarkdownTableCell -Line $Lines[$progress.RowIdx].Trim() -Headers $progress.Headers -Updates $updates
    Write-ProjectLog -Level "SUCCESS" -Message "Overall Progress: $Dimension -> $totalValidated/$totalApplicable validated"

    return $Lines
}

function Update-ReportsGenerated {
    # Reports Generated is DERIVED, never incremented: it is set to the number of distinct reports
    # in this dimension's registry table. The registry has several writers — this script,
    # New-ValidationReport.ps1's placeholder row, and the template's manual steps — so a
    # "was this report already counted?" guard can be fooled by any of them, including this
    # run's own earlier writes (PF-IMP-2158, PF-IMP-2352). A count of the registry cannot.
    # Kept separate from Update-OverallProgress so the counter stays right even when the
    # Feature-by-Feature column lookup fails. Returns the lines plus the count it wrote, for
    # the post-write check ($null when nothing was written).
    param([string[]]$Lines)

    $registry = Find-RegistryTable -Lines $Lines
    if (-not $registry) {
        # Leave the counter alone rather than write a 0 the registry does not support.
        Write-ProjectLog -Level "WARN" -Message "Could not find the '$Dimension Validation Reports' registry table — Reports Generated left unchanged"
        return @{ Lines = $Lines; Count = $null }
    }

    $idIdx = [array]::IndexOf([string[]]$registry.Headers, 'Report ID')
    $ids = [System.Collections.Generic.HashSet[string]]::new()
    for ($i = $registry.FirstRow; $i -lt $registry.End; $i++) {
        $cells = Split-MarkdownTableRow -Line $Lines[$i].Trim()
        if ($null -eq $cells -or $idIdx -ge $cells.Count) { continue }
        $id = (Get-MarkdownLinkText -Value $cells[$idIdx]).Trim()
        if ($id -notmatch '^[—-]*$') { [void]$ids.Add($id) }
    }

    $progress = Find-ProgressRow -Lines $Lines
    if (-not $progress) {
        Write-ProjectLog -Level "WARN" -Message "Could not find the Overall Progress row for '$Dimension' — Reports Generated not written"
        return @{ Lines = $Lines; Count = $null }
    }

    $Lines[$progress.RowIdx] = Set-MarkdownTableCell -Line $Lines[$progress.RowIdx].Trim() -Headers $progress.Headers -Updates @{ 'Reports Generated' = "$($ids.Count)" }
    Write-ProjectLog -Level "SUCCESS" -Message "Overall Progress: $Dimension -> $($ids.Count) reports registered"
    return @{ Lines = $Lines; Count = $ids.Count }
}

function Set-RegistryEntry {
    # Upserts this report's row in the dimension's registry table. An existing row is filled in
    # rather than skipped: New-ValidationReport.ps1 writes a placeholder row (—/3.0, IN PROGRESS)
    # when it creates the report, and a re-run may correct a score (PF-IMP-2352). The row is
    # matched by exact report ID, so PD-VAL-100 never matches a PD-VAL-1000 row. Both paths
    # address cells by the table's own header names.
    param([string[]]$Lines)

    $registry = Find-RegistryTable -Lines $Lines
    if (-not $registry) {
        Write-ProjectLog -Level "WARN" -Message "Could not find the '$Dimension Validation Reports' registry table"
        return $Lines
    }

    $values = @{
        'Report ID' = "[$ReportId]($ReportPath)"
        'Features'  = $FeatureIds -join ', '
        'Date'      = $Date
        'Status'    = $ReportStatus
    }
    # An omitted optional value leaves an existing row's cell as it is (a placeholder already
    # holds the dash); a new row gets the dash.
    if ($Score)   { $values['Score'] = $Score }
    if ($Issues)  { $values['Issues'] = $Issues }
    if ($Actions) { $values['Actions'] = $Actions }

    $absent = @($values.Keys | Where-Object { $registry.Headers -notcontains $_ })
    if ($absent.Count -gt 0) {
        Write-ProjectLog -Level "WARN" -Message "Registry table has no column(s) '$($absent -join "', '")' — those values were not written"
        foreach ($key in $absent) { $values.Remove($key) }
    }

    $idIdx = [array]::IndexOf([string[]]$registry.Headers, 'Report ID')
    for ($i = $registry.FirstRow; $i -lt $registry.End; $i++) {
        $cells = Split-MarkdownTableRow -Line $Lines[$i].Trim()
        if ($null -eq $cells -or $idIdx -ge $cells.Count) { continue }
        if ((Get-MarkdownLinkText -Value $cells[$idIdx]).Trim() -eq $ReportId) {
            $Lines[$i] = Set-MarkdownTableCell -Line $Lines[$i].Trim() -Headers $registry.Headers -Updates $values
            Write-ProjectLog -Level "SUCCESS" -Message "Updated registry entry: $ReportId ($($FeatureIds -join ', '))"
            return $Lines
        }
    }

    $newRow = New-HeaderDrivenTableRow -Content ($Lines -join "`n") -SectionHeading $Lines[$registry.SectionIdx] -ValueMap $values
    $result = [System.Collections.Generic.List[string]]::new([string[]]$Lines)
    $result.Insert($registry.End, $newRow)
    Write-ProjectLog -Level "SUCCESS" -Message "Added registry entry: $ReportId ($($FeatureIds -join ', '))"
    return $result.ToArray()
}

function Update-FeatureOverallStatus {
    param([string[]]$Lines)

    # Find the Feature-by-Feature table
    $headerIdx = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\|\s*Feature\s*\|' -and $Lines[$i] -match 'Overall') {
            $headerIdx = $i
            break
        }
    }

    if ($headerIdx -eq -1) { return $Lines }

    $headers = $Lines[$headerIdx] -split '\|' | ForEach-Object { $_.Trim() }

    # Find the Overall column index
    $overallIdx = -1
    for ($c = 0; $c -lt $headers.Count; $c++) {
        if ($headers[$c] -eq 'Overall') {
            $overallIdx = $c
            break
        }
    }

    if ($overallIdx -eq -1) { return $Lines }

    # For each feature row, check if this feature was in our update set
    for ($i = $headerIdx + 2; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -notmatch '^\|') { break }

        $cells = $Lines[$i] -split '\|'
        $featureCell = $cells[1].Trim()

        if (-not (Test-TargetFeature -FeatureCell $featureCell)) { continue }

        # Check all dimension cells (columns 2 through overallIdx-1)
        $allDone = $true
        $anyFailed = $false
        for ($c = 2; $c -lt $overallIdx; $c++) {
            if ($c -ge $cells.Count) { continue }
            $val = $cells[$c].Trim()
            if ($val -eq 'N/A' -or $val -eq '') { continue }
            if ($val -match $ValidatedCellPattern) {
                # Validated
            } elseif ($val -match 'Failed') {
                $anyFailed = $true
                $allDone = $false
            } else {
                $allDone = $false
            }
        }

        $newStatus = if ($anyFailed) { "ISSUES_FOUND" }
                     elseif ($allDone) { "VALIDATED" }
                     else { "IN_PROGRESS" }

        $currentStatus = $cells[$overallIdx].Trim()
        if ($currentStatus -ne $newStatus) {
            $cells[$overallIdx] = " $newStatus "
            $Lines[$i] = $cells -join '|'
            Write-ProjectLog -Level "SUCCESS" -Message "Feature $featureCell Overall: $currentStatus -> $newStatus"
        }
    }

    return $Lines
}

function Update-FrontmatterDate {
    param([string[]]$Lines)

    for ($i = 0; $i -lt [Math]::Min(20, $Lines.Count); $i++) {
        if ($Lines[$i] -match '^updated:\s*\d{4}-\d{2}-\d{2}') {
            $Lines[$i] = "updated: $CurrentDate"
            Write-ProjectLog -Level "SUCCESS" -Message "Updated frontmatter date to $CurrentDate"
            break
        }
    }

    return $Lines
}

# --- Main ---

Write-ProjectLog -Level "INFO" -Message "Starting Validation Report State Update — $ScriptName"
Write-ProjectLog -Level "INFO" -Message "Tracking file: $ResolvedTrackingFile"
Write-ProjectLog -Level "INFO" -Message "Dimension: $Dimension"
Write-ProjectLog -Level "INFO" -Message "Features: $($FeatureIds -join ', ')"
Write-ProjectLog -Level "INFO" -Message "Report: $ReportId"

if (-not (Test-Prerequisites)) {
    exit 1
}

# Single read
$lines = Get-Content $ResolvedTrackingFile -Encoding UTF8

# Chain transformations
# PF-PRO-077: this one also reports which Feature cells it wrote, for the post-write assertion.
$fbf = Update-FeatureByFeatureCells -Lines $lines
$lines = $fbf.Lines
$lines = Set-RegistryEntry -Lines $lines
$lines = Update-OverallProgress -Lines $lines
# Derived from the registry, so it must run after Set-RegistryEntry; reports its count for the
# post-write check.
$reports = Update-ReportsGenerated -Lines $lines
$lines = $reports.Lines
$lines = Update-FeatureOverallStatus -Lines $lines
$lines = Update-FrontmatterDate -Lines $lines

# Single write
if ($PSCmdlet.ShouldProcess($ResolvedTrackingFile, "Update validation tracking for $Dimension ($ReportId)")) {
    $lines | Set-Content $ResolvedTrackingFile -Encoding UTF8

    # Read-after-write verification (PF-PRO-077 / PF-IMP-2126), after the run's only write and
    # before the success line. Assert-TableRowInFile, never Assert-LineInFile: only a header-aware
    # check can tell a correct row from one whose cells have shifted under the wrong headers. The
    # feature cells are rebuilt by a raw split/join; for the registry row, which is built from its
    # table's own header, the assertion is the backstop.
    if (-not $WhatIfPreference) {
        foreach ($writtenCell in $fbf.UpdatedFeatureCells) {
            $rowPattern = "^\|\s*" + [regex]::Escape($writtenCell) + "\s*\|(?:.*\|)?\s*" + [regex]::Escape($fbf.CellValue) + "\s*\|"
            Assert-TableRowInFile -Path $ResolvedTrackingFile -Pattern $rowPattern -Context "feature row '$writtenCell' → $($fbf.CellValue) in $ResolvedTrackingFile"
        }
        $registryPattern = "^\|\s*\[" + [regex]::Escape($ReportId) + "\]\(" + [regex]::Escape($ReportPath) + "\)\s*\|.*\|\s*" + [regex]::Escape($Date) + "\s*\|.*\|\s*" + [regex]::Escape($ReportStatus) + "\s*\|"
        Assert-TableRowInFile -Path $ResolvedTrackingFile -Pattern $registryPattern -Context "registry row $ReportId ($Date, $ReportStatus) in $ResolvedTrackingFile"

        # The derived counter, read back by header name from what is now on disk.
        if ($null -ne $reports.Count) {
            $onDisk = [string[]](Get-Content $ResolvedTrackingFile -Encoding UTF8)
            $written = Find-ProgressRow -Lines $onDisk
            $actual = if ($written) { Get-MarkdownTableCell -Line $onDisk[$written.RowIdx].Trim() -Headers $written.Headers -Header 'Reports Generated' }
            if ("$actual".Trim() -ne "$($reports.Count)") {
                throw "Post-write check: Reports Generated for '$Dimension' reads '$actual' in $ResolvedTrackingFile, expected $($reports.Count)"
            }
        }
    }

    Write-ProjectSummary "$ReportId → $($FeatureIds.Count) feature$(if ($FeatureIds.Count -ne 1) { 's' }) × $Dimension"
} else {
    Write-ProjectLog -Level "INFO" -Message "WhatIf mode — no changes written"
}


    # Soak: success outcome (PF-PRO-028 v2.0)
    if ($soakInSoak) { Confirm-SoakInvocation -Outcome success }
}
catch {
    if ($soakInSoak) {
        $soakErrMsg = $_.Exception.Message
        if ($soakErrMsg.Length -gt 80) { $soakErrMsg = $soakErrMsg.Substring(0, 80) + "..." }
        Confirm-SoakInvocation -Outcome failure -Notes $soakErrMsg
    }
    Write-Error "Validation report state update failed: $($_.Exception.Message)"
    exit 1
}
